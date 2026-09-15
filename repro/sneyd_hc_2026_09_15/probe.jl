# Compare HC setup and monodromy on the exact family captured by dense_single.
# This is a solver diagnostic, not an estimator or a root-completeness claim.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using HomotopyContinuation, JSON, SHA, Random, Profile, LinearAlgebra
const HC = HomotopyContinuation
length(ARGS) in (4,5) || error("Expected SYSTEM_JSON OUTPUT_DIRECTORY polyhedral|monodromy SECONDS [KNOWN_START_JSON]")
input_path, out, mode, seconds_arg = ARGS[1:4]
mode in ("polyhedral", "monodromy") || error("Unsupported mode")
seconds = parse(Float64, seconds_arg)
Base.exit_on_sigint(false)
Random.seed!(20260915)
input = JSON.parsefile(input_path)
record = Dict{String,Any}("status"=>"reconstructing", "mode"=>mode, "seed"=>20260915,
    "input_sha256"=>bytes2hex(sha256(read(input_path))),
    "worker_sha256"=>bytes2hex(sha256(read(@__FILE__))), "julia_version"=>string(VERSION),
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "hc_version"=>string(pkgversion(HC)), "profile_ready"=>true,
    "compile"=>"all", "julia_threads"=>Threads.nthreads(),
    "coordinate_normalization"=>get(input,"normalization",nothing),
    "completeness"=>"not established", "scope"=>"Captured generic family, no interpolation or observation fitting")
function checkpoint()
    open(joinpath(out, "result.json.tmp"), "w") do io
        JSON.print(io, record, 2)
    end
    mv(joinpath(out, "result.json.tmp"), joinpath(out, "result.json"); force=true)
end
function stage!(name)
    record["status"] = name
    record["stage_started_ns"] = time_ns()
    checkpoint()
    println("STAGE ", name); flush(stdout)
end
finite_number(x) = isfinite(x) ? x : string(x)
Profile.init(; n=10^7, delay=0.002)
Profile.set_peek_duration(10.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out, "profile_$(time_ns()).txt");
    format=:flat, C=true, sortedby=:count)
checkpoint()
retained_roots = Vector{ComplexF64}[]
try
    variables = [HC.ModelKit.Variable(Symbol(n)) for n in input["unknowns"]]
    parameters = [HC.ModelKit.Variable(Symbol(n)) for n in input["data_variables"]]
    symbols = vcat(variables, parameters)
    equations = HC.ModelKit.Expression[]
    for terms in input["polynomials"]
        equation = zero(first(variables))
        for term in terms
            coefficient = parse(BigInt, term["numerator"]) // parse(BigInt, term["denominator"])
            exponents = Int.(term["exponents"])
            equation += coefficient * prod(symbols[i]^exponents[i] for i in eachindex(symbols) if exponents[i] != 0; init=1)
        end
        push!(equations, equation)
    end
    system = HC.System(equations; variables, parameters)
    # Verify every ordered coefficient and exponent, not just a floating probe.
    for (equation, terms) in zip(equations, input["polynomials"])
        actual = HC.ModelKit.to_dict(HC.expand(equation), symbols)
        expected = Dict(Int.(t["exponents"]) => parse(BigInt,t["numerator"]) // parse(BigInt,t["denominator"]) for t in terms)
        @assert keys(actual) == keys(expected)
        @assert all(Rational{BigInt}(HC.ModelKit.to_number(actual[e])) == c for (e,c) in expected)
    end
    record["exact_coefficient_roundtrip"] = true
    record["equations"] = length(equations)
    record["unknowns"] = length(variables)
    record["data_parameters"] = length(parameters)
    support, _ = HC.support_coefficients(system)
    record["terms_per_equation"] = [length(t) for t in input["polynomials"]]
    record["solve_support_per_equation"] = [size(s,2) for s in support]
    record["degrees_in_unknowns"] = [maximum(sum, eachcol(s)) for s in support]
    record["total_degree_bound"] = string(prod(big.(record["degrees_in_unknowns"])))
    p0 = ComplexF64.(input["generic_parameters_real"] .+ im .* input["generic_parameters_imag"])
    record["operation_started_ns"] = time_ns()
    if mode == "polyhedral"
        stage!("polyhedral_setup")
        setup = @timed HC.solver_startsolutions(system; target_parameters=p0,
            seed=UInt32(20260915), start_system=:polyhedral, compile=:all, show_progress=true)
        solver, starts = setup.value
        record["setup_seconds"] = setup.time
        record["setup_compile_seconds"] = setup.compile_time
        record["polyhedral_start_paths"] = length(starts)
        record["path_count_note"] = "Default affine polyhedral starts (supports augmented with the origin); not the torus-only MV score or physical multiplicity M"
        stage!("polyhedral_tracking")
        # Stream starts to avoid collecting every start vector before
        # timing tracking. Same HC solver/tracker; one Julia thread, no root cap.
        roots = retained_roots
        codes = Dict{String,Int}()
        record["paths_tracked"] = 0
        record["tracking_driver"] = "HC.ResultIterator, streaming serial traversal"
        for result in HC.solve(solver, starts; iterator_only=true)
            code = string(result.return_code)
            codes[code] = get(codes, code, 0) + 1
            record["paths_tracked"] += 1
            HC.is_success(result) && push!(roots, HC.solution(result))
            if record["paths_tracked"] % 100 == 0
                record["path_return_codes"] = codes
                record["successful_endpoints"] = length(roots)
                checkpoint()
            end
            (time_ns()-record["operation_started_ns"])/1e9 >= seconds && break
        end
        record["path_return_codes"] = codes
        record["successful_endpoints"] = length(roots)
        record["roots_real"] = real.(roots)
        record["roots_imag"] = imag.(roots)
        record["status"] = record["paths_tracked"] == length(starts) ? "complete" : "budget_exhausted"
    else
        if length(ARGS) == 5
            known = JSON.parsefile(ARGS[5])
            @assert known["system_sha256"] == record["input_sha256"]
            rational(s) = begin
                a = split(s,'/'); parse(BigInt,a[1]) // (length(a)==1 ? big(1) : parse(BigInt,a[2]))
            end
            x = ComplexF64.(rational.(known["root"]))
            p = ComplexF64.(rational.(known["parameters"]))
            record["known_start_sha256"] = bytes2hex(sha256(read(ARGS[5])))
            record["start_source"] = known["source"]
        else
            stage!("find_start_pair")
            start = @timed HC.find_start_pair(system; compile=:all, max_tries=100)
            record["find_start_pair_seconds"] = start.time
            record["find_start_pair_compile_seconds"] = start.compile_time
            isnothing(start.value) && error("HC.find_start_pair failed after 100 random Newton starts")
            x, p = start.value
            record["start_source"] = "HC random Newton in unknowns and data parameters; no generating parameter/state values supplied"
        end
        record["start_root_real"] = real.(x)
        record["start_root_imag"] = imag.(x)
        record["start_parameters_real"] = real.(p)
        record["start_parameters_imag"] = imag.(p)
        record["start_residual_inf"] = finite_number(norm(HC.evaluate(system,x,p),Inf))
        record["start_jacobian_condition"] = finite_number(cond(HC.jacobian(system,x,p)))
        record["loop_root_counts"] = Int[]
        record["monodromy_options"] = Dict("timeout"=>seconds, "max_loops_no_progress"=>10,
            "trace_test"=>false, "duplicate_check"=>"heuristic", "target_solutions_count"=>nothing)
        stage!("monodromy")
        measurement = @timed HC.monodromy_solve(system, [x], p;
            compile=:all, threading=false, seed=UInt32(20260915), timeout=seconds,
            max_loops_no_progress=10, trace_test=false, show_progress=true, catch_interrupt=true,
            loop_finished_callback=results -> begin
                push!(record["loop_root_counts"],length(results)); checkpoint()
                println("MONODROMY_LOOP roots=",length(results)); flush(stdout)
                false
            end)
        result = measurement.value
        roots = HC.solutions(result)
        record["monodromy_seconds"] = measurement.time
        record["monodromy_compile_seconds"] = measurement.compile_time
        record["return_code"] = string(result.returncode)
        record["roots_found"] = length(roots)
        record["roots_real"] = real.(roots)
        record["roots_imag"] = imag.(roots)
        record["tracked_loops"] = result.statistics.tracked_loops[]
        record["generated_loops"] = length(result.loops)
        stage!("validating")
        record["residuals_inf"] = [finite_number(norm(HC.evaluate(system,r,p),Inf)) for r in roots]
        record["certified_distinct_roots"] = isempty(roots) ? 0 :
            HC.ndistinct_certified(HC.certify(system, roots, p; show_progress=false))
        record["status"] = "complete"
    end
catch err
    record["interrupted_stage"] = record["status"]
    record["status"] = err isa InterruptException ? "interrupted" : "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    if mode == "polyhedral" && !isempty(retained_roots)
        record["roots_real"] = real.(retained_roots)
        record["roots_imag"] = imag.(retained_roots)
    end
    haskey(record,"operation_started_ns") && (record["operation_seconds"] = (time_ns()-record["operation_started_ns"])/1e9)
    checkpoint()
end
println("FINISHED ", record["status"]); flush(stdout)
record["status"] in ("complete", "budget_exhausted") || exit(1)
