"""
Pre-seed research harness — Phase A scaffolding.

Loads a representative not-too-easy ODE case, runs the full pipeline with sensitivity-seed
augmentation OFF, captures the baseline candidate pool with provenance metadata. Builds a
polish context for trajectory-loss evaluation. Provides a `run_strategy` interface that
takes a strategy function `(pool, metadata) -> Vector{ParameterEstimationResult}` and
reports per-strategy summary statistics.

Phase A goal: confirm scaffolding works end-to-end on fitzhugh polish=OFF with strategy S0
(pass-through). Subsequent phases add S1, S2, S3, S4, S5, S6 strategies.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/preseed_research_harness.jl")'
"""

using CSV
using Logging
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Random
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Statistics
using Printf

const ODEPE = ODEParameterEstimation

# ─── Case loading (mirrors test/generate_sensitivity_seeds_validation.jl) ──────────

function _load_bilby_data(case_dir::AbstractString, mq)
    datafile = joinpath(case_dir, "data.csv")
    isfile(datafile) || error("Benchmark dataset not found at $datafile")
    csv_data = CSV.read(datafile, Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

function build_seir_pep()
    parameters = @parameters a b nu
    states = @variables S(t) E(t) In(t) Npop(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(S) ~ (-15840.0 * b * In * S) / (3960000.0 * Npop),
        D(E) ~ ((15840.0 * b * In * S) / (2000.0 * Npop) - 6.0 * nu * E) / 20.0,
        D(In) ~ (-4.0 * a * In + 6.0 * nu * E) / 10.0,
        D(Npop) ~ 0,
    ]
    measured_quantities = [y1 ~ 10.0 * In, y2 ~ 2000.0 * Npop]
    ic = [0.647, 0.182, 0.418, 0.321]
    p_true = [0.187, 0.414, 0.277]
    model, mq = ODEPE.create_ordered_ode_system("seir", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "seir_2_1em4",
        model, mq, data_sample, [0.0, 60.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

function build_fitzhugh_nagumo_pep()
    parameters = @parameters g a b
    states = @variables Vm(t) R(t)
    observables = @variables y1(t)
    state_equations = [
        D(Vm) ~ (-3.0) * g * (0.5 * R - 2.0 * Vm + (2.6666666666666665) * (Vm^3)),
        D(R) ~ (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g),
    ]
    measured_quantities = [y1 ~ -2.0 * Vm]
    ic = [0.42, 0.404]
    p_true = [0.779, 0.849, 0.887]
    model, mq = ODEPE.create_ordered_ode_system("fitzhugh_nagumo", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "fitzhugh_nagumo_2_1em4",
        model, mq, data_sample, [0.0, 1.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

# ─── Pool capture ─────────────────────────────────────────────────────────────────

"""
    capture_pool(pep; polish_solutions=false) -> NamedTuple

Run the full pipeline with sensitivity-seed augmentation OFF. Capture the unaugmented pool
of candidates plus everything needed to evaluate strategies on it.
"""
function capture_pool(pep; polish_solutions::Bool = false)
    opts = EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 3,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = polish_solutions,
        polish_solver_solutions = false,
        polish_maxiters = 50,
        polish_maxtime = 30.0,
        use_parameter_homotopy = true,
        use_multipoint = true,
        multipoint_n_points = 2,
        multipoint_max_pairs = 4,
        max_solutions = 30,
        use_sensitivity_seeds = false,  # capture baseline pool only
    )

    println("Running pipeline on $(pep.name) (polish=$(polish_solutions ? "ON" : "OFF"))...")
    elapsed = @elapsed begin
        results = with_logger(NullLogger()) do
            ODEPE.analyze_parameter_estimation_problem(pep, opts)
        end
    end
    println("Pipeline completed in $(round(elapsed; digits=1))s")

    # results = (results_tuple, sorted_cluster_tuple, uq_result)
    # results_tuple = (solved_res, unident_dict, trivial_dict, all_unidentifiable)
    pool = results[1][1]

    # Build a polish context for trajectory-loss evaluation.
    ctx = ODEPE._build_polish_context(pep; opts = opts)

    # Truth as a single dict over Symbolics keys.
    truth = OrderedDict{Any, Any}()
    for (k, v) in pep.p_true; truth[k] = v; end
    for (k, v) in pep.ic; truth[k] = v; end

    return (
        pep = pep,
        opts = opts,
        pool = pool,
        polish_ctx = ctx,
        truth = truth,
        elapsed = elapsed,
    )
end

# ─── Per-candidate / per-seed metric helpers ──────────────────────────────────────

"""
    candidate_max_rel_err(candidate, truth) -> Float64

Max relative error of params + states vs. truth. NaN if no parameters match.
"""
function candidate_max_rel_err(candidate, truth)
    estimated = OrderedDict{Any, Any}()
    for (k, v) in candidate.parameters; estimated[k] = v; end
    for (k, v) in candidate.states; estimated[k] = v; end
    rels = Float64[]
    for (sym, true_val) in truth
        haskey(estimated, sym) || continue
        est_val = Float64(estimated[sym])
        tv = Float64(true_val)
        push!(rels, abs(tv) > 1e-12 ? abs(est_val - tv) / abs(tv) : abs(est_val - tv))
    end
    return isempty(rels) ? NaN : maximum(rels)
end

"""
    candidate_loss(candidate, polish_ctx) -> Float64

Trajectory-loss eval at the candidate via the polish-context closure. NaN on failure.
"""
function candidate_loss(candidate, polish_ctx)
    try
        # Build the (states; params) external vector in the order the ctx expects.
        state_lookup = Dict{String, Float64}()
        for (k, v) in candidate.states; state_lookup[string(k)] = Float64(v); end
        param_lookup = Dict{String, Float64}()
        for (k, v) in candidate.parameters; param_lookup[string(k)] = Float64(v); end

        ic_vec = Float64[get(state_lookup, string(s), NaN) for s in polish_ctx.unknown_syms]
        p_vec = Float64[get(param_lookup, string(p), NaN) for p in polish_ctx.param_syms]
        any(isnan, ic_vec) && return NaN
        any(isnan, p_vec) && return NaN

        p_external = vcat(ic_vec, p_vec)
        if !isnothing(polish_ctx.lb) && !isnothing(polish_ctx.ub)
            p_external = clamp.(p_external, polish_ctx.lb, polish_ctx.ub)
        end
        p_internal = ODEPE._polish_external_to_internal(
            p_external, polish_ctx.coordinate_transforms, polish_ctx.coordinate_shifts,
        )
        return Float64(polish_ctx.optf.f(p_internal, nothing))
    catch
        return NaN
    end
end

# ─── Strategy interface ──────────────────────────────────────────────────────────

"""
    run_strategy(name, strategy_fn, captured) -> NamedTuple

Apply a strategy to the captured pool, evaluate the resulting seeds vs. truth and
trajectory loss, print and return a summary.

`strategy_fn(captured) -> Vector{ParameterEstimationResult}`. Should return ONLY the
new pre-seeds (not the original pool); we'll concatenate with the pool in the report so
the "best-of-set" includes baseline candidates as a floor.
"""
function run_strategy(name::AbstractString, strategy_fn, captured; print_top::Int = 5)
    seeds_only = strategy_fn(captured)
    seeds_plus_pool = vcat(captured.pool, seeds_only)

    # Score each
    scored = map(seeds_plus_pool) do c
        rel = candidate_max_rel_err(c, captured.truth)
        loss = candidate_loss(c, captured.polish_ctx)
        (rel = rel, loss = loss)
    end

    # Stats over the seeds-only set
    seed_scored = map(seeds_only) do c
        rel = candidate_max_rel_err(c, captured.truth)
        loss = candidate_loss(c, captured.polish_ctx)
        (rel = rel, loss = loss)
    end
    seed_finite = filter(s -> isfinite(s.rel), seed_scored)
    seed_finite_loss = filter(s -> isfinite(s.loss), seed_scored)

    # Best-of-set over union (pool + seeds)
    pool_finite = filter(s -> isfinite(s.rel), scored)
    best_rel = isempty(pool_finite) ? NaN : minimum(s.rel for s in pool_finite)
    pool_finite_loss = filter(s -> isfinite(s.loss), scored)
    best_loss = isempty(pool_finite_loss) ? Inf : minimum(s.loss for s in pool_finite_loss)

    println("\n--- Strategy $name ---")
    println("  pool size: $(length(captured.pool)) → with seeds: $(length(seeds_plus_pool))")
    println("  seeds emitted: $(length(seeds_only))")
    if !isempty(seed_finite)
        rels = [s.rel for s in seed_finite]
        @printf("  seed rel-err: min=%.4g, median=%.4g, max=%.4g\n", minimum(rels), median(rels), maximum(rels))
    else
        println("  seed rel-err: (no finite values)")
    end
    if !isempty(seed_finite_loss)
        losses = [s.loss for s in seed_finite_loss]
        @printf("  seed loss:    min=%.4g, median=%.4g, max=%.4g\n", minimum(losses), median(losses), maximum(losses))
    else
        println("  seed loss: (no finite values)")
    end
    @printf("  union best-rel-err: %.4g  (oracle metric)\n", best_rel)
    @printf("  union best-loss:    %.4g\n", best_loss)

    # Top-K by rel
    if print_top > 0 && !isempty(scored)
        sorted_idx = sortperm([isfinite(s.rel) ? s.rel : Inf for s in scored])
        println("  top $(min(print_top, length(scored))) by rel-err:")
        for i in 1:min(print_top, length(sorted_idx))
            idx = sorted_idx[i]
            c = seeds_plus_pool[idx]
            origin = idx ≤ length(captured.pool) ? "pool" : "seed"
            src = isnothing(c.provenance) ? "?" : string(c.provenance.source_type)
            @printf("    [%s/%s] rel=%.4g loss=%.4g\n", origin, src, scored[idx].rel, scored[idx].loss)
        end
    end

    return (
        name = name,
        n_seeds = length(seeds_only),
        union_best_rel = best_rel,
        union_best_loss = best_loss,
        seed_scored = seed_scored,
    )
end

# ─── Strategies ──────────────────────────────────────────────────────────────────

"""
    strategy_S0(captured) -> Vector{ParameterEstimationResult}

Baseline pass-through: emit no seeds. Used as the reference for relative measurements.
"""
function strategy_S0(captured)
    return ODEPE.ParameterEstimationResult[]
end

"""
    _make_seed_result(params_dict, states_dict, t0; source_type=:preseed_research)

Construct a `ParameterEstimationResult` shell for a research pre-seed, with err=nothing
(filled in by the harness via `candidate_loss` when evaluating).
"""
function _make_seed_result(params_dict, states_dict, t0::Real; source_type::Symbol = :preseed_research)
    result = ODEPE.ParameterEstimationResult(
        params_dict,
        states_dict,
        Float64(t0),
        nothing,                  # err — populated by harness eval
        nothing,                  # return_code
        0,                        # datasize
        Float64(t0),              # report_time
        OrderedDict{ODEPE.Symbolics.Num, Float64}(),
        Set{ODEPE.Symbolics.Num}(),
        nothing,                  # solution
    )
    if !isnothing(result.provenance)
        result.provenance.source_type = source_type
        result.provenance.primary_method = :algebraic
        result.provenance.polish_applied = false
    end
    return result
end

"""
    strategy_S1(captured) -> Vector{ParameterEstimationResult}

All-pairs mean blend on parameters. For each pair (A, B) in the pool, emit a seed with
params = (A.params + B.params)/2. States: take A's states (the second parent's states are
typically incompatible because they live at a different shooting point).

This is the formalized "buggy mean-blend" baseline. On fitzhugh it should produce a seed
with rel ≈ 2.54 (the win the parser-bug accidentally achieved).
"""
function strategy_S1(captured)
    pool = captured.pool
    n = length(pool)
    seeds = ODEPE.ParameterEstimationResult[]
    for i in 1:n
        for j in (i + 1):n
            a, b = pool[i], pool[j]
            # Blend params (assuming both have the same param key set)
            blended_params = OrderedDict{ODEPE.Symbolics.Num, Float64}()
            for (k, va) in a.parameters
                if haskey(b.parameters, k)
                    blended_params[k] = (Float64(va) + Float64(b.parameters[k])) / 2
                else
                    blended_params[k] = Float64(va)
                end
            end
            # States: take A's states (incomparable across shooting points, so picking one is honest)
            blended_states = OrderedDict{ODEPE.Symbolics.Num, Float64}()
            for (k, vs) in a.states
                blended_states[k] = Float64(vs)
            end
            t0 = a.at_time
            push!(seeds, _make_seed_result(blended_params, blended_states, t0; source_type = :S1_mean_blend))
        end
    end
    return seeds
end

"""
    _param_vector(candidate) -> Vector{Float64}

Extract a candidate's parameter values in a canonical alphabetical-by-name order. Used for
clustering and comparisons in param-only space.
"""
function _param_vector(candidate)
    pairs = sort(collect(candidate.parameters); by = x -> string(x[1]))
    return Float64[Float64(v) for (_, v) in pairs]
end

"""
    _cluster_pool_by_params(pool; n_clusters=nothing, log_transform=true)
        -> Vector{Vector{Int}}

Cluster the pool on parameter values only. Coordinate transform: log(|·|) for positive-
valued params (sign-preserving), MAD-scale across pool. Return a vector of clusters where
each is a list of pool indices.

Simple agglomerative hierarchical clustering with average linkage; cuts at the chosen
number of clusters if specified, otherwise picks via single-linkage gap heuristic.
"""
function _cluster_pool_by_params(pool; n_clusters::Union{Nothing, Int} = nothing,
                                  log_transform::Bool = true)
    n = length(pool)
    n == 0 && return Vector{Int}[]
    n == 1 && return [[1]]

    # Build the data matrix in transformed coords
    P = hcat([_param_vector(c) for c in pool]...)' |> Matrix{Float64}  # n × d
    if log_transform
        # Sign-preserving log: sign(x) * log(|x| + 1) — handles zeros and negatives
        @inbounds for i in eachindex(P)
            x = P[i]
            P[i] = sign(x) * log(abs(x) + 1.0)
        end
    end
    # MAD-scale per column
    for j in axes(P, 2)
        col = @view P[:, j]
        μ = median(col)
        mad_val = median(abs.(col .- μ))
        if mad_val > 1e-12
            P[:, j] = (col .- μ) ./ mad_val
        else
            P[:, j] = col .- μ
        end
    end

    # Pairwise distances
    D = zeros(n, n)
    for i in 1:n, j in (i + 1):n
        d = sqrt(sum((P[i, :] .- P[j, :]).^2))
        D[i, j] = D[j, i] = d
    end

    # Simple agglomerative: start with each point in own cluster, merge closest until target count.
    clusters = [[i] for i in 1:n]
    target = isnothing(n_clusters) ? max(1, n ÷ 6) : max(1, n_clusters)  # rough default if not specified
    while length(clusters) > target
        # Find closest pair (average linkage)
        best_dist = Inf
        best_i, best_j = 0, 0
        for i in 1:length(clusters), j in (i + 1):length(clusters)
            cluster_i, cluster_j = clusters[i], clusters[j]
            d_avg = mean(D[a, b] for a in cluster_i, b in cluster_j)
            if d_avg < best_dist
                best_dist = d_avg
                best_i, best_j = i, j
            end
        end
        best_i == 0 && break
        # Merge
        merged = vcat(clusters[best_i], clusters[best_j])
        deleteat!(clusters, best_j)  # j > i, delete higher first
        deleteat!(clusters, best_i)
        push!(clusters, merged)
    end
    return clusters
end

"""
    strategy_S5(captured; n_draws=50, alpha=1.0, seed=0) -> Vector{ParameterEstimationResult}

Random Dirichlet convex combinations of pool members on params only. Drawing weights
w ~ Dir(α=1.0, n) and emitting Σ w_i x_i.params, with states from a uniformly chosen
parent. Cheap exploration that doesn't depend on cluster geometry.
"""
function strategy_S5(captured; n_draws::Int = 50, alpha::Float64 = 1.0, seed::Int = 0)
    pool = captured.pool
    n = length(pool)
    n < 2 && return ODEPE.ParameterEstimationResult[]
    seeds = ODEPE.ParameterEstimationResult[]
    rng = MersenneTwister(seed)

    param_keys = collect(keys(pool[1].parameters))
    for _ in 1:n_draws
        # Draw Dirichlet(α=1, ..., 1) weights via i.i.d. Exp(1) + normalize.
        # (For α≠1 we'd need actual Gamma; sticking with α=1 keeps it stdlib-only.)
        gammas = [randexp(rng) for _ in 1:n]
        w = gammas ./ sum(gammas)

        blended_params = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for k in param_keys
            v = 0.0
            for i in 1:n
                v += w[i] * Float64(get(pool[i].parameters, k, 0.0))
            end
            blended_params[k] = v
        end

        # States: pick a uniformly random parent
        parent_idx = rand(rng, 1:n)
        parent_states = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for (k, v) in pool[parent_idx].states
            parent_states[k] = Float64(v)
        end
        push!(seeds, _make_seed_result(blended_params, parent_states, pool[parent_idx].at_time;
                                        source_type = :S5_dirichlet))
    end
    return seeds
end

"""
    _classify_flappers_from_pool(pool) -> Vector{Symbol}

Return the set of parameter symbols (as strings) classified as :loose by
coordinate-of-variation across the pool. Uses Statistics.std and median directly so we
don't need to re-implement compute_cross_solution_spread (which expects a `pep` and uses
truth — circular for our purposes).
"""
function _classify_flappers_from_pool(pool; cv_threshold::Float64 = 0.5)
    n = length(pool)
    n < 2 && return Symbol[]
    param_keys = collect(keys(pool[1].parameters))
    flapper_keys = Symbol[]
    for k in param_keys
        vals = Float64[Float64(c.parameters[k]) for c in pool if haskey(c.parameters, k)]
        length(vals) < 2 && continue
        med = median(vals)
        s = std(vals)
        # CV = std / |median|; classify as flapper if CV exceeds threshold or median is near-zero
        cv = abs(med) > 1e-12 ? s / abs(med) : (s > 1e-6 ? Inf : 0.0)
        if cv >= cv_threshold
            push!(flapper_keys, Symbol(string(k)))
        end
    end
    return flapper_keys
end

"""
    strategy_S6_simple(captured; flapper_target=:zero) -> Vector{ParameterEstimationResult}

Identify flapper params via pool CV (≥50%); for each pool candidate, emit a seed where
flapper params are replaced with the chosen target (zero or pool median). Other params
unchanged. No Newton-snap — this is the "naive Tikhonov" version to see what shrinkage
alone gets us.
"""
function strategy_S6_simple(captured; flapper_target::Symbol = :zero)
    pool = captured.pool
    isempty(pool) && return ODEPE.ParameterEstimationResult[]

    flapper_syms = _classify_flappers_from_pool(pool)
    if isempty(flapper_syms)
        return ODEPE.ParameterEstimationResult[]
    end

    println("  [S6] Detected flappers: ", flapper_syms)

    param_keys = collect(keys(pool[1].parameters))
    flapper_targets = Dict{ODEPE.Symbolics.Num, Float64}()
    for k in param_keys
        if Symbol(string(k)) in flapper_syms
            if flapper_target == :zero
                flapper_targets[k] = 0.0
            elseif flapper_target == :median
                vals = Float64[Float64(c.parameters[k]) for c in pool if haskey(c.parameters, k)]
                flapper_targets[k] = median(vals)
            else
                flapper_targets[k] = 0.0
            end
        end
    end

    seeds = ODEPE.ParameterEstimationResult[]
    for c in pool
        new_params = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for (k, v) in c.parameters
            new_params[k] = haskey(flapper_targets, k) ? flapper_targets[k] : Float64(v)
        end
        new_states = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for (k, v) in c.states
            new_states[k] = Float64(v)
        end
        push!(seeds, _make_seed_result(new_params, new_states, c.at_time;
                                        source_type = :S6_tikhonov_simple))
    end
    return seeds
end

"""
    strategy_S2_trimmed(captured; trim_frac=0.5) -> Vector{ParameterEstimationResult}

Variant of S2 that first trims the pool (drops the candidates farthest from the pool
centroid in transformed coords) before computing the median. The trimming is meant to
get rid of wild outlier candidates whose presence drags the median out of the truth-near
region.

Emits ONE seed = median of the surviving (untrimmed) candidates' params, with states
from the median-closest survivor.
"""
function strategy_S2_trimmed(captured; trim_frac::Float64 = 0.5)
    pool = captured.pool
    n = length(pool)
    n < 2 && return ODEPE.ParameterEstimationResult[]

    param_keys = collect(keys(pool[1].parameters))
    P = hcat([_param_vector(c) for c in pool]...)' |> Matrix{Float64}
    # Sign-preserving log + MAD-scale (mirrors clustering helper)
    @inbounds for i in eachindex(P)
        P[i] = sign(P[i]) * log(abs(P[i]) + 1.0)
    end
    for j in axes(P, 2)
        col = @view P[:, j]
        μ = median(col)
        mad_val = median(abs.(col .- μ))
        if mad_val > 1e-12
            P[:, j] = (col .- μ) ./ mad_val
        else
            P[:, j] = col .- μ
        end
    end

    centroid = vec(median(P; dims = 1))
    distances = [sqrt(sum((P[i, :] .- centroid).^2)) for i in 1:n]
    n_keep = max(2, Int(round(n * (1 - trim_frac))))
    keep_idx = sortperm(distances)[1:n_keep]
    survivors = pool[keep_idx]

    med_params = OrderedDict{ODEPE.Symbolics.Num, Float64}()
    for k in param_keys
        vals = Float64[Float64(c.parameters[k]) for c in survivors if haskey(c.parameters, k)]
        isempty(vals) && continue
        med_params[k] = median(vals)
    end
    med_vec = Float64[get(med_params, k, 0.0) for k in param_keys]
    best_dist = Inf
    medoid = first(survivors)
    for c in survivors
        v = _param_vector(c)
        d = sqrt(sum((v .- med_vec).^2))
        if d < best_dist
            best_dist = d
            medoid = c
        end
    end
    med_states = OrderedDict{ODEPE.Symbolics.Num, Float64}()
    for (k, v) in medoid.states
        med_states[k] = Float64(v)
    end
    return [_make_seed_result(med_params, med_states, medoid.at_time;
                               source_type = :S2_trimmed_median)]
end

"""
    strategy_S2(captured; n_clusters=nothing) -> Vector{ParameterEstimationResult}

Cluster the pool by params only, take per-cluster coordinate-wise MEDIAN of parameters.
States: pick the medoid candidate's states (the cluster member closest to the cluster's
median, since states aren't directly comparable across shooting points).

Default cluster count: SI's `n_solutions_perfect` if available, otherwise `max(1, n_pool ÷ 6)`.
For Phase B we use `n ÷ 6` as a heuristic until we wire branch detection.
"""
function strategy_S2(captured; n_clusters::Union{Nothing, Int} = nothing)
    pool = captured.pool
    n = length(pool)
    n == 0 && return ODEPE.ParameterEstimationResult[]

    clusters = _cluster_pool_by_params(pool; n_clusters = n_clusters)
    seeds = ODEPE.ParameterEstimationResult[]

    # First pool member's keys define the param/state ordering
    param_keys = collect(keys(pool[1].parameters))

    for cluster_idx in clusters
        members = pool[cluster_idx]
        length(members) < 2 && continue  # nothing to median over

        # Coordinate-wise median of params
        med_params = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for k in param_keys
            vals = Float64[Float64(c.parameters[k]) for c in members if haskey(c.parameters, k)]
            isempty(vals) && continue
            med_params[k] = median(vals)
        end

        # Pick medoid: cluster member closest to median in transformed param space
        med_vec = Float64[get(med_params, k, 0.0) for k in param_keys]
        best_dist = Inf
        medoid_idx = first(cluster_idx)
        for ci in cluster_idx
            v = _param_vector(pool[ci])
            d = sqrt(sum((v .- med_vec).^2))
            if d < best_dist
                best_dist = d
                medoid_idx = ci
            end
        end

        med_states = OrderedDict{ODEPE.Symbolics.Num, Float64}()
        for (k, v) in pool[medoid_idx].states
            med_states[k] = Float64(v)
        end
        push!(seeds, _make_seed_result(med_params, med_states, pool[medoid_idx].at_time;
                                        source_type = :S2_cluster_median))
    end

    return seeds
end

# ─── Driver ──────────────────────────────────────────────────────────────────────

const CASE_NAME = get(ENV, "PRESEED_CASE", "fitzhugh_polish_off")

println("Pre-seed research harness — case: $CASE_NAME")
println("="^70)

pep, polish_flag = if CASE_NAME == "fitzhugh_polish_off"
    (build_fitzhugh_nagumo_pep(), false)
elseif CASE_NAME == "fitzhugh_polish_on"
    (build_fitzhugh_nagumo_pep(), true)
elseif CASE_NAME == "seir_polish_on"
    (build_seir_pep(), true)
elseif CASE_NAME == "seir_polish_off"
    (build_seir_pep(), false)
else
    error("Unknown PRESEED_CASE: $CASE_NAME")
end

captured = capture_pool(pep; polish_solutions = polish_flag)

println("\nCaptured pool: $(length(captured.pool)) candidates")
println("Truth: ", join(["$k=$(round(v;sigdigits=4))" for (k, v) in captured.truth], ", "))

# Pool-baseline summary
pool_rels = [candidate_max_rel_err(c, captured.truth) for c in captured.pool]
pool_finite = filter(isfinite, pool_rels)
if !isempty(pool_finite)
    @printf("Pool baseline: min rel-err = %.4g, median = %.4g, max = %.4g\n",
        minimum(pool_finite), median(pool_finite), maximum(pool_finite))
end

# Run S0 (should produce empty seed set; union best-rel = pool best-rel)
results_S0 = run_strategy("S0 (baseline)", strategy_S0, captured)

# Phase B: S1 (all-pairs mean blend) and S2 (cluster + median)
results_S1 = run_strategy("S1 (all-pairs mean blend)", strategy_S1, captured)
# Try a few cluster counts for S2 since branch count is unknown a priori on fitzhugh
results_S2_2 = run_strategy("S2 (median, k=2)", c -> strategy_S2(c; n_clusters = 2), captured)
results_S2_3 = run_strategy("S2 (median, k=3)", c -> strategy_S2(c; n_clusters = 3), captured)
results_S2_4 = run_strategy("S2 (median, k=4)", c -> strategy_S2(c; n_clusters = 4), captured)

# Phase D-ish: S5 (Dirichlet) and S6_simple (Tikhonov on flappers, no Newton)
results_S5_50 = run_strategy("S5 (Dirichlet, n=50)", c -> strategy_S5(c; n_draws = 50, seed = 42), captured)
results_S5_200 = run_strategy("S5 (Dirichlet, n=200)", c -> strategy_S5(c; n_draws = 200, seed = 42), captured)
results_S6_zero = run_strategy("S6_simple (flapper→0)", c -> strategy_S6_simple(c; flapper_target = :zero), captured)
results_S6_med = run_strategy("S6_simple (flapper→median)", c -> strategy_S6_simple(c; flapper_target = :median), captured)

# Trimmed median variants — drop outlier candidates first then median
results_S2_trim25 = run_strategy("S2_trimmed (trim=25%)", c -> strategy_S2_trimmed(c; trim_frac = 0.25), captured)
results_S2_trim50 = run_strategy("S2_trimmed (trim=50%)", c -> strategy_S2_trimmed(c; trim_frac = 0.5), captured)
results_S2_trim75 = run_strategy("S2_trimmed (trim=75%)", c -> strategy_S2_trimmed(c; trim_frac = 0.75), captured)

println()
println(repeat("=", 70))
println("Headline (oracle-best union rel-err per strategy):")
@printf("  S0 (baseline):                  %.4g\n", results_S0.union_best_rel)
@printf("  S1 (all-pairs mean blend):      %.4g\n", results_S1.union_best_rel)
@printf("  S2 (cluster median k=2):        %.4g\n", results_S2_2.union_best_rel)
@printf("  S2 (cluster median k=3):        %.4g\n", results_S2_3.union_best_rel)
@printf("  S2 (cluster median k=4):        %.4g\n", results_S2_4.union_best_rel)
@printf("  S5 (Dirichlet n=50):            %.4g\n", results_S5_50.union_best_rel)
@printf("  S5 (Dirichlet n=200):           %.4g\n", results_S5_200.union_best_rel)
@printf("  S6_simple (flapper→0):          %.4g\n", results_S6_zero.union_best_rel)
@printf("  S6_simple (flapper→median):     %.4g\n", results_S6_med.union_best_rel)
@printf("  S2_trimmed (trim=25%%):          %.4g\n", results_S2_trim25.union_best_rel)
@printf("  S2_trimmed (trim=50%%):          %.4g\n", results_S2_trim50.union_best_rel)
@printf("  S2_trimmed (trim=75%%):          %.4g\n", results_S2_trim75.union_best_rel)

println()
println(repeat("=", 70))
println("PHASE_B_DONE")
