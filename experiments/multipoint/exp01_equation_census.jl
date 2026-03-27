# Experiment 1: Equation Census — classify each template equation by type and derivative order
#
# For each model, examine the ACTUAL SIAN template equations and determine:
#   1. Which variables appear, with their derivative orders
#   2. Which equations are "data equations" (var = constant) vs "structural" (ODE relations)
#   3. The maximum derivative order that appears in each equation
#   4. Which equations could be dropped for a 2-point square system
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp01_equation_census.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using Printf

models = OrderedDict{String, Any}(
    "simple" => (ODEParameterEstimation.simple, [0.0, 1.0]),
    "lotka_volterra" => (ODEParameterEstimation.lotka_volterra, nothing),
    "forced_lv_sinusoidal" => (ODEParameterEstimation.forced_lv_sinusoidal, nothing),
    "seir" => (ODEParameterEstimation.seir, nothing),
    "hiv" => (ODEParameterEstimation.hiv, nothing),
)

println("=" ^ 110)
println("EXPERIMENT 1: Template Equation Census")
println("=" ^ 110)

for (name, (ctor, oti)) in models
    println("\n", "━" ^ 100)
    println("MODEL: $name")
    println("━" ^ 100)

    pep = try; ctor(); catch e; println("  SKIP: $e"); continue; end
    ti = !isnothing(oti) ? oti : !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=21, time_interval=ti, nooutput=true))
    catch e; println("  SKIP: $e"); continue; end

    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    model = pep_work.model.system
    mq = pep_work.measured_quantities
    states = ModelingToolkit.unknowns(model)
    params = ModelingToolkit.parameters(model)

    # Build the template and instantiate at one point
    setup = try
        ODEParameterEstimation.setup_parameter_estimation(
            pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); continue; end

    t_vec = pep_work.data_sample["t"]
    idx = setup.time_index_set[1]
    t_eval = t_vec[idx]

    prod_eqs, prod_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict,
        setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[idx],
        precomputed_interpolants=setup.interpolants)

    n_eqs = length(prod_eqs)
    n_vars = length(prod_vars)

    # Classify each variable
    var_info = OrderedDict{Any, NamedTuple}()
    for v in prod_vars
        vname = string(v)
        parsed = ODEParameterEstimation.parse_derivative_variable_name(vname)
        role = ODEParameterEstimation._classify_polynomial_variables([vname], pep_work)[vname]
        if !isnothing(parsed)
            base, order = parsed
            var_info[v] = (name=vname, base=String(base), order=order, role=role)
        else
            var_info[v] = (name=vname, base=vname, order=0, role=role)
        end
    end

    n_params = count(vi -> vi.role == :parameter, values(var_info))
    n_state = n_vars - n_params

    println("  System: $(n_eqs) equations, $(n_vars) variables ($(n_params) params, $(n_state) state/deriv)")
    println("  Eval point: t = $t_eval")

    # Print variable census
    println("\n  Variables by derivative order:")
    max_order = maximum(vi.order for vi in values(var_info))
    for ord in 0:max_order
        vars_at_order = [(vi.name, vi.role) for vi in values(var_info) if vi.order == ord]
        if !isempty(vars_at_order)
            param_vars = [v[1] for v in vars_at_order if v[2] == :parameter]
            state_vars = [v[1] for v in vars_at_order if v[2] != :parameter]
            parts = String[]
            !isempty(param_vars) && push!(parts, "params: " * join(param_vars, ", "))
            !isempty(state_vars) && push!(parts, "state: " * join(state_vars, ", "))
            println("    order $ord: ", join(parts, " | "))
        end
    end

    # Classify each equation
    # Build oracle values for residual computation
    max_d = maximum(values(setup.good_deriv_level))
    state_taylor = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_eval, max_d + 2)
    obs_taylor = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, state_taylor, t_eval, max_d + 2)
    true_vals = ODEParameterEstimation._build_true_value_vector(pep_work, prod_vars;
        state_taylor=state_taylor, obs_taylor=obs_taylor, t_eval=t_eval)

    # Also build perfect system for comparison
    perfect_interps = Dict{Num, ODEParameterEstimation.PerfectInterpolant}()
    for (key, tc) in obs_taylor
        perfect_interps[key] = ODEParameterEstimation.PerfectInterpolant(t_eval, tc)
    end
    perf_eqs, perf_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict,
        setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[idx],
        precomputed_interpolants=perfect_interps)

    # Compute residuals at true values for both systems
    f_prod = ODEParameterEstimation._compile_system_function(prod_eqs, prod_vars)
    f_perf = ODEParameterEstimation._compile_system_function(perf_eqs, perf_vars)
    r_prod = any(isnan, true_vals) ? fill(NaN, n_eqs) : f_prod(true_vals)
    r_perf = any(isnan, true_vals) ? fill(NaN, n_eqs) : f_perf(true_vals)

    println("\n  Equation census:")
    @printf("  %-4s  %-8s  %-8s  %-10s  %-10s  %-50s\n",
        "Eq#", "max_ord", "n_vars", "res_prod", "res_perf", "variables involved")
    println("  ", "-" ^ 96)

    eq_max_orders = Int[]
    eq_is_data = Bool[]  # true if equation carries interpolation noise

    for (i, eq) in enumerate(prod_eqs)
        eq_vars = Symbolics.get_variables(eq)

        # Find max derivative order among variables in this equation
        eq_max_ord = 0
        var_names_in_eq = String[]
        for v in eq_vars
            if haskey(var_info, v)
                eq_max_ord = max(eq_max_ord, var_info[v].order)
                push!(var_names_in_eq, var_info[v].name)
            else
                push!(var_names_in_eq, string(v) * "(?)")
            end
        end

        # An equation is "data" if its residual differs between production and perfect
        is_data = abs(r_prod[i] - r_perf[i]) > 1e-12

        push!(eq_max_orders, eq_max_ord)
        push!(eq_is_data, is_data)

        type_str = is_data ? "DATA" : "STRUCT"
        vars_str = join(var_names_in_eq, ", ")
        if length(vars_str) > 50
            vars_str = vars_str[1:47] * "..."
        end

        @printf("  %-4d  %-8d  %-8d  %-10.2e  %-10.2e  %s  [%s]\n",
            i, eq_max_ord, length(eq_vars), r_prod[i], r_perf[i], vars_str, type_str)
    end

    # Summary: equations by type and max derivative order
    println("\n  Summary:")
    for ord in 0:max_order
        data_at_ord = count(i -> eq_max_orders[i] == ord && eq_is_data[i], 1:n_eqs)
        struct_at_ord = count(i -> eq_max_orders[i] == ord && !eq_is_data[i], 1:n_eqs)
        if data_at_ord + struct_at_ord > 0
            println("    order $ord: $data_at_ord data + $struct_at_ord structural = $(data_at_ord + struct_at_ord) equations")
        end
    end

    n_data = count(eq_is_data)
    n_struct = n_eqs - n_data
    println("    Total: $n_data data + $n_struct structural = $n_eqs equations")

    # Multi-point analysis
    println("\n  Multi-point analysis:")
    println("    2-point system: $(2*n_eqs) eqs, $(n_params + 2*n_state) vars → drop $n_params")

    # Which equations to drop? Find the n_params DATA equations with highest derivative order
    data_eq_indices = [i for i in 1:n_eqs if eq_is_data[i]]
    sorted_data = sort(data_eq_indices, by=i -> -eq_max_orders[i])
    drop_candidates = sorted_data[1:min(n_params, length(sorted_data))]

    println("    Proposed drop (highest-order data eqs): equations $(drop_candidates)")
    println("    Their max orders: ", [eq_max_orders[i] for i in drop_candidates])
    println("    Their production residuals: ", [@sprintf("%.2e", r_prod[i]) for i in drop_candidates])

    # Check: does the retained system still have full Jacobian rank?
    keep_indices = setdiff(1:n_eqs, drop_candidates)
    kept_eqs = prod_eqs[keep_indices]
    kept_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in kept_eqs
        union!(kept_vars_set, Symbolics.get_variables(eq))
    end
    kept_vars = collect(kept_vars_set)

    println("    Retained system: $(length(kept_eqs)) eqs, $(length(kept_vars)) vars")

    if length(kept_vars) > 0 && !any(isnan, true_vals)
        try
            # Build true values for the kept variables
            kept_true = Float64[]
            for v in kept_vars
                idx_v = findfirst(isequal(v), prod_vars)
                push!(kept_true, isnothing(idx_v) ? NaN : true_vals[idx_v])
            end

            if !any(isnan, kept_true)
                f_kept = ODEParameterEstimation._compile_system_function(kept_eqs, kept_vars)
                J_kept = ODEParameterEstimation.ForwardDiff.jacobian(f_kept, kept_true)
                r_kept = rank(J_kept; atol=1e-8)
                println("    Retained Jacobian rank: $r_kept / $(length(kept_vars))",
                    r_kept == length(kept_vars) ? " ✓ FULL RANK" : " ✗ RANK DEFICIENT")
            end
        catch e
            println("    Jacobian check failed: $e")
        end
    end
end

println("\n", "=" ^ 110)
println("EXPERIMENT 1 COMPLETE")
println("=" ^ 110)
