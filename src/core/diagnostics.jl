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
    solver = AutoVern9(Rodas4P()),
    abstol = 1e-14,
    reltol = 1e-14,
)
    model = pep.model
    sys = model.system
    t_iv = ModelingToolkit.get_iv(sys)
    states = ModelingToolkit.unknowns(sys)
    params = ModelingToolkit.parameters(sys)
    eqs = ModelingToolkit.equations(sys)

    # Step 1: Solve ODE at high accuracy to get state values at t_eval
    tspan = pep.recommended_time_interval
    if isnothing(tspan) || isnothing(pep.data_sample)
        tspan = [-0.5, 0.5]
    else
        t_vec = pep.data_sample["t"]
        tspan = [first(t_vec), last(t_vec)]
    end

    completed_sys = ModelingToolkit.complete(sys)
    ordered_params = [pep.p_true[p] for p in params]
    ordered_ic = [pep.ic[s] for s in states]

    prob = ODEProblem(
        completed_sys,
        merge(
            Dict(ModelingToolkit.unknowns(completed_sys) .=> ordered_ic),
            Dict(ModelingToolkit.parameters(completed_sys) .=> ordered_params),
        ),
        tspan,
    )
    sol = ModelingToolkit.solve(prob, solver; abstol, reltol, dense = true)

    # Step 2: Extract state values at t_eval
    param_vals = Dict{Num, Float64}()
    for (p, v) in pep.p_true
        param_vals[p] = v
    end

    state_coeffs = Dict{Num, Vector{Float64}}()
    for s in states
        c = zeros(max_order + 1)
        c[1] = sol(t_eval, idxs = s)
        state_coeffs[s] = c
    end

    # Step 3: Extract symbolic RHS from each equation: D(x_i) ~ f_i(...)
    rhs_exprs = Num[]
    for eq in eqs
        push!(rhs_exprs, eq.rhs)
    end

    # Step 4: Recursion — for each order k, compute the (k+1)-th Taylor coefficient
    # x^(k+1)(t0) / (k+1)! = f^(k)(t0) / (k+1)!
    # But f^(k) as Taylor coeff = (Taylor coeff of f at order k)
    # So state_coeffs[i][k+2] = f_taylor_coeffs[i][k+1] / (k+1)
    for k in 0:(max_order - 1)
        # Compute Taylor coefficients of each RHS expression using current state_coeffs
        for (si, s) in enumerate(states)
            rhs_tc = _taylor_coeffs_expr(rhs_exprs[si], state_coeffs, param_vals, Num(t_iv), t_eval, k)
            # The k-th Taylor coefficient of f gives us the (k+1)-th of x:
            # x_{k+1} = f_k / (k+1)
            state_coeffs[s][k+2] = rhs_tc[k+1] / (k + 1)
        end
    end

    return state_coeffs
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
    # Get setup data (SIAN + interpolants) if not provided
    if isnothing(setup_data)
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

            denom = max(abs(true_val), 1e-15)
            rel_err = abs(true_val - interp_val) / denom

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

# ─── Variable classification ───────────────────────────────────────────

"""
    _classify_polynomial_variables(var_names, pep)

Classify each variable name in the polynomial system into a role:
  :parameter, :state_ic, :state_derivative, :data_derivative, :transcendental

Uses `parse_derivative_variable_name` to decompose SIAN-style names (e.g. `x1_0`, `y1_2`).
"""
function _classify_polynomial_variables(var_names::Vector{String}, pep::ParameterEstimationProblem)
    roles = Dict{String, Symbol}()

    # Build lookup sets
    param_bases = Set{String}()
    for p in keys(pep.p_true)
        push!(param_bases, replace(string(p), "(t)" => ""))
    end
    state_bases = Set{String}()
    for s in keys(pep.ic)
        push!(state_bases, replace(string(s), "(t)" => ""))
    end
    obs_bases = Set{String}()
    for mq in pep.measured_quantities
        obs_name = replace(string(mq.lhs), "(t)" => "")
        # Strip _obs_trfn_ prefix for matching
        if !startswith(obs_name, "_obs_trfn_")
            push!(obs_bases, obs_name)
        end
    end

    for vn in var_names
        # Check transcendental first
        if contains(vn, "_trfn_")
            roles[vn] = :transcendental
            continue
        end

        parsed = parse_derivative_variable_name(vn)
        if !isnothing(parsed)
            base_name, deriv_order = parsed

            # Parameter (order 0 only in SI template)
            if base_name in param_bases && deriv_order == 0
                roles[vn] = :parameter
                continue
            end

            # State IC (order 0) or state derivative (order > 0)
            if base_name in state_bases
                roles[vn] = deriv_order == 0 ? :state_ic : :state_derivative
                continue
            end

            # Observable derivative (data variable)
            if base_name in obs_bases
                roles[vn] = :data_derivative
                continue
            end
        end

        # Direct parameter match (no _N suffix)
        if vn in param_bases
            roles[vn] = :parameter
            continue
        end

        # Direct state match
        if vn in state_bases
            roles[vn] = :state_ic
            continue
        end

        # Default to state_derivative (unknown role)
        roles[vn] = :state_derivative
    end

    return roles
end

"""
    _equations_to_strings(equations)

Convert symbolic equations to human-readable strings.
"""
function _equations_to_strings(equations)
    return [string(eq) * " = 0" for eq in equations]
end

# ─── Polynomial feasibility diagnosis ─────────────────────────────────

"""
    diagnose_polynomial_system(pep; kwargs...) → PolynomialFeasibilityReport

Build the SI polynomial system with both perfect (oracle) and production
interpolant data, solve both with HC.jl, and compare solution counts,
residuals, and distances to the true parameter values.
"""
function diagnose_polynomial_system(
    pep::ParameterEstimationProblem;
    interpolator = agp_gpr_robust,
    setup_data = nothing,
    t_eval::Union{Nothing, Float64} = nothing,
    max_order::Union{Nothing, Int} = nothing,
    kwargs...,
)
    if isnothing(setup_data)
        setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)
    end

    t_vec = pep.data_sample["t"]
    if isnothing(t_eval)
        idx = setup_data.time_index_set[1]
        t_eval = t_vec[idx]
    end
    time_idx = argmin(abs.(t_vec .- t_eval))

    if isnothing(max_order)
        max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))
    end

    model = pep.model.system
    mq = pep.measured_quantities

    # Compute oracle Taylor coefficients for true-value lookup
    state_taylor = compute_oracle_taylor_coefficients(pep, t_eval, max_order + 2; kwargs...)
    obs_taylor = compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_order + 2)

    # Build perfect interpolants from oracle data
    perfect_interps = Dict{Num, PerfectInterpolant}()
    for (key, tc) in obs_taylor
        perfect_interps[key] = PerfectInterpolant(t_eval, tc)
    end

    # Build polynomial system with PRODUCTION interpolants
    prod_eqs, prod_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = setup_data.interpolants,
    )

    # Build polynomial system with PERFECT interpolants
    perf_eqs, perf_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = perfect_interps,
    )

    n_eqs = length(prod_eqs)
    n_vars = length(prod_vars)
    is_square = n_eqs == n_vars
    var_names = string.(prod_vars)

    # Solve both systems
    prod_solutions = Vector{Float64}[]
    perf_solutions = Vector{Float64}[]

    if is_square && n_vars > 0
        try
            prod_solutions, _, _, _ = solve_with_hc(prod_eqs, prod_vars)
        catch e
            @warn "[DIAG] HC.jl failed on production system: $e"
        end
        try
            perf_solutions, _, _, _ = solve_with_hc(perf_eqs, perf_vars)
        catch e
            @warn "[DIAG] HC.jl failed on perfect system: $e"
        end
    end

    # Map variable names to true values (using oracle Taylor for derivative vars)
    true_vals = _build_true_value_vector(pep, prod_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)

    # Compute residuals at true values
    true_res_prod = _compute_residual(prod_eqs, prod_vars, true_vals)
    true_res_perf = _compute_residual(perf_eqs, perf_vars, true_vals)

    # Closest solution distance
    dist_prod = _closest_solution_distance(prod_solutions, true_vals)
    dist_perf = _closest_solution_distance(perf_solutions, true_vals)

    # Classify variables and store equation strings
    eq_strings = _equations_to_strings(prod_eqs)
    var_roles = _classify_polynomial_variables(var_names, pep)

    return PolynomialFeasibilityReport(
        pep.name, n_eqs, n_vars, is_square,
        length(perf_solutions), length(prod_solutions),
        true_res_perf, true_res_prod,
        dist_perf, dist_prod,
        var_names, eq_strings, var_roles,
    )
end

"""
Build a vector of true values in the order of `varlist` by matching
variable names to parameters, states, and their derivatives.
Uses oracle Taylor coefficients to resolve derivative variables (e.g., x1_1, x2_2).
"""
function _build_true_value_vector(pep::ParameterEstimationProblem, varlist;
    state_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    obs_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    t_eval::Float64 = 0.0,
)
    true_vals = Float64[]
    for v in varlist
        val = _lookup_true_value(pep, v; state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)
        push!(true_vals, val)
    end
    return true_vals
end

function _lookup_true_value(pep::ParameterEstimationProblem, var;
    state_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    obs_taylor::Union{Nothing, Dict{Num, Vector{Float64}}} = nothing,
    t_eval::Float64 = 0.0,
)
    # Direct parameter match
    for (p, v) in pep.p_true
        if isequal(var, p)
            return v
        end
    end
    # Direct state match
    for (s, v) in pep.ic
        if isequal(var, s)
            return v
        end
    end

    var_name = string(var)

    # Check bare _obs_trfn_ names (Symbolics form, no _N suffix) before parsing
    clean_name = replace(var_name, r"\(.*\)" => "")
    obs_trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_eval)
    if !isnothing(obs_trfn_val)
        return obs_trfn_val
    end

    # Try parse as derivative variable (e.g., y1_0, x1_0, x2_2)
    parsed = parse_derivative_variable_name(var_name)
    if !isnothing(parsed)
        base_name, deriv_order = parsed

        # Check if it's a _trfn_ or _obs_trfn_ variable
        trfn_val = evaluate_trfn_template_variable(var_name, t_eval)
        if isnothing(trfn_val)
            trfn_val = evaluate_obs_trfn_template_variable(var_name, t_eval)
        end
        if !isnothing(trfn_val)
            return trfn_val
        end

        # Match against parameters by base name (order 0 only)
        for (p, v) in pep.p_true
            p_str = string(p)
            p_base = replace(p_str, "(t)" => "")
            if p_base == base_name && deriv_order == 0
                return v
            end
        end

        # Match against states by base name — use Taylor coefficients for all orders
        # SIAN variables store actual derivatives f^(k)(t_eval), not Taylor coeffs f^(k)(t0)/k!
        # Taylor coeffs are at t_eval, so tc[k+1] * k! = f^(k)(t_eval)
        for (s, v) in pep.ic
            s_str = string(s)
            s_base = replace(s_str, "(t)" => "")
            if s_base == base_name
                if !isnothing(state_taylor) && haskey(state_taylor, s)
                    tc = state_taylor[s]
                    if deriv_order + 1 <= length(tc)
                        return tc[deriv_order + 1] * factorial(deriv_order)
                    end
                end
                # Fallback: IC only valid for order 0 at t=0
                if deriv_order == 0
                    return v
                end
            end
        end

        # Match against observable names — use observable Taylor coefficients
        if !isnothing(obs_taylor)
            for mq in pep.measured_quantities
                obs_lhs_name = replace(string(mq.lhs), "(t)" => "")
                if obs_lhs_name == base_name
                    key = ModelingToolkit.diff2term(mq.rhs)
                    if haskey(obs_taylor, key)
                        tc = obs_taylor[key]
                        if deriv_order + 1 <= length(tc)
                            return tc[deriv_order + 1] * factorial(deriv_order)
                        end
                    end
                end
            end
        end
    end

    # Unknown variable — return NaN
    @warn "[DIAG] Could not find true value for variable: $var"
    return NaN
end

function _compute_residual(equations, varlist, vals)
    if isempty(equations) || isempty(vals) || any(isnan, vals)
        return NaN
    end
    try
        f = _compile_system_function(equations, varlist)
        r = f(vals)
        return norm(r)
    catch
        # Fallback to substitution
        subst_dict = Dict(varlist[i] => vals[i] for i in eachindex(varlist))
        total = 0.0
        for eq in equations
            r = try
                Float64(Symbolics.value(Symbolics.substitute(eq, subst_dict)))
            catch
                NaN
            end
            total += r^2
        end
        return sqrt(total)
    end
end

function _closest_solution_distance(solutions, true_vals)
    if isempty(solutions) || any(isnan, true_vals)
        return Inf
    end
    min_dist = Inf
    for sol in solutions
        d = norm(sol .- true_vals)
        min_dist = min(min_dist, d)
    end
    return min_dist
end

# ─── Sensitivity analysis ─────────────────────────────────────────────

"""
    diagnose_sensitivity(pep; kwargs...) → SensitivityReport

Compute Jacobian conditioning at the true solution and root displacement
between perfect and production polynomial systems.
"""
function diagnose_sensitivity(
    pep::ParameterEstimationProblem;
    interpolator = agp_gpr_robust,
    setup_data = nothing,
    poly_report::Union{Nothing, PolynomialFeasibilityReport} = nothing,
    t_eval::Union{Nothing, Float64} = nothing,
    max_order::Union{Nothing, Int} = nothing,
    kwargs...,
)
    if isnothing(setup_data)
        setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)
    end

    t_vec = pep.data_sample["t"]
    if isnothing(t_eval)
        idx = setup_data.time_index_set[1]
        t_eval = t_vec[idx]
    end
    time_idx = argmin(abs.(t_vec .- t_eval))

    if isnothing(max_order)
        max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))
    end

    model = pep.model.system
    mq = pep.measured_quantities

    # Compute oracle Taylor for true-value lookup
    state_taylor = compute_oracle_taylor_coefficients(pep, t_eval, max_order + 2; kwargs...)
    obs_taylor = compute_observable_taylor_coefficients(pep, state_taylor, t_eval, max_order + 2)

    # Build production system to get equations + varlist
    prod_eqs, prod_vars = construct_equation_system_from_si_template(
        model, mq, pep.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator = interpolator,
        time_index_set = [time_idx],
        precomputed_interpolants = setup_data.interpolants,
    )

    true_vals = _build_true_value_vector(pep, prod_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)
    n_vars = length(prod_vars)

    # Compute Jacobian via ForwardDiff on a compiled system function
    jac_cond = NaN
    eff_rank = 0
    svs = Float64[]
    J_matrix = Matrix{Float64}(undef, 0, 0)

    if n_vars > 0 && !any(isnan, true_vals)
        try
            sys_fn = _compile_system_function(prod_eqs, prod_vars)
            J = ForwardDiff.jacobian(sys_fn, true_vals)
            J_matrix = J

            sv = svd(J)
            svs = sv.S
            jac_cond = length(svs) > 0 ? svs[1] / max(svs[end], 1e-300) : NaN
            eff_rank = count(s -> s > 1e-10 * svs[1], svs)
        catch e
            @warn "[DIAG] Jacobian computation failed: $e"
        end
    end

    # Root displacement: ||sol_prod - sol_perf|| / ||data_prod - data_perf||
    root_sens = NaN
    if !isnothing(poly_report) && isfinite(poly_report.closest_distance_production) && isfinite(poly_report.closest_distance_perfect)
        data_diff = abs(poly_report.true_residual_production - poly_report.true_residual_perfect)
        if data_diff > 1e-300
            root_sens = abs(poly_report.closest_distance_production - poly_report.closest_distance_perfect) / data_diff
        end
    end

    # Build Jacobian labels and variable roles
    eq_labels = ["Eq $i" for i in 1:length(prod_eqs)]
    var_names = [string(v) for v in prod_vars]
    var_roles = _classify_polynomial_variables(var_names, pep)

    # ── Parameter-data sensitivity: dx*/dd via implicit function theorem ──
    S_matrix = Matrix{Float64}(undef, 0, 0)
    data_labels = String[]
    data_roles = Dict{String, Symbol}()
    unknown_labels = String[]
    unknown_roles = Dict{String, Symbol}()

    try
        S_matrix, data_labels, data_roles, unknown_labels, unknown_roles = _compute_data_sensitivity(
            pep, setup_data, t_eval, prod_vars, true_vals;
            state_taylor = state_taylor, obs_taylor = obs_taylor, kwargs...)
    catch e
        @warn "[DIAG] Data sensitivity computation failed: $e"
    end

    return SensitivityReport(pep.name, jac_cond, eff_rank, svs, root_sens,
        J_matrix, eq_labels, var_names, var_roles,
        S_matrix, data_labels, data_roles, unknown_labels, unknown_roles)
end

"""
    _compute_data_sensitivity(pep, setup_data, t_eval, prod_vars, true_vals; kwargs...)

Compute the parameter-data sensitivity matrix S = -(∂F/∂x)⁻¹ · (∂F/∂d) via the
implicit function theorem.  Here F(x, d) = 0 is the SI polynomial system, x are
the unknowns (params, ICs, state derivatives), and d are the data variables
(interpolated observable derivatives).

S[i,j] tells you: a unit perturbation in data variable j causes S[i,j] displacement
in unknown i.  This directly quantifies how interpolation errors propagate to
recovered parameter values.

Returns `(S_matrix, data_labels, data_roles)`.
"""
function _compute_data_sensitivity(
    pep::ParameterEstimationProblem,
    setup_data,
    t_eval::Float64,
    prod_vars,
    true_vals;
    state_taylor = nothing,
    obs_taylor = nothing,
    kwargs...,
)
    model = pep.model.system
    mq = pep.measured_quantities
    DD = setup_data.good_DD

    # Step 1: Get SI template equations (pre-substitution)
    ordered_model = if isa(model, OrderedODESystem)
        model
    else
        (_, _, model_states, model_ps) = unpack_ODE(model)
        OrderedODESystem(model, model_states, model_ps)
    end

    template_equations, derivative_dict, _, _, _, _ = get_si_equation_system(
        ordered_model, mq, pep.data_sample;
        DD = DD, infolevel = 0,
    )
    template_DD = ensure_si_template_dd_support(ordered_model, mq, DD, derivative_dict)

    # Step 2: Collect all variables from template equations
    all_template_vars = OrderedCollections.OrderedSet{Any}()
    for eq in template_equations
        union!(all_template_vars, Symbolics.get_variables(eq))
    end

    # Step 3: Identify data variables from DD.obs_lhs
    data_var_set = Set{Any}()
    for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
        for v in level_vars
            if v in all_template_vars
                push!(data_var_set, v)
            end
        end
    end

    # Step 4: Substitute _trfn_ vars only (known functions of time, not data)
    t_vec = pep.data_sample["t"]
    time_idx = argmin(abs.(t_vec .- t_eval))
    t_point = t_vec[time_idx]

    trfn_subst = Dict{Any, Any}()
    trfn_substituted_vars = Set{Any}()
    for v in all_template_vars
        vname = string(v)
        trfn_val = evaluate_trfn_template_variable(vname, t_point)
        if isnothing(trfn_val)
            # Also try _obs_trfn_ pattern (observable wrappers for transcendental inputs)
            trfn_val = evaluate_obs_trfn_template_variable(vname, t_point)
        end
        if !isnothing(trfn_val)
            trfn_subst[v] = trfn_val
            push!(trfn_substituted_vars, v)
        end
    end

    working_equations = if !isempty(trfn_subst)
        Symbolics.substitute.(template_equations, Ref(trfn_subst))
    else
        template_equations
    end

    # Remove trivial equations (0 variables after _trfn_ substitution)
    kept_equations = eltype(working_equations)[]
    for eq in working_equations
        if !isempty(Symbolics.get_variables(eq))
            push!(kept_equations, eq)
        end
    end

    if isempty(kept_equations)
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Re-collect variables after substitution
    remaining_vars = OrderedCollections.OrderedSet{Any}()
    for eq in kept_equations
        union!(remaining_vars, Symbolics.get_variables(eq))
    end

    # Step 5: Separate unknowns (solved-for) and data (interpolated) variables
    # Remove _trfn_/_obs_trfn_ vars from data set (they're known functions, not data)
    for v in trfn_substituted_vars
        delete!(data_var_set, v)
    end
    # Template vars and prod_vars may be different Symbolics objects with the same name,
    # so use isequal for matching (structural comparison, not reference equality).
    data_var_names = Set(string(v) for v in data_var_set)
    unknown_vars = [v for v in remaining_vars if !(string(v) in data_var_names)]
    data_vars = [v for v in remaining_vars if string(v) in data_var_names]

    n_x = length(unknown_vars)
    n_d = length(data_vars)

    if n_x == 0 || n_d == 0
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Step 6: Build true values for all variables
    # Unknowns use _build_true_value_vector (SIAN naming).
    # Data vars use oracle Taylor coefficients directly via DD.obs_lhs mapping.
    unknown_true = _build_true_value_vector(pep, unknown_vars;
        state_taylor = state_taylor, obs_taylor = obs_taylor, t_eval = t_eval)

    # Build oracle values for data variables from obs_taylor
    data_true = Float64[]
    for v in data_vars
        val = NaN
        # Match data variable against DD.obs_lhs to find (obs_idx, deriv_level)
        for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
            deriv_level = level_idx - 1
            for (obs_idx, lhs_var) in enumerate(level_vars)
                if isequal(v, lhs_var)
                    # Get oracle value: obs_taylor gives Taylor coefficients
                    # Taylor coeff[k+1] * k! = f^(k)(t_eval)
                    if !isnothing(obs_taylor) && obs_idx <= length(mq)
                        obs_rhs_key = ModelingToolkit.diff2term(mq[obs_idx].rhs)
                        if haskey(obs_taylor, obs_rhs_key)
                            tc = obs_taylor[obs_rhs_key]
                            if deriv_level + 1 <= length(tc)
                                val = tc[deriv_level + 1] * factorial(deriv_level)
                            end
                        end
                    end
                    @goto found_data_val
                end
            end
        end
        @label found_data_val
        push!(data_true, val)
    end

    combined_vars = [unknown_vars..., data_vars...]
    combined_true = [unknown_true..., data_true...]

    if any(isnan, combined_true)
        @warn "[DIAG] NaN in combined true values for data sensitivity" nan_count = count(isnan, combined_true)
        return Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}()
    end

    # Step 7: Build combined function and compute full Jacobian
    combined_fn = _compile_system_function(kept_equations, combined_vars)
    J_full = ForwardDiff.jacobian(combined_fn, combined_true)

    # Partition: J_x = J_full[:, 1:n_x], J_d = J_full[:, n_x+1:end]
    J_x = J_full[:, 1:n_x]
    J_d = J_full[:, (n_x + 1):end]

    # Step 8: IFT: S = -(J_x \ J_d)  or pinv for ill-conditioned systems
    cond_Jx = try
        svs_x = svd(J_x).S
        length(svs_x) > 0 ? svs_x[1] / max(svs_x[end], 1e-300) : Inf
    catch
        Inf
    end

    S = if cond_Jx > 1e6
        -(pinv(J_x) * J_d)
    else
        -(J_x \ J_d)
    end

    # Build labels and roles
    d_labels = [string(v) for v in data_vars]
    d_roles = _classify_polynomial_variables(d_labels, pep)
    x_labels = [string(v) for v in unknown_vars]
    x_roles = _classify_polynomial_variables(x_labels, pep)

    return S, d_labels, d_roles, x_labels, x_roles
end

"""
Compile a vector of symbolic equations into a callable `f(x) → Vector{Float64}`
via `Symbolics.build_function`. Falls back to substitution-based evaluation.
The compiled function is compatible with ForwardDiff dual numbers.
"""
function _compile_system_function(equations, varlist)
    try
        # build_function with expression=Val(false) returns a compiled Julia function
        fn = Symbolics.build_function(equations, varlist; expression = Val(false))
        # build_function returns (out-of-place, in-place); take out-of-place
        f_oop = fn isa Tuple ? fn[1] : fn
        return f_oop
    catch e
        @warn "[DIAG] build_function failed, using substitution fallback: $e"
        # Fallback: closure over symbolic substitution (works but no AD)
        return function (vals)
            subst_dict = Dict(varlist[i] => vals[i] for i in eachindex(varlist))
            result = zeros(eltype(vals), length(equations))
            for (i, eq) in enumerate(equations)
                result[i] = try
                    Float64(Symbolics.value(Symbolics.substitute(eq, subst_dict)))
                catch
                    eltype(vals)(NaN)
                end
            end
            return result
        end
    end
end

# ─── Default interpolators for multi-interpolator sweep ────────────────

const _DIAGNOSTIC_DEFAULT_INTERPOLATORS = [
    InterpolatorAAADGPR,     # production default (rational + GP)
    InterpolatorAAAD,        # pure rational (best for stiff/boundary)
    InterpolatorAGPRobust,   # robust GP (good for smooth data)
    InterpolatorFHD,         # Floater-Hormann finite differences (baseline)
]

# ─── Top-level orchestrator ───────────────────────────────────────────

"""
    diagnose(pep; kwargs...) → DiagnosticReport | ComprehensiveDiagnosticReport

Run the full diagnostic pipeline on a `ParameterEstimationProblem`.

## Single-point mode (default, backward compatible)
    diagnose(pep)
    diagnose(pep; interpolator = aaad_gpr_pivot)

Returns a `DiagnosticReport`.

## Multi-point / multi-interpolator mode
    diagnose(pep; t_eval_points = [0.0, 5.0, 10.0])
    diagnose(pep; interpolators = [InterpolatorAAAD, InterpolatorAGPRobust])
    diagnose(pep; t_eval_points = [...], interpolators = [...])

Returns a `ComprehensiveDiagnosticReport` with a derivative accuracy grid
across all (interpolator, evaluation point) combinations.  The full 3-stage
pipeline (polynomial feasibility + sensitivity) runs for the best combination.

## Keyword arguments
- `interpolator`: Single interpolator function (default: `aaad_gpr_pivot`).
- `interpolators`: Vector of `InterpolatorMethod` enums for multi-interpolator sweep.
- `t_eval_points`: Vector of evaluation times.  Empty → production shooting points.
- `full_analysis`: Controls how many points get the full 3-stage pipeline.
  - `:best` (default) — only the best (interpolator, point) combination
  - `:top3` — top 3 best-derivative-accuracy points
  - `:all` — every shooting point
  - `Int` — top N points
  - `Vector{Float64}` — specific time points
- `save_to_disk`: Write text/CSV/HTML to `artifacts/diagnostics/`.
- `html_report`: Generate collapsible-section HTML report (default: `true`).
"""
function diagnose(
    pep::ParameterEstimationProblem;
    interpolator = aaad_gpr_pivot,
    interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[],
    t_eval_points::Vector{Float64} = Float64[],
    full_analysis::Union{Symbol, Int, Vector{Float64}} = :best,
    save_to_disk = true,
    html_report = true,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing,
    kwargs...,
)
    multi_mode = !isempty(interpolators) || !isempty(t_eval_points)

    if multi_mode
        return _diagnose_comprehensive(pep;
            interpolator = interpolator,
            interpolators = interpolators,
            t_eval_points = t_eval_points,
            full_analysis = full_analysis,
            save_to_disk = save_to_disk,
            html_report = html_report,
            estimation_report = estimation_report,
            data_config = data_config,
            kwargs...)
    end

    # ── Single-point mode (backward compatible) ────────────────────────
    @info "[DIAGNOSE] Starting diagnostic for model: $(pep.name)"

    setup_data = setup_parameter_estimation(pep; interpolator = interpolator, nooutput = true)

    t_vec = pep.data_sample["t"]
    t_eval = t_vec[setup_data.time_index_set[1]]
    max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))

    # Derive interpolator name from function
    _interp_name = try
        s = string(interpolator)
        # Strip module prefix if present (e.g. "ODEParameterEstimation.agp_gpr_robust" → "agp_gpr_robust")
        last(split(s, '.'))
    catch
        "unknown"
    end

    @info "[DIAGNOSE] Stage 1: Derivative accuracy analysis..."
    deriv_report = diagnose_derivative_accuracy(pep;
        setup_data = setup_data, t_eval = t_eval, max_order = max_order,
        interpolator_name = _interp_name, kwargs...)

    @info "[DIAGNOSE] Stage 2: Polynomial feasibility analysis..."
    poly_report = diagnose_polynomial_system(pep;
        setup_data = setup_data, t_eval = t_eval, max_order = max_order, kwargs...)

    @info "[DIAGNOSE] Stage 3: Sensitivity analysis..."
    sens_report = diagnose_sensitivity(pep;
        setup_data = setup_data, poly_report = poly_report,
        t_eval = t_eval, max_order = max_order, kwargs...)

    difficulty, bottleneck = _classify_difficulty(deriv_report, poly_report, sens_report)

    report = DiagnosticReport(
        pep.name, deriv_report, poly_report, sens_report,
        difficulty, bottleneck, Dates.now(),
    )

    _print_diagnostic_summary(report)
    if save_to_disk
        _save_diagnostic_report(report)
        if html_report
            _save_diagnostic_html(report; pep = pep)
        end
    end

    return report
end

# ─── Comprehensive multi-point / multi-interpolator orchestrator ──────

function _diagnose_comprehensive(
    pep::ParameterEstimationProblem;
    interpolator = aaad_gpr_pivot,
    interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[],
    t_eval_points::Vector{Float64} = Float64[],
    full_analysis::Union{Symbol, Int, Vector{Float64}} = :best,
    save_to_disk = true,
    html_report = true,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing,
    kwargs...,
)
    @info "[DIAGNOSE] Comprehensive diagnostic for model: $(pep.name)"

    # Run SIAN once (structural, interpolator-independent)
    ident_data = setup_identifiability(pep; nooutput = true)
    t_vec = pep.data_sample["t"]
    max_order = isempty(ident_data.good_deriv_level) ? 2 : maximum(values(ident_data.good_deriv_level))

    # Resolve interpolator list
    if isempty(interpolators)
        interpolators = _DIAGNOSTIC_DEFAULT_INTERPOLATORS
    end

    interp_names = String[]
    interp_funcs = Function[]
    for im in interpolators
        push!(interp_names, string(interpolator_method_to_symbol(im)))
        try
            push!(interp_funcs, get_interpolator_function(im))
        catch e
            @warn "[DIAGNOSE] Skipping interpolator $im: $e"
            pop!(interp_names)
        end
    end

    # Resolve evaluation points — use production shooting points by default
    if isempty(t_eval_points)
        n_total = length(t_vec)
        shoot_indices = compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
        # Avoid exact first point (boundary) — shift index 1 to index 2 if present
        if !isempty(shoot_indices) && shoot_indices[1] == 1 && n_total > 2
            shoot_indices[1] = 2
        end
        t_eval_points = unique(sort([t_vec[i] for i in shoot_indices if i >= 1 && i <= n_total]))
        @info "[DIAGNOSE] Using $(length(t_eval_points)) production shooting points (exponential warp)"
    end

    # ── Grid sweep: derivative accuracy for each (interpolator, t_eval) ─
    @info "[DIAGNOSE] Sweeping $(length(interp_names)) interpolators × $(length(t_eval_points)) points..."
    all_deriv_reports = DerivativeAccuracyReport[]
    # Track best per-point across all interpolators
    best_worst_err = Inf
    best_interp_idx = 1
    best_point_idx = 1
    # Track ranking: (worst_error, interp_idx, point_idx)
    ranking = Tuple{Float64, Int, Int}[]

    for (ii, ifunc) in enumerate(interp_funcs)
        interpolants = create_interpolants(pep.measured_quantities, pep.data_sample, t_vec, ifunc)

        # Build a setup_data-like tuple for this interpolator
        time_idx_set = pick_points(t_vec, ident_data.good_num_points, interpolants, 0.5)
        sd = (
            states = ident_data.states,
            params = ident_data.params,
            t_vector = t_vec,
            interpolants = interpolants,
            good_num_points = ident_data.good_num_points,
            good_deriv_level = ident_data.good_deriv_level,
            good_udict = ident_data.good_udict,
            good_varlist = ident_data.good_varlist,
            good_DD = ident_data.good_DD,
            time_index_set = time_idx_set,
            all_unidentifiable = Set{Num}(),
            numerical_advisory = ident_data.numerical_advisory,
        )

        for (pi, te) in enumerate(t_eval_points)
            dr = try
                diagnose_derivative_accuracy(pep;
                    setup_data = sd, t_eval = te, max_order = max_order,
                    interpolator_name = interp_names[ii], kwargs...)
            catch e
                @warn "[DIAGNOSE] derivative accuracy failed for $(interp_names[ii]) at t=$te: $e"
                continue
            end
            push!(all_deriv_reports, dr)
            push!(ranking, (dr.worst_rel_error, ii, pi))

            if dr.worst_rel_error < best_worst_err
                best_worst_err = dr.worst_rel_error
                best_interp_idx = ii
                best_point_idx = pi
            end
        end
    end

    # ── Determine which points get full 3-stage analysis ──────────────
    sort!(ranking; by = first)  # best (lowest error) first

    # Build list of (interp_idx, point_idx) for full analysis
    full_analysis_set = _resolve_full_analysis_points(
        full_analysis, ranking, t_eval_points, interp_funcs)

    # Always ensure the best is first
    if !isempty(full_analysis_set) && full_analysis_set[1] != (best_interp_idx, best_point_idx)
        filter!(x -> x != (best_interp_idx, best_point_idx), full_analysis_set)
        pushfirst!(full_analysis_set, (best_interp_idx, best_point_idx))
    elseif isempty(full_analysis_set)
        full_analysis_set = [(best_interp_idx, best_point_idx)]
    end

    # ── Full 3-stage pipeline for selected points ─────────────────────
    full_reports = DiagnosticReport[]

    for (k, (ii, pi)) in enumerate(full_analysis_set)
        ifunc = interp_funcs[ii]
        te = t_eval_points[pi]
        @info "[DIAGNOSE] Full analysis $k/$(length(full_analysis_set)): $(interp_names[ii]) at t=$(round(te; digits=4))"

        setup = setup_parameter_estimation(pep; interpolator = ifunc, nooutput = true)

        deriv = diagnose_derivative_accuracy(pep;
            setup_data = setup, t_eval = te, max_order = max_order,
            interpolator_name = interp_names[ii], kwargs...)
        poly = diagnose_polynomial_system(pep;
            setup_data = setup, t_eval = te, max_order = max_order, kwargs...)
        sens = diagnose_sensitivity(pep;
            setup_data = setup, poly_report = poly,
            t_eval = te, max_order = max_order, kwargs...)

        difficulty, bottleneck = _classify_difficulty(deriv, poly, sens)
        push!(full_reports, DiagnosticReport(
            pep.name, deriv, poly, sens,
            difficulty, bottleneck, Dates.now(),
        ))
    end

    comp = ComprehensiveDiagnosticReport(
        pep.name, full_reports, all_deriv_reports,
        interp_names, t_eval_points,
        interp_names[best_interp_idx], t_eval_points[best_point_idx],
    )

    _print_diagnostic_summary(comp.best)
    _print_grid_summary(comp)

    if save_to_disk
        _save_diagnostic_report(comp.best)
        if html_report
            _save_comprehensive_html(comp; pep = pep, estimation_report = estimation_report,
                data_config = data_config)
        end
    end

    return comp
end

"""
Resolve the `full_analysis` kwarg into a list of (interp_idx, point_idx) tuples.
"""
function _resolve_full_analysis_points(
    full_analysis::Union{Symbol, Int, Vector{Float64}},
    ranking::Vector{Tuple{Float64, Int, Int}},
    t_eval_points::Vector{Float64},
    interp_funcs)

    if full_analysis isa Symbol
        if full_analysis == :best
            n = 1
        elseif full_analysis == :top3
            n = 3
        elseif full_analysis == :all
            n = length(ranking)
        else
            n = 1
        end
        # Take top N unique (interp, point) pairs from ranking
        seen = Set{Tuple{Int, Int}}()
        result = Tuple{Int, Int}[]
        for (_, ii, pi) in ranking
            key = (ii, pi)
            if key ∉ seen
                push!(seen, key)
                push!(result, key)
                length(result) >= n && break
            end
        end
        return result
    elseif full_analysis isa Int
        n = full_analysis
        seen = Set{Tuple{Int, Int}}()
        result = Tuple{Int, Int}[]
        for (_, ii, pi) in ranking
            key = (ii, pi)
            if key ∉ seen
                push!(seen, key)
                push!(result, key)
                length(result) >= n && break
            end
        end
        return result
    elseif full_analysis isa Vector{Float64}
        # Full analysis at specific time points (using best interpolator for each)
        result = Tuple{Int, Int}[]
        for t_target in full_analysis
            # Find closest eval point
            dists = abs.(t_eval_points .- t_target)
            pi = argmin(dists)
            # Find best interpolator for this point from ranking
            best_ii = 1
            best_err = Inf
            for (err, ii, pidx) in ranking
                if pidx == pi && err < best_err
                    best_err = err
                    best_ii = ii
                end
            end
            push!(result, (best_ii, pi))
        end
        return unique(result)
    end

    return Tuple{Int, Int}[]
end

function _print_grid_summary(comp::ComprehensiveDiagnosticReport)
    println("  Interpolator × Point Grid (worst relative error)")
    println("  " * "-" ^ 68)
    @printf("  %-20s", "Interpolator")
    for te in comp.eval_points
        @printf(" %12s", @sprintf("t=%.2f", te))
    end
    println()
    println("  " * "-" ^ 68)

    n_points = length(comp.eval_points)
    for (ii, iname) in enumerate(comp.interpolator_names)
        @printf("  %-20s", iname)
        for pi in 1:n_points
            # Find matching report in grid
            grid_idx = (ii - 1) * n_points + pi
            if grid_idx <= length(comp.derivative_grid)
                dr = comp.derivative_grid[grid_idx]
                err = dr.worst_rel_error
                marker = (iname == comp.best_interpolator && comp.eval_points[pi] == comp.best_eval_point) ? "*" : " "
                @printf(" %11.2e%s", err, marker)
            else
                @printf(" %12s", "—")
            end
        end
        println()
    end
    println("  (* = best combination)")
    println("=" ^ 72)
    println()
end

function _classify_difficulty(deriv, poly, sens)
    # Infeasible: 0 solutions with production data
    if poly.n_solutions_production == 0 && poly.is_square
        return :infeasible, "No algebraic solutions found with production interpolants"
    end

    worst_err = deriv.worst_rel_error
    cond = sens.jacobian_cond

    if worst_err < 0.01 && (isnan(cond) || cond < 1e6)
        return :easy, "All derivatives accurate (<1%), well-conditioned Jacobian"
    elseif worst_err < 0.10 && (isnan(cond) || cond < 1e12)
        bottleneck = if worst_err >= 0.01
            @sprintf("Derivative accuracy bottleneck: %s order %d (%.1f%% error)", deriv.worst_obs, deriv.worst_order, worst_err * 100)
        else
            @sprintf("Jacobian conditioning: %.2e", cond)
        end
        return :moderate, bottleneck
    else
        # Distinguish conditioning-only hard from derivative+conditioning hard
        if worst_err < 0.01
            bottleneck = @sprintf("Jacobian cond %.2e (derivatives accurate, conditioning is the bottleneck)", cond)
        else
            bottleneck = @sprintf("Derivative error %.1f%% at %s order %d; Jacobian cond %.2e",
                worst_err * 100, deriv.worst_obs, deriv.worst_order, cond)
        end
        return :hard, bottleneck
    end
end

# ─── Color-coded equation printing (terminal) ─────────────────────────

const _ROLE_COLORS = Dict{Symbol, Symbol}(
    :parameter => :blue,
    :state_ic => :green,
    :state_derivative => :yellow,
    :data_derivative => :cyan,
    :transcendental => :magenta,
)

const _ROLE_LABELS = Dict{Symbol, String}(
    :parameter => "param",
    :state_ic => "state IC",
    :state_derivative => "state deriv",
    :data_derivative => "data deriv",
    :transcendental => "transcendental",
)

"""Print a compact legend for variable role colors."""
function _print_color_coded_legend()
    print("    Legend: ")
    for (role, label) in sort(collect(_ROLE_LABELS); by = first)
        color = get(_ROLE_COLORS, role, :normal)
        printstyled(label; color = color, bold = true)
        print("  ")
    end
    println()
end

"""
Print an equation string with variables colored by their role.
Tokenizes on word boundaries and looks up each token in the role map.
"""
function _print_color_coded_equation(eq_str::String, var_roles::Dict{String, Symbol})
    # Tokenize: split into variable-name tokens and other characters
    tokens = _tokenize_equation(eq_str)
    for (token, is_var) in tokens
        if is_var && haskey(var_roles, token)
            color = get(_ROLE_COLORS, var_roles[token], :normal)
            printstyled(token; color = color)
        else
            print(token)
        end
    end
end

"""
Tokenize an equation string into (text, is_variable_name) pairs.
Variable names are sequences of [a-zA-Z_][a-zA-Z0-9_]* that might appear in var_roles.
"""
function _tokenize_equation(eq_str::String)
    tokens = Tuple{String, Bool}[]
    i = 1
    n = length(eq_str)
    while i <= n
        c = eq_str[i]
        if isletter(c) || c == '_'
            # Read a full identifier
            j = i + 1
            while j <= n && ((isletter(eq_str[j]) || isdigit(eq_str[j])) || eq_str[j] == '_')
                j += 1
            end
            push!(tokens, (eq_str[i:j-1], true))
            i = j
        else
            # Non-identifier character(s)
            j = i + 1
            while j <= n && !isletter(eq_str[j]) && eq_str[j] != '_'
                j += 1
            end
            push!(tokens, (eq_str[i:j-1], false))
            i = j
        end
    end
    return tokens
end

function _print_diagnostic_summary(report::DiagnosticReport)
    println()
    println("=" ^ 72)
    println("  DIAGNOSTIC REPORT: $(report.model_name)")
    println("  Difficulty: $(report.difficulty) | $(report.bottleneck)")
    println("=" ^ 72)

    # Derivative accuracy table
    da = report.derivative_accuracy
    println("\n  Derivative Accuracy (t = $(@sprintf("%.4f", da.t_eval)))")
    println("  " * "-" ^ 68)
    @printf("  %-15s %5s %15s %15s %12s\n", "Observable", "Order", "True", "Interpolant", "Rel Error")
    println("  " * "-" ^ 68)
    for e in da.entries
        marker = e.rel_error > 0.10 ? " ←" : ""
        @printf("  %-15s %5d %15.6e %15.6e %11.2e%s\n",
            e.obs, e.order, e.true_val, e.interp_val, e.rel_error, marker)
    end

    # Polynomial feasibility
    pf = report.polynomial_feasibility
    println("\n  Polynomial System: $(pf.n_equations) eqs × $(pf.n_variables) vars ($(pf.is_square ? "square" : "NOT square"))")
    @printf("  Solutions — perfect: %d, production: %d\n", pf.n_solutions_perfect, pf.n_solutions_production)
    @printf("  True residual — perfect: %.2e, production: %.2e\n", pf.true_residual_perfect, pf.true_residual_production)
    @printf("  Closest distance — perfect: %.2e, production: %.2e\n", pf.closest_distance_perfect, pf.closest_distance_production)

    # Color-coded equations (first 5 + count of remaining)
    if !isempty(pf.equation_strings)
        println("\n  Equations (color-coded by variable role):")
        _print_color_coded_legend()
        n_show = min(5, length(pf.equation_strings))
        for i in 1:n_show
            print("    ")
            _print_color_coded_equation(pf.equation_strings[i], pf.variable_roles)
            println()
        end
        remaining = length(pf.equation_strings) - n_show
        if remaining > 0
            println("    ... and $remaining more equations")
        end
    end

    # Sensitivity
    sr = report.sensitivity
    @printf("\n  Jacobian cond: %.2e | Effective rank: %d / %d\n",
        sr.jacobian_cond, sr.effective_rank, length(sr.singular_values))
    if !isnan(sr.root_sensitivity)
        @printf("  Root sensitivity: %.2e\n", sr.root_sensitivity)
    end

    println("=" ^ 72)
    println()
end

function _save_diagnostic_report(report::DiagnosticReport)
    dir = joinpath("artifacts", "diagnostics", report.model_name)
    mkpath(dir)

    # Summary text
    open(joinpath(dir, "summary.txt"), "w") do io
        println(io, "Diagnostic Report: $(report.model_name)")
        println(io, "Timestamp: $(report.timestamp)")
        println(io, "Difficulty: $(report.difficulty)")
        println(io, "Bottleneck: $(report.bottleneck)")
        println(io)

        da = report.derivative_accuracy
        println(io, "Derivative Accuracy (t = $(da.t_eval)):")
        @printf(io, "%-15s %5s %15s %15s %12s\n", "Observable", "Order", "True", "Interpolant", "Rel Error")
        for e in da.entries
            @printf(io, "%-15s %5d %15.6e %15.6e %11.2e\n",
                e.obs, e.order, e.true_val, e.interp_val, e.rel_error)
        end
        println(io)

        pf = report.polynomial_feasibility
        println(io, "Polynomial System: $(pf.n_equations) eqs × $(pf.n_variables) vars")
        @printf(io, "Solutions: perfect=%d, production=%d\n", pf.n_solutions_perfect, pf.n_solutions_production)
        @printf(io, "True residual: perfect=%.2e, production=%.2e\n", pf.true_residual_perfect, pf.true_residual_production)
        @printf(io, "Closest distance: perfect=%.2e, production=%.2e\n", pf.closest_distance_perfect, pf.closest_distance_production)
        println(io)

        sr = report.sensitivity
        @printf(io, "Jacobian cond: %.2e\n", sr.jacobian_cond)
        @printf(io, "Effective rank: %d / %d\n", sr.effective_rank, length(sr.singular_values))
    end

    # Derivative accuracy CSV
    open(joinpath(dir, "derivative_accuracy.csv"), "w") do io
        println(io, "observable,order,true_val,interp_val,rel_error")
        for e in report.derivative_accuracy.entries
            @printf(io, "%s,%d,%.15e,%.15e,%.15e\n",
                e.obs, e.order, e.true_val, e.interp_val, e.rel_error)
        end
    end

    # Sensitivity CSV
    open(joinpath(dir, "sensitivity.csv"), "w") do io
        println(io, "index,singular_value")
        for (i, sv) in enumerate(report.sensitivity.singular_values)
            @printf(io, "%d,%.15e\n", i, sv)
        end
    end

    @info "[DIAGNOSE] Reports saved to $dir"
end

# ─── HTML report generation ────────────────────────────────────────────

const _HTML_CSS = """
<style>
  :root { --bg: #fafbfc; --card: #fff; --border: #d0d7de; --accent: #0969da;
          --easy: #1a7f37; --moderate: #bf8700; --hard: #cf222e; --infeasible: #8250df;
          --teal: #0d7d6b; --gray-mid: #6e7781; }
  * { box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
         background: var(--bg); color: #1f2328; max-width: 1080px; margin: 2rem auto; padding: 0 1rem; }
  h1 { font-size: 1.5rem; border-bottom: 1px solid var(--border); padding-bottom: .5rem; }
  h2 { font-size: 1.2rem; margin-top: 1.5rem; }
  h3 { font-size: 1rem; margin: .75rem 0 .35rem; }
  h4 { font-size: .9rem; margin: .5rem 0 .25rem; }
  .math { font-family: "Cambria Math", "STIX Two Math", "Times New Roman", serif; font-style: italic; }
  .section-kicker { font-size: .7rem; font-weight: 700; letter-spacing: .08em;
                    text-transform: uppercase; color: var(--gray-mid); margin-bottom: .15rem; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-weight: 600;
           font-size: .85rem; color: #fff; }
  .badge-easy { background: var(--easy); }
  .badge-moderate { background: var(--moderate); }
  .badge-hard { background: var(--hard); }
  .badge-infeasible { background: var(--infeasible); }
  .badge-obs { background: var(--teal); font-size: .7rem; padding: 1px 6px; vertical-align: middle; }
  .badge-latent { background: var(--gray-mid); font-size: .7rem; padding: 1px 6px; vertical-align: middle; }
  /* Summary grid */
  .summary-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
                  gap: .75rem; margin: 1rem 0 1.5rem; }
  .metric-card { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
                 padding: .75rem 1rem;
                 box-shadow: 0 1px 2px rgba(15,23,42,0.04), 0 8px 24px rgba(15,23,42,0.06); }
  .metric-card .mc-label { font-size: .72rem; font-weight: 700; letter-spacing: .06em;
                            text-transform: uppercase; color: var(--gray-mid); margin-bottom: .25rem; }
  .metric-card .mc-value { font-size: 1.3rem; font-weight: 700; line-height: 1.1; }
  .metric-card .mc-sub { font-size: .75rem; color: var(--gray-mid); margin-top: .15rem; }
  /* Collapsible sections */
  details { background: var(--card); border: 1px solid var(--border); border-radius: 8px;
            margin: .75rem 0;
            box-shadow: 0 1px 2px rgba(15,23,42,0.04), 0 8px 24px rgba(15,23,42,0.06); }
  details > summary { cursor: pointer; padding: .65rem 1rem; font-weight: 600;
                       list-style: none; user-select: none; display: flex; align-items: center; gap: .5rem; }
  details > summary::before { content: '\\25B6'; font-size: .65rem; color: var(--gray-mid);
                               transition: transform .15s; display: inline-block; }
  details[open] > summary::before { transform: rotate(90deg); }
  details > summary:hover { background: #f6f8fa; border-radius: 8px; }
  .detail-body { padding: .5rem 1rem 1rem; }
  /* Tables */
  table { border-collapse: collapse; width: 100%; font-size: .85rem; margin: .5rem 0;
          font-variant-numeric: tabular-nums lining-nums; }
  th, td { text-align: right; padding: 4px 10px; border-bottom: 1px solid var(--border); }
  th { background: #f6f8fa; font-weight: 600; text-align: right; }
  th:first-child, td:first-child { text-align: left; }
  /* Error severity */
  .err-ok { color: var(--easy); }
  .err-warn { color: var(--moderate); }
  .err-bad { color: var(--hard); font-weight: 600; }
  .best-cell { background: #dafbe1; font-weight: 600; }
  /* Misc utility */
  .meta { color: #656d76; font-size: .8rem; }
  .kv { display: grid; grid-template-columns: 200px 1fr; gap: 2px 12px; font-size: .9rem; margin: .5rem 0; }
  .kv dt { font-weight: 600; }
  /* Jacobian / heatmap */
  .jac-wrap { overflow-x: auto; margin: .5rem 0; }
  .jac-table { border-collapse: collapse; font-size: .7rem; width: auto; }
  .jac-table th { font-size: .7rem; padding: 2px 4px; white-space: nowrap; }
  .jac-table td { font-size: .7rem; padding: 2px 4px; text-align: right; font-family: monospace;
                  font-variant-numeric: tabular-nums; }
  .jac-table .jac-zero { color: #ccc; }
  .jac-table .jac-col-header { writing-mode: vertical-rl; text-orientation: mixed; transform: rotate(180deg);
                                 font-weight: 600; text-align: left; padding: 4px 2px; height: 6em; }
  /* Overview grid */
  .overview-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: .5rem 0; }
  .overview-grid table { font-size: .85rem; }
  /* Provenance box */
  .provenance { color: #656d76; font-size: .8rem; margin: .25rem 0 .5rem; padding: .4rem .6rem;
                 background: #f6f8fa; border-radius: 4px; border-left: 3px solid var(--accent); }
  /* Trajectory plot cards */
  .plot-card { margin: .5rem 0; border-radius: 6px; border: 1px solid var(--border);
               overflow: hidden; }
  .plot-card.observable { border-left: 4px solid var(--teal); }
  .plot-card.latent { border-left: 4px solid var(--gray-mid); }
  .plot-card-title { padding: .4rem .75rem; font-size: .85rem; font-weight: 600;
                     background: #f6f8fa; display: flex; align-items: center; gap: .5rem; }
  .plot-card-body { padding: .5rem; }
  /* Print */
  @media print {
    body { max-width: 100%; margin: 0; padding: 0; }
    details { box-shadow: none; break-inside: avoid; }
    details[open] > summary::before { content: '\\25BC'; }
    .metric-card { box-shadow: none; }
  }
</style>
"""

function _err_class(e::Float64)
    e < 0.01 ? "err-ok" : e < 0.10 ? "err-warn" : "err-bad"
end

function _difficulty_badge(d::Symbol)
    """<span class="badge badge-$(d)">$(d)</span>"""
end

function _fmt(x::Float64; sigdigits = 3)
    isnan(x) && return "NaN"
    isinf(x) && return x > 0 ? "∞" : "-∞"
    x == 0.0 && return "0"
    ax = abs(x)
    if ax >= 1e-3 && ax < 1e4
        s = string(round(x; sigdigits = sigdigits))
        if contains(s, '.')
            s = rstrip(s, '0')
            s = rstrip(s, '.')
        end
        return s
    else
        exp = floor(Int, log10(ax))
        mantissa = x / 10.0^exp
        m_str = string(round(mantissa; sigdigits = sigdigits))
        if contains(m_str, '.')
            m_str = rstrip(m_str, '0')
            m_str = rstrip(m_str, '.')
        end
        return "$(m_str)×10<sup>$(exp)</sup>"
    end
end

function _fmt_pct(x::Float64)
    isnan(x) && return "NaN"
    pct = x * 100
    if pct >= 0.01 && pct < 1000
        return string(round(pct; sigdigits = 3)) * "%"
    else
        return _fmt(x)
    end
end

"""
    _save_diagnostic_html(report::DiagnosticReport; pep=nothing)

Generate a self-contained HTML report with collapsible sections for a single
DiagnosticReport.  When `pep` is provided, includes SVG trajectory plots.
"""
function _save_diagnostic_html(report::DiagnosticReport; pep = nothing)
    dir = joinpath("artifacts", "diagnostics", report.model_name)
    mkpath(dir)
    path = joinpath(dir, "report.html")

    # Compute UQ if sensitivity matrix is available
    uq_report = nothing
    uq_interps = nothing
    if !isnothing(pep) && !isempty(report.sensitivity.data_sensitivity_matrix)
        try
            setup_data = setup_parameter_estimation(pep; interpolator = agp_gpr_uq, nooutput = true)
            result = diagnose_uncertainty(pep, setup_data, report.derivative_accuracy.t_eval, report.sensitivity)
            if !isnothing(result)
                uq_report, uq_interps = result
            end
        catch e
            @warn "[DIAGNOSE] UQ computation failed (non-fatal): $e"
        end
    end

    open(path, "w") do io
        _write_html_header(io, report.model_name, report.difficulty, report.bottleneck, report.timestamp)
        _write_html_executive_summary(io, report; pep = pep, uq = uq_report)
        if !isnothing(pep)
            _write_html_model_overview_section(io, pep)
            _write_html_trajectory_section(io, pep; uq_interpolants = uq_interps)
        end
        _write_html_deriv_section(io, report.derivative_accuracy)
        _write_html_poly_section(io, report.polynomial_feasibility;
            t_eval = report.derivative_accuracy.t_eval,
            interpolator_name = report.derivative_accuracy.interpolator_name)
        _write_html_sens_section(io, report.sensitivity)
        if !isnothing(uq_report)
            _write_html_uq_section(io, uq_report; uq_interpolants = uq_interps)
        end
        _write_html_footer(io)
    end
    @info "[DIAGNOSE] HTML report: $path"
end

"""
    _save_comprehensive_html(comp::ComprehensiveDiagnosticReport; pep=nothing)

Generate a self-contained HTML report with the interpolator×point grid
and collapsible detail sections for a ComprehensiveDiagnosticReport.
When `pep` is provided, includes SVG trajectory plots.
"""
function _save_comprehensive_html(comp::ComprehensiveDiagnosticReport; pep = nothing,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing)
    dir = joinpath("artifacts", "diagnostics", comp.model_name)
    mkpath(dir)
    path = joinpath(dir, "report.html")
    r = comp.best

    # Compute UQ if sensitivity matrix is available
    uq_report = nothing
    uq_interps = nothing
    if !isnothing(pep) && !isempty(r.sensitivity.data_sensitivity_matrix)
        try
            # Use agp_gpr_uq so the SAME GP provides derivatives to UQ as to estimation
            setup_data = setup_parameter_estimation(pep; interpolator = agp_gpr_uq, nooutput = true)
            result = diagnose_uncertainty(pep, setup_data, comp.best_eval_point, r.sensitivity)
            if !isnothing(result)
                uq_report, uq_interps = result
                @info "[DIAGNOSE] UQ computed: max CV = $(_fmt_pct(uq_report.max_cv)), status = $(uq_report.status)"
            end
        catch e
            @warn "[DIAGNOSE] UQ computation failed (non-fatal): $e"
        end
    end

    # Compute backsolve UQ if we have both estimation results and UQ
    backsolve_uq = nothing
    if !isnothing(estimation_report) && !isnothing(uq_report) && !isnothing(pep)
        try
            backsolve_uq = propagate_backsolve_uncertainty(pep, estimation_report.best_result, uq_report)
            if !isnothing(backsolve_uq) && backsolve_uq.success
                @info "[DIAGNOSE] Backsolve UQ: amplification = $(round(backsolve_uq.amplification; sigdigits=3))"
            end
        catch e
            @warn "[DIAGNOSE] Backsolve UQ failed (non-fatal): $e"
        end
    end

    open(path, "w") do io
        _write_html_header(io, comp.model_name, r.difficulty, r.bottleneck, r.timestamp;
            best_interp = comp.best_interpolator, best_point = comp.best_eval_point)

        _write_html_executive_summary(io, comp; pep = pep, uq = uq_report,
            estimation_report = estimation_report, data_config = data_config)

        # Model overview + trajectories (visual context before numerics)
        if !isnothing(pep)
            _write_html_model_overview_section(io, pep)
            _write_html_trajectory_section(io, pep; uq_interpolants = uq_interps,
                estimated_result = !isnothing(estimation_report) ? estimation_report.best_result : nothing)
        end

        # Grid section
        _write_html_grid_section(io, comp)

        # Best-combination detail sections
        _write_html_deriv_section(io, r.derivative_accuracy; label = "Best Combination")
        _write_html_poly_section(io, r.polynomial_feasibility;
            t_eval = comp.best_eval_point, interpolator_name = comp.best_interpolator)
        _write_html_sens_section(io, r.sensitivity)

        # UQ section
        if !isnothing(uq_report)
            _write_html_uq_section(io, uq_report; uq_interpolants = uq_interps)
        end

        # Estimation results section
        if !isnothing(estimation_report)
            _write_html_estimation_section(io, estimation_report; uq = uq_report)
        end

        # Backsolve UQ section
        if !isnothing(backsolve_uq) && backsolve_uq.success
            _write_html_backsolve_uq_section(io, backsolve_uq)
        end

        # Per-interpolator expandable detail
        _write_html_all_deriv_details(io, comp)

        _write_html_footer(io)
    end
    @info "[DIAGNOSE] HTML report: $path"
end

# ─── HTML building blocks ──────────────────────────────────────────────

function _write_html_header(io, model_name, difficulty, bottleneck, timestamp;
    best_interp = nothing, best_point = nothing)
    println(io, "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">")
    println(io, "<title>Diagnostic: $model_name</title>")
    println(io, _HTML_CSS)
    println(io, "</head><body>")
    println(io, "<h1>Diagnostic Report: <code>$model_name</code></h1>")
    println(io, "<p>$(_difficulty_badge(difficulty)) &nbsp; $bottleneck</p>")
    meta = "<p class=\"meta\">$(Dates.format(timestamp, "yyyy-mm-dd HH:MM:SS"))"
    if !isnothing(best_interp)
        meta *= " &middot; Best: <b>$best_interp</b> at t=$(@sprintf("%.4f", best_point))"
    end
    meta *= "</p>"
    println(io, meta)
end

function _write_html_footer(io)
    println(io, "<p class=\"meta\" style=\"margin-top:2rem;\">Generated by ODEParameterEstimation.jl diagnostic framework</p>")
    println(io, "</body></html>")
end

"""
    _write_html_executive_summary(io, report_or_comp; pep=nothing)

Write a grid of metric cards immediately after the page header.  Accepts either
a `DiagnosticReport` or a `ComprehensiveDiagnosticReport` (uses `.best` in that case).
"""
function _write_html_executive_summary(io, report; pep = nothing, uq = nothing,
    estimation_report::Union{Nothing, EstimationResultsReport} = nothing,
    data_config::Union{Nothing, NamedTuple} = nothing)
    # Normalise to a DiagnosticReport
    r = report isa ComprehensiveDiagnosticReport ? report.best : report

    da = r.derivative_accuracy
    pf = r.polynomial_feasibility
    sr = r.sensitivity

    println(io, "<div class=\"summary-grid\">")

    # ── Card: States / Params / Obs ───────────────────────────────────
    if !isnothing(pep)
        n_states = length(pep.ic)
        n_params = length(pep.p_true)
        n_obs = count(mq -> !startswith(replace(string(mq.lhs), r"\(.*\)" => ""), "_obs_trfn_"),
            pep.measured_quantities)
        println(io, """<div class="metric-card">
  <div class="mc-label">Model Size</div>
  <div class="mc-value">$(n_states)s / $(n_params)p</div>
  <div class="mc-sub">$(n_obs) observable(s)</div>
</div>""")
    end

    # ── Card: Data Configuration ──────────────────────────────────────
    if !isnothing(data_config)
        noise_str = data_config.noise_level > 0 ? "$(_fmt(data_config.noise_level))" : "none"
        t_str = "[$(round(data_config.time_interval[1]; digits=2)), $(round(data_config.time_interval[2]; digits=2))]"
        println(io, """<div class="metric-card">
  <div class="mc-label">Data</div>
  <div class="mc-value" style="font-size:.95rem;">$(data_config.datasize) pts</div>
  <div class="mc-sub">noise: $noise_str &middot; $t_str</div>
</div>""")
    elseif !isnothing(pep) && !isnothing(pep.data_sample)
        n_pts = length(pep.data_sample["t"])
        t_data = pep.data_sample["t"]
        t_str = "[$(round(t_data[1]; digits=2)), $(round(t_data[end]; digits=2))]"
        println(io, """<div class="metric-card">
  <div class="mc-label">Data</div>
  <div class="mc-value" style="font-size:.95rem;">$n_pts pts</div>
  <div class="mc-sub">$t_str</div>
</div>""")
    end

    # ── Card: Identifiability ──────────────────────────────────────────
    if !isnothing(pep)
        if pep.unident_count == 0
            println(io, """<div class="metric-card">
  <div class="mc-label">Identifiability</div>
  <div class="mc-value" style="color:var(--easy);">All ✓</div>
  <div class="mc-sub">structurally identifiable</div>
</div>""")
        else
            println(io, """<div class="metric-card">
  <div class="mc-label">Identifiability</div>
  <div class="mc-value" style="color:var(--moderate);">$(pep.unident_count)</div>
  <div class="mc-sub">unidentifiable</div>
</div>""")
        end
    end

    # ── Card: Best interpolator ────────────────────────────────────────
    interp_display = da.interpolator_name == "unknown" ? "—" : da.interpolator_name
    println(io, """<div class="metric-card">
  <div class="mc-label">Best Interpolator</div>
  <div class="mc-value" style="font-size:.95rem;">$(interp_display)</div>
  <div class="mc-sub">t = $(@sprintf("%.4f", da.t_eval))</div>
</div>""")

    # ── Card: Worst derivative error ───────────────────────────────────
    worst_cls = da.worst_rel_error < 0.01 ? "var(--easy)" : da.worst_rel_error < 0.10 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Worst Deriv Error</div>
  <div class="mc-value" style="color:$worst_cls;">$(_fmt_pct(da.worst_rel_error))</div>
  <div class="mc-sub">$(isempty(da.worst_obs) ? "" : replace(da.worst_obs, r"\(.*\)" => "") * " ord $(da.worst_order)")</div>
</div>""")

    # ── Card: Jacobian condition number ────────────────────────────────
    cond_color = isnan(sr.jacobian_cond) ? "#333" :
        sr.jacobian_cond < 1e6 ? "var(--easy)" :
        sr.jacobian_cond < 1e12 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Jacobian κ</div>
  <div class="mc-value" style="color:$cond_color;">$(_fmt(sr.jacobian_cond))</div>
  <div class="mc-sub">rank $(sr.effective_rank) / $(length(sr.singular_values))</div>
</div>""")

    # ── Card: Difficulty badge (large) ─────────────────────────────────
    diff_color = r.difficulty == :easy ? "var(--easy)" :
        r.difficulty == :moderate ? "var(--moderate)" :
        r.difficulty == :hard ? "var(--hard)" : "var(--infeasible)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Difficulty</div>
  <div class="mc-value" style="color:$diff_color;font-size:1.5rem;">$(r.difficulty)</div>
  <div class="mc-sub" style="font-size:.7rem;">$(replace(r.bottleneck[1:min(60,length(r.bottleneck))], "&" => "&amp;", "<" => "&lt;", ">" => "&gt;"))$(length(r.bottleneck) > 60 ? "…" : "")</div>
</div>""")

    # ── Estimation cards (if available) ──────────────────────────────
    if !isnothing(estimation_report)
        err_color = estimation_report.best_error < 0.01 ? "var(--easy)" :
            estimation_report.best_error < 0.10 ? "var(--moderate)" : "var(--hard)"
        println(io, """<div class="metric-card">
  <div class="mc-label">Best Error</div>
  <div class="mc-value" style="color:$err_color;">$(_fmt(estimation_report.best_error))</div>
  <div class="mc-sub">$(estimation_report.n_results) solution(s)</div>
</div>""")
        println(io, """<div class="metric-card">
  <div class="mc-label">Estimation Time</div>
  <div class="mc-value" style="font-size:.95rem;">$(round(estimation_report.estimation_time_seconds; digits=1))s</div>
  <div class="mc-sub">full pipeline</div>
</div>""")
    end

    # ── UQ card (if available) ────────────────────────────────────────
    if !isnothing(uq)
        _write_html_uq_summary_cards(io, uq)
    end

    println(io, "</div>")  # close summary-grid
end

"""
    _pretty_name(s::String) → String

Convert a raw symbolic variable name into a readable HTML snippet.

Rules applied (in order):
1. Strip `(t)` suffix (e.g. `x1(t)` → `x1`)
2. Detect `Differential(t, N)(var(t))` patterns and render as prime notation
   - N=1 → `var&prime;`   (′)
   - N=2 → `var&Prime;`   (″)
   - N=3 → `var&#8243;`   (‴)
   - N≥4 → `d<sup>N</sup>var/dt<sup>N</sup>`
3. Convert trailing digit sequence to subscript: `x12` → `x<sub>12</sub>`
4. Keeps the raw name available as a `title` attribute for tooltips when wrapped
   in `<span title="...">`.

For Jacobian/sensitivity matrix headers, callers should wrap with:
  `<span title="RAW_NAME">PRETTY_NAME</span>`
"""
function _pretty_name(s::AbstractString)::String
    # Strip outer whitespace
    raw = strip(s)

    # ── Detect Differential(t, N)(var(t)) pattern ─────────────────────
    m = match(r"^Differential\(t,\s*(\d+)\)\((\w+)\(t\)\)$", raw)
    if !isnothing(m)
        n = parse(Int, m.captures[1])
        var = m.captures[2]
        base = _pretty_name_base(var)
        return if n == 1
            "$(base)&prime;"
        elseif n == 2
            "$(base)&Prime;"
        elseif n == 3
            "$(base)&#8243;"
        else
            "d<sup>$n</sup>$(base)/dt<sup>$n</sup>"
        end
    end

    # ── Strip (t) suffix ──────────────────────────────────────────────
    core = replace(raw, r"\(t\)$" => "")

    # ── Apply base formatting (subscript trailing digits) ─────────────
    return _pretty_name_base(core)
end

"""Apply subscript formatting to trailing digit sequence in a bare name."""
function _pretty_name_base(s::AbstractString)::String
    m = match(r"^(.*?)(\d+)$", s)
    if !isnothing(m)
        base = m.captures[1]
        digits = m.captures[2]
        return "$(base)<sub>$(digits)</sub>"
    end
    return s
end

"""
Write a collapsible Model Overview section with ODE equations, parameters, states, observables,
identifiability status, and data summary. Placed first in the report.
"""
function _write_html_model_overview_section(io, pep::ParameterEstimationProblem)
    println(io, "<details open><summary>Model Overview</summary><div class=\"detail-body\">")

    # ODE Equations
    println(io, "<h3 style=\"margin-top:0\">ODE Equations</h3>")
    eqs = try
        ModelingToolkit.equations(pep.model.system)
    catch
        []
    end
    if !isempty(eqs)
        println(io, "<ol style=\"font-family:monospace;font-size:.85rem;line-height:1.6;\">")
        for eq in eqs
            eq_str = replace(string(eq), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            println(io, "<li>$eq_str</li>")
        end
        println(io, "</ol>")
    else
        println(io, "<p class=\"meta\">No equations available</p>")
    end

    # Two-column grid: States & ICs | Parameters & True Values
    println(io, "<div class=\"overview-grid\">")

    # States & ICs
    println(io, "<div>")
    println(io, "<h3>States &amp; Initial Conditions</h3>")
    println(io, "<table><tr><th>State</th><th>IC Value</th></tr>")
    for (s, v) in pep.ic
        raw = string(s)
        raw_esc = replace(raw, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(raw)
        println(io, "<tr><td><span title=\"$raw_esc\" class=\"math\">$pretty</span></td><td>$(_fmt(v))</td></tr>")
    end
    println(io, "</table></div>")

    # Parameters & True Values
    println(io, "<div>")
    println(io, "<h3>Parameters &amp; True Values</h3>")
    println(io, "<table><tr><th>Parameter</th><th>True Value</th></tr>")
    for (p, v) in pep.p_true
        raw = string(p)
        raw_esc = replace(raw, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(raw)
        println(io, "<tr><td><span title=\"$raw_esc\" class=\"math\">$pretty</span></td><td>$(_fmt(v))</td></tr>")
    end
    println(io, "</table></div>")

    println(io, "</div>")  # close overview-grid

    # Observables
    println(io, "<h3>Observables</h3>")
    println(io, "<ul style=\"font-family:monospace;font-size:.85rem;\">")
    for mq in pep.measured_quantities
        lhs_raw = string(mq.lhs)
        lhs_esc = replace(lhs_raw, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        lhs_pretty = _pretty_name(lhs_raw)
        rhs_str = replace(string(mq.rhs), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        println(io, "<li><span title=\"$lhs_esc\" class=\"math\">$lhs_pretty</span> = $rhs_str</li>")
    end
    println(io, "</ul>")

    # Identifiability badge
    if pep.unident_count == 0
        println(io, "<p><span class=\"badge badge-easy\">All identifiable</span></p>")
    else
        println(io, "<p><span class=\"badge badge-moderate\">$(pep.unident_count) unidentifiable</span></p>")
    end

    # Data summary
    if !isnothing(pep.data_sample) && haskey(pep.data_sample, "t")
        t_vec = pep.data_sample["t"]
        n_pts = length(t_vec)
        t_min = @sprintf("%.4f", first(t_vec))
        t_max = @sprintf("%.4f", last(t_vec))
        println(io, "<p class=\"meta\">Data: $n_pts points over [$t_min, $t_max]</p>")
    end

    println(io, "</div></details>")
end

function _write_html_deriv_section(io, da::DerivativeAccuracyReport; label = "")
    title = isempty(label) ? "Derivative Accuracy (t = $(@sprintf("%.4f", da.t_eval)))" :
        "Derivative Accuracy — $label (t = $(@sprintf("%.4f", da.t_eval)))"
    println(io, "<details open><summary>$title</summary><div class=\"detail-body\">")
    # Provenance annotation
    interp_label = da.interpolator_name == "unknown" ? "" : "Interpolator: <b>$(da.interpolator_name)</b><br>"
    println(io, """<div class="provenance">$(interp_label)"True Value" = oracle Taylor coefficients at the exact ODE solution (machine precision).<br>"Interpolant" = value from the production interpolation method.</div>""")
    println(io, "<table><tr><th>Observable</th><th>Order</th><th>True Value</th><th>Interpolant</th><th>Rel Error</th></tr>")
    for e in da.entries
        cls = _err_class(e.rel_error)
        obs_raw_esc = replace(e.obs, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        obs_pretty = _pretty_name(e.obs)
        println(io, "<tr><td><span title=\"$obs_raw_esc\" class=\"math\">$obs_pretty</span></td><td>$(e.order)</td><td>$(_fmt(e.true_val))</td><td>$(_fmt(e.interp_val))</td><td class=\"$cls\">$(_fmt_pct(e.rel_error))</td></tr>")
    end
    println(io, "</table>")
    worst_pretty = _pretty_name(da.worst_obs)
    worst_raw_esc = replace(da.worst_obs, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
    println(io, "<p class=\"meta\">Worst: <b><span title=\"$worst_raw_esc\">$worst_pretty</span></b> order $(da.worst_order) — $(_fmt_pct(da.worst_rel_error))</p>")
    println(io, "</div></details>")
end

function _write_html_poly_section(io, pf::PolynomialFeasibilityReport;
    pep = nothing, t_eval::Float64 = NaN, interpolator_name::String = "")
    println(io, "<details><summary>Polynomial Feasibility ($(pf.n_equations) eqs × $(pf.n_variables) vars)</summary><div class=\"detail-body\">")
    # Provenance annotation
    prov_parts = String[]
    if !isnan(t_eval)
        push!(prov_parts, "SI template polynomial system instantiated at shooting point t = $(@sprintf("%.4f", t_eval)).")
    end
    if !isempty(interpolator_name)
        push!(prov_parts, "\"Perfect\" = oracle Taylor interpolants (exact data); \"Production\" = <b>$interpolator_name</b>.")
    else
        push!(prov_parts, "\"Perfect\" = oracle Taylor interpolants (exact data); \"Production\" = production interpolation method.")
    end
    println(io, """<div class="provenance">$(join(prov_parts, "<br>"))</div>""")
    println(io, "<dl class=\"kv\">")
    println(io, "<dt>Square</dt><dd>$(pf.is_square)</dd>")
    println(io, "<dt>Solutions (perfect)</dt><dd>$(pf.n_solutions_perfect)</dd>")
    println(io, "<dt>Solutions (production)</dt><dd>$(pf.n_solutions_production)</dd>")
    println(io, "<dt>True residual (perfect)</dt><dd>$(_fmt(pf.true_residual_perfect))</dd>")
    println(io, "<dt>True residual (production)</dt><dd>$(_fmt(pf.true_residual_production))</dd>")
    println(io, "<dt>Closest distance (perfect)</dt><dd>$(_fmt(pf.closest_distance_perfect))</dd>")
    println(io, "<dt>Closest distance (production)</dt><dd>$(_fmt(pf.closest_distance_production))</dd>")
    println(io, "</dl>")
    if !isempty(pf.variable_names)
        pretty_vars = ["""<span title="$(replace(v, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;"))" class="math">$(_pretty_name(v))</span>""" for v in pf.variable_names]
        println(io, "<details><summary>Variable names ($(length(pf.variable_names)))</summary><div class=\"detail-body\">$(join(pretty_vars, ", "))</div></details>")
    end
    # Color-coded equations
    if !isempty(pf.equation_strings)
        _write_html_equation_section(io, pf)
    end
    println(io, "</div></details>")
end

# ─── HTML color-coded equation helpers ────────────────────────────────

const _HTML_ROLE_COLORS = Dict{Symbol, String}(
    :parameter => "#0969da",       # blue
    :state_ic => "#1a7f37",        # green
    :state_derivative => "#bf8700", # amber
    :data_derivative => "#0550ae",  # teal/cyan
    :transcendental => "#8250df",   # purple
)

"""Write a collapsible section with all equations, color-coded by variable role."""
function _write_html_equation_section(io, pf::PolynomialFeasibilityReport)
    println(io, "<details><summary>Polynomial Equations ($(length(pf.equation_strings)))</summary><div class=\"detail-body\">")

    # Legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">")
    for (role, label) in sort(collect(_ROLE_LABELS); by = first)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        print(io, """<span style="color:$color;font-weight:600;">&#9632; $label</span> &nbsp; """)
    end
    println(io, "</p>")

    # Equations
    println(io, "<ol style=\"font-family:monospace;font-size:.82rem;line-height:1.6;\">")
    for eq_str in pf.equation_strings
        print(io, "<li>")
        _write_html_color_coded_equation(io, eq_str, pf.variable_roles)
        println(io, "</li>")
    end
    println(io, "</ol>")
    println(io, "</div></details>")
end

"""Write a single equation with colored <span> tags per variable."""
function _write_html_color_coded_equation(io, eq_str::String, var_roles::Dict{String, Symbol})
    tokens = _tokenize_equation(eq_str)
    for (token, is_var) in tokens
        esc_token = replace(token, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        if is_var && haskey(var_roles, token)
            color = get(_HTML_ROLE_COLORS, var_roles[token], "#333")
            print(io, """<span style="color:$color;font-weight:600;">$esc_token</span>""")
        else
            print(io, esc_token)
        end
    end
end

function _write_html_sens_section(io, sr::SensitivityReport)
    println(io, "<details><summary>Sensitivity Analysis</summary><div class=\"detail-body\">")
    # Provenance annotation
    println(io, """<div class="provenance">J = ∂F/∂x evaluated at true values, where F = SI polynomial system, x = unknowns (params, ICs, state derivatives).<br>Condition number κ = σ_max / σ_min bounds worst-case error amplification: ‖δx‖/‖x‖ ≤ κ · ‖δd‖/‖d‖.<br>The <b>Parameter–Data Sensitivity</b> matrix below gives the actual per-variable amplification via the implicit function theorem.</div>""")
    println(io, "<dl class=\"kv\">")
    cond_cls = isnan(sr.jacobian_cond) ? "" : sr.jacobian_cond < 1e6 ? "err-ok" : sr.jacobian_cond < 1e12 ? "err-warn" : "err-bad"
    println(io, "<dt>Jacobian condition</dt><dd class=\"$cond_cls\">$(_fmt(sr.jacobian_cond))</dd>")
    println(io, "<dt>Effective rank</dt><dd>$(sr.effective_rank) / $(length(sr.singular_values))</dd>")
    if !isnan(sr.root_sensitivity)
        println(io, "<dt>Root sensitivity</dt><dd>$(_fmt(sr.root_sensitivity))</dd>")
    end
    println(io, "</dl>")
    if !isempty(sr.singular_values)
        println(io, "<details><summary>Singular value spectrum ($(length(sr.singular_values)))</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>#</th><th>σ</th><th>σ / σ_max</th></tr>")
        smax = sr.singular_values[1]
        for (i, sv) in enumerate(sr.singular_values)
            ratio = smax > 0 ? sv / smax : NaN
            cls = ratio < 1e-10 ? "err-bad" : ratio < 1e-6 ? "err-warn" : ""
            println(io, "<tr><td>$i</td><td>$(_fmt(sv))</td><td class=\"$cls\">$(_fmt(ratio))</td></tr>")
        end
        println(io, "</table></div></details>")
    end
    # Full Jacobian matrix (if captured)
    if length(sr.jacobian_matrix) > 0 && !isempty(sr.jacobian_col_labels)
        n_rows, n_cols = size(sr.jacobian_matrix)
        default_open = n_rows <= 16 && n_cols <= 16
        open_attr = default_open ? " open" : ""
        println(io, "<details$open_attr><summary>Full Jacobian Matrix ∂F/∂x ($(n_rows) × $(n_cols))</summary><div class=\"detail-body\">")
        _write_html_jacobian_table(io, sr)
        println(io, "</div></details>")
    end
    # Data sensitivity matrix: dx*/dd via implicit function theorem
    if length(sr.data_sensitivity_matrix) > 0 && !isempty(sr.data_sensitivity_data_labels)
        _write_html_data_sensitivity_section(io, sr)
    end
    println(io, "</div></details>")
end

"""
Write the parameter-data sensitivity matrix S = -(∂F/∂x)⁻¹·(∂F/∂d) as a labeled
HTML table with heatmap coloring. S[i,j] = how much unknown i shifts per unit
perturbation of data variable j.
"""
function _write_html_data_sensitivity_section(io, sr::SensitivityReport)
    S = sr.data_sensitivity_matrix
    n_unknowns, n_data = size(S)
    max_abs = maximum(abs, S; init = 1e-300)

    # Summary statistics
    max_amp = @sprintf("%.2e", max_abs)
    println(io, "<details open><summary>Parameter–Data Sensitivity dx*/dd ($(n_unknowns) × $(n_data))</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance">S = -(∂F/∂x)<sup>-1</sup>·(∂F/∂d) via implicit function theorem.<br>S[i,j] = displacement in unknown i per unit error in data variable j.<br>Max amplification: <b>$max_amp</b></div>""")

    # Per-unknown sensitivity summary (which unknown is most affected?)
    row_max = [maximum(abs, S[i, :]; init = 0.0) for i in 1:n_unknowns]
    # Use data_sensitivity_unknown_labels (correct for the S matrix) with fallback to jacobian_col_labels
    unknown_labels = if !isempty(sr.data_sensitivity_unknown_labels)
        sr.data_sensitivity_unknown_labels
    else
        sr.jacobian_col_labels
    end
    unknown_roles_dict = if !isempty(sr.data_sensitivity_unknown_roles)
        sr.data_sensitivity_unknown_roles
    else
        sr.jacobian_col_roles
    end
    col_labels = sr.data_sensitivity_data_labels

    if length(unknown_labels) != n_unknowns
        @warn "[HTML] Data sensitivity row label count ($(length(unknown_labels))) != matrix rows ($n_unknowns)"
    end

    # Sort unknowns by sensitivity (most sensitive first) for the summary
    sorted_idx = sortperm(row_max; rev = true)
    println(io, "<h4 style=\"margin-top:.5rem;\">Most sensitive unknowns</h4>")
    println(io, "<table><tr><th>Unknown</th><th>Role</th><th>Max |S|</th><th>Most sensitive to</th></tr>")
    n_show = min(8, n_unknowns)
    for k in 1:n_show
        i = sorted_idx[k]
        uname = i <= length(unknown_labels) ? unknown_labels[i] : "x_$i"
        role = get(unknown_roles_dict, uname, :unknown)
        role_label = get(_ROLE_LABELS, role, string(role))
        role_color = get(_HTML_ROLE_COLORS, role, "#333")
        max_s = row_max[i]
        # Find which data var this unknown is most sensitive to
        j_max = argmax(abs.(S[i, :]))
        dname = j_max <= length(col_labels) ? col_labels[j_max] : "d_$j_max"
        cls = max_s > 100.0 ? "err-bad" : max_s > 10.0 ? "err-warn" : "err-ok"
        uname_esc = replace(uname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        upretty = _pretty_name(uname)
        dname_esc = replace(dname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        dpretty = _pretty_name(dname)
        println(io, """<tr><td><span title="$uname_esc" style="color:$role_color;font-weight:600;" class="math">$upretty</span></td><td>$role_label</td><td class="$cls">$(_fmt(max_s))</td><td><span title="$dname_esc" class="math">$dpretty</span></td></tr>""")
    end
    println(io, "</table>")

    # Full matrix (collapsible for large systems)
    default_open = n_unknowns <= 12 && n_data <= 12
    open_attr = default_open ? " open" : ""
    println(io, "<details$open_attr><summary>Full Sensitivity Matrix ($(n_unknowns) × $(n_data))</summary><div class=\"detail-body\">")

    # Role legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">Columns = data variables (interpolated observable derivatives). Rows = unknowns.</p>")

    println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

    # Column headers (data variable names, rotated)
    print(io, "<tr><th></th>")
    for dname in col_labels
        drole = get(sr.data_sensitivity_data_roles, dname, :data_derivative)
        color = get(_HTML_ROLE_COLORS, drole, "#0550ae")
        esc_name = replace(dname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        dpretty = _pretty_name(dname)
        print(io, """<th class="jac-col-header" style="color:$color;" title="$esc_name"><span title="$esc_name">$dpretty</span></th>""")
    end
    println(io, "</tr>")

    # Data rows (one per unknown)
    for i in 1:n_unknowns
        uname = i <= length(unknown_labels) ? unknown_labels[i] : "x_$i"
        role = get(unknown_roles_dict, uname, :unknown)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        esc_name = replace(uname, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        upretty = _pretty_name(uname)
        print(io, """<tr><th style="color:$color;font-weight:600;" title="$esc_name" class="math">$upretty</th>""")
        for j in 1:n_data
            _write_jacobian_cell(io, S[i, j], max_abs)
        end
        println(io, "</tr>")
    end

    println(io, "</table></div>")
    println(io, "</div></details>")
    println(io, "</div></details>")
end

"""
Write the full labelled Jacobian matrix as an HTML table with color-coded column headers
and heatmap cell backgrounds.
"""
function _write_html_jacobian_table(io, sr::SensitivityReport)
    J = sr.jacobian_matrix
    n_rows, n_cols = size(J)
    max_abs = maximum(abs, J; init = 1e-300)

    # Role legend
    println(io, "<p style=\"font-size:.8rem;margin-bottom:.5rem;\">")
    for (role, label) in sort(collect(_ROLE_LABELS); by = first)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        print(io, """<span style="color:$color;font-weight:600;">&#9632; $label</span> &nbsp; """)
    end
    println(io, "</p>")

    println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

    # Column headers (rotated variable names, color-coded by role)
    print(io, "<tr><th></th>")
    for (ci, col_name) in enumerate(sr.jacobian_col_labels)
        role = get(sr.jacobian_col_roles, col_name, :state_derivative)
        color = get(_HTML_ROLE_COLORS, role, "#333")
        esc_name = replace(col_name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(col_name)
        print(io, """<th class="jac-col-header" style="color:$color;" title="$esc_name"><span title="$esc_name">$pretty</span></th>""")
    end
    println(io, "</tr>")

    # Data rows
    for ri in 1:n_rows
        row_label = ri <= length(sr.jacobian_row_labels) ? sr.jacobian_row_labels[ri] : "Eq $ri"
        print(io, "<tr><th title=\"$row_label\">$row_label</th>")
        for ci in 1:n_cols
            _write_jacobian_cell(io, J[ri, ci], max_abs)
        end
        println(io, "</tr>")
    end

    println(io, "</table></div>")
end

"""Write a single Jacobian cell with heatmap coloring."""
function _write_jacobian_cell(io, val::Float64, max_abs::Float64)
    if abs(val) < 1e-14 * max_abs
        print(io, "<td class=\"jac-zero\">0</td>")
    else
        # Compute log-intensity for background color (0..1 range)
        intensity = clamp(log10(abs(val) / max_abs + 1e-300) / log10(max_abs + 1e-300) + 1.0, 0.0, 1.0)
        alpha = @sprintf("%.2f", 0.08 + 0.22 * intensity)
        bg = val > 0 ? "rgba(26,127,55,$alpha)" : "rgba(207,34,46,$alpha)"
        fmt_val = @sprintf("%.1e", val)
        print(io, """<td style="background:$bg;">$fmt_val</td>""")
    end
end

function _write_html_grid_section(io, comp::ComprehensiveDiagnosticReport)
    println(io, "<details open><summary>Interpolator × Evaluation Point Grid</summary><div class=\"detail-body\">")
    println(io, """<div class="provenance">Each cell = max<sub>obs,order</sub> |true − interp| / max(|true|, ε). Green highlight = best combination.</div>""")
    println(io, "<table><tr><th>Interpolator</th>")
    for te in comp.eval_points
        println(io, "<th>t=$(@sprintf("%.2f", te))</th>")
    end
    println(io, "</tr>")

    n_points = length(comp.eval_points)
    for (ii, iname) in enumerate(comp.interpolator_names)
        println(io, "<tr><td>$iname</td>")
        for pi in 1:n_points
            grid_idx = (ii - 1) * n_points + pi
            if grid_idx <= length(comp.derivative_grid)
                dr = comp.derivative_grid[grid_idx]
                err = dr.worst_rel_error
                is_best = (iname == comp.best_interpolator && comp.eval_points[pi] ≈ comp.best_eval_point)
                cls = _err_class(err) * (is_best ? " best-cell" : "")
                println(io, "<td class=\"$cls\">$(_fmt(err))</td>")
            else
                println(io, "<td>—</td>")
            end
        end
        println(io, "</tr>")
    end
    println(io, "</table></div></details>")
end

function _write_html_all_deriv_details(io, comp::ComprehensiveDiagnosticReport)
    println(io, "<details><summary>All Derivative Accuracy Tables</summary><div class=\"detail-body\">")
    n_points = length(comp.eval_points)
    for (ii, iname) in enumerate(comp.interpolator_names)
        for (pi, te) in enumerate(comp.eval_points)
            grid_idx = (ii - 1) * n_points + pi
            if grid_idx <= length(comp.derivative_grid)
                dr = comp.derivative_grid[grid_idx]
                _write_html_deriv_section(io, dr;
                    label = "$iname")
            end
        end
    end
    println(io, "</div></details>")
end

# ─── SVG trajectory plots in HTML ─────────────────────────────────────

"""
Write a collapsible "Trajectories" section with SVG plots of observables
(data + ODE curve) and state variables (ODE curve only).
Observable states appear first with a teal left-border accent;
latent states appear after with a gray left-border accent.
"""
function _write_html_trajectory_section(io, pep; uq_interpolants = nothing,
    estimated_result::Union{Nothing, ParameterEstimationResult} = nothing)
    plots = try
        _generate_trajectory_plots(pep; uq_interpolants = uq_interpolants,
            estimated_result = estimated_result)
    catch e
        @warn "[DIAGNOSE] Trajectory plot generation failed: $e"
        Tuple{String, String, Bool}[]
    end
    isempty(plots) && return

    # Separate observable and latent plots
    obs_plots = [(t, s) for (t, s, is_obs) in plots if is_obs]
    lat_plots = [(t, s) for (t, s, is_obs) in plots if !is_obs]

    println(io, "<details open><summary>Trajectories ($(length(plots)) plots)</summary><div class=\"detail-body\">")

    # Observable plots first
    if !isempty(obs_plots)
        println(io, "<p class=\"section-kicker\">Observables</p>")
        for (title, svg) in obs_plots
            println(io, """<div class="plot-card observable">""")
            println(io, """<div class="plot-card-title">$title <span class="badge badge-obs">Observable</span></div>""")
            println(io, """<div class="plot-card-body">$svg</div>""")
            println(io, "</div>")
        end
    end

    # Latent state plots
    if !isempty(lat_plots)
        println(io, "<p class=\"section-kicker\" style=\"margin-top:1rem;\">Latent States</p>")
        for (title, svg) in lat_plots
            println(io, """<div class="plot-card latent">""")
            println(io, """<div class="plot-card-title">$title <span class="badge badge-latent">Latent</span></div>""")
            println(io, """<div class="plot-card-body">$svg</div>""")
            println(io, "</div>")
        end
    end

    println(io, "</div></details>")
end

# ─── Uncertainty Quantification ────────────────────────────────────────

"""
    _parse_data_label(label) → (base_name, deriv_order)

Parse a data variable label that may be in SIAN style ("y1_0", "y1_2") or
Symbolics style ("y1(t)", "Differential(t, 1)(y1(t))").

Returns `("", 0)` if parsing fails.
"""
function _parse_data_label(label::String)
    # Try Symbolics Differential pattern: "Differential(t, N)(var(t))"
    m = match(r"^Differential\(t,\s*(\d+)\)\((\w+)\(t\)\)$", label)
    if !isnothing(m)
        order = parse(Int, m.captures[1])
        base = m.captures[2]
        return (base, order)
    end

    # Try Symbolics bare variable: "var(t)"
    m = match(r"^(\w+)\(t\)$", label)
    if !isnothing(m)
        return (m.captures[1], 0)
    end

    # Try SIAN style: "var_N"
    parsed = parse_derivative_variable_name(label)
    if !isnothing(parsed)
        base, order = parsed
        return (String(base), order)
    end

    return ("", 0)
end

"""
    _match_obs_name(base_name, obs_name_to_idx) → Union{Int, Nothing}

Find the observable index matching a base name. Tries exact match then prefix match.
"""
function _match_obs_name(base_name::AbstractString, obs_name_to_idx::Dict{String, Int})
    # Exact match
    haskey(obs_name_to_idx, base_name) && return obs_name_to_idx[base_name]

    # Prefix match (e.g. "y1" matching "y1_extra")
    for (oname, oidx) in obs_name_to_idx
        if oname == base_name || startswith(oname, base_name)
            return oidx
        end
    end

    return nothing
end

"""
    diagnose_uncertainty(pep, setup_data, t_eval, sensitivity_report; kwargs...) → UncertaintyReport

Propagate GP posterior covariance through the parameter-data sensitivity matrix
to compute parameter uncertainty: Σ_x = S · Σ_d · S'.

Returns `nothing` if the sensitivity matrix is empty or UQ computation fails.
"""
function diagnose_uncertainty(
    pep::ParameterEstimationProblem,
    setup_data,
    t_eval::Float64,
    sensitivity_report::SensitivityReport;
    kwargs...,
)
    S = sensitivity_report.data_sensitivity_matrix
    data_labels = sensitivity_report.data_sensitivity_data_labels

    if isempty(S) || isempty(data_labels)
        return nothing
    end

    n_unknowns, n_data = size(S)

    # Validate dimension consistency between S and unknown labels
    expected_labels = length(sensitivity_report.data_sensitivity_unknown_labels)
    if expected_labels > 0 && expected_labels != n_unknowns
        @warn "[UQ] Label count mismatch: S has $n_unknowns rows but $expected_labels unknown labels — aborting UQ"
        return nothing
    end

    # Step 1: Fit UQ GPs for each non-trfn observable
    t_data = pep.data_sample["t"]
    uq_interps = Dict{String, AGPInterpolatorUQ}()
    obs_names = String[]
    obs_posterior_mean = Vector{Float64}[]
    obs_posterior_std = Vector{Float64}[]

    # Determine max derivative order needed from data labels
    # Data labels may use SIAN style ("y1_0", "y1_1") or Symbolics style
    # ("y1(t)", "Differential(t, 1)(y1(t))")
    max_deriv_needed = 0
    for dl in data_labels
        _, order = _parse_data_label(dl)
        max_deriv_needed = max(max_deriv_needed, order)
    end
    # SE kernel now supports arbitrary order via Hermite recurrence.
    # Cap at a reasonable maximum to prevent runaway computation.
    max_deriv_needed = min(max_deriv_needed, 8)

    for mq in pep.measured_quantities
        obs_name = replace(string(mq.lhs), r"\(.*\)" => "")
        startswith(obs_name, "_obs_trfn_") && continue

        obs_rhs = ModelingToolkit.diff2term(mq.rhs)
        y_data = _get_observable_data(pep, obs_rhs)
        isnothing(y_data) && continue

        try
            # Reuse estimation interpolant if it's already an AGPInterpolatorUQ
            if haskey(setup_data.interpolants, obs_rhs) &&
               setup_data.interpolants[obs_rhs] isa AGPInterpolatorUQ
                interp_uq = setup_data.interpolants[obs_rhs]
            else
                interp_uq = agp_gpr_uq(Float64.(t_data), Float64.(y_data))
            end
            uq_interps[obs_name] = interp_uq

            μ, Σ = joint_derivative_covariance(interp_uq, t_eval, max_deriv_needed)
            # Warn on negative variance before clipping
            neg_diag = findall(d -> d < -1e-10, diag(Σ))
            if !isempty(neg_diag)
                @warn "[UQ] Negative GP posterior variance for '$obs_name' at indices $neg_diag (values: $(diag(Σ)[neg_diag])) — clipping to zero"
            end
            σ = sqrt.(max.(diag(Σ), 0.0))

            push!(obs_names, obs_name)
            push!(obs_posterior_mean, μ)
            push!(obs_posterior_std, σ)
        catch e
            @warn "[UQ] GP fitting failed for observable $obs_name: $e"
        end
    end

    if isempty(obs_names)
        return nothing
    end

    # Step 2: Build Σ_d by mapping data_labels to GP posterior covariance entries
    # Build obs_name → index in obs_names
    obs_name_to_idx = Dict(obs_names[i] => i for i in eachindex(obs_names))

    # For each observable, get the full posterior covariance at t_eval
    obs_cov_blocks = Dict{String, Matrix{Float64}}()
    for (i, name) in enumerate(obs_names)
        if haskey(uq_interps, name)
            _, Σ_obs = joint_derivative_covariance(uq_interps[name], t_eval, max_deriv_needed)
            obs_cov_blocks[name] = Σ_obs
        end
    end

    warnings = String[]

    Σ_d = zeros(n_data, n_data)
    for i in 1:n_data
        base_i, order_i = _parse_data_label(data_labels[i])
        if isempty(base_i)
            msg = "Unparseable data label '$(data_labels[i])' — skipped in Σ_d"
            push!(warnings, msg)
            @warn "[UQ] $msg"
            continue
        end

        # Find which observable this corresponds to
        obs_idx_i = _match_obs_name(base_i, obs_name_to_idx)
        if isnothing(obs_idx_i)
            msg = "Data label '$(data_labels[i])' (base='$base_i') has no matching observable — skipped in Σ_d"
            push!(warnings, msg)
            @warn "[UQ] $msg"
            continue
        end
        obs_name_i = obs_names[obs_idx_i]

        for j in 1:n_data
            base_j, order_j = _parse_data_label(data_labels[j])
            if isempty(base_j)
                continue  # already warned on the outer loop
            end

            # Must be same observable (block-diagonal assumption)
            obs_idx_j = _match_obs_name(base_j, obs_name_to_idx)
            isnothing(obs_idx_j) && continue
            obs_idx_i != obs_idx_j && continue

            # Look up covariance from the GP posterior block
            if haskey(obs_cov_blocks, obs_name_i)
                Σ_block = obs_cov_blocks[obs_name_i]
                if order_i + 1 <= size(Σ_block, 1) && order_j + 1 <= size(Σ_block, 2)
                    Σ_d[i, j] = Σ_block[order_i + 1, order_j + 1]
                end
            end
        end
    end

    # Enforce PSD on Σ_d
    Σ_d = Symmetric(Σ_d)
    evals = eigvals(Σ_d)
    if minimum(evals) < 0
        Σ_d = Σ_d + Matrix{Float64}(I, n_data, n_data) * (abs(minimum(evals)) + 1e-15)
    end

    # Check: zero-variance data variables with nonzero sensitivity
    xlabels = if !isempty(sensitivity_report.data_sensitivity_unknown_labels)
        sensitivity_report.data_sensitivity_unknown_labels
    else
        sensitivity_report.jacobian_col_labels  # fallback for legacy reports
    end
    zero_diag = findall(d -> d == 0.0, diag(Σ_d))
    if !isempty(zero_diag)
        for idx in zero_diag
            sensitive_params = findall(s -> abs(s) > 1e-10, S[:, idx])
            if !isempty(sensitive_params)
                pnames = [xlabels[k] for k in sensitive_params]
                msg = "Zero GP covariance for '$(data_labels[idx])' but parameters [$(join(pnames, ", "))] depend on it — their uncertainty is UNDERESTIMATED"
                push!(warnings, msg)
                @warn "[UQ] $msg"
            end
        end
    end

    # Step 3: Compute Σ_x = S · Σ_d · S'
    Σ_x = S * Matrix(Σ_d) * S'
    Σ_x = Symmetric(Σ_x)

    # Enforce PSD
    evals_x = eigvals(Σ_x)
    if minimum(evals_x) < 0
        Σ_x = Σ_x + Matrix{Float64}(I, n_unknowns, n_unknowns) * (abs(minimum(evals_x)) + 1e-15)
    end

    # Warn on negative variance before clipping
    neg_diag_x = findall(d -> d < -1e-10, diag(Σ_x))
    if !isempty(neg_diag_x)
        neg_labels = [xlabels[k] for k in neg_diag_x if k <= length(xlabels)]
        msg = "Negative variance for parameters [$(join(neg_labels, ", "))] (values: $(diag(Σ_x)[neg_diag_x])) — numerical breakdown, clipping to zero"
        push!(warnings, msg)
        @warn "[UQ] $msg"
    end

    param_std = sqrt.(max.(diag(Σ_x), 0.0))

    # Step 4: Build param labels and true values (from data sensitivity unknown labels)
    param_labels = if !isempty(sensitivity_report.data_sensitivity_unknown_labels)
        sensitivity_report.data_sensitivity_unknown_labels
    else
        sensitivity_report.jacobian_col_labels  # fallback for legacy reports
    end
    param_roles = if !isempty(sensitivity_report.data_sensitivity_unknown_roles)
        sensitivity_report.data_sensitivity_unknown_roles
    else
        sensitivity_report.jacobian_col_roles  # fallback for legacy reports
    end

    # Look up true values for each unknown
    param_true_values = Float64[]
    for label in param_labels
        val = NaN
        # Try matching against p_true
        for (p, v) in pep.p_true
            if replace(string(p), "(t)" => "") == label
                val = v
                break
            end
        end
        # Try matching against ic
        if isnan(val)
            for (s, v) in pep.ic
                if replace(string(s), "(t)" => "") == label
                    val = v
                    break
                end
            end
        end
        # Try parsed name for derivative variables
        if isnan(val)
            parsed = parse_derivative_variable_name(label)
            if !isnothing(parsed)
                base, order = parsed
                if order == 0
                    for (p, v) in pep.p_true
                        if replace(string(p), "(t)" => "") == base
                            val = v
                            break
                        end
                    end
                    if isnan(val)
                        for (s, v) in pep.ic
                            if replace(string(s), "(t)" => "") == base
                                val = v
                                break
                            end
                        end
                    end
                end
            end
        end
        push!(param_true_values, val)
    end

    # Step 5: Correlation matrix
    corr = zeros(n_unknowns, n_unknowns)
    for i in 1:n_unknowns
        for j in 1:n_unknowns
            si = param_std[i]
            sj = param_std[j]
            if si > 0 && sj > 0
                corr[i, j] = clamp(Matrix(Σ_x)[i, j] / (si * sj), -1.0, 1.0)
            elseif i == j
                corr[i, j] = 1.0
            end
        end
    end

    # Step 6: Quality classification
    max_cv = 0.0
    for i in 1:n_unknowns
        tv = param_true_values[i]
        if isfinite(tv) && abs(tv) > 1e-15
            cv = param_std[i] / abs(tv)
            max_cv = max(max_cv, cv)
        end
    end

    status = if max_cv < 0.5
        :ok
    elseif max_cv < 2.0
        :wide_ci
    else
        :degenerate
    end

    return UncertaintyReport(
        pep.name, t_eval,
        obs_names, obs_posterior_mean, obs_posterior_std,
        Matrix(Σ_d), data_labels,
        Matrix(Σ_x), param_std, param_labels, param_roles, param_true_values,
        corr,
        max_cv, status, warnings,
    ), uq_interps
end

# ─── UQ HTML rendering ───────────────────────────────────────────────

"""
Write the UQ section to the HTML report: CI table, correlation matrix,
observation uncertainty, and executive summary cards.
"""
function _write_html_uq_section(io, uq::UncertaintyReport;
    uq_interpolants::Union{Nothing, Dict{String, AGPInterpolatorUQ}} = nothing)
    println(io, "<details open><summary>Parameter Uncertainty (GP → IFT)</summary><div class=\"detail-body\">")

    # Provenance
    status_badge = if uq.status == :ok
        """<span class="badge badge-easy">OK</span>"""
    elseif uq.status == :wide_ci
        """<span class="badge badge-moderate">Wide CI</span>"""
    else
        """<span class="badge badge-hard">Degenerate</span>"""
    end
    println(io, """<div class="provenance">Σ<sub>x</sub> = S·Σ<sub>d</sub>·S<sup>T</sup> where S = parameter–data sensitivity, Σ<sub>d</sub> = GP posterior covariance at t = $(@sprintf("%.4f", uq.t_eval)). $status_badge</div>""")

    # Warning box (if any)
    if !isempty(uq.warnings)
        println(io, """<div style="background:#fff3cd;border:1px solid #ffc107;border-radius:6px;padding:10px 14px;margin:8px 0;">""")
        println(io, """<strong style="color:#856404;">UQ Warnings</strong><ul style="margin:4px 0 0 0;padding-left:20px;">""")
        for w in uq.warnings
            w_esc = replace(w, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            println(io, "<li style=\"color:#856404;\">$w_esc</li>")
        end
        println(io, "</ul></div>")
    end

    # CI table
    println(io, "<h4>Parameter Confidence Intervals</h4>")
    println(io, "<table><tr><th>Parameter</th><th>Role</th><th>True Value</th><th>±1σ (68%)</th><th>±2σ (95%)</th><th>CV</th><th>Status</th></tr>")

    n_params = min(length(uq.param_labels), length(uq.param_true_values), length(uq.param_std))
    for i in 1:n_params
        label = uq.param_labels[i]
        raw_esc = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
        pretty = _pretty_name(label)
        role = get(uq.param_roles, label, :unknown)
        role_label = get(_ROLE_LABELS, role, string(role))
        role_color = get(_HTML_ROLE_COLORS, role, "#333")

        tv = uq.param_true_values[i]
        σ = uq.param_std[i]

        tv_str = isfinite(tv) ? _fmt(tv) : "—"
        σ1_str = _fmt(σ)
        σ2_str = _fmt(1.96 * σ)

        # CV
        cv = (isfinite(tv) && abs(tv) > 1e-15) ? σ / abs(tv) : NaN
        cv_str = isfinite(cv) ? _fmt_pct(cv) : "—"
        cv_cls = !isfinite(cv) ? "" : cv < 0.10 ? "err-ok" : cv < 0.50 ? "err-warn" : "err-bad"

        status_mark = !isfinite(cv) ? "—" : cv < 0.10 ? "✓" : cv < 0.50 ? "~" : "✗"

        println(io, """<tr><td><span title="$raw_esc" style="color:$role_color;font-weight:600;" class="math">$pretty</span></td><td>$role_label</td><td>$tv_str</td><td>±$σ1_str</td><td>±$σ2_str</td><td class="$cv_cls">$cv_str</td><td>$status_mark</td></tr>""")
    end
    println(io, "</table>")

    # Observation Uncertainty at Shooting Point
    if !isempty(uq.obs_names)
        println(io, "<details><summary>Observation GP Posterior at t = $(@sprintf("%.4f", uq.t_eval))</summary><div class=\"detail-body\">")
        println(io, "<table><tr><th>Observable</th><th>Order</th><th>μ (mean)</th><th>σ (std)</th></tr>")
        for (oi, obs_name) in enumerate(uq.obs_names)
            for k in eachindex(uq.obs_posterior_mean[oi])
                order = k - 1
                μ_val = uq.obs_posterior_mean[oi][k]
                σ_val = uq.obs_posterior_std[oi][k]
                obs_pretty = _pretty_name(obs_name)
                println(io, "<tr><td class=\"math\">$obs_pretty</td><td>$order</td><td>$(_fmt(μ_val))</td><td>$(_fmt(σ_val))</td></tr>")
            end
        end
        println(io, "</table></div></details>")
    end

    # GP Noise Estimates
    if !isnothing(uq_interpolants) && !isempty(uq_interpolants)
        println(io, "<details><summary>GP Noise Estimates</summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">Estimated observation noise σ<sub>n</sub> from GP hyperparameter optimization (kernel jitter on diagonal of K).</div>""")
        println(io, "<table><tr><th>Observable</th><th>σ<sub>n</sub> (noise std)</th><th>σ<sub>n</sub>² (noise var)</th></tr>")
        for (obs_name, interp) in sort(collect(uq_interpolants); by = first)
            σ_n = sqrt(max(interp.noise_var, 0.0))
            println(io, "<tr><td class=\"math\">$(_pretty_name(obs_name))</td><td>$(_fmt(σ_n))</td><td>$(_fmt(interp.noise_var))</td></tr>")
        end
        println(io, "</table></div></details>")
    end

    # Correlation matrix (use actual matrix size to avoid bounds errors with _trfn_ vars)
    n = min(length(uq.param_labels), size(uq.correlation_matrix, 1))
    if n > 0
        default_open = n <= 12
        open_attr = default_open ? " open" : ""
        println(io, "<details$open_attr><summary>Parameter Correlation Matrix ($n × $n)</summary><div class=\"detail-body\">")
        println(io, """<div class="provenance">ρ[i,j] = Σ<sub>x</sub>[i,j] / (σ<sub>i</sub>·σ<sub>j</sub>). Blue = positive correlation, red = negative, white = independent.</div>""")
        println(io, "<div class=\"jac-wrap\"><table class=\"jac-table\">")

        # Column headers
        print(io, "<tr><th></th>")
        for label in uq.param_labels
            raw_esc = replace(label, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            pretty = _pretty_name(label)
            role = get(uq.param_roles, label, :unknown)
            color = get(_HTML_ROLE_COLORS, role, "#333")
            print(io, """<th class="jac-col-header" style="color:$color;" title="$raw_esc">$pretty</th>""")
        end
        println(io, "</tr>")

        # Rows
        for i in 1:n
            label_i = uq.param_labels[i]
            raw_esc = replace(label_i, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")
            pretty = _pretty_name(label_i)
            role = get(uq.param_roles, label_i, :unknown)
            color = get(_HTML_ROLE_COLORS, role, "#333")
            print(io, """<tr><th style="color:$color;font-weight:600;" title="$raw_esc" class="math">$pretty</th>""")
            for j in 1:n
                ρ = uq.correlation_matrix[i, j]
                _write_correlation_cell(io, ρ)
            end
            println(io, "</tr>")
        end
        println(io, "</table></div></div></details>")
    end

    println(io, "</div></details>")
end

"""Write a single correlation cell with blue/red coloring."""
function _write_correlation_cell(io, ρ::Float64)
    if abs(ρ) < 1e-10
        print(io, "<td class=\"jac-zero\">0</td>")
    else
        alpha = @sprintf("%.2f", 0.1 + 0.3 * abs(ρ))
        bg = ρ > 0 ? "rgba(9,105,218,$alpha)" : "rgba(207,34,46,$alpha)"
        fmt_val = @sprintf("%.2f", ρ)
        print(io, """<td style="background:$bg;">$fmt_val</td>""")
    end
end

"""Write UQ metric cards for the executive summary grid."""
function _write_html_uq_summary_cards(io, uq::UncertaintyReport)
    # Max σ card
    max_σ = maximum(uq.param_std; init = 0.0)
    σ_color = uq.status == :ok ? "var(--easy)" : uq.status == :wide_ci ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="metric-card">
  <div class="mc-label">Max Param σ</div>
  <div class="mc-value" style="color:$σ_color;">$(_fmt(max_σ))</div>
  <div class="mc-sub">$(_fmt_pct(uq.max_cv)) worst CV</div>
</div>""")
end

# ─── diagnose_model: one-line convenience API ──────────────────────────

"""
    diagnose_model(pep; opts=EstimationOptions(), full_analysis=:best, kwargs...)

Convenience wrapper that automates the full diagnostic pipeline:
1. Sample data from the PEP (if not already sampled)
2. Transform for transcendental functions (sin/cos/exp)
3. Compute production shooting points
4. Call `diagnose()` with comprehensive multi-point analysis

Returns a `ComprehensiveDiagnosticReport`.

# Keyword arguments
- `opts::EstimationOptions`: Controls datasize, time_interval, noise, etc.
- `full_analysis`: Controls depth — see `diagnose()` docs.
- `interpolators`: Vector of `InterpolatorMethod` enums (default: production set).
- All other kwargs are forwarded to `diagnose()`.
"""
function diagnose_model(
    pep::ParameterEstimationProblem;
    opts::EstimationOptions = EstimationOptions(),
    full_analysis::Union{Symbol, Int, Vector{Float64}} = :best,
    interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[],
    run_estimation::Bool = false,
    kwargs...,
)
    # Step 1: Sample data if not already present
    pep_data = if isnothing(pep.data_sample)
        @info "[DIAGNOSE_MODEL] Sampling data (datasize=$(opts.datasize))..."
        sample_problem_data(pep, opts)
    else
        pep
    end

    # Step 2: Transform for transcendentals
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_transformed, tr_info = try
        transform_pep_for_estimation(pep_data, t_var)
    catch e
        @warn "[DIAGNOSE_MODEL] Transcendental transform failed (may not be needed): $e"
        (pep_data, nothing)
    end

    if !isnothing(tr_info)
        @info "[DIAGNOSE_MODEL] Transformed $(length(tr_info.entries)) transcendental(s)"
    end

    # Step 3: Optionally run estimation pipeline
    est_report = nothing
    if run_estimation
        @info "[DIAGNOSE_MODEL] Running estimation pipeline..."
        est_start = time()
        try
            est_opts = EstimationOptions(;
                nooutput = true,
                datasize = opts.datasize,
                time_interval = opts.time_interval,
                noise_level = opts.noise_level,
                ode_solver = opts.ode_solver,
                interpolator = InterpolatorAGPUQ,
                polish_solutions = false,
                polish_solver_solutions = false,
            )
            raw_tuple, analyzed_tuple, uq_est = analyze_parameter_estimation_problem(pep_transformed, est_opts)
            elapsed = time() - est_start
            @info "[DIAGNOSE_MODEL] Estimation completed in $(round(elapsed; digits=1))s"
            # analyzed_tuple[1] is the sorted vector of best ParameterEstimationResults
            est_results = analyzed_tuple[1]
            est_report = _build_estimation_report(pep_transformed, est_results, nothing, elapsed)
        catch e
            @warn "[DIAGNOSE_MODEL] Estimation failed (non-fatal): $e"
        end
    end

    # Step 4: Compute production shooting points
    t_vec = pep_transformed.data_sample["t"]
    n_total = length(t_vec)
    shoot_indices = compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
    # Avoid exact boundary
    if !isempty(shoot_indices) && shoot_indices[1] == 1 && n_total > 2
        shoot_indices[1] = 2
    end
    t_eval_points = unique(sort([t_vec[i] for i in shoot_indices if i >= 1 && i <= n_total]))

    # Step 5: Call diagnose with comprehensive mode
    return diagnose(pep_transformed;
        interpolators = isempty(interpolators) ? _DIAGNOSTIC_DEFAULT_INTERPOLATORS : interpolators,
        t_eval_points = t_eval_points,
        full_analysis = full_analysis,
        estimation_report = est_report,
        data_config = (datasize = opts.datasize, noise_level = opts.noise_level,
                       time_interval = opts.time_interval),
        kwargs...,
    )
end

# ─── Estimation Results Report Builder ──────────────────────────────────

"""
    _build_estimation_report(pep, analyzed_results, uq_report, elapsed) → EstimationResultsReport

Build an `EstimationResultsReport` from estimation pipeline outputs.
`analyzed_results` is the vector of `ParameterEstimationResult` from `analyze_estimation_result`.
"""
function _build_estimation_report(pep::ParameterEstimationProblem,
    analyzed_results, uq_report, elapsed::Float64)

    # analyzed_results is already oracle-sorted (by max relative error against truth,
    # excluding unidentifiable params). Use that ordering — do NOT re-sort by backsolve
    # error, which can select a wrong algebraic branch that happens to have low
    # approximation error but wildly wrong parameter values.
    valid = filter(r -> !isnothing(r.err) && isfinite(r.err), analyzed_results)
    if isempty(valid)
        valid = analyzed_results
    end
    isempty(valid) && error("No estimation results to build report from")

    # Take the first (best oracle-sorted) result
    best = first(valid)
    best_error = isnothing(best.err) ? NaN : best.err

    # Build set of unidentifiable parameter names for flagging
    unident_names = Set{String}()
    for u in best.all_unidentifiable
        push!(unident_names, replace(string(u), "(t)" => ""))
    end

    # Build parameter comparison
    param_comparison = @NamedTuple{name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool, is_unidentifiable::Bool}[]
    for (p, true_val) in pep.p_true
        p_name = replace(string(p), "(t)" => "")
        est_val = NaN
        for (ep, ev) in best.parameters
            if replace(string(ep), "(t)" => "") == p_name
                est_val = ev
                break
            end
        end
        rel_err = abs(true_val) > 1e-15 ? abs(est_val - true_val) / abs(true_val) : abs(est_val - true_val)
        within = true  # default if no UQ
        is_unident = p_name in unident_names
        push!(param_comparison, (name = p_name, true_val = true_val, est_val = est_val,
            rel_error = rel_err, within_ci = within, is_unidentifiable = is_unident))
    end

    # Build state (IC) comparison
    state_comparison = @NamedTuple{name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool}[]
    for (s, true_val) in pep.ic
        s_name = replace(string(s), "(t)" => "")
        # Skip _trfn_ states
        startswith(s_name, "_trfn_") && continue
        est_val = NaN
        for (es, ev) in best.states
            if replace(string(es), "(t)" => "") == s_name
                est_val = ev
                break
            end
        end
        rel_err = abs(true_val) > 1e-15 ? abs(est_val - true_val) / abs(true_val) : abs(est_val - true_val)
        within = true  # default if no UQ
        push!(state_comparison, (name = s_name, true_val = true_val, est_val = est_val,
            rel_error = rel_err, within_ci = within))
    end

    # Update CI coverage if UQ is available (use _find_uq_sigma for SIAN name matching)
    if !isnothing(uq_report) && !isempty(uq_report.param_std)
        for i in eachindex(param_comparison)
            pc = param_comparison[i]
            σ = _find_uq_sigma(pc.name, uq_report)
            if isfinite(σ)
                within = abs(pc.true_val - pc.est_val) < 2 * σ
                param_comparison[i] = (name = pc.name, true_val = pc.true_val,
                    est_val = pc.est_val, rel_error = pc.rel_error, within_ci = within,
                    is_unidentifiable = pc.is_unidentifiable)
            end
        end
    end

    return EstimationResultsReport(
        pep.name, length(valid), best_error, elapsed,
        param_comparison, state_comparison, best,
    )
end

# ─── Backsolve Uncertainty Propagation ─────────────────────────────────

"""
    propagate_backsolve_uncertainty(pep, best_result, uq_report) → BacksolveUQReport

Propagate parameter uncertainty from the shooting point through the backward
ODE integration to initial conditions at t₀ using the delta method:

    Σ_{s(t₀)} = J_g · Σ_{p, s(t_eval)} · J_g'

where J_g = ∂g/∂(p, s(t_eval)) is computed via ForwardDiff.
"""
function propagate_backsolve_uncertainty(pep::ParameterEstimationProblem,
    best_result::ParameterEstimationResult,
    uq_report::UncertaintyReport)

    t_data = pep.data_sample["t"]
    t0 = t_data[1]
    t_shoot = best_result.at_time

    # If estimation was at t0, no backsolve needed — return actual values
    if abs(t_shoot - t0) < 1e-10
        real_states = [s for s in pep.model.original_states
                        if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]
        ic_names = [replace(string(s), "(t)" => "") for s in real_states]
        n_ic = length(ic_names)

        # Get actual estimated ICs
        ic_est = Float64[]
        for s in real_states
            s_name = replace(string(s), "(t)" => "")
            found = false
            for (es, ev) in best_result.states
                if replace(string(es), "(t)" => "") == s_name
                    push!(ic_est, ev); found = true; break
                end
            end
            found || push!(ic_est, NaN)
        end

        # Get true ICs
        ic_true = [get(pep.ic, s, NaN) for s in real_states]

        # At t0, uncertainty comes directly from UQ (no backsolve propagation)
        ic_std = Float64[]
        for s_name in ic_names
            push!(ic_std, _find_uq_sigma(s_name, uq_report))
        end
        # Replace NaN with 0 for missing entries
        ic_std = [isnan(s) ? 0.0 : s for s in ic_std]

        ic_covers = [ic_std[i] > 0 ? abs(ic_true[i] - ic_est[i]) < 2 * ic_std[i] : true
                     for i in 1:n_ic]

        return BacksolveUQReport(
            t_shoot, t0, ic_names, ic_est, ic_true, ic_std,
            ic_covers, Matrix{Float64}(undef, 0, 0), 1.0, true,
        )
    end

    sys = pep.model.system
    params = pep.model.original_parameters
    states = pep.model.original_states

    # Filter out _trfn_ states
    real_states = [s for s in states if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]
    ic_names = [replace(string(s), "(t)" => "") for s in real_states]
    n_params = length(params)
    n_states = length(real_states)

    # Extract estimated parameter values and state ICs
    est_params = Float64[]
    for p in params
        p_name = replace(string(p), "(t)" => "")
        found = false
        for (ep, ev) in best_result.parameters
            if replace(string(ep), "(t)" => "") == p_name
                push!(est_params, ev)
                found = true
                break
            end
        end
        found || push!(est_params, NaN)
    end

    est_ics = Float64[]
    for s in real_states
        s_name = replace(string(s), "(t)" => "")
        found = false
        for (es, ev) in best_result.states
            if replace(string(es), "(t)" => "") == s_name
                push!(est_ics, ev)
                found = true
                break
            end
        end
        found || push!(est_ics, NaN)
    end

    # True ICs for coverage check
    ic_true = Float64[]
    for s in real_states
        push!(ic_true, get(pep.ic, s, NaN))
    end

    # Build the backsolve closure: θ = [params..., states_at_t_shoot...] → states_at_t0
    # We need to forward-solve from t0 to t_shoot with estimated params, get states at t_shoot,
    # then build a closure that takes those values and back-solves
    completed_sys = ModelingToolkit.complete(sys)
    completed_states = ModelingToolkit.unknowns(completed_sys)
    completed_params = ModelingToolkit.parameters(completed_sys)

    function backsolve_closure(θ)
        p_vals = θ[1:n_params]
        s_vals_at_shoot = θ[n_params+1:n_params+length(states)]

        u0_dict = Dict(completed_states .=> s_vals_at_shoot)
        p_dict = Dict(completed_params .=> p_vals)

        prob = ODEProblem(completed_sys, merge(u0_dict, p_dict), (t_shoot, t0))
        sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas4P());
            abstol = 1e-12, reltol = 1e-12, saveat = Float64[])

        # Extract states at t0
        result = zeros(eltype(θ), length(states))
        for i in eachindex(states)
            result[i] = sol(t0)[i]
        end
        return result
    end

    # Get states at t_shoot by forward-solving from estimated ICs
    states_at_shoot = try
        # Use the estimated solution if available
        if !isnothing(best_result.solution)
            [best_result.solution(t_shoot)[i] for i in eachindex(states)]
        else
            # Forward solve
            all_ics = Float64[]
            for s in states
                s_name = replace(string(s), "(t)" => "")
                found = false
                for (es, ev) in best_result.states
                    if replace(string(es), "(t)" => "") == s_name
                        push!(all_ics, ev)
                        found = true
                        break
                    end
                end
                found || push!(all_ics, 0.0)
            end

            u0_dict = Dict(completed_states .=> all_ics)
            p_dict = Dict(completed_params .=> est_params)
            prob = ODEProblem(completed_sys, merge(u0_dict, p_dict), (t0, t_shoot))
            sol = OrdinaryDiffEq.solve(prob, AutoVern9(Rodas4P()); abstol = 1e-12, reltol = 1e-12)
            [sol(t_shoot)[i] for i in eachindex(states)]
        end
    catch e
        @warn "[BACKSOLVE_UQ] Failed to get states at shooting point: $e"
        return BacksolveUQReport(t_shoot, t0, ic_names, est_ics, ic_true,
            fill(NaN, n_states), fill(false, n_states),
            Matrix{Float64}(undef, 0, 0), NaN, false)
    end

    # Build θ point
    θ_point = vcat(est_params, states_at_shoot)

    # Compute Jacobian via ForwardDiff
    J_g = try
        ForwardDiff.jacobian(backsolve_closure, θ_point)
    catch e
        @warn "[BACKSOLVE_UQ] ForwardDiff Jacobian failed: $e"
        return BacksolveUQReport(t_shoot, t0, ic_names, est_ics, ic_true,
            fill(NaN, n_states), fill(false, n_states),
            Matrix{Float64}(undef, 0, 0), NaN, false)
    end

    # Extract the sub-block of Σ_x corresponding to [params, order-0 states]
    # from the UQ report. UQ param_labels include derivative variables — we only
    # want params and order-0 state ICs.
    n_theta = n_params + length(states)
    Σ_sub = zeros(n_theta, n_theta)

    # Build mapping: θ index → UQ param index
    theta_labels = String[]
    for p in params
        push!(theta_labels, replace(string(p), "(t)" => ""))
    end
    for s in states
        push!(theta_labels, replace(string(s), "(t)" => ""))
    end

    for i in 1:n_theta
        for j in 1:n_theta
            # Find matching indices in UQ param_labels
            ui = _find_uq_param_index(theta_labels[i], uq_report)
            uj = _find_uq_param_index(theta_labels[j], uq_report)
            if !isnothing(ui) && !isnothing(uj)
                Σ_sub[i, j] = uq_report.param_covariance[ui, uj]
            end
        end
    end

    # Propagate: Σ_ic = J_g · Σ_sub · J_g'
    Σ_ic = J_g * Σ_sub * J_g'

    # Extract only the real (non-trfn) state rows from J_g result
    # J_g returns all states, but we only want real ones
    real_indices = [i for (i, s) in enumerate(states)
                    if !startswith(replace(string(s), "(t)" => ""), "_trfn_")]

    ic_std = [sqrt(max(Σ_ic[i, i], 0.0)) for i in real_indices]
    ic_estimated = est_ics

    # Extract the backsolve result at t0 for estimated values
    try
        result_at_t0 = backsolve_closure(θ_point)
        ic_estimated = [result_at_t0[i] for i in real_indices]
    catch
        # Fall back to the estimation ICs
    end

    ic_ci_covers = [abs(ic_true[i] - ic_estimated[i]) < 2 * ic_std[i] for i in 1:n_states]

    # Amplification = max singular value of J_g
    svs = try
        svdvals(J_g[real_indices, :])
    catch
        [NaN]
    end
    amplification = maximum(svs; init = NaN)

    return BacksolveUQReport(
        t_shoot, t0, ic_names, ic_estimated, ic_true,
        ic_std, ic_ci_covers,
        J_g[real_indices, :], amplification, true,
    )
end

"""Find the index of a variable name in the UQ report's param_labels."""
function _find_uq_param_index(name::String, uq::UncertaintyReport)
    for (i, label) in enumerate(uq.param_labels)
        if label == name
            return i
        end
        # Also try parsed base name for derivative vars like "x1_0"
        parsed = parse_derivative_variable_name(label)
        if !isnothing(parsed)
            base, order = parsed
            if order == 0 && String(base) == name
                return i
            end
        end
    end
    return nothing
end

# ─── UQ Name-Matching Helper ─────────────────────────────────────────

"""
    _find_uq_sigma(name, uq) → Float64

Look up the standard deviation for variable `name` in the UQ report,
trying exact match first, then SIAN-style `_0` suffix match (e.g. `a_0` → `a`).
Returns `NaN` if no match found.
"""
function _find_uq_sigma(name::String, uq::UncertaintyReport)
    # Exact match
    for j in eachindex(uq.param_labels)
        if uq.param_labels[j] == name
            return uq.param_std[j]
        end
    end
    # SIAN-style match: "a_0" matches "a"
    for j in eachindex(uq.param_labels)
        parsed = parse_derivative_variable_name(uq.param_labels[j])
        if !isnothing(parsed)
            base, order = parsed
            if order == 0 && String(base) == name
                return uq.param_std[j]
            end
        end
    end
    return NaN
end

# ─── Estimation Results HTML Section ──────────────────────────────────

"""
Write the estimation results section to the HTML report.
Shows a comparison table of true vs estimated values with CI coverage.
"""
function _write_html_estimation_section(io, est::EstimationResultsReport;
    uq::Union{Nothing, UncertaintyReport} = nothing)

    println(io, "<details open><summary>Estimation Results</summary><div class=\"detail-body\">")

    # Summary line
    err_badge = est.best_error < 0.01 ? """<span class="badge badge-easy">Low Error</span>""" :
        est.best_error < 0.10 ? """<span class="badge badge-moderate">Moderate Error</span>""" :
        """<span class="badge badge-hard">High Error</span>"""
    println(io, """<div class="provenance">Best error: $(_fmt(est.best_error)) &middot; $(est.n_results) solution(s) &middot; $(round(est.estimation_time_seconds; digits=1))s $err_badge</div>""")

    has_uq = !isnothing(uq) && !isempty(uq.param_std)

    # Parameters table
    if !isempty(est.param_comparison)
        println(io, "<h4>Parameters</h4>")
        println(io, "<table><tr><th>Parameter</th><th>True</th><th>Estimated</th><th>Rel Error</th>")
        if has_uq
            println(io, "<th>±2σ CI</th><th>Coverage</th>")
        end
        println(io, "</tr>")

        for pc in est.param_comparison
            is_unident = pc.is_unidentifiable
            err_cls = is_unident ? "" : pc.rel_error < 0.01 ? "err-ok" : pc.rel_error < 0.10 ? "err-warn" : "err-bad"
            pretty = _pretty_name(pc.name)
            raw_esc = replace(pc.name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

            unident_badge = is_unident ? """ <span class="badge badge-moderate">unident.</span>""" : ""
            row_style = is_unident ? " style=\"opacity:0.6;\"" : ""
            print(io, """<tr$row_style><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>$unident_badge</td>""")
            print(io, "<td>$(_fmt(pc.true_val))</td>")
            print(io, "<td>$(_fmt(pc.est_val))</td>")
            print(io, """<td class="$err_cls">$(_fmt_pct(pc.rel_error))</td>""")

            if has_uq
                if is_unident
                    # Skip CI for unidentifiable parameters
                    print(io, "<td>—</td><td>—</td>")
                else
                    σ = _find_uq_sigma(pc.name, uq)
                    if isfinite(σ)
                        ci_lo = pc.est_val - 1.96 * σ
                        ci_hi = pc.est_val + 1.96 * σ
                        within = abs(pc.true_val - pc.est_val) < 2 * σ
                        cov_mark = within ? """<span style="color:var(--easy);">✓</span>""" :
                            """<span style="color:var(--hard);">✗</span>"""
                        print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td><td>$cov_mark</td>")
                    else
                        print(io, "<td>—</td><td>—</td>")
                    end
                end
            end
            println(io, "</tr>")
        end
        println(io, "</table>")
    end

    # States (ICs) table — with CI columns when UQ is available
    if !isempty(est.state_comparison)
        println(io, "<h4>Initial Conditions</h4>")
        println(io, "<table><tr><th>State</th><th>True</th><th>Estimated</th><th>Rel Error</th>")
        if has_uq
            println(io, "<th>±2σ CI</th><th>Coverage</th>")
        end
        println(io, "</tr>")

        for sc in est.state_comparison
            err_cls = sc.rel_error < 0.01 ? "err-ok" : sc.rel_error < 0.10 ? "err-warn" : "err-bad"
            pretty = _pretty_name(sc.name)
            raw_esc = replace(sc.name, "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

            print(io, """<tr><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>(0)</td>""")
            print(io, "<td>$(_fmt(sc.true_val))</td>")
            print(io, "<td>$(_fmt(sc.est_val))</td>")
            print(io, """<td class="$err_cls">$(_fmt_pct(sc.rel_error))</td>""")

            if has_uq
                σ = _find_uq_sigma(sc.name, uq)
                if isfinite(σ)
                    ci_lo = sc.est_val - 1.96 * σ
                    ci_hi = sc.est_val + 1.96 * σ
                    within = abs(sc.true_val - sc.est_val) < 2 * σ
                    cov_mark = within ? """<span style="color:var(--easy);">✓</span>""" :
                        """<span style="color:var(--hard);">✗</span>"""
                    print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td><td>$cov_mark</td>")
                else
                    print(io, "<td>—</td><td>—</td>")
                end
            end
            println(io, "</tr>")
        end
        println(io, "</table>")
    end

    println(io, "</div></details>")
end

# ─── Backsolve UQ HTML Section ──────────────────────────────────────────

"""
Write the backsolve UQ section to the HTML report.
Shows uncertainty propagation from shooting point through backward ODE to t₀.
"""
function _write_html_backsolve_uq_section(io, bq::BacksolveUQReport)
    println(io, "<details><summary>Backsolve Uncertainty (t=$(round(bq.t_shoot; digits=4)) → t₀=$(round(bq.t0; digits=4)))</summary><div class=\"detail-body\">")

    amp_color = bq.amplification < 10 ? "var(--easy)" : bq.amplification < 100 ? "var(--moderate)" : "var(--hard)"
    println(io, """<div class="provenance">Uncertainty propagated from shooting point t = $(round(bq.t_shoot; digits=4)) to t₀ = $(round(bq.t0; digits=4)) via backward ODE Jacobian (ForwardDiff). Amplification factor: <span style="color:$amp_color;font-weight:600;">$(_fmt(bq.amplification))×</span> (max singular value of J<sub>g</sub>).</div>""")

    # IC table
    println(io, "<table><tr><th>State IC</th><th>True</th><th>Estimated</th><th>σ (propagated)</th><th>95% CI</th><th>Coverage</th></tr>")

    for i in eachindex(bq.ic_names)
        pretty = _pretty_name(bq.ic_names[i])
        raw_esc = replace(bq.ic_names[i], "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

        ci_lo = bq.ic_estimated[i] - 1.96 * bq.ic_std[i]
        ci_hi = bq.ic_estimated[i] + 1.96 * bq.ic_std[i]
        cov_mark = bq.ic_ci_covers[i] ? """<span style="color:var(--easy);">✓</span>""" :
            """<span style="color:var(--hard);">✗</span>"""

        print(io, """<tr><td><span title="$raw_esc" class="math" style="font-weight:600;">$pretty</span>(0)</td>""")
        print(io, "<td>$(_fmt(bq.ic_true[i]))</td>")
        print(io, "<td>$(_fmt(bq.ic_estimated[i]))</td>")
        print(io, "<td>$(_fmt(bq.ic_std[i]))</td>")
        print(io, "<td>[$(_fmt(ci_lo)), $(_fmt(ci_hi))]</td>")
        println(io, "<td>$cov_mark</td></tr>")
    end
    println(io, "</table>")

    println(io, "</div></details>")
end
