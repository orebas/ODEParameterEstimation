# Capture the actual single-point HC roots and the equations about to be polished.
# Reuses the frozen full-scale validation harness, but stops after the first
# interpolator's HC solve. The instrumentation exists only in this Julia process.
using ODEParameterEstimation, TOML, SHA
const ROOT = normpath(joinpath(@__DIR__, "..", ".."))
length(ARGS) == 2 || error("Expected MODEL OUTPUT_DIRECTORY")

function capture_actual_polish(pep, equations, solve_vars, data_vars, indices, values,
    roots, candidate, interpolants)
    isnothing(candidate) && error("Expected the ordinary noise-frontier candidate")
    instantiated = Vector{String}[]
    for (idx, data) in zip(indices, values)
        actual, actual_vars = ODEParameterEstimation.instantiate_noise_frontier_candidate(
            candidate, interpolants, pep.data_sample, pep.measured_quantities, idx)
        @assert isequal(actual_vars, solve_vars)
        sub = Dict(zip(data_vars, data))
        @assert isequal(actual, [ODEParameterEstimation.Symbolics.substitute(eq, sub) for eq in equations])
        push!(instantiated, string.(actual))
    end
    record = Dict("model"=>pep.name, "julia_version"=>string(VERSION),
        "equations"=>string.(equations), "solve_variables"=>string.(solve_vars),
        "data_variables"=>string.(data_vars), "point_indices"=>indices,
        "data_values"=>values, "roots"=>[real.(r) for r in roots],
        "instantiated_equations"=>instantiated,
        "source_revision"=>strip(read(Cmd(["git", "-C", ROOT, "rev-parse", "HEAD"]), String)),
        "multishot_source_sha256"=>bytes2hex(sha256(read(joinpath(ROOT,"src","core","optimized_multishot_estimation.jl")))))
    open(joinpath(abspath(ARGS[2]), "actual_system.toml"), "w") do io
        TOML.print(io, record; sorted=true)
    end
    println("CAPTURED actual $(length(equations)) × $(length(solve_vars)) system, $(length(roots)) points"); flush(stdout)
    throw(InterruptException())
end

source = read(joinpath(ROOT, "src", "core", "optimized_multishot_estimation.jl"), String)
start = first(findfirst("function optimized_multishot_parameter_estimation(", source))
source = source[start:end]
needle = "_t_hc_elapsed = time() - _t_hc_start"
@assert count(needle, source) == 1
hook = "try; Main.capture_actual_polish(PEP, local_template_equations, local_solve_vars, local_extended_data_vars, valid_point_indices, valid_param_values_list, solutions_by_point, frontier_sp_candidate, interpolants); catch capture_error; showerror(stderr,capture_error,catch_backtrace()); throw(InterruptException()); end"
source = replace(source, needle => needle * "\n\t\t\t\t" * hook)
Base.include_string(ODEParameterEstimation, source, "capture_actual_multishot.jl")
harness_path = joinpath(ROOT, "repro", "deferred_denominators_2026_09_11", "run_rational.jl")
harness = read(harness_path, String)
harness = replace(harness, "record[\"status\"] == \"complete\" || exit(1)" =>
    "isfile(joinpath(out, \"actual_system.toml\")) || exit(1)")
Base.include_string(Main, harness, harness_path)
