using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using Symbolics: Num
using CSV
using DelimitedFiles
using Statistics
using Printf
using Dates

const ODEPE = ODEParameterEstimation
const BENCHMARK_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09"
const OUTPUT_ROOT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "cstr_crauste_deep_dive")
const ANALYSIS_ROOT = joinpath(BENCHMARK_ROOT, "analysis_results")
const FILETREE_ROOT = joinpath(BENCHMARK_ROOT, "filetree")
const DEFAULT_CASES = [
    "cstr_1_0",
    "cstr_1_1em8",
    "crauste_3_1em8",
]
const ENABLE_LOCAL_UQ = get(ENV, "ODEPE_DEEP_DIVE_ENABLE_UQ", "0") == "1"
const RENDER_ONLY = get(ENV, "ODEPE_DEEP_DIVE_RENDER_ONLY", "0") == "1"
const NOISE_TAGS = [
    "0e+00",
    "1e-08",
    "1e-06",
    "1e-04",
    "1e-02",
]
const METHODS = [
    "amigo2_run",
    "odepe_nopolish",
    "odepe_polish",
    "odepe_multipoint",
]
const ODEPE_POOL_METHODS = [
    "odepe_nopolish",
    "odepe_polish",
    "odepe_multipoint",
]

struct CaseSpec
    case_id::String
    system::String
    run_idx::Int
    noise_tag::String
end

function _default_cases()
    requested = split(get(ENV, "ODEPE_DEEP_DIVE_CASE_IDS", join(DEFAULT_CASES, ",")), ",")
    case_ids = filter(!isempty, strip.(requested))
    specs = CaseSpec[]
    for case_id in case_ids
        parts = split(case_id, "_")
        if length(parts) < 3
            error("Invalid case id '$case_id' — expected <system>_<run>_<noise>")
        end
        system = join(parts[1:(end - 2)], "_")
        run_idx = parse(Int, parts[end - 1])
        noise_suffix = parts[end]
        noise_tag = if noise_suffix == "0"
            "0e+00"
        elseif noise_suffix == "1em8"
            "1e-08"
        elseif noise_suffix == "1em6"
            "1e-06"
        elseif noise_suffix == "1em4"
            "1e-04"
        elseif noise_suffix == "1em2"
            "1e-02"
        else
            error("Unsupported noise suffix '$noise_suffix' in case '$case_id'")
        end
        push!(specs, CaseSpec(case_id, system, run_idx, noise_tag))
    end
    return specs
end

function _benchmark_case_dir(run_family::String, case_id::String)
    return joinpath(FILETREE_ROOT, run_family, case_id)
end

function _find_case_file(case_id::String, file_name::String)
    for family in ("odepe_polish", "odepe_nopolish", "amigo2_run")
        candidate = joinpath(_benchmark_case_dir(family, case_id), file_name)
        isfile(candidate) && return candidate
    end
    error("Could not locate '$file_name' for case '$case_id'")
end

function _read_script_text(case_id::String)
    return read(_find_case_file(case_id, "script.jl"), String)
end

function _parse_numeric_vector(script_text::AbstractString, variable_name::AbstractString)
    pattern = Regex("(?ms)^\\s*" * variable_name * "\\s*=\\s*\\[(.*?)\\]")
    match_obj = match(pattern, script_text)
    isnothing(match_obj) && error("Could not find '$variable_name' in generated script")
    content = replace(match_obj.captures[1], '\n' => ' ')
    tokens = filter(!isempty, strip.(split(content, ",")))
    return Float64[parse(Float64, tok) for tok in tokens]
end

function _load_data_sample(case_id::String, measured_quantities)
    data_path = _find_case_file(case_id, "data.csv")
    matrix = Array{Float64}(readdlm(data_path, ',', Float64))
    ndims(matrix) == 1 && (matrix = reshape(matrix, 1, :))

    data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
    data_sample["t"] = vec(matrix[:, 1])
    for (i, eq) in enumerate(measured_quantities)
        data_sample[Num(eq.rhs)] = vec(matrix[:, i + 1])
    end
    return data_sample
end

function build_benchmark_case(case_id::String)
    script_text = _read_script_text(case_id)
    p_true = _parse_numeric_vector(script_text, "p_true")
    ic = _parse_numeric_vector(script_text, "ic")
    time_interval = _parse_numeric_vector(script_text, "time_interval")

    if startswith(case_id, "cstr_")
        parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
        states = @variables C(t) Temp(t) r_eff(t)
        observables = @variables y1(t)
        equations = [
            D(C) ~ (1.0 - C) / (2.0 * tau) - 1.999863916554819 * r_eff * C,
            D(Temp) ~ (Tin - Temp) / (2.0 * tau) +
                      0.0285694845222117 * dH_rhoCP * r_eff * C -
                      2.0 * UA_VrhoCP * Temp +
                      0.8571428571428571 * UA_VrhoCP +
                      0.05714285714285714 * UA_VrhoCP * sin(0.5 * t),
            D(r_eff) ~ 12.5 * r_eff / (Temp^2) *
                       ((Tin - Temp) / (2.0 * tau) +
                        0.0285694845222117 * dH_rhoCP * r_eff * C -
                        2.0 * UA_VrhoCP * Temp +
                        0.8571428571428571 * UA_VrhoCP +
                        0.05714285714285714 * UA_VrhoCP * sin(0.5 * t)),
        ]
        measured_quantities = [y1 ~ 700.0 * Temp]
        model, mq = create_ordered_ode_system("cstr", states, parameters, equations, measured_quantities)
        data_sample = _load_data_sample(case_id, mq)
        return ParameterEstimationProblem(
            case_id,
            model,
            mq,
            data_sample,
            time_interval,
            nothing,
            OrderedDict(parameters .=> p_true),
            OrderedDict(states .=> ic),
            0,
        )
    elseif startswith(case_id, "crauste_")
        parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
        states = @variables Npop(t) E(t) L(t) M(t) P(t)
        observables = @variables y1(t) y2(t) y3(t) y4(t)
        equations = [
            D(Npop) ~ (-24270.0 * mu_N * Npop - 582.4799999999999 * delta_NE * P * Npop) / 16180.0,
            D(E) ~ (582.4799999999999 * delta_NE * P * Npop +
                     10.0 * (-1.18 * delta_EL - 0.000432 * mu_EE * E + 2.56 * rho_E * P) * E) / 10.0,
            D(L) ~ (11.799999999999999 * delta_EL * E -
                     10.0 * (0.05 * delta_LM + 7.2e-7 * mu_LE * E + 0.00015000000000000001 * mu_LL * L) * L) / 10.0,
            D(M) ~ 0.05 * delta_LM * L,
            D(P) ~ (-0.11 * mu_P - 3.6e-6 * mu_PE * E - 0.00036 * mu_PL * L + 0.6 * rho_P * P) * P,
        ]
        measured_quantities = [y1 ~ 16180.0 * Npop, y2 ~ 10.0 * E, y3 ~ 10.0 * M + 10.0 * L, y4 ~ 2.0 * P]
        model, mq = create_ordered_ode_system("crauste", states, parameters, equations, measured_quantities)
        data_sample = _load_data_sample(case_id, mq)
        return ParameterEstimationProblem(
            case_id,
            model,
            mq,
            data_sample,
            time_interval,
            nothing,
            OrderedDict(parameters .=> p_true),
            OrderedDict(states .=> ic),
            0,
        )
    else
        error("Unsupported benchmark case '$case_id'")
    end
end

function _comparison_path(system::String, method::String, noise_tag::String)
    return joinpath(ANALYSIS_ROOT, "parameter_comparison_$(system)_$(method)_noise_$(noise_tag).csv")
end

function _load_selected_metrics(spec::CaseSpec, method::String)
    path = _comparison_path(spec.system, method, spec.noise_tag)
    isfile(path) || return nothing
    for row in CSV.File(path)
        Int(row.Run) == spec.run_idx || continue
        return (
            median_rel_err = Float64(row.MedianRelErr),
            mean_rel_err = Float64(row.MeanRelErr),
            max_rel_err = Float64(row.MaxRelErr),
            rmse = Float64(row.RMSE),
            success = Bool(row.Success),
        )
    end
    return nothing
end

function _noise_summary(system::String, method::String, noise_tag::String)
    path = _comparison_path(system, method, noise_tag)
    isfile(path) || return nothing
    rows = collect(CSV.File(path))
    isempty(rows) && return nothing
    rmses = Float64[r.RMSE for r in rows]
    max_errs = Float64[r.MaxRelErr for r in rows]
    successes = Bool[r.Success for r in rows]
    return (
        mean_rmse = mean(rmses),
        median_rmse = median(rmses),
        mean_max_rel = mean(max_errs),
        success_count = count(identity, successes),
        total = length(rows),
    )
end

function _read_result_matrix(path::String)
    open(path, "r") do io
        headers = split(strip(readline(io)), ",")
        data = Array{Float64}(readdlm(io, ',', Float64))
        ndims(data) == 1 && (data = reshape(data, 1, :))
        return headers, data
    end
end

function _truth_lookup(pep::ParameterEstimationProblem)
    truth = Dict{String, Float64}()
    for (p, v) in pep.p_true
        truth[string(p)] = v
    end
    for (s, v) in pep.ic
        truth[string(s)] = v
    end
    return truth
end

function _row_truth_metrics(headers::AbstractVector{<:AbstractString}, row::AbstractVector{<:Real}, truth_lookup::Dict{String, Float64})
    rel_errors = Float64[]
    for (header, value) in zip(headers, row)
        haskey(truth_lookup, header) || continue
        true_val = truth_lookup[header]
        denom = max(abs(true_val), 1e-12)
        push!(rel_errors, abs(Float64(value) - true_val) / denom)
    end
    isempty(rel_errors) && return (rmse = NaN, max_rel = NaN, mean_rel = NaN)
    return (
        rmse = sqrt(mean(abs2, rel_errors)),
        max_rel = maximum(rel_errors),
        mean_rel = mean(rel_errors),
    )
end

function _pool_summary(spec::CaseSpec, method::String, pep::ParameterEstimationProblem)
    path = joinpath(_benchmark_case_dir(method, spec.case_id), "result.csv")
    isfile(path) || return nothing
    headers, data = _read_result_matrix(path)
    truth = _truth_lookup(pep)
    if size(data, 1) == 0
        return (
            rows = 0,
            nonfinite_rows = 0,
            box_violation_rows = 0,
            top_row_truth_rmse = NaN,
            best_truth_rmse = NaN,
            best_truth_max_rel = NaN,
            best_truth_row = 0,
            better_than_top_count = 0,
        )
    end

    metrics = [_row_truth_metrics(headers, view(data, i, :), truth) for i in 1:size(data, 1)]
    rmses = [m.rmse for m in metrics]
    best_idx = argmin(rmses)
    top_rmse = first(rmses)
    nonfinite_rows = count(i -> any(!isfinite, view(data, i, :)), 1:size(data, 1))
    box_violation_rows = count(i -> any(x -> isfinite(x) && (x < 1e-5 || x > 10.0), view(data, i, :)), 1:size(data, 1))
    better_than_top = count(r -> isfinite(r) && r + 1e-12 < top_rmse, rmses)
    return (
        rows = size(data, 1),
        nonfinite_rows = nonfinite_rows,
        box_violation_rows = box_violation_rows,
        top_row_truth_rmse = top_rmse,
        best_truth_rmse = rmses[best_idx],
        best_truth_max_rel = metrics[best_idx].max_rel,
        best_truth_row = best_idx,
        better_than_top_count = better_than_top,
    )
end

function _run_local_diagnosis(pep::ParameterEstimationProblem)
    diagnostic_mode = :direct
    direct_failure = ""
    pep_for_diag = pep
    report = nothing
    setup = nothing
    t_eval = NaN
    interpolator_name = "aaad_gpr"

    function run_single_point_diagnose(pep_local)
        local_setup = ODEPE.setup_parameter_estimation(pep_local; interpolator = aaad_gpr_pivot, nooutput = true)
        t_vector = pep_local.data_sample["t"]
        time_indices = local_setup.time_index_set isa AbstractVector ? collect(local_setup.time_index_set) : [local_setup.time_index_set]
        t_idx = time_indices[cld(length(time_indices), 2)]
        local_t_eval = t_vector[t_idx]
        max_order = isempty(local_setup.good_deriv_level) ? 2 : maximum(values(local_setup.good_deriv_level))
        deriv = ODEPE.diagnose_derivative_accuracy(
            pep_local;
            setup_data = local_setup,
            t_eval = local_t_eval,
            max_order = max_order,
            interpolator_name = interpolator_name,
        )
        poly = ODEPE.diagnose_polynomial_system(
            pep_local;
            setup_data = local_setup,
            t_eval = local_t_eval,
            max_order = max_order,
        )
        sens = ODEPE.diagnose_sensitivity(
            pep_local;
            setup_data = local_setup,
            poly_report = poly,
            t_eval = local_t_eval,
            max_order = max_order,
        )
        difficulty, bottleneck = ODEPE._classify_difficulty(deriv, poly, sens)
        eb = try
            ODEPE.compute_error_budget(sens, deriv, poly)
        catch
            nothing
        end
        return (
            report = ODEPE.DiagnosticReport(pep_local.name, deriv, poly, sens, difficulty, bottleneck, Dates.now(), eb),
            setup = local_setup,
            t_eval = local_t_eval,
        )
    end

    function run_derivative_only_diagnose(pep_local)
        local_setup = ODEPE.setup_parameter_estimation(pep_local; interpolator = aaad_gpr_pivot, nooutput = true)
        t_vector = pep_local.data_sample["t"]
        time_indices = local_setup.time_index_set isa AbstractVector ? collect(local_setup.time_index_set) : [local_setup.time_index_set]
        t_idx = time_indices[cld(length(time_indices), 2)]
        local_t_eval = t_vector[t_idx]
        max_order = isempty(local_setup.good_deriv_level) ? 2 : maximum(values(local_setup.good_deriv_level))
        deriv = ODEPE.diagnose_derivative_accuracy(
            pep_local;
            setup_data = local_setup,
            t_eval = local_t_eval,
            max_order = max_order,
            interpolator_name = interpolator_name,
        )
        return (setup = local_setup, t_eval = local_t_eval, deriv = deriv)
    end

    if startswith(pep.name, "cstr_")
        deriv_report = nothing
        try
            run = run_derivative_only_diagnose(pep)
            setup = run.setup
            t_eval = run.t_eval
            deriv_report = run.deriv
        catch err
            diagnostic_mode = :transformed
            direct_failure = sprint(showerror, err)
            t_var = ModelingToolkit.get_iv(pep.model.system)
            pep_for_diag, _ = ODEPE.transform_pep_for_estimation(pep, t_var)
            run = run_derivative_only_diagnose(pep_for_diag)
            setup = run.setup
            t_eval = run.t_eval
            deriv_report = run.deriv
        end

        return (
            diagnostic_mode = diagnostic_mode,
            direct_failure = direct_failure,
            difficulty = :hard,
            bottleneck = "cstr_derivative_only_after_direct_trig_failure",
            best_interpolator = interpolator_name,
            best_eval_point = t_eval,
            worst_deriv_error = deriv_report.worst_rel_error,
            max_required_order = deriv_report.max_required_order,
            prod_solution_count = -1,
            prod_closest_distance = NaN,
            jacobian_cond = NaN,
            effective_rank = -1,
            root_sensitivity = NaN,
            sensitivity_nonlinearity = NaN,
            sensitivity_concentration = NaN,
            is_pathological = false,
            uq_status = :skipped,
            uq_max_cv = NaN,
        )
    end

    try
        run = run_single_point_diagnose(pep)
        report = run.report
        setup = run.setup
        t_eval = run.t_eval
    catch err
        diagnostic_mode = :transformed
        direct_failure = sprint(showerror, err)
        t_var = ModelingToolkit.get_iv(pep.model.system)
        pep_for_diag, _ = ODEPE.transform_pep_for_estimation(pep, t_var)
        run = run_single_point_diagnose(pep_for_diag)
        report = run.report
        setup = run.setup
        t_eval = run.t_eval
    end

    best = report
    uq_result = if ENABLE_LOCAL_UQ
        try
            ODEPE.diagnose_uncertainty(pep_for_diag, setup, t_eval, best.sensitivity)
        catch e
            @warn "UQ diagnosis failed for $(pep.name): $e"
            nothing
        end
    else
        nothing
    end
    uq_report = if isnothing(uq_result)
        nothing
    elseif uq_result isa Tuple
        first(uq_result)
    else
        uq_result
    end
    return (
        diagnostic_mode = diagnostic_mode,
        direct_failure = direct_failure,
        difficulty = best.difficulty,
        bottleneck = best.bottleneck,
        best_interpolator = interpolator_name,
        best_eval_point = t_eval,
        worst_deriv_error = best.derivative_accuracy.worst_rel_error,
        max_required_order = best.derivative_accuracy.max_required_order,
        prod_solution_count = best.polynomial_feasibility.n_solutions_production,
        prod_closest_distance = best.polynomial_feasibility.closest_distance_production,
        jacobian_cond = best.sensitivity.jacobian_cond,
        effective_rank = best.sensitivity.effective_rank,
        root_sensitivity = best.sensitivity.root_sensitivity,
        sensitivity_nonlinearity = isnothing(best.error_budget) ? NaN : best.error_budget.sensitivity_nonlinearity,
        sensitivity_concentration = isnothing(best.error_budget) ? NaN : best.error_budget.sensitivity_concentration,
        is_pathological = isnothing(best.error_budget) ? false : best.error_budget.is_pathological,
        uq_status = isnothing(uq_report) ? :missing : uq_report.status,
        uq_max_cv = isnothing(uq_report) ? NaN : uq_report.max_cv,
    )
end

function _repo_model_mismatch_notes()
    return [
        "Repo default `crauste()` is the old wrong model; benchmark `crauste` matches the corrected 25-day, 12-parameter formulation.",
        "Repo default `cstr()` is not the bilby benchmark model; the benchmark uses the scaled fixed-activation 3-state formulation with a single observable.",
        "This deep dive treats the bilby generated scripts and data files as the source of truth.",
    ]
end

function _case_interpretation(spec::CaseSpec, selected::AbstractDict, pools::AbstractDict, diag::NamedTuple)
    bullets = String[]
    polish = get(selected, "odepe_polish", nothing)
    nopol = get(selected, "odepe_nopolish", nothing)
    multi = get(selected, "odepe_multipoint", nothing)
    polish_pool = get(pools, "odepe_polish", nothing)
    nopol_pool = get(pools, "odepe_nopolish", nothing)

    if spec.system == "cstr"
        if diag.diagnostic_mode == :transformed
            push!(bullets, "Direct SI-based diagnosis fails on the raw benchmark model because of the explicit sinusoidal forcing term; the local diagnostic metrics below come from the transformed polynomialized system.")
        end
        if !isnothing(polish) && !isnothing(nopol) && polish.rmse >= 0.9 * nopol.rmse
            push!(bullets, "Polish does not materially rescue the exported ODEPE solution on this case.")
        end
        if !isnothing(polish_pool) && isfinite(polish_pool.best_truth_rmse) && !isnothing(polish) &&
           polish_pool.best_truth_rmse >= 0.8 * polish.rmse
            push!(bullets, "The exported `odepe_polish` pool does not hide a much better truth-close basin; this is not primarily a finalist-ranking miss.")
        end
        if !isnothing(polish_pool) && polish_pool.box_violation_rows > 0
            push!(bullets, "The saved polished pool contains rows outside the nominal `[1e-5, 10]` box, so bound enforcement needs to be audited separately from search quality.")
        end
        if diag.is_pathological || diag.sensitivity_concentration > 0.5
            push!(bullets, "Local single-interpolator diagnostics show concentrated/pathological sensitivity, consistent with weak latent-state observability under one-observable data.")
        end
        if !isnothing(multi) && !isnothing(polish) && multi.rmse + 1e-12 < polish.rmse
            push!(bullets, "Saved `odepe_multipoint` beats saved `odepe_polish` on this case, which points toward algebraic-information loss rather than mere breadth loss.")
        end
    elseif spec.system == "crauste"
        if diag.diagnostic_mode == :transformed
            push!(bullets, "Diagnostics required a transformed system, which is itself a warning sign for benchmark-faithful SI analysis.")
        end
        if !isnothing(polish) && !isnothing(nopol) && polish.rmse + 1e-12 < nopol.rmse
            push!(bullets, "Polishing materially improves the selected ODEPE solution on this case.")
        end
        if !isnothing(polish_pool) && !isnothing(polish) && polish_pool.best_truth_rmse + 1e-12 < polish.rmse
            push!(bullets, "The saved `odepe_polish` pool contains a better truth-close basin than the exported selected result, so ranking/selection is at least part of the problem.")
        elseif !isnothing(polish_pool) && !isnothing(polish)
            push!(bullets, "The exported selected result is close to the best truth-close basin visible in the saved pool, so additional basin discovery may still be required.")
        end
        if !isnothing(polish_pool) && !isnothing(nopol_pool) && polish_pool.best_truth_rmse + 1e-12 < nopol_pool.best_truth_rmse
            push!(bullets, "Polish expands basin quality substantially relative to the raw exported pool.")
        end
        if diag.is_pathological
            push!(bullets, "The local sensitivity audit is still pathological, but not in the same one-observable way as `cstr`; this looks more like a noisy search/basin problem than a spec problem.")
        end
    end

    isempty(bullets) && push!(bullets, "No strong automatic diagnosis trigger fired; inspect the tables directly before changing the benchmark spec.")
    return bullets
end

function _format_float(x)
    if isnothing(x)
        return "N/A"
    elseif x isa Symbol
        return String(x)
    elseif x isa Bool
        return string(x)
    elseif !(x isa Real)
        return string(x)
    elseif !isfinite(x)
        return string(x)
    elseif abs(x) >= 1000 || abs(x) < 1e-3
        return @sprintf("%.4e", x)
    else
        return @sprintf("%.4f", x)
    end
end

function _write_tsv(path::String, headers::Vector{String}, rows::Vector{Vector})
    open(path, "w") do io
        println(io, join(headers, '\t'))
        for row in rows
            println(io, join((_format_float(x) for x in row), '\t'))
        end
    end
end

function _noise_summary_rows(system::String)
    rows = Vector{Vector}()
    for noise_tag in NOISE_TAGS
        for method in METHODS
            summary = _noise_summary(system, method, noise_tag)
            isnothing(summary) && continue
            push!(rows, Any[
                system,
                noise_tag,
                method,
                summary.mean_rmse,
                summary.median_rmse,
                summary.mean_max_rel,
                summary.success_count,
                summary.total,
            ])
        end
    end
    return rows
end

function _case_method_rows(specs::Vector{CaseSpec}, peps::Dict{String, ParameterEstimationProblem})
    rows = Vector{Vector}()
    for spec in specs
        pep = peps[spec.case_id]
        for method in METHODS
            selected = _load_selected_metrics(spec, method)
            pool = method in ODEPE_POOL_METHODS ? _pool_summary(spec, method, pep) : nothing
            push!(rows, Any[
                spec.case_id,
                spec.system,
                spec.noise_tag,
                method,
                isnothing(selected) ? NaN : selected.rmse,
                isnothing(selected) ? NaN : selected.max_rel_err,
                isnothing(selected) ? false : selected.success,
                isnothing(pool) ? 0 : pool.rows,
                isnothing(pool) ? 0 : pool.nonfinite_rows,
                isnothing(pool) ? 0 : pool.box_violation_rows,
                isnothing(pool) ? NaN : pool.top_row_truth_rmse,
                isnothing(pool) ? NaN : pool.best_truth_rmse,
                isnothing(pool) ? 0 : pool.best_truth_row,
                isnothing(pool) ? 0 : pool.better_than_top_count,
            ])
        end
    end
    return rows
end

function _local_diagnostic_rows(specs::Vector{CaseSpec}, diagnostics::Dict{String, NamedTuple})
    rows = Vector{Vector}()
    for spec in specs
        diag = diagnostics[spec.case_id]
        push!(rows, Any[
            spec.case_id,
            spec.system,
            diag.diagnostic_mode,
            diag.difficulty,
            diag.bottleneck,
            diag.best_interpolator,
            diag.best_eval_point,
            diag.worst_deriv_error,
            diag.max_required_order,
            diag.prod_solution_count,
            diag.prod_closest_distance,
            diag.jacobian_cond,
            diag.effective_rank,
            diag.root_sensitivity,
            diag.sensitivity_nonlinearity,
            diag.sensitivity_concentration,
            diag.is_pathological,
            diag.uq_status,
            diag.uq_max_cv,
        ])
    end
    return rows
end

function _read_local_diagnostics_tsv(path::String)
    isfile(path) || error("Missing local diagnostics TSV at $path")
    diagnostics = Dict{String, NamedTuple}()
    for row in CSV.File(path; delim = '\t')
        case_id = String(row.case_id)
        diagnostics[case_id] = (
            diagnostic_mode = Symbol(row.diagnostic_mode),
            direct_failure = "",
            difficulty = Symbol(row.difficulty),
            bottleneck = String(row.bottleneck),
            best_interpolator = String(row.best_interpolator),
            best_eval_point = Float64(row.best_eval_point),
            worst_deriv_error = Float64(row.worst_deriv_error),
            max_required_order = Int(round(Float64(row.max_required_order))),
            prod_solution_count = Int(round(Float64(row.prod_solution_count))),
            prod_closest_distance = Float64(row.prod_closest_distance),
            jacobian_cond = Float64(row.jacobian_cond),
            effective_rank = Int(round(Float64(row.effective_rank))),
            root_sensitivity = Float64(row.root_sensitivity),
            sensitivity_nonlinearity = Float64(row.sensitivity_nonlinearity),
            sensitivity_concentration = Float64(row.sensitivity_concentration),
            is_pathological = Bool(row.is_pathological),
            uq_status = Symbol(row.uq_status),
            uq_max_cv = Float64(row.uq_max_cv),
        )
    end
    return diagnostics
end

function _render_markdown(path::String, specs::Vector{CaseSpec}, peps::Dict{String, ParameterEstimationProblem},
    diagnostics::Dict{String, NamedTuple})

    open(path, "w") do io
        generated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")
        println(io, "# CSTR and Crauste Benchmark Deep Dive\n")
        println(io, "_Generated: $(generated_at)_\n")

        println(io, "## Benchmark Model Provenance\n")
        for note in _repo_model_mismatch_notes()
            println(io, "- $note")
        end
        println(io)

        for system in ("cstr", "crauste")
            println(io, "## $(uppercasefirst(system))\n")
            println(io, "### Aggregate Benchmark Snapshot\n")
            println(io, "| Noise | Method | Mean RMSE | Median RMSE | Mean Max Rel Err | Success |")
            println(io, "| --- | --- | ---: | ---: | ---: | ---: |")
            for row in _noise_summary_rows(system)
                _, noise_tag, method, mean_rmse, median_rmse, mean_max_rel, success_count, total = row
                println(io, "| $noise_tag | $method | $(_format_float(mean_rmse)) | $(_format_float(median_rmse)) | $(_format_float(mean_max_rel)) | $success_count/$total |")
            end
            println(io)

            for spec in filter(s -> s.system == system, specs)
                pep = peps[spec.case_id]
                diag = diagnostics[spec.case_id]
                selected = Dict(method => _load_selected_metrics(spec, method) for method in METHODS)
                pools = Dict(method => _pool_summary(spec, method, pep) for method in ODEPE_POOL_METHODS)

                println(io, "### Case `$(spec.case_id)`\n")
                println(io, "- Noise: `$(spec.noise_tag)`")
                println(io, "- Observables: `$(length(pep.measured_quantities))`")
                println(io, "- States: `$(length(pep.model.original_states))`")
                println(io, "- Parameters: `$(length(pep.model.original_parameters))`\n")

                println(io, "#### Selected Winner Metrics\n")
                println(io, "| Method | RMSE | Max Rel Err | Success |")
                println(io, "| --- | ---: | ---: | ---: |")
                for method in METHODS
                    metric = selected[method]
                    if isnothing(metric)
                        println(io, "| $method | N/A | N/A | N/A |")
                    else
                        println(io, "| $method | $(_format_float(metric.rmse)) | $(_format_float(metric.max_rel_err)) | $(metric.success) |")
                    end
                end
                println(io)

                println(io, "#### Exported ODEPE Pool Audit\n")
                println(io, "| Method | Rows | Nonfinite Rows | Box-Violating Rows | First-Row Truth RMSE | Best Truth RMSE | Best Truth Row | Better-Than-First Rows |")
                println(io, "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
                for method in ODEPE_POOL_METHODS
                    pool = pools[method]
                    if isnothing(pool)
                        println(io, "| $method | N/A | N/A | N/A | N/A | N/A | N/A | N/A |")
                    else
                        println(io, "| $method | $(pool.rows) | $(pool.nonfinite_rows) | $(pool.box_violation_rows) | $(_format_float(pool.top_row_truth_rmse)) | $(_format_float(pool.best_truth_rmse)) | $(pool.best_truth_row) | $(pool.better_than_top_count) |")
                    end
                end
                println(io)

                println(io, "#### Local Diagnostic Pass (`InterpolatorAAADGPR`)\n")
                println(io, "| Metric | Value |")
                println(io, "| --- | --- |")
                println(io, "| Diagnostic mode | `$(diag.diagnostic_mode)` |")
                println(io, "| Difficulty | `$(diag.difficulty)` |")
                println(io, "| Bottleneck | $(diag.bottleneck) |")
                println(io, "| Best eval point | $(_format_float(diag.best_eval_point)) |")
                println(io, "| Worst derivative error | $(_format_float(diag.worst_deriv_error)) |")
                println(io, "| Production solution count | $(diag.prod_solution_count) |")
                println(io, "| Jacobian condition number | $(_format_float(diag.jacobian_cond)) |")
                println(io, "| Effective rank | $(diag.effective_rank) |")
                println(io, "| Root sensitivity | $(_format_float(diag.root_sensitivity)) |")
                println(io, "| Sensitivity nonlinearity | $(_format_float(diag.sensitivity_nonlinearity)) |")
                println(io, "| Sensitivity concentration | $(_format_float(diag.sensitivity_concentration)) |")
                println(io, "| Pathological concentration | $(diag.is_pathological) |")
                println(io, "| UQ status | `$(diag.uq_status)` |")
                println(io, "| UQ max CV | $(_format_float(diag.uq_max_cv)) |")
                println(io)

                if !isempty(diag.direct_failure)
                    println(io, "> Direct diagnose failure before transformation: `$(replace(diag.direct_failure, '\n' => ' '))`\n")
                end

                println(io, "#### Preliminary Diagnosis\n")
                for bullet in _case_interpretation(spec, selected, pools, diag)
                    println(io, "- $bullet")
                end
                println(io)
            end
        end
    end
end

function main()
    mkpath(OUTPUT_ROOT)
    specs = _default_cases()

    println("Building benchmark-faithful cases...")
    peps = Dict{String, ParameterEstimationProblem}()
    for spec in specs
        println("  - $(spec.case_id)")
        peps[spec.case_id] = build_benchmark_case(spec.case_id)
    end

    diagnostics = Dict{String, NamedTuple}()
    local_diag_path = joinpath(OUTPUT_ROOT, "local_diagnostics.tsv")
    if RENDER_ONLY
        println("\nLoading cached local diagnostics...")
        diagnostics = _read_local_diagnostics_tsv(local_diag_path)
    else
        println("\nRunning local diagnostics...")
        for spec in specs
            println("  - $(spec.case_id)")
            diagnostics[spec.case_id] = _run_local_diagnosis(peps[spec.case_id])
        end
    end

    noise_headers = [
        "system", "noise_tag", "method",
        "mean_rmse", "median_rmse", "mean_max_rel_err",
        "success_count", "total_count",
    ]
    noise_rows = vcat(_noise_summary_rows("cstr"), _noise_summary_rows("crauste"))
    _write_tsv(joinpath(OUTPUT_ROOT, "benchmark_noise_summary.tsv"), noise_headers, noise_rows)

    case_headers = [
        "case_id", "system", "noise_tag", "method",
        "selected_rmse", "selected_max_rel_err", "selected_success",
        "pool_rows", "pool_nonfinite_rows", "pool_box_violation_rows",
        "pool_first_row_truth_rmse", "pool_best_truth_rmse", "pool_best_truth_row",
        "pool_better_than_first_count",
    ]
    _write_tsv(joinpath(OUTPUT_ROOT, "case_method_summary.tsv"), case_headers, _case_method_rows(specs, peps))

    diag_headers = [
        "case_id", "system", "diagnostic_mode", "difficulty", "bottleneck",
        "best_interpolator", "best_eval_point",
        "worst_deriv_error", "max_required_order",
        "prod_solution_count", "prod_closest_distance",
        "jacobian_cond", "effective_rank", "root_sensitivity",
        "sensitivity_nonlinearity", "sensitivity_concentration",
        "is_pathological", "uq_status", "uq_max_cv",
    ]
    if !RENDER_ONLY
        _write_tsv(local_diag_path, diag_headers, _local_diagnostic_rows(specs, diagnostics))
    end

    md_path = joinpath(OUTPUT_ROOT, "summary.md")
    _render_markdown(md_path, specs, peps, diagnostics)

    println("\nWrote deep-dive artifact to:")
    println("  " * md_path)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
