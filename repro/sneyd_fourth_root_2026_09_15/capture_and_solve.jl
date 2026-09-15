# Research-only instrumentation in an isolated worker. Save the actual HC family
# and then invoke the unmodified production generic-start solver.
import ODEParameterEstimation: compute_generic_start_solutions

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
    result = invoke(ODEPE.compute_generic_start_solutions, Tuple{Any,Any,Any},
        poly_system, solve_vars, data_vars; gamma_seed, show_progress, debug)
    record["generic_start_seconds"] = (time_ns()-started)/1e9
    record["generic_start_count"] = isnothing(first(result)) ? 0 : length(first(result))
    record["generic_start_empty"] = isnothing(first(result)) || isempty(first(result))
    checkpoint()
    record["generic_start_empty"] && throw(InterruptException())
    record["status"] = "estimating"
    checkpoint()
    return result
end
