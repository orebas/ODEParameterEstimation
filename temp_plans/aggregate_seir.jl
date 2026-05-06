# Apply the aggregation strategies to seir_2_1em4 per-record CSV.
# Compare: naive median vs MAD-rejection vs IFT-mismatch-gated median.

using CSV
using DataFrames
using Statistics
using Printf

const CSV_PATH = "artifacts/diagnostics/seed_strategy_recon_2026_05_04/seir_per_record.csv"

df = CSV.read(CSV_PATH, DataFrame)
println("Loaded $(nrow(df)) records")

# Filter to parameters only
params_df = filter(row -> row.role == "parameter", df)
println("Parameter records: $(nrow(params_df))")
println("Unique params: ", unique(params_df.param_or_ic_label))
println("Unique SPs: ", unique(params_df.sp))
println("Unique interpolators: ", unique(params_df.interp))

println()
@printf("%-50s %s\n", "Strategy", "estimate (rel err vs truth)")
println("=" ^ 95)

for param_label in unique(params_df.param_or_ic_label)
    sub = filter(row -> row.param_or_ic_label == param_label, params_df)
    truth = first(sub.truth_val)
    estimates = sub.estimate
    actual_deltas = sub.actual_delta
    predicted_deltas = sub.predicted_delta

    # IFT mismatches (relative)
    mismatches = [
        isfinite(act) && act != 0 ? abs(pred - act) / abs(act) : Inf
        for (act, pred) in zip(actual_deltas, predicted_deltas)
    ]

    println()
    @printf("--- %s (truth = %g, n_records = %d) ---\n", param_label, truth, length(estimates))

    # Strategy 1: naive median
    s1 = median(estimates)
    @printf("  %-46s %12.4g  (%.2e)\n", "(1) naive median", s1, abs(s1 - truth) / max(abs(truth), 1e-12))

    # Strategy 2: MAD-based outlier rejection
    med = median(estimates)
    mad = median(abs.(estimates .- med))
    if mad > 0
        inliers = estimates[abs.(estimates .- med) .<= 3 * mad]
        s2 = isempty(inliers) ? med : median(inliers)
        @printf("  %-46s %12.4g  (%.2e)  [n=%d]\n", "(2) MAD<3 inlier median", s2, abs(s2 - truth) / max(abs(truth), 1e-12), length(inliers))
    end

    # Strategy 3: IFT-mismatch < τ gate
    for τ in [0.005, 0.01, 0.05, 0.10, 0.20]
        idx = mismatches .< τ
        n_in = sum(idx)
        if n_in > 0
            s3 = median(estimates[idx])
            @printf("  %-46s %12.4g  (%.2e)  [n=%d]\n",
                "(3) IFT-mismatch < $τ gate", s3,
                abs(s3 - truth) / max(abs(truth), 1e-12), n_in)
        else
            @printf("  %-46s %12s  (no inliers)\n", "(3) IFT-mismatch < $τ gate", "—")
        end
    end

    # Strategy: trimmed-cond (keep candidates with smallest cond_J)
    # Get unique (sp, interp) and their cond_J
    by_combo = combine(groupby(sub, [:sp, :interp]), :cond_J => first => :cond_J,
                       :estimate => first => :estimate,
                       :actual_delta => first => :actual_delta,
                       :predicted_delta => first => :predicted_delta)
    sort!(by_combo, :cond_J)
    n_keep = max(2, div(nrow(by_combo), 3))  # keep best 1/3 by cond
    keep = first(by_combo, n_keep)
    s4 = median(keep.estimate)
    @printf("  %-46s %12.4g  (%.2e)  [n=%d, cond range %g..%g]\n",
        "(4) keep best 1/3 by cond, median", s4, abs(s4 - truth) / max(abs(truth), 1e-12),
        n_keep, first(keep.cond_J), last(keep.cond_J))

    # Best individual estimate (oracle)
    best_idx = argmin(abs.(estimates .- truth))
    @printf("  %-46s %12.4g  (%.2e)\n", "ORACLE: best single combo",
        estimates[best_idx], abs(estimates[best_idx] - truth) / max(abs(truth), 1e-12))
end

println()
println("AGGREGATE_SEIR_DONE")
