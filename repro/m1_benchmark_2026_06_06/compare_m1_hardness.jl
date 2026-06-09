using ODEParameterEstimation
using Logging
using Printf

const OUT_CSV = joinpath(@__DIR__, "m1_hardness_local.csv")

const CASES = [
    (:biohydrogenation, ODEParameterEstimation.biohydrogenation, [0.0, 36.0], :biohydrogenation),
    (:biohydrogenation_m1, ODEParameterEstimation.biohydrogenation_m1, [0.0, 36.0], :biohydrogenation),
    (:daisy_mamil4, ODEParameterEstimation.daisy_mamil4, [0.0, 10.0], :daisy_mamil4),
    (:daisy_mamil4_m1, ODEParameterEstimation.daisy_mamil4_m1, [0.0, 10.0], :daisy_mamil4),
    (:seir, ODEParameterEstimation.seir, [0.0, 60.0], :seir),
    (:seir_m1, ODEParameterEstimation.seir_m1, [0.0, 60.0], :seir),
    (:slowfast, ODEParameterEstimation.slowfast, [0.0, 10.0], :slowfast),
    (:slow_fast_m1, ODEParameterEstimation.slow_fast_m1, [0.0, 10.0], :slowfast),
    (:latent_subpopulation_branch, ODEParameterEstimation.latent_subpopulation_branch, [0.0, 12.0], :latent_subpopulation),
    (:latent_subpopulation_observed_control, ODEParameterEstimation.latent_subpopulation_observed_control, [0.0, 12.0], :latent_subpopulation),
    (:receptor_subtype_binding_branch, ODEParameterEstimation.receptor_subtype_binding_branch, [0.0, 8.0], :receptor_subtype_binding),
    (:receptor_subtype_binding_observed_control, ODEParameterEstimation.receptor_subtype_binding_observed_control, [0.0, 8.0], :receptor_subtype_binding),
]

function csv_escape(x)
    s = string(x)
    if occursin(',', s) || occursin('"', s) || occursin('\n', s)
        return "\"" * replace(s, "\"" => "\"\"") * "\""
    end
    return s
end

function analysis_field(analysis, name::Symbol, fallback_index::Int, default = missing)
    if hasproperty(analysis, name)
        return getproperty(analysis, name)
    end
    try
        return analysis[fallback_index]
    catch
        return default
    end
end

function run_case(name::Symbol, ctor, interval, family::Symbol)
    pep = ctor()
    n_unknowns = length(pep.ic) + length(pep.p_true)
    opts = EstimationOptions(
        datasize = 61,
        time_interval = interval,
        noise_level = 0.0,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        flow = FlowStandard,
        system_solver = SolverHC,
        use_si_template = true,
        system_construction_policy = :noise_frontier,
        construction_candidate_limit = 32,
        construction_beam_width = 8,
        construction_compute_mixed_volume = true,
        interpolator = InterpolatorAAAD,
        interpolators = InterpolatorMethod[],
        shooting_points = 1,
        use_parameter_homotopy = false,
        use_multipoint = false,
        polish_solver_solutions = false,
        polish_solutions = false,
        branch_completion = false,
        opt_lb = 1e-5 .* ones(n_unknowns),
        opt_ub = 10.0 .* ones(n_unknowns),
    )

    t0 = time()
    try
        spep = sample_problem_data(pep, opts)
        sample_seconds = time() - t0
        timed = @timed with_logger(NullLogger()) do
            analyze_parameter_estimation_problem(spep, opts)
        end
        raw_results, analysis, _ = timed.value
        solutions = analysis_field(analysis, :solutions, 1, [])
        raw_count = (raw_results isa Tuple && length(raw_results) >= 1 && raw_results[1] isa AbstractVector) ? length(raw_results[1]) : 0
        best_count = length(solutions)
        return (
            family = family,
            system = name,
            status = :ok,
            sample_seconds = sample_seconds,
            estimate_seconds = timed.time,
            alloc_mb = timed.bytes / 1024^2,
            raw_count = raw_count,
            best_count = best_count,
            algebraic_multiplicity = analysis_field(analysis, :algebraic_multiplicity, 9, missing),
            best_error = analysis_field(analysis, :besterror, 2, missing),
            best_max_error = analysis_field(analysis, :best_max_error, 6, missing),
            best_approximation_error = analysis_field(analysis, :best_approximation_error, 7, missing),
            message = "",
        )
    catch err
        return (
            family = family,
            system = name,
            status = :error,
            sample_seconds = time() - t0,
            estimate_seconds = missing,
            alloc_mb = missing,
            raw_count = missing,
            best_count = missing,
            algebraic_multiplicity = missing,
            best_error = missing,
            best_max_error = missing,
            best_approximation_error = missing,
            message = sprint(showerror, err),
        )
    end
end

const HEADER = [
    :family,
    :system,
    :status,
    :sample_seconds,
    :estimate_seconds,
    :alloc_mb,
    :raw_count,
    :best_count,
    :algebraic_multiplicity,
    :best_error,
    :best_max_error,
    :best_approximation_error,
    :message,
]

rows = NamedTuple[]
for (name, ctor, interval, family) in CASES
    @info "running local hardness comparison" system = name
    row = run_case(name, ctor, interval, family)
    push!(rows, row)
    println(join((csv_escape(getproperty(row, h)) for h in HEADER), ","))
    flush(stdout)
end

open(OUT_CSV, "w") do io
    println(io, join(string.(HEADER), ","))
    for row in rows
        println(io, join((csv_escape(getproperty(row, h)) for h in HEADER), ","))
    end
end

println("wrote ", OUT_CSV)
