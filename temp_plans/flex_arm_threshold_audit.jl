"""
Verify the MAX_ERROR_THRESHOLD gate hypothesis on flexible_arm_0_1em4.

Method: Read bilby's saved odepe_nopolish/result.csv. For each row:
- Compute max-rel-err against truth (oracle metric).
- Compute trajectory loss `err` via polish-context closure (the gate's input).
- Classify: "pre-gate" (err < 0.5) vs "post-gate" (err >= 0.5).

Question: does the saved pool contain truth-near rows with err >= 0.5 that the gate
would discard? On flexible_arm, prior memo says yes.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/flex_arm_threshold_audit.jl")'
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

# ─── Build flexible_arm PEP from bilby script ────────────────────────────────────

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

function build_flex_arm()
    parameters = @parameters Jm Jt bm bt k
    states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)
    observables = @variables y1(t) y2(t)
    state_equations = [
        D(theta_m) ~ omega_m,
        D(omega_m) ~ (0.5 - 0.1*bm*omega_m - 20.0*k*(-0.5*theta_t + 0.5*theta_m)) / (0.1*Jm),
        D(theta_t) ~ omega_t,
        D(omega_t) ~ (-0.05*bt*omega_t - 20.0*k*(0.5*theta_t - 0.5*theta_m)) / (0.05*Jt),
    ]
    measured_quantities = [y1 ~ 0.5*theta_m, y2 ~ 0.5*theta_t]
    ic = [0.623, 0.681, 0.53, 0.188]
    p_true = [0.419, 0.445, 0.592, 0.156, 0.758]
    model, mq = ODEPE.create_ordered_ode_system("flexible_arm", states, parameters, state_equations, measured_quantities)
    case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/flexible_arm_0_1em4"
    data_sample = _load_bilby_data(case_dir, mq)
    return ParameterEstimationProblem(
        "flexible_arm_0_1em4",
        model, mq, data_sample, [0.0, 10.0], nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )
end

# ─── Read result.csv and audit ─────────────────────────────────────────────────────

println("Building flex_arm PEP...")
pep = build_flex_arm()
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
    multipoint_n_points = 2,
    multipoint_max_pairs = 4,
    max_solutions = 30,
    use_sensitivity_seeds = false,
)

println("Building polish context...")
ctx = ODEPE._build_polish_context(pep; opts = opts)

# Build truth dict
truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end
println("Truth: ", join(["$k=$(round(v;sigdigits=4))" for (k,v) in truth], ", "))

# Read result.csv directly with CSV.File (don't need Tables.jl).
result_csv = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/flexible_arm_0_1em4/result.csv"
csv_iter = CSV.File(result_csv)
header = Symbol.(csv_iter.names)
df = Dict{Symbol, Vector{Float64}}()
for col in header
    df[col] = Float64[Float64(getproperty(row, col)) for row in csv_iter]
end
println("\nCSV header: ", header)
println("Number of rows: ", length(first(values(df))))

# For each row, build a candidate (param vec + state vec)
function row_to_candidate(row_idx, df, header, pep, ctx)
    # CSV columns mix params and state(t) — need to map to ctx ordering.
    # ctx.unknown_syms is the state-IC ordering (as Num); ctx.param_syms is params.
    state_lookup = Dict{String, Float64}()
    param_lookup = Dict{String, Float64}()
    for col in header
        col_str = String(col)
        val = Float64(df[col][row_idx])
        # State columns end with "(t)" in bilby format
        if endswith(col_str, "(t)")
            state_lookup[col_str] = val
        else
            param_lookup[col_str] = val
        end
    end
    return state_lookup, param_lookup
end

function _max_rel_err_dicts(state_lookup, param_lookup, truth)
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
    return isempty(rels) ? NaN : maximum(rels)
end

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
    catch e
        return NaN
    end
end

n_rows = length(first(values(df)))
println("\nProcessing $(n_rows) rows...")
flush(stdout)

rows_data = []
for i in 1:n_rows
    state_lookup, param_lookup = row_to_candidate(i, df, header, pep, ctx)
    rel = _max_rel_err_dicts(state_lookup, param_lookup, truth)
    loss = _eval_loss(state_lookup, param_lookup, ctx)
    push!(rows_data, (idx=i, rel=rel, loss=loss, params=param_lookup, states=state_lookup))
end

# ─── Analyze: pre-gate vs post-gate ────────────────────────────────────────────────

const MAX_ERROR_THRESHOLD = 0.5

pregate = filter(r -> isfinite(r.loss) && r.loss < MAX_ERROR_THRESHOLD, rows_data)
postgate = filter(r -> isfinite(r.loss) && r.loss >= MAX_ERROR_THRESHOLD, rows_data)
nan_loss = filter(r -> !isfinite(r.loss), rows_data)

println("\n", "="^72)
println("Threshold-gate audit")
println("="^72)
println("Total rows:                $(n_rows)")
println("Loss < 0.5 (pass gate):    $(length(pregate))")
println("Loss >= 0.5 (dropped):     $(length(postgate))")
println("Loss = NaN (failed eval):  $(length(nan_loss))")

# Best rel-err by category
finite_rel = filter(r -> isfinite(r.rel), rows_data)
finite_pregate_rel = filter(r -> isfinite(r.rel), pregate)
finite_postgate_rel = filter(r -> isfinite(r.rel), postgate)

if !isempty(finite_rel)
    @printf("\nBest rel-err overall:        %.4g (idx %d)\n",
        minimum(r.rel for r in finite_rel),
        finite_rel[argmin([r.rel for r in finite_rel])].idx)
end
if !isempty(finite_pregate_rel)
    @printf("Best rel-err in pregate set: %.4g (idx %d, loss %.4g)\n",
        minimum(r.rel for r in finite_pregate_rel),
        finite_pregate_rel[argmin([r.rel for r in finite_pregate_rel])].idx,
        finite_pregate_rel[argmin([r.rel for r in finite_pregate_rel])].loss)
end
if !isempty(finite_postgate_rel)
    @printf("Best rel-err in DROPPED set: %.4g (idx %d, loss %.4g)\n",
        minimum(r.rel for r in finite_postgate_rel),
        finite_postgate_rel[argmin([r.rel for r in finite_postgate_rel])].idx,
        finite_postgate_rel[argmin([r.rel for r in finite_postgate_rel])].loss)
end

# Print top-10 by rel-err — see which side of the gate they're on
println("\nTop 10 rows by rel-err (best first):")
@printf("%-4s %-12s %-12s %-9s %-9s %-9s %-9s %-9s %-9s %-9s\n",
    "idx", "rel", "loss", "Jm", "Jt", "bm", "bt", "k", "theta_m", "omega_m")
sorted_by_rel = sort(rows_data; by = r -> isfinite(r.rel) ? r.rel : Inf)
for r in first(sorted_by_rel, 10)
    @printf("%-4d %-12.4g %-12.4g %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g %-9.4g\n",
        r.idx, r.rel, r.loss,
        get(r.params, "Jm", NaN), get(r.params, "Jt", NaN),
        get(r.params, "bm", NaN), get(r.params, "bt", NaN), get(r.params, "k", NaN),
        get(r.states, "theta_m(t)", NaN), get(r.states, "omega_m(t)", NaN))
end

# Print top-5 by loss
println("\nTop 5 by loss (lowest loss first — these pass the gate):")
sorted_by_loss = sort(filter(r -> isfinite(r.loss), rows_data); by = r -> r.loss)
for r in first(sorted_by_loss, 5)
    @printf("idx %-4d  rel=%-9.4g  loss=%-9.4g\n", r.idx, r.rel, r.loss)
end

# THE KEY QUESTION: are there truth-better rows being dropped?
println("\n", "="^72)
println("KEY DIAGNOSIS")
println("="^72)
if !isempty(finite_pregate_rel) && !isempty(finite_postgate_rel)
    best_pregate = minimum(r.rel for r in finite_pregate_rel)
    best_postgate = minimum(r.rel for r in finite_postgate_rel)
    if best_postgate < best_pregate
        @printf("⚠  GATE BITES: dropped pool's best rel = %.4g, kept pool's best = %.4g\n",
            best_postgate, best_pregate)
        @printf("   Truth-better candidates exist that the gate is discarding.\n")
        @printf("   Improvement available by removing/relaxing the gate: %.2f×\n",
            best_pregate / best_postgate)
    else
        @printf("✓ Gate doesn't bite here: kept set's best (%.4g) <= dropped set's best (%.4g)\n",
            best_pregate, best_postgate)
    end
end

# Save details
csv_path = joinpath(OUTDIR, "flex_arm_pool_audit.csv")
open(csv_path, "w") do io
    println(io, "idx,rel,loss,gated_out,Jm,Jt,bm,bt,k")
    for r in rows_data
        gated = isfinite(r.loss) && r.loss >= MAX_ERROR_THRESHOLD
        println(io, "$(r.idx),$(r.rel),$(r.loss),$(gated),",
            "$(get(r.params,"Jm",NaN)),$(get(r.params,"Jt",NaN)),",
            "$(get(r.params,"bm",NaN)),$(get(r.params,"bt",NaN)),",
            "$(get(r.params,"k",NaN))")
    end
end
println("\nSaved per-row CSV to: $csv_path")

println("\nFLEX_ARM_AUDIT_DONE")
