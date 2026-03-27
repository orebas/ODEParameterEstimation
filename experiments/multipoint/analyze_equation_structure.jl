# Analyze the structure: which equations are CHOICES and which variables are REQUESTS
#
# For each equation in the SIAN template:
#   - Is it a "derivative-of-F" equation (ODE structure)?
#   - Or is it a "pinning" equation (data request)?
#   - What variables does it introduce?
#   - Which of those are observed (generate interpolation requests)?
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; include("experiments/multipoint/analyze_equation_structure.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf

function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function analyze_model(name, pep; t_interval=nothing, n_data=51)
    println("\n", "=" ^ 80)
    println("MODEL: $name")
    println("=" ^ 80)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, noise_level=0.0, nooutput=true))
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_data; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    model = pep_data.model.system; mq = pep_data.measured_quantities
    t_vec = pep_data.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_data.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    # Build at one point to analyze structure
    t_mid = round(Int, n_t * 0.5)
    eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_data.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_mid], precomputed_interpolants=setup.interpolants)

    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_data)

    println("Params: $(length(real_params))  States: $(count(r -> r != :parameter, values(roles)))  Obs: $(length(mq))")
    println("Template: $(length(eqs)) equations, $(length(vars)) variables")
    println()

    # Classify each equation
    println("EQUATION STRUCTURE:")
    println("  (STRUCT = derivative-of-F equation, DATA = pinning/interpolation request)")
    println()

    struct_eqs = Int[]   # indices of structural equations
    data_eqs = Int[]     # indices of data/pinning equations

    for (i, eq) in enumerate(eqs)
        eq_vars = Symbolics.get_variables(eq)
        nv = length(eq_vars)
        is_data = nv == 1  # data equations have exactly 1 variable: "constant - var = 0"

        if is_data
            push!(data_eqs, i)
            var_name = string(first(eq_vars))
            ord = get_deriv_order(var_name)
            println("  Eq $i: DATA   pin $(rpad(var_name, 8)) (order $ord interpolation REQUEST)")
        else
            push!(struct_eqs, i)
            max_ord = maximum(get_deriv_order(v) for v in eq_vars)
            # What new variables does this equation introduce?
            # (variables that don't appear in earlier structural equations)
            println("  Eq $i: STRUCT (max_ord=$max_ord, $nv vars)")
        end
    end

    println()
    println("Summary: $(length(struct_eqs)) structural + $(length(data_eqs)) data = $(length(eqs)) total")
    println("Structural eqs are the CHOICES. Data eqs are the CONSEQUENCES (requests).")

    # At 1 point: n_struct + n_data = n_vars (square)
    # At 2 points: 2*n_struct + 2*n_data equations, n_params + 2*n_state_vars variables
    # Overdetermined by n_params
    n_params = count(r -> r == :parameter, values(roles))
    n_state = length(vars) - n_params

    println()
    println("1 point: $(length(eqs)) eqs = $(length(vars)) vars (square)")
    println("2 points: $(2*length(eqs)) eqs, $(n_params + 2*n_state) vars → overdetermined by $n_params")
    println()
    println("To get back to square, we need to REMOVE $n_params structural equations.")
    println("Each removed structural equation also removes its data consequences.")
    println()

    # Which structural equations to remove?
    # The ones that generate the HIGHEST-ORDER interpolation requests.
    println("Structural equations by max derivative order:")
    for eq_idx in struct_eqs
        eq_vars = Symbolics.get_variables(eqs[eq_idx])
        max_ord = maximum(get_deriv_order(v) for v in eq_vars)
        observed_vars = [string(v) for v in eq_vars if get_deriv_order(v) > 0]
        println("  Eq $eq_idx: max_ord=$max_ord  vars=$(join(observed_vars, ", "))")
    end

    println()
    println("Data equations (interpolation requests) by order:")
    for eq_idx in data_eqs
        var = first(Symbolics.get_variables(eqs[eq_idx]))
        println("  Eq $eq_idx: order=$(get_deriv_order(var))  $(string(var))")
    end
end

analyze_model("lotka_volterra", ODEParameterEstimation.lotka_volterra())
analyze_model("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(); t_interval=[0.0, 10.0])
analyze_model("simple", ODEParameterEstimation.simple(); t_interval=[0.0, 1.0])
