# Experiment 0b: ME identifiability + derivative order analysis
#
# Questions:
#   1. SE vs ME identifiability for more models (including biohydrogenation, crauste, cstr, hiv, seir)
#   2. For each model, what's the MINIMUM derivative order for a full-rank Jacobian at 1 point vs 2 points?
#   3. Does SI.jl's ME mode help identify the right derivative level for multi-point?
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp00b_me_and_deriv_orders.jl")'

using ODEParameterEstimation
using ModelingToolkit
using StructuralIdentifiability
using OrderedCollections
using Logging
using LinearAlgebra
using Printf

models = OrderedDict{String, Function}(
    "simple" => ODEParameterEstimation.simple,
    "lotka_volterra" => ODEParameterEstimation.lotka_volterra,
    "forced_lv_sinusoidal" => ODEParameterEstimation.forced_lv_sinusoidal,
    "vanderpol" => ODEParameterEstimation.vanderpol,
    "harmonic" => ODEParameterEstimation.harmonic,
    "biohydrogenation" => ODEParameterEstimation.biohydrogenation,
    "crauste" => ODEParameterEstimation.crauste,
    "cstr" => ODEParameterEstimation.cstr,
    "hiv" => ODEParameterEstimation.hiv,
    "seir" => ODEParameterEstimation.seir,
)

println("=" ^ 110)
println("EXPERIMENT 0b: ME Identifiability + Derivative Order Analysis")
println("=" ^ 110)

# Collect summary for final table
summary_rows = []

for (name, ctor) in models
    println("\n", "━" ^ 90)
    println("MODEL: $name")
    println("━" ^ 90)

    pep = try; ctor(); catch e; println("  SKIP: constructor failed — $e"); continue; end
    pep_data = try
        ODEParameterEstimation.sample_problem_data(
            pep, EstimationOptions(datasize=21, time_interval=pep.recommended_time_interval, nooutput=true))
    catch e
        println("  SKIP: sampling failed — $e"); continue
    end

    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, tr_info = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch; (pep_data, nothing); end

    model = pep_work.model.system
    mq = pep_work.measured_quantities
    si_mq = [eq.lhs ~ eq.rhs for eq in mq]
    states = ModelingToolkit.unknowns(model)
    params = ModelingToolkit.parameters(model)
    n_s, n_p, n_o = length(states), length(params), length(mq)

    println("  States=$n_s  Params=$n_p  Obs=$n_o")

    # ── Part 1: SE and ME identifiability ──
    se_str = ""
    me_n_exp = -1
    me_str = ""

    # SE
    try
        se = StructuralIdentifiability.assess_identifiability(
            model; measured_quantities=si_mq, loglevel=Logging.Error)
        se_parts = []
        for (k, v) in se
            kname = replace(string(k), "(t)" => "")
            startswith(kname, "_trfn_") && continue
            startswith(kname, "_obs_trfn_") && continue
            push!(se_parts, "$kname=$v")
        end
        se_str = join(se_parts, "  ")
        println("  SE: $se_str")
    catch e
        se_str = "FAILED"
        println("  SE: FAILED — ", sprint(showerror, e))
    end

    # ME
    try
        si_ode, var_map = StructuralIdentifiability.mtk_to_si(model, si_mq)
        param_funcs = collect(si_ode.parameters)
        me_result = StructuralIdentifiability.assess_local_identifiability(
            si_ode; funcs_to_check=param_funcs, type=:ME, loglevel=Logging.Error)
        if me_result isa Tuple
            result_dict, n_exp = me_result
            me_n_exp = n_exp
            me_parts = ["num_exp=$n_exp"]
            for (k, v) in result_dict
                push!(me_parts, "$(string(k))=$v")
            end
            me_str = join(me_parts, "  ")
            println("  ME: $me_str")
        end
    catch e
        me_str = "FAILED"
        println("  ME: FAILED — ", sprint(showerror, e))
    end

    # ── Part 2: Template at default derivative level ──
    default_deriv = Dict{Int,Int}()
    n_eqs_1pt = 0
    n_vars_1pt = 0
    n_param_vars = 0
    n_state_vars = 0

    try
        setup = ODEParameterEstimation.setup_parameter_estimation(
            pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
        default_deriv = setup.good_deriv_level
        t_vec = pep_work.data_sample["t"]
        idx = setup.time_index_set[1]

        prod_eqs, prod_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict,
            setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[idx],
            precomputed_interpolants=setup.interpolants)

        n_eqs_1pt = length(prod_eqs)
        n_vars_1pt = length(prod_vars)
        var_names = string.(prod_vars)
        roles = ODEParameterEstimation._classify_polynomial_variables(var_names, pep_work)
        n_param_vars = count(v -> v == :parameter, values(roles))
        n_state_vars = n_vars_1pt - n_param_vars
        max_deriv = maximum(values(default_deriv))

        println("  Default template: $(n_eqs_1pt)×$(n_vars_1pt) ($(n_param_vars) params, $(n_state_vars) state) deriv=$default_deriv")
        println("  2-pt: $(2*n_eqs_1pt) eqs, $(n_param_vars + 2*n_state_vars) vars, drop $(n_param_vars)")

        # ── Part 3: Try LOWER derivative levels ──
        # For the multi-point question: can we use fewer derivatives with 2 points?
        println("\n  Derivative order sweep (checking Jacobian rank at oracle values):")
        println("  " * "-" ^ 80)
        @printf("  %-8s  %-10s  %-10s  %-10s  %-10s  %-12s  %-10s\n",
            "max_ord", "1pt_eqs", "1pt_vars", "square?", "J_rank", "2pt_square?", "note")
        println("  " * "-" ^ 80)

        state_taylor = ODEParameterEstimation.compute_oracle_taylor_coefficients(
            pep_work, t_vec[idx], max_deriv + 2)
        obs_taylor = ODEParameterEstimation.compute_observable_taylor_coefficients(
            pep_work, state_taylor, t_vec[idx], max_deriv + 2)

        for test_order in 1:max_deriv
            # Build template with reduced derivative level
            test_deriv_level = Dict(k => min(v, test_order) for (k, v) in default_deriv)

            try
                test_eqs, test_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
                    model, mq, pep_work.data_sample,
                    test_deriv_level, setup.good_udict,
                    setup.good_varlist, setup.good_DD;
                    interpolator=ODEParameterEstimation.aaad_gpr_pivot,
                    time_index_set=[idx],
                    precomputed_interpolants=setup.interpolants)

                ne = length(test_eqs)
                nv = length(test_vars)
                is_square = ne == nv

                # Compute Jacobian rank at oracle values
                jrank = 0
                try
                    true_vals = ODEParameterEstimation._build_true_value_vector(
                        pep_work, test_vars;
                        state_taylor=state_taylor, obs_taylor=obs_taylor,
                        t_eval=t_vec[idx])
                    if !any(isnan, true_vals)
                        f = ODEParameterEstimation._compile_system_function(test_eqs, test_vars)
                        J = ODEParameterEstimation.ForwardDiff.jacobian(f, true_vals)
                        jrank = rank(J; atol=1e-8)
                    end
                catch; end

                # 2-point analysis
                test_roles = ODEParameterEstimation._classify_polynomial_variables(string.(test_vars), pep_work)
                np = count(v -> v == :parameter, values(test_roles))
                ns = nv - np
                two_pt_eqs = 2 * ne
                two_pt_vars = np + 2 * ns
                two_pt_square = two_pt_eqs == two_pt_vars

                note = ""
                if !is_square && two_pt_square
                    note = "★ 2PT EXACT SQUARE"
                elseif two_pt_eqs < two_pt_vars
                    note = "underdetermined"
                elseif two_pt_eqs > two_pt_vars
                    note = "drop $(two_pt_eqs - two_pt_vars)"
                end

                @printf("  %-8d  %-10d  %-10d  %-10s  %-10d  %-12s  %s\n",
                    test_order, ne, nv, is_square, jrank,
                    two_pt_square ? "YES" : "no($(two_pt_eqs)×$(two_pt_vars))",
                    note)
            catch e
                @printf("  %-8d  FAILED: %s\n", test_order, sprint(showerror, e))
            end
        end

        # Also show the default (full) level
        @printf("  %-8s  %-10d  %-10d  %-10s  %-10s  %-12s  %s\n",
            "default", n_eqs_1pt, n_vars_1pt, n_eqs_1pt == n_vars_1pt, "full",
            "drop $n_param_vars", "(current pipeline)")

    catch e
        println("  Template: FAILED — ", sprint(showerror, e))
    end

    push!(summary_rows, (name, n_s, n_p, n_o, me_n_exp, n_eqs_1pt, n_vars_1pt, n_param_vars, default_deriv))
end

# ── Final summary table ──
println("\n\n", "=" ^ 110)
println("SUMMARY TABLE")
println("=" ^ 110)
@printf("%-25s  %-4s  %-4s  %-4s  %-6s  %-10s  %-8s  %-8s  %s\n",
    "Model", "n_s", "n_p", "n_o", "ME_exp", "1pt_sys", "n_param", "2pt_drop", "deriv_levels")
println("-" ^ 110)
for (name, n_s, n_p, n_o, me_exp, ne, nv, np, dl) in summary_rows
    @printf("%-25s  %-4d  %-4d  %-4d  %-6s  %-10s  %-8d  %-8d  %s\n",
        name, n_s, n_p, n_o,
        me_exp >= 0 ? string(me_exp) : "?",
        "$(ne)×$(nv)",
        np, np,
        dl)
end
println("=" ^ 110)
