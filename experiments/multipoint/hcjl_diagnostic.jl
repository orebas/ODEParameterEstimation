# HC.jl Diagnostic: detailed solution analysis for multi-point systems
#
# For each system variant, reports:
#   - Total paths tracked
#   - Real solutions (with tolerance)
#   - Complex solutions
#   - Singular solutions
#   - Path failures
#   - The Newton root (from oracle start)
#   - The true parameter values
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/hcjl_diagnostic.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using HomotopyContinuation

# ═══════════════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════════════

function get_template_at_point(pep_work, setup, t_idx)
    ODEParameterEstimation.construct_equation_system_from_si_template(
        pep_work.model.system, pep_work.measured_quantities, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
end

function get_oracle_values(pep_work, vars, t_eval, setup)
    max_d = maximum(values(setup.good_deriv_level))
    st = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_eval, max_d + 2)
    ot = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, st, t_eval, max_d + 2)
    return ODEParameterEstimation._build_true_value_vector(pep_work, vars;
        state_taylor=st, obs_taylor=ot, t_eval=t_eval)
end

function rename_state_vars(eqs, vars, pep_work; suffix="_pt2")
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
    param_names = Set(vn for (vn, r) in roles if r == :parameter)
    rd = Dict{Any,Any}()
    for v in vars
        string(v) in param_names && continue
        rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * suffix))
    end
    renamed_eqs = [Symbolics.substitute(eq, rd) for eq in eqs]
    return renamed_eqs, rd
end

function newton_solve(f, x0; max_iter=20, tol=1e-12)
    xc = copy(x0)
    for i in 1:max_iter
        r = f(xc)
        norm(r) < tol && return (x=xc, residual=norm(r), converged=true, iters=i)
        J = ForwardDiff.jacobian(f, xc)
        rk = rank(J; atol=1e-10)
        rk < length(xc) && return (x=xc, residual=norm(r), converged=false, iters=i)
        xc = xc .- (J \ r)
    end
    r = f(xc)
    return (x=xc, residual=norm(r), converged=norm(r) < tol, iters=max_iter)
end

function convert_to_hc_format_safe(poly_system, varlist)
    # Safe version of convert_to_hc_format that sorts replacements by length (longest first)
    # to avoid substring collision (e.g., "x2_0" matching inside "x2_0_pt2")
    string_target = string.(poly_system)
    sanitized = ODEParameterEstimation.sanitize_vars(varlist)

    mapping = Dict{String, String}()
    for (i, v) in enumerate(varlist)
        mapping[string(v)] = "hmcs(\"" * sanitized[i] * "\")"
    end

    # Two-pass replacement to avoid substring collision:
    # Pass 1: replace variable names with unique placeholders (no substrings of variable names)
    # Pass 2: replace placeholders with hmcs("...") calls
    sorted_keys = sort(collect(keys(mapping)); by=length, rev=true)
    placeholders = Dict{String, String}()
    for (idx, k) in enumerate(sorted_keys)
        placeholders[k] = "\x01VAR$(idx)\x01"  # unique non-printable placeholder
    end
    for i in eachindex(string_target)
        local s = string_target[i]
        # Pass 1: longest-first replacement to placeholders
        for k in sorted_keys
            s = replace(s, k => placeholders[k])
        end
        # Pass 2: placeholders to hmcs("...")
        for k in sorted_keys
            s = replace(s, placeholders[k] => mapping[k])
        end
        string_target[i] = s
    end

    parsed = eval.(Meta.parse.(string_target))
    HomotopyContinuation.set_default_compile(:all)
    hc_variables = [HomotopyContinuation.ModelKit.Variable(Symbol(sanitized[i])) for i in eachindex(varlist)]
    hc_system = HomotopyContinuation.System(parsed, variables=hc_variables)
    return hc_system, hc_variables
end

function hcjl_detailed_solve(eqs, vars; label="")
    println("\n  --- HC.jl: $label ($(length(eqs))×$(length(vars))) ---")

    hc_system, hc_variables = try
        convert_to_hc_format_safe(eqs, vars)
    catch e
        println("    CONVERT FAILED: ", sprint(showerror, e)[1:min(80,end)])
        # Debug: show first few equation strings after replacement
        sanitized = ODEParameterEstimation.sanitize_vars(vars)
        mapping = Dict(string(vars[i]) => "hmcs(\"$(sanitized[i])\")" for i in eachindex(vars))
        sorted_pairs = sort(collect(mapping); by=x->length(x[1]), rev=true)
        for (ei, eq) in enumerate(eqs)
            local s = string(eq)
            for (k, v) in sorted_pairs; s = replace(s, k => v); end
            println("    Eq$ei after replace: $s")
        end
        return nothing
    end

    result = try
        HomotopyContinuation.solve(hc_system; show_progress=false)
    catch e
        println("    SOLVE FAILED: ", sprint(showerror, e)[1:min(80,end)])
        return nothing
    end

    # Detailed path analysis
    all_sols = HomotopyContinuation.results(result)
    n_total = length(all_sols)
    n_success = count(r -> r.return_code == :success, all_sols)
    n_at_infinity = count(r -> r.return_code == :at_infinity, all_sols)
    n_excess = count(r -> r.return_code == :excess_solution, all_sols)
    n_other = n_total - n_success - n_at_infinity - n_excess

    real_sols = HomotopyContinuation.solutions(result; only_real=true, real_tol=1e-6)
    all_finite = HomotopyContinuation.solutions(result)
    singular = try; HomotopyContinuation.singular(result); catch; []; end

    println("    Paths tracked: $n_total")
    println("    Success: $n_success, At infinity: $n_at_infinity, Excess: $n_excess, Other: $n_other")
    println("    Real solutions (tol=1e-6): $(length(real_sols))")
    println("    All finite solutions: $(length(all_finite))")
    println("    Singular: $(length(singular))")

    if !isempty(real_sols)
        for (i, s) in enumerate(real_sols[1:min(3, end)])
            println("    Real sol $i: ", round.(Float64.(real.(s)); sigdigits=5))
        end
    elseif !isempty(all_finite)
        println("    (No real solutions — showing first complex:)")
        for (i, s) in enumerate(all_finite[1:min(2, end)])
            println("    Complex sol $i: ", round.(s; sigdigits=4))
        end
    end

    # Degree info
    println("    Bezout bound: ", try; HomotopyContinuation.bezout_number(hc_system); catch; "?"; end)

    return (real_sols=real_sols, all_finite=all_finite, n_paths=n_total, n_success=n_success)
end

function param_error_summary(sol_vec, vars, pep_work)
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
    for (i, v) in enumerate(vars)
        vn = string(v)
        roles[vn] == :parameter || continue
        base = replace(vn, "_0" => "")
        for (pk, pv) in pep_work.p_true
            pname = replace(string(pk), "(t)" => "")
            (startswith(pname, "_trfn_") || startswith(pname, "_obs_trfn_")) && continue
            if pname == base
                rel = abs(sol_vec[i] - pv) / max(abs(pv), 1e-10)
                @printf("      %s: est=%.4f true=%.4f rel=%.3f\n", base, sol_vec[i], pv, rel)
            end
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════
# Run diagnostics
# ═══════════════════════════════════════════════════════════════════════════

function run_diagnostic(name, pep; n_data=21, t_interval=nothing)
    println("\n", "=" ^ 90)
    println("HC.jl DIAGNOSTIC: $name (n=$n_data)")
    println("=" ^ 90)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, nooutput=true))
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end
    setup = ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    t_idx_a = max(2, round(Int, n_t * 0.33))
    t_idx_b = min(n_t - 1, round(Int, n_t * 0.67))
    println("  Points: t_a=$(t_vec[t_idx_a]) (idx=$t_idx_a), t_b=$(t_vec[t_idx_b]) (idx=$t_idx_b)")

    # ── System A (1-point at t_a) ───────────────────────────────────────
    eqs_a, vars_a = get_template_at_point(pep_work, setup, t_idx_a)
    oracle_a = get_oracle_values(pep_work, vars_a, t_vec[t_idx_a], setup)

    # ── System B (1-point at t_b, renamed) ──────────────────────────────
    eqs_b, vars_b = get_template_at_point(pep_work, setup, t_idx_b)
    oracle_b_orig = get_oracle_values(pep_work, vars_b, t_vec[t_idx_b], setup)
    eqs_br, rename_dict = rename_state_vars(eqs_b, vars_b, pep_work)
    reverse_rename = Dict(v => k for (k, v) in rename_dict)

    # ── Combined system (all equations) ─────────────────────────────────
    combined_eqs = vcat(eqs_a, eqs_br)
    cv_set = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(cv_set, Symbolics.get_variables(eq)); end
    combined_vars = collect(cv_set)

    # Oracle values for combined
    oracle_combined = Float64[]
    for v in combined_vars
        if haskey(reverse_rename, v)
            idx_orig = findfirst(isequal(reverse_rename[v]), vars_b)
            push!(oracle_combined, isnothing(idx_orig) ? NaN : oracle_b_orig[idx_orig])
        else
            idx_orig = findfirst(isequal(v), vars_a)
            push!(oracle_combined, isnothing(idx_orig) ? NaN : oracle_a[idx_orig])
        end
    end

    println("\n  System sizes: A=$(length(eqs_a))×$(length(vars_a)), B=$(length(eqs_br))×$(length(Symbolics.get_variables(eqs_br[1]))), Combined=$(length(combined_eqs))×$(length(combined_vars))")

    # ── Test 1: HC.jl on 1-point A ─────────────────────────────────────
    r1 = hcjl_detailed_solve(eqs_a, vars_a; label="1-point A (t=$(t_vec[t_idx_a]))")
    if !isnothing(r1) && !isempty(r1.real_sols)
        println("    Param errors (best real sol):")
        param_error_summary(Float64.(real.(r1.real_sols[1])), vars_a, pep_work)
    end

    # ── Test 2: HC.jl on 1-point B (renamed) ───────────────────────────
    bv_set = OrderedCollections.OrderedSet{Any}()
    for eq in eqs_br; union!(bv_set, Symbolics.get_variables(eq)); end
    b_vars = collect(bv_set)
    r2 = hcjl_detailed_solve(eqs_br, b_vars; label="1-point B renamed (t=$(t_vec[t_idx_b]))")

    # ── Test 3: HC.jl on combined (overdetermined) ─────────────────────
    r3 = hcjl_detailed_solve(combined_eqs, combined_vars; label="Combined overdetermined ($(length(combined_eqs))×$(length(combined_vars)))")

    # ── Test 4: HC.jl on greedy-selected square subset ─────────────────
    if !any(isnan, oracle_combined)
        f_comb = ODEParameterEstimation._compile_system_function(combined_eqs, combined_vars)
        J_comb = ForwardDiff.jacobian(f_comb, oracle_combined)

        # Greedy row selection
        selected = Int[]; current_rows = zeros(0, length(combined_vars)); cr = 0
        for i in 1:length(combined_eqs)
            test = vcat(current_rows, J_comb[i:i, :])
            r = rank(test; atol=1e-8)
            if r > cr; push!(selected, i); current_rows = test; cr = r; end
        end
        if cr == length(combined_vars)
            sel_eqs = combined_eqs[selected]
            n_from_a = count(i -> i <= length(eqs_a), selected)
            n_from_b = count(i -> i > length(eqs_a), selected)
            r4 = hcjl_detailed_solve(sel_eqs, combined_vars;
                label="Greedy selected ($n_from_a from A + $n_from_b from B = $(length(selected)))")
        end

        # ── Test 5: Newton from oracle on the greedy system ─────────────
        println("\n  --- Newton from oracle on greedy $(length(selected))×$(length(combined_vars)) ---")
        f_sel = ODEParameterEstimation._compile_system_function(sel_eqs, combined_vars)
        nr = newton_solve(f_sel, oracle_combined)
        @printf("    Converged: %s, iters: %d, ||F||: %.2e\n", nr.converged, nr.iters, nr.residual)
        if nr.converged
            println("    Param errors (Newton):")
            param_error_summary(nr.x, combined_vars, pep_work)
        end

        # ── Test 6: Gauss-Newton on the full overdetermined system ──────
        println("\n  --- Gauss-Newton from oracle on overdetermined $(length(combined_eqs))×$(length(combined_vars)) ---")
        xc = copy(oracle_combined)
        for iter in 1:15
            r = f_comb(xc)
            J = ForwardDiff.jacobian(f_comb, xc)
            nr_val = norm(r)
            iter <= 3 && @printf("    Iter %d: ||F||=%.4e\n", iter, nr_val)
            nr_val < 1e-10 && break
            xc = xc .- (transpose(J) * J) \ (transpose(J) * r)
        end
        r_final = f_comb(xc)
        @printf("    Final: ||F||=%.4e\n", norm(r_final))
        println("    Param errors (Gauss-Newton):")
        param_error_summary(xc, combined_vars, pep_work)
    end

    # ── True values summary ─────────────────────────────────────────────
    println("\n  --- True parameter values ---")
    for (pk, pv) in pep_work.p_true
        pname = replace(string(pk), "(t)" => "")
        (startswith(pname, "_trfn_") || startswith(pname, "_obs_trfn_")) && continue
        @printf("    %s = %.4f\n", pname, pv)
    end
end

# ═══════════════════════════════════════════════════════════════════════════

run_diagnostic("simple", ODEParameterEstimation.simple(); t_interval=[0.0, 1.0])
run_diagnostic("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(); n_data=31, t_interval=[0.0, 10.0])
