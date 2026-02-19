# =============================================================================
# Export Scaled Models to JSON for the Benchmark Harness
# =============================================================================
#
# Loads all 26 scaled models and exports them in the systems.json format
# expected by ~/tmp/no-matlab-no-worry.
#
# Usage:
#   julia export_to_json.jl [output_path]
#   Default output: systems_scaled.json in current directory
# =============================================================================

include("scaled_models.jl")

import Pkg
try
    @eval using JSON
catch
    Pkg.add("JSON")
    @eval using JSON
end

# Symbolics and ModelingToolkit already loaded via ODEParameterEstimation (from scaled_models.jl)

"""
    clean_expr_string(expr_str, var_names)

Clean a Symbolics expression string for JSON export:
- Strip `(t)` from known variable names
- Remove `Integer()` wrappers
- Preserve `sin()`, `cos()`, `exp()` function calls
"""
function clean_expr_string(expr_str::String, var_names::Set{String})
    s = expr_str

    # Replace known_var(t) with known_var
    # Sort by length descending to avoid partial matches (e.g., "x1" before "x")
    sorted_names = sort(collect(var_names), by=length, rev=true)
    for name in sorted_names
        s = replace(s, "$(name)(t)" => name)
    end

    # Symbolics sometimes outputs "Integer(N)" wrapper
    s = replace(s, r"Integer\((\d+)\)" => s"\1")

    # Insert explicit * between number and variable name or parenthesis
    # Symbolics outputs "0.6k3" instead of "0.6*k3", "2.0sin" instead of "2.0*sin"
    # Also "0.5(...)" instead of "0.5*(...)"
    # Pattern: digit immediately followed by letter or opening paren
    # BUT exclude scientific notation like 3.6e-7 (digit followed by e/E and +/-/digit)
    s = replace(s, r"(\d)(?![eE][+-]?\d)([a-zA-Z_(])" => s"\1*\2")

    # Clean up rational literals: "3//1" -> "3.0", "-3//1" -> "-3.0"
    s = replace(s, r"(-?\d+)//(\d+)" => function(m)
        parts = split(m, "//")
        num = parse(Int, parts[1])
        den = parse(Int, parts[2])
        return string(Float64(num // den))
    end)

    # Clean up double spaces
    s = replace(s, r"\s+" => " ")

    return strip(s)
end

"""
    extract_model_json(name, pep)

Extract a model's data from a ParameterEstimationProblem into a Dict
matching the systems.json format.
"""
function extract_model_json(name::Symbol, pep)
    sys = pep.model.system

    # Get state and parameter names (clean, no (t))
    state_vars = ModelingToolkit.unknowns(sys)
    param_vars = ModelingToolkit.parameters(sys)

    state_names = Set{String}()
    param_names = Set{String}()

    for sv in state_vars
        clean = replace(string(Symbolics.tosymbol(sv, escape=false)), "(t)" => "")
        push!(state_names, clean)
    end

    for pv in param_vars
        clean = replace(string(pv), "(t)" => "")
        push!(param_names, clean)
    end

    all_var_names = union(state_names, param_names)

    # Extract equations via string parsing
    # ModelingToolkit equations have form: Differential(t, 1)(x(t)) ~ rhs
    eqs = ModelingToolkit.equations(sys)
    ode_system = Dict{String, String}()

    for eq in eqs
        lhs_str = string(eq.lhs)
        rhs_str = string(eq.rhs)

        # Parse LHS: "Differential(t, 1)(x(t))" or "Differential(t)(x(t))"
        m = match(r"Differential\(t(?:,\s*\d+)?\)\((\w+)\(t\)\)", lhs_str)
        if m !== nothing
            state_name = String(m.captures[1])
            clean_rhs = clean_expr_string(rhs_str, all_var_names)
            ode_system[state_name] = clean_rhs
        else
            @warn "Could not parse LHS: $lhs_str"
        end
    end

    # Extract measurements
    measurements = Dict{String, String}()
    mq_names = String[]

    for mq in pep.measured_quantities
        lhs_str = replace(string(mq.lhs), "(t)" => "")
        rhs_str = clean_expr_string(string(mq.rhs), all_var_names)
        measurements[lhs_str] = rhs_str
        push!(mq_names, lhs_str)
    end

    # Get ordered state/param names (preserving OrderedDict order from p_true/ic)
    ordered_state_names = [replace(string(Symbolics.tosymbol(k, escape=false)), "(t)" => "") for k in keys(pep.ic)]
    ordered_param_names = [replace(string(k), "(t)" => "") for k in keys(pep.p_true)]

    # Time interval
    ti = pep.recommended_time_interval
    time_interval = ti === nothing ? [0.0, 10.0] : [Float64(ti[1]), Float64(ti[2])]

    # Use the model name from the PEP (already includes _scaled suffix)
    model_name = pep.name

    return Dict(
        "name" => model_name,
        "state_variables" => ordered_state_names,
        "parameter_variables" => ordered_param_names,
        "measurement_variables" => mq_names,
        "ode_system" => ode_system,
        "measurements" => measurements,
        "time_interval" => time_interval,
        "non_identifiable" => String[],
    )
end

function main()
    output_path = length(ARGS) > 0 ? ARGS[1] : "systems_scaled.json"

    println("Exporting $(length(SCALED_MODELS)) scaled models to JSON...")

    systems = Dict{String, Any}[]

    # Process in a deterministic order
    model_keys = sort(collect(keys(SCALED_MODELS)))

    for key in model_keys
        println("  Processing: $key")
        try
            pep = SCALED_MODELS[key]()
            entry = extract_model_json(key, pep)
            push!(systems, entry)

            # Verify: all states should have equations
            missing_eqs = setdiff(Set(entry["state_variables"]), Set(keys(entry["ode_system"])))
            if !isempty(missing_eqs)
                @warn "  Missing equations for states: $missing_eqs"
            end

            println("    -> $(entry["name"]): $(length(entry["state_variables"])) states, $(length(entry["parameter_variables"])) params, $(length(entry["measurement_variables"])) obs")
        catch e
            println("    ERROR: $e")
            for (exc, bt) in Base.current_exceptions()
                showerror(stdout, exc, bt)
                println()
            end
            println("    Skipping $key")
        end
    end

    result = Dict("systems" => systems)

    open(output_path, "w") do io
        JSON.print(io, result, 2)
    end

    println("\nDone! Wrote $(length(systems)) models to $output_path")
end

main()
