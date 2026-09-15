# Research only: matched original samples with y=w^4 or z=fourth_root(y)=w.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
include("model.jl")
using Logging
length(ARGS) == 5 || error("Expected SPEC OUTPUT free|rational quartic|root PHASE")
spec_path, outarg, model_kind, observation_kind, phase = ARGS
out = abspath(outarg)
spec = JSON.parsefile(spec_path)
isfile(joinpath(out,"result.json")) && error("Use a fresh output directory")
mkpath(out)
Base.exit_on_sigint(false)
const STUDY_SEED = 20260915
Random.seed!(STUDY_SEED)
started_ns = time_ns()
record = Dict{String,Any}("status"=>"preparing", "model_kind"=>model_kind,
    "observation_kind"=>observation_kind, "phase"=>phase, "pid"=>getpid(),
    "julia_version"=>string(VERSION), "seed"=>STUDY_SEED,
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()),"Manifest.toml")))),
    "spec_sha256"=>bytes2hex(sha256(read(spec_path))),
    "source_sha256"=>Dict(f=>bytes2hex(sha256(read(joinpath(@__DIR__,f))))
        for f in readdir(@__DIR__) if endswith(f,".jl")))
record["versions"] = Dict(d.name=>string(d.version) for d in values(Pkg.dependencies())
    if d.name in ("ODEParameterEstimation", "Symbolics", "SymbolicUtils", "ModelingToolkit",
        "HomotopyContinuation", "SIAN", "StructuralIdentifiability", "GaussianProcesses", "Groebner", "Nemo", "PEtab"))
checkpoint() = (record["elapsed_seconds"]=(time_ns()-started_ns)/1e9;
    write_json(joinpath(out,"result.json"),record))
checkpoint()
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> begin
    path = joinpath(out,"profile_$(time_ns()).txt")
    Profile.print(path; format=:flat, C=true, sortedby=:count)
    println("PROFILE_SAVED ",path); flush(stdout)
end
record["profile_ready"] = true
checkpoint()
include("capture_and_solve.jl")
include("probes.jl")
context = ODEPE.RunContext(; capture_timing=true)
try
    study = study_problem(spec,model_kind,observation_kind)
    pep = study.pep
    record["model_definition"] = (; states=string.(pep.model.original_states),
        parameters=string.(pep.model.original_parameters),
        equations=string.(MTK.equations(pep.model.system)),
        observations=string.(pep.measured_quantities),
        linear_observation=string(study.linear),
        generating_parameters=pep.p_true, generating_initial_states=pep.ic,
        time_interval=pep.recommended_time_interval,
        bounds_order=vcat(string.(pep.model.original_states),string.(pep.model.original_parameters)),
        lower_bounds=study.lower, upper_bounds=study.upper,
        truth_use="Generator and post-fit diagnostics only; all retained ICs and rates remain unknown")
    record["transformation"] = (; fourth_power_roundtrip_max_error=study.fourth_power_roundtrip_max_error,
        applied_before_interpolation=true, original_data=spec["original_data"],
        branch="Nonnegative real root; generating positive compartment model",
        other_inference_changes="None within each model/phase pair")
    expression = Num(only(pep.measured_quantities).rhs)
    write_json(joinpath(out,"data.json"), (; times=study.times,
        signals=[(; expression=string(expression),values=pep.data_sample[expression])]))
    record["status"] = "validating_model"
    checkpoint()
    simulated = ODEPE.sample_data(pep.model.system, [only(pep.measured_quantities).lhs ~ study.linear],
        pep.recommended_time_interval, pep.p_true, pep.ic, length(study.times);
        solver=pep.solver, abstol=1e-12, reltol=1e-12)
    @assert simulated["t"] == study.times
    values = simulated[Num(study.linear)]
    record["generating_validation"] = (;
        original_y_max_relative_error=maximum(abs.(values.^4 .- study.raw))/maximum(study.raw),
        root_z_max_abs_error=maximum(abs.(values .- study.rooted)),
        generated_linear_min=minimum(values))
    record["generating_validation"].original_y_max_relative_error < 1e-7 || error("Model does not reproduce retained data")
    # Record ordinary production rescaling; observation transformation may change
    # its choices. Do not freeze those choices silently or count extra data.
    _, scale = ODEPE.rescale_pep(pep)
    record["scale_info"] = isnothing(scale) ? nothing :
        Dict(string(k)=>getfield(scale,k) for k in fieldnames(typeof(scale)))
    opts = EstimationOptions(; datasize=length(study.times), time_interval=pep.recommended_time_interval,
        compute_algebraic_multiplicity=false,
        construction_compute_mixed_volume=(phase=="selection"),
        noise_level=0.0, shooting_points=20, shooting_warp=true, shooting_warp_beta=3.0,
        use_multipoint=(model_kind=="rational"), multipoint_n_points=2, multipoint_max_pairs=15,
        polish_solver_solutions=true, polish_solutions=true,
        polish_maxiters=5000, polish_method=PolishLSOBoundedLog, opt_maxiters=200000,
        opt_lb=study.lower, opt_ub=study.upper, abstol=1e-12, reltol=1e-12,
        polish_maxtime=120.0, polish_divergence_factor=10.0,
        polish_stagnation_window=50, polish_ode_maxiters=20000,
        terminal_fallback=:none, compute_uncertainty=false,
        dump_raw_candidates_path=joinpath(out,"raw_candidates.csv"),
        dump_polished_path=joinpath(out,"polished_candidates.csv"),
        profile_phases=true, heartbeat=true, diagnostics=true, nooutput=false,
        hc_show_progress=true, save_system=true)
    record["options"] = Dict(string(k)=>getfield(opts,k) for k in fieldnames(EstimationOptions))
    effective = ODEPE.maybe_filter_interpolators_by_noise(ODEPE.resolve_interpolator_list(opts),pep,opts)
    record["effective_interpolators"] = [string(first(entry)) for entry in effective]
    record["multiplicity_policy"] = "Unknown during estimation. Historical quartic M=544 is not transferred to rooted data. Separate probe counts its own representative-fixed model."
    record["preparation_seconds"] = (time_ns()-started_ns)/1e9
    record["estimation_started_ns"] = time_ns()
    record["status"] = "estimating"
    checkpoint()
    println("ESTIMATION_START ",record["estimation_started_ns"]); flush(stdout)
    if phase in ("estimate","selection")
        answer = cd(out) do
            Base.ScopedValues.with(ODEPE.RUN_CONTEXT=>context) do
                analyze_parameter_estimation_problem(pep,opts)
            end
        end
        raw, analysis, _ = answer
        ranked = first(analysis)
        function result_record(r)
            scores = try
                score_candidate(study,r)
            catch err
                (; scoring_error=sprint(showerror,err,catch_backtrace()))
            end
            return (; fit_error_on_active_observation=r.err, parameters=r.parameters, states=r.states,
                source_anchor_time=r.at_time, report_time=r.report_time,
                all_unidentifiable=string.(collect(r.all_unidentifiable)),
                provenance=Dict(string(k)=>getfield(r.provenance,k) for k in fieldnames(typeof(r.provenance))),
                common_scale_scores=scores)
        end
        record["ranked_results"] = result_record.(ranked)
        record["raw_count"] = length(first(raw))
        record["status"] = isempty(ranked) ? "no_candidates" : "complete"
    else
        run_probe(pep,phase)
        record["status"] = "complete"
    end
catch err
    stopped = err isa InterruptException && get(record,"generic_start_empty",false)
    captured = err isa InterruptException && get(record,"selection_capture_complete",false)
    record["status"] = captured ? "selection_complete" : stopped ? "generic_start_failed" : err isa InterruptException ? "interrupted" : "failed"
    (stopped || captured) || (record["error"]=sprint(showerror,err,catch_backtrace()))
finally
    haskey(record,"estimation_started_ns") &&
        (record["estimation_seconds"]=(time_ns()-record["estimation_started_ns"])/1e9)
    !isnothing(context.timing) && (record["timing"]=ODEPE.timing_breakdown_to_dict(context.timing))
    write_json(joinpath(out,"detailed_timing.json"),context.detailed_timing_sink)
    write_json(joinpath(out,"resolve_timing.json"),context.resolve_timing_sink)
    checkpoint()
end
println("FINISHED ",model_kind," ",observation_kind," ",phase," ",record["status"]); flush(stdout)
record["status"] in ("failed","interrupted","generic_start_failed") && exit(1)
