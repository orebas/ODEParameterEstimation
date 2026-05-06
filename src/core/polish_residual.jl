# Residual-mode polish path: bounded LeastSquaresOptim LM and FastLevenbergMarquardt
# in per-variable transformed coordinates. Promoted from
# test/generate_residual_polish_ablation.jl after the April-2026 polish bake-off
# (temp_plans/2026-05-01_local_polish_default_recommendation.md).
#
# This path shares PolishContext setup (observable funcs, data_targets, base ODEProblem,
# coordinate transforms) with the legacy scalar polisher. The only difference is the
# inner solve: a residual-vector LM call rather than Optimization.solve on a scalar loss.
#
# Includes:
# - revert guard (return p0 when ‖r(p_solved)‖ > ‖r(p0)‖)
# - sentinel residual fill (1e6) for failed ODE solves — `Inf` would poison LM Jacobian
# - optional λ‖x_internal‖² regularization via augmented residual
# - native bound support (LSO/FastLM accept `lower=`/`upper=` directly)

const _RESIDUAL_SENTINEL_VALUE = 1.0e6

"""
	_residual_sentinel(eltype) -> sentinel value of correct type

The residual fill value used when an ODE solve fails inside the LM loop.
"""
_residual_sentinel(res::AbstractVector{T}) where {T} = convert(T, _RESIDUAL_SENTINEL_VALUE)

"""
	_polish_single_residual(ctx, p0; ...) -> (ParameterEstimationResult, opt_result)

Residual-mode polish using `LeastSquaresOptim.LevenbergMarquardt()` (`solver_kind = :lso_direct`)
or `FastLevenbergMarquardt.lmsolve!` (`solver_kind = :fastlm_direct`). The residual
vector is `r(p_internal) = [observed - model] ++ optional λ-augmentation`.

Bounds are passed natively to LSO/FastLM. The `revert guard` ensures we never return
a polished point whose final residual norm exceeds the seed's — the seed is returned
in that case.

Optional λ regularization (`ctx.regularization_lambda > 0`) appends `√λ · x_internal`
rows to the residual. Default is off (λ = 0) per the recommendation memo.
"""
function _polish_single_residual(
	ctx::PolishContext,
	p0::AbstractVector{<:Real};
	solver_kind::Symbol = :lso_direct,
	optimizer_factory = () -> LeastSquaresOptim.LevenbergMarquardt(),
	maxiters::Int = 1000,
	maxtime::Float64 = 300.0,
	lso_delta::Float64 = 10.0,
	lso_x_tol::Float64 = -1.0,
	lso_f_tol::Float64 = -1.0,
	lso_g_tol::Float64 = -1.0,
)
	# --- Coordinate transform setup ---
	has_external_bounds = !isnothing(ctx.lb) && !isnothing(ctx.ub)
	p0_external = has_external_bounds ? clamp.(Float64.(p0), ctx.lb, ctx.ub) : Float64.(p0)
	p0_internal = _polish_external_to_internal(p0_external, ctx.coordinate_transforms, ctx.coordinate_shifts)

	# Bounds on internal coords are honored by LSO/FastLM directly; pass through ±Inf
	# entries verbatim — both backends accept unbounded coordinates.
	internal_lb = ctx.internal_lb
	internal_ub = ctx.internal_ub

	# --- Residual layout ---
	λ = max(ctx.regularization_lambda, 0.0)
	use_regularization = λ > 0.0
	penalty_scale = use_regularization ? sqrt(λ) : 0.0
	n_unknowns = length(p0_internal)
	n_obs_residual = sum(length(target) for target in ctx.data_targets)
	residual_count = n_obs_residual + (use_regularization ? n_unknowns : 0)
	residual_count == 0 && throw(ArgumentError("Residual polish requires at least one observed datum"))

	# --- Residual closure ---
	function residual!(res, p_internal, _ = nothing)
		p_all = _polish_internal_to_external(p_internal, ctx.coordinate_transforms, ctx.coordinate_shifts)
		ic_guess = @view p_all[1:ctx.n_ic]
		param_guess = @view p_all[(ctx.n_ic + 1):end]

		prob_opt = remake(
			ctx.base_ode_prob;
			u0 = Dict(ctx.unknown_syms .=> ic_guess),
			p = Dict(ctx.param_syms .=> param_guess),
			build_initializeprob = false,
		)

		sol_opt = try
			ModelingToolkit.solve(
				prob_opt,
				ctx.solver;
				saveat = ctx.t_vector,
				abstol = ctx.abstol,
				reltol = ctx.reltol,
				maxiters = ctx.polish_ode_maxiters,
			)
		catch
			fill!(res, _residual_sentinel(res))
			return nothing
		end

		if sol_opt.retcode != ReturnCode.Success
			fill!(res, _residual_sentinel(res))
			return nothing
		end

		idx = 1
		@inbounds for (j, f) in enumerate(ctx.obs_funcs)
			data_true = ctx.data_targets[j]
			for i in eachindex(ctx.t_vector)
				res[idx] = f(sol_opt.u[i], param_guess) - data_true[i]
				idx += 1
			end
		end
		if use_regularization
			@inbounds for i in eachindex(p_internal)
				res[idx] = penalty_scale * p_internal[i]
				idx += 1
			end
		end
		return nothing
	end

	residual_vec(p_internal) = (r = Vector{eltype(p_internal)}(undef, residual_count); residual!(r, p_internal); r)

	function jacobian!(J, p_internal, _ = nothing)
		ForwardDiff.jacobian!(J, residual_vec, p_internal)
		return nothing
	end

	# --- Initial residual for revert guard ---
	initial_residual = zeros(residual_count)
	residual!(initial_residual, p0_internal)
	initial_norm = norm(initial_residual)

	# --- Solve ---
	candidate_internal = p0_internal
	solver_result = nothing

	if solver_kind === :fastlm_direct
		J0 = zeros(eltype(p0_internal), residual_count, n_unknowns)
		f0 = zeros(eltype(p0_internal), residual_count)
		workspace = FastLevenbergMarquardt.LMWorkspace(copy(p0_internal), f0, J0)
		linear_solver = n_unknowns <= residual_count ? :qr : :cholesky
		fastlm_residual! = (res, u, p) -> begin
			residual!(res, u, p)
			return res
		end
		fastlm_jacobian! = (J, u, p) -> begin
			jacobian!(J, u, p)
			return J
		end
		result = FastLevenbergMarquardt.lmsolve!(
			fastlm_residual!,
			fastlm_jacobian!,
			workspace,
			nothing,
			internal_lb,
			internal_ub;
			solver = linear_solver,
			xtol = lso_x_tol > 0 ? lso_x_tol : ctx.reltol,
			ftol = lso_f_tol > 0 ? lso_f_tol : ctx.reltol,
			gtol = lso_g_tol > 0 ? lso_g_tol : ctx.abstol,
			maxit = maxiters,
		)
		solver_result = result
		candidate_internal = result[1]

	elseif solver_kind === :lso_direct
		problem = LeastSquaresOptim.LeastSquaresProblem(
			x = copy(p0_internal),
			f! = (out, x) -> residual!(out, x, nothing),
			g! = (J, x) -> jacobian!(J, x, nothing),
			output_length = residual_count,
		)
		opt = optimizer_factory()
		result = LeastSquaresOptim.optimize!(
			problem,
			opt;
			x_tol = lso_x_tol > 0 ? lso_x_tol : ctx.reltol,
			f_tol = lso_f_tol > 0 ? lso_f_tol : ctx.reltol,
			g_tol = lso_g_tol > 0 ? lso_g_tol : ctx.abstol,
			iterations = maxiters,
			Δ = lso_delta,
			lower = isnothing(internal_lb) ? eltype(p0_internal)[] : internal_lb,
			upper = isnothing(internal_ub) ? eltype(p0_internal)[] : internal_ub,
		)
		solver_result = result
		candidate_internal = result.minimizer
	else
		throw(ArgumentError("Unknown residual polish solver_kind '$solver_kind' (expected :lso_direct or :fastlm_direct)"))
	end

	# --- Revert guard: keep the seed if the solver made things worse ---
	final_residual = similar(initial_residual)
	residual!(final_residual, candidate_internal)
	final_norm = norm(final_residual)

	p_opt_internal, objective_residual = if isfinite(final_norm) && final_norm <= initial_norm
		candidate_internal, final_residual
	else
		p0_internal, initial_residual
	end

	p_opt = _polish_internal_to_external(p_opt_internal, ctx.coordinate_transforms, ctx.coordinate_shifts)
	ic_opt = p_opt[1:ctx.n_ic]
	param_opt = p_opt[(ctx.n_ic + 1):end]

	prob_final = remake(
		ctx.base_ode_prob;
		u0 = Dict(ctx.unknown_syms .=> ic_opt),
		p = Dict(ctx.param_syms .=> param_opt),
		build_initializeprob = false,
	)
	sol_final = ModelingToolkit.solve(
		prob_final,
		ctx.solver;
		saveat = ctx.t_vector,
		abstol = ctx.abstol,
		reltol = ctx.reltol,
	)

	# Use ONLY the trajectory-fit portion of the residual when reporting err — exclude
	# the λ-augmented rows so the err is comparable across λ values.
	final_obj = sum(abs2, @view objective_residual[1:n_obs_residual])

	states_out = OrderedDict(s => ic_opt[ctx.state_index[s]] for s in ctx.state_syms_out if haskey(ctx.state_index, s))
	params_out = OrderedDict(p => param_opt[ctx.param_index[p]] for p in ctx.param_syms_out if haskey(ctx.param_index, p))

	final_result = ParameterEstimationResult(
		params_out,
		states_out,
		ctx.t_vector[1],
		final_obj,
		nothing,
		length(ctx.t_vector),
		ctx.t_vector[1],
		OrderedDict{Num, Float64}(),
		Set{Num}(),
		sol_final,
	)
	final_result.provenance = ResultProvenance(
		primary_method = :direct_opt,
		post_polish_error = final_obj,
	)
	sync_result_contract!(final_result)
	return final_result, solver_result
end
