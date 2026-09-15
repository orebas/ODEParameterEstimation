# Research-only instrumentation in an isolated worker. Save the actual HC family
# and then invoke the unmodified production generic-start solver.
import ODEParameterEstimation: compute_generic_start_solutions

function family_fingerprint(capture)
    packet = json_safe(capture)
    # Ordered arrays avoid dependence on dictionary serialization order.
    payload = [packet["unknowns"], packet["data_variables"],
        packet["original_unknowns"], packet["original_data_variables"],
        [[[term["numerator"], term["denominator"], term["exponents"]]
            for term in equation] for equation in packet["polynomials"]],
        packet["generic_parameters_real"], packet["generic_parameters_imag"]]
    return bytes2hex(sha256(JSON.json(payload)))
end

function compute_generic_start_solutions(poly_system::AbstractVector, solve_vars, data_vars;
        gamma_seed=0, show_progress=false, debug=false)
    hc = ODEPE.HomotopyContinuation
    system, variables, parameters = ODEPE.convert_to_hc_format_with_params(poly_system, solve_vars, data_vars)
    all_variables = vcat(variables, parameters)
    terms = map(hc.expressions(system)) do equation
        coefficients = hc.ModelKit.to_dict(hc.expand(equation), all_variables)
        [begin
            value = Rational{BigInt}(hc.ModelKit.to_number(coefficients[exponents]))
            (; numerator=string(numerator(value)), denominator=string(denominator(value)), exponents)
        end for exponents in sort!(collect(keys(coefficients)); by=Tuple)]
    end
    p0_rng = gamma_seed < 0 ? ODEPE.MersenneTwister() :
        ODEPE.MersenneTwister(gamma_seed == 0 ? hash(string.(solve_vars)) : UInt64(gamma_seed))
    p0 = randn(p0_rng, ComplexF64, length(parameters))
    capture = (; scope="Exact selected HC family; production generic-start solver runs after capture",
        captured_unix=time(), capture_seconds_since_estimation=(time_ns()-record["estimation_started_ns"])/1e9,
        unknowns=string.(variables), data_variables=string.(parameters),
        original_unknowns=string.(solve_vars), original_data_variables=string.(data_vars),
        equations=string.(hc.expressions(system)), polynomials=terms,
        generic_parameters_real=real.(p0), generic_parameters_imag=imag.(p0), gamma_seed)
    index = length(get!(record, "hc_systems", Any[])) + 1
    write_json(joinpath(out, "generic_system_$index.json"), capture)
    fingerprint = family_fingerprint(capture)
    baseline_path = joinpath(out, "baseline_family.json")
    if isfile(baseline_path)
        baseline_fingerprint = family_fingerprint(JSON.parsefile(baseline_path))
        fingerprint == baseline_fingerprint || error("Selected HC family differs from the retained rooted free-rate baseline")
        record["matches_baseline_family_and_p0"] = true
    end
    record["family_fingerprint"] = fingerprint
    push!(record["hc_systems"], (; equations=length(terms), unknowns=length(variables),
        data_parameters=length(parameters), monomials=sum(length, terms),
        max_degree=maximum(sum(term.exponents[1:length(variables)]) for row in terms for term in row),
        captured_seconds=capture.capture_seconds_since_estimation))
    record["status"] = "generic_start_solving"
    checkpoint()
    println("CAPTURED_GENERIC_SYSTEM equations=$(length(terms)) unknowns=$(length(variables)) data_parameters=$(length(parameters))")
    flush(stdout)
    if phase == "selection"
        record["selection_capture_complete"] = true
        checkpoint()
        throw(InterruptException())
    end
    started = time_ns()
    cache_path = get(ENV, "ODEPE_SNEYD_START_CACHE", "")
    from_cache = !isempty(cache_path) && isfile(cache_path)
    result = if from_cache
        cache = JSON.parsefile(cache_path)
        cache["family_fingerprint"] == fingerprint || error("Generic root cache belongs to a different polynomial family or p0")
        cache["manifest_sha256"] == record["manifest_sha256"] || error("Generic root cache has a different environment")
        cache["julia_version"] == record["julia_version"] || error("Generic root cache has a different Julia version")
        roots = [ComplexF64.(real_part, imag_part) for (real_part, imag_part) in
            zip(cache["solutions_real"], cache["solutions_imag"])]
        length(roots) == cache["count"] || error("Truncated generic root cache")
        all(root -> length(root) == length(variables) && all(isfinite, root), roots) ||
            error("Invalid root dimensions or nonfinite cache values")
        isempty(roots) && error("Empty generic root cache")
        record["cached_generic_solve_seconds"] = cache["solve_seconds"]
        write_json(joinpath(out, "generic_start_solutions.json"), cache)
        println("REUSED_GENERIC_START_CACHE count=$(length(roots))"); flush(stdout)
        (roots, p0)
    else
        fresh = invoke(ODEPE.compute_generic_start_solutions, Tuple{Any,Any,Any},
            poly_system, solve_vars, data_vars; gamma_seed, show_progress, debug)
        if !isnothing(first(fresh)) && !isempty(first(fresh))
            roots, actual_p0 = fresh
            actual_p0 == p0 || error("Captured and actual generic parameters differ")
            cache = (; scope="Unscaled generic roots returned by ordinary HC solve; completeness is not certified",
                family_fingerprint=fingerprint, manifest_sha256=record["manifest_sha256"],
                julia_version=record["julia_version"], versions=record["versions"],
                source_output=out, count=length(roots), solve_seconds=(time_ns()-started)/1e9,
                parameters_real=real.(p0), parameters_imag=imag.(p0),
                solutions_real=[real.(root) for root in roots],
                solutions_imag=[imag.(root) for root in roots])
            write_json(joinpath(out, "generic_start_solutions.json"), cache)
            if !isempty(cache_path)
                mkpath(dirname(cache_path))
                write_json(cache_path, cache)
            end
        end
        fresh
    end
    record["generic_start_seconds"] = (time_ns()-started)/1e9
    record["generic_start_from_cache"] = from_cache
    record["generic_start_count"] = isnothing(first(result)) ? 0 : length(first(result))
    record["generic_start_empty"] = isnothing(first(result)) || isempty(first(result))
    checkpoint()
    record["generic_start_empty"] && throw(InterruptException())
    record["status"] = "estimating"
    checkpoint()
    return result
end
