"""
Threshold-gate audit on multiple AMIGO2-only cases.

For each case:
1. Build PEP from bilby script.jl.
2. Read result.csv (the saved odepe_nopolish output post-clustering).
3. For each row, compute max-rel-err vs truth and evaluate trajectory loss via polish_ctx.
4. Classify by threshold and report:
   - Pool stats (best rel, best loss)
   - Whether the truth-best candidate is gated out
   - Whether ANY truth-near rows (rel < 0.5 say) survive the err < MAX_ERROR_THRESHOLD gate

Cases:
- flexible_arm_0_1em4 (already audited; re-run for consistency)
- forced_lotka_volterra_0_1em2 (high-noise total-failure, AMIGO2 8/8)
- daisy_mamil3_7_1em4 (broad_mixed sweep flagged "near miss")
- cstr_1_0 (zero noise, ODEPE collapses params to 0)

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/multi_case_threshold_audit.jl")'
"""

using CSV
using Logging
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Statistics
using Printf

const ODEPE = ODEParameterEstimation
const OUTDIR = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "seed_strategy_recon_2026_05_04")
mkpath(OUTDIR)
const BILBY_ROOT = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish"

function _load_bilby_data(case_dir::AbstractString, mq)
    datafile = joinpath(case_dir, "data.csv")
    csv_data = CSV.read(datafile, Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

# ─── Case builders ────────────────────────────────────────────────────────────────

function build_flex_arm()
    parameters = @parameters Jm Jt bm bt k
    states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)
    observables = @variables y1(t) y2(t)
    eqs = [
        D(theta_m) ~ omega_m,
        D(omega_m) ~ (0.5 - 0.1*bm*omega_m - 20.0*k*(-0.5*theta_t + 0.5*theta_m)) / (0.1*Jm),
        D(theta_t) ~ omega_t,
        D(omega_t) ~ (-0.05*bt*omega_t - 20.0*k*(0.5*theta_t - 0.5*theta_m)) / (0.05*Jt),
    ]
    mq_orig = [y1 ~ 0.5*theta_m, y2 ~ 0.5*theta_t]
    ic = [0.623, 0.681, 0.53, 0.188]
    p_true = [0.419, 0.445, 0.592, 0.156, 0.758]
    model, mq = ODEPE.create_ordered_ode_system("flexible_arm", states, parameters, eqs, mq_orig)
    case_dir = joinpath(BILBY_ROOT, "flexible_arm_0_1em4")
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem("flexible_arm_0_1em4", model, mq, data_sample, [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0), case_dir
end

function build_forced_lv()
    parameters = @parameters alpha beta delta gamma
    states = @variables x(t) yv(t)
    observables = @variables y1(t) y2(t)
    eqs = [
        D(x) ~ (-0.3*sin(2.0*t) + 6.0*alpha*x - 8.0*beta*x*yv) / 2.0,
        D(yv) ~ (-12.0*gamma*yv + 4.0*delta*x*yv) / 2.0,
    ]
    mq_orig = [y1 ~ 2.0*x, y2 ~ 2.0*yv]
    ic = [0.806, 0.676]
    p_true = [0.103, 0.243, 0.59, 0.165]
    model, mq = ODEPE.create_ordered_ode_system("forced_lotka_volterra", states, parameters, eqs, mq_orig)
    case_dir = joinpath(BILBY_ROOT, "forced_lotka_volterra_0_1em2")
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem("forced_lotka_volterra_0_1em2", model, mq, data_sample, [0.0, 5.0], nothing,
        OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0), case_dir
end

function build_daisy_mamil3_7()
    parameters = @parameters a12 a13 a21 a31 a01
    states = @variables x1(t) x2(t) x3(t)
    observables = @variables y1(t) y2(t)
    eqs = [
        D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
        D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
        D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
    ]
    mq_orig = [y1 ~ 0.5 * x1, y2 ~ x2]
    ic = [0.139, 0.303, 0.457]
    p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
    model, mq = ODEPE.create_ordered_ode_system("daisy_mamil3", states, parameters, eqs, mq_orig)
    case_dir = joinpath(BILBY_ROOT, "daisy_mamil3_7_1em4")
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem("daisy_mamil3_7_1em4", model, mq, data_sample, [0.0, 20.0], nothing,
        OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0), case_dir
end

# ─── Audit one case ────────────────────────────────────────────────────────────────

function _eval_loss(state_lookup, param_lookup, ctx)
    try
        ic_vec = Float64[get(state_lookup, string(s), NaN) for s in ctx.unknown_syms]
        p_vec = Float64[get(param_lookup, string(p), NaN) for p in ctx.param_syms]
        any(isnan, ic_vec) && return NaN
        any(isnan, p_vec) && return NaN
        p_external = vcat(ic_vec, p_vec)
        if !isnothing(ctx.lb) && !isnothing(ctx.ub)
            p_external = clamp.(p_external, ctx.lb, ctx.ub)
        end
        p_internal = ODEPE._polish_external_to_internal(
            p_external, ctx.coordinate_transforms, ctx.coordinate_shifts,
        )
        return Float64(ctx.optf.f(p_internal, nothing))
    catch
        return NaN
    end
end

function audit_case(name, builder)
    println("\n", "="^72)
    println("CASE: $name")
    println("="^72)
    pep, case_dir = builder()
    opts = EstimationOptions(
        interpolator = InterpolatorAAADGPR,
        interpolators = InterpolatorMethod[],
        shooting_points = 12,
        shooting_warp = true,
        shooting_warp_beta = 3.0,
        nooutput = true,
        diagnostics = false,
        save_system = false,
        polish_solutions = false,
        use_parameter_homotopy = true,
        use_multipoint = true,
        max_solutions = 30,
        use_sensitivity_seeds = false,
    )
    ctx = ODEPE._build_polish_context(pep; opts = opts)

    truth = OrderedDict{Any, Any}()
    for (k, v) in pep.p_true; truth[k] = v; end
    for (k, v) in pep.ic; truth[k] = v; end

    result_csv = joinpath(case_dir, "result.csv")
    csv_iter = CSV.File(result_csv)
    header = Symbol.(csv_iter.names)
    df = Dict{Symbol, Vector{Float64}}()
    for col in header
        df[col] = Float64[Float64(getproperty(row, col)) for row in csv_iter]
    end
    n_rows = length(first(values(df)))
    println("Pool size: $n_rows rows")

    rows_data = []
    for i in 1:n_rows
        state_lookup = Dict{String, Float64}()
        param_lookup = Dict{String, Float64}()
        for col in header
            col_str = String(col)
            val = df[col][i]
            if endswith(col_str, "(t)")
                state_lookup[col_str] = val
            else
                param_lookup[col_str] = val
            end
        end
        rels = Float64[]
        for (sym, true_val) in truth
            s = string(sym)
            est = if haskey(state_lookup, s)
                state_lookup[s]
            elseif haskey(param_lookup, s)
                param_lookup[s]
            else
                continue
            end
            tv = Float64(true_val)
            push!(rels, abs(tv) > 1e-12 ? abs(est - tv) / abs(tv) : abs(est - tv))
        end
        rel = isempty(rels) ? NaN : maximum(rels)
        loss = _eval_loss(state_lookup, param_lookup, ctx)
        push!(rows_data, (idx=i, rel=rel, loss=loss))
    end

    finite_rel = filter(r -> isfinite(r.rel), rows_data)
    finite_loss = filter(r -> isfinite(r.loss), rows_data)

    pregate = filter(r -> isfinite(r.loss) && r.loss < 0.5, rows_data)
    postgate = filter(r -> isfinite(r.loss) && r.loss >= 0.5, rows_data)
    nan_loss_rows = filter(r -> !isfinite(r.loss), rows_data)

    println("Pre-gate (loss<0.5):  $(length(pregate))")
    println("Post-gate (loss>=0.5): $(length(postgate))")
    println("NaN loss:             $(length(nan_loss_rows))")

    if !isempty(finite_rel)
        @printf("Best rel-err (anywhere):     %.4g\n", minimum(r.rel for r in finite_rel))
    end

    finite_pregate_rel = filter(r -> isfinite(r.rel), pregate)
    finite_postgate_rel = filter(r -> isfinite(r.rel), postgate)

    if !isempty(finite_pregate_rel)
        @printf("Best rel in pre-gate (kept): %.4g\n", minimum(r.rel for r in finite_pregate_rel))
    end
    if !isempty(finite_postgate_rel)
        @printf("Best rel in post-gate (DROP): %.4g\n", minimum(r.rel for r in finite_postgate_rel))
    end

    # Top 5 by rel
    println("Top 5 by rel-err:")
    sorted_rel = sort(finite_rel; by = r -> r.rel)
    for r in first(sorted_rel, 5)
        gated = isfinite(r.loss) && r.loss >= 0.5 ? "DROPPED" : "kept"
        @printf("  idx %d: rel=%.4g, loss=%.4g  [%s]\n", r.idx, r.rel, r.loss, gated)
    end
    # Top 5 by loss
    println("Top 5 by loss:")
    sorted_loss = sort(finite_loss; by = r -> r.loss)
    for r in first(sorted_loss, 5)
        @printf("  idx %d: loss=%.4g, rel=%.4g\n", r.idx, r.loss, r.rel)
    end

    # CRITICAL: compare gate-keepers vs truth-best
    if !isempty(finite_pregate_rel) && !isempty(finite_postgate_rel)
        bp = minimum(r.rel for r in finite_pregate_rel)
        bg = minimum(r.rel for r in finite_postgate_rel)
        if bg < bp
            @printf("⚠ Gate discards truth-better candidate (%.4g) keeping %.4g — RANKING MISS\n", bg, bp)
        end
    elseif !isempty(finite_postgate_rel) && isempty(pregate)
        # No candidates pass the gate — fallback to top-MAX_SOLUTIONS by err
        # Check if the truth-best is in top-MAX_SOLUTIONS by err
        sorted_by_err = sort(finite_loss; by = r -> r.loss)[1:min(20, length(finite_loss))]
        truth_best_idx = finite_postgate_rel[argmin([r.rel for r in finite_postgate_rel])].idx
        in_top20 = any(r -> r.idx == truth_best_idx, sorted_by_err)
        @printf("Gate fallback: %d in top-20 by err. Truth-best (idx=%d, rel=%.4g) %s.\n",
            length(sorted_by_err), truth_best_idx,
            minimum(r.rel for r in finite_postgate_rel),
            in_top20 ? "IN top-20 (kept)" : "NOT in top-20 (DROPPED via fallback)")
    end

    return rows_data, finite_pregate_rel, finite_postgate_rel
end

# ─── Run all cases ────────────────────────────────────────────────────────────────

cases = [
    ("flexible_arm_0_1em4", build_flex_arm),
    ("forced_lotka_volterra_0_1em2", build_forced_lv),
    ("daisy_mamil3_7_1em4", build_daisy_mamil3_7),
]

results = Dict()
for (name, builder) in cases
    try
        results[name] = audit_case(name, builder)
    catch e
        println("\nFAILED on $name: $e")
        bt = sprint(showerror, e, catch_backtrace())
        println(first(bt, 500))
    end
end

println("\n", "="^72)
println("MULTI_CASE_AUDIT_DONE")
