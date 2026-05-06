using Dates
using FastLevenbergMarquardt
using ForwardDiff
using LinearAlgebra
using NonlinearSolve
using SciMLBase

const PROBE_OUTPUT = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "residual_polish_ablation", "fast_nlls_forwarddiff_probe.md")

function build_probe_problem()
    function residual!(res, u, _)
        x, y = u
        res[1] = x - 2.0
        res[2] = y - 3.0
        res[3] = x * y - 6.0
        return nothing
    end

    function residual_vec(u)
        r = Vector{eltype(u)}(undef, 3)
        residual!(r, u, nothing)
        return r
    end

    function jacobian!(J, u, _)
        ForwardDiff.jacobian!(J, residual_vec, u)
        return nothing
    end

    nf = NonlinearFunction(
        residual!;
        resid_prototype = zeros(3),
        jac_prototype = zeros(3, 2),
        jac = jacobian!,
    )
    return NonlinearLeastSquaresProblem(nf, [1.5, 2.5])
end

function run_probe(alg, label)
    prob = build_probe_problem()
    try
        sol = NonlinearSolve.solve(prob, alg; abstol = 1e-10, reltol = 1e-10, maxiters = 1000)
        residual_norm = norm(sol.resid)
        return Dict(
            :label => label,
            :status => SciMLBase.successful_retcode(sol) ? :ok : :retcode_fail,
            :retcode => string(sol.retcode),
            :u => collect(sol.u),
            :residual_norm => residual_norm,
            :reason => "",
        )
    catch err
        return Dict(
            :label => label,
            :status => :error,
            :retcode => "error",
            :u => Float64[],
            :residual_norm => Inf,
            :reason => sprint(showerror, err),
        )
    end
end

function render_report(path, reports)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Fast NLLS ForwardDiff Probe\n")
        println(io, "- Generated: `$(Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS"))`\n")
        println(io, "| Solver | Status | Retcode | Residual norm | Solution | Reason |")
        println(io, "| --- | --- | --- | ---: | --- | --- |")
        for report in reports
            solution = isempty(report[:u]) ? "`[]`" : "`$(round.(report[:u]; digits = 6))`"
            reason = isempty(report[:reason]) ? "" : "`$(report[:reason])`"
            println(
                io,
                "| `$(report[:label])` | `$(report[:status])` | `$(report[:retcode])` | `$(round(report[:residual_norm]; digits = 8))` | $(solution) | $(reason) |",
            )
        end
    end
end

function main()
    reports = Dict[
        run_probe(
            NonlinearSolve.FastShortcutNLLSPolyalg(
                concrete_jac = true,
                autodiff = nothing,
                jvp_autodiff = nothing,
                vjp_autodiff = nothing,
            ),
            "FastShortcutNLLSPolyalg()",
        ),
        run_probe(
            NonlinearSolve.FastLevenbergMarquardtJL(autodiff = nothing),
            "FastLevenbergMarquardtJL()",
        ),
        run_probe(
            NonlinearSolve.TrustRegion(autodiff = nothing),
            "TrustRegion()",
        ),
        run_probe(
            NonlinearSolve.LevenbergMarquardt(autodiff = nothing),
            "LevenbergMarquardt()",
        ),
    ]
    render_report(PROBE_OUTPUT, reports)
    println("Wrote probe report to $(PROBE_OUTPUT)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
