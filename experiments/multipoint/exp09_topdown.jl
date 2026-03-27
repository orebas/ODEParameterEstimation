# Experiment 9: Top-down structural stripping
#
# Algorithm:
# 1. Build the full multi-point combined system (overdetermined)
# 2. Classify equations as STRUCTURAL (ODE derivatives) or DATA (interpolation pins)
# 3. Remove structural equations starting from highest derivative order
# 4. When a structural eq is removed, also remove any data equations that
#    pinned variables ONLY needed by that structural eq
# 5. Stop when square
# 6. Solve with HC.jl, report solution count + accuracy + timing
#
# Also: detailed HC.jl diagnostics (paths, mixed volume, timing breakdown)
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; include("experiments/multipoint/exp09_topdown.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random
using HomotopyContinuation

function get_deriv_order(name_str)
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = ODEParameterEstimation.parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

function run_topdown(name, pep; n_data=51, t_interval=nothing, n_points=2)
    println("\n", "=" ^ 90)
    @printf("%s — n=%d, %d points, top-down stripping\n", name, n_data, n_points)
    println("=" ^ 90)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, noise_level=0.0, nooutput=true))
    catch e; println("  SKIP: $e"); return nothing; end
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end
    println("  Params: ", keys(real_params))

    # Cache template
    setup = try
        ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); return nothing; end

    si_tmpl = try
        ordered_model = ODEParameterEstimation.OrderedODESystem(model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model))
        t, _ = ODEParameterEstimation.prepare_si_template_with_structural_fix(
            ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
            states=ModelingToolkit.unknowns(model), params=ModelingToolkit.parameters(model), infolevel=0)
        t
    catch e
        @warn "Template caching failed, will rebuild each time" exception=e
        nothing
    end

    function build_at(t_idx)
        ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx],
            precomputed_interpolants=setup.interpolants, si_template=si_tmpl)
    end

    # ── 1-point baseline ────────────────────────────────────────────────
    best_1pt = Inf; best_1pt_t = 0.0
    roles = nothing
    for frac in [0.2, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, min(n_t-1, round(Int, n_t * frac)))
        eqs, vars = build_at(t_idx)
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        solutions = try; s, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs, vars); s; catch; []; end
        pidxs = [i for (i, v) in enumerate(vars) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars[i]), "_0" => "") for i in pidxs]
        for sol in solutions
            me = maximum(haskey(real_params, pn) ? abs(sol[pidxs[j]]-real_params[pn])/max(abs(real_params[pn]),1e-10) : 0.0 for (j,pn) in enumerate(pnames))
            if me < best_1pt; best_1pt = me; best_1pt_t = t_vec[t_idx]; end
        end
    end
    @printf("  1-point best: %.4f at t=%.2f\n", best_1pt, best_1pt_t)

    # ── Build multi-point system ────────────────────────────────────────
    param_set = Set(vn for (vn, r) in roles if r == :parameter)
    fracs = n_points == 2 ? [0.25, 0.75] : collect(range(0.15, 0.85; length=n_points))
    t_indices = [max(2, min(n_t-1, round(Int, n_t * f))) for f in fracs]
    println("  Points: ", [round(t_vec[i]; digits=2) for i in t_indices])

    all_eqs = []; all_vars_list = []
    for t_idx in t_indices
        eqs, vars = build_at(t_idx)
        push!(all_eqs, eqs); push!(all_vars_list, vars)
    end

    # Rename + combine
    combined_eqs = Num[]
    eq_meta = []  # (point_idx, is_data, deriv_order, original_eq_idx)
    n_per = length(all_eqs[1])

    for (pt, eqs) in enumerate(all_eqs)
        if pt == 1
            for (i, eq) in enumerate(eqs)
                push!(combined_eqs, eq)
                nv = length(Symbolics.get_variables(eq))
                is_data = nv == 1
                mo = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point=pt, is_data=is_data, order=mo, orig_idx=i))
            end
        else
            rd = Dict{Any,Any}()
            for v in all_vars_list[pt]
                string(v) in param_set && continue
                rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt$(pt)"))
            end
            for (i, eq) in enumerate(eqs)
                renamed = Symbolics.substitute(eq, rd)
                push!(combined_eqs, renamed)
                nv = length(Symbolics.get_variables(eq))
                is_data = nv == 1
                mo = maximum(get_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point=pt, is_data=is_data, order=mo, orig_idx=i))
            end
        end
    end

    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(cvs, Symbolics.get_variables(eq)); end
    combined_vars = collect(cvs)
    n_eq = length(combined_eqs); n_var = length(combined_vars)
    overdetermined = n_eq - n_var

    println("  Combined: $(n_eq) eqs, $(n_var) vars, overdetermined by $overdetermined")

    n_struct = count(m -> !m.is_data, eq_meta)
    n_data = count(m -> m.is_data, eq_meta)
    println("  Structural: $n_struct, Data: $n_data")

    # ── Pre-compute full Jacobian for rank checking ─────────────────────
    println("\n  Computing full Jacobian...")
    f_combined = ODEParameterEstimation._compile_system_function(combined_eqs, combined_vars)
    rand_point = randn(n_var) .* 10.0
    J_full = ForwardDiff.jacobian(f_combined, rand_point)
    full_rank = rank(J_full; atol=1e-8)
    println("  Full Jacobian: $(size(J_full)), rank=$full_rank / $n_var")
    if full_rank < n_var
        println("  WARNING: Combined system itself is rank-deficient ($full_rank < $n_var)")
    end

    # ── Rank-aware top-down stripping ─────────────────────────────────────
    #
    # Remove highest-order structural equations, cascading data removal,
    # but CHECK RANK at each step. If removal drops rank below remaining
    # variable count, restore and skip that equation.

    struct_indices = [i for (i, m) in enumerate(eq_meta) if !m.is_data]
    data_indices = [i for (i, m) in enumerate(eq_meta) if m.is_data]
    struct_by_order = sort(struct_indices; by=i -> -eq_meta[i].order)

    kept = trues(n_eq)

    println("\n  Stripping (highest-order first, rank-aware):")
    for idx in struct_by_order
        # Save state for potential restore
        saved_kept = copy(kept)

        # Tentatively remove this structural equation
        kept[idx] = false
        m = eq_meta[idx]

        # Cascade: remove data equations for orphaned variables
        struct_vars = Set{Any}()
        for i in 1:n_eq
            kept[i] && !eq_meta[i].is_data && union!(struct_vars, Symbolics.get_variables(combined_eqs[i]))
        end
        cascaded = Int[]
        for di in data_indices
            !kept[di] && continue
            data_var = first(Symbolics.get_variables(combined_eqs[di]))
            if !(data_var in struct_vars)
                kept[di] = false
                push!(cascaded, di)
            end
        end

        # Compute remaining variable count
        remaining_var_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq; kept[i] && union!(remaining_var_set, Symbolics.get_variables(combined_eqs[i])); end
        remaining_var_count = length(remaining_var_set)
        remaining_eq_count = count(kept)

        # RANK CHECK: does the remaining system still have full rank?
        kept_rows = findall(kept)
        new_rank = isempty(kept_rows) ? 0 : rank(J_full[kept_rows, :]; atol=1e-8)

        cascade_str = isempty(cascaded) ? "" : " + $(length(cascaded)) data"

        if new_rank < remaining_var_count
            # Removal broke independence — RESTORE
            kept .= saved_kept
            @printf("    -eq%d (pt%d ord=%d)%s → RANK DROP (%d < %d vars). KEPT.\n",
                idx, m.point, m.order, cascade_str, new_rank, remaining_var_count)
        elseif remaining_eq_count == remaining_var_count && new_rank == remaining_var_count
            # SQUARE and FULL RANK — success
            @printf("    -eq%d (pt%d ord=%d)%s → %d eqs, %d vars, rank=%d → SQUARE!\n",
                idx, m.point, m.order, cascade_str, remaining_eq_count, remaining_var_count, new_rank)
            break
        elseif remaining_eq_count < remaining_var_count
            # Underdetermined — should not happen with rank guard, but just in case
            kept .= saved_kept
            @printf("    -eq%d (pt%d ord=%d) → UNDERDETERMINED. KEPT.\n", idx, m.point, m.order)
            break
        else
            # Still overdetermined, removal was safe
            @printf("    -eq%d (pt%d ord=%d)%s → %d eqs, %d vars, rank=%d (Δ=%d)\n",
                idx, m.point, m.order, cascade_str, remaining_eq_count, remaining_var_count,
                new_rank, remaining_eq_count - remaining_var_count)
        end
    end

    # Check if we reached square
    remaining_eq_count = count(kept)
    remaining_var_set = OrderedCollections.OrderedSet{Any}()
    for i in 1:n_eq; kept[i] && union!(remaining_var_set, Symbolics.get_variables(combined_eqs[i])); end
    remaining_var_count = length(remaining_var_set)

    if remaining_eq_count > remaining_var_count
        # Still overdetermined — fall back to greedy row selection
        println("\n  Top-down stalled at $(remaining_eq_count) eqs, $remaining_var_count vars (Δ=$(remaining_eq_count - remaining_var_count))")
        println("  Falling back to greedy row selection (low-order preference)...")
        kept_rows = findall(kept)
        # Sort by (data first, ascending order, point)
        sorted_kept = sort(kept_rows; by=i -> (eq_meta[i].is_data ? -1 : 0, eq_meta[i].order, eq_meta[i].point))

        final_sel = Int[]
        cur_rows = zeros(eltype(J_full), 0, size(J_full, 2))
        cur_rank = 0
        for idx in sorted_kept
            test = vcat(cur_rows, J_full[idx:idx, :])
            r = rank(test; atol=1e-8)
            if r > cur_rank
                push!(final_sel, idx)
                cur_rows = test
                cur_rank = r
            end
            cur_rank == remaining_var_count && break
        end
        # Update kept
        kept .= false
        for idx in final_sel; kept[idx] = true; end
        println("  Greedy selected $(length(final_sel)) / $remaining_var_count equations")
    end

    remaining_eqs = combined_eqs[kept]
    rv = OrderedCollections.OrderedSet{Any}()
    for eq in remaining_eqs; union!(rv, Symbolics.get_variables(eq)); end
    remaining_vars = collect(rv)

    is_square = length(remaining_eqs) == length(remaining_vars)
    max_remaining_order = maximum(m.order for m in eq_meta[kept])
    println("  Square: $is_square, max order: $max_remaining_order")

    if !is_square
        println("  Cannot solve — not square")
        return (name=name, best_1pt=best_1pt, err_topdown=Inf, n_sols=0, is_square=false,
                max_order=max_remaining_order, hc_time=0.0, hc_paths=0, mixed_vol=0)
    end

    # ── Solve with HC.jl (detailed diagnostics) ─────────────────────────
    println("\n  --- HC.jl solve ---")
    hc_system, hc_variables = try
        ODEParameterEstimation.convert_to_hc_format(remaining_eqs, remaining_vars)
    catch e
        println("  Convert failed: $(sprint(showerror, e)[1:min(60,end)])")
        return (name=name, best_1pt=best_1pt, err_topdown=Inf, n_sols=0, is_square=true,
                max_order=max_remaining_order, hc_time=0.0, hc_paths=0, mixed_vol=0)
    end

    bez = try; HomotopyContinuation.bezout_number(hc_system); catch; -1; end
    println("  Bezout bound: $bez")

    t0 = time()
    result = try
        HomotopyContinuation.solve(hc_system; show_progress=false)
    catch e
        println("  HC.jl solve failed: $(sprint(showerror, e)[1:min(60,end)])")
        nothing
    end
    hc_time = time() - t0

    if isnothing(result)
        return (name=name, best_1pt=best_1pt, err_topdown=Inf, n_sols=0, is_square=true,
                max_order=max_remaining_order, hc_time=hc_time, hc_paths=0, mixed_vol=0)
    end

    all_paths = HomotopyContinuation.nresults(result)
    real_sols = HomotopyContinuation.solutions(result; only_real=true, real_tol=1e-6)
    mixed_vol = try; length(HomotopyContinuation.results(result)); catch; -1; end

    @printf("  HC.jl: %d paths, %d real solutions, %.1fs\n", all_paths, length(real_sols), hc_time)

    # Score solutions
    pidxs = [i for (i, v) in enumerate(remaining_vars) if string(v) in param_set]
    pnames = [replace(string(remaining_vars[i]), "_0" => "") for i in pidxs]

    best_err = Inf
    for (si, sol) in enumerate(real_sols)
        pvals = Float64[real(sol[i]) for i in pidxs]
        me = 0.0
        for (j, pn) in enumerate(pnames)
            haskey(real_params, pn) && (me = max(me, abs(pvals[j]-real_params[pn])/max(abs(real_params[pn]),1e-10)))
        end
        if si <= 5
            param_str = join([@sprintf("%s=%.3f", pn, pvals[j]) for (j, pn) in enumerate(pnames) if haskey(real_params, pn)], " ")
            @printf("    sol%d: %s  err=%.4f\n", si, param_str, me)
        end
        best_err = min(best_err, me)
    end

    @printf("\n  RESULT: 1pt=%.4f → topdown=%.4f (%.1f× %s)\n",
        best_1pt, best_err, best_1pt/max(best_err, 1e-10),
        best_err < best_1pt ? "BETTER" : best_err > best_1pt ? "WORSE" : "SAME")

    return (name=name, best_1pt=best_1pt, err_topdown=best_err, n_sols=length(real_sols),
            is_square=true, max_order=max_remaining_order, hc_time=hc_time,
            hc_paths=all_paths, mixed_vol=mixed_vol)
end

# ═══════════════════════════════════════════════════════════════════════════

models = [
    ("simple", ODEParameterEstimation.simple(), 51, [0.0, 1.0]),
    ("lotka_volterra", ODEParameterEstimation.lotka_volterra(), 51, nothing),
    ("fitzhugh_nagumo", ODEParameterEstimation.fitzhugh_nagumo(), 51, nothing),
    ("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(), 51, [0.0, 10.0]),
    ("biohydrogenation", ODEParameterEstimation.biohydrogenation(), 51, [0.0, 1.0]),
    ("hiv", ODEParameterEstimation.hiv(), 51, nothing),
    ("daisy_mamil3", ODEParameterEstimation.daisy_mamil3(), 51, nothing),
    ("seir", ODEParameterEstimation.seir(), 51, nothing),
    ("treatment", ODEParameterEstimation.treatment(), 51, nothing),
]

flush(stdout)
results = []
for (name, pep, nd, ti) in models
    r = run_topdown(name, pep; n_data=nd, t_interval=ti, n_points=2)
    flush(stdout)
    !isnothing(r) && push!(results, r)
end

println("\n\n", "=" ^ 90)
println("FINAL SUMMARY — Top-Down Structural Stripping (2 points)")
println("=" ^ 90)
@printf("%-20s  %8s  %8s  %6s  %5s  %5s  %7s  %8s\n",
    "Model", "1pt_err", "2pt_err", "Improv", "Sols", "MaxOd", "HCtime", "Paths")
println("-" ^ 85)
for r in results
    imp = r.best_1pt / max(r.err_topdown, 1e-10)
    @printf("%-20s  %8.4f  %8.4f  %5.1f×  %5d  %5d  %6.1fs  %8d\n",
        r.name, r.best_1pt, r.err_topdown, imp, r.n_sols, r.max_order, r.hc_time, r.hc_paths)
end
println("=" ^ 90)
