# Optional upstream oracle: run in an environment containing SIAN and
# GaussianProcesses, never in the package's ordinary test environment.
using SIAN, GaussianProcesses, Nemo, StructuralIdentifiability
using Random, Statistics, LinearAlgebra, Optim, LineSearches, TaylorDiff, TOML

include(joinpath(@__DIR__, "..", "support", "backend_fixtures.jl"))

function gp_fixture()
    xs = collect(range(0.,4.;length=17))
    ys = sin.(xs) .+ 0.03*cos.(3xs)
    gp = GaussianProcesses.GP(xs,ys,MeanZero(),SEIso(log(0.7),log(1.2)),log(0.05))
    GaussianProcesses.update_target_and_dtarget!(gp)
    points = [0.125,1.375,2.625,3.875]
    f(x) = first(GaussianProcesses.predict_f(gp,[x]))[1]
    jets = [[order == 0 ? f(x) : TaylorDiff.derivative(f,x,Val(order)) for x in points] for order in 0:6]
    return Dict("xs"=>xs,"ys"=>ys,"points"=>points,
        "log_parameters"=>GaussianProcesses.get_params(gp),
        "covariance"=>vec(Matrix(gp.cK)),"nll"=>-gp.target,
        "gradient"=>-gp.dtarget,"jets"=>jets)
end

function capture_backends(output)
    result = Dict("provenance"=>Dict("odepe_revision"=>"81bcf14e4c9e16fb60391a7427586974498450bd",
        "sian_revision"=>"2f78ca8a0cc93f99eb2f800f08c1dbd20f8b28d9",
        "gp_revision"=>"3e896e9dbd0c41341c723ab16dcf0c261fc7b95a",
        "julia"=>string(VERSION)),
        "sian_polynomial"=>sian_fixture(SIAN,false),
        "sian_rational"=>sian_fixture(SIAN,true),"gp"=>gp_fixture())
    open(output,"w") do io
        TOML.print(io,result)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    capture_backends(only(ARGS))
end
