# Experiment 7: Clean controlled comparison — 1-point vs 2-point greedy
#
# Fix: compute full Jacobian once, do greedy row selection on the matrix
# Use more data points and noiseless data
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp07_clean_comparison.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using ForwardDiff
using Printf

# ═══════════════════════════════════════════════════════════════════════════

function fast_greedy_row_select(J, n_target; cost_order=nothing)
    # Select n_target rows from J that maximize rank, preferring rows with lower cost
    n_rows, n_cols = size(J)
    n_target = min(n_target, n_cols)  # can't select more than n_cols independent rows

    if isnothing(cost_order)
        cost_order = 1:n_rows  # default: process in original order
    end

    selected = Int[]
    current_rows = zeros(eltype(J), 0, n_cols)
    current_rank = 0

    for idx in cost_order
        test_rows = vcat(current_rows, J[idx:idx, :])
        r = rank(test_rows; atol=1e-8)
        if r > current_rank
            push!(selected, idx)
            current_rows = test_rows
            current_rank = r
        end
        current_rank == n_target && break
    end
    return selected
end

function run_comparison(name, pep; n_data=51, t_interval=nothing, n_points=2)
    println("\n", "=" ^ 100)
    println("$name — n=$n_data, $n_points points, noise=0")
    println("=" ^ 100)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]

    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, noise_level=0.0, nooutput=true))
    catch e; println("  SKIP: $e"); return; end

    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    setup = try
        ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); return; end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end
    println("  True: ", real_params)
    println("  t = [$(t_vec[1]), $(t_vec[end])], n=$n_t")

    # ── Helper: solve at a point and report ─────────────────────────────
    function solve_and_report(label, eqs, vars)
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        pidxs = [i for (i, v) in enumerate(vars) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars[i]), "_0" => "") for i in pidxs]

        solutions = try; s, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs, vars); s
        catch e; println("    HC FAIL: ", sprint(showerror, e)[1:min(60,end)]); return Inf; end

        best_err = Inf
        for sol in solutions
            pvals = [sol[i] for i in pidxs]
            max_err = 0.0
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (max_err = max(max_err, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            if max_err < best_err
                best_err = max_err
            end
        end
        @printf("  %s: %d sol, best max_rel_err=%.4f\n", label, length(solutions), best_err)
        return best_err
    end

    # ── Helper: get derivative order of an equation ─────────────────────
    function eq_deriv_order(eq)
        max_ord = 0
        for v in Symbolics.get_variables(eq)
            parsed = ODEParameterEstimation.parse_derivative_variable_name(string(v))
            !isnothing(parsed) && (max_ord = max(max_ord, parsed[2]))
        end
        return max_ord
    end

    # ── 1-point baseline at several t ───────────────────────────────────
    println("\n  --- 1-point baseline ---")
    best_1pt = Inf
    for frac in [0.15, 0.25, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, round(Int, n_t * frac))
        eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
        err = solve_and_report(@sprintf("1pt t=%.2f", t_vec[t_idx]), eqs, vars)
        best_1pt = min(best_1pt, err)
    end
    @printf("  BEST 1-point: %.4f\n", best_1pt)

    # ── Build multi-point system ────────────────────────────────────────
    println("\n  --- $n_points-point systems ---")

    # Choose well-separated time points
    fracs = n_points == 2 ? [0.25, 0.75] :
            n_points == 3 ? [0.2, 0.5, 0.8] :
            range(0.15, 0.85; length=n_points)
    t_indices = [max(2, min(n_t-1, round(Int, n_t * f))) for f in fracs]
    println("  Points: ", [@sprintf("t=%.2f", t_vec[i]) for i in t_indices])

    roles = ODEParameterEstimation._classify_polynomial_variables(
        string.(ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_indices[1]], precomputed_interpolants=setup.interpolants)[2]),
        pep_work)
    param_names_set = Set(vn for (vn, r) in roles if r == :parameter)

    all_point_eqs = []
    all_point_vars = []
    for t_idx in t_indices
        eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
        push!(all_point_eqs, eqs); push!(all_point_vars, vars)
    end

    # Rename state vars for points 2, 3, ...
    combined_eqs = copy(all_point_eqs[1])
    rename_dicts = [Dict{Any,Any}()]
    for pt in 2:n_points
        rd = Dict{Any,Any}()
        for v in all_point_vars[pt]
            string(v) in param_names_set && continue
            rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt$(pt)"))
        end
        push!(rename_dicts, rd)
        append!(combined_eqs, [Symbolics.substitute(eq, rd) for eq in all_point_eqs[pt]])
    end

    cv = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(cv, Symbolics.get_variables(eq)); end
    combined_vars = collect(cv)

    n_eq = length(combined_eqs)
    n_var = length(combined_vars)
    println("  Combined: $n_eq eqs, $n_var vars (overdetermined by $(n_eq - n_var))")

    # ── Compute full Jacobian at a random point (ONE compilation) ───────
    println("  Computing full Jacobian...")
    rand_point = randn(n_var) .* 10  # random eval point
    f_all = ODEParameterEstimation._compile_system_function(combined_eqs, combined_vars)
    J_all = ForwardDiff.jacobian(f_all, rand_point)
    println("  J size: $(size(J_all)), rank: $(rank(J_all; atol=1e-8))")

    # ── Equation metadata ───────────────────────────────────────────────
    eq_orders = [eq_deriv_order(eq) for eq in combined_eqs]
    eq_points = Int[]
    for pt in 1:n_points
        append!(eq_points, fill(pt, length(all_point_eqs[pt])))
    end

    # ── Strategy 1: Low-order-first ─────────────────────────────────────
    cost_order_s1 = sortperm(eq_orders)
    sel_s1 = fast_greedy_row_select(J_all, n_var; cost_order=cost_order_s1)

    if length(sel_s1) == n_var
        sel_orders = eq_orders[sel_s1]
        sel_points = eq_points[sel_s1]
        @printf("  Strategy 1 (low-order-first): %d eqs, max_order=%d, per_point=%s\n",
            length(sel_s1), maximum(sel_orders), [count(==(pt), sel_points) for pt in 1:n_points])
        println("  Order histogram: ", [count(==(o), sel_orders) for o in 0:maximum(sel_orders)])

        err_s1 = solve_and_report("Strategy 1", combined_eqs[sel_s1], combined_vars)
    else
        println("  Strategy 1: could not reach square ($(length(sel_s1))/$n_var)")
        err_s1 = Inf
    end

    # ── Strategy 2: High-order-first (control — should be worse) ────────
    cost_order_s2 = sortperm(eq_orders; rev=true)
    sel_s2 = fast_greedy_row_select(J_all, n_var; cost_order=cost_order_s2)

    if length(sel_s2) == n_var
        sel_orders2 = eq_orders[sel_s2]
        sel_points2 = eq_points[sel_s2]
        @printf("  Strategy 2 (high-order-first): %d eqs, max_order=%d, per_point=%s\n",
            length(sel_s2), maximum(sel_orders2), [count(==(pt), sel_points2) for pt in 1:n_points])
        println("  Order histogram: ", [count(==(o), sel_orders2) for o in 0:maximum(sel_orders2)])

        err_s2 = solve_and_report("Strategy 2", combined_eqs[sel_s2], combined_vars)
    else
        println("  Strategy 2: could not reach square")
        err_s2 = Inf
    end

    # ── Strategy 3: Default order (no preference — baseline for selection) ──
    sel_s3 = fast_greedy_row_select(J_all, n_var)  # default: process in order (A first, then B)
    if length(sel_s3) == n_var
        err_s3 = solve_and_report("Strategy 3 (default)", combined_eqs[sel_s3], combined_vars)
    else
        err_s3 = Inf
    end

    # ── Summary ─────────────────────────────────────────────────────────
    println("\n  ━━━ SUMMARY ━━━")
    @printf("  Best 1-point:              %.4f\n", best_1pt)
    @printf("  Strategy 1 (low-order):    %.4f  (%.1f×)\n", err_s1, best_1pt / max(err_s1, 1e-10))
    @printf("  Strategy 2 (high-order):   %.4f  (%.1f×)\n", err_s2, best_1pt / max(err_s2, 1e-10))
    @printf("  Strategy 3 (default):      %.4f  (%.1f×)\n", err_s3, best_1pt / max(err_s3, 1e-10))
end

# ═══════════════════════════════════════════════════════════════════════════

run_comparison("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal();
    n_data=51, t_interval=[0.0, 10.0], n_points=2)

run_comparison("forced_lv_sinusoidal 3pt", ODEParameterEstimation.forced_lv_sinusoidal();
    n_data=51, t_interval=[0.0, 10.0], n_points=3)

run_comparison("biohydrogenation", ODEParameterEstimation.biohydrogenation();
    n_data=51, t_interval=[0.0, 1.0], n_points=2)

run_comparison("biohydrogenation 3pt", ODEParameterEstimation.biohydrogenation();
    n_data=51, t_interval=[0.0, 1.0], n_points=3)

run_comparison("lotka_volterra", ODEParameterEstimation.lotka_volterra();
    n_data=51, n_points=2)

run_comparison("hiv", ODEParameterEstimation.hiv();
    n_data=51, n_points=2)
