# Experiment 8: Multi-point with interleaved greedy selection
#
# For each model: combine templates from N points with shared params + separate state vars,
# use interleaved greedy row selection to get a square system, solve with HC.jl.
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp08_interleaved.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using ForwardDiff
using Printf
using Random

function run_model(name, pep; n_data=51, t_interval=nothing, n_points=2)
    println("\n", "=" ^ 90)
    println("$name — n=$n_data, $n_points points")
    println("=" ^ 90)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, noise_level=0.0, nooutput=true))
    catch e; println("  SKIP: $e"); return nothing; end
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    setup = try
        ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); return nothing; end

    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end
    println("  Params: ", real_params)

    # ── Helper: solve and score ─────────────────────────────────────────
    function solve_score(eqs, vars)
        solutions = try; s, _, _, _ = ODEParameterEstimation.solve_with_hc(eqs, vars); s
        catch; return (Inf, 0); end
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        pidxs = [i for (i, v) in enumerate(vars) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars[i]), "_0" => "") for i in pidxs]
        best = Inf
        for sol in solutions
            pvals = [sol[i] for i in pidxs]
            me = 0.0
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (me = max(me, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            best = min(best, me)
        end
        return (best, length(solutions))
    end

    # ── Build and cache the SI template (ONCE per model) ──────────────
    # First call builds and caches; subsequent calls reuse
    first_eqs, first_vars = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[round(Int, n_t*0.5)], precomputed_interpolants=setup.interpolants)

    # Extract the cached template from setup (it's stored after first construction)
    # We need to get the si_template object. The cleanest way: call prepare_si_template directly.
    ordered_model = if isa(model, ODEParameterEstimation.OrderedODESystem); model
    else ODEParameterEstimation.OrderedODESystem(model, ModelingToolkit.unknowns(model), ModelingToolkit.parameters(model)); end

    si_template_cached = try
        ODEParameterEstimation.prepare_si_template_with_structural_fix(
            ordered_model, mq, pep_work.data_sample, setup.good_DD, false;
            states=ModelingToolkit.unknowns(model), params=ModelingToolkit.parameters(model), infolevel=0)
    catch
        # Fallback: just use nothing (will rebuild each time)
        (nothing, nothing)
    end
    si_tmpl = si_template_cached isa Tuple ? si_template_cached[1] : nothing

    function build_at_point(t_idx)
        ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample, setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot, time_index_set=[t_idx],
            precomputed_interpolants=setup.interpolants, si_template=si_tmpl)
    end

    # ── 1-point baseline ────────────────────────────────────────────────
    best_1pt = Inf; best_1pt_t = 0.0
    for frac in [0.2, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, min(n_t-1, round(Int, n_t * frac)))
        eqs, vars = build_at_point(t_idx)
        err, nsol = solve_score(eqs, vars)
        if err < best_1pt; best_1pt = err; best_1pt_t = t_vec[t_idx]; end
    end
    @printf("  1-point best: %.4f at t=%.2f\n", best_1pt, best_1pt_t)

    # ── Build multi-point combined system ───────────────────────────────
    fracs = n_points == 2 ? [0.25, 0.75] :
            n_points == 3 ? [0.2, 0.5, 0.8] :
            collect(range(0.15, 0.85; length=n_points))
    t_indices = [max(2, min(n_t-1, round(Int, n_t * f))) for f in fracs]

    all_eqs = []; all_vars_list = []
    for t_idx in t_indices
        eqs, vars = build_at_point(t_idx)
        push!(all_eqs, eqs); push!(all_vars_list, vars)
    end

    roles = ODEParameterEstimation._classify_polynomial_variables(string.(all_vars_list[1]), pep_work)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    combined_eqs = copy(all_eqs[1])
    for pt in 2:n_points
        rd = Dict{Any,Any}()
        for v in all_vars_list[pt]
            string(v) in param_set && continue
            rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt$(pt)"))
        end
        append!(combined_eqs, [Symbolics.substitute(eq, rd) for eq in all_eqs[pt]])
    end
    cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined_eqs; union!(cvs, Symbolics.get_variables(eq)); end
    combined_vars = collect(cvs)

    n_eq = length(combined_eqs); n_var = length(combined_vars)
    n_per_pt = length(all_eqs[1])

    # ── Compute full Jacobian ───────────────────────────────────────────
    rp = randn(n_var) .* 10
    f_all = ODEParameterEstimation._compile_system_function(combined_eqs, combined_vars)
    J = ForwardDiff.jacobian(f_all, rp)
    full_rank = rank(J; atol=1e-8)
    println("  Combined: $(n_eq)×$(n_var), rank=$full_rank")

    # ── Derivative orders (strip _ptN suffix before parsing) ─────────────
    eq_ords = [begin; mo=0; for v in Symbolics.get_variables(eq)
        clean = replace(string(v), r"_pt\d+$" => "")
        p = ODEParameterEstimation.parse_derivative_variable_name(clean)
        !isnothing(p) && (mo = max(mo, p[2])); end; mo; end for eq in combined_eqs]

    # ── Greedy with different orderings ─────────────────────────────────
    function greedy(order)
        sel = Int[]; cur = zeros(eltype(J), 0, n_var); cr = 0
        for idx in order
            test = vcat(cur, J[idx:idx, :]); r = rank(test; atol=1e-8)
            if r > cr; push!(sel, idx); cur = test; cr = r; end
            cr == n_var && break
        end
        return sel
    end

    function report(label, sel)
        if length(sel) < n_var
            @printf("  %-25s: %d/%d NOT SQUARE\n", label, length(sel), n_var)
            return Inf
        end
        n_per = [count(i -> div(i-1, n_per_pt)+1 == pt, sel) for pt in 1:n_points]
        max_o = maximum(eq_ords[sel])
        err, nsol = solve_score(combined_eqs[sel], combined_vars)
        @printf("  %-25s: %d/%d per_pt=%s max_ord=%d %d sols err=%.4f\n",
            label, length(sel), n_var, n_per, max_o, nsol, err)
        return err
    end

    # Interleaved order (A1,B1,A2,B2,...)
    interleaved = Int[]
    for i in 1:n_per_pt
        for pt in 1:n_points
            push!(interleaved, (pt-1)*n_per_pt + i)
        end
    end
    err_interleaved = report("Interleaved", greedy(interleaved))

    # Interleaved + low-order preference: sort within each point by deriv order, then interleave
    sorted_per_pt = [sortperm(eq_ords[(pt-1)*n_per_pt+1:pt*n_per_pt]) .+ (pt-1)*n_per_pt for pt in 1:n_points]
    interleaved_lo = Int[]
    for i in 1:n_per_pt
        for pt in 1:n_points
            i <= length(sorted_per_pt[pt]) && push!(interleaved_lo, sorted_per_pt[pt][i])
        end
    end
    err_lo = report("Interleaved low-order", greedy(interleaved_lo))

    # Best of 20 random permutations
    best_rand_err = Inf; best_rand_label = ""
    for trial in 1:5
        sel = greedy(randperm(n_eq))
        if length(sel) == n_var
            err, nsol = solve_score(combined_eqs[sel], combined_vars)
            if err < best_rand_err
                best_rand_err = err
                n_per = [count(i -> div(i-1, n_per_pt)+1 == pt, sel) for pt in 1:n_points]
                best_rand_label = "per_pt=$n_per max_ord=$(maximum(eq_ords[sel]))"
            end
        end
    end
    @printf("  %-25s: err=%.4f %s\n", "Best of 5 random", best_rand_err, best_rand_label)

    # Summary
    println()
    @printf("  SUMMARY: 1pt=%.4f interleaved=%.4f low_ord=%.4f random=%.4f\n",
        best_1pt, err_interleaved, err_lo, best_rand_err)
    improvement = best_1pt / min(err_interleaved, err_lo, best_rand_err)
    @printf("  Best multi-point improvement: %.1f×\n", improvement)

    return (name=name, best_1pt=best_1pt, err_interleaved=err_interleaved, err_lo=err_lo, best_rand=best_rand_err)
end

# ═══════════════════════════════════════════════════════════════════════════

models = [
    ("simple", ODEParameterEstimation.simple(), 51, [0.0, 1.0]),
    ("lotka_volterra", ODEParameterEstimation.lotka_volterra(), 51, nothing),
    ("fitzhugh_nagumo", ODEParameterEstimation.fitzhugh_nagumo(), 51, nothing),
    ("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(), 51, [0.0, 10.0]),
    ("biohydrogenation", ODEParameterEstimation.biohydrogenation(), 51, [0.0, 1.0]),
    ("hiv", ODEParameterEstimation.hiv(), 51, nothing),
    ("daisy_ex3", ODEParameterEstimation.daisy_ex3(), 51, nothing),
    ("daisy_mamil3", ODEParameterEstimation.daisy_mamil3(), 51, nothing),
    ("seir", ODEParameterEstimation.seir(), 51, nothing),
    ("treatment", ODEParameterEstimation.treatment(), 51, nothing),
]

results = []
for (name, pep, nd, ti) in models
    r = run_model(name, pep; n_data=nd, t_interval=ti, n_points=2)
    !isnothing(r) && push!(results, r)
end

println("\n\n", "=" ^ 90)
println("FINAL SUMMARY — 2-point interleaved greedy")
println("=" ^ 90)
@printf("%-25s  %10s  %10s  %10s  %10s  %8s\n", "Model", "1pt_best", "Interleav", "Low-ord", "Rand20", "Improve")
println("-" ^ 85)
for r in results
    best_mp = min(r.err_interleaved, r.err_lo, r.best_rand)
    imp = r.best_1pt / max(best_mp, 1e-10)
    @printf("%-25s  %10.4f  %10.4f  %10.4f  %10.4f  %7.1f×\n",
        r.name, r.best_1pt, r.err_interleaved, r.err_lo, r.best_rand, imp)
end
