# Experiment 0: SI.jl Multi-Experiment Identifiability Query (v3)
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp00_si_me_query.jl")'

using ODEParameterEstimation
using ModelingToolkit
using StructuralIdentifiability
using OrderedCollections
using Printf
using Logging

models = OrderedDict{String, Function}(
    "simple" => ODEParameterEstimation.simple,
    "lotka_volterra" => ODEParameterEstimation.lotka_volterra,
    "forced_lv_sinusoidal" => ODEParameterEstimation.forced_lv_sinusoidal,
    "vanderpol" => ODEParameterEstimation.vanderpol,
)

println("=" ^ 100)
println("EXPERIMENT 0: SE vs ME Identifiability")
println("=" ^ 100)

for (name, ctor) in models
    println("\n", "─" ^ 80)
    println("MODEL: $name")
    println("─" ^ 80)

    pep = ctor()
    pep_data = ODEParameterEstimation.sample_problem_data(
        pep, EstimationOptions(datasize=11, time_interval=[0.0, 5.0], nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, tr_info = try
        ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var)
    catch; (pep_data, nothing); end

    model = pep_work.model.system
    states = ModelingToolkit.unknowns(model)
    params = ModelingToolkit.parameters(model)
    mq = pep_work.measured_quantities
    n_s, n_p, n_o = length(states), length(params), length(mq)

    println("  States ($n_s), Params ($n_p), Observables ($n_o)")
    !isnothing(tr_info) && println("  Transcendental: $(length(tr_info.entries)) entries")

    # ── SE identifiability via assess_identifiability ──
    println("\n  SE identifiability:")
    se_result = nothing
    try
        si_mq = [eq.lhs ~ eq.rhs for eq in mq]
        se_result = StructuralIdentifiability.assess_identifiability(
            model; measured_quantities=si_mq, loglevel=Logging.Warn)
        for (k, v) in se_result
            kname = replace(string(k), "(t)" => "")
            println("    $kname: $v")
        end
    catch e
        println("    FAILED: ", sprint(showerror, e))
    end

    # ── ME identifiability via assess_local_identifiability(type=:ME) ──
    println("\n  ME identifiability (parameters only):")
    try
        si_mq = [eq.lhs ~ eq.rhs for eq in mq]

        # Try various ways to get the internal SI ODE object
        si_ode = nothing

        # Method 1: preprocess_ode (the documented internal API)
        for func_name in [:preprocess_ode, :mtk_to_si, :_mtk_to_si]
            if isdefined(StructuralIdentifiability, func_name)
                println("    Trying SI.$func_name...")
                try
                    f = getfield(StructuralIdentifiability, func_name)
                    si_ode = f(model, si_mq)
                    println("    Success via $func_name")
                    break
                catch e2
                    println("    $func_name failed: ", sprint(showerror, e2))
                end
            end
        end

        if isnothing(si_ode)
            # Method 2: Try calling through the main entry point which does the conversion internally
            # assess_local_identifiability with MTK model + measured_quantities
            println("    Trying assess_local_identifiability with MTK model directly...")
            try
                # Only check parameters for ME
                param_funcs = [p for p in params]
                me_result = StructuralIdentifiability.assess_local_identifiability(
                    model;
                    measured_quantities=si_mq,
                    funcs_to_check=param_funcs,
                    type=:ME,
                    loglevel=Logging.Warn)

                if me_result isa Tuple
                    result_dict, n_exp = me_result
                    println("    Number of experiments needed: $n_exp")
                    for (k, v) in result_dict
                        println("    $(replace(string(k), "(t)" => "")): $v")
                    end
                else
                    println("    Result (not a tuple — SE fallback?): $me_result")
                end
            catch e3
                println("    Direct MTK ME call failed: ", sprint(showerror, e3))
            end
        else
            # We have the internal SI ODE object — call ME directly
            param_funcs = collect(si_ode.parameters)
            me_result = StructuralIdentifiability.assess_local_identifiability(
                si_ode;
                funcs_to_check=param_funcs,
                type=:ME,
                loglevel=Logging.Warn)

            if me_result isa Tuple
                result_dict, n_exp = me_result
                println("    Number of experiments needed: $n_exp")
                for (k, v) in result_dict
                    println("    $(string(k)): $v")
                end
            else
                println("    Result: $me_result")
            end
        end
    catch e
        println("    ME FAILED: ", sprint(showerror, e))
    end

    # ── Dimension analysis for the actual 1-point template ──
    println("\n  Actual template dimensions (from pipeline):")
    try
        ordered_model = if isa(model, ODEParameterEstimation.OrderedODESystem)
            model
        else
            ODEParameterEstimation.OrderedODESystem(model, states, params)
        end

        setup = ODEParameterEstimation.setup_parameter_estimation(
            pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)

        t_vec = pep_work.data_sample["t"]
        idx = setup.time_index_set[1]
        prod_eqs, prod_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict,
            setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[idx],
            precomputed_interpolants=setup.interpolants)

        n_eqs = length(prod_eqs)
        n_vars = length(prod_vars)

        # Classify variables
        var_names = string.(prod_vars)
        var_roles = ODEParameterEstimation._classify_polynomial_variables(var_names, pep_work)
        n_param_vars = count(v -> v == :parameter, values(var_roles))
        n_state_vars = n_vars - n_param_vars

        println("    1-point system: $n_eqs equations, $n_vars variables")
        println("      Parameters: $n_param_vars")
        println("      State/derivative vars: $n_state_vars")
        println("      Square: $(n_eqs == n_vars)")
        println("    Derivative levels: $(setup.good_deriv_level)")

        # Multi-point estimates
        for n_pts in [2, 3]
            mp_eqs = n_pts * n_eqs
            mp_vars = n_param_vars + n_pts * n_state_vars
            overdetermined = mp_eqs - mp_vars
            println("    $(n_pts)-point system: $(mp_eqs) eqs, $(mp_vars) vars, overdetermined by $(overdetermined)")
            println("      → need to drop $(overdetermined) equations for squareness")
        end
    catch e
        println("    Template construction failed: ", sprint(showerror, e))
    end
end

println("\n", "=" ^ 100)
println("EXPERIMENT 0 COMPLETE")
println("=" ^ 100)
