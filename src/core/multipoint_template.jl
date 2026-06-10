"""
Multi-Point Template System for ODEParameterEstimation

Extends the single-point SI-template pattern to N-point systems:
- Build once: duplicate template N times, rename per-point vars, rank-aware strip to square
- Evaluate cheaply: substitute interpolated data at any time point set
- Solve with HC parameter homotopy: track solutions between time point pairs
"""

using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Symbolics
using NonlinearSolve
using Printf: @sprintf

# ═══════════════════════════════════════════════════════════════════════════════
# Helper: parse derivative order, stripping _ptK suffix first
# ═══════════════════════════════════════════════════════════════════════════════

function _multipoint_deriv_order(name_str)
    # Deliberately SIAN-form only (NOT parse_jet_label): multipoint template
    # variables are always SIAN-style jet names, and the characterization tests
    # lock Differential-form inputs to order 0 here. Strips the _ptK multipoint
    # suffix first; failure contract is order 0.
    clean = replace(string(name_str), r"_pt\d+$" => "")
    parsed = parse_derivative_variable_name(clean)
    return isnothing(parsed) ? 0 : parsed[2]
end

# ═══════════════════════════════════════════════════════════════════════════════
# Variable renaming for multi-point
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _rename_per_point_variables(equations, variables, shared_names, point_index)

Rename non-shared variables by appending `_ptK` suffix.
Point 1 is left unchanged. Returns `(renamed_equations, rename_dict)`.
"""
function _rename_per_point_variables(equations::Vector, variables::Vector,
        shared_names::Set{String}, point_index::Int)
    if point_index == 1
        return equations, Dict{Any, Any}()
    end
    rd = Dict{Any, Any}()
    for v in variables
        string(v) in shared_names && continue
        new_name = replace(string(v), r"\(.*\)$" => "") * "_pt$(point_index)"
        rd[v] = Symbolics.variable(Symbol(new_name))
    end
    renamed_eqs = [Symbolics.substitute(eq, rd) for eq in equations]
    return renamed_eqs, rd
end

# ═══════════════════════════════════════════════════════════════════════════════
# Variable classification for multi-point
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _classify_solve_vs_data(all_symb_vars, inst_var_names_set, pep_data)

Partition symbolic template variables into solve_vars and data_vars by comparing
the symbolic variable set against the instantiated (post-substitution) variable set.

Data variables are those present in the symbolic equations but absent from the
instantiated equations — they got substituted with numerical values. This approach
is naming-convention-agnostic and works regardless of whether SIAN uses y-names
or x-names for observables.
"""
function _classify_solve_vs_data(all_symb_vars::Vector, inst_var_names_set::Set{String},
        pep_data::ParameterEstimationProblem)

    # Name-based classification for parameter identification
    roles = _classify_polynomial_variables(
        [replace(string(v), r"_pt\d+$" => "") for v in all_symb_vars], pep_data)

    solve_vars = Any[]
    data_vars = Any[]
    param_indices = Int[]

    for (i, v) in enumerate(all_symb_vars)
        v_name = string(v)
        clean_name = replace(v_name, r"_pt\d+$" => "")

        # A variable is "data" if its clean name is NOT in the instantiated variable set
        # (it disappeared after numerical data substitution) OR if it's a transcendental
        is_data = !(clean_name in inst_var_names_set) ||
                  contains(clean_name, "_trfn_")

        if is_data
            push!(data_vars, v)
        else
            push!(solve_vars, v)
            role = get(roles, clean_name, :state_derivative)
            if role == :parameter
                push!(param_indices, length(solve_vars))
            end
        end
    end

    return solve_vars, data_vars, param_indices
end

# ═══════════════════════════════════════════════════════════════════════════════
# Rank-aware top-down stripping
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _rank_aware_topdown_strip(equations, variables, eq_metadata; rank_atol, diagnostics)

Remove highest-order structural equations from an overdetermined system,
checking Jacobian rank at each step. Returns a `BitVector` mask of kept equations.

Algorithm:
1. Sort structural equations by descending derivative order
2. For each: tentatively remove + cascade orphaned data equations
3. Check rank of remaining Jacobian rows
4. If rank dropped below remaining var count → restore and skip
5. If square and full rank → done
6. Fallback: greedy row selection (data-first, low-order preference)
"""
function _rank_aware_topdown_strip(equations::Vector, variables::Vector,
        eq_metadata::Vector; rank_atol::Float64 = 1e-8, diagnostics::Bool = false,
        n_rank_probes::Int = 3)

    n_eq = length(equations)
    n_var = length(variables)

    # Pre-compute Jacobian at multiple random points, take max rank
    f_combined = _compile_system_function(equations, variables)
    J_full = nothing
    best_full_rank = 0
    # Seeded rank probes (postcampaign review P1): equation-stripping decisions
    # must be deterministic; the noise-frontier twin already seeds identically.
    probe_rng = MersenneTwister(0x9f4d0329)
    for _ in 1:n_rank_probes
        rand_point = randn(probe_rng, n_var) .* 10.0
        J_probe = ForwardDiff.jacobian(f_combined, rand_point)
        r = rank(J_probe; atol = rank_atol)
        if r > best_full_rank
            best_full_rank = r
            J_full = J_probe
        end
    end

    if diagnostics
        println("  [MPT] Full Jacobian: $(size(J_full)), rank=$best_full_rank / $n_var")
    end

    struct_indices = [i for (i, m) in enumerate(eq_metadata) if !m.is_data]
    data_indices = [i for (i, m) in enumerate(eq_metadata) if m.is_data]
    struct_by_order = sort(struct_indices; by = i -> -eq_metadata[i].order)

    kept = trues(n_eq)

    for idx in struct_by_order
        saved_kept = copy(kept)
        kept[idx] = false
        m = eq_metadata[idx]

        # Cascade: remove data equations for orphaned variables
        struct_vars = Set{Any}()
        for i in 1:n_eq
            kept[i] && !eq_metadata[i].is_data && union!(struct_vars, Symbolics.get_variables(equations[i]))
        end
        cascaded = Int[]
        for di in data_indices
            !kept[di] && continue
            data_var = first(Symbolics.get_variables(equations[di]))
            if !(data_var in struct_vars)
                kept[di] = false
                push!(cascaded, di)
            end
        end

        # Compute remaining variable count
        remaining_var_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq
            kept[i] && union!(remaining_var_set, Symbolics.get_variables(equations[i]))
        end
        remaining_var_count = length(remaining_var_set)
        remaining_eq_count = count(kept)

        # Rank check
        kept_rows = findall(kept)
        new_rank = isempty(kept_rows) ? 0 : rank(J_full[kept_rows, :]; atol = rank_atol)

        if new_rank < remaining_var_count
            # Removal broke independence — restore
            kept .= saved_kept
            if diagnostics
                println("    [MPT] -eq$idx (pt$(m.point) ord=$(m.order)) → RANK DROP ($new_rank < $remaining_var_count). KEPT.")
            end
        elseif remaining_eq_count == remaining_var_count && new_rank == remaining_var_count
            # Square and full rank — success
            if diagnostics
                println("    [MPT] -eq$idx (pt$(m.point) ord=$(m.order)) → $remaining_eq_count eqs, $remaining_var_count vars → SQUARE!")
            end
            break
        elseif remaining_eq_count < remaining_var_count
            # Underdetermined — restore
            kept .= saved_kept
            if diagnostics
                println("    [MPT] -eq$idx (pt$(m.point) ord=$(m.order)) → UNDERDETERMINED. KEPT.")
            end
            break
        else
            # Still overdetermined, removal was safe
            if diagnostics
                println("    [MPT] -eq$idx (pt$(m.point) ord=$(m.order)) → $remaining_eq_count eqs, $remaining_var_count vars (Δ=$(remaining_eq_count - remaining_var_count))")
            end
        end
    end

    # Check if we reached square
    remaining_eq_count = count(kept)
    remaining_var_set = OrderedCollections.OrderedSet{Any}()
    for i in 1:n_eq
        kept[i] && union!(remaining_var_set, Symbolics.get_variables(equations[i]))
    end
    remaining_var_count = length(remaining_var_set)

    if remaining_eq_count > remaining_var_count
        # Still overdetermined — greedy row selection fallback
        if diagnostics
            println("  [MPT] Greedy fallback: $remaining_eq_count eqs → $remaining_var_count vars")
        end
        kept_rows = findall(kept)
        sorted_kept = sort(kept_rows; by = i -> (eq_metadata[i].is_data ? -1 : 0, eq_metadata[i].order, eq_metadata[i].point))

        final_sel = Int[]
        cur_rows = zeros(eltype(J_full), 0, size(J_full, 2))
        cur_rank = 0
        for idx in sorted_kept
            test = vcat(cur_rows, J_full[idx:idx, :])
            r = rank(test; atol = rank_atol)
            if r > cur_rank
                push!(final_sel, idx)
                cur_rows = test
                cur_rank = r
            end
            cur_rank == remaining_var_count && break
        end
        kept .= false
        for idx in final_sel
            kept[idx] = true
        end
        if diagnostics
            println("  [MPT] Greedy selected $(length(final_sel)) / $remaining_var_count equations")
        end
    end

    return kept
end

# ═══════════════════════════════════════════════════════════════════════════════
# Sensitivity-aware greedy stripping
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _sensitivity_aware_strip(equations, variables, eq_metadata; rank_atol, diagnostics, n_rank_probes)

Greedy equation stripping that minimizes Jacobian condition number at each step,
rather than blindly removing highest-order equations. Returns a `BitVector` mask.

Algorithm:
1. Compute Jacobian at random probe points (like topdown)
2. Greedy loop: at each step, try removing each candidate equation
   and pick the removal that results in the lowest κ(J_x_remaining)
3. Cascade orphaned data equations (same as topdown)
4. Stop when square and full rank
"""
function _sensitivity_aware_strip(equations::Vector, variables::Vector,
        eq_metadata::Vector; rank_atol::Float64 = 1e-8, diagnostics::Bool = false,
        n_rank_probes::Int = 3)

    n_eq = length(equations)
    n_var = length(variables)

    # Pre-compute Jacobian at multiple random points, keep best
    f_combined = _compile_system_function(equations, variables)
    J_full = nothing
    best_full_rank = 0
    # Seeded rank probes (postcampaign review P1): equation-stripping decisions
    # must be deterministic; the noise-frontier twin already seeds identically.
    probe_rng = MersenneTwister(0x9f4d0329)
    for _ in 1:n_rank_probes
        rand_point = randn(probe_rng, n_var) .* 10.0
        J_probe = ForwardDiff.jacobian(f_combined, rand_point)
        r = rank(J_probe; atol = rank_atol)
        if r > best_full_rank
            best_full_rank = r
            J_full = J_probe
        end
    end

    if diagnostics
        println("  [MPT-SA] Full Jacobian: $(size(J_full)), rank=$best_full_rank / $n_var")
    end

    struct_indices = Set(i for (i, m) in enumerate(eq_metadata) if !m.is_data)
    data_indices = [i for (i, m) in enumerate(eq_metadata) if m.is_data]

    kept = trues(n_eq)

    # Helper: compute condition number for a given kept mask
    # Uses the kept rows of J_full, considering only columns with significant entries
    function _cond_for_kept(mask)
        rows = findall(mask)
        isempty(rows) && return Inf
        J_sub = J_full[rows, :]
        # Keep columns where max abs value > threshold (avoid pure-zero columns)
        col_max = vec(maximum(abs, J_sub; dims = 1))
        thresh = maximum(col_max) * 1e-14
        col_mask = col_max .> thresh
        count(col_mask) == 0 && return Inf
        J_active = J_sub[:, col_mask]
        n_r, n_c = size(J_active)
        n_r < n_c && return Inf  # underdetermined
        svs = try
            svdvals(J_active)
        catch
            return Inf
        end
        isempty(svs) && return Inf
        # Use ratio of largest to smallest singular value
        # Even if rank-deficient, return the ratio (large but finite) so we can compare
        return svs[1] / max(svs[end], 1e-300)
    end

    # Helper: cascade orphaned data equations and compute remaining variable count
    function _cascade_and_count!(mask)
        struct_vars = Set{Any}()
        for i in 1:n_eq
            mask[i] && !eq_metadata[i].is_data && union!(struct_vars, Symbolics.get_variables(equations[i]))
        end
        cascaded = 0
        for di in data_indices
            !mask[di] && continue
            data_var = first(Symbolics.get_variables(equations[di]))
            if !(data_var in struct_vars)
                mask[di] = false
                cascaded += 1
            end
        end
        remaining_var_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq
            mask[i] && union!(remaining_var_set, Symbolics.get_variables(equations[i]))
        end
        return length(remaining_var_set), count(mask), cascaded
    end

    max_iters = n_eq  # safety bound
    for iter in 1:max_iters
        remaining_eq_count = count(kept)
        remaining_var_set = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq
            kept[i] && union!(remaining_var_set, Symbolics.get_variables(equations[i]))
        end
        remaining_var_count = length(remaining_var_set)

        if remaining_eq_count <= remaining_var_count
            break  # square or underdetermined — done
        end

        # Try removing each candidate structural equation, score by κ
        best_idx = -1
        best_cond = Inf
        best_mask = nothing

        candidates = [i for i in 1:n_eq if kept[i] && i in struct_indices]
        for idx in candidates
            trial = copy(kept)
            trial[idx] = false
            # Cascade orphaned data equations
            nv, neq, casc = _cascade_and_count!(trial)

            if neq < nv
                continue  # would make underdetermined — skip
            end

            # Check rank — use multiple probes if available, accept if rank >= nv
            trial_rows = findall(trial)
            trial_rank = rank(J_full[trial_rows, :]; atol = rank_atol)
            if trial_rank < nv
                continue  # rank drop at all probes — skip
            end

            c = _cond_for_kept(trial)
            if c < best_cond
                best_cond = c
                best_idx = idx
                best_mask = trial
            end
        end

        if best_idx < 0
            # No safe removal found — fall back to topdown for remaining equations
            if diagnostics
                println("  [MPT-SA] No safe removal at iter $iter ($(count(kept)) eqs, $remaining_var_count vars) — falling back to topdown for remaining")
            end
            # Use topdown logic for remaining stripping: remove highest-order structural equation
            fallback_candidates = sort(
                [i for i in 1:n_eq if kept[i] && i in struct_indices];
                by = i -> -eq_metadata[i].order)
            fallback_done = false
            for idx in fallback_candidates
                saved = copy(kept)
                kept[idx] = false
                nv2, neq2, _ = _cascade_and_count!(kept)
                trial_rows = findall(kept)
                trial_rank = isempty(trial_rows) ? 0 : rank(J_full[trial_rows, :]; atol = rank_atol)
                if trial_rank < nv2
                    kept .= saved
                    continue
                end
                if neq2 == nv2
                    if diagnostics
                        println("    [MPT-SA] topdown fallback -eq$idx (ord=$(eq_metadata[idx].order)) → $neq2 eqs, $nv2 vars → SQUARE!")
                    end
                    fallback_done = true
                    break
                elseif neq2 < nv2
                    kept .= saved
                    continue
                else
                    if diagnostics
                        println("    [MPT-SA] topdown fallback -eq$idx (ord=$(eq_metadata[idx].order)) → $neq2 eqs, $nv2 vars")
                    end
                end
            end
            if !fallback_done
                break  # truly stuck
            end
            # Check if we're square now
            nv_final = 0
            for i in 1:n_eq
                kept[i] && (nv_final += 1)
            end
            remaining_var_set_f = OrderedCollections.OrderedSet{Any}()
            for i in 1:n_eq
                kept[i] && union!(remaining_var_set_f, Symbolics.get_variables(equations[i]))
            end
            if nv_final <= length(remaining_var_set_f)
                break
            end
            continue  # keep going with sensitivity-aware for next iteration
        end

        m = eq_metadata[best_idx]
        kept .= best_mask
        remaining_eq_count = count(kept)
        remaining_var_set2 = OrderedCollections.OrderedSet{Any}()
        for i in 1:n_eq
            kept[i] && union!(remaining_var_set2, Symbolics.get_variables(equations[i]))
        end
        remaining_var_count = length(remaining_var_set2)

        if diagnostics
            println("    [MPT-SA] -eq$best_idx (pt$(m.point) ord=$(m.order)) → $remaining_eq_count eqs, $remaining_var_count vars, κ=$(@sprintf("%.2e", best_cond))$(remaining_eq_count == remaining_var_count ? " → SQUARE!" : "")")
        end

        if remaining_eq_count == remaining_var_count
            break  # square — done
        end
    end

    # If still overdetermined, use the same greedy fallback as topdown
    remaining_eq_count = count(kept)
    remaining_var_set = OrderedCollections.OrderedSet{Any}()
    for i in 1:n_eq
        kept[i] && union!(remaining_var_set, Symbolics.get_variables(equations[i]))
    end
    remaining_var_count = length(remaining_var_set)

    if remaining_eq_count > remaining_var_count
        if diagnostics
            println("  [MPT-SA] Greedy fallback: $remaining_eq_count eqs → $remaining_var_count vars")
        end
        kept_rows = findall(kept)
        sorted_kept = sort(kept_rows; by = i -> (eq_metadata[i].is_data ? -1 : 0, eq_metadata[i].order, eq_metadata[i].point))
        final_sel = Int[]
        cur_rows = zeros(eltype(J_full), 0, size(J_full, 2))
        cur_rank = 0
        for idx in sorted_kept
            test = vcat(cur_rows, J_full[idx:idx, :])
            r = rank(test; atol = rank_atol)
            if r > cur_rank
                push!(final_sel, idx)
                cur_rows = test
                cur_rank = r
            end
            cur_rank == remaining_var_count && break
        end
        kept .= false
        for idx in final_sel
            kept[idx] = true
        end
        if diagnostics
            println("  [MPT-SA] Greedy selected $(length(final_sel)) / $remaining_var_count equations")
        end
    end

    return kept
end

# ═══════════════════════════════════════════════════════════════════════════════
# Time point selection by Jacobian conditioning
# ═══════════════════════════════════════════════════════════════════════════════

"""
    select_time_points_by_conditioning(pep_data, setup, si_template; n_candidates=15,
        n_points=2, strip_strategy=:sensitivity, diagnostics=false)

Scan candidate time point pairs and return the pair whose multipoint system
has the lowest Jacobian condition number κ(J_x).

Returns `(best_indices::Vector{Int}, best_cond::Float64, all_results::Vector)`.
"""
function select_time_points_by_conditioning(
    pep_data::ParameterEstimationProblem,
    setup::NamedTuple,
    si_template;
    n_candidates::Int = 15,
    n_points::Int = 2,
    strip_strategy::Symbol = :sensitivity,
    margin::Float64 = 0.05,
    diagnostics::Bool = false,
)
    t_vec = pep_data.data_sample["t"]
    n_t = length(t_vec)

    # Generate candidate time index pairs
    lo = max(2, round(Int, n_t * margin))
    hi = min(n_t - 1, round(Int, n_t * (1.0 - margin)))

    candidates = Vector{Int}[]
    # Evenly spaced candidates
    for f1 in range(0.1, 0.45; length = 5)
        for f2 in range(0.55, 0.9; length = 5)
            i1 = clamp(round(Int, n_t * f1), lo, hi)
            i2 = clamp(round(Int, n_t * f2), lo, hi)
            i1 != i2 && push!(candidates, [i1, i2])
        end
    end
    # Deduplicate
    unique!(candidates)
    # Limit
    if length(candidates) > n_candidates
        candidates = candidates[1:n_candidates]
    end

    results = @NamedTuple{indices::Vector{Int}, t_values::Vector{Float64}, cond::Float64}[]
    best_cond = Inf
    best_indices = candidates[1]

    for (ci, idx_pair) in enumerate(candidates)
        t_values = [t_vec[i] for i in idx_pair]
        try
            # Build template with this pair's probe points
            mpt = build_multipoint_template(pep_data, setup, si_template;
                n_points = n_points, diagnostics = false, strip_strategy = strip_strategy)

            # Evaluate Jacobian at these specific time points
            f_sys = _compile_system_function(mpt.stripped_equations, vcat(mpt.solve_vars, mpt.data_vars))
            # Use random solve vars but realistic data magnitude
            x_probe = vcat(randn(length(mpt.solve_vars)) .* 10.0, randn(length(mpt.data_vars)) .* 10.0)
            J = ForwardDiff.jacobian(f_sys, x_probe)
            n_solve = length(mpt.solve_vars)
            J_x = J[:, 1:n_solve]
            svs = svdvals(J_x)
            c = isempty(svs) ? Inf : svs[1] / max(svs[end], 1e-300)

            push!(results, (indices = idx_pair, t_values = t_values, cond = c))

            if diagnostics
                println("  [TP-SCAN] pair $(idx_pair) → t=$(round.(t_values; digits=2)), κ=$(@sprintf("%.2e", c))")
            end

            if c < best_cond
                best_cond = c
                best_indices = idx_pair
            end
        catch e
            if diagnostics
                println("  [TP-SCAN] pair $(idx_pair) → FAILED: $e")
            end
        end
    end

    sort!(results; by = r -> r.cond)

    if diagnostics
        println("  [TP-SCAN] Best: indices=$(best_indices), t=$(round.([t_vec[i] for i in best_indices]; digits=2)), κ=$(@sprintf("%.2e", best_cond))")
    end

    return best_indices, best_cond, results
end

# ═══════════════════════════════════════════════════════════════════════════════
# Build: construct multi-point template
# ═══════════════════════════════════════════════════════════════════════════════

"""
    build_multipoint_template(pep_data, setup, si_template; n_points=2, diagnostics=false)

Build a multi-point polynomial template from the single-point SI template.

# Algorithm
1. Evaluate SI template at N well-separated probe points
2. Classify variables (shared params vs per-point state/data)
3. Rename per-point variables with `_ptK` suffix
4. Combine and run rank-aware top-down stripping
5. Build the combined SYMBOLIC system (same renaming, no data substitution)
6. Apply stripping mask to symbolic system
7. Classify stripped vars into solve_vars vs data_vars
"""
function build_multipoint_template(
        pep_data::ParameterEstimationProblem,
        setup::NamedTuple,
        si_template;
        n_points::Int = 2,
        diagnostics::Bool = false,
        rank_atol::Float64 = 1e-8,
        strip_strategy::Symbol = :topdown,  # :topdown or :sensitivity
)
    model = pep_data.model.system
    mq = pep_data.measured_quantities
    data_sample = pep_data.data_sample
    t_vec = data_sample["t"]
    n_t = length(t_vec)

    # Template DD for observable mapping
    template_DD = hasproperty(si_template, :template_DD) ? si_template.template_DD : setup.good_DD

    # Choose well-separated probe points
    fracs = n_points == 1 ? [0.5] :
            n_points == 2 ? [0.25, 0.75] :
            collect(range(0.15, 0.85; length = n_points))
    probe_indices = [max(2, min(n_t - 1, round(Int, n_t * f))) for f in fracs]

    if diagnostics
        println("[MPT] Building $(n_points)-point template, probes at t=$(round.(t_vec[probe_indices]; digits=3))")
    end

    # ── Step 1: Evaluate at probe points ──────────────────────────────
    all_inst_eqs = Vector{Vector}()  # instantiated equations per point
    all_inst_vars = Vector{Vector}()
    all_symb_eqs = Vector{Vector}()  # symbolic equations per point (from template)

    for t_idx in probe_indices
        inst_eqs, inst_vars = construct_equation_system_from_si_template(
            model, mq, data_sample, setup.good_deriv_level,
            setup.good_udict, setup.good_varlist, setup.good_DD;
            interpolator = aaad_gpr_pivot, time_index_set = [t_idx],
            precomputed_interpolants = setup.interpolants,
            si_template = si_template)
        push!(all_inst_eqs, inst_eqs)
        push!(all_inst_vars, inst_vars)
    end

    # Get the symbolic template equations (before data substitution)
    symb_template_eqs = si_template.equations

    # ── Step 2: Classify variables ────────────────────────────────────
    roles = _classify_polynomial_variables(string.(all_inst_vars[1]), pep_data)
    param_set = Set(vn for (vn, r) in roles if r == :parameter)

    if diagnostics
        println("[MPT] Shared parameters: ", param_set)
        println("[MPT] Per-point instantiated: $(length(all_inst_eqs[1])) eqs, $(length(all_inst_vars[1])) vars")
    end

    # ── Step 3: Build name mapping for symbolic template variables ────
    # The symbolic template has variables with complex Symbolics names
    # (e.g. "Differential(t)(y1(t))"). We need to map each to a clean
    # SIAN-style name for proper renaming.
    #
    # Solve vars: already have clean names (they're the same objects as inst_vars)
    # Data vars: identified from DD.obs_lhs, mapped to clean names via (obs_idx, order)

    symb_template_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in symb_template_eqs
        union!(symb_template_vars_set, Symbolics.get_variables(eq))
    end
    symb_template_vars = collect(symb_template_vars_set)

    # Build clean name mapping for ALL template variables
    inst_var_name_set = Set(string(v) for v in all_inst_vars[1])
    symb_to_clean = Dict{Any, String}()
    for v in symb_template_vars
        sname = string(v)
        if sname in inst_var_name_set
            # Solve variable — already has a clean name
            symb_to_clean[v] = sname
        else
            # Data variable — look up in DD.obs_lhs
            found = false
            for (level_idx, level_vars) in enumerate(template_DD.obs_lhs)
                for (obs_idx, lhs_v) in enumerate(level_vars)
                    if lhs_v === v || isequal(lhs_v, v)
                        deriv_order = level_idx - 1
                        obs_name = replace(string(mq[obs_idx].lhs), r"\(.*\)$" => "")
                        symb_to_clean[v] = "$(obs_name)_$(deriv_order)"
                        found = true
                        break
                    end
                end
                found && break
            end
            if !found
                # Fallback: use sanitized string name
                clean = replace(sname, r"\(.*?\)" => "")
                clean = replace(clean, r"[^a-zA-Z0-9_]" => "_")
                symb_to_clean[v] = clean
            end
        end
    end

    if diagnostics
        n_data_mapped = count(v -> !(string(v) in inst_var_name_set), symb_template_vars)
        println("[MPT] Template vars: $(length(symb_template_vars)) total, $n_data_mapped data vars mapped")
    end

    # ── Step 4: Rename + combine both instantiated and symbolic equations ─
    combined_inst_eqs = Num[]
    combined_symb_eqs = Num[]
    eq_meta = @NamedTuple{point::Int, is_data::Bool, order::Int}[]

    for pt in 1:n_points
        # Rename instantiated equations (clean names, proven approach from exp09)
        inst_renamed, _ = _rename_per_point_variables(
            all_inst_eqs[pt], all_inst_vars[pt], param_set, pt)

        # Rename symbolic equations using the clean name mapping
        # For point 1: rename data vars to clean names (solve vars already have clean names)
        # For point k > 1: rename ALL non-shared vars to clean_name_ptK
        rd = Dict{Any, Any}()
        for v in symb_template_vars
            sname = string(v)
            clean = get(symb_to_clean, v, sname)
            if pt == 1
                # Only rename if the variable has a complex name (data var)
                if sname != clean && !(clean in param_set)
                    rd[v] = Symbolics.variable(Symbol(clean))
                end
            else
                clean in param_set && continue
                rd[v] = Symbolics.variable(Symbol(clean * "_pt$(pt)"))
            end
        end
        symb_renamed = isempty(rd) ? collect(symb_template_eqs) :
                       [Symbolics.substitute(eq, rd) for eq in symb_template_eqs]

        # The instantiated system may have fewer equations than the symbolic template
        # (e.g., _trfn_ equations become trivial 0≈0 after substitution and are removed).
        # We need to match symbolic equations to their instantiated counterparts.
        # Strategy: the instantiation preserves equation ORDER but drops some.
        # Match by checking which symbolic equations, after data substitution, produce
        # equations with the same variable set as the instantiated ones.
        #
        # Simple approach: if counts match, 1:1 correspondence. If not, keep only
        # the first len(inst) symbolic equations as a safe fallback, since the removed
        # equations are typically at the end (trivial _trfn_ equations).
        n_inst = length(inst_renamed)
        n_symb = length(symb_renamed)
        if n_inst == n_symb
            # Perfect 1:1 correspondence
            for (i, eq) in enumerate(inst_renamed)
                push!(combined_inst_eqs, eq)
                nv = length(Symbolics.get_variables(eq))
                mo = maximum(_multipoint_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point = pt, is_data = nv == 1, order = mo))
            end
            append!(combined_symb_eqs, symb_renamed)
        else
            # Mismatch: instantiation removed some equations (typically _trfn_ trivials).
            # Build a mapping: for each inst equation, find its symbolic counterpart
            # by matching variable overlap after substitution.
            # Fallback: just use inst equations as both inst and symb (lose symbolic
            # data vars, but at least the system works).
            if diagnostics
                println("[MPT] Equation count mismatch: $n_inst inst vs $n_symb symb (transcendental model?)")
            end
            for (i, eq) in enumerate(inst_renamed)
                push!(combined_inst_eqs, eq)
                nv = length(Symbolics.get_variables(eq))
                mo = maximum(_multipoint_deriv_order(v) for v in Symbolics.get_variables(eq))
                push!(eq_meta, (point = pt, is_data = nv == 1, order = mo))
            end
            # For symbolic: use instantiated equations as symbolic stand-ins.
            # This means no parameter homotopy for transcendental models (data vars
            # are already substituted), but direct solve still works.
            append!(combined_symb_eqs, inst_renamed)
        end
    end

    inst_cvs = OrderedCollections.OrderedSet{Any}()
    for eq in combined_inst_eqs
        union!(inst_cvs, Symbolics.get_variables(eq))
    end
    combined_inst_vars = collect(inst_cvs)

    if diagnostics
        println("[MPT] Combined instantiated: $(length(combined_inst_eqs)) eqs, $(length(combined_inst_vars)) vars")
    end

    # ── Step 5: Strip (using instantiated system for Jacobian) ────────
    if diagnostics
        println("[MPT] Running $(strip_strategy == :sensitivity ? "sensitivity-aware" : "rank-aware top-down") stripping...")
    end
    kept = if strip_strategy == :sensitivity
        _sensitivity_aware_strip(combined_inst_eqs, combined_inst_vars, eq_meta;
            rank_atol = rank_atol, diagnostics = diagnostics)
    else
        _rank_aware_topdown_strip(combined_inst_eqs, combined_inst_vars, eq_meta;
            rank_atol = rank_atol, diagnostics = diagnostics)
    end

    n_kept = count(kept)
    kept_equation_indices = findall(kept)
    dropped_equation_indices = findall(.!kept)
    if diagnostics
        println("[MPT] Stripping result: $n_kept / $(length(combined_inst_eqs)) equations kept")
    end

    # ── Step 6: Apply mask to symbolic equations ──────────────────────
    stripped_symb_eqs = combined_symb_eqs[kept]
    stripped_meta = eq_meta[kept]

    # Collect all variables in stripped symbolic system
    stripped_vars_set = OrderedCollections.OrderedSet{Any}()
    for eq in stripped_symb_eqs
        union!(stripped_vars_set, Symbolics.get_variables(eq))
    end
    stripped_all_vars = collect(stripped_vars_set)

    # ── Step 7: Classify into solve_vars vs data_vars ─────────────────
    # Data variables are those present in symbolic equations but absent from
    # the instantiated combined variable set (they disappeared after data subst)
    combined_inst_var_names = Set(string(v) for v in combined_inst_vars)
    solve_vars, data_vars, param_indices = _classify_solve_vs_data(
        stripped_all_vars, combined_inst_var_names, pep_data)

    # Compute clean parameter names
    param_names = String[]
    for i in param_indices
        clean = replace(string(solve_vars[i]), r"_0$" => "")
        clean = replace(clean, r"\(.*\)$" => "")
        push!(param_names, clean)
    end

    # Compute per-point data variable index lists (may not be contiguous)
    per_point_data_indices = [Int[] for _ in 1:n_points]
    for (i, dv) in enumerate(data_vars)
        name = string(dv)
        assigned = false
        for pt in 2:n_points
            if endswith(name, "_pt$pt")
                push!(per_point_data_indices[pt], i)
                assigned = true
                break
            end
        end
        if !assigned
            push!(per_point_data_indices[1], i)
        end
    end

    # Convert to ranges (they should be contiguous after proper ordering, but use full range)
    per_point_ranges = UnitRange{Int}[]
    for pt in 1:n_points
        indices = per_point_data_indices[pt]
        if isempty(indices)
            push!(per_point_ranges, 1:0)
        else
            push!(per_point_ranges, first(indices):last(indices))
        end
    end

    is_square = length(stripped_symb_eqs) == length(solve_vars)
    if diagnostics
        println("[MPT] Final: $(length(stripped_symb_eqs)) eqs, $(length(solve_vars)) solve_vars, $(length(data_vars)) data_vars")
        println("[MPT] Square: $is_square")
        println("[MPT] Params ($(length(param_indices))): ", param_names)
    end

    if !is_square
        @warn "[MPT] Multi-point template is NOT square: $(length(stripped_symb_eqs)) eqs vs $(length(solve_vars)) solve_vars"
    end

    return MultiPointTemplate(
        n_points,
        si_template,
        combined_symb_eqs,
        stripped_symb_eqs,
        solve_vars,
        data_vars,
        param_indices,
        param_names,
        stripped_meta,
        length(combined_inst_eqs),
        Int[kept_equation_indices...],
        Int[dropped_equation_indices...],
        per_point_ranges,
        template_DD,
        mq,
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Evaluate: substitute data at specific time points
# ═══════════════════════════════════════════════════════════════════════════════

"""
    evaluate_multipoint_template(mpt, time_indices, interpolants, data_sample; diagnostics)

Evaluate the pre-computed template at specific time point indices.
Returns a `MultiPointEvaluation` with data values ready for HC.jl.
"""
function evaluate_multipoint_template(
        mpt::MultiPointTemplate,
        time_indices::Vector{Int},
        interpolants::Dict,
        data_sample;
        diagnostics::Bool = false,
)
    eval_t0 = time()
    stage_seconds = OrderedDict{Symbol, Float64}()
    nth_deriv_calls = 0
    nth_deriv_seconds = 0.0
    trfn_eval_seconds = 0.0
    parse_lookup_seconds = 0.0
    max_deriv_order = 0
    @assert length(time_indices) == mpt.n_points "Expected $(mpt.n_points) time indices, got $(length(time_indices))"

    t_vec = data_sample["t"]
    t_values = Float64[t_vec[i] for i in time_indices]
    data_values = Float64[]

    DD = mpt.template_DD
    mq = mpt.measured_quantities

    # Build observable name → index mapping from measured_quantities
    obs_name_to_idx = _timed_detail_stage!(stage_seconds, :observable_name_map) do
        mapping = Dict{String, Int}()
        for (idx, mq_eq) in enumerate(mq)
            obs_name = replace(string(mq_eq.lhs), r"\(.*\)$" => "")
            mapping[obs_name] = idx
        end
        mapping
    end

    for (pt, t_idx) in enumerate(time_indices)
        t_point = t_values[pt]
        range = mpt.per_point_data_var_ranges[pt]

        for dv_idx in range
            dv = mpt.data_vars[dv_idx]
            dv_name = string(dv)

            # Strip _ptK suffix for lookup
            clean_name = replace(dv_name, r"_pt\d+$" => "")

            # Try _trfn_ evaluation first
            t_trfn = time()
            trfn_val = evaluate_trfn_template_variable(clean_name, t_point)
            if isnothing(trfn_val)
                trfn_val = evaluate_obs_trfn_template_variable(clean_name, t_point)
            end
            trfn_eval_seconds += time() - t_trfn
            if !isnothing(trfn_val)
                push!(data_values, Float64(trfn_val))
                continue
            end

            # Parse the clean SIAN-style name (e.g., "y1_0" → base="y1", order=0)
            t_parse = time()
            parsed = parse_derivative_variable_name(clean_name)
            if isnothing(parsed)
                parse_lookup_seconds += time() - t_parse
                # Fail fast: NaN (not 0.0) — the downstream all(isfinite, …)
                # guards reject this combo instead of solving a wrong system.
                @warn "[MPT-EVAL] Cannot parse data variable: $dv_name (clean=$clean_name)"
                push!(data_values, NaN)
                continue
            end
            base_name, deriv_order = parsed
            max_deriv_order = max(max_deriv_order, deriv_order)

            # Find observable index by matching base name against measured quantities
            obs_idx = get(obs_name_to_idx, string(base_name), nothing)
            if isnothing(obs_idx)
                # Fallback: try y1/y2/etc. pattern
                m = match(r"^y(\d+)$", string(base_name))
                if !isnothing(m)
                    obs_idx = parse(Int, m.captures[1])
                end
            end
            parse_lookup_seconds += time() - t_parse

            val = nothing
            if !isnothing(obs_idx) && obs_idx <= length(mq)
                obs_rhs = ModelingToolkit.diff2term(mq[obs_idx].rhs)
                if haskey(interpolants, obs_rhs)
                    t_nth = time()
                    val = nth_deriv(x -> interpolants[obs_rhs](x), deriv_order, t_point)
                    nth_deriv_seconds += time() - t_nth
                    nth_deriv_calls += 1
                else
                    obs_lhs_wrapped = Symbolics.wrap(mq[obs_idx].lhs)
                    if haskey(interpolants, obs_lhs_wrapped)
                        t_nth = time()
                        val = nth_deriv(x -> interpolants[obs_lhs_wrapped](x), deriv_order, t_point)
                        nth_deriv_seconds += time() - t_nth
                        nth_deriv_calls += 1
                    end
                end
            end

            if isnothing(val)
                # Fail fast: NaN (not 0.0) — rejected by the all(isfinite, …) guards.
                @warn "[MPT-EVAL] No interpolant for $dv_name (base=$base_name, order=$deriv_order, obs_idx=$obs_idx)"
                push!(data_values, NaN)
            else
                push!(data_values, Float64(val))
            end
        end
    end

    stage_seconds[:transcendental_lookup] = trfn_eval_seconds
    stage_seconds[:parse_and_lookup] = parse_lookup_seconds
    stage_seconds[:nth_deriv] = nth_deriv_seconds
    total_seconds = time() - eval_t0
    accounted = sum(values(stage_seconds))
    stage_seconds[:other] = max(0.0, total_seconds - accounted)
    _record_detailed_timing!((
        category = :multipoint_template_evaluate,
        context = _current_detailed_timing_context(),
        total_seconds = total_seconds,
        stage_seconds = copy(stage_seconds),
        time_indices = Tuple(time_indices),
        point_count = length(time_indices),
        data_var_count = length(mpt.data_vars),
        data_value_count = length(data_values),
        nth_deriv_calls = nth_deriv_calls,
        max_deriv_order = max_deriv_order,
    ))
    return MultiPointEvaluation(mpt, time_indices, t_values, data_values)
end

# ═══════════════════════════════════════════════════════════════════════════════
# Solve: direct and parameter homotopy
# ═══════════════════════════════════════════════════════════════════════════════

"""
    solve_multipoint_direct(eval; options)

Direct solve: substitute data values into symbolic equations, then solve with HC.jl.
Returns a vector of real solution vectors (each in solve_vars order).
"""
function solve_multipoint_direct(eval::MultiPointEvaluation; options::Dict = Dict())
    mpt = eval.template

    # Build substitution dictionary: data_var -> value
    subst_dict = Dict{Any, Any}()
    for (i, dv) in enumerate(mpt.data_vars)
        if i <= length(eval.data_values)
            subst_dict[dv] = eval.data_values[i]
        end
    end

    # Substitute into stripped equations
    instantiated_eqs = [Symbolics.substitute(eq, subst_dict) for eq in mpt.stripped_equations]

    # Solve with existing HC solver
    solutions, _, _, _ = solve_with_hc(instantiated_eqs, mpt.solve_vars; options = options)
    return solutions
end

"""
    solve_multipoint_parameterized(mpt, evaluations; options)

Parameter homotopy solve: data_vars are HC parameters, solve_vars are HC variables.
Solves at first evaluation using fresh polyhedral solve, then tracks solutions
to subsequent evaluations.

Returns one vector of solutions per evaluation.
"""
function solve_multipoint_parameterized(
        mpt::MultiPointTemplate,
        evaluations::Vector{MultiPointEvaluation};
        options::Dict = Dict(),
        precomputed_generic_solutions = nothing,
        precomputed_generic_params = nothing,
)
    if isempty(evaluations)
        return Vector{Vector{Vector{Float64}}}()
    end

    param_values_list = [e.data_values for e in evaluations]

    return solve_with_hc_parameterized(
        mpt.stripped_equations,
        mpt.solve_vars,
        mpt.data_vars,
        param_values_list;
        options = options,
        precomputed_generic_solutions = precomputed_generic_solutions,
        precomputed_generic_params = precomputed_generic_params,
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Overdetermined solve: HC core + GN/LM refinement
# ═══════════════════════════════════════════════════════════════════════════════

"""
    solve_multipoint_overdetermined(mpt, eval_result, all_equations, all_vars;
        diagnostics=false)

Solve using HC on the stripped (square) system, then refine each solution against
the full overdetermined (pre-strip) system using Levenberg-Marquardt.

Returns refined solution vectors in `mpt.solve_vars` order.
"""
function solve_multipoint_overdetermined(
    mpt::MultiPointTemplate,
    eval_result::MultiPointEvaluation,
    all_equations::Vector,
    all_vars::Vector;
    diagnostics::Bool = false,
)
    # Step 1: solve the square stripped system via HC
    hc_solutions = solve_multipoint_direct(eval_result)
    if isempty(hc_solutions)
        diagnostics && println("  [MP-OD] HC found 0 solutions on square core")
        return Vector{Float64}[]
    end
    diagnostics && println("  [MP-OD] HC found $(length(hc_solutions)) solutions on square core")

    # Step 2: build the overdetermined residual function
    # Substitute data values into all_equations (not just stripped)
    data_subst = Dict{Any, Float64}()
    for (j, dv) in enumerate(mpt.data_vars)
        if j <= length(eval_result.data_values)
            data_subst[dv] = eval_result.data_values[j]
        end
    end

    # Substitute data into all equations
    inst_all_eqs = [Symbolics.substitute(eq, data_subst) for eq in all_equations]

    # Collect remaining variables (should be solve_vars)
    remaining_vars = mpt.solve_vars

    # Compile overdetermined residual
    f_od = try
        _compile_system_function(inst_all_eqs, remaining_vars)
    catch e
        diagnostics && println("  [MP-OD] Failed to compile overdetermined system: $e")
        return hc_solutions  # fall back to HC solutions
    end

    n_eqs = length(inst_all_eqs)
    n_vars = length(remaining_vars)
    diagnostics && println("  [MP-OD] Overdetermined system: $n_eqs eqs × $n_vars vars")

    # Step 3: refine each HC solution using LM
    refined = Vector{Float64}[]
    for (si, sol) in enumerate(hc_solutions)
        x0 = Float64.(sol)
        try
            # Use NonlinearSolve.jl with LevenbergMarquardt
            residual! = (du, u, p) -> begin
                du .= f_od(u)
            end
            nf = NonlinearFunction(residual!)
            prob = NonlinearLeastSquaresProblem(nf, x0)
            lm_sol = NonlinearSolve.solve(prob, LevenbergMarquardt();
                abstol = 1e-12, reltol = 1e-12, maxiters = 100)

            refined_x = Float64.(lm_sol.u)
            # Check improvement
            res_hc = norm(f_od(x0))
            res_lm = norm(f_od(refined_x))
            if res_lm <= res_hc
                push!(refined, refined_x)
                diagnostics && println("  [MP-OD] Solution $si: HC residual=$(@sprintf("%.2e", res_hc)) → LM residual=$(@sprintf("%.2e", res_lm))")
            else
                push!(refined, x0)  # LM diverged, keep HC
                diagnostics && println("  [MP-OD] Solution $si: LM diverged ($(@sprintf("%.2e", res_lm)) > $(@sprintf("%.2e", res_hc))), keeping HC")
            end
        catch e
            push!(refined, x0)  # LM failed, keep HC
            diagnostics && println("  [MP-OD] Solution $si: LM failed ($e), keeping HC")
        end
    end

    return refined
end

# ═══════════════════════════════════════════════════════════════════════════════
# Point selection
# ═══════════════════════════════════════════════════════════════════════════════

"""
    select_time_point_pairs(n_time_points, n_pairs, n_points_per_pair; strategy, margin)

Select sets of time point indices for multi-point evaluation.

Strategies:
- `:spread` — maximize separation between points within each pair, spread across time
- `:random` — random selection with minimum separation

Returns a vector of index vectors, each of length `n_points_per_pair`.
"""
function select_time_point_pairs(
        n_time_points::Int, n_pairs::Int, n_points_per_pair::Int;
        strategy::Symbol = :spread,
        margin::Float64 = 0.1,
)
    pairs = Vector{Vector{Int}}()
    min_idx = max(2, round(Int, n_time_points * margin))
    max_idx = min(n_time_points - 1, round(Int, n_time_points * (1 - margin)))

    if strategy == :spread
        if n_points_per_pair == 2
            # Generate n_pairs well-spread pairs
            for k in 1:n_pairs
                # Shift the center of each pair to spread across time
                center_frac = 0.5
                if n_pairs > 1
                    center_frac = 0.3 + 0.4 * (k - 1) / (n_pairs - 1)
                end
                center = round(Int, n_time_points * center_frac)

                # Separation: vary from ~25% to ~40% of time range
                sep_frac = 0.25 + 0.15 * ((k - 1) % 3) / max(1, min(2, n_pairs - 1))
                sep = max(2, round(Int, n_time_points * sep_frac))

                idx_a = clamp(center - sep ÷ 2, min_idx, max_idx)
                idx_b = clamp(center + sep ÷ 2, min_idx, max_idx)
                if idx_a == idx_b
                    idx_b = min(idx_a + 2, max_idx)
                end
                push!(pairs, [idx_a, idx_b])
            end
        else
            # N > 2 points: spread evenly across time range, shift between pairs
            for k in 1:n_pairs
                offset = (k - 1) * 3  # slight shift per pair
                indices = Int[]
                for j in 1:n_points_per_pair
                    frac = margin + (1 - 2 * margin) * (j - 1) / max(1, n_points_per_pair - 1)
                    idx = clamp(round(Int, n_time_points * frac) + offset, min_idx, max_idx)
                    push!(indices, idx)
                end
                push!(pairs, indices)
            end
        end
    elseif strategy == :random
        min_sep = max(2, round(Int, n_time_points * 0.1))
        for _ in 1:n_pairs
            attempts = 0
            while attempts < 100
                indices = sort(rand(min_idx:max_idx, n_points_per_pair))
                # Check minimum separation
                ok = all(indices[i+1] - indices[i] >= min_sep for i in 1:(length(indices)-1))
                if ok
                    push!(pairs, indices)
                    break
                end
                attempts += 1
            end
        end
    end

    return pairs
end

"""
    _generate_combinations!(result, items, k)

Generate all C(n,k) combinations of `items` taken `k` at a time. Appends to `result`.
"""
function _generate_combinations!(result::Vector{Vector{Int}}, items::Vector{Int}, k::Int)
    n = length(items)
    k > n && return
    indices = collect(1:k)
    while true
        push!(result, items[indices])
        # Find rightmost index that can be incremented
        i = k
        while i > 0 && indices[i] == n - k + i
            i -= 1
        end
        i == 0 && break
        indices[i] += 1
        for j in (i + 1):k
            indices[j] = indices[j - 1] + 1
        end
    end
end

# ═══════════════════════════════════════════════════════════════════════════════
# Adaptive point selection strategies
# ═══════════════════════════════════════════════════════════════════════════════

"""
    _gp_quality_score(t_idx, interpolants, mq, template_DD, t_vec, max_order)

Score a time point by GP interpolation quality. Lower = better (less GP uncertainty).
Uses the GP posterior variance at all required derivative orders.
Falls back to distance-from-boundary heuristic if GP variance is unavailable.
"""
function _gp_quality_score(t_idx::Int, interpolants::Dict, mq, template_DD, t_vec, max_order::Int)
    t = t_vec[t_idx]
    total_var = 0.0
    n_evals = 0

    for (obs_idx, mq_eq) in enumerate(mq)
        obs_rhs = ModelingToolkit.diff2term(mq_eq.rhs)
        if _is_trfn_observable(Symbolics.wrap(obs_rhs))
            continue
        end
        interp = get(interpolants, obs_rhs, nothing)
        isnothing(interp) && continue

        for order in 0:min(max_order, length(template_DD.obs_lhs) - 1)
            # Try to get GP variance if the interpolant supports it
            var = try
                _, v = mean_and_var(interp, t, order)
                v
            catch
                # Fallback: penalize boundaries (derivative accuracy degrades there)
                n_t = length(t_vec)
                boundary_dist = min(t_idx - 1, n_t - t_idx) / n_t
                (1.0 + order)^2 / max(boundary_dist, 0.01)
            end
            total_var += var
            n_evals += 1
        end
    end

    return n_evals > 0 ? total_var / n_evals : Inf
end

"""
    select_time_point_pairs_gp_quality(n_time_points, n_pairs, n_points_per_pair,
        interpolants, mq, template_DD, t_vec; margin, max_order)

Select time point pairs by GP interpolation quality. Picks points where the
GP posterior variance is lowest (most reliable derivatives).

This is a simple "avoid bad regions" strategy — it doesn't consider parameter
sensitivity, just data quality.
"""
function select_time_point_pairs_gp_quality(
        n_time_points::Int, n_pairs::Int, n_points_per_pair::Int,
        interpolants::Dict, mq, template_DD, t_vec;
        margin::Float64 = 0.1, max_order::Int = 3,
)
    min_idx = max(2, round(Int, n_time_points * margin))
    max_idx = min(n_time_points - 1, round(Int, n_time_points * (1 - margin)))
    candidates = min_idx:max_idx

    # Score every candidate point
    scores = Float64[_gp_quality_score(i, interpolants, mq, template_DD, t_vec, max_order)
                     for i in candidates]

    # Pick top points (lowest score = best quality), with minimum separation
    sorted_indices = candidates[sortperm(scores)]
    min_sep = max(2, round(Int, n_time_points * 0.05))

    # Greedily build pairs from the best-quality points
    selected_points = Int[]
    for idx in sorted_indices
        if all(abs(idx - s) >= min_sep for s in selected_points)
            push!(selected_points, idx)
        end
        length(selected_points) >= n_pairs * n_points_per_pair && break
    end

    # Form pairs
    pairs = Vector{Vector{Int}}()
    sort!(selected_points)
    if n_points_per_pair == 2
        # Pair up: (1st, last), (2nd, 2nd-to-last), etc. for maximum separation
        n = length(selected_points)
        for k in 1:min(n_pairs, n ÷ 2)
            push!(pairs, [selected_points[k], selected_points[n - k + 1]])
        end
    else
        for k in 1:n_points_per_pair:length(selected_points)
            chunk = selected_points[k:min(k + n_points_per_pair - 1, end)]
            length(chunk) == n_points_per_pair && push!(pairs, chunk)
            length(pairs) >= n_pairs && break
        end
    end

    return pairs
end

"""
    select_time_point_pairs_sensitivity(mpt, n_pairs, interpolants, data_sample;
        margin, n_candidates)

Select time point pairs that minimize expected parameter error propagation.

For each candidate pair (t_a, t_b):
1. Evaluate the multipoint template → get data values
2. Substitute into the symbolic Jacobian
3. Compute condition number of the solve-variable Jacobian
4. Score = condition number (lower = more robust)

This is the "D-optimal" inspired strategy: pick pairs where the polynomial
system is best-conditioned, meaning small data perturbations cause small
parameter errors.
"""
function select_time_point_pairs_sensitivity(
        mpt::MultiPointTemplate, n_pairs::Int,
        interpolants::Dict, data_sample;
        margin::Float64 = 0.1, n_candidates::Int = 30,
)
    t_vec = data_sample["t"]
    n_t = length(t_vec)
    min_idx = max(2, round(Int, n_t * margin))
    max_idx = min(n_t - 1, round(Int, n_t * (1 - margin)))
    n_pts = mpt.n_points

    # Generate candidate pairs
    candidates = Vector{Vector{Int}}()
    min_sep = max(3, round(Int, n_t * 0.1))

    if n_pts == 2
        # Sample candidate pairs with good spread
        for _ in 1:n_candidates * 3
            a = rand(min_idx:max_idx)
            b = rand(min_idx:max_idx)
            if abs(b - a) >= min_sep
                push!(candidates, sort([a, b]))
            end
            length(candidates) >= n_candidates && break
        end
    end

    # Also add the spread-strategy pairs as baseline candidates
    spread_pairs = select_time_point_pairs(n_t, min(6, n_pairs), n_pts; strategy = :spread, margin = margin)
    append!(candidates, spread_pairs)
    unique!(candidates)

    # Score each candidate by Jacobian conditioning
    scored = Tuple{Float64, Vector{Int}}[]
    f_sys = _compile_system_function(mpt.stripped_equations, vcat(mpt.solve_vars, mpt.data_vars))

    for pair in candidates
        eval_result = try
            evaluate_multipoint_template(mpt, pair, interpolants, data_sample)
        catch
            continue
        end
        any(!isfinite, eval_result.data_values) && continue

        # Evaluate Jacobian at a representative point (data values substituted, solve vars random)
        n_solve = length(mpt.solve_vars)
        n_data = length(mpt.data_vars)
        x_probe = vcat(randn(n_solve), eval_result.data_values)

        J = try
            ForwardDiff.jacobian(f_sys, x_probe)
        catch
            continue
        end

        # Extract the solve-variable block of the Jacobian
        J_solve = J[:, 1:n_solve]

        # Score by condition number (lower = better conditioned)
        cond_num = try
            svs = svdvals(J_solve)
            svs[1] / max(svs[end], 1e-15)
        catch
            Inf
        end

        push!(scored, (cond_num, pair))
    end

    # Sort by score (ascending = better conditioned first)
    sort!(scored; by = first)

    # Take top n_pairs, ensuring diversity (no overlapping indices)
    pairs = Vector{Vector{Int}}()
    used = Set{Int}()
    for (score, pair) in scored
        if !any(idx in used for idx in pair)
            push!(pairs, pair)
            union!(used, pair)
        end
        length(pairs) >= n_pairs && break
    end

    # If we didn't get enough diverse pairs, relax the diversity constraint
    if length(pairs) < n_pairs
        for (score, pair) in scored
            pair in pairs && continue
            push!(pairs, pair)
            length(pairs) >= n_pairs && break
        end
    end

    return pairs
end

"""
    select_time_point_pairs_homotopy_probed(mpt, n_pairs, interpolants, data_sample;
        margin, n_candidates, real_params)

Adaptive strategy: generate many candidate pairs, solve each via cheap parameter
homotopy, and keep the pairs that produce the best solutions.

Scoring criteria:
1. Number of real solutions (more = better, captures all branches)
2. Solution residual (lower = more accurate)
3. Parameter consistency across pairs (solutions that agree = trustworthy)

This leverages the unique advantage of parameter homotopy: we can cheaply
explore many pairs and keep the winners.
"""
function select_time_point_pairs_homotopy_probed(
        mpt::MultiPointTemplate, n_pairs::Int,
        interpolants::Dict, data_sample;
        margin::Float64 = 0.1, n_candidates::Int = 20,
)
    t_vec = data_sample["t"]
    n_t = length(t_vec)
    n_pts = mpt.n_points

    # Generate diverse candidate pairs
    all_candidates = Vector{Vector{Int}}()

    # Spread candidates
    append!(all_candidates, select_time_point_pairs(n_t, min(8, n_candidates ÷ 2), n_pts;
        strategy = :spread, margin = margin))

    # Random candidates
    append!(all_candidates, select_time_point_pairs(n_t, n_candidates, n_pts;
        strategy = :random, margin = margin))

    unique!(all_candidates)

    # Evaluate all candidates
    valid_evals = Tuple{Vector{Int}, MultiPointEvaluation}[]
    for pair in all_candidates
        ev = try
            evaluate_multipoint_template(mpt, pair, interpolants, data_sample)
        catch
            continue
        end
        all(isfinite, ev.data_values) && push!(valid_evals, (pair, ev))
    end

    isempty(valid_evals) && return select_time_point_pairs(n_t, n_pairs, n_pts; strategy = :spread, margin = margin)

    # Solve all candidates via parameter homotopy (cheap!)
    evals_only = [ev for (_, ev) in valid_evals]
    solutions_by_pair = try
        solve_multipoint_parameterized(mpt, evals_only;
            options = Dict(:show_progress => false, :real_tol => 1e-6))
    catch
        return select_time_point_pairs(n_t, n_pairs, n_pts; strategy = :spread, margin = margin)
    end

    # Score each pair
    scored = Tuple{Float64, Vector{Int}}[]
    f_sys = _compile_system_function(mpt.stripped_equations, mpt.solve_vars)

    for (k, (pair, ev)) in enumerate(valid_evals)
        k > length(solutions_by_pair) && break
        sols = solutions_by_pair[k]

        # Score components:
        n_real = length(sols)
        n_real == 0 && (push!(scored, (Inf, pair)); continue)

        # Compute residuals by substituting solutions back
        subst_dict = Dict{Any, Any}()
        for (i, dv) in enumerate(mpt.data_vars)
            i <= length(ev.data_values) && (subst_dict[dv] = ev.data_values[i])
        end
        inst_eqs = [Symbolics.substitute(eq, subst_dict) for eq in mpt.stripped_equations]
        f_inst = try
            _compile_system_function(inst_eqs, mpt.solve_vars)
        catch
            push!(scored, (1e10, pair))
            continue
        end

        best_residual = Inf
        for sol in sols
            res = try
                norm(f_inst(sol))
            catch
                Inf
            end
            best_residual = min(best_residual, res)
        end

        # Combined score: prioritize low residual, bonus for more real solutions
        score = best_residual / max(1, n_real)
        push!(scored, (score, pair))
    end

    sort!(scored; by = first)

    # Take top n_pairs
    pairs = Vector{Vector{Int}}()
    for (score, pair) in scored
        push!(pairs, pair)
        length(pairs) >= n_pairs && break
    end

    return pairs
end
