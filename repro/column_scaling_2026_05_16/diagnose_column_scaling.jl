# Column-scaling diagnostic prototype (read-only).
#
# Per docs/2026-05-01_variable_scaling_investigation.md, three challenging
# systems have cond(J) far above what derivative accuracy alone would predict:
#   biohydrogenation @ noise=1e-8: cond ≈ 4.5e+10
#   daisy_mamil4    @ noise=1e-8: cond ≈ 2.0e+6
#   crauste         (also flagged)
#
# This script reproduces those numbers under CURRENT code, then asks the
# follow-up question:
#
#   If we right-multiply J by an optimally-chosen diagonal D = diag(s),
#   how much smaller is cond(J · D)? That is the *theoretical ceiling*
#   on what variable rescaling could buy.
#
# Two scaling choices (from the existing doc):
#   1) Column-norm-based: D_ii = 1/||J[:,i]||_2 (Bauer-Skeel optimal diagonal scaling)
#   2) Truth-magnitude:   D_ii = max(|truth_i|, 1.0)  (proxy for "bound-based")
#
# Outputs:
#   - column_scaling_results.csv: one row per (system, noise) with cond_raw,
#     cond_colnorm, cond_truth, ratios, and per-column norm range.
#   - per-system .txt with full SVD spectra and column-norm tables.

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using LinearAlgebra
using Statistics
using Printf

# Pull in model registry — load_examples.jl exposes biohydrogenation, daisy_mamil4, crauste
include(joinpath(dirname(@__FILE__), "..", "..", "src", "examples", "load_examples.jl"))

const OUT_DIR = @__DIR__
const RESULTS_CSV = joinpath(OUT_DIR, "column_scaling_results.csv")

# Systems to test: (model symbol, noise levels)
const TEST_CASES = [
    (:biohydrogenation, [1e-8, 0.0]),
    (:daisy_mamil4,    [1e-8, 0.0]),
    (:crauste,         [1e-8]),  # crauste is heavier; one noise level
]

# Helper: extract truth magnitude for a column label
function _truth_magnitude_for_label(label::AbstractString, role::Symbol, pep)
    base = replace(string(label), "_0" => "", "(t)" => "")
    for (k, v) in pep.p_true
        if replace(string(k), "(t)" => "") == base
            return abs(Float64(v))
        end
    end
    for (k, v) in pep.ic
        if replace(string(k), "(t)" => "") == base
            return abs(Float64(v))
        end
    end
    return NaN
end

"""
Compute cond(M·D) for a diagonal D given by the column-norm reciprocal.
Equivalent to scaling each column to unit L2 norm.
"""
function cond_after_colnorm_scaling(J::AbstractMatrix)
    col_norms = [norm(@view J[:, i]) for i in 1:size(J, 2)]
    safe_norms = [max(n, 1e-30) for n in col_norms]
    D = Diagonal(1.0 ./ safe_norms)
    JD = J * D
    svals = svdvals(JD)
    if length(svals) == 0 || svals[end] < 1e-300
        return NaN, col_norms, svals
    end
    return svals[1] / svals[end], col_norms, svals
end

"""
Compute cond(M·D) for a diagonal D given by per-column truth magnitudes.
For columns whose corresponding variable is not a parameter/state IC (e.g.
data variables, state derivatives), the truth value is read from
`true_vals` at that column.
"""
function cond_after_truth_scaling(J::AbstractMatrix, true_vals::Vector{Float64})
    if length(true_vals) != size(J, 2)
        @warn "[truth-scale] length(true_vals)=$(length(true_vals)) != n_cols=$(size(J, 2)); skipping"
        return NaN, Float64[], Float64[]
    end
    scales = [max(abs(v), 1.0) for v in true_vals]
    D = Diagonal(scales)
    JD = J * D
    svals = svdvals(JD)
    if length(svals) == 0 || svals[end] < 1e-300
        return NaN, scales, svals
    end
    return svals[1] / svals[end], scales, svals
end

# CSV header
csv_lines = ["system,noise,n_eqs,n_vars,eff_rank,cond_raw,cond_colnorm,cond_truth," *
             "improvement_colnorm,improvement_truth," *
             "col_norm_min,col_norm_max,col_norm_range_orders"]

for (model_sym, noise_levels) in TEST_CASES
    !(haskey(ALL_MODELS, model_sym)) && (println("Skipping unknown model: $model_sym"); continue)
    println("\n" * "="^70)
    println("System: $model_sym")
    println("="^70)
    pep_template = ALL_MODELS[model_sym]()

    for noise in noise_levels
        println("\n  noise = $noise")
        opts = EstimationOptions(
            datasize = 101,
            noise_level = noise,
            nooutput = true,
        )
        local pep
        try
            pep = sample_problem_data(pep_template, opts)
        catch e
            println("  [skip] sampling failed: $e")
            continue
        end

        # Compute the SI-template Jacobian via existing infrastructure
        local sr
        try
            sr = diagnose_sensitivity(pep)
        catch e
            println("  [skip] diagnose_sensitivity failed: $e")
            continue
        end

        if isempty(sr.jacobian_matrix)
            println("  [skip] empty jacobian matrix")
            continue
        end

        J = sr.jacobian_matrix
        cond_raw = sr.jacobian_cond
        eff_rank = sr.effective_rank
        n_eqs, n_vars = size(J)

        # Get true_vals from the diagnostic infrastructure (the input to ForwardDiff)
        # Not directly stored on SensitivityReport, so we approximate truth magnitudes
        # from the col labels via lookup on pep.p_true and pep.ic.
        truth_proxy = Float64[]
        for label in sr.jacobian_col_labels
            role = get(sr.jacobian_col_roles, label, :unknown)
            # Try to extract a numeric truth magnitude
            v = _truth_magnitude_for_label(label, role, pep)
            push!(truth_proxy, isfinite(v) ? v : 1.0)
        end

        cond_colnorm, col_norms, svals_cn = cond_after_colnorm_scaling(J)
        cond_truth, truth_scales, svals_tr = cond_after_truth_scaling(J, truth_proxy)

        col_norm_min = minimum(col_norms)
        col_norm_max = maximum(col_norms)
        col_norm_range = (col_norm_min > 0) ? log10(col_norm_max / col_norm_min) : NaN
        improvement_cn = isfinite(cond_colnorm) ? cond_raw / cond_colnorm : NaN
        improvement_tr = isfinite(cond_truth) ? cond_raw / cond_truth : NaN

        @printf("  cond_raw         = %.3e (rank=%d/%d)\n", cond_raw, eff_rank, min(n_eqs, n_vars))
        @printf("  cond_colnorm     = %.3e  (improvement %.2fx)\n", cond_colnorm, improvement_cn)
        @printf("  cond_truth_mag   = %.3e  (improvement %.2fx)\n", cond_truth, improvement_tr)
        @printf("  col_norm range   = %.3e .. %.3e  (%.1f orders)\n",
                col_norm_min, col_norm_max, col_norm_range)

        push!(csv_lines, @sprintf("%s,%g,%d,%d,%d,%.6e,%.6e,%.6e,%.3f,%.3f,%.6e,%.6e,%.3f",
            String(model_sym), noise, n_eqs, n_vars, eff_rank,
            cond_raw, cond_colnorm, cond_truth, improvement_cn, improvement_tr,
            col_norm_min, col_norm_max, col_norm_range))

        # Per-system detail dump
        detail_path = joinpath(OUT_DIR, @sprintf("%s_noise_%g_detail.txt", String(model_sym), noise))
        open(detail_path, "w") do io
            println(io, "System: $model_sym, noise = $noise")
            println(io, "n_eqs × n_vars: $n_eqs × $n_vars (eff_rank = $eff_rank)")
            println(io, "cond_raw         = $(cond_raw)")
            println(io, "cond_colnorm     = $(cond_colnorm)  (improvement $(improvement_cn)x)")
            println(io, "cond_truth_mag   = $(cond_truth)  (improvement $(improvement_tr)x)")
            println(io, "")
            println(io, "Singular values (raw):")
            for (i, s) in enumerate(sr.singular_values)
                println(io, @sprintf("  σ[%2d] = %.6e", i, s))
            end
            println(io, "")
            println(io, "Per-column norms (raw J):")
            for (i, label) in enumerate(sr.jacobian_col_labels)
                role = get(sr.jacobian_col_roles, label, :unknown)
                println(io, @sprintf("  [%2d] %-25s role=%-15s norm=%.3e  truth_proxy=%.3e",
                    i, label, role, col_norms[i], truth_proxy[i]))
            end
            println(io, "")
            println(io, "Singular values (after column-norm rescaling):")
            for (i, s) in enumerate(svals_cn)
                println(io, @sprintf("  σ[%2d] = %.6e", i, s))
            end
            println(io, "")
            println(io, "Singular values (after truth-magnitude rescaling):")
            for (i, s) in enumerate(svals_tr)
                println(io, @sprintf("  σ[%2d] = %.6e", i, s))
            end
        end
        println("  detail → $detail_path")
    end
end

# Write CSV
open(RESULTS_CSV, "w") do io
    for line in csv_lines
        println(io, line)
    end
end

println("\n" * "="^70)
println("Summary CSV written to: $RESULTS_CSV")
println("Per-system details in: $OUT_DIR/<system>_noise_<n>_detail.txt")
println("="^70)
