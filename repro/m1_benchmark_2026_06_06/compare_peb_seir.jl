using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using Logging

function benchmark_seir(; m1::Bool)
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

    return ParameterEstimationProblem(
        m1 ? "seir_m1_peb" : "seir_peb",
        model,
        mq,
        nothing,
        [0.0, 30.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
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

function run_case(label::Symbol, pep0; polish::Bool)
    n_unknowns = length(pep0.ic) + length(pep0.p_true)
    opts = EstimationOptions(
        datasize = 61,
        time_interval = [0.0, 30.0],
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
        polish_solver_solutions = polish,
        polish_solutions = polish,
        polish_method = PolishLSOBoundedLog,
        polish_maxtime = 120.0,
        polish_maxiters = 1000,
        polish_max_concurrency = 1,
        opt_maxiters = 5000,
        branch_completion = false,
        opt_lb = 1e-5 .* ones(n_unknowns),
        opt_ub = 10.0 .* ones(n_unknowns),
    )

    spep = sample_problem_data(pep0, opts)
    timed = @timed with_logger(NullLogger()) do
        analyze_parameter_estimation_problem(spep, opts)
    end
    raw_results, analysis, _ = timed.value
    solutions = field_or_index(analysis, :solutions, 1, [])
    raw_count = (raw_results isa Tuple && length(raw_results) >= 1 && raw_results[1] isa AbstractVector) ? length(raw_results[1]) : 0
    return (
        system = label,
        polish = polish,
        seconds = timed.time,
        raw_count = raw_count,
        best_count = length(solutions),
        algebraic_multiplicity = field_or_index(analysis, :algebraic_multiplicity, 9, missing),
        best_max_error = field_or_index(analysis, :best_max_error, 6, missing),
        best_approximation_error = field_or_index(analysis, :best_approximation_error, 7, missing),
    )
end

println("system,polish,seconds,raw_count,best_count,algebraic_multiplicity,best_max_error,best_approximation_error")
for polish in (false, true)
    for (label, pep) in ((:seir_peb, benchmark_seir(m1 = false)), (:seir_m1_peb, benchmark_seir(m1 = true)))
        row = run_case(label, pep; polish = polish)
        println(join((row.system, row.polish, round(row.seconds; digits = 3), row.raw_count, row.best_count,
            row.algebraic_multiplicity, row.best_max_error, row.best_approximation_error), ","))
        flush(stdout)
    end
end
