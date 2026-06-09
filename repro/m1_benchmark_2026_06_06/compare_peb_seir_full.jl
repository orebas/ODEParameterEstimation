using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using Symbolics: Num
using Logging

const QUOLL_SEIR_DATA = "/home/orebas/ParameterEstimationBenchmark-local/benchmark_quoll_broad_2026-05-29/filetree/data_noisy/seir_0_0/data.csv"
const OUTDIR = joinpath(@__DIR__, "peb_seir_full")

function benchmark_seir(; m1::Bool, data_sample = nothing)
    parameters = @parameters a b nu
    states = @variables S(t) E(t) In(t) Npop(t)
    observables = m1 ? @variables(y1(t), y2(t), y3(t)) : @variables(y1(t), y2(t))

    equations = [
        D(S) ~ (-15840.0 * b * In * S) / (3960000.0 * Npop),
        D(E) ~ ((15840.0 * b * In * S) / (2000.0 * Npop) - 6.0 * nu * E) / 20.0,
        D(In) ~ (-4.0 * a * In + 6.0 * nu * E) / 10.0,
        D(Npop) ~ 0,
    ]
    measured_quantities = m1 ?
        [observables[1] ~ 10.0 * In, observables[2] ~ 2000.0 * Npop, observables[3] ~ 20.0 * E] :
        [observables[1] ~ 10.0 * In, observables[2] ~ 2000.0 * Npop]

    model, mq = create_ordered_ode_system(m1 ? "seir_m1_peb" : "seir_peb", states, parameters, equations, measured_quantities)

    # PEB seir_0_0 truth from repro/multiplicity_complete_2026_05_19/branches_in_bounds.txt.
    p_true = [0.500, 0.275, 0.376]
    ic_true = [0.839, 0.246, 0.356, 0.201]

    pep = ParameterEstimationProblem(
        m1 ? "seir_m1_peb" : "seir_peb",
        model,
        mq,
        data_sample,
        [0.0, 30.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
    return pep, mq
end

function read_peb_data(path::AbstractString, mq)
    rows = Vector{Vector{Float64}}()
    for line in eachline(path)
        isempty(strip(line)) && continue
        push!(rows, parse.(Float64, split(strip(line), ",")))
    end
    data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
    data_sample["t"] = [row[1] for row in rows]
    for (i, eq) in enumerate(mq)
        data_sample[Num(eq.rhs)] = [row[i + 1] for row in rows]
    end
    return data_sample
end

function full_options(pep0)
    n_unknowns = length(pep0.ic) + length(pep0.p_true)
    return EstimationOptions(
        datasize = 750,
        time_interval = [0.0, 30.0],
        noise_level = 0.0,
        system_solver = SolverHC,
        flow = FlowStandard,
        use_si_template = true,
        system_construction_policy = :noise_frontier,
        construction_candidate_limit = 64,
        construction_beam_width = 16,
        construction_compute_mixed_volume = true,
        branch_completion = false,
        shooting_points = 20,
        shooting_warp = true,
        shooting_warp_beta = 3.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 15,
        polish_solver_solutions = true,
        polish_solutions = true,
        polish_maxiters = 5000,
        polish_method = PolishLSOBoundedLog,
        opt_maxiters = 200000,
        opt_lb = 1e-5 .* ones(n_unknowns),
        opt_ub = 10.0 .* ones(n_unknowns),
        abstol = 1e-12,
        reltol = 1e-12,
        polish_maxtime = 600.0,
        polish_divergence_factor = 10.0,
        polish_stagnation_window = 50,
        polish_ode_maxiters = 20000,
        diagnostics = true,
        nooutput = true,
        save_system = false,
    )
end

function field_or_index(analysis, name::Symbol, idx::Int, default = missing)
    if hasproperty(analysis, name)
        return getproperty(analysis, name)
    end
    try
        return analysis[idx]
    catch
        return default
    end
end

function best_solution(analysis)
    sols = field_or_index(analysis, :solutions, 1, [])
    return isempty(sols) ? nothing : sols[1]
end

function provenance_value(sol, name::Symbol, default = missing)
    isnothing(sol) && return default
    hasproperty(sol, :provenance) || return default
    provenance = sol.provenance
    hasproperty(provenance, name) || return default
    value = getproperty(provenance, name)
    return isnothing(value) ? default : value
end

function value_string(value)
    value === missing && return ""
    return replace(string(value), "," => ";", "\n" => " ")
end

function raw_count(raw_results)
    return (raw_results isa Tuple && length(raw_results) >= 1 && raw_results[1] isa AbstractVector) ? length(raw_results[1]) : 0
end

function summarize_row(label::Symbol, source::Symbol, elapsed::Real, raw_results, analysis)
    sol = best_solution(analysis)
    sols = field_or_index(analysis, :solutions, 1, [])
    return (
        system = label,
        data_source = source,
        seconds = elapsed,
        raw_count = raw_count(raw_results),
        best_count = length(sols),
        algebraic_multiplicity = field_or_index(analysis, :algebraic_multiplicity, 9, missing),
        best_max_error = field_or_index(analysis, :best_max_error, 6, missing),
        best_approximation_error = field_or_index(analysis, :best_approximation_error, 7, missing),
        best_rms_error = field_or_index(analysis, :best_rms_error, 8, missing),
        source_type = provenance_value(sol, :source_type, ""),
        interpolator_source = provenance_value(sol, :interpolator_source, ""),
        rescue_path = provenance_value(sol, :rescue_path, ""),
        primary_method = provenance_value(sol, :primary_method, ""),
        multipoint_combo_index = provenance_value(sol, :multipoint_combo_index, ""),
        aggregation_strategy = provenance_value(sol, :aggregation_strategy, ""),
    )
end

function write_row(io, row)
    println(io, join(value_string.((row.system, row.data_source, round(row.seconds; digits = 3),
        row.raw_count, row.best_count, row.algebraic_multiplicity, row.best_max_error,
        row.best_approximation_error, row.best_rms_error, row.source_type,
        row.interpolator_source, row.rescue_path, row.primary_method,
        row.multipoint_combo_index, row.aggregation_strategy)), ","))
end

function write_solution(label::Symbol, analysis)
    sol = best_solution(analysis)
    open(joinpath(OUTDIR, string(label, "_best_solution.txt")), "w") do io
        if isnothing(sol)
            println(io, "no solution")
            return
        end
        println(io, "states=", sol.states)
        println(io, "parameters=", sol.parameters)
        if hasproperty(sol, :provenance)
            println(io, "provenance=", sol.provenance)
        end
    end
end

function write_timing(label::Symbol, timing)
    open(joinpath(OUTDIR, string(label, "_timing.txt")), "w") do io
        if isnothing(timing)
            println(io, "no timing captured")
        else
            show(io, MIME("text/plain"), ODEParameterEstimation.timing_breakdown_to_dict(timing))
            println(io)
        end
    end
end

function run_case(label::Symbol, pep0, source::Symbol)
    opts = full_options(pep0)
    pep = source == :generated_clean ? sample_problem_data(pep0, opts) : pep0
    t0 = time()
    (value, timing) = ODEParameterEstimation.with_estimation_timing() do
        with_logger(NullLogger()) do
            analyze_parameter_estimation_problem(pep, opts)
        end
    end
    elapsed = time() - t0
    raw_results, analysis, _ = value
    write_timing(label, timing)
    write_solution(label, analysis)
    return summarize_row(label, source, elapsed, raw_results, analysis)
end

mkpath(OUTDIR)

original_pep0, original_mq = benchmark_seir(m1 = false)
original_data = read_peb_data(QUOLL_SEIR_DATA, original_mq)
original_pep, _ = benchmark_seir(m1 = false, data_sample = original_data)
m1_pep, _ = benchmark_seir(m1 = true)

summary_path = joinpath(OUTDIR, "summary.csv")
open(summary_path, "w") do io
    println(io, "system,data_source,seconds,raw_count,best_count,algebraic_multiplicity,best_max_error,best_approximation_error,best_rms_error,source_type,interpolator_source,rescue_path,primary_method,multipoint_combo_index,aggregation_strategy")
    println("system,data_source,seconds,raw_count,best_count,algebraic_multiplicity,best_max_error,best_approximation_error,best_rms_error,source_type,interpolator_source,rescue_path,primary_method,multipoint_combo_index,aggregation_strategy")

    for row in (
        run_case(:seir_peb_full, original_pep, :quoll_broad_data_csv),
        run_case(:seir_m1_peb_full, m1_pep, :generated_clean),
    )
        write_row(io, row)
        write_row(stdout, row)
        flush(io)
        flush(stdout)
    end
end

println("summary_path=", summary_path)
