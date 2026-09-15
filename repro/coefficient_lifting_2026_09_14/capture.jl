# Run from the global Julia environment; the existing optional environment is
# activated without resolution or installation.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, PEtab, JSON, SHA
const Ext = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
length(ARGS) == 3 || error("Usage: capture.jl problem.yaml condition output.json")
path, condition, output = ARGS
isfile(output) && error("Use a fresh output file")
println("Loading adapter"); flush(stdout)
problem = load_petab_problem(path)
println("Extracting coefficient structure"); flush(stdout)
seconds = @elapsed structure = Ext.petab_coefficient_structure(problem, condition)
record = Dict{String,Any}("condition_id"=>structure.condition_id, "state_ids"=>structure.state_ids,
    "parameter_ids"=>structure.parameter_ids, "variables"=>string.(ODEParameterEstimation.Nemo.gens(structure.ring)),
    "seconds"=>seconds, "julia_version"=>string(VERSION),
    "denominator_guards"=>string.(structure.denominator_guards),
    "source_hashes"=>Dict(file=>bytes2hex(sha256(read(joinpath(dirname(path), file))))
        for file in sort(readdir(dirname(path))) if endswith(file, ".xml") || endswith(file, ".tsv") || endswith(file, ".yaml")),
    "extractor_sha256"=>bytes2hex(sha256(read(joinpath(@__DIR__, "../../ext/petab/coefficient_structure.jl")))))
for property in (:assignments, :coefficients, :expanded_coefficients, :dynamics, :expanded_dynamics)
    record[string(property)] = Dict(k=>string(v) for (k,v) in getproperty(structure, property))
end
open(output, "w") do io
    JSON.print(io, record, 2)
end
println("Captured ", length(structure.assignments), " assignments and ", length(structure.coefficients), " coefficients in ", seconds, " seconds")
