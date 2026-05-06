# Simpler diagnose() call on forced_lv — single interpolator, single t_eval (default).
# Just get ONE sensitivity matrix + one polynomial-feasibility report. Much faster than
# the 12×6×top3 full sweep that hung.

using CSV
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf

const ODEPE = ODEParameterEstimation

function _load_bilby_data(case_dir, mq)
    csv_data = CSV.read(joinpath(case_dir, "data.csv"), Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

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
model, mq = ODEPE.create_ordered_ode_system("forced_lv", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2"
pep = ParameterEstimationProblem("forced_lv_diag_simple", model, mq, _load_bilby_data(case_dir, mq), [0.0, 5.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

println("Running default diagnose() — single AAADGPR interpolator, auto-chosen t_eval ...")
flush(stdout)
elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep; save_to_disk = true, html_report = true)
    end
end
@printf("\nElapsed: %.1fs\n", elapsed)
flush(stdout)

# The single-point return is a DiagnosticReport (not ComprehensiveDiagnosticReport).
println("Report type: $(typeof(diag_report))")

# Direct field access
if hasfield(typeof(diag_report), :difficulty)
    @printf("Difficulty: %s\n", diag_report.difficulty)
end
if hasfield(typeof(diag_report), :bottleneck)
    println("Bottleneck: $(diag_report.bottleneck)")
end

# Polynomial feasibility
if hasfield(typeof(diag_report), :polynomial_feasibility) && !isnothing(diag_report.polynomial_feasibility)
    pf = diag_report.polynomial_feasibility
    println("\n--- Polynomial feasibility ---")
    @printf("Equations × Variables: %d × %d (square=%s)\n",
        hasfield(typeof(pf), :n_equations) ? pf.n_equations : -1,
        hasfield(typeof(pf), :n_unknowns) ? pf.n_unknowns : -1,
        hasfield(typeof(pf), :is_square) ? string(pf.is_square) : "?")
    @printf("HC solutions (perfect data):    %d\n", pf.n_solutions_perfect)
    @printf("HC solutions (production data): %d\n", pf.n_solutions_production)
    @printf("True residual (perfect):    %.4g\n", pf.true_residual_perfect)
    @printf("True residual (production): %.4g\n", pf.true_residual_production)
    @printf("Closest distance from truth: %.4g\n", pf.closest_distance)
end

# Sensitivity
if hasfield(typeof(diag_report), :sensitivity) && !isnothing(diag_report.sensitivity)
    sr = diag_report.sensitivity
    println("\n--- Sensitivity ---")
    @printf("Jacobian condition: %.4g\n", sr.jacobian_cond)
    @printf("Effective rank: %d\n", sr.effective_rank)

    sv = sr.singular_values
    @printf("σ_max=%.4g, σ_min=%.4g, ratio=%.4g\n",
        maximum(sv), minimum(sv), maximum(sv)/minimum(sv))
    println("All singular values (sorted desc):")
    for s in sort(sv; rev=true)
        @printf("  %.4g\n", s)
    end

    # S matrix row norms
    if hasfield(typeof(sr), :data_sensitivity_matrix) && !isnothing(sr.data_sensitivity_matrix)
        S = sr.data_sensitivity_matrix
        if size(S, 1) > 0 && size(S, 2) > 0
            row_lbls = sr.data_sensitivity_unknown_labels
            col_lbls = sr.data_sensitivity_data_labels
            println("\nS matrix shape: $(size(S))")
            println("\nS row norms (per-unknown total amplification, sorted desc):")
            rn = [(row_lbls[k], norm(S[k, :])) for k in 1:size(S, 1)]
            sort!(rn; by = x -> -x[2])
            for (label, nrm) in rn
                @printf("  %-30s %-12.4g\n", label, nrm)
            end
            println("\nS col norms (per-data-input amplification, sorted desc):")
            cn = [(col_lbls[k], norm(S[:, k])) for k in 1:size(S, 2)]
            sort!(cn; by = x -> -x[2])
            for (label, nrm) in cn
                @printf("  %-50s %-12.4g\n", label, nrm)
            end
            # Top S entries
            println("\nTop 10 |S[i,j]| entries:")
            flat_abs = abs.(vec(S))
            sorted_idx = sortperm(flat_abs; rev=true)
            for k in first(sorted_idx, 10)
                nrows = size(S, 1)
                i = ((k - 1) % nrows) + 1
                j = ((k - 1) ÷ nrows) + 1
                @printf("  S[%-25s, %-50s] = %-12.4g\n", row_lbls[i], col_lbls[j], S[i, j])
            end
        end
    end
    # Smallest right singular vector of jacobian = sloppy direction
    if hasfield(typeof(sr), :jacobian_matrix) && !isnothing(sr.jacobian_matrix)
        J = sr.jacobian_matrix
        if size(J, 1) > 0 && size(J, 2) > 0
            Fsvd = svd(Matrix(J))
            v_min = Fsvd.V[:, end]
            σ_min = Fsvd.S[end]
            f_col_lbls = sr.jacobian_col_labels
            println("\nSmallest-σ right singular vector (sloppy direction in unknown space):")
            @printf("σ_min = %.4g\n", σ_min)
            for k in sortperm(abs.(v_min); rev=true)
                @printf("  %-30s %-12.4g\n", f_col_lbls[k], v_min[k])
            end
        end
    end
end

# Derivative accuracy
if hasfield(typeof(diag_report), :derivative_accuracy) && !isnothing(diag_report.derivative_accuracy)
    da = diag_report.derivative_accuracy
    println("\n--- Derivative accuracy ---")
    @printf("Worst rel err: %.4g (obs %s, order %d)\n",
        da.worst_rel_error, da.worst_obs, da.worst_order)
end

println("\nFORCED_LV_SIMPLE_DIAG_DONE")
