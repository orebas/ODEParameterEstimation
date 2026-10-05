# Run in the optional reference environment: CHECKOUT OUTPUT.toml [BASELINE_MODULE].
# Warm both implementations, then alternate order with one BLAS thread.
using GaussianProcesses, SIAN, Nemo, StructuralIdentifiability
using LinearAlgebra, Statistics, Random, TOML, Optim, LineSearches
include(joinpath(ARGS[1], "src", "internal", "gp", "GPBackend.jl"))
include(joinpath(ARGS[1], "src", "internal", "sian", "SIANBackend.jl"))
include(joinpath(ARGS[1], "test", "support", "backend_fixtures.jl"))
BLAS.set_num_threads(1)
baseline = if length(ARGS) == 3
    scope = Module(:BaselineGP)
    Base.include(scope,ARGS[3])
    getproperty(scope,:GPBackend)
else
    nothing
end

function paired_cost(reference, internal)
    reference(); internal()
    seconds = [Float64[], Float64[]]
    bytes = [Int[], Int[]]
    callbacks = (reference, internal)
    for repetition in 1:6
        for arm in (isodd(repetition) ? (1, 2) : (2, 1))
            GC.gc()
            measurement = @timed callbacks[arm]()
            push!(seconds[arm], measurement.time)
            push!(bytes[arm], measurement.bytes)
        end
    end
    return Dict("reference_seconds"=>seconds[1], "internal_seconds"=>seconds[2],
        "reference_bytes"=>bytes[1], "internal_bytes"=>bytes[2],
        "median_time_ratio"=>median(seconds[2])/median(seconds[1]),
        "median_allocation_ratio"=>median(bytes[2])/median(bytes[1]))
end

records = Dict{String,Any}()
cases = TOML.parsefile(joinpath(ARGS[1], "test", "fixtures", "internal_backends", "fits.toml"))["cases"]
xs = collect(range(0., 4.; length=201))
ys = sin.(1.4xs) .+ 0.2cos.(3.1xs) .+ 0.03randn(MersenneTwister(20261005), length(xs))
push!(cases, Dict("case"=>"smooth_noisy_201", "xs"=>xs, "ys"=>ys))
for data in cases
    xs, ys = data["xs"], data["ys"]
    normalized = (ys .- mean(ys)) ./ std(ys)
    function reference()
        gp = GaussianProcesses.GP(xs, normalized, MeanZero(), SEIso(log(std(xs)/8), 0.), -2.)
        GaussianProcesses.optimize!(gp; method=Optim.LBFGS(linesearch=LineSearches.BackTracking()))
        return gp
    end
    internal() = GPBackend.fit_se(xs, normalized)
    record = paired_cost(reference, internal)
    if !isnothing(baseline)
        record["baseline_comparison"] = paired_cost(()->baseline.fit_se(xs, normalized), internal)
    end
    records[data["case"]] = record
end
for rational in (false, true)
    records[rational ? "sian_rational" : "sian_polynomial"] =
        paired_cost(()->sian_fixture(SIAN, rational), ()->sian_fixture(SIANBackend, rational))
end
open(ARGS[2], "w") do io
    TOML.print(io, Dict("julia"=>string(VERSION), "blas_threads"=>BLAS.get_num_threads(),
        "cases"=>records))
end
