#= UQ Math Audit: verify IFT-based CI computation step by step =#

using ODEParameterEstimation
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Logging
global_logger(ConsoleLogger(stderr, Logging.Error))
redirect_stderr(devnull)

function audit_uq(pep_factory; datasize=201, time_interval=nothing)
    pep_raw = pep_factory()
    ti = isnothing(time_interval) ? pep_raw.recommended_time_interval : time_interval
    opts = EstimationOptions(datasize=datasize, time_interval=ti, nooutput=true,
        polish_solutions=false, polish_solver_solutions=false)

    # Step 0: Sample data and transform
    pep = sample_problem_data(pep_raw, opts)
    t_var = ModelingToolkit.get_iv(pep.model.system)
    pep_t, _ = try
        transform_pep_for_estimation(pep, t_var)
    catch
        (pep, nothing)
    end

    println("=" ^ 72)
    println("  UQ MATH AUDIT: $(pep_t.name)")
    println("  datasize=$datasize  t=$(ti)")
    println("=" ^ 72)

    # Step 1: Run estimation (get θ̂)
    println("\n--- Step 1: Estimation ---")
    raw, analyzed, _ = analyze_parameter_estimation_problem(pep_t, opts)
    results = analyzed[1]  # oracle-sorted
    println("  $(length(results)) solutions found")

    # Pick oracle-best result
    best = first(results)
    println("  Best oracle error: $(round(best.err; sigdigits=4))")
    println("  at_time: $(best.at_time)")

    # Step 2: Setup diagnostic infrastructure
    println("\n--- Step 2: Diagnostic setup ---")
    setup_data = setup_parameter_estimation(pep_t; interpolator=aaad_gpr_pivot, nooutput=true)

    t_data = pep_t.data_sample["t"]
    # Use the shooting point from the best result
    t_eval = best.at_time
    time_idx = argmin(abs.(t_data .- t_eval))
    t_eval = t_data[time_idx]
    println("  Evaluating at t=$(round(t_eval; digits=4)) (index $time_idx)")

    # Step 3: Compute oracle Taylor coefficients and true values
    max_order = 12
    state_taylor = compute_oracle_taylor_coefficients(pep_t, t_eval, max_order)
    obs_taylor = compute_observable_taylor_coefficients(pep_t, state_taylor, t_eval, max_order)

    # Step 4: Build the polynomial system and get variable lists
    model = pep_t.model.system
    mq = pep_t.measured_quantities
    DD = setup_data.good_DD

    ordered_model = isa(model, OrderedODESystem) ? model :
        (let (_, _, ms, ps) = unpack_ODE(model); OrderedODESystem(model, ms, ps) end)

    template_equations, derivative_dict, _, _, _, _ = get_si_equation_system(
        ordered_model, mq, pep_t.data_sample; DD=DD, infolevel=0)
    template_DD = ensure_si_template_dd_support(ordered_model, mq, DD, derivative_dict)

    # Collect all variables
    all_template_vars = OrderedCollections.OrderedSet{Any}()
    for eq in template_equations
        union!(all_template_vars, Symbolics.get_variables(eq))
    end

    # Identify data vs unknown variables
    data_var_set = Set{Any}()
    for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
        for v in level_vars
            v in all_template_vars && push!(data_var_set, v)
        end
    end

    # Substitute _trfn_ vars
    trfn_subst = Dict{Any,Any}()
    for v in all_template_vars
        tv = evaluate_trfn_template_variable(string(v), t_eval)
        !isnothing(tv) && (trfn_subst[v] = tv)
    end
    working_eqs = isempty(trfn_subst) ? template_equations :
        Symbolics.substitute.(template_equations, Ref(trfn_subst))
    kept_eqs = [eq for eq in working_eqs if !isempty(Symbolics.get_variables(eq))]

    remaining_vars = OrderedCollections.OrderedSet{Any}()
    for eq in kept_eqs
        union!(remaining_vars, Symbolics.get_variables(eq))
    end

    data_var_names = Set(string(v) for v in data_var_set)
    unknown_vars = [v for v in remaining_vars if !(string(v) in data_var_names)]
    data_vars = [v for v in remaining_vars if string(v) in data_var_names]

    n_x = length(unknown_vars)
    n_d = length(data_vars)
    println("  System: $(length(kept_eqs)) eqs, $n_x unknowns, $n_d data vars")
    println("  Unknown vars: ", [string(v) for v in unknown_vars])
    println("  Data vars: ", [string(v) for v in data_vars])

    # Step 5: Get TRUE values for all variables
    x_true = ODEParameterEstimation._build_true_value_vector(pep_t, unknown_vars;
        state_taylor=state_taylor, obs_taylor=obs_taylor)

    d_true = Float64[]
    for v in data_vars
        val = NaN
        for (li, lvars) in enumerate(template_DD.obs_lhs)
            for (oi, lv) in enumerate(lvars)
                if isequal(v, lv) && !isnothing(obs_taylor) && oi <= length(mq)
                    key = ModelingToolkit.diff2term(mq[oi].rhs)
                    if haskey(obs_taylor, key)
                        tc = obs_taylor[key]
                        dl = li - 1
                        if dl + 1 <= length(tc)
                            val = tc[dl+1] * factorial(dl)
                        end
                    end
                    @goto found
                end
            end
        end
        @label found
        push!(d_true, val)
    end

    if any(isnan, x_true) || any(isnan, d_true)
        println("  WARNING: NaN in true values, aborting")
        return
    end

    # Step 6: Get ESTIMATED values for unknowns (from θ̂)
    x_hat = Float64[]
    for v in unknown_vars
        vname = string(v)
        val = NaN
        # Match against estimation result
        for (p, ev) in best.parameters
            pname = replace(string(p), "(t)" => "")
            parsed = parse_derivative_variable_name(vname)
            if !isnothing(parsed)
                base, order = parsed
                if order == 0 && String(base) == pname
                    val = ev; break
                end
            end
            if pname * "_0" == vname
                val = ev; break
            end
        end
        if isnan(val)
            for (s, ev) in best.states
                sname = replace(string(s), "(t)" => "")
                parsed = parse_derivative_variable_name(vname)
                if !isnothing(parsed)
                    base, order = parsed
                    if order == 0 && String(base) == sname
                        val = ev; break
                    end
                end
            end
        end
        push!(x_hat, val)
    end

    # Step 7: Get GP-interpolated data values (d̂)
    d_hat = Float64[]
    prod_eqs, prod_vars = construct_equation_system_from_si_template(
        model, mq, pep_t.data_sample,
        setup_data.good_deriv_level, setup_data.good_udict,
        setup_data.good_varlist, setup_data.good_DD;
        interpolator=aaad_gpr_pivot,
        time_index_set=[time_idx],
        precomputed_interpolants=setup_data.interpolants,
    )

    # Match data vars to their production values
    for v in data_vars
        val = NaN
        vname = string(v)
        for (pvi, pv) in enumerate(prod_vars)
            if string(pv) == vname || isequal(v, pv)
                # This var appeared in prod_vars; its value is substituted into the equations
                # We need to find what the interpolant gave for this data variable
                break
            end
        end
        # Alternative: evaluate the system at truth and solve for data values
        push!(d_hat, val)
    end

    # Actually, let's get d̂ by evaluating the GP interpolants directly
    d_hat = Float64[]
    for v in data_vars
        val = NaN
        for (li, lvars) in enumerate(template_DD.obs_lhs)
            for (oi, lv) in enumerate(lvars)
                if isequal(v, lv) && oi <= length(mq)
                    dl = li - 1  # derivative level
                    obs_name = replace(string(mq[oi].lhs), r"\(.*\)" => "")
                    # Get interpolant
                    if haskey(setup_data.interpolants, mq[oi].rhs) ||
                       haskey(setup_data.interpolants, ModelingToolkit.diff2term(mq[oi].rhs))
                        key = haskey(setup_data.interpolants, mq[oi].rhs) ? mq[oi].rhs :
                            ModelingToolkit.diff2term(mq[oi].rhs)
                        interp = setup_data.interpolants[key]
                        # Evaluate derivative at t_eval
                        if dl == 0
                            val = interp(t_eval)
                        else
                            # Use finite differences or TaylorDiff for higher derivs
                            h = 1e-5
                            if dl == 1
                                val = (interp(t_eval + h) - interp(t_eval - h)) / (2h)
                            elseif dl == 2
                                val = (interp(t_eval + h) - 2*interp(t_eval) + interp(t_eval - h)) / h^2
                            else
                                # Higher order: use the setup_data derivative evaluation
                                val = NaN  # will fill from precomputed
                            end
                        end
                    end
                    @goto found2
                end
            end
        end
        @label found2
        push!(d_hat, val)
    end

    # Better approach: use the precomputed interpolant values at the shooting point
    # The SI template system substitutes data values. Let's reconstruct d̂ from
    # the production system evaluated at the shooting point.
    # Actually, the simplest way: build the compiled system, evaluate at x_true with d_hat,
    # and compare to evaluating at x_true with d_true.

    # Let's use the most reliable method: compile F(x,d) and use it
    combined_vars = [unknown_vars..., data_vars...]
    combined_fn = try
        fn = Symbolics.build_function(kept_eqs, combined_vars; expression=Val(false))
        fn isa Tuple ? fn[1] : fn
    catch
        nothing
    end

    if isnothing(combined_fn)
        println("  WARNING: Could not compile system function")
        return
    end

    # Verify: F(x_true, d_true) ≈ 0
    combined_true = [x_true..., d_true...]
    residual_true = combined_fn(combined_true)
    println("\n--- Step 3: Verify F(x_true, d_true) ≈ 0 ---")
    println("  max|F(x_true, d_true)| = $(@sprintf("%.2e", maximum(abs, residual_true)))")

    # Step 8: Compute Jacobians
    println("\n--- Step 4: Jacobians ---")
    J_full_true = ForwardDiff.jacobian(combined_fn, combined_true)
    J_x_true = J_full_true[:, 1:n_x]
    J_d_true = J_full_true[:, n_x+1:end]

    # S at true values
    cond_Jx_true = cond(J_x_true)
    S_true = if cond_Jx_true > 1e14
        -(pinv(J_x_true) * J_d_true)
    else
        -(J_x_true \ J_d_true)
    end
    println("  cond(J_x) at truth: $(@sprintf("%.2e", cond_Jx_true))")

    # Now we need d̂. Let me reconstruct it from the interpolants more carefully.
    # Use the setup_data to evaluate interpolated derivatives at the shooting point.
    println("\n--- Step 5: Reconstructing d̂ from interpolants ---")

    # The interpolants in setup_data.interpolants are keyed by observable RHS
    # For each data variable, we need to figure out which observable and derivative order
    d_hat_recon = Float64[]
    for (di, v) in enumerate(data_vars)
        val = NaN
        vname = string(v)
        for (li, lvars) in enumerate(template_DD.obs_lhs)
            for (oi, lv) in enumerate(lvars)
                if isequal(v, lv) && oi <= length(mq)
                    dl = li - 1
                    obs_rhs = ModelingToolkit.diff2term(mq[oi].rhs)
                    if haskey(setup_data.interpolants, obs_rhs)
                        interp = setup_data.interpolants[obs_rhs]
                        # Use TaylorDiff-style evaluation if available
                        # For now use the interpolant's derivative capabilities
                        try
                            if dl == 0
                                val = Float64(interp(t_eval))
                            else
                                # Numerical differentiation with appropriate step
                                val = _numerical_derivative(interp, t_eval, dl)
                            end
                        catch e
                            @debug "Failed to evaluate derivative" v dl e
                        end
                    end
                    @goto found3
                end
            end
        end
        @label found3
        push!(d_hat_recon, val)
    end

    # Check: how many d̂ values did we get?
    n_good = count(!isnan, d_hat_recon)
    println("  Reconstructed $n_good / $n_d data values from interpolants")

    if n_good < n_d
        println("  WARNING: Missing data values, trying alternative approach...")
        # Alternative: solve F(x, d) = 0 for d given x = x_hat
        # This won't work directly. Let's use what we have.
    end

    # For the values we DO have, compute the key quantities
    δd = d_hat_recon .- d_true
    δx = x_hat .- x_true

    println("\n--- Step 6: Data errors δd = d̂ - d_true ---")
    for (di, v) in enumerate(data_vars)
        vname = string(v)
        if !isnan(d_hat_recon[di])
            rel = abs(d_true[di]) > 1e-15 ? abs(δd[di]) / abs(d_true[di]) : abs(δd[di])
            @printf("  %-30s  true=%+12.6e  d̂=%+12.6e  δd=%+9.2e  rel=%8.2e\n",
                vname, d_true[di], d_hat_recon[di], δd[di], rel)
        else
            @printf("  %-30s  true=%+12.6e  d̂=NaN\n", vname, d_true[di])
        end
    end

    println("\n--- Step 7: Parameter errors δx = x̂ - x_true ---")
    for (xi, v) in enumerate(unknown_vars)
        vname = string(v)
        if !isnan(x_hat[xi])
            rel = abs(x_true[xi]) > 1e-15 ? abs(δx[xi]) / abs(x_true[xi]) : abs(δx[xi])
            @printf("  %-20s  true=%+12.6e  x̂=%+12.6e  δx=%+9.2e  rel=%8.2e\n",
                vname, x_true[xi], x_hat[xi], δx[xi], rel)
        else
            @printf("  %-20s  true=%+12.6e  x̂=NaN\n", vname, x_true[xi])
        end
    end

    # Step 9: First-order prediction vs actual
    println("\n--- Step 8: First-order prediction S_true · δd vs actual δx ---")
    if all(!isnan, δd)
        δx_predicted = S_true * δd
        println("  Variable                  actual δx      predicted S·δd    ratio")
        for (xi, v) in enumerate(unknown_vars)
            vname = string(v)
            if !isnan(x_hat[xi]) && abs(δx_predicted[xi]) > 1e-300
                ratio = δx[xi] / δx_predicted[xi]
                @printf("  %-20s  %+12.4e  %+12.4e  %8.3f\n",
                    vname, δx[xi], δx_predicted[xi], ratio)
            elseif !isnan(x_hat[xi])
                @printf("  %-20s  %+12.4e  %+12.4e  —\n",
                    vname, δx[xi], δx_predicted[xi])
            end
        end
    else
        println("  SKIPPED: missing δd values")
    end

    # Step 10: GP posterior σ vs actual δd (calibration check)
    println("\n--- Step 9: GP calibration: |δd| vs GP posterior σ ---")
    # Fit UQ GPs
    for (oi, mqe) in enumerate(mq)
        obs_name = replace(string(mqe.lhs), r"\(.*\)" => "")
        startswith(obs_name, "_obs_trfn_") && continue
        obs_rhs = ModelingToolkit.diff2term(mqe.rhs)
        y_data = ODEParameterEstimation._get_observable_data(pep_t, obs_rhs)
        isnothing(y_data) && continue

        try
            interp_uq = agp_gpr_uq(Float64.(t_data), Float64.(y_data))
            max_d = min(4, max_order)
            μ, Σ = joint_derivative_covariance(interp_uq, t_eval, max_d)
            σ = sqrt.(max.(diag(Σ), 0.0))

            println("  Observable: $obs_name  (σₙ=$(@sprintf("%.2e", sqrt(interp_uq.noise_var))))")
            for k in 0:max_d
                # Find the matching data variable
                for (di, dv) in enumerate(data_vars)
                    for (li, lvars) in enumerate(template_DD.obs_lhs)
                        for (oidx, lv) in enumerate(lvars)
                            if isequal(dv, lv) && oidx == oi && li - 1 == k
                                actual_err = isnan(δd[di]) ? NaN : abs(δd[di])
                                gp_σ = σ[k+1]
                                ratio = (isnan(actual_err) || gp_σ < 1e-300) ? NaN : actual_err / gp_σ
                                @printf("    order %d: GP_σ=%9.2e  |δd|=%9.2e  |δd|/σ=%6.2f  %s\n",
                                    k, gp_σ, actual_err, ratio,
                                    isnan(ratio) ? "" : ratio < 2.0 ? "✓ calibrated" :
                                    ratio < 5.0 ? "~ marginal" : "✗ miscalibrated")
                            end
                        end
                    end
                end
            end
        catch e
            println("  Observable $obs_name: UQ GP failed: $e")
        end
    end

    println("\n" * "=" ^ 72)
    println("  AUDIT COMPLETE")
    println("=" ^ 72)
end

# Numerical derivative helper
function _numerical_derivative(f, x, order; h=nothing)
    if isnothing(h)
        h = max(abs(x) * 1e-4, 1e-6)
    end
    if order == 0
        return f(x)
    elseif order == 1
        return (f(x+h) - f(x-h)) / (2h)
    elseif order == 2
        return (f(x+h) - 2f(x) + f(x-h)) / h^2
    elseif order == 3
        return (-f(x-2h) + 2f(x-h) - 2f(x+h) + f(x+2h)) / (2h^3)
    elseif order == 4
        return (f(x-2h) - 4f(x-h) + 6f(x) - 4f(x+h) + f(x+2h)) / h^4
    else
        # Recursive for higher orders
        return (_numerical_derivative(f, x+h, order-1; h=h) -
                _numerical_derivative(f, x-h, order-1; h=h)) / (2h)
    end
end

# Run on LV first (should be well-behaved)
println("\n\n" * "#" ^ 72)
println("# LOTKA-VOLTERRA")
println("#" ^ 72)
audit_uq(lotka_volterra; datasize=201, time_interval=[0.0, 20.0])
