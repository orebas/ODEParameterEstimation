module ReceptorFastProbes

using Dates
using HomotopyContinuation
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Printf
using Random
using Symbolics

const OPE = ODEParameterEstimation
const HC = HomotopyContinuation

export OPE, HC, PARAM_NAMES, TRUTH_PARAMS, SWAP_PARAMS
export env_bool, env_float, env_int, env_list, output_path, write_jsonl
export receptor_setup, alternative_receptor_problem, shooting_indices, oracle_params
export oracle_params_for_indices, parameterized_system, safe_mixed_volume
export fresh_solve, track_solve, solution_sets, path_histogram
export classify_solutions, is_physical_solution, residual_norms, full_residual_norms
export unscale_solution, branch_errors, data_var_order, equation_features, rank_matrix, select_trim, summarize_template
export print_summary_table

const PARAM_NAMES = ["R1tot", "R2tot", "kon1", "kon2", "koff1", "koff2"]
const TRUTH_PARAMS = [1.10, 0.70, 0.80, 1.30, 0.40, 0.60]
const SWAP_PARAMS = [0.70, 1.10, 1.30, 0.80, 0.60, 0.40]

"""
    env_list(name, default; parse_item = identity)

Parse comma-separated environment variables used by the probe scripts.
"""
function env_list(name::AbstractString, default; parse_item = identity)
    raw = get(ENV, name, "")
    isempty(strip(raw)) && return default
    return [parse_item(strip(x)) for x in split(raw, ",") if !isempty(strip(x))]
end

env_bool(name::AbstractString, default::Bool = false) =
    lowercase(strip(get(ENV, name, default ? "1" : "0"))) in ("1", "true", "yes", "on")

function env_int(name::AbstractString, default::Int)
    raw = get(ENV, name, "")
    isempty(strip(raw)) && return default
    return parse(Int, strip(raw))
end

function env_float(name::AbstractString, default::Float64)
    raw = get(ENV, name, "")
    isempty(strip(raw)) && return default
    return parse(Float64, strip(raw))
end

function output_path(name::AbstractString)
    root = get(ENV, "ODEPE_RECEPTOR_FAST_OUT", joinpath(@__DIR__, "out"))
    mkpath(root)
    return joinpath(root, name)
end

function _json(x)
    if x === nothing
        return "null"
    elseif x isa Bool
        return x ? "true" : "false"
    elseif x isa Integer
        return string(x)
    elseif x isa AbstractFloat
        return isfinite(x) ? string(x) : "\"" * string(x) * "\""
    elseif x isa Symbol
        return _json(String(x))
    elseif x isa AbstractString
        escaped = replace(x, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n", "\t" => "\\t")
        return "\"" * escaped * "\""
    elseif x isa AbstractVector || x isa Tuple
        return "[" * join((_json(v) for v in x), ",") * "]"
    elseif x isa AbstractDict
        parts = String[]
        for k in sort(collect(keys(x)); by = string)
            push!(parts, _json(string(k)) * ":" * _json(x[k]))
        end
        return "{" * join(parts, ",") * "}"
    else
        return _json(string(x))
    end
end

write_jsonl(io, record::AbstractDict) = println(io, _json(record))

function _ordered_vars(equations)
    vars = Any[]
    seen = Set{Any}()
    for eq in equations
        for v in Symbolics.get_variables(eq)
            if !(v in seen)
                push!(vars, v)
                push!(seen, v)
            end
        end
    end
    return vars
end

function _ordered_model(pep)
    if pep.model isa OPE.OrderedODESystem
        return pep.model
    elseif hasproperty(pep.model, :system) && pep.model.system isa OPE.OrderedODESystem
        return pep.model.system
    else
        _, _, states, params = OPE.unpack_ODE(pep.model)
        return OPE.OrderedODESystem(pep.model, states, params)
    end
end

"""
    receptor_setup(; datasize=201, model_kind=:original)

Build the SIAN template context shared by all receptor probes. `model_kind` can
be `:original`, `:sum_ca`, or `:sum_diff`.
"""
function receptor_setup(; datasize::Int = env_int("ODEPE_RECEPTOR_FAST_DATASIZE", 201),
        model_kind::Symbol = :original,
        infolevel::Int = 0)
    pep = model_kind == :original ? OPE.receptor_subtype_binding_branch() :
        alternative_receptor_problem(model_kind)

    opts = EstimationOptions(datasize = datasize, noise_level = 0.0,
        use_si_template = true, nooutput = true, diagnostics = false)
    spep = sample_problem_data(pep, opts)
    setup = OPE.setup_parameter_estimation(spep; interpolator = OPE.aaad, nooutput = true)
    DD = setup.good_DD
    model = _ordered_model(spep)
    template_equations, derivative_dict, _, _, _, metadata =
        OPE.get_si_equation_system(model, spep.measured_quantities, spep.data_sample;
            DD = DD, infolevel = infolevel)
    template_DD = OPE.ensure_si_template_dd_support(
        model, spep.measured_quantities, DD, derivative_dict)
    data_vars = OPE.extract_data_variables_from_DD(template_DD)
    data_set = Set(data_vars)
    solve_vars = [v for v in _ordered_vars(template_equations) if !(v in data_set)]

    full_equations = hasproperty(metadata, :full_equations) ? metadata.full_equations :
        get(metadata, :full_equations, template_equations)
    selected_ids = hasproperty(metadata, :selected_equation_indices) ?
        collect(metadata.selected_equation_indices) : collect(1:length(template_equations))
    dropped_ids = hasproperty(metadata, :dropped_equation_indices) ?
        collect(metadata.dropped_equation_indices) : Int[]

    return (pep = pep, spep = spep, model_kind = model_kind,
        setup = setup, template_DD = template_DD,
        equations = collect(template_equations), full_equations = collect(full_equations),
        selected_equation_indices = selected_ids, dropped_equation_indices = dropped_ids,
        data_vars = collect(data_vars), solve_vars = collect(solve_vars),
        t_vector = spep.data_sample["t"], measured_quantities = spep.measured_quantities)
end

function alternative_receptor_problem(kind::Symbol)
    @parameters R1tot R2tot kon1 kon2 koff1 koff2
    @variables t
    D = Differential(t)
    observables = @variables y1(t) y2(t)
    p_true = [1.10, 0.70, 0.80, 1.30, 0.40, 0.60]

    if kind == :sum_ca
        states = @variables L(t) S(t) Ca(t)
        Cb = S - Ca
        flux_a = kon1 * L * (R1tot - Ca) - koff1 * Ca
        flux_b = kon2 * L * (R2tot - Cb) - koff2 * Cb
        equations = [
            D(L) ~ -(flux_a + flux_b),
            D(S) ~ flux_a + flux_b,
            D(Ca) ~ flux_a,
        ]
        ic_true = [2.00, 0.30, 0.10]
        name = "receptor_subtype_binding_sum_ca"
    elseif kind == :sum_diff
        states = @variables L(t) S(t) Delta(t)
        Ca = (S + Delta) / 2
        Cb = (S - Delta) / 2
        flux_a = kon1 * L * (R1tot - Ca) - koff1 * Ca
        flux_b = kon2 * L * (R2tot - Cb) - koff2 * Cb
        equations = [
            D(L) ~ -(flux_a + flux_b),
            D(S) ~ flux_a + flux_b,
            D(Delta) ~ flux_a - flux_b,
        ]
        ic_true = [2.00, 0.30, -0.10]
        name = "receptor_subtype_binding_sum_diff"
    else
        error("Unknown alternative receptor model kind: $kind")
    end

    measured_quantities = [y1 ~ states[1], y2 ~ states[2]]
    model, mq = OPE.create_ordered_ode_system(
        name, states, [R1tot, R2tot, kon1, kon2, koff1, koff2],
        equations, measured_quantities)

    return ParameterEstimationProblem(
        name, model, mq, nothing, [0.0, 8.0], nothing,
        OrderedDict([R1tot, R2tot, kon1, kon2, koff1, koff2] .=> p_true),
        OrderedDict(states .=> ic_true),
        0)
end

function shooting_indices(S; n_points::Int = env_int("ODEPE_RECEPTOR_FAST_POINTS", 3))
    return OPE.compute_shooting_indices(n_points, length(S.t_vector); warp = true, beta = 3.0)
end

function oracle_params(S, t)
    interpolants = OPE.build_perfect_interpolants(S.spep, Float64(t), 12)
    return OPE.evaluate_data_vars_at_point(
        interpolants, S.data_vars, S.template_DD, S.measured_quantities, Float64(t))
end

oracle_params_for_indices(S, indices) = [oracle_params(S, S.t_vector[i]) for i in indices]

function canonicalize_data_placeholders(S, equations)
    substitutions = Dict{Any, Any}()
    for data_var in S.data_vars
        name = string(data_var)
        channel = occursin("y1", name) ? "y1" : occursin("y2", name) ? "y2" : nothing
        isnothing(channel) && continue
        order = data_var_order(data_var)
        substitutions[Symbolics.variable(Symbol("$(channel)_$(order)"))] = data_var
    end
    return [Symbolics.substitute(eq, substitutions) for eq in equations]
end

function parameterized_system(S, equations = S.equations; scale::Bool = true,
        scale_params = nothing)
    equations = canonicalize_data_placeholders(S, equations)
    hc_system, hc_vars, hc_params =
        OPE.convert_to_hc_format_with_params(equations, S.solve_vars, S.data_vars)
    scales = ones(Float64, length(hc_vars))
    if scale
        if isnothing(scale_params)
            idx = shooting_indices(S)
            scale_params = oracle_params_for_indices(S, idx)
        end
        scales = OPE.compute_column_scales(S.solve_vars, S.data_vars, scale_params)
        hc_system = OPE.scale_hc_system(hc_system, hc_vars, scales)
    end
    return (system = hc_system, hc_vars = hc_vars, hc_params = hc_params, scales = scales)
end

function safe_mixed_volume(system)
    try
        return Int(HC.mixed_volume(system))
    catch err
        return "failed: " * sprint(showerror, err)
    end
end

function path_histogram(res)
    counts = Dict{String, Int}()
    for pr in HC.path_results(res)
        key = string(try pr.return_code catch; :unknown end)
        counts[key] = get(counts, key, 0) + 1
    end
    return counts
end

function solution_sets(res; real_tol::Float64 = env_float("ODEPE_RECEPTOR_FAST_REAL_TOL", 1e-9))
    finite = try
        HC.solutions(res; only_nonsingular = false, only_finite = true)
    catch
        Any[]
    end
    real = try
        HC.solutions(res; only_nonsingular = false, only_finite = true,
            only_real = true, real_atol = real_tol)
    catch
        Any[]
    end
    return (finite = finite, real = real)
end

function fresh_solve(sys, p; show_progress::Bool = false)
    elapsed = @elapsed res = HC.solve(sys; target_parameters = p, show_progress = show_progress)
    sets = solution_sets(res)
    return (result = res, seconds = elapsed, finite = sets.finite, real = sets.real,
        histogram = path_histogram(res),
        ntracked = try Int(HC.ntracked(res)) catch; missing end)
end

function track_solve(sys, starts, p0, p1; show_progress::Bool = false, kwargs...)
    elapsed = @elapsed res = HC.solve(sys, starts;
        start_parameters = p0, target_parameters = p1, show_progress = show_progress, kwargs...)
    sets = solution_sets(res)
    return (result = res, seconds = elapsed, finite = sets.finite, real = sets.real,
        histogram = path_histogram(res),
        success = count(pr -> (try pr.return_code == :success catch; false end), HC.path_results(res)),
        started = length(starts))
end

function _substitute_residual(equations, solve_vars, data_vars, x, p)
    substitutions = Dict{Any, Any}()
    for (i, var) in enumerate(solve_vars)
        i <= length(x) && (substitutions[var] = x[i])
    end
    for (i, var) in enumerate(data_vars)
        i <= length(p) && (substitutions[var] = p[i])
    end
    vals = ComplexF64[]
    for eq in equations
        push!(vals, ComplexF64(Symbolics.value(Symbolics.substitute(eq, substitutions))))
    end
    return vals
end

function residual_norms(S, x_true, p; equations = S.equations)
    vals = _substitute_residual(equations, S.solve_vars, S.data_vars, x_true, p)
    return (norm2 = norm(vals), maxabs = isempty(vals) ? 0.0 : maximum(abs.(vals)))
end

function full_residual_norms(S, x_true, p)
    return residual_norms(S, x_true, p; equations = S.full_equations)
end

function unscale_solution(scales, sol)
    return ComplexF64[scales[i] * sol[i] for i in 1:min(length(scales), length(sol))]
end

function param_indices(S)
    mapping = Dict{String, Int}()
    for (i, v) in enumerate(S.solve_vars)
        mapping[string(v)] = i
    end
    return [haskey(mapping, name) ? mapping[name] : get(mapping, name * "_0", 0) for name in PARAM_NAMES]
end

function max_relative_error(vals, truth)
    errs = Float64[]
    for i in eachindex(truth)
        denom = max(abs(truth[i]), 1e-12)
        push!(errs, abs(real(vals[i]) - truth[i]) / denom)
    end
    return maximum(errs)
end

function branch_errors(S, x_true)
    inds = param_indices(S)
    if any(==(0), inds)
        return (truth = Inf, swap = Inf)
    end
    vals = [x_true[i] for i in inds]
    return (truth = max_relative_error(vals, TRUTH_PARAMS),
        swap = max_relative_error(vals, SWAP_PARAMS))
end

function classify_solutions(S, sols, scales, p;
        branch_tol::Float64 = env_float("ODEPE_RECEPTOR_FAST_BRANCH_TOL", 1e-2),
        residual_tol::Float64 = env_float("ODEPE_RECEPTOR_FAST_RESIDUAL_TOL", 1e-6))
    n_truth = 0
    n_swap = 0
    n_full_valid = 0
    n_physical = 0
    best_truth = Inf
    best_swap = Inf
    full_max = Float64[]
    for sol in sols
        x_true = unscale_solution(scales, sol)
        errs = branch_errors(S, x_true)
        best_truth = min(best_truth, errs.truth)
        best_swap = min(best_swap, errs.swap)
        errs.truth <= branch_tol && (n_truth += 1)
        errs.swap <= branch_tol && (n_swap += 1)
        full_res = try full_residual_norms(S, x_true, p) catch; (maxabs = Inf,) end
        push!(full_max, Float64(full_res.maxabs))
        full_res.maxabs <= residual_tol && (n_full_valid += 1)
        is_physical_solution(S, x_true) && (n_physical += 1)
    end
    return Dict(
        "n_solutions" => length(sols),
        "n_truth_like" => n_truth,
        "n_swap_like" => n_swap,
        "truth_present" => n_truth > 0,
        "swap_present" => n_swap > 0,
        "best_truth_relerr" => best_truth,
        "best_swap_relerr" => best_swap,
        "n_full_valid" => n_full_valid,
        "n_physical" => n_physical,
        "max_full_residual" => isempty(full_max) ? Inf : maximum(full_max),
        "median_full_residual" => isempty(full_max) ? Inf : sort(full_max)[cld(length(full_max), 2)],
    )
end

function _find_var_index(S, names)
    name_set = Set(names)
    for (i, v) in enumerate(S.solve_vars)
        string(v) in name_set && return i
    end
    return 0
end

function is_physical_solution(S, x_true; tol::Float64 = 1e-8)
    inds = param_indices(S)
    if !any(==(0), inds)
        all(real(x_true[i]) > -tol && isfinite(real(x_true[i])) for i in inds) || return false
    end
    l0 = _find_var_index(S, ["L", "L_0"])
    ca0 = _find_var_index(S, ["Ca", "Ca_0"])
    cb0 = _find_var_index(S, ["Cb", "Cb_0"])
    s0 = _find_var_index(S, ["S", "S_0"])
    if l0 != 0 && real(x_true[l0]) < -tol
        return false
    end
    if ca0 != 0 && real(x_true[ca0]) < -tol
        return false
    end
    if cb0 != 0 && real(x_true[cb0]) < -tol
        return false
    end
    if s0 != 0 && real(x_true[s0]) < -tol
        return false
    end
    return true
end

function equation_features(S, eq, idx::Int)
    vars = Symbolics.get_variables(eq)
    data_orders = Int[]
    solve_count = 0
    text = string(eq)
    for m in eachmatch(r"y\d+_(\d+)", text)
        push!(data_orders, parse(Int, m.captures[1]))
    end
    for m in eachmatch(r"Differential\(t,\s*(\d+)\)\(y\d+\(t\)\)", text)
        push!(data_orders, parse(Int, m.captures[1]))
    end
    if occursin(r"(^|[^A-Za-z0-9_])y\d+\(t\)", text)
        push!(data_orders, 0)
    end
    for v in vars
        if any(d -> isequal(d, v), S.data_vars)
            push!(data_orders, data_var_order(v))
        elseif any(s -> isequal(s, v), S.solve_vars)
            solve_count += 1
        end
    end
    return (idx = idx, data_present = !isempty(data_orders),
        max_data_order = isempty(data_orders) ? -1 : maximum(data_orders),
        solve_var_count = solve_count,
        total_var_count = length(vars),
        text_len = length(string(eq)))
end

function data_var_order(v)
    text = string(v)
    m = match(r"Differential\(t,\s*(\d+)\)", text)
    return isnothing(m) ? 0 : parse(Int, m.captures[1])
end

function rank_matrix(S; seed::Int = 20260528)
    rng = MersenneTwister(seed)
    Jsym = Symbolics.jacobian(collect(S.full_equations), S.solve_vars)
    substitutions = Dict{Any, Any}()
    for v in S.solve_vars
        substitutions[v] = rand(rng) + 0.25
    end
    for v in S.data_vars
        substitutions[v] = rand(rng) + 0.25
    end
    J = Matrix{Float64}(undef, size(Jsym, 1), size(Jsym, 2))
    for i in axes(Jsym, 1), j in axes(Jsym, 2)
        J[i, j] = Float64(Symbolics.value(Symbolics.substitute(Jsym[i, j], substitutions)))
    end
    return J
end

function greedy_basis_from_order(J, order; target_rank::Int = size(J, 2), atol::Float64 = 1e-9)
    selected = Int[]
    current = zeros(Float64, 0, size(J, 2))
    current_rank = 0
    for idx in order
        trial = vcat(current, J[idx:idx, :])
        trial_rank = rank(trial; atol = atol)
        if trial_rank > current_rank
            push!(selected, idx)
            current = trial
            current_rank = trial_rank
            current_rank >= target_rank && break
        end
    end
    return selected, current_rank
end

function trim_order(S, policy::Symbol; seed::Int = 1, max_pin_order::Union{Nothing, Int} = nothing)
    feats = [equation_features(S, eq, i) for (i, eq) in enumerate(S.full_equations)]
    indices = collect(eachindex(S.full_equations))

    order = if policy == :current
        collect(indices)
    elseif policy == :random
        rng = MersenneTwister(seed)
        shuffle(rng, collect(indices))
    elseif policy == :pins_low_order_first
        sort(collect(indices); by = i -> (
            feats[i].data_present ? 0 : 1,
            feats[i].max_data_order < 0 ? 99 : feats[i].max_data_order,
            feats[i].solve_var_count,
            feats[i].text_len,
            i))
    elseif policy == :support_first
        sort(collect(indices); by = i -> (feats[i].solve_var_count, feats[i].text_len, i))
    else
        error("unknown trim policy $policy")
    end

    if !isnothing(max_pin_order)
        allowed = Int[]
        forbidden = Int[]
        for i in order
            if feats[i].data_present && feats[i].max_data_order > max_pin_order
                push!(forbidden, i)
            else
                push!(allowed, i)
            end
        end
        order = vcat(allowed, forbidden)
    end
    return order, feats
end

function select_trim(S, policy::Symbol; seed::Int = 1,
        max_pin_order::Union{Nothing, Int} = nothing, J = nothing)
    J = isnothing(J) ? rank_matrix(S; seed = 20260528) : J
    order, feats = trim_order(S, policy; seed = seed, max_pin_order = max_pin_order)
    selected, rk = greedy_basis_from_order(J, order; target_rank = length(S.solve_vars))
    emergency = Int[]
    if !isnothing(max_pin_order)
        for i in selected
            f = feats[i]
            if f.data_present && f.max_data_order > max_pin_order
                push!(emergency, i)
            end
        end
    end
    return (selected = selected, rank = rk, emergency = emergency,
        equations = S.full_equations[selected], features = feats)
end

function summarize_template(S; compute_mixed_volume::Bool = false)
    rec = Dict{String, Any}(
        "model_kind" => string(S.model_kind),
        "n_equations" => length(S.equations),
        "n_full_equations" => length(S.full_equations),
        "n_solve_vars" => length(S.solve_vars),
        "n_data_vars" => length(S.data_vars),
        "selected_equation_indices" => S.selected_equation_indices,
        "dropped_equation_indices" => S.dropped_equation_indices,
        "max_data_order_selected" => maximum([equation_features(S, eq, i).max_data_order for (i, eq) in enumerate(S.equations)]),
    )
    if compute_mixed_volume
        ps = parameterized_system(S; scale = false)
        rec["mixed_volume"] = safe_mixed_volume(ps.system)
    end
    return rec
end

function print_summary_table(records)
    isempty(records) && return
    keys_to_show = ["case", "policy", "segment", "eta", "seed", "success",
        "n_solutions", "truth_present", "swap_present", "seconds"]
    for k in keys_to_show
        any(r -> haskey(r, k), records) && @printf("%-18s", k[1:min(end, 17)])
    end
    println()
    for r in records
        for k in keys_to_show
            if any(rr -> haskey(rr, k), records)
                val = get(r, k, "")
                if val isa AbstractFloat
                    @printf("%-18.4g", val)
                else
                    text = string(val)
                    @printf("%-18s", text[1:min(end, 17)])
                end
            end
        end
        println()
    end
end

end # module
