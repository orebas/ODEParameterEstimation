# Statistical aggregation experiment on the forced_lv 25-candidate sweep data.
# Data source: G3_forced_lv_sp_mp_sweep.md (per-(SP, interp) α and β actual + IFT-predicted Δ).
# Strategies tested:
#   (1) Naive median across all 25 candidates (baseline)
#   (2) MAD-based outlier rejection then median
#   (3) IFT-mismatch-gated median (drop candidates where |Δ_actual - Δ_predicted|/|Δ_actual| > τ)
#   (4) Trim k worst-residual candidates (variation of 2)
#   (5) Inverse-variance weighted: weight ∝ 1/(1 + |Δ_predicted|^2) — favors candidates where
#       IFT predicts small displacement (good conditioning + low data noise)
# Goal: confirm strategies (2)–(5) recover α and β to <2% relative vs truth, vs naive 18% / 9%.

using Statistics
using Printf

# ── Hand-encoded from G3_forced_lv_sp_mp_sweep.md ──
# Each row: (SP, interp, β_actual_Δ, β_IFT_pred, α_actual_Δ, α_IFT_pred)
records = [
    (0.083, "aaad_gpr",                 -2.112e-01, -1.836e-01, -1.879e-01, -1.630e-01),
    (0.083, "agp_robust",                -2.112e-01, -1.836e-01, -1.879e-01, -1.630e-01),
    (0.083, "agp_robust_se_times_rq",    -2.126e-01, -1.853e-01, -1.891e-01, -1.646e-01),
    (0.083, "chebyshev_bic",             -9.975e-01, -9.178e-01, -8.902e-01, -8.185e-01),
    (0.083, "s2_aaa_mle",                +2.161e-01, +1.486e+00, +1.823e-01, +1.307e+00),
    (0.333, "aaad_gpr",                  -2.137e-02, -2.166e-02, -1.864e-02, -1.887e-02),
    (0.333, "agp_robust",                -2.137e-02, -2.166e-02, -1.864e-02, -1.887e-02),
    (0.333, "agp_robust_se_times_rq",    -2.182e-02, -2.210e-02, -1.903e-02, -1.926e-02),
    (0.333, "chebyshev_bic",             -3.189e-02, -3.206e-02, -2.896e-02, -2.909e-02),
    (0.333, "s2_aaa_mle",                +2.025e-01, +4.875e-01, +1.706e-01, +4.191e-01),
    (1.083, "aaad_gpr",                  +5.494e-04, +5.501e-04, +9.400e-04, +9.409e-04),
    (1.083, "agp_robust",                +5.494e-04, +5.501e-04, +9.400e-04, +9.409e-04),
    (1.083, "agp_robust_se_times_rq",    +6.710e-04, +6.713e-04, +1.037e-03, +1.038e-03),
    (1.083, "chebyshev_bic",             -7.613e-03, -7.573e-03, -4.400e-03, -4.374e-03),
    (1.083, "s2_aaa_mle",                -3.027e-01, -2.535e-01, -2.089e-01, -1.867e-01),
    (2.787, "aaad_gpr",                  +1.864e-02, +1.850e-02, +6.639e-03, +6.597e-03),
    (2.787, "agp_robust",                +1.864e-02, +1.850e-02, +6.639e-03, +6.597e-03),
    (2.787, "agp_robust_se_times_rq",    +1.838e-02, +1.825e-02, +6.568e-03, +6.528e-03),
    (2.787, "chebyshev_bic",             +1.743e-02, +1.724e-02, +6.160e-03, +6.105e-03),
    (2.787, "s2_aaa_mle",                -1.438e-01, -1.597e-01, -6.604e-02, -6.715e-02),
    (5.000, "aaad_gpr",                  -2.012e-01, -2.048e-01, -3.395e-02, -3.459e-02),
    (5.000, "agp_robust",                -2.012e-01, -2.048e-01, -3.395e-02, -3.459e-02),
    (5.000, "agp_robust_se_times_rq",    -1.880e-01, -1.909e-01, -3.174e-02, -3.227e-02),
    (5.000, "chebyshev_bic",             +4.693e-01, +6.557e-01, +7.797e-02, +1.088e-01),
    (5.000, "s2_aaa_mle",                -2.334e+00, -2.542e+00, -4.497e-01, -5.360e-01),
]

# Truth values
β_truth = 0.243
α_truth = 0.103

# Extract param Δ vectors
β_Δ_actual = [r[3] for r in records]
β_Δ_pred   = [r[4] for r in records]
α_Δ_actual = [r[5] for r in records]
α_Δ_pred   = [r[6] for r in records]

# Convert Δ → estimate (truth + Δ)
β_est = β_truth .+ β_Δ_actual
α_est = α_truth .+ α_Δ_actual

# IFT mismatch per (param, candidate): |Δ_actual - Δ_predicted| / |Δ_actual|
β_ift_mismatch = abs.(β_Δ_actual .- β_Δ_pred) ./ max.(abs.(β_Δ_actual), 1e-12)
α_ift_mismatch = abs.(α_Δ_actual .- α_Δ_pred) ./ max.(abs.(α_Δ_actual), 1e-12)

# Per-candidate aggregate IFT mismatch (max over the params)
ift_mismatch_per_cand = max.(β_ift_mismatch, α_ift_mismatch)

# ── Strategy 1: Naive median across all 25 ──
β_strat1 = median(β_est)
α_strat1 = median(α_est)

# ── Strategy 2: MAD-based outlier rejection then median ──
function mad_filtered_median(values; k_mad = 3.0)
    med = median(values)
    mad = median(abs.(values .- med))
    if mad == 0
        return med
    end
    inliers = values[abs.(values .- med) .<= k_mad * mad]
    return isempty(inliers) ? med : median(inliers)
end
β_strat2 = mad_filtered_median(β_est; k_mad = 3.0)
α_strat2 = mad_filtered_median(α_est; k_mad = 3.0)

# ── Strategy 3: IFT-mismatch-gated median ──
function ift_gated_median(values, mismatch; threshold = 0.05)
    inliers = values[mismatch .< threshold]
    if isempty(inliers)
        return median(values)  # fallback
    end
    return median(inliers)
end
β_strat3 = ift_gated_median(β_est, β_ift_mismatch; threshold = 0.05)
α_strat3 = ift_gated_median(α_est, α_ift_mismatch; threshold = 0.05)

# ── Strategy 4: trim worst k candidates by aggregate IFT mismatch, median rest ──
function trim_k_worst(values, scores; k = 5)
    n = length(values)
    keep_n = n - k
    if keep_n <= 0
        return median(values)
    end
    keep_idx = sortperm(scores)[1:keep_n]  # smallest scores = best
    return median(values[keep_idx])
end
β_strat4 = trim_k_worst(β_est, ift_mismatch_per_cand; k = 5)
α_strat4 = trim_k_worst(α_est, ift_mismatch_per_cand; k = 5)

# ── Strategy 5: inverse-displacement weighted median ──
# Idea: candidates where IFT predicts small Δ are "well-conditioned + low-noise"
# weight = 1 / (1 + |Δ_predicted|^2). Then weighted median.
function weighted_median(values, weights)
    perm = sortperm(values)
    sorted_vals = values[perm]
    sorted_w = weights[perm]
    cumw = cumsum(sorted_w) ./ sum(sorted_w)
    idx = findfirst(>=( 0.5), cumw)
    return sorted_vals[idx]
end
β_weights = 1.0 ./ (1.0 .+ β_Δ_pred .^ 2)
α_weights = 1.0 ./ (1.0 .+ α_Δ_pred .^ 2)
β_strat5 = weighted_median(β_est, β_weights)
α_strat5 = weighted_median(α_est, α_weights)

# ── Best single (SP, interp) — what's achievable if we knew the right combo ──
β_best_idx = argmin(abs.(β_Δ_actual))
α_best_idx = argmin(abs.(α_Δ_actual))
β_oracle_best = β_est[β_best_idx]
α_oracle_best = α_est[α_best_idx]

# ── Print results ──
println("=" ^ 76)
println("FORCED_LV β AND α — AGGREGATION STRATEGIES vs TRUTH")
println("=" ^ 76)
@printf("%-50s %12s %12s %12s\n", "Strategy", "β estimate", "β rel err", "%")
println("-" ^ 76)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "truth (reference)",         β_truth,        0.0,                            0.0)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(1) naive median (n=25)",   β_strat1, abs(β_strat1 - β_truth) / β_truth, 100*abs(β_strat1 - β_truth) / β_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(2) MAD outlier rejection", β_strat2, abs(β_strat2 - β_truth) / β_truth, 100*abs(β_strat2 - β_truth) / β_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(3) IFT-mismatch < 5% gate", β_strat3, abs(β_strat3 - β_truth) / β_truth, 100*abs(β_strat3 - β_truth) / β_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(4) trim k=5 worst by IFT-mismatch", β_strat4, abs(β_strat4 - β_truth) / β_truth, 100*abs(β_strat4 - β_truth) / β_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(5) inv-displacement weighted median", β_strat5, abs(β_strat5 - β_truth) / β_truth, 100*abs(β_strat5 - β_truth) / β_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "ORACLE: best single (SP, interp)",   β_oracle_best, abs(β_oracle_best - β_truth) / β_truth, 100*abs(β_oracle_best - β_truth) / β_truth)

println()
@printf("%-50s %12s %12s %12s\n", "Strategy", "α estimate", "α rel err", "%")
println("-" ^ 76)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "truth (reference)",         α_truth,        0.0,                            0.0)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(1) naive median (n=25)",   α_strat1, abs(α_strat1 - α_truth) / α_truth, 100*abs(α_strat1 - α_truth) / α_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(2) MAD outlier rejection", α_strat2, abs(α_strat2 - α_truth) / α_truth, 100*abs(α_strat2 - α_truth) / α_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(3) IFT-mismatch < 5% gate", α_strat3, abs(α_strat3 - α_truth) / α_truth, 100*abs(α_strat3 - α_truth) / α_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(4) trim k=5 worst by IFT-mismatch", α_strat4, abs(α_strat4 - α_truth) / α_truth, 100*abs(α_strat4 - α_truth) / α_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "(5) inv-displacement weighted median", α_strat5, abs(α_strat5 - α_truth) / α_truth, 100*abs(α_strat5 - α_truth) / α_truth)
@printf("%-50s %12.6f %12.4e %11.2f%%\n", "ORACLE: best single (SP, interp)",   α_oracle_best, abs(α_oracle_best - α_truth) / α_truth, 100*abs(α_oracle_best - α_truth) / α_truth)

println()
println("=" ^ 76)
println("Inlier counts per strategy")
println("=" ^ 76)
ift_inliers_β = sum(β_ift_mismatch .< 0.05)
ift_inliers_α = sum(α_ift_mismatch .< 0.05)
@printf("MAD inliers (β):           %d / 25 (k=3)\n", sum(abs.(β_est .- median(β_est)) .<= 3*median(abs.(β_est .- median(β_est)))))
@printf("MAD inliers (α):           %d / 25 (k=3)\n", sum(abs.(α_est .- median(α_est)) .<= 3*median(abs.(α_est .- median(α_est)))))
@printf("IFT-gate inliers (β):      %d / 25 (threshold 5%%)\n", ift_inliers_β)
@printf("IFT-gate inliers (α):      %d / 25 (threshold 5%%)\n", ift_inliers_α)

println()
println("=" ^ 76)
println("Sensitivity sweep on IFT-mismatch threshold (β)")
println("=" ^ 76)
for τ in [0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.20, 0.50, 1.00]
    β_τ = ift_gated_median(β_est, β_ift_mismatch; threshold = τ)
    α_τ = ift_gated_median(α_est, α_ift_mismatch; threshold = τ)
    nβ = sum(β_ift_mismatch .< τ)
    nα = sum(α_ift_mismatch .< τ)
    @printf("τ=%.3f  β=%.5f (rel %.4f)  α=%.5f (rel %.4f)  n_β=%d  n_α=%d\n",
        τ, β_τ, abs(β_τ - β_truth) / β_truth,
        α_τ, abs(α_τ - α_truth) / α_truth, nβ, nα)
end

println()
println("AGGREGATION_EXPERIMENT_DONE")
