# Experiment 6: Weighted Rank-Preserving Equation Selection
#
# Compare 3 strategies for selecting a square subset from a multi-point candidate pool:
#   Strategy 1: Low-order-first greedy
#   Strategy 2: Sensitivity-weighted greedy
#   Strategy 3: UQ-weighted greedy
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/exp06_equation_selection.jl")'

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Symbolics
using LinearAlgebra
using ForwardDiff
using Printf
using HomotopyContinuation

# ═══════════════════════════════════════════════════════════════════════════
# Equation metadata
# ═══════════════════════════════════════════════════════════════════════════

struct EquationMeta
    eq::Num                    # the Symbolics equation
    point_idx::Int             # which time point (0 = structural/shared)
    is_data::Bool              # true = data equation (carries interpolation noise)
    max_deriv_order::Int       # max derivative order of variables in this equation
    source_type::Symbol        # :y_equation, :x_cascade
    deriv_order_in_chain::Int  # position in the Y or X chain
end

# ═══════════════════════════════════════════════════════════════════════════
# Build candidate pool with metadata
# ═══════════════════════════════════════════════════════════════════════════

function build_candidate_pool(pep_work, setup, t_indices; n_points=length(t_indices))
    model = pep_work.model.system; mq = pep_work.measured_quantities
    t_vec = pep_work.data_sample["t"]

    # Get template at each point
    point_eqs = []
    point_vars = []
    for t_idx in t_indices
        eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            model, mq, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
        push!(point_eqs, eqs)
        push!(point_vars, vars)
    end

    # Classify variables
    roles = ODEParameterEstimation._classify_polynomial_variables(string.(point_vars[1]), pep_work)
    param_names = Set(vn for (vn, r) in roles if r == :parameter)

    # Classify equations at point 1 (production vs oracle comparison)
    max_d = maximum(values(setup.good_deriv_level))
    st1 = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_vec[t_indices[1]], max_d + 2)
    ot1 = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, st1, t_vec[t_indices[1]], max_d + 2)
    perfect1 = Dict{Num, ODEParameterEstimation.PerfectInterpolant}()
    for (k, tc) in ot1; perfect1[k] = ODEParameterEstimation.PerfectInterpolant(t_vec[t_indices[1]], tc); end
    perf_eqs1, _ = ODEParameterEstimation.construct_equation_system_from_si_template(
        model, mq, pep_work.data_sample,
        setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
        interpolator=ODEParameterEstimation.aaad_gpr_pivot,
        time_index_set=[t_indices[1]], precomputed_interpolants=perfect1)

    true_vals1 = ODEParameterEstimation._build_true_value_vector(pep_work, point_vars[1];
        state_taylor=st1, obs_taylor=ot1, t_eval=t_vec[t_indices[1]])
    f_prod1 = ODEParameterEstimation._compile_system_function(point_eqs[1], point_vars[1])
    f_perf1 = ODEParameterEstimation._compile_system_function(perf_eqs1, point_vars[1])
    r_prod1 = any(isnan, true_vals1) ? fill(NaN, length(point_eqs[1])) : f_prod1(true_vals1)
    r_perf1 = any(isnan, true_vals1) ? fill(NaN, length(point_eqs[1])) : f_perf1(true_vals1)

    # Build equation metadata for each point
    # For deriv order: parse each variable name in the equation
    function eq_max_deriv(eq, vars_list)
        eq_vars = Symbolics.get_variables(eq)
        max_ord = 0
        for v in eq_vars
            parsed = ODEParameterEstimation.parse_derivative_variable_name(string(v))
            !isnothing(parsed) && (max_ord = max(max_ord, parsed[2]))
        end
        return max_ord
    end

    # Build the pool: for each point, rename state vars and create metadata
    all_candidates = EquationMeta[]
    all_rename_dicts = Dict{Int, Dict{Any,Any}}()

    for (pt_idx, (eqs, vars)) in enumerate(zip(point_eqs, point_vars))
        # Rename state vars for this point (point 1 keeps originals if only 1 point)
        if n_points > 1 && pt_idx > 1
            rd = Dict{Any,Any}()
            for v in vars
                string(v) in param_names && continue
                rd[v] = Symbolics.variable(Symbol(replace(string(v), r"\(.*\)$" => "") * "_pt$(pt_idx)"))
            end
            all_rename_dicts[pt_idx] = rd
            renamed_eqs = [Symbolics.substitute(eq, rd) for eq in eqs]
        else
            all_rename_dicts[pt_idx] = Dict{Any,Any}()
            renamed_eqs = eqs
        end

        # Classify each equation
        for (i, eq) in enumerate(renamed_eqs)
            # Is it a data equation? (compare prod vs perf residual for point 1 pattern)
            # For other points, same equation index has the same classification
            is_data = abs(r_prod1[i] - r_perf1[i]) > 1e-12
            max_ord = eq_max_deriv(eqs[i], vars)  # use original eq for parsing (renamed vars have _pt2 suffix)

            push!(all_candidates, EquationMeta(
                renamed_eqs[i],
                pt_idx,
                is_data,
                max_ord,
                is_data ? :y_equation : :x_cascade,
                max_ord,
            ))
        end
    end

    # Collect all variables
    all_vars_set = OrderedCollections.OrderedSet{Any}()
    for c in all_candidates; union!(all_vars_set, Symbolics.get_variables(c.eq)); end
    all_vars = collect(all_vars_set)

    # Build oracle values for the combined system
    oracle_vals = Float64[]
    for v in all_vars
        found = false
        for (pt_idx, rd) in all_rename_dicts
            rev_rd = Dict(val => key for (key, val) in rd)
            if haskey(rev_rd, v)
                orig_v = rev_rd[v]
                t_eval = t_vec[t_indices[pt_idx]]
                st = ODEParameterEstimation.compute_oracle_taylor_coefficients(pep_work, t_eval, max_d + 2)
                ot = ODEParameterEstimation.compute_observable_taylor_coefficients(pep_work, st, t_eval, max_d + 2)
                push!(oracle_vals, ODEParameterEstimation._lookup_true_value(pep_work, orig_v; state_taylor=st, obs_taylor=ot, t_eval=t_eval))
                found = true; break
            end
        end
        if !found
            t_eval = t_vec[t_indices[1]]
            push!(oracle_vals, ODEParameterEstimation._lookup_true_value(pep_work, v; state_taylor=st1, obs_taylor=ot1, t_eval=t_eval))
        end
    end

    return (candidates=all_candidates, all_vars=all_vars, oracle_vals=oracle_vals,
            param_names=param_names, point_eqs=point_eqs, point_vars=point_vars,
            rename_dicts=all_rename_dicts)
end

# ═══════════════════════════════════════════════════════════════════════════
# Equation selection strategies
# ═══════════════════════════════════════════════════════════════════════════

function select_equations_greedy(candidates, all_vars, oracle_vals; cost_fn=c->c.max_deriv_order)
    # Sort by cost (ascending = prefer low cost)
    sorted_indices = sortperm([cost_fn(c) for c in candidates])

    # Greedy selection with rank check
    selected = Int[]
    selected_eqs = Num[]
    n_vars = length(all_vars)

    for idx in sorted_indices
        c = candidates[idx]
        test_eqs = vcat(selected_eqs, c.eq)

        # Check rank increase
        if any(isnan, oracle_vals)
            # Can't check rank — just add
            push!(selected, idx)
            push!(selected_eqs, c.eq)
        else
            f = ODEParameterEstimation._compile_system_function(test_eqs, all_vars)
            J = ForwardDiff.jacobian(f, oracle_vals)
            new_rank = rank(J; atol=1e-8)
            if new_rank == length(test_eqs)
                push!(selected, idx)
                push!(selected_eqs, c.eq)
            end
        end

        length(selected_eqs) == n_vars && break
    end

    return selected
end

# ═══════════════════════════════════════════════════════════════════════════
# HC.jl solve with fixed string replacement
# ═══════════════════════════════════════════════════════════════════════════

function solve_with_hc_safe(eqs, vars)
    # Use the main codebase convert_to_hc_format (now fixed with two-pass replacement)
    ODEParameterEstimation.solve_with_hc(eqs, vars)
end

# ═══════════════════════════════════════════════════════════════════════════
# Main experiment
# ═══════════════════════════════════════════════════════════════════════════

function run_selection_experiment(name, pep; n_data=31, t_interval=nothing, n_points=2)
    println("\n", "=" ^ 100)
    println("$name (n=$n_data, $n_points points)")
    println("=" ^ 100)

    ti = !isnothing(t_interval) ? t_interval :
         !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]
    pep_data = try
        ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(datasize=n_data, time_interval=ti, nooutput=true))
    catch e; println("  SKIP: $e"); return; end
    t_var = ModelingToolkit.get_iv(pep_data.model.system)
    pep_work, _ = try; ODEParameterEstimation.transform_pep_for_estimation(pep_data, t_var); catch; (pep_data, nothing); end

    setup = try
        ODEParameterEstimation.setup_parameter_estimation(pep_work; interpolator=ODEParameterEstimation.aaad_gpr_pivot, nooutput=true)
    catch e; println("  Setup failed: $e"); return; end

    t_vec = pep_work.data_sample["t"]; n_t = length(t_vec)

    # Pick time points
    if n_points == 1
        t_indices = [setup.time_index_set[1]]
    elseif n_points == 2
        t_indices = [max(2, round(Int, n_t * 0.25)), min(n_t - 1, round(Int, n_t * 0.75))]
    else
        fracs = range(0.15, 0.85; length=n_points)
        t_indices = [max(2, min(n_t - 1, round(Int, n_t * f))) for f in fracs]
    end
    println("  Time points: ", [round(t_vec[i]; digits=2) for i in t_indices])

    # True params
    real_params = OrderedDict{String,Float64}()
    for (k, v) in pep_work.p_true
        sn = replace(string(k), "(t)" => "")
        (startswith(sn, "_trfn_") || startswith(sn, "_obs_trfn_")) || (real_params[sn] = v)
    end

    # ── 1-point baseline ────────────────────────────────────────────────
    println("\n  --- 1-point baseline ---")
    best_1pt_err = Inf
    for frac in [0.15, 0.25, 0.33, 0.5, 0.67, 0.8]
        t_idx = max(2, round(Int, n_t * frac))
        eqs, vars = ODEParameterEstimation.construct_equation_system_from_si_template(
            pep_work.model.system, pep_work.measured_quantities, pep_work.data_sample,
            setup.good_deriv_level, setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator=ODEParameterEstimation.aaad_gpr_pivot,
            time_index_set=[t_idx], precomputed_interpolants=setup.interpolants)
        solutions = try; s, _, _, _ = solve_with_hc_safe(eqs, vars); s; catch; Vector{Float64}[]; end
        roles = ODEParameterEstimation._classify_polynomial_variables(string.(vars), pep_work)
        pidxs = [i for (i, v) in enumerate(vars) if roles[string(v)] == :parameter]
        pnames = [replace(string(vars[i]), "_0" => "") for i in pidxs]
        for sol in solutions
            pvals = [sol[i] for i in pidxs]
            max_err = 0.0
            for (j, pn) in enumerate(pnames)
                haskey(real_params, pn) && (max_err = max(max_err, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
            end
            best_1pt_err = min(best_1pt_err, max_err)
        end
    end
    @printf("  Best 1-point: max_rel_err=%.3f\n", best_1pt_err)

    # ── Build candidate pool ────────────────────────────────────────────
    println("\n  --- Building $(n_points)-point candidate pool ---")
    pool = build_candidate_pool(pep_work, setup, t_indices; n_points=n_points)
    n_cand = length(pool.candidates)
    n_vars = length(pool.all_vars)
    println("  Candidates: $n_cand equations, $n_vars variables")

    # Show pool stats
    for pt in 1:n_points
        pt_eqs = filter(c -> c.point_idx == pt, pool.candidates)
        data_eqs = filter(c -> c.is_data, pt_eqs)
        struct_eqs = filter(c -> !c.is_data, pt_eqs)
        max_ord = maximum(c.max_deriv_order for c in pt_eqs; init=0)
        println("  Point $pt: $(length(pt_eqs)) eqs ($(length(data_eqs)) data + $(length(struct_eqs)) struct), max_order=$max_ord")
    end

    # ── Strategy 1: Low-order-first greedy ──────────────────────────────
    println("\n  --- Strategy 1: Low-order-first ---")
    sel1 = select_equations_greedy(pool.candidates, pool.all_vars, pool.oracle_vals;
        cost_fn=c -> c.max_deriv_order * 10 + (c.is_data ? 1 : 0))  # prefer structural at same order

    if length(sel1) == n_vars
        sel1_eqs = [pool.candidates[i].eq for i in sel1]
        sel1_orders = [pool.candidates[i].max_deriv_order for i in sel1]
        sel1_points = [pool.candidates[i].point_idx for i in sel1]
        max_ord_sel = maximum(sel1_orders)
        n_per_pt = [count(==(pt), sel1_points) for pt in 1:n_points]

        @printf("  Selected: %d eqs, max_order=%d, per_point=%s\n", length(sel1), max_ord_sel, n_per_pt)
        println("  Order histogram: ", [count(==(o), sel1_orders) for o in 0:max_ord_sel])

        # Solve with HC.jl
        solutions = try; s, _, _, _ = solve_with_hc_safe(sel1_eqs, pool.all_vars); s; catch e;
            println("  HC.jl FAILED: ", sprint(showerror, e)[1:min(80,end)]); Vector{Float64}[]; end
        println("  HC.jl: $(length(solutions)) solution(s)")

        # Parameter errors
        if !isempty(solutions)
            roles = ODEParameterEstimation._classify_polynomial_variables(string.(pool.all_vars), pep_work)
            pidxs = [i for (i, v) in enumerate(pool.all_vars) if roles[string(v)] == :parameter]
            pnames = [replace(string(pool.all_vars[i]), "_0" => "") for i in pidxs]
            best_err = Inf
            for sol in solutions
                pvals = [sol[i] for i in pidxs]
                max_err = 0.0
                for (j, pn) in enumerate(pnames)
                    haskey(real_params, pn) && (max_err = max(max_err, abs(pvals[j] - real_params[pn]) / max(abs(real_params[pn]), 1e-10)))
                end
                if max_err < best_err
                    best_err = max_err
                    println("    Best sol params:")
                    for (j, pn) in enumerate(pnames)
                        haskey(real_params, pn) && @printf("      %s: est=%.4f true=%.4f rel=%.3f\n", pn, pvals[j], real_params[pn], abs(pvals[j]-real_params[pn])/max(abs(real_params[pn]),1e-10))
                    end
                end
            end
            @printf("  Strategy 1 max_rel_err: %.3f (1-point was %.3f, improvement: %.1f×)\n",
                best_err, best_1pt_err, best_1pt_err / max(best_err, 1e-10))
        end
    else
        println("  Could not reach square: selected $(length(sel1)) / $n_vars")
    end
end

# ═══════════════════════════════════════════════════════════════════════════
# Run experiments
# ═══════════════════════════════════════════════════════════════════════════

models = [
    ("simple", ODEParameterEstimation.simple(), 21, [0.0, 1.0]),
    ("lotka_volterra", ODEParameterEstimation.lotka_volterra(), 21, nothing),
    ("forced_lv_sinusoidal", ODEParameterEstimation.forced_lv_sinusoidal(), 31, [0.0, 10.0]),
    ("fitzhugh_nagumo", ODEParameterEstimation.fitzhugh_nagumo(), 21, nothing),
    ("biohydrogenation", ODEParameterEstimation.biohydrogenation(), 21, [0.0, 1.0]),
    ("hiv", ODEParameterEstimation.hiv(), 21, nothing),
]

for (name, pep, nd, ti) in models
    run_selection_experiment(name, pep; n_data=nd, t_interval=ti, n_points=2)
end
