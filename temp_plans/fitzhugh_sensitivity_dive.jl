"""
Sensitivity-matrix deep dive for fitzhugh.

Three precise questions:
1. What does S = -(∂F/∂x)⁻¹ (∂F/∂d) look like at truth?
2. How does a 2.2% derivative error at order 4 amplify into 700% parameter error?
3. Does the multipoint version of S have a worse structure?

Approach: re-run diagnose() in single-point mode, extract the in-memory SensitivityReport,
print row/column norms and top entries. Then re-run in multipoint mode, do the same.
Predict δx from a calibrated δd vector and compare to the actual pool's best candidate.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/fitzhugh_sensitivity_dive.jl")'
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
const OUTDIR = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "fitzhugh_deep_dive")
mkpath(OUTDIR)

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

function build_fitzhugh()
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

# ─── Inspection helpers ─────────────────────────────────────────────────────────────

function inspect_sensitivity(report, label::AbstractString)
    sr = report.sensitivity
    S = sr.data_sensitivity_matrix
    F = sr.jacobian_matrix
    sv = sr.singular_values
    row_labels = sr.data_sensitivity_unknown_labels
    col_labels = sr.data_sensitivity_data_labels
    f_row_labels = sr.jacobian_row_labels
    f_col_labels = sr.jacobian_col_labels

    println("\n" * "="^72)
    println("Sensitivity inspection: $label")
    println("="^72)
    println("System size: $(size(F, 1)) eqs × $(size(F, 2)) unknowns")
    println("Data size: $(size(S, 2)) data variables (derivative coefficients)")
    @printf("Jacobian cond: %.4g\n", sr.jacobian_cond)
    println("Singular values (∂F/∂x): ", round.(sv; sigdigits=3))
    @printf("σ_min / σ_max = 1 / %.4g\n", sv[1] / sv[end])

    # Per-row norms (per-unknown how sensitive to data noise)
    println("\nPer-unknown total sensitivity (‖S row(p)‖):")
    @printf("%-30s %-12s\n", "unknown", "row_norm")
    row_norms = [norm(S[i, :]) for i in 1:size(S, 1)]
    perm = sortperm(row_norms; rev = true)
    for i in perm
        @printf("%-30s %-12.4g\n", row_labels[i], row_norms[i])
    end

    # Per-column norms (which derivative most affects ANY parameter)
    println("\nPer-data column norms (‖S col(d)‖):")
    @printf("%-40s %-12s\n", "data", "col_norm")
    col_norms = [norm(S[:, j]) for j in 1:size(S, 2)]
    cperm = sortperm(col_norms; rev = true)
    for j in cperm
        @printf("%-40s %-12.4g\n", col_labels[j], col_norms[j])
    end

    # Top 10 cells by absolute value
    println("\nTop 10 (unknown, data) cells of S by |value|:")
    @printf("%-30s %-40s %-12s\n", "unknown", "data", "S[i,j]")
    flat_abs = abs.(vec(S))
    flat_perm = sortperm(flat_abs; rev = true)
    for k in flat_perm[1:min(10, length(flat_perm))]
        # Linear index in column-major: k = (j-1)*nrows + i
        nrows = size(S, 1)
        i = ((k - 1) % nrows) + 1
        j = ((k - 1) ÷ nrows) + 1
        @printf("%-30s %-40s %-12.4g\n", row_labels[i], col_labels[j], S[i, j])
    end

    # Smallest-singular-vector direction (the sloppy direction in unknown-space)
    Fsvd = svd(F)
    v_min = Fsvd.V[:, end]   # right singular vector for smallest σ
    println("\nSmallest-σ right singular vector v (sloppy direction in ∂F/∂x's domain):")
    println("σ_min = ", round(Fsvd.S[end]; sigdigits=4))
    @printf("%-30s %-12s\n", "unknown", "v[i]")
    perm = sortperm(abs.(v_min); rev = true)
    for i in perm
        @printf("%-30s %-12.4g\n", f_col_labels[i], v_min[i])
    end

    return (
        S = S, F = F, sv = sv, row_labels = row_labels, col_labels = col_labels,
        f_col_labels = f_col_labels, v_min = v_min, σ_min = Fsvd.S[end],
    )
end

# ─── Run diagnose() in single-point + multi-point modes ───────────────────────────

pep = build_fitzhugh()

println("Running diagnose() in single-point mode (fast)...")
@elapsed begin
    sp_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep; save_to_disk = false, html_report = false)
    end
end
sp_inspection = inspect_sensitivity(sp_report, "single-point (fitzhugh, t=diagnose-chosen)")

# Multipoint mode: pass a list of t_eval_points
println("\n\nRunning diagnose() in multi-point mode (3 shooting points: t=0.0, 0.18, 1.0)...")
t_eval_mp = [0.0, 0.18, 1.0]
@elapsed begin
    mp_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep; save_to_disk = false, html_report = false, t_eval_points = t_eval_mp)
    end
end

# mp_report is a ComprehensiveDiagnosticReport; the per-point sensitivity is in derivative_grid
# Find the per-(interp, t_eval) reports
println("\nMulti-point report structure: ", typeof(mp_report))
if hasfield(typeof(mp_report), :derivative_grid)
    println("derivative_grid has $(length(mp_report.derivative_grid)) entries")
end

# ─── Predict pool best from S ──────────────────────────────────────────────────────

println("\n", "="^72)
println("PREDICTION: given a 2.2% derivative error at order 4, what δx does S predict?")
println("="^72)

let
    S_sp = sp_inspection.S
    col_labels = sp_inspection.col_labels
    row_labels = sp_inspection.row_labels

    # Find the order-4 column (likely "Differential(t, 4)(y1(t))")
    order4_cols = findall(c -> occursin(", 4)", c), col_labels)
    println("Order-4 data columns: ", col_labels[order4_cols])

    if !isempty(order4_cols)
        # Predict: δx = S * δd where δd has 2.2% (=0.022) at the order-4 column
        # We use 2.2% × (true value of d_4) ≈ 0.022 * 70.7 ≈ 1.56 absolute error
        δd_abs = zeros(size(S_sp, 2))
        for c in order4_cols
            δd_abs[c] = 0.022 * 70.7  # absolute error from D1 summary
        end
        δx_predicted = S_sp * δd_abs
        println("\nPredicted absolute Δx from 2.2%-rel order-4 error alone:")
        @printf("%-30s %-12s\n", "unknown", "Δx_pred")
        perm = sortperm(abs.(δx_predicted); rev = true)
        for i in perm
            @printf("%-30s %-12.4g\n", row_labels[i], δx_predicted[i])
        end

        # Now use the truth values + actual interpolant errors at all orders
        # From summary.txt at t=0.499:
        # ord 0: 1.4e-6 rel, true=-1.65 → δ ≈ 2.3e-6
        # ord 1: 1.1e-4 rel, true=-0.577 → δ ≈ 6.5e-5
        # ord 2: 8.2e-4 rel, true=2.67 → δ ≈ 2.2e-3
        # ord 3: 7.0e-3 rel, true=-17.1 → δ ≈ 0.12
        # ord 4: 2.2e-2 rel, true=70.7 → δ ≈ 1.56
        true_vals = Dict(0 => -1.65, 1 => -0.577, 2 => 2.67, 3 => -17.1, 4 => 70.7)
        rel_errs = Dict(0 => 1.4e-6, 1 => 1.1e-4, 2 => 8.2e-4, 3 => 7.0e-3, 4 => 2.2e-2)
        δd_full = zeros(size(S_sp, 2))
        for j in 1:length(col_labels)
            for ord in 0:4
                if occursin(ord == 0 ? "y1(t)" : ", $ord)", col_labels[j])
                    if ord == 0 && occursin("Differential", col_labels[j])
                        continue  # skip Diff(t, ...) when ord==0
                    end
                    δd_full[j] = abs(true_vals[ord]) * rel_errs[ord]
                    break
                end
            end
        end
        println("\nApplied δd vector (per-column derivative error):")
        @printf("%-40s %-12s\n", "data", "|δd|")
        for j in 1:length(col_labels)
            @printf("%-40s %-12.4g\n", col_labels[j], δd_full[j])
        end
        δx_full = S_sp * δd_full
        println("\nPredicted δx from full per-order error (all orders 0..4):")
        @printf("%-30s %-12s\n", "unknown", "Δx_pred")
        for i in 1:length(row_labels)
            @printf("%-30s %-12.4g\n", row_labels[i], δx_full[i])
        end

        # Compare to truth → pool-best displacement
        # truth: g=0.779, a=0.849, b=0.887; Vm=0.42, R=0.404
        # pool_best (idx 3): g=0.7925, a=2.066, b=7.15; Vm=0.42, R=0.4191
        # → Δx_actual: Δg=0.013, Δa=1.22, Δb=6.26, ΔVm=0, ΔR=0.015
        println("\nActual displacement: pool_best − truth")
        println("  Δg = 0.013, Δa = 1.22, Δb = 6.26, ΔVm = 0, ΔR = 0.015")
        println("  Norm: ", round(sqrt(0.013^2 + 1.22^2 + 6.26^2 + 0 + 0.015^2); sigdigits=4))
    end
end

println("\nSENSITIVITY_DIVE_DONE")
