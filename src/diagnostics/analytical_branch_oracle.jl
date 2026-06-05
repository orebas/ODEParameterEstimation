# Analytical branch oracle for Wallaby finite-branch systems.
#
# This is a standalone diagnostic, intended to be included manually:
#
#   julia --startup-file=no -e 'using ODEParameterEstimation; include("src/diagnostics/analytical_branch_oracle.jl"); run_wallaby_branch_oracles()'
#
# It uses only the model definition and truth values from PEB's generated data
# scripts. It does not call any benchmark estimator and does not read noisy data.

using Dates
using HomotopyContinuation
using ModelingToolkit
using OrderedCollections
using OrdinaryDiffEq
using Symbolics

const ORACLE_WALLABY_M2_SYSTEMS = ("daisy_mamil4", "seir", "slow_fast", "biohydrogenation")
const ORACLE_EXPECTED_M = Dict(
    "daisy_mamil4" => (algebraic = 2, physical = 2),
    "seir" => (algebraic = 2, physical = 2),
    "slow_fast" => (algebraic = 2, physical = 1),
    "biohydrogenation" => (algebraic = 2, physical = 1),
)

"""
    load_wallaby_generated_problem(path) -> ParameterEstimationProblem

Load only the model/truth portion of a PEB generated-data Julia script. The
sampling and file-writing tail is deliberately not executed.
"""
function load_wallaby_generated_problem(path::AbstractString)
    source = read(path, String)
    start_idx = findfirst("const t =", source)
    isnothing(start_idx) && error("Could not find `const t =` in generated script: $path")
    stop_idx = findfirst(r"\n\s*opts\s*=", source)
    isnothing(stop_idx) && error("Could not find `opts =` boundary in generated script: $path")

    body = source[first(start_idx):prevind(source, first(stop_idx))]
    mod = Module(Symbol(:WallabyGeneratedProblem, hash(path)))
    Core.eval(mod, :(using ModelingToolkit))
    Core.eval(mod, :(using OrdinaryDiffEq))
    Core.eval(mod, :(using ODEParameterEstimation))
    Core.eval(mod, :(using OrderedCollections))
    Base.include_string(mod, body, path)
    return Base.invokelatest(() -> getfield(mod, :PEP))
end

_strip_time_suffix(name::AbstractString) = replace(String(name), "(t)" => "")

function _base_name(v)
    s = _strip_time_suffix(string(v))
    return s
end

function _numeric_float(x)
    y = Symbolics.unwrap(Symbolics.simplify(x))
    if y isa Number
        return Float64(real(y))
    end
    try
        return Float64(real(y))
    catch
        # Last-resort path for fully numeric symbolic remnants such as rationals.
        return Float64(real(Core.eval(@__MODULE__, Meta.parse(string(y)))))
    end
end

function _truth_substitution(pep; t0::Float64 = 0.0)
    t = ModelingToolkit.get_iv(pep.model.system)
    subst = Dict{Any, Any}(t => t0)
    for (p, v) in pep.p_true
        subst[p] = Float64(v)
    end
    for (x, v) in pep.ic
        subst[x] = Float64(v)
    end
    return subst
end

function _compute_state_jet_values(DD, truth_subst)
    values = Dict{Any, Float64}()
    subst = Dict{Any, Any}(truth_subst)
    for level in eachindex(DD.states_rhs)
        for idx in eachindex(DD.states_rhs[level])
            expr = Symbolics.substitute(DD.states_rhs[level][idx], subst)
            value = _numeric_float(expr)
            lhs = DD.states_lhs[level][idx]
            values[lhs] = value
            subst[lhs] = value
        end
    end
    return values
end

function _force_extend_derivative_data!(DD, required_order::Int)
    D = ModelingToolkit.D_nounits
    while length(DD.obs_lhs) - 1 < required_order
        push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))
        next_state_rhs = Num[]
        for expr in D.(DD.states_rhs[end])
            push!(next_state_rhs, expand_derivatives(expr))
        end
        push!(DD.states_rhs, next_state_rhs)
        push!(DD.states_lhs_cleared, expand_derivatives.(D.(DD.states_lhs_cleared[end])))
        next_state_rhs_cleared = Num[]
        for expr in D.(DD.states_rhs_cleared[end])
            push!(next_state_rhs_cleared, expand_derivatives(expr))
        end
        push!(DD.states_rhs_cleared, next_state_rhs_cleared)

        push!(DD.obs_lhs, expand_derivatives.(D.(DD.obs_lhs[end])))
        next_obs_rhs = Num[]
        for expr in D.(DD.obs_rhs[end])
            push!(next_obs_rhs, expand_derivatives(expr))
        end
        push!(DD.obs_rhs, next_obs_rhs)
        push!(DD.obs_lhs_cleared, expand_derivatives.(D.(DD.obs_lhs_cleared[end])))
        next_obs_rhs_cleared = Num[]
        for expr in D.(DD.obs_rhs_cleared[end])
            push!(next_obs_rhs_cleared, expand_derivatives(expr))
        end
        push!(DD.obs_rhs_cleared, next_obs_rhs_cleared)
    end
    return DD
end

function _oracle_template_dd(ode, measured_quantities, DD, derivative_dict)
    template_DD = ODEParameterEstimation.ensure_si_template_dd_support(
        ode,
        measured_quantities,
        DD,
        derivative_dict,
    )
    required_order = isempty(derivative_dict) ? 0 : maximum(Int(v) for v in values(derivative_dict))
    if length(template_DD.obs_lhs) - 1 < required_order
        @warn "DerivativeData was still shorter than the SI template requirement; force-extending for analytical oracle" current_order = length(template_DD.obs_lhs) - 1 required_order
        _force_extend_derivative_data!(template_DD, required_order)
    end
    return template_DD
end

function _state_and_param_name_values(DD, pep, branch_values::AbstractDict; t0::Float64 = 0.0)
    t = ModelingToolkit.get_iv(pep.model.system)
    subst = Dict{Any, Any}(t => t0)
    name_values = Dict{String, Float64}()

    for (p, truth) in pep.p_true
        base = _base_name(p)
        value = Float64(get(branch_values, base, truth))
        subst[p] = value
        name_values["$(base)_0"] = value
    end
    for (x, truth) in pep.ic
        base = _base_name(x)
        value = Float64(get(branch_values, base, truth))
        subst[x] = value
        name_values["$(base)_0"] = value
    end

    for level in eachindex(DD.states_rhs)
        for idx in eachindex(DD.states_rhs[level])
            expr = Symbolics.substitute(DD.states_rhs[level][idx], subst)
            value = _numeric_float(expr)
            lhs = DD.states_lhs[level][idx]
            subst[lhs] = value
            state_base = _base_name(ModelingToolkit.unknowns(pep.model.system)[idx])
            name_values["$(state_base)_$(level)"] = value
        end
    end
    return name_values
end

"""
    analytical_jet(DD, pep; t0=0.0)

Return exact observable derivative values keyed by the SI-template observable
variables in `DD.obs_lhs`. Values are evaluated along the ODE solution at the
truth parameters and initial conditions, without fitting or interpolation.
"""
function analytical_jet(DD, pep; t0::Float64 = 0.0)
    object_values, _name_values = analytical_jet_maps(DD, pep; t0 = t0)
    return object_values
end

function analytical_jet_maps(DD, pep; t0::Float64 = 0.0)
    truth_subst = _truth_substitution(pep; t0 = t0)
    state_jet = _compute_state_jet_values(DD, truth_subst)
    subst = Dict{Any, Any}(truth_subst)
    for (k, v) in state_jet
        subst[k] = v
    end

    out = Dict{Any, Float64}()
    name_values = Dict{String, Float64}()
    for level in eachindex(DD.obs_rhs)
        for idx in eachindex(DD.obs_rhs[level])
            expr = Symbolics.substitute(DD.obs_rhs[level][idx], subst)
            value = _numeric_float(expr)
            out[DD.obs_lhs[level][idx]] = value
            name_values["y$(idx)_$(level - 1)"] = value
        end
    end
    return out, name_values
end

function _augment_with_trfn_values!(values::Dict, name_values::Dict{String, Float64}, equations, t_point::Float64)
    vars = OrderedSet{Any}()
    for eq in equations
        union!(vars, Symbolics.get_variables(eq))
    end
    for v in vars
        var_name = string(v)
        val = ODEParameterEstimation.evaluate_trfn_template_variable(var_name, t_point)
        isnothing(val) && (val = ODEParameterEstimation.evaluate_obs_trfn_template_variable(var_name, t_point))
        if !isnothing(val)
            values[v] = Float64(val)
            name_values[string(v)] = Float64(val)
        end
    end
    return values
end

function _substitute_knowns(expr, object_values::Dict, name_values::Dict{String, Float64})
    out = Symbolics.substitute(expr, object_values)
    vars = Symbolics.get_variables(out)
    isempty(vars) && return out
    by_name = Dict{Any, Any}()
    for v in vars
        value = get(name_values, string(v), nothing)
        if !isnothing(value)
            by_name[v] = value
        end
    end
    isempty(by_name) && return out
    return Symbolics.substitute(out, by_name)
end

function _instantiate_equations(equations, known_values::Dict, known_name_values::Dict{String, Float64}; residual_tol::Float64 = 1e-8)
    substituted = [_substitute_knowns(eq, known_values, known_name_values) for eq in equations]
    kept = Any[]
    final_vars = OrderedSet{Any}()
    trivial_residuals = Float64[]

    for eq in substituted
        vars = Symbolics.get_variables(eq)
        if isempty(vars)
            push!(trivial_residuals, abs(_numeric_float(eq)))
        else
            push!(kept, eq)
            union!(final_vars, vars)
        end
    end

    # Match the production helper's defensive overdetermined pruning. This should
    # rarely matter for Wallaby M=2 systems, but keeps the oracle aligned with the
    # SI-template solve path when substitution removes data-only equations.
    while length(kept) > length(final_vars)
        var_eq_count = Dict{Any, Int}()
        for eq in kept
            for v in Symbolics.get_variables(eq)
                var_eq_count[v] = get(var_eq_count, v, 0) + 1
            end
        end
        removed = false
        for idx in length(kept):-1:1
            eq_vars = Symbolics.get_variables(kept[idx])
            if all(v -> get(var_eq_count, v, 0) >= 2, eq_vars)
                deleteat!(kept, idx)
                removed = true
                break
            end
        end
        removed || break
        final_vars = OrderedSet{Any}()
        for eq in kept
            union!(final_vars, Symbolics.get_variables(eq))
        end
    end

    max_trivial_residual = isempty(trivial_residuals) ? 0.0 : maximum(trivial_residuals)
    if max_trivial_residual > residual_tol
        @warn "Nonzero data-only residual while instantiating oracle equations" max_trivial_residual
    end
    return kept, collect(final_vars), max_trivial_residual
end

function _solve_hc_with_counts(equations, vars; real_tol::Float64 = 1e-9)
    t0 = time()
    hc_system, hc_vars = ODEParameterEstimation.convert_to_hc_format(equations, vars)
    result = ODEParameterEstimation._hc_solve(hc_system, show_progress = false)
    all_hc = HomotopyContinuation.solutions(result)
    real_hc = HomotopyContinuation.solutions(result, only_real = true, real_tol = real_tol)
    real_solutions = Vector{Vector{Float64}}()
    for sol in real_hc
        push!(real_solutions, Float64[real(sol[i]) for i in eachindex(hc_vars)])
    end
    return (
        real_solutions = real_solutions,
        n_complex_total = length(all_hc),
        seconds = time() - t0,
    )
end

function _solution_assignment(vars, sol)
    out = Dict{Any, Float64}()
    for (v, value) in zip(vars, sol)
        out[v] = Float64(value)
    end
    return out
end

function _branch_variable_names(pep)
    names = String[]
    append!(names, [_base_name(p) for p in keys(pep.p_true)])
    append!(names, [_base_name(x) for x in keys(pep.ic)])
    return names
end

function _branch_value_map(pep, assignment)
    wanted = Set(_branch_variable_names(pep))
    out = OrderedDict{String, Float64}()
    for (v, value) in assignment
        s = _strip_time_suffix(string(v))
        if endswith(s, "_0")
            base = s[1:prevind(s, lastindex(s), 2)]
            if base in wanted
                out[base] = Float64(value)
            end
        elseif s in wanted
            out[s] = Float64(value)
        end
    end
    return out
end

function _truth_value_map(pep)
    out = OrderedDict{String, Float64}()
    for (p, v) in pep.p_true
        out[_base_name(p)] = Float64(v)
    end
    for (x, v) in pep.ic
        out[_base_name(x)] = Float64(v)
    end
    return out
end

function _max_relative_error(values::AbstractDict, truth::AbstractDict)
    errs = Float64[]
    for (k, tv) in truth
        haskey(values, k) || continue
        denom = max(abs(Float64(tv)), 1e-12)
        push!(errs, abs(Float64(values[k]) - Float64(tv)) / denom)
    end
    return isempty(errs) ? Inf : maximum(errs)
end

function _is_positive(branch_values::AbstractDict; lb::Float64 = 1e-5)
    return all(v -> isfinite(v) && v > 0.0, Base.values(branch_values))
end

function _is_in_bounds(branch_values::AbstractDict; lb::Float64 = 1e-5, ub::Float64 = 10.0)
    return all(v -> isfinite(v) && lb <= v <= ub, Base.values(branch_values))
end

function _verify_against_dropped(
    dropped_equations,
    known_values::Dict,
    known_name_values::Dict{String, Float64},
    assignment::Dict,
    candidate_name_values::Dict{String, Float64};
    tol::Float64 = 1e-6,
)
    isempty(dropped_equations) && return (passed = true, max_residual = 0.0, residuals = Float64[])
    subst = Dict{Any, Any}(known_values)
    for (k, v) in assignment
        subst[k] = v
    end
    names = Dict{String, Float64}(known_name_values)
    for (k, v) in candidate_name_values
        names[k] = v
    end
    residuals = Float64[]
    for eq in dropped_equations
        residual = abs(_numeric_float(_substitute_knowns(eq, subst, names)))
        push!(residuals, residual)
    end
    max_residual = isempty(residuals) ? 0.0 : maximum(residuals)
    return (passed = max_residual <= tol, max_residual = max_residual, residuals = residuals)
end

function _all_solve_values(assignment)
    pairs_sorted = sort([(string(k), Float64(v)) for (k, v) in assignment]; by = first)
    return OrderedDict{String, Float64}(pairs_sorted)
end

function _oracle_git_sha()
    try
        return readchomp(`git rev-parse HEAD`)
    catch
        return "unknown"
    end
end

function analytical_branch_oracle(
    pep;
    system_name::AbstractString = pep.name,
    instance::Integer = -1,
    expected_algebraic::Integer = get(ORACLE_EXPECTED_M, String(system_name), (algebraic = -1, physical = -1)).algebraic,
    expected_physical::Integer = get(ORACLE_EXPECTED_M, String(system_name), (algebraic = -1, physical = -1)).physical,
    bounds::Tuple{Float64, Float64} = (1e-5, 10.0),
    t0::Float64 = 0.0,
    dropped_tol::Float64 = 1e-6,
    real_tol::Float64 = 1e-9,
    infolevel::Integer = 0,
)
    data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}("t" => [t0])
    DD0 = ODEParameterEstimation.populate_derivatives(pep.model.system, pep.measured_quantities, 2, OrderedDict())
    template_equations, derivative_dict, _unidentifiable, _identifiable_funcs, _roles, metadata =
        ODEParameterEstimation.get_si_equation_system(
            pep.model,
            pep.measured_quantities,
            data_sample;
            DD = DD0,
            infolevel = infolevel,
        )
    template_DD = _oracle_template_dd(pep.model, pep.measured_quantities, DD0, derivative_dict)

    known_values, known_name_values = analytical_jet_maps(template_DD, pep; t0 = t0)
    known_values = Dict{Any, Float64}(known_values)
    known_name_values = Dict{String, Float64}(known_name_values)
    _augment_with_trfn_values!(known_values, known_name_values, template_equations, t0)

    selected_eqs, solve_vars, max_trivial_residual = _instantiate_equations(
        template_equations,
        known_values,
        known_name_values,
    )
    if isempty(selected_eqs) || isempty(solve_vars)
        return _empty_oracle_payload(
            pep,
            system_name,
            instance,
            expected_algebraic,
            expected_physical;
            note = "No nontrivial equations or solve variables after exact jet substitution.",
        )
    end

    solve_result = _solve_hc_with_counts(selected_eqs, solve_vars; real_tol = real_tol)
    full_equations = hasproperty(metadata, :full_equations) ? metadata.full_equations : template_equations
    dropped_indices = hasproperty(metadata, :dropped_equation_indices) ? metadata.dropped_equation_indices : Int[]
    dropped_equations = [full_equations[i] for i in dropped_indices if 1 <= i <= length(full_equations)]

    truth_values = _truth_value_map(pep)
    lb, ub = bounds
    algebraic_branches = Vector{Any}()
    out_of_bounds_branches = Vector{Any}()
    n_real_positive = 0
    n_in_bounds = 0
    n_passed = 0

    for (idx0, sol) in enumerate(solve_result.real_solutions)
        assignment = _solution_assignment(solve_vars, sol)
        branch_values = _branch_value_map(pep, assignment)
        candidate_name_values = _state_and_param_name_values(template_DD, pep, branch_values; t0 = t0)
        is_positive = _is_positive(branch_values; lb = lb)
        is_in_bounds = _is_in_bounds(branch_values; lb = lb, ub = ub)
        verification = _verify_against_dropped(
            dropped_equations,
            known_values,
            known_name_values,
            assignment,
            candidate_name_values;
            tol = dropped_tol,
        )
        truth_err = _max_relative_error(branch_values, truth_values)

        is_positive && (n_real_positive += 1)
        is_in_bounds && (n_in_bounds += 1)
        verification.passed && (n_passed += 1)

        branch_payload = OrderedDict{String, Any}(
            "branch_index" => idx0 - 1,
            "is_truth" => truth_err <= 1e-8,
            "truth_max_relative_error" => truth_err,
            "in_bounds" => is_in_bounds,
            "positive" => is_positive,
            "verified_against_dropped" => verification.passed,
            "max_dropped_residual" => verification.max_residual,
            "values" => branch_values,
            "solve_values" => _all_solve_values(assignment),
        )
        if is_positive && is_in_bounds && verification.passed
            push!(algebraic_branches, branch_payload)
        else
            push!(out_of_bounds_branches, branch_payload)
        end
    end

    return OrderedDict{String, Any}(
        "_meta" => OrderedDict{String, Any}(
            "schema_version" => 1,
            "generated_by" => "analytical_branch_oracle.jl",
            "odepe_sha" => _oracle_git_sha(),
            "generated_at" => string(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS"), "Z"),
            "notes" => "Oracle for branch-aware analysis. Inputs: ODE + truth. NO benchmark-method calls. NO data of any kind. Truth-aware diagnostic for the synthetic benchmark.",
        ),
        "system" => String(system_name),
        "instance" => Int(instance),
        "M_expected_algebraic" => Int(expected_algebraic),
        "M_expected_physical" => Int(expected_physical),
        "M_observed" => length(algebraic_branches),
        "truth" => OrderedDict{String, Any}(
            "parameters" => OrderedDict{String, Float64}(_base_name(k) => Float64(v) for (k, v) in pep.p_true),
            "states" => OrderedDict{String, Float64}(_base_name(k) => Float64(v) for (k, v) in pep.ic),
        ),
        "algebraic_branches" => algebraic_branches,
        "out_of_bounds_branches" => out_of_bounds_branches,
        "diagnostics" => OrderedDict{String, Any}(
            "n_hc_complex_roots_total" => solve_result.n_complex_total,
            "n_real_positive_roots" => n_real_positive,
            "n_in_bounds" => n_in_bounds,
            "n_passed_dropped_verification" => n_passed,
            "hc_solve_seconds" => solve_result.seconds,
            "n_selected_equations" => length(selected_eqs),
            "n_solve_variables" => length(solve_vars),
            "selected_equation_indices" => hasproperty(metadata, :selected_equation_indices) ? metadata.selected_equation_indices : Int[],
            "dropped_equation_indices" => dropped_indices,
            "max_trivial_residual_after_jet_substitution" => max_trivial_residual,
        ),
    )
end

function _empty_oracle_payload(pep, system_name, instance, expected_algebraic, expected_physical; note)
    return OrderedDict{String, Any}(
        "_meta" => OrderedDict{String, Any}(
            "schema_version" => 1,
            "generated_by" => "analytical_branch_oracle.jl",
            "odepe_sha" => _oracle_git_sha(),
            "generated_at" => string(Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS"), "Z"),
            "notes" => note,
        ),
        "system" => String(system_name),
        "instance" => Int(instance),
        "M_expected_algebraic" => Int(expected_algebraic),
        "M_expected_physical" => Int(expected_physical),
        "M_observed" => 0,
        "truth" => OrderedDict{String, Any}(
            "parameters" => OrderedDict{String, Float64}(_base_name(k) => Float64(v) for (k, v) in pep.p_true),
            "states" => OrderedDict{String, Float64}(_base_name(k) => Float64(v) for (k, v) in pep.ic),
        ),
        "algebraic_branches" => Any[],
        "out_of_bounds_branches" => Any[],
        "diagnostics" => OrderedDict{String, Any}("error_note" => note),
    )
end

function write_oracle_json(path::AbstractString, payload)
    mkpath(dirname(path))
    open(path, "w") do io
        _write_json(io, payload, 0)
        write(io, '\n')
    end
    return path
end

function run_wallaby_branch_oracle(
    system::AbstractString,
    instance::Integer;
    wallaby_root::AbstractString = "/home/orebas/rsync-readonly-PEB/benchmark_wallaby_2026-05-17",
    output_dir::AbstractString = joinpath(pwd(), "artifacts", "algebraic_branch_oracle"),
    kwargs...,
)
    script_path = joinpath(wallaby_root, "filetree", "data_generation", "$(system)_$(instance).jl")
    isfile(script_path) || error("Missing Wallaby generated-data script: $script_path")
    pep = load_wallaby_generated_problem(script_path)
    expected = get(ORACLE_EXPECTED_M, String(system), (algebraic = -1, physical = -1))
    payload = analytical_branch_oracle(
        pep;
        system_name = system,
        instance = instance,
        expected_algebraic = expected.algebraic,
        expected_physical = expected.physical,
        kwargs...,
    )
    output_path = joinpath(output_dir, "$(system)_$(instance).json")
    write_oracle_json(output_path, payload)
    return payload, output_path
end

function run_wallaby_branch_oracles(;
    systems = ORACLE_WALLABY_M2_SYSTEMS,
    instances = 0:9,
    wallaby_root::AbstractString = "/home/orebas/rsync-readonly-PEB/benchmark_wallaby_2026-05-17",
    output_dir::AbstractString = joinpath(pwd(), "artifacts", "algebraic_branch_oracle"),
    kwargs...,
)
    outputs = OrderedDict{String, String}()
    for system in systems
        for instance in instances
            @info "[BRANCH-ORACLE] Running" system instance
            _payload, output_path = run_wallaby_branch_oracle(
                String(system),
                Int(instance);
                wallaby_root = wallaby_root,
                output_dir = output_dir,
                kwargs...,
            )
            outputs["$(system)_$(instance)"] = output_path
            @info "[BRANCH-ORACLE] Wrote" output_path
        end
    end
    return outputs
end

function _write_json(io, x, indent::Int)
    if x === nothing
        write(io, "null")
    elseif x isa Bool
        write(io, x ? "true" : "false")
    elseif x isa Integer
        write(io, string(x))
    elseif x isa AbstractFloat
        if isfinite(x)
            write(io, repr(Float64(x)))
        else
            write(io, "null")
        end
    elseif x isa AbstractString
        write(io, '"', _json_escape(x), '"')
    elseif x isa Symbol
        write(io, '"', _json_escape(String(x)), '"')
    elseif x isa AbstractDict
        write(io, "{")
        first_item = true
        for (k, v) in x
            first_item || write(io, ",")
            write(io, "\n", " "^(indent + 2))
            _write_json(io, string(k), indent + 2)
            write(io, ": ")
            _write_json(io, v, indent + 2)
            first_item = false
        end
        if !first_item
            write(io, "\n", " "^indent)
        end
        write(io, "}")
    elseif x isa AbstractVector || x isa Tuple
        write(io, "[")
        for (i, item) in enumerate(x)
            i == 1 || write(io, ",")
            write(io, "\n", " "^(indent + 2))
            _write_json(io, item, indent + 2)
        end
        if !isempty(x)
            write(io, "\n", " "^indent)
        end
        write(io, "]")
    else
        _write_json(io, string(x), indent)
    end
end

function _json_escape(s::AbstractString)
    out = IOBuffer()
    for c in s
        if c == '"'
            write(out, "\\\"")
        elseif c == '\\'
            write(out, "\\\\")
        elseif c == '\n'
            write(out, "\\n")
        elseif c == '\r'
            write(out, "\\r")
        elseif c == '\t'
            write(out, "\\t")
        else
            write(out, c)
        end
    end
    return String(take!(out))
end
