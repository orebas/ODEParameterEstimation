# Research-only interception: loaded explicitly by run.jl in a fresh process.
# A more-specific method stops at the first actual generic-start solve, after
# ordinary SI construction and subsystem selection. No production source edits.
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
    capture = (; scope="Exact first selected generic-start HC family; no solve or data fit performed",
        captured_unix=time(), capture_seconds_since_estimation=(time_ns()-record["estimation_started_ns"])/1e9,
        unknowns=string.(variables), data_variables=string.(parameters),
        original_unknowns=string.(solve_vars), original_data_variables=string.(data_vars),
        equations=string.(hc.expressions(system)), polynomials=terms,
        generic_parameters_real=real.(p0), generic_parameters_imag=imag.(p0), gamma_seed,
        capture_source_sha256=bytes2hex(sha256(read(@__FILE__))))
    write_json(joinpath(out, "generic_system.json"), capture)
    println("CAPTURED_GENERIC_SYSTEM equations=$(length(terms)) unknowns=$(length(variables)) data_parameters=$(length(parameters))")
    flush(stdout)
    # The normal pipeline propagates interrupts through nested solver catches.
    # run.jl recognizes a completed capture and records this as an intentional stop.
    throw(InterruptException())
end
