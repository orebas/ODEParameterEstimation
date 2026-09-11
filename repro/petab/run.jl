# Isolated worker. The supervisor starts the 15-minute timer after package load,
# before any model-specific import, translation, start generation or compilation.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, PEtab, Fides, JSON, Random, TOML, OrdinaryDiffEq, SHA

length(ARGS) in (4, 5) || error("usage: run.jl MODEL METHOD MODEL_ROOT OUTPUT_PREFIX [MAX_DERIVATIVE_ORDER]")
name, method, root, prefix = ARGS[1:4]
max_derivative_order = length(ARGS) == 5 ? parse(Int, ARGS[5]) : 4
method in ("odepe", "odepe_blocks2", "odepe_blocks4", "odepe_blocks6", "petab_julia") || error("Unknown Julia method: $method")
config = TOML.parsefile(joinpath(@__DIR__, "targets.toml"))
Random.seed!(config["seed"])
started = time()
open(prefix * ".ready.tmp", "w") do io
    println(io, started)
end
Base.Filesystem.rename(prefix * ".ready.tmp", prefix * ".ready")
function write_result(value)
    open(prefix * ".json.tmp", "w") do io
        JSON.print(io, json_safe(value))
    end
    mv(prefix * ".json.tmp", prefix * ".json"; force=true)
end
json_safe(value::AbstractFloat) = isfinite(value) ? value : string(value)
json_safe(value::AbstractDict) = Dict(string(k) => json_safe(v) for (k, v) in value)
json_safe(value::NamedTuple) = Dict(string(k) => json_safe(v) for (k, v) in pairs(value))
json_safe(value::AbstractArray) = map(json_safe, value)
json_safe(value) = value

record = Dict{String, Any}("problem"=>name, "method"=>method,
    "benchmark_revision"=>config["benchmark_revision"], "seed"=>config["seed"],
    "seconds_cap"=>config["seconds_per_method"], "julia_version"=>string(VERSION))
record["thread_settings"] = Dict(key => get(ENV, key, "unset") for key in
    ("JULIA_NUM_THREADS", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"))
record["versions"] = Dict(d.name => string(d.version) for d in values(Pkg.dependencies())
    if d.name in ("ODEParameterEstimation", "PEtab", "Fides", "SBMLImporter", "Symbolics",
        "ModelingToolkit", "OrdinaryDiffEq", "StructuralIdentifiability", "SIAN", "GaussianProcesses"))
record["environment_sha256"] = bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml"))))
record["worker_sha256"] = bytes2hex(sha256(read(@__FILE__)))
source_root = normpath(joinpath(@__DIR__, "..", ".."))
source_files = String[joinpath(source_root, "Project.toml"), @__FILE__, joinpath(@__DIR__, "targets.toml")]
for directory in ("src", "ext")
    for (parent, _, files) in walkdir(joinpath(source_root, directory))
        append!(source_files, [joinpath(parent, file) for file in files if endswith(file, ".jl")])
    end
end
source_bytes = IOBuffer()
for path in sort!(source_files)
    write(source_bytes, relpath(path, source_root), '\0', read(path))
end
record["implementation_sha256"] = bytes2hex(sha256(take!(source_bytes)))
try
    path = joinpath(root, name, "$name.yaml")
    isfile(path) || (path = joinpath(root, name, "problem.yaml"))
    ode_options = name in config["julia_bdf_models"] ? (; odesolver=ODESolver(PEtab.QNDF())) : (;)
    if startswith(method, "odepe")
        adapter = load_petab_problem(path; ode_options=ode_options)
        prob = adapter.petab
    else
        ext = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
        reference_model, repaired = ext._load_petab_model(path)
        prob = PEtabODEProblem(reference_model; ode_options...)
        record["import_compatibility_repairs"] = repaired
    end
    record["ode_solver"] = string(prob.probinfo.solver.solver)
    record["ode_tolerances"] = (; abstol=prob.probinfo.solver.abstol,
        reltol=prob.probinfo.solver.reltol, maxiters=prob.probinfo.solver.maxiters)
    record["gradient_method"] = string(prob.probinfo.gradient_method)
    record["optimizer_options"] = (; hessian="BFGS", maxiter=10000,
        fatol=1e-8, frtol=1e-8, gatol=1e-6, grtol=0.0, xtol=0.0)
    # Every canonical pilot table lacks initialization distributions. Sampling
    # uniformly in scaled bounds is intentional; allow_inf prevents hidden
    # retries that would give the two baseline implementations different starts.
    parameter_rows = prob.model_info.model.petab_tables[:parameters]
    for row in eachrow(parameter_rows)
        if hasproperty(row, :initializationPriorType) && !ismissing(row.initializationPriorType)
            isempty(string(row.initializationPriorType)) || error("Initialization distribution needs explicit support in the pilot runner")
        end
    end
    start_path = joinpath(dirname(prefix), name * ".start.json")
    if isfile(start_path)
        start_record = JSON.parsefile(start_path)
        ids = String.(prob.xnames)
        mapping = Dict(zip(start_record["parameter_ids"], start_record["x"]))
        x0 = Float64[mapping[id] for id in ids]
    else
        x0 = collect(get_startguesses(MersenneTwister(config["seed"]), prob, 1;
            sample_prior=false, allow_inf=true))
        temporary, io = mktemp(dirname(start_path))
        try
            JSON.print(io, (; parameter_ids=String.(prob.xnames), x=x0,
                provenance="uniform in PEtab scaled bounds; no nominal estimated values", seed=config["seed"]))
        finally
            close(io)
        end
        # Concurrent methods use the same seed and ID ordering. Publish a whole
        # record atomically so another worker can never read a partial vector.
        Base.Filesystem.rename(temporary, start_path)
    end
    record["parameter_ids"] = String.(prob.xnames)
    record["x0"] = x0
    record["preparation_seconds"] = time() - started
    record["initial_nllh"] = prob.nllh(x0)
    record["status"] = "prepared"
    write_result(record)
    println("PREPARED ", name, " ", method, " objective=", record["initial_nllh"])
    flush(stdout)
    remaining = config["seconds_per_method"] - (time() - started)
    remaining > 0 || error("Preparation exhausted the run budget")
    function refine(p, x, seconds)
        # Fides requires the same concrete vector type for x0 and its bounds.
        # PEtab's bounds carry parameter names; populate a fresh matching vector.
        named_start = similar(p.lower_bounds)
        named_start .= x
        return calibrate(p, named_start, Fides.BFGS();
            options=Fides.FidesOptions(; maxtime=Float64(seconds), maxiter=10000, verbose="warning"))
    end
    if startswith(method, "odepe")
        options = EstimationOptions(interpolators=[InterpolatorAGPRobust, InterpolatorAGPRobustRQ],
            shooting_points=6, multipoint_max_pairs=6, nooutput=true, diagnostics=false,
            save_system=false, compute_uncertainty=false)
        checkpoint = partial -> begin
            record["result"] = partial
            record["status"] = hasproperty(partial, :construction_progress) ? "prepared" : "algebraic_complete"
            write_result(record)
            hasproperty(partial, :construction_progress) && println("BLOCK_PROGRESS ", partial.construction_progress)
            flush(stdout)
        end
        block_options = (;)
        if startswith(method, "odepe_blocks")
            group_size = parse(Int, replace(method, "odepe_blocks"=>""))
            conditions = collect(keys(adapter.condition_states))
            group_size <= length(conditions) || error("Model has fewer than $group_size experiments")
            group = conditions[1:group_size]
            record["experiment_construction"] = (; groups=[group], max_derivative_order,
                selection="first conditions in canonical measurement-row order",
                rank_selector="multipoint noise frontier; up to 8 bases; no mixed-volume ranking",
                initial_only_projection="available group states only; other entries retain recorded x0",
                refinement="all conditions and all estimated parameters in original PEtab objective")
            block_options = (; experiment_groups=[group], max_derivative_order)
            write_result(record)
        end
        result = estimate_petab_problem(adapter; options=options, x0=x0,
            polish=refine, checkpoint=checkpoint, max_seconds=remaining, block_options...)
        record["result"] = result
        record["status"] = string(result.status)
    else
        result = refine(prob, x0, remaining)
        converged = string(result.converged) in ("FTOL", "XTOL", "GTOL")
        record["result"] = (; x=collect(result.xmin), nllh=result.fmin,
            status=string(result.converged), converged, iterations=result.niterations)
        record["status"] = isfinite(result.fmin) ? (converged ? "success" : "optimizer_stopped") : "optimization_failed"
    end
catch err
    record["status"] = "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
end
record["total_seconds"] = time() - started
write_result(record)
println("FINISHED ", name, " ", method, " ", record["status"])
flush(stdout)
