# SHADE+LM hybrid baseline.
#
# Global phase: Metaheuristics.SHADE (Success-History Adaptive Differential
# Evolution) explores the bounded box derivative-free in the same per-variable
# transformed coordinates the polish step uses (via `_build_polish_context`).
#
# Local phase: top-K SHADE seeds are handed to `_polish_single_from_context`,
# which dispatches on `opts.polish_method`. Default `PolishLSOBoundedLog`
# gives bounded `LeastSquaresOptim.LevenbergMarquardt` with ForwardDiff
# Jacobian, revert guard, and the LSO trust-region tuning chosen in the
# 2026-05 polish bake-off. Switching `opts.polish_method` to any other
# `PolishMethod` (FastLM, LBFGS, BFGS, NewtonTrust) is a no-code-change swap.
#
# Modularity hook: `_run_shade_phase` returns a fixed-shape NamedTuple
# `(positions, fvals, n_evals, elapsed)`. A future TikTak/DE/ISRES global
# phase matching that contract drops into `shade_lm_estimate` at one line.

# Sentinel for non-finite SHADE-phase loss values (ODE solver failure, etc.).
# SHADE ranks by fitness; a population dominated by `Inf` collapses diversity.
# This must comfortably exceed any plausible legitimate trajectory-fit loss
# without overflowing downstream arithmetic.
const _SHADE_FALLBACK_SENTINEL = 1.0e12

# Defensive fallback for `±Inf` entries in `ctx.internal_lb`/`internal_ub`.
# `compute_default_bounds` always returns finite signed bounds, so this only
# triggers when a user passes explicit `opts.opt_lb`/`opt_ub` containing
# `±Inf` and the resulting transform is `:linear` (which preserves the
# infinity). `±20` in transformed coords is `≈ ±5e8` in linear space.
const _SHADE_INF_BOUND_FALLBACK = 20.0


"""
	shade_lm_estimate(PEP::ParameterEstimationProblem; opts = EstimationOptions()) -> ParameterEstimationResult

Hybrid global+local parameter estimation baseline. Runs SHADE in the bounded
internal-coordinate box (per-variable `:log`/`:shifted_log`/`:linear` from the
polish-context's `:auto` policy), then polishes the top-K SHADE candidates
through `_polish_single_from_context` using `opts.polish_method`.

# Tuning knobs (all in `EstimationOptions`)

- `shade_total_max_evals` — total objective-call budget (default `200_000`).
- `shade_total_max_time` — total wall-clock budget in seconds (default `600.0`).
- `shade_global_eval_fraction` — fraction of budget allocated to SHADE
  (default `0.7`); the remainder goes to local polish.
- `shade_n_local_starts` — number of top-fitness SHADE seeds to polish
  (default `5`).
- `shade_population` — SHADE population size; `0` (default) auto-sizes to
  `max(50, 10 * (n_states + n_params))`.
- `shade_seed` — RNG seed for SHADE; `nothing` (default) lets Metaheuristics
  pick a random one.
- `polish_method` — local refinement method (default `PolishLSOBoundedLog`).
  Any `PolishMethod` enum value works without code changes.
- All other `polish_*` knobs (Δ, tolerances, divergence/stagnation guards,
  ODE maxiters, regularization λ) flow through unchanged.

Returns a `ParameterEstimationResult` with `provenance.primary_method = :shade_lm`.
"""
function shade_lm_estimate(
	PEP::ParameterEstimationProblem;
	opts::EstimationOptions = EstimationOptions(),
)
	validate_options(opts) || throw(ArgumentError(
		"Invalid EstimationOptions; fix the reported configuration errors before calling shade_lm_estimate."))

	# 1. Build the polish context once. This compiles observable functions,
	#    builds the base ODE problem, computes per-variable coordinate
	#    transforms, and packages the scalar loss closure as `ctx.optf.f`.
	ctx = _build_polish_context(PEP; opts = opts)

	n_total = ctx.n_ic + ctx.n_param
	n_total >= 1 || throw(ArgumentError("PEP has no states or parameters; nothing to estimate."))

	# 2. Resolve SHADE bounds in internal coords (defensive ±Inf clamp).
	shade_lb, shade_ub = _finite_shade_bounds(ctx)

	# 3. SHADE objective with finite sentinel for non-finite loss values.
	shade_obj = _safe_loss_closure(ctx)

	# 4. Allocate budget across phases.
	pop_size = opts.shade_population > 0 ? opts.shade_population : max(50, 10 * n_total)
	global_evals = max(pop_size, round(Int, opts.shade_total_max_evals * opts.shade_global_eval_fraction))
	global_time = opts.shade_total_max_time * opts.shade_global_eval_fraction

	# 5. Run SHADE.
	shade_result = _run_shade_phase(shade_obj, shade_lb, shade_ub,
		global_evals, global_time, pop_size, opts.shade_seed)

	# 6. Local-phase setup: rank SHADE population, pick top-K, allocate time.
	n_starts = min(opts.shade_n_local_starts, length(shade_result.fvals))
	n_starts >= 1 || throw(ErrorException(
		"SHADE phase produced an empty population; cannot pick local seeds."))
	order = sortperm(shade_result.fvals)
	remaining_time = max(opts.shade_total_max_time - shade_result.elapsed, 1.0)
	per_seed_time = remaining_time / n_starts

	# Pre-resolve scalar optimizer (only consulted by `_polish_single_from_context`
	# for non-residual `PolishMethod`s; residual methods early-dispatch).
	scalar_optimizer = if is_residual_polish_method(opts.polish_method)
		BFGS()  # placeholder; residual path ignores this
	else
		get_polish_optimizer(opts.polish_method)()
	end

	pre_polish_best_err = shade_result.fvals[order[1]]
	best_result::Union{Nothing, ParameterEstimationResult} = nothing
	best_err = Inf

	# 7. Polish each top-K seed and keep the best polished result.
	for i in 1:n_starts
		seed_internal = @view shade_result.positions[order[i], :]
		seed_external = _polish_internal_to_external(
			collect(seed_internal),
			ctx.coordinate_transforms,
			ctx.coordinate_shifts,
		)

		polished, _ = _polish_single_from_context(
			ctx, seed_external;
			optimizer = scalar_optimizer,
			polish_method = opts.polish_method,
			maxiters = opts.polish_maxiters,
			maxtime = per_seed_time,
			divergence_factor = opts.polish_divergence_factor,
			stagnation_window = opts.polish_stagnation_window,
			lso_delta = opts.polish_lso_delta,
			lso_x_tol = opts.polish_lso_x_tol,
			lso_f_tol = opts.polish_lso_f_tol,
			lso_g_tol = opts.polish_lso_g_tol,
		)

		if !isnothing(polished.err) && polished.err < best_err
			best_err = polished.err
			best_result = polished
		end
	end

	if best_result === nothing
		throw(ErrorException(
			"SHADE+LM: every top-K polish call returned a non-finite error. " *
			"Best SHADE fitness was $(pre_polish_best_err)."))
	end

	# 8. Tag provenance with the SHADE+LM lineage. Keep `pre_polish_error`
	#    as the best raw SHADE fitness so downstream reporting can see the
	#    quality lift the polish phase contributed.
	best_result.provenance = ResultProvenance(
		primary_method = :shade_lm,
		pre_polish_error = pre_polish_best_err,
		post_polish_error = best_err,
		polish_applied = true,
	)
	sync_result_contract!(best_result)

	return best_result
end


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

"""
	_safe_loss_closure(ctx) -> Function

Wraps `ctx.optf.f` so that non-finite loss values become a large finite
sentinel. SHADE ranks by fitness — `Inf` from ODE failures collapses
population diversity; a finite sentinel preserves ordering.
"""
function _safe_loss_closure(ctx::PolishContext)
	return function (x_internal)
		v = try
			ctx.optf.f(x_internal, nothing)
		catch
			return _SHADE_FALLBACK_SENTINEL
		end
		return isfinite(v) ? v : _SHADE_FALLBACK_SENTINEL
	end
end


"""
	_finite_shade_bounds(ctx) -> (Vector{Float64}, Vector{Float64})

Defensively replaces `±Inf` entries in `ctx.internal_lb`/`internal_ub` with
`±_SHADE_INF_BOUND_FALLBACK` so SHADE has a finite hyper-rectangle to search.
The default `compute_default_bounds` path always yields finite bounds; this
only matters for users who explicitly set `opts.opt_lb`/`opt_ub` with `±Inf`
and a `:linear` coordinate policy.
"""
function _finite_shade_bounds(ctx::PolishContext)
	n = ctx.n_ic + ctx.n_param
	lb = isnothing(ctx.internal_lb) ? fill(-_SHADE_INF_BOUND_FALLBACK, n) : Float64.(ctx.internal_lb)
	ub = isnothing(ctx.internal_ub) ? fill( _SHADE_INF_BOUND_FALLBACK, n) : Float64.(ctx.internal_ub)
	@inbounds for i in eachindex(lb)
		isfinite(lb[i]) || (lb[i] = -_SHADE_INF_BOUND_FALLBACK)
		isfinite(ub[i]) || (ub[i] =  _SHADE_INF_BOUND_FALLBACK)
		lb[i] < ub[i] || throw(ArgumentError(
			"SHADE bounds invalid at index $i: lb=$(lb[i]) ≥ ub=$(ub[i])"))
	end
	return lb, ub
end


"""
	_run_shade_phase(obj, lb, ub, max_evals, max_time, pop_size, seed) -> NamedTuple

Run the global SHADE phase. Returns a fixed-shape NamedTuple:

    (positions::Matrix{Float64},   # rows = individuals, cols = variables
     fvals::Vector{Float64},       # fitness per individual
     n_evals::Int,                 # total function calls used
     elapsed::Float64)             # wall-clock seconds spent

This shape is the modularity contract: a future `_run_tiktak_phase` /
`_run_de_phase` / `_run_isres_phase` must match it so `shade_lm_estimate`
swaps backends at one call site.
"""
function _run_shade_phase(
	obj,
	lb::AbstractVector{<:Real},
	ub::AbstractVector{<:Real},
	max_evals::Int,
	max_time::Real,
	pop_size::Int,
	seed::Union{Nothing, UInt},
)
	# Metaheuristics expects a 2×n bounds matrix (row 1 = lb, row 2 = ub).
	bounds = [Float64.(lb) Float64.(ub)]'

	shade = Metaheuristics.SHADE(; N = pop_size)
	shade.options.f_calls_limit = Float64(max_evals)
	shade.options.time_limit = Float64(max_time)
	if seed !== nothing
		shade.options.seed = seed
	end

	t_start = time()
	result = Metaheuristics.optimize(obj, bounds, shade)
	elapsed = time() - t_start

	positions = Matrix{Float64}(Metaheuristics.positions(result))
	fvals = Vector{Float64}(Metaheuristics.fvals(result))
	n_evals = Int(Metaheuristics.nfes(result))

	return (positions = positions, fvals = fvals, n_evals = n_evals, elapsed = elapsed)
end
