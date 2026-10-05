using ODEParameterEstimation
using Random
using Statistics
using Printf
using TOML

const ODEPE = ODEParameterEstimation
const methods = (
    gp = ODEPE.aaad_gpr_pivot,
    agp_se = ODEPE.agp_gpr_robust,
    agp_uq = ODEPE.agp_gpr_uq,
)

cases = (
    (name = "smooth_clean", f = x -> sin(1.4x) + 0.2cos(3.1x),
     df = x -> 1.4cos(1.4x) - 0.62sin(3.1x), noise = 0.0, n = 41),
    (name = "smooth_noisy", f = x -> sin(1.4x) + 0.2cos(3.1x),
     df = x -> 1.4cos(1.4x) - 0.62sin(3.1x), noise = 0.03, n = 41),
    (name = "mixed_scale", f = x -> sin(0.8x) + 0.08sin(9x),
     df = x -> 0.8cos(0.8x) + 0.72cos(9x), noise = 0.01, n = 61),
    (name = "transient", f = x -> exp(-3x) + 0.1sin(4x),
     df = x -> -3exp(-3x) + 0.4cos(4x), noise = 0.01, n = 41),
)

input_path = joinpath(@__DIR__, "inputs.toml")
datasets = if isfile(input_path)
    TOML.parsefile(input_path)
else
    generated = Dict{String, Any}()
    for (case_idx, case) in enumerate(cases)
        rng = MersenneTwister(20261004 + case_idx)
        xs = collect(range(0.0, 4.0; length = case.n))
        generated[case.name] = Dict(
            "xs" => xs,
            "ys" => case.f.(xs) .+ case.noise .* randn(rng, case.n),
            "eval_xs" => [(xs[j] + xs[j+1])/2 for j in 2:3:(case.n-2)],
            "seed" => 20261004 + case_idx,
        )
    end
    open(input_path, "w") do io
        TOML.print(io, generated; sorted = true)
    end
    generated
end

println("Julia=", VERSION, " ODEPE=", Base.pkgversion(ODEPE))
for pkg in (ODEPE.GaussianProcesses, ODEPE.AbstractGPs, ODEPE.Optim,
            ODEPE.Nemo, ODEPE.StructuralIdentifiability)
    println(nameof(pkg), "=", Base.pkgversion(pkg))
end
println("case,method,n,noise,pred_rmse,jet1_rmse,fit_seconds,status")
for (case_idx, case) in enumerate(cases)
    xs = datasets[case.name]["xs"]
    ys = datasets[case.name]["ys"]
    eval_xs = datasets[case.name]["eval_xs"]
    for (method_name, fit) in pairs(methods)
        fit_seconds = 0.0
        try
            interp = nothing
            fit_seconds = @elapsed interp = fit(xs, ys)
            preds = interp.(eval_xs)
            pred_rmse = sqrt(mean(abs2, preds .- case.f.(eval_xs)))
            jets = [ODEPE._estimation_derivative(interp, 1, x) for x in eval_xs]
            jet_rmse = sqrt(mean(abs2, jets .- case.df.(eval_xs)))
            @printf("%s,%s,%d,%.3g,%.6g,%.6g,%.3f,ok\n",
                    case.name, method_name, case.n, case.noise,
                    pred_rmse, jet_rmse, fit_seconds)
        catch err
            @printf("%s,%s,%d,%.3g,NaN,NaN,%.3f,%s\n",
                    case.name, method_name, case.n, case.noise,
                    fit_seconds, replace(sprint(showerror, err), ',' => ';'))
        end
        flush(stdout)
    end
end
