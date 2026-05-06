# Concrete deep dive on forced_lv_0_1em2 at the SINGLE best-known (interp, t_eval).
# Dumps: equations, interp-vs-oracle inputs, HC result, per-equation residuals,
# S·Δd prediction vs Δx actual. No conjecture — just the saved fields.

using CSV
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf
using Dates

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

# ── Build the bilby forced_lv_0_1em2 PEP ──
parameters = @parameters alpha beta delta gamma
states = @variables x(t) yv(t)
observables = @variables y1(t) y2(t)
eqs = [
    D(x)  ~ (-0.3*sin(2.0*t) + 6.0*alpha*x - 8.0*beta*x*yv) / 2.0,
    D(yv) ~ (-12.0*gamma*yv + 4.0*delta*x*yv) / 2.0,
]
mq_orig = [y1 ~ 2.0*x, y2 ~ 2.0*yv]
ic = [0.806, 0.676]
p_true = [0.103, 0.243, 0.59, 0.165]
model, mq = ODEPE.create_ordered_ode_system("forced_lv", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2"
pep = ParameterEstimationProblem(
    "forced_lv_deep_dump", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 5.0], nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

println("[", Dates.format(now(), "HH:MM:SS"), "] Running diagnose at t_eval=4.95 with AAADGPR (best from prior sweep)...")
flush(stdout)

# Run the multi-mode diagnose with one (interp, t) combo so we get the same
# per-source DiagnosticReport machinery (equations, inputs, oracle, HC outcome).
elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep;
            interpolators = [ODEPE.InterpolatorAAADGPR],
            t_eval_points = [4.95],
            full_analysis = :all,
            save_to_disk = false,
            html_report = false,
        )
    end
end
@printf("Done in %.1f s\n", elapsed)

# Multi-mode returns ComprehensiveDiagnosticReport.full_reports[]
@assert diag_report isa ODEPE.ComprehensiveDiagnosticReport
@assert !isempty(diag_report.full_reports) "no full reports; check :all path"
sub = diag_report.full_reports[1]
@printf("\nSource: interpolator=%s, t_eval=%.4f\n",
    diag_report.interpolator_names[1], diag_report.eval_points[1])

pf = sub.polynomial_feasibility
sr = sub.sensitivity
da = sub.derivative_accuracy
eb = sub.error_budget

println("\n" * "="^72)
println("=== POLYNOMIAL TEMPLATE (the 12 equations) ===")
println("="^72)
@printf("Shape: %d eqs × %d vars (square=%s)\n", pf.n_equations, pf.n_variables, pf.is_square)
println("Variables (with role):")
for (k, vname) in enumerate(pf.variable_names)
    role = haskey(pf.variable_roles, vname) ? pf.variable_roles[vname] : :unknown
    @printf("  [%2d] %-30s  role=%s\n", k, vname, role)
end
println("\nEquations:")
for (k, eq) in enumerate(pf.equation_strings)
    println("  ($(lpad(k,2))) ", eq)
end

println("\n" * "="^72)
println("=== INTERPOLANT INPUTS vs ORACLE (the 6 derivative-data values) ===")
println("="^72)
@printf("Format: data_var | true_oracle | interpolant | abs_err | rel_err\n")
true_d = pf.data_var_true
prod_d = pf.data_var_prod
labels = pf.data_var_labels
for k in eachindex(labels)
    abs_err = abs(prod_d[k] - true_d[k])
    rel_err = abs(true_d[k]) > 0 ? abs_err / abs(true_d[k]) : NaN
    @printf("  %-50s  %+.6e  %+.6e  %.4e  %.4e\n", labels[k], true_d[k], prod_d[k], abs_err, rel_err)
end

println("\n" * "="^72)
println("=== HC.jl RESULT (closest production solution) ===")
println("="^72)
@printf("Solutions found — perfect: %d, production: %d\n",
    pf.n_solutions_perfect, pf.n_solutions_production)
@printf("‖F(x_truth, d_perfect)‖ = %.4e\n", pf.true_residual_perfect)
@printf("‖F(x_truth, d_obs)‖    = %.4e   ← residual of TRUTH given noisy data\n", pf.true_residual_production)
@printf("Closest distance perfect:    %.4e\n", pf.closest_distance_perfect)
@printf("Closest distance production: %.4e   ← x_HC distance from truth\n", pf.closest_distance_production)

println("\nVariable-by-variable: truth vs closest production root vs Δ:")
truth_vals = pf.true_values
closest = pf.closest_solution_production
@assert length(truth_vals) == length(closest) == length(pf.variable_names)
for k in eachindex(pf.variable_names)
    delta = closest[k] - truth_vals[k]
    rel = abs(truth_vals[k]) > 0 ? abs(delta) / abs(truth_vals[k]) : NaN
    @printf("  [%2d] %-30s  truth=%+.6e  prod=%+.6e  Δ=%+.4e  rel=%.4e\n",
        k, pf.variable_names[k], truth_vals[k], closest[k], delta, rel)
end

println("\n" * "="^72)
println("=== JACOBIAN / SENSITIVITY ===")
println("="^72)
@printf("cond = %.4e   effective rank = %d / %d\n",
    sr.jacobian_cond, sr.effective_rank, length(sr.singular_values))
@printf("Singular values: %s\n",
    join(map(s -> @sprintf("%.4e", s), sr.singular_values), ", "))

if !isempty(sr.data_sensitivity_matrix)
    S = sr.data_sensitivity_matrix
    rl = sr.data_sensitivity_unknown_labels
    cl = sr.data_sensitivity_data_labels
    @printf("S shape: %d × %d (rows = unknowns, cols = data vars)\n", size(S, 1), size(S, 2))
    println("S row norms:")
    for k in eachindex(rl)
        @printf("  %-30s  %.4e\n", rl[k], norm(S[k, :]))
    end
end

println("\n" * "="^72)
println("=== IFT VALIDATION: predicted Δx (= S·Δd) vs ACTUAL Δx ===")
println("="^72)
if !isnothing(eb)
    println("Fields in error_budget:")
    for f in fieldnames(typeof(eb))
        v = getfield(eb, f)
        if v isa Real
            @printf("  %-30s = %.4e\n", string(f), v)
        elseif v isa AbstractVector{<:Real} && length(v) <= 16
            @printf("  %-30s = [%s]\n", string(f),
                join(map(x -> @sprintf("%.3e", x), v), ", "))
        elseif v isa AbstractVector{<:AbstractString}
            @printf("  %-30s = [%s]\n", string(f), join(v, ", "))
        elseif v isa AbstractVector
            @printf("  %-30s = (vector len %d)\n", string(f), length(v))
        else
            @printf("  %-30s = (skipped: type %s)\n", string(f), typeof(v))
        end
    end
else
    println("(no error_budget computed)")
end

println("\n" * "="^72)
println("=== PER-UNKNOWN IFT validation (entries) ===")
println("="^72)
if !isnothing(eb) && hasproperty(eb, :entries)
    println("unknown | role | predicted Δx (S·Δd) | actual Δx | ratio (pred/act)")
    for entry in eb.entries
        mismatch_rel = isfinite(entry.delta_x_actual) && entry.delta_x_actual != 0 ?
            abs(entry.delta_x_predicted - entry.delta_x_actual) / abs(entry.delta_x_actual) : NaN
        @printf("  %-30s  %-20s  %+.4e  %+.4e  %+.4e  rel_mismatch=%.4e\n",
            entry.unknown_label, entry.unknown_role,
            entry.delta_x_predicted, entry.delta_x_actual, entry.prediction_ratio, mismatch_rel)
    end
    println()
    println("Field names of one entry: ", fieldnames(typeof(eb.entries[1])))
end

println("\nFORCED_LV_DEEP_DUMP_DONE")
