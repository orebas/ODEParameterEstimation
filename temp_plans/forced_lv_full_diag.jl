"""
Run diagnose() on forced_lotka_volterra_0_1em2 at bilby production config and extract
the precise sensitivity / polynomial / error-budget data into a markdown report.

Goal: stop guessing, get actual numbers for jacobian_cond, n_solutions_perfect,
S row norms, sloppy direction, etc.

Usage:
    julia --startup-file=no -e 'using ODEParameterEstimation; include("temp_plans/forced_lv_full_diag.jl")'
"""

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
const OUTDIR = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "seed_strategy_recon_2026_05_04")
mkpath(OUTDIR)

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
pep = ParameterEstimationProblem("forced_lv_diag", model, mq, _load_bilby_data(case_dir, mq), [0.0, 5.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

# Use the bilby interpolator list (12 interpolators)
bilby_interpolators = InterpolatorMethod[
    InterpolatorAAAD, InterpolatorAAADGPR, InterpolatorS2AAAMLE,
    InterpolatorAGPRobust, InterpolatorAGPRobustRQ,
    InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ,
    InterpolatorS3SE, InterpolatorS3RQ,
    InterpolatorS3SEpRQ, InterpolatorS3SExRQ, InterpolatorFHD,
]

# Run diagnose with full_analysis=:top3 (cheaper than :all). Test points span the data.
test_points = [0.05, 0.5, 1.5, 2.5, 4.5, 4.95]

println("Running diagnose() on forced_lv at bilby config (12 interpolators × $(length(test_points)) t-points, top3 full)...")
println("This will be heavy — possibly 30-60 min.")
flush(stdout)

elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep;
            interpolators = bilby_interpolators,
            t_eval_points = test_points,
            full_analysis = :top3,
            save_to_disk = true,
            html_report = true,
        )
    end
end
@printf("\nDiagnose() ran in %.1fs (%.1f min)\n", elapsed, elapsed/60)

# diag_report is ComprehensiveDiagnosticReport.
# Fields: model_name, derivative_grid::Vector{DerivativeAccuracyReport},
#         full_reports::Vector{DiagnosticReport}, interpolator_names, etc.
println("\nReport type: $(typeof(diag_report))")
fields_avail = fieldnames(typeof(diag_report))
println("Fields: $fields_avail")

# Print the per-(interp, t) full reports
println("\n", "="^80)
println("Per-(interpolator, t_eval) full reports")
println("="^80)

if hasfield(typeof(diag_report), :full_reports) && !isnothing(diag_report.full_reports)
    full = diag_report.full_reports
    @printf("\nNumber of full reports: %d\n", length(full))

    for (i, fr) in enumerate(full)
        println("\n--- Full report $i ---")
        if hasfield(typeof(fr), :model_name)
            println("Model: $(fr.model_name)")
        end
        if hasfield(typeof(fr), :difficulty)
            println("Difficulty: $(fr.difficulty)")
        end
        if hasfield(typeof(fr), :bottleneck)
            println("Bottleneck: $(fr.bottleneck)")
        end
        # Polynomial feasibility
        if hasfield(typeof(fr), :polynomial_feasibility) && !isnothing(fr.polynomial_feasibility)
            pf = fr.polynomial_feasibility
            @printf("Poly system: %d eqs × %d vars\n",
                hasfield(typeof(pf), :n_equations) ? pf.n_equations : -1,
                hasfield(typeof(pf), :n_unknowns) ? pf.n_unknowns : -1)
            if hasfield(typeof(pf), :n_solutions_perfect)
                @printf("n_solutions_perfect: %d\n", pf.n_solutions_perfect)
            end
            if hasfield(typeof(pf), :n_solutions_production)
                @printf("n_solutions_production: %d\n", pf.n_solutions_production)
            end
            if hasfield(typeof(pf), :true_residual_perfect)
                @printf("true residual (perfect data): %.4g\n", pf.true_residual_perfect)
            end
            if hasfield(typeof(pf), :true_residual_production)
                @printf("true residual (production data): %.4g\n", pf.true_residual_production)
            end
            if hasfield(typeof(pf), :closest_distance)
                @printf("closest distance from truth: %.4g\n", pf.closest_distance)
            end
            if hasfield(typeof(pf), :is_square)
                println("is_square: $(pf.is_square)")
            end
        end
        # Sensitivity
        if hasfield(typeof(fr), :sensitivity) && !isnothing(fr.sensitivity)
            sr = fr.sensitivity
            if hasfield(typeof(sr), :jacobian_cond)
                @printf("jacobian cond: %.4g\n", sr.jacobian_cond)
            end
            if hasfield(typeof(sr), :effective_rank)
                println("effective rank: $(sr.effective_rank)")
            end
            if hasfield(typeof(sr), :singular_values) && !isnothing(sr.singular_values)
                sv = sr.singular_values
                @printf("singular values: σ_max=%.4g, σ_min=%.4g, ratio=%.4g\n",
                    maximum(sv), minimum(sv), maximum(sv)/minimum(sv))
                println("all SV: ", round.(sv; sigdigits=3))
            end
            # S matrix row norms (per-unknown amplification)
            if hasfield(typeof(sr), :data_sensitivity_matrix) && !isnothing(sr.data_sensitivity_matrix)
                S = sr.data_sensitivity_matrix
                if size(S, 1) > 0 && size(S, 2) > 0
                    println("\nS matrix shape: $(size(S))")
                    row_lbls = hasfield(typeof(sr), :data_sensitivity_unknown_labels) ?
                        sr.data_sensitivity_unknown_labels : ["row_$i" for i in 1:size(S,1)]
                    col_lbls = hasfield(typeof(sr), :data_sensitivity_data_labels) ?
                        sr.data_sensitivity_data_labels : ["col_$j" for j in 1:size(S,2)]

                    println("Per-unknown row norm (sensitivity to all data):")
                    rn = [(row_lbls[k], norm(S[k, :])) for k in 1:size(S, 1)]
                    sort!(rn; by = x -> -x[2])
                    for (label, nrm) in first(rn, min(15, length(rn)))
                        @printf("  %-30s %-12.4g\n", label, nrm)
                    end

                    println("\nPer-data column norm (which derivative most amplifies anything):")
                    cn = [(col_lbls[k], norm(S[:, k])) for k in 1:size(S, 2)]
                    sort!(cn; by = x -> -x[2])
                    for (label, nrm) in first(cn, min(10, length(cn)))
                        @printf("  %-40s %-12.4g\n", label, nrm)
                    end
                end
            end
            # Smallest right singular vector of jacobian_matrix = sloppy direction
            if hasfield(typeof(sr), :jacobian_matrix) && !isnothing(sr.jacobian_matrix)
                J = sr.jacobian_matrix
                if size(J, 1) > 0 && size(J, 2) > 0
                    Fsvd = svd(Matrix(J))
                    v_min = Fsvd.V[:, end]
                    σ_min = Fsvd.S[end]
                    f_col_lbls = hasfield(typeof(sr), :jacobian_col_labels) ?
                        sr.jacobian_col_labels : ["col_$j" for j in 1:size(J, 2)]
                    println("\nSmallest-σ right singular vector (sloppy direction):")
                    @printf("  σ_min = %.4g\n", σ_min)
                    perm = sortperm(abs.(v_min); rev = true)
                    for k in first(perm, min(10, length(v_min)))
                        @printf("  %-30s %-12.4g\n", f_col_lbls[k], v_min[k])
                    end
                end
            end
        end
        # Error budget (signed IFT)
        if hasfield(typeof(fr), :error_budget) && !isnothing(fr.error_budget)
            eb = fr.error_budget
            println("\nError budget report present.")
            if hasfield(typeof(eb), :nonlinearity_metric)
                @printf("nonlinearity metric: %.4g\n", eb.nonlinearity_metric)
            end
        end
    end
else
    println("(no full_reports field on diag_report or it's empty)")
end

println("\nFORCED_LV_FULL_DIAG_DONE")
