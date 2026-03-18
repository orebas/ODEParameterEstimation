using Dates
using Logging
using ODEParameterEstimation

const MODEL_NAME = Symbol(ARGS[1])
const MODEL_CATEGORY = Symbol(ARGS[2])

function build_iterfix_audit_opts(pep)
    time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval
    return EstimationOptions(
        datasize = 101,
        time_interval = time_interval,
        noise_level = 1e-8,
        flow = FlowStandard,
        use_si_template = true,
        use_parameter_homotopy = true,
        polish_solver_solutions = true,
        polish_solutions = false,
        interpolators = [InterpolatorAAAD, InterpolatorAGPRobust],
        nooutput = false,
        diagnostics = true,
        save_system = false,
    )
end

function audit_marker(tag::AbstractString, pairs::Pair...)
    payload = join((string(first(p), "=", last(p)) for p in pairs), '\t')
    println(string(tag, '\t', payload))
    flush(stdout)
    flush(stderr)
end

function main()
    start_time = time()
    audit_marker(
        "AUDIT_CASE_START",
        :model => MODEL_NAME,
        :category => MODEL_CATEGORY,
        :started_at => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
    )

    try
        model_fn = getfield(ODEParameterEstimation, MODEL_NAME)
        pep = model_fn()
        opts = build_iterfix_audit_opts(pep)
        sampled = sample_problem_data(pep, opts)
        analyze_parameter_estimation_problem(sampled, opts)

        audit_marker(
            "AUDIT_CASE_END",
            :status => "completed",
            :runtime_seconds => round(time() - start_time; digits = 3),
            :finished_at => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        )
        return
    catch err
        exception_summary = sprint(showerror, err)
        audit_marker(
            "AUDIT_EXCEPTION_SUMMARY",
            :status => "error",
            :summary => repr(exception_summary),
        )
        showerror(stderr, err, catch_backtrace())
        println(stderr)
        flush(stderr)
        audit_marker(
            "AUDIT_CASE_END",
            :status => "error",
            :runtime_seconds => round(time() - start_time; digits = 3),
            :finished_at => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        )
        exit(1)
    end
end

main()
