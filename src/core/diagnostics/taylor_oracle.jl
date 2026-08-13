# Split 2026-06-10 from the 5,443-line src/core/diagnostics.jl (Phase F2;
# pure content move, functions byte-identical). Part: expression-tree Taylor evaluator, oracle coefficients, derivative accuracy.
"""
Automated deep-dive diagnostic framework for ODEParameterEstimation.

Provides `diagnose(pep)` to generate oracle Taylor-coefficient data,
compare against production interpolants, solve polynomial systems with
both perfect and production data, and report conditioning/sensitivity.
"""

# ─── Expression-tree Taylor coefficient evaluator ─────────────────────

"""
    _taylor_coeffs_expr(expr, state_coeffs, param_vals, t0, max_k)

Recursively evaluate Taylor coefficients of a Symbolics expression tree.
`state_coeffs[i][k+1]` = k-th Taylor coefficient of state i about `t0`.
Returns a `Vector{Float64}` of length `max_k + 1`.
"""
function _taylor_coeffs_expr(
    expr,
    state_coeffs::Dict,   # Num → Vector{Float64}
    param_vals::Dict,      # Num → Float64
    t_var,                 # the independent variable Num
    t0::Float64,
    max_k::Int,
)::Vector{Float64}
    # Unwrap Num to get the underlying SymbolicUtils value
    sym_val = Symbolics.value(expr)

    # --- leaf: pure number (unwrapped or native) ---
    if sym_val isa Real && !(sym_val isa Symbolics.Num)
        c = zeros(max_k + 1)
        c[1] = Float64(sym_val)
        return c
    end

    # --- leaf: parameter ---
    for (p, v) in param_vals
        if isequal(expr, p) || isequal(sym_val, Symbolics.value(p))
            c = zeros(max_k + 1)
            c[1] = v
            return c
        end
    end

    # --- leaf: state variable ---
    for (s, sc) in state_coeffs
        if isequal(expr, s) || isequal(sym_val, Symbolics.value(s))
            return sc[1:max_k+1]
        end
    end

    # --- leaf: independent variable t ---
    if isequal(expr, t_var) || isequal(sym_val, Symbolics.value(t_var))
        c = zeros(max_k + 1)
        c[1] = t0
        if max_k >= 1
            c[2] = 1.0
        end
        return c
    end

    # --- interior node: use SymbolicUtils to dispatch on operation ---
    if !SymbolicUtils.istree(sym_val)
        # Unknown leaf — try to convert to float via Symbolics.value
        c = zeros(max_k + 1)
        try
            c[1] = Float64(sym_val)
        catch
            error("Cannot evaluate Taylor coefficients for leaf expression: $expr (unwrapped: $sym_val, type: $(typeof(sym_val)))")
        end
        return c
    end

    op = SymbolicUtils.operation(sym_val)
    args = SymbolicUtils.arguments(sym_val)

    if op === (+)
        result = zeros(max_k + 1)
        for a in args
            result .+= _taylor_coeffs_expr(Symbolics.wrap(a), state_coeffs, param_vals, t_var, t0, max_k)
        end
        return result
    elseif op === (-)
        if length(args) == 1
            return -_taylor_coeffs_expr(Symbolics.wrap(args[1]), state_coeffs, param_vals, t_var, t0, max_k)
        else
            return _taylor_coeffs_expr(Symbolics.wrap(args[1]), state_coeffs, param_vals, t_var, t0, max_k) .-
                   _taylor_coeffs_expr(Symbolics.wrap(args[2]), state_coeffs, param_vals, t_var, t0, max_k)
        end
    elseif op === (*)
        # Cauchy product, left-fold for n-ary
        result = _taylor_coeffs_expr(Symbolics.wrap(args[1]), state_coeffs, param_vals, t_var, t0, max_k)
        for i in 2:length(args)
            b = _taylor_coeffs_expr(Symbolics.wrap(args[i]), state_coeffs, param_vals, t_var, t0, max_k)
            result = _cauchy_product(result, b, max_k)
        end
        return result
    elseif op === (/)
        num = _taylor_coeffs_expr(Symbolics.wrap(args[1]), state_coeffs, param_vals, t_var, t0, max_k)
        den = _taylor_coeffs_expr(Symbolics.wrap(args[2]), state_coeffs, param_vals, t_var, t0, max_k)
        return _taylor_division(num, den, max_k)
    elseif op === (^)
        base_c = _taylor_coeffs_expr(Symbolics.wrap(args[1]), state_coeffs, param_vals, t_var, t0, max_k)
        # args[2] should be an integer exponent for polynomial RHS.
        # SymbolicUtils may wrap literal integers as BasicSymbolic{SymReal},
        # so unwrap before checking.
        exp_raw = args[2]
        exp_val = try
            Symbolics.value(Symbolics.wrap(exp_raw))
        catch
            exp_raw
        end
        if exp_val isa Integer || (exp_val isa Number && isinteger(exp_val))
            return _taylor_power(base_c, Int(exp_val), max_k)
        else
            error("Non-integer power in Taylor coefficient evaluation: $expr (exponent=$exp_val, type=$(typeof(exp_val)))")
        end
    elseif op === sin
        # Check if argument is c * t (transcendental of time only)
        return _taylor_transcendental(sin, args[1], state_coeffs, param_vals, t_var, t0, max_k)
    elseif op === cos
        return _taylor_transcendental(cos, args[1], state_coeffs, param_vals, t_var, t0, max_k)
    elseif op === exp
        return _taylor_transcendental(exp, args[1], state_coeffs, param_vals, t_var, t0, max_k)
    else
        error("Unsupported operation in Taylor coefficient evaluation: $op in expression $expr")
    end
end

"""
Cauchy product of two Taylor coefficient vectors.
"""
function _cauchy_product(a::Vector{Float64}, b::Vector{Float64}, max_k::Int)
    c = zeros(max_k + 1)
    for k in 0:max_k
        s = 0.0
        for j in 0:k
            s += a[j+1] * b[k-j+1]
        end
        c[k+1] = s
    end
    return c
end

"""
Taylor coefficients of a/b via the recurrence c_k = (a_k - Σ_{j=1}^{k} b_j c_{k-j}) / b_0.
"""
function _taylor_division(num::Vector{Float64}, den::Vector{Float64}, max_k::Int)
    c = zeros(max_k + 1)
    if abs(den[1]) < 1e-300
        error("Division by zero in Taylor coefficient evaluation (den[0] ≈ 0)")
    end
    c[1] = num[1] / den[1]
    for k in 1:max_k
        s = num[k+1]
        for j in 1:k
            s -= den[j+1] * c[k-j+1]
        end
        c[k+1] = s / den[1]
    end
    return c
end

"""
Taylor coefficients of base^n for integer n, via repeated Cauchy product.
"""
function _taylor_power(base::Vector{Float64}, n::Int, max_k::Int)
    if n == 0
        c = zeros(max_k + 1)
        c[1] = 1.0
        return c
    elseif n == 1
        return copy(base)
    elseif n < 0
        # Negative power: base^(-|n|) = 1 / base^|n|
        pos = _taylor_power(base, -n, max_k)
        one_coeffs = zeros(max_k + 1)
        one_coeffs[1] = 1.0
        return _taylor_division(one_coeffs, pos, max_k)
    else
        # Repeated squaring
        if n == 2
            return _cauchy_product(base, base, max_k)
        end
        half = _taylor_power(base, n ÷ 2, max_k)
        result = _cauchy_product(half, half, max_k)
        if isodd(n)
            result = _cauchy_product(result, base, max_k)
        end
        return result
    end
end

"""
Taylor coefficients for transcendental functions of time: sin(c*t), cos(c*t), exp(c*t).
The argument must be of the form `constant * t` (no state dependence).
"""
function _taylor_transcendental(func, arg, state_coeffs, param_vals, t_var, t0, max_k)
    # Evaluate argument Taylor coefficients — must be linear in t only
    arg_coeffs = _taylor_coeffs_expr(Symbolics.wrap(arg), state_coeffs, param_vals, t_var, t0, max_k)

    # The argument should be c*t, so arg_coeffs = [c*t0, c, 0, 0, ...]
    # Check no state dependence (all higher coefficients should be zero)
    ω = arg_coeffs[1]  # value at t0: c * t0

    if func === sin
        c = zeros(max_k + 1)
        for k in 0:max_k
            # k-th derivative of sin(arg) at t0, divided by k!
            # For sin(c*t): d^k/dt^k sin(c*t)|_{t0} = c^k * sin(c*t0 + k*π/2)
            # As Taylor coeff: c^k * sin(c*t0 + k*π/2) / k!
            freq = length(arg_coeffs) >= 2 ? arg_coeffs[2] : 0.0  # this is c (the coefficient of t)
            c[k+1] = freq^k * sin(ω + k * π / 2) / factorial(k)
        end
        return c
    elseif func === cos
        c = zeros(max_k + 1)
        for k in 0:max_k
            freq = length(arg_coeffs) >= 2 ? arg_coeffs[2] : 0.0
            c[k+1] = freq^k * cos(ω + k * π / 2) / factorial(k)
        end
        return c
    elseif func === exp
        c = zeros(max_k + 1)
        for k in 0:max_k
            freq = length(arg_coeffs) >= 2 ? arg_coeffs[2] : 0.0
            c[k+1] = freq^k * exp(ω) / factorial(k)
        end
        return c
    else
        error("Unsupported transcendental function: $func")
    end
end

# ─── Oracle Taylor coefficient computation ────────────────────────────

"""
    _propagate_state_taylor(sys, state_values, param_vals, t_eval, max_order)

Propagate Taylor coefficients of all states about `t_eval` from point values
alone: seed `coeffs[1] = state_values[i]` and recurse through the symbolic
RHS (`x_{k+1} = f_k / (k+1)` via Cauchy products on the expression tree).
No trajectory is needed — the jet of an ODE solution at a point is an
algebraic function of (state values, parameters) at that point.

`state_values` must be ordered like `ModelingToolkit.unknowns(sys)`.
Returns `Dict{Num, Vector{Float64}}` with `coeffs[k+1] = x^(k)(t_eval) / k!`.
"""
function _propagate_state_taylor(
    sys,
    state_values::AbstractVector{<:Real},
    param_vals::Dict{Num, Float64},
    t_eval::Float64,
    max_order::Int,
)
    t_iv = ModelingToolkit.get_iv(sys)
    states = ModelingToolkit.unknowns(sys)
    eqs = ModelingToolkit.equations(sys)
    length(state_values) == length(states) ||
        error("_propagate_state_taylor: got $(length(state_values)) state values for $(length(states)) states")

    state_coeffs = Dict{Num, Vector{Float64}}()
    for (si, s) in enumerate(states)
        c = zeros(max_order + 1)
        c[1] = Float64(state_values[si])
        state_coeffs[s] = c
    end

    # Extract symbolic RHS from each equation: D(x_i) ~ f_i(...)
    rhs_exprs = Num[]
    for eq in eqs
        push!(rhs_exprs, eq.rhs)
    end

    # Recursion — for each order k, compute the (k+1)-th Taylor coefficient
    # x^(k+1)(t_eval) / (k+1)! = f^(k)(t_eval) / (k+1)!
    # The k-th Taylor coefficient of f gives the (k+1)-th of x: x_{k+1} = f_k / (k+1)
    for k in 0:(max_order - 1)
        for (si, s) in enumerate(states)
            rhs_tc = _taylor_coeffs_expr(rhs_exprs[si], state_coeffs, param_vals, Num(t_iv), t_eval, k)
            state_coeffs[s][k+2] = rhs_tc[k+1] / (k + 1)
        end
    end

    return state_coeffs
end

"""
    compute_oracle_taylor_coefficients(pep, t_eval, max_order; kwargs...)

Compute machine-precision Taylor coefficients for all states at `t_eval`
using symbolic RHS recursion (Cauchy products on the expression tree).

Returns `state_coeffs::Dict{Num, Vector{Float64}}` where each vector has
length `max_order + 1` with `coeffs[k+1] = x^(k)(t_eval) / k!`.
"""
function compute_oracle_taylor_coefficients(
    pep::ParameterEstimationProblem,
    t_eval::Float64,
    max_order::Int;
    solver = AutoVern9(Rodas5P()),
    abstol = 1e-14,
    reltol = 1e-14,
    completed_sys = nothing,
    base_ode_problem = nothing,
)
    model = pep.model
    sys = model.system
    states = ModelingToolkit.unknowns(sys)
    params = ModelingToolkit.parameters(sys)

    # Step 1: Solve ODE at high accuracy to get state values at t_eval.
    # The data sample's t-vector is the canonical source of the integration range
    # and covers the requested t_eval by construction. We previously fell back to
    # `pep.recommended_time_interval` and then to `[-0.5, 0.5]`, but every callsite
    # in the codebase passes a sampled PEP, so those fallbacks were dead code that
    # silently masked configuration errors. Refuse to integrate without a data sample.
    if isnothing(pep.data_sample) || !haskey(pep.data_sample, "t")
        error("compute_oracle_taylor_coefficients requires `pep.data_sample` with a \"t\" key (got nothing or no t-vector)")
    end
    t_vec = pep.data_sample["t"]
    tspan = [first(t_vec), last(t_vec)]

    completed_sys = isnothing(completed_sys) ? ModelingToolkit.complete(sys) : completed_sys
    ordered_params = [pep.p_true[p] for p in params]
    ordered_ic = [pep.ic[s] for s in states]
    u0_map = Dict(ModelingToolkit.unknowns(completed_sys) .=> ordered_ic)
    p_map = Dict(ModelingToolkit.parameters(completed_sys) .=> ordered_params)

    prob = if isnothing(base_ode_problem)
        ODEProblem(
            completed_sys,
            merge(u0_map, p_map),
            tspan,
        )
    else
        remake(base_ode_problem; u0 = u0_map, p = p_map, build_initializeprob = false)
    end
    sol = ModelingToolkit.solve(prob, solver; abstol, reltol, dense = true)

    # Step 2: Extract state values at t_eval and propagate jets algebraically
    param_vals = Dict{Num, Float64}()
    for (p, v) in pep.p_true
        param_vals[p] = v
    end

    state_values = Float64[sol(t_eval, idxs = s) for s in states]
    return _propagate_state_taylor(sys, state_values, param_vals, t_eval, max_order)
end

"""
    compute_observable_taylor_coefficients(pep, state_coeffs, t_eval, max_order)

Compute Taylor coefficients for observables from state Taylor coefficients
by walking the observable expression trees.

Returns `Dict{Num, Vector{Float64}}` keyed by observable RHS expressions.
"""
function compute_observable_taylor_coefficients(
    pep::ParameterEstimationProblem,
    state_coeffs::Dict{Num, Vector{Float64}},
    t_eval::Float64,
    max_order::Int,
)
    sys = pep.model.system
    t_iv = ModelingToolkit.get_iv(sys)
    params = ModelingToolkit.parameters(sys)

    param_vals = Dict{Num, Float64}()
    for (p, v) in pep.p_true
        param_vals[p] = v
    end

    obs_coeffs = Dict{Num, Vector{Float64}}()
    for mq in pep.measured_quantities
        obs_rhs = mq.rhs
        tc = _taylor_coeffs_expr(obs_rhs, state_coeffs, param_vals, Num(t_iv), t_eval, max_order)
        # Key by the diff2term'd rhs (same convention as precomputed_interpolants)
        key = ModelingToolkit.diff2term(obs_rhs)
        obs_coeffs[key] = tc
    end

    return obs_coeffs
end

# ─── Estimate-conditioned Taylor coefficients (Stream B, 2026-08) ─────
# The estimate-value siblings of the oracle builders above. They evaluate the
# same jets at the ESTIMATE instead of truth, so the UQ chain can run on real
# data where `pep.p_true`/`pep.ic` are unavailable.

"""
    compute_estimate_taylor_coefficients(pep, estimate, t_eval, max_order)

Estimate-conditioned sibling of [`compute_oracle_taylor_coefficients`](@ref):
Taylor coefficients of all states about `t_eval` evaluated at the estimate.
θ̂ comes from `estimate.parameters` (with `estimate.unident_dict` as fallback
for fixed unidentifiable parameters); x̂(t_eval) is resolved by
`_uq_state_values_at_time` (the estimate's retained trajectory when present,
else a forward solve from its t0 states). Higher orders come from the same
symbolic RHS recursion the oracle uses — no truth values are touched.

Returns `state_coeffs::Dict{Num, Vector{Float64}}` with
`coeffs[k+1] = x̂^(k)(t_eval) / k!`.
"""
function compute_estimate_taylor_coefficients(
    pep::ParameterEstimationProblem,
    estimate::ParameterEstimationResult,
    t_eval::Float64,
    max_order::Int,
)
    if isnothing(pep.data_sample) || !haskey(pep.data_sample, "t")
        error("compute_estimate_taylor_coefficients requires `pep.data_sample` with a \"t\" key")
    end
    sys = pep.model.system
    completed_sys = ModelingToolkit.complete(sys)
    completed_states = ModelingToolkit.unknowns(completed_sys)
    completed_params = ModelingToolkit.parameters(completed_sys)

    param_values = _uq_ordered_result_values(estimate.parameters, completed_params)
    # Unidentifiable parameters may carry their fixed value only in unident_dict
    if !isnothing(estimate.unident_dict)
        fallback = _uq_ordered_result_values(estimate.unident_dict, completed_params)
        for i in eachindex(param_values)
            isfinite(param_values[i]) || (param_values[i] = fallback[i])
        end
    end
    any(!isfinite, param_values) &&
        error("compute_estimate_taylor_coefficients: estimate is missing finite values for some model parameters")

    t0 = Float64(pep.data_sample["t"][1])
    x_at_eval = _uq_state_values_at_time(
        pep, estimate, completed_sys, completed_states, completed_params,
        param_values, t0, t_eval,
    )

    # Order the anchor like unknowns(sys) (the propagation ordering) via cleaned names
    by_name = Dict(_uq_clean_name(s) => x_at_eval[i] for (i, s) in enumerate(completed_states))
    states = ModelingToolkit.unknowns(sys)
    state_values = Float64[get(by_name, _uq_clean_name(s), NaN) for s in states]
    any(!isfinite, state_values) &&
        error("compute_estimate_taylor_coefficients: could not resolve estimate state values at t = $t_eval")

    param_vals = Dict{Num, Float64}()
    for (i, p) in enumerate(completed_params)
        param_vals[p] = param_values[i]
    end

    return _propagate_state_taylor(sys, state_values, param_vals, t_eval, max_order)
end

"""
    interpolant_taylor_coefficients(pep, interpolants, t_eval, max_order)

Taylor-coefficient-shaped view of the production interpolants' jets:
`coeffs[k+1] = interp^(k)(t_eval) / k!`, keyed like `precomputed_interpolants`
(by `diff2term`'d observable RHS). These are the observation-derivative values
the solver actually consumed — the estimate-conditioned replacement for
`compute_observable_taylor_coefficients` (which requires truth).
"""
function interpolant_taylor_coefficients(
    pep::ParameterEstimationProblem,
    interpolants::AbstractDict,
    t_eval::Float64,
    max_order::Int,
)
    obs_coeffs = Dict{Num, Vector{Float64}}()
    for mq in pep.measured_quantities
        key = ModelingToolkit.diff2term(mq.rhs)
        haskey(interpolants, key) || continue
        interp = interpolants[key]
        tc = zeros(max_order + 1)
        all_finite = true
        for k in 0:max_order
            val = try
                Float64(nth_deriv(x -> interp(x), k, t_eval))
            catch
                NaN
            end
            isfinite(val) || (all_finite = false)
            tc[k+1] = val / factorial(k)
        end
        all_finite ||
            @warn "[UQ] Non-finite interpolant jet for $(mq.lhs) at t = $t_eval (orders ≤ $max_order)"
        obs_coeffs[key] = tc
    end
    return obs_coeffs
end

"""
    build_perfect_interpolants(pep, t_eval, max_order; kwargs...)

Build `Dict{Num, PerfectInterpolant}` keyed the same way as `precomputed_interpolants`.
Each PerfectInterpolant stores oracle Taylor coefficients and evaluates via Horner.
"""
function build_perfect_interpolants(
    pep::ParameterEstimationProblem,
    t_eval::Float64,
    max_order::Int;
    kwargs...,
)
    state_coeffs = compute_oracle_taylor_coefficients(pep, t_eval, max_order; kwargs...)
    obs_coeffs = compute_observable_taylor_coefficients(pep, state_coeffs, t_eval, max_order)

    perfect = Dict{Num, PerfectInterpolant}()
    for (key, tc) in obs_coeffs
        perfect[key] = PerfectInterpolant(t_eval, tc)
    end

    return perfect
end

# ─── Derivative accuracy diagnosis ────────────────────────────────────

"""
    diagnose_derivative_accuracy(pep; interpolator, kwargs...) → DerivativeAccuracyReport

Compare oracle Taylor derivatives against production interpolant derivatives
for every (observable, derivative order) pair required by the SI template.
"""
function diagnose_derivative_accuracy(
    pep::ParameterEstimationProblem;
    interpolator = agp_gpr_robust,
    setup_data = nothing,
    t_eval::Union{Nothing, Float64} = nothing,
    max_order::Union{Nothing, Int} = nothing,
    interpolator_name::String = "unknown",
    kwargs...,
)
    # Get setup data (SIAN + interpolants) if not provided.
    # When building setup_data here, also auto-handle transcendentals so direct
    # callers don't need to pre-transform. transform_pep_for_estimation is idempotent.
    if isnothing(setup_data)
        t_var_for_trfn = ModelingToolkit.get_iv(pep.model.system)
        pep, _ = try
            transform_pep_for_estimation(pep, t_var_for_trfn)
        catch e
            @warn "[DIAGNOSE_DERIV] Transcendental transform failed (may not be needed): $e"
            (pep, nothing)
        end
        setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)
    end

    # Determine evaluation point
    if isnothing(t_eval)
        t_vec = pep.data_sample["t"]
        idx = setup_data.time_index_set[1]
        t_eval = t_vec[idx]
    end

    # Determine max derivative order needed
    if isnothing(max_order)
        max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))
    end

    # Build oracle interpolants
    perfect = build_perfect_interpolants(pep, t_eval, max_order + 2; kwargs...)

    # Compare against production interpolants
    entries = @NamedTuple{obs::String, order::Int, true_val::Float64, interp_val::Float64, rel_error::Float64}[]

    worst_obs = ""
    worst_order = 0
    worst_rel_error = 0.0

    for (obs_idx, mq) in enumerate(pep.measured_quantities)
        obs_rhs = ModelingToolkit.diff2term(mq.rhs)
        obs_name = string(mq.lhs)

        # Skip _trfn_ auxiliary observables — these are analytically known functions
        # of time (sin/cos/exp) added by transform_pep_for_estimation.  Their
        # "derivative accuracy" is irrelevant to the estimation problem.
        if startswith(replace(obs_name, r"\(.*\)" => ""), "_obs_trfn_")
            continue
        end

        perf_interp = perfect[obs_rhs]
        prod_interp = setup_data.interpolants[obs_rhs]

        for order in 0:max_order
            true_val = nth_deriv(x -> perf_interp(x), order, t_eval)
            interp_val = try
                nth_deriv(x -> prod_interp(x), order, t_eval)
            catch
                NaN
            end

            # Relative error guard: when the true value is effectively zero
            # (e.g. derivatives of conserved quantities), dividing by a tiny
            # epsilon inflates pure numerical noise into "10500%" artefacts.
            # Fall back to absolute error in that regime — the metric is
            # consumed via thresholds like 1%/10%, and ~1e-13 absolute is
            # correctly classified as "easy".
            abs_err = abs(true_val - interp_val)
            rel_err = abs(true_val) < 1e-10 ? abs_err : abs_err / abs(true_val)

            push!(entries, (obs = obs_name, order = order, true_val = true_val, interp_val = interp_val, rel_error = rel_err))

            if rel_err > worst_rel_error
                worst_rel_error = rel_err
                worst_obs = obs_name
                worst_order = order
            end
        end
    end

    return DerivativeAccuracyReport(
        pep.name, t_eval, max_order, entries,
        worst_obs, worst_order, worst_rel_error,
        interpolator_name,
    )
end

