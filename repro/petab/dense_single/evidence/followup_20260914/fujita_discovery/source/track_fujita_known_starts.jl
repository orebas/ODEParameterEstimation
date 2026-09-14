# Isolate path tracking with independently generated exact start/target roots.
# This supplies ONE starting root; it is not a complete solver or a data fit.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, Random, Profile, LinearAlgebra
const HC = HomotopyContinuation
length(ARGS) in (2, 3) || error("Expected START_PAIR_JSON OUTPUT_DIRECTORY [monodromy]")
discovery = length(ARGS) == 3
discovery && ARGS[3] != "monodromy" && error("Unsupported discovery mode")
Base.exit_on_sigint(false)
input = JSON.parsefile(ARGS[1])
out = ARGS[2]
record = Dict{String,Any}(
    "status" => "converting", "input_sha256" => bytes2hex(sha256(read(ARGS[1]))),
    "harness_sha256" => bytes2hex(sha256(read(@__FILE__))),
    "julia_version" => string(VERSION), "pid" => getpid(), "profile_ready" => true,
    "scope" => "Known-root tracking diagnostic, one supplied starting root, no root enumeration or observation fitting.",
    "column_scaling" => false, "seed" => 20260914, "trials" => Any[])
function checkpoint()
    open(joinpath(out, "result.json.tmp"), "w") do io
        JSON.print(io, record)
    end
    mv(joinpath(out, "result.json.tmp"), joinpath(out, "result.json"); force=true)
end
finite_number(x) = isfinite(x) ? x : nothing
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out, "profile.txt"); format=:flat, C=true, sortedby=:count)
checkpoint()
try
    for name in vcat(input["unknowns"], input["all_data_variables"])
        Core.eval(Main, Expr(:(=), Symbol(name), QuoteNode(HC.ModelKit.Variable(Symbol(name)))))
    end
    variables = [getfield(Main, Symbol(n)) for n in input["unknowns"]]
    data = [getfield(Main, Symbol(n)) for n in input["data_variables"]]
    all_data = [getfield(Main, Symbol(n)) for n in input["all_data_variables"]]
    equations = [Core.eval(Main, Meta.parse(replace(s, "**"=>"^"))) for s in input["equations"]]
    all_equations = [Core.eval(Main, Meta.parse(replace(s, "**"=>"^"))) for s in input["all_equations"]]
    system = HC.System(equations; variables, parameters=data)
    full_system = HC.System(all_equations; variables, parameters=all_data)
    start = input["cases"][1]
    x0 = ComplexF64.(start["root"])
    p0 = ComplexF64.(start["data"])
    record["start_residual_inf"] = norm(HC.evaluate(system, x0, p0), Inf)
    record["start_jacobian_condition"] = finite_number(cond(HC.jacobian(system, x0, p0)))
    record["status"] = "tracking"
    record["estimation_started_unix"] = time() # existing supervisor's stage clock
    checkpoint()
    rng = MersenneTwister(20260914)
    starts = [x0]
    if discovery
        record["scope"] = "Bounded monodromy root-discovery diagnostic from one supplied root, followed by independent synthetic targets. No observation fitting or completeness certificate."
        record["status"] = "monodromy"
        record["monodromy_options"] = Dict("timeout"=>120.0, "max_loops_no_progress"=>3,
            "trace_test"=>false, "duplicate_check"=>"heuristic")
        checkpoint()
        measurement = @timed HC.monodromy_solve(system, starts, p0;
            seed=UInt32(20260914), timeout=120.0, max_loops_no_progress=3,
            trace_test=false, show_progress=false, catch_interrupt=false,
            loop_finished_callback=results -> begin
                record["discovery_roots_after_last_loop"] = length(results)
                checkpoint()
                false
            end)
        result = measurement.value
        starts = HC.solutions(result)
        record["monodromy"] = Dict("return_code"=>string(result.returncode),
            "seconds"=>measurement.time, "compile_seconds"=>measurement.compile_time,
            "roots"=>length(starts), "generated_loops"=>length(result.loops),
            "tracked_loops"=>result.statistics.tracked_loops[],
            "start_roots_real"=>real.(starts), "start_roots_imag"=>imag.(starts))
        record["status"] = "tracking"
        checkpoint()
        println("MONODROMY_END roots=$(length(starts)) return_code=$(result.returncode)"); flush(stdout)
    end
    modes = discovery ? (:gamma_straight,) : (:parameter, :gamma_straight)
    for mode in modes, target in input["cases"][2:end]
        p1 = ComplexF64.(target["data"])
        gamma = cis(2π * rand(rng))
        trial = Dict{String,Any}("mode"=>string(mode), "target"=>target["name"], "status"=>"tracking")
        mode == :gamma_straight && (trial["gamma"] = [real(gamma), imag(gamma)])
        push!(record["trials"], trial)
        checkpoint()
        println("TRACK_START mode=$mode target=$(target["name"])"); flush(stdout)
        measurement = @timed if mode == :parameter
            HC.solve(system, starts; start_parameters=p0, target_parameters=p1, show_progress=false)
        else
            # Same fixed-system gamma homotopy as ODEPE._track_gamma_straight,
            # here with one seed and no fresh-solve fallback.
            HC.solve(system, system, starts; start_parameters=p0, target_parameters=p1,
                     gamma, show_progress=false)
        end
        trial["seconds"] = measurement.time
        trial["compile_seconds"] = measurement.compile_time
        trial["paths"] = [Dict(
            "return_code"=>string(r.return_code), "accepted_steps"=>r.accepted_steps,
            "rejected_steps"=>r.rejected_steps, "residual"=>finite_number(r.residual),
            "accuracy"=>finite_number(r.accuracy), "condition_jacobian"=>finite_number(r.condition_jacobian))
            for r in measurement.value.path_results]
        candidates = Any[]
        for root in HC.solutions(measurement.value; only_nonsingular=false)
            physical = Int.(input["physical_indices"])
            known = Float64.(target["root"])
            push!(candidates, Dict(
                "selected_85_residual_inf"=>finite_number(norm(HC.evaluate(system, root, p1), Inf)),
                "all_88_residual_inf"=>finite_number(norm(HC.evaluate(full_system, root, Float64.(target["all_data"])), Inf)),
                "max_physical_relative_error"=>finite_number(maximum(abs.(root[physical] .- known[physical]) ./ abs.(known[physical]))),
                "max_root_scaled_error"=>finite_number(maximum(abs.(root .- known) ./ max.(1.0, abs.(known)))),
                "max_imaginary_part"=>finite_number(maximum(abs.(imag.(root)))),
                "root_real"=>real.(root), "root_imag"=>imag.(root)))
        end
        trial["candidates"] = candidates
        trial["status"] = "complete"
        checkpoint()
        println("TRACK_END mode=$mode target=$(target["name"]) finite=$(length(candidates)) seconds=$(measurement.time)"); flush(stdout)
    end
    record["status"] = "complete"
catch err
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    haskey(record, "estimation_started_unix") && (record["tracking_elapsed_seconds"] = time()-record["estimation_started_unix"])
    checkpoint()
end
println("FINISHED ", record["status"]); flush(stdout)
record["status"] == "complete" || exit(1)
