# Experiment 5: Option C — combine standard templates + algebraic_independence
#
# Take the existing single-point template (fully processed by SIAN's 3 stages),
# instantiate at 2 time points, combine with shared params + renamed state vars,
# run algebraic_independence to select best equations.
#
# KEY QUESTION: Does algebraic_independence select equations from BOTH points,
# or does it just pick all equations from one point (since at a generic point
# the two instantiations have the same polynomial structure)?
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp05_option_c.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Printf
using Symbolics

function test_option_c(name, pep; n_data=21, t_interval=nothing)
    println("\n", "=" ^ 90)
    println("OPTION C: $name")
    println("=" ^ 90)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, nooutput=true))
    catch e; println("  SKIP: $e"); return; end
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    setup = ODEParameterEstimation.setup_parameter_estimation(
        pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    # Step 1: Get the standard 1-point template (already fully processed)
    t_idx_a = max(2, round(Int, n_t * 0.33))
    t_idx_b = min(n_t - 1, round(Int, n_t * 0.67))

    eqs_a, vars_a = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx_a], precomputed_interpolants=setup.interpolants)

    eqs_b, vars_b = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx_b], precomputed_interpolants=setup.interpolants)

    println("  Point A (t=$(t_vec[t_idx_a])): $(length(eqs_a))×$(length(vars_a))")
    println("  Point B (t=$(t_vec[t_idx_b])): $(length(eqs_b))×$(length(vars_b))")

    # Step 2: Classify vars, rename point B state vars
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars_a), pep_work)
    param_names = Set(vn for (vn, r) in roles if r == :parameter)

    rename_dict = Dict{Any, Any}()
    for v in vars_b
        string(v) in param_names && continue
        base = replace(string(v), r"\(.*\)$" => "")
        rename_dict[v] = Symbolics.variable(Symbol(base * "_pt2"))
    end
    eqs_b_renamed = [Symbolics.substitute(eq, rename_dict) for eq in eqs_b]

    # Step 3: Combine
    combined_eqs = vcat(eqs_a, eqs_b_renamed)
    combined_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(combined_vars_set, Symbolics.get_variables(eq)); end
    combined_vars = collect(combined_vars_set)

    n_combined_eqs = length(combined_eqs)
    n_combined_vars = length(combined_vars)
    println("  Combined: $(n_combined_eqs) eqs, $(n_combined_vars) vars")
    println("  Overdetermined by: $(n_combined_eqs - n_combined_vars)")

    # Step 4: Check Jacobian rank at oracle values
    max_d = maximum(values(setup.good_deriv_level))
    st_a = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_vec[t_idx_a], max_d + 2)
    ot_a = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, st_a, t_vec[t_idx_a], max_d + 2)
    st_b = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_vec[t_idx_b], max_d + 2)
    ot_b = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, st_b, t_vec[t_idx_b], max_d + 2)

    reverse_rename = Dict(v => k for (k, v) in rename_dict)
    true_vals = Float64[]
    for v in combined_vars
        if haskey(reverse_rename, v)
            val = ODEParameterEstimation._lookup_true_value(pep_work, reverse_rename[v];
                state_taylor=st_b, obs_taylor=ot_b, t_eval=t_vec[t_idx_b])
        else
            val = ODEParameterEstimation._lookup_true_value(pep_work, v;
                state_taylor=st_a, obs_taylor=ot_a, t_eval=t_vec[t_idx_a])
        end
        push!(true_vals, val)
    end

    if any(isnan, true_vals)
        println("  WARNING: $(count(isnan, true_vals)) NaN in true values — some vars can't be looked up")
        # Show which vars are NaN
        for (i, v) in enumerate(combined_vars)
            isnan(true_vals[i]) && println("    NaN: $(string(v))")
        end
    end

    if !any(isnan, true_vals)
        f = ODEParameterEstimation._compile_system_function(combined_eqs, combined_vars)
        J = ODEParameterEstimation.ForwardDiff.jacobian(f, true_vals)
        jrank = rank(J; atol=1e-8)
        println("  Jacobian rank at oracle: $jrank / $n_combined_vars")

        # Step 5: Greedy row selection (simulating algebraic_independence on Symbolics)
        # Pick equations that increase rank, tracking which point they came from
        selected_indices = Int[]
        current_rows = zeros(0, n_combined_vars)
        current_rank = 0
        n_from_a = 0; n_from_b = 0

        for i in 1:n_combined_eqs
            test_rows = vcat(current_rows, J[i:i, :])
            r = rank(test_rows; atol=1e-8)
            if r > current_rank
                push!(selected_indices, i)
                current_rows = test_rows
                current_rank = r
                if i <= length(eqs_a)
                    n_from_a += 1
                else
                    n_from_b += 1
                end
            end
        end

        println("  Greedy selection: $(length(selected_indices)) eqs (rank=$current_rank)")
        println("  From point A: $n_from_a, From point B: $n_from_b")
        println("  Square: $(length(selected_indices) == n_combined_vars)")

        # Show which equations were selected
        for idx in selected_indices
            source = idx <= length(eqs_a) ? "A" : "B"
            eq_in_source = idx <= length(eqs_a) ? idx : idx - length(eqs_a)
            println("    Eq $idx (point $source, #$eq_in_source)")
        end

        # Step 6: Try HC.jl on the selected subset
        if length(selected_indices) == n_combined_vars
            selected_eqs = combined_eqs[selected_indices]
            println("\n  Solving $(length(selected_eqs))×$(n_combined_vars) with HC.jl...")
            try
                solutions, _, _, _ = ODEParameterEstimation.solve_with_hc(selected_eqs, combined_vars)
                println("  HC.jl: $(length(solutions)) solution(s)")

                # Compare to 1-point
                solutions_1pt, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs_a, vars_a)
                println("  1-point: $(length(solutions_1pt)) solution(s)")
            catch e
                println("  HC.jl FAILED: ", sprint(showerror, e)[1:min(80,end)])
            end
        end
    end
end

# Test on key models
test_option_c("simple", ODEParameterEstimation.simple(); t_interval=[0.0, 1.0])
test_option_c("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(); t_interval=[0.0, 10.0], n_data=31)
