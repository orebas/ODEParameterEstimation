# Run with the isolated reference environment and a checkout path as argument.
# Includes only the private GP module, so the upstream oracle remains independent.
using GaussianProcesses, Statistics, Random, TOML, Test
using Optim, LineSearches, TaylorDiff
include(joinpath(ARGS[1], "src", "internal", "gp", "GPBackend.jl"))

cases = (
    ("smooth_clean", x->sin(1.4x)+0.2cos(3.1x), x->1.4cos(1.4x)-0.62sin(3.1x), 0.,41),
    ("smooth_noisy", x->sin(1.4x)+0.2cos(3.1x), x->1.4cos(1.4x)-0.62sin(3.1x), .03,41),
    ("mixed_scale", x->sin(.8x)+.08sin(9x), x->.8cos(.8x)+.72cos(9x), .01,61),
    ("transient", x->exp(-3x)+.1sin(4x), x->-3exp(-3x)+.4cos(4x), .01,41),
)
records = []
frozen = TOML.parsefile(joinpath(ARGS[1], "test", "fixtures", "internal_backends", "fits.toml"))["cases"]
for (idx,(name,f,df,noise,n)) in enumerate(cases)
    # Reuse the exact checked-in observations across Julia/BLAS versions.
    data = only(filter(data -> data["case"] == name, frozen))
    xs,ys = data["xs"],data["ys"]
    μ,σ = mean(ys),std(ys)
    normalized = (ys.-μ)./max(σ,1e-8)
    gp = GaussianProcesses.GP(xs,normalized,MeanZero(),SEIso(log(std(xs)/8),0.),-2.)
    result = GaussianProcesses.optimize!(gp;method=Optim.LBFGS(linesearch=LineSearches.BackTracking()))
    fit = GPBackend.fit_se(xs,normalized)
    old(x) = σ*first(GaussianProcesses.predict_f(gp,[x]))[1]+μ
    new(x) = σ*GPBackend.predict_mean(fit,x)+μ
    pts = [(xs[j]+xs[j+1])/2 for j in 2:3:n-2]
    jets_old = [[k==0 ? old(x) : TaylorDiff.derivative(old,x,Val(k)) for x in pts] for k in 0:6]
    jets_new = [[k==0 ? new(x) : TaylorDiff.derivative(new,x,Val(k)) for x in pts] for k in 0:6]
    record = Dict("case"=>name,"xs"=>xs,"ys"=>ys,"points"=>pts,"jets"=>jets_old,
        "parameters"=>GaussianProcesses.get_params(gp),"nll"=>-gp.target,
        "internal_parameters"=>fit.log_parameters,"internal_nll"=>fit.nll,
        "max_jet_difference"=>[maximum(abs.(a.-b)) for (a,b) in zip(jets_old,jets_new)],
        "reference_rmse"=>[sqrt(mean(abs2,jets_old[1].-f.(pts))),sqrt(mean(abs2,jets_old[2].-df.(pts)))],
        "internal_rmse"=>[sqrt(mean(abs2,jets_new[1].-f.(pts))),sqrt(mean(abs2,jets_new[2].-df.(pts)))],
        "reference_converged"=>Optim.converged(result),"internal_converged"=>fit.converged)
    push!(records,record)
    println(name," ", record["max_jet_difference"]," nll ",-gp.target," ",fit.nll)
    flush(stdout)
end
open(ARGS[2],"w") do io
    TOML.print(io,Dict("cases"=>records))
end
