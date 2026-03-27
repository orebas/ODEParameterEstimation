#=============================================================================
     DIAGNOSTIC CASE STUDY (FAST) — daisy_mamil3 (Run 4, noise=1e-2)

Same as run_bilby_diagnostic.jl but downsampled to 201 points for speed.
Uses a different model name ("daisy_mamil3_fast") so artifacts don't collide
with the full 1501-point run.

Run from this directory:
  cd tutorials/diagnostics_benchmark_fast
  julia --startup-file=no -e 'using ODEParameterEstimation; include("run_bilby_diagnostic_fast.jl")'
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using Printf
using Logging
using CSV
using Symbolics: Num

global_logger(ConsoleLogger(stderr, Logging.Error))
redirect_stderr(devnull)

println("=" ^ 72)
println("  DIAGNOSTIC (FAST): daisy_mamil3 (downsampled to 201 pts)")
println("=" ^ 72)
println()

#=============================================================================
  MODEL DEFINITION — same bilby benchmark scaled equations
=============================================================================#

parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)

state_equations = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 +
             0.334 * a12 * x2 + 0.9990000000000001 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.9990000000000001 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
measured_quantities = [
    y1 ~ 0.5 * x1,
    y2 ~ x2,
]

p_true = [0.896, 0.461, 0.157, 0.334, 0.222]
ic = [0.434, 0.205, 0.583]

model, mq = create_ordered_ode_system(
    "daisy_mamil3_fast",
    states,
    parameters,
    state_equations,
    measured_quantities,
)

#=============================================================================
  LOAD AND DOWNSAMPLE BENCHMARK DATA
=============================================================================#

println("  Loading benchmark data and downsampling ...")
csv_data = CSV.read(joinpath(@__DIR__, "data.csv"), Tuple, header = false)

# Downsample from 1501 to 201 points (every ~7.5th point, evenly spaced indices)
n_full = length(csv_data[1])
n_target = 201
indices = round.(Int, range(1, n_full, length = n_target))

data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1][indices])
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1][indices])
end
println("  Downsampled: $(n_full) → $(length(data_sample["t"])) time points")
println()

#=============================================================================
  CONSTRUCT PEP + RUN DIAGNOSTICS
=============================================================================#

pep = ParameterEstimationProblem(
    "daisy_mamil3_fast",
    model,
    mq,
    data_sample,
    [0.0, 20.0],
    nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

println("─" ^ 72)
println("  Running diagnose_model with estimation ...")
println("─" ^ 72)
println()

report = diagnose_model(pep;
    opts = EstimationOptions(
        datasize = length(data_sample["t"]),
        time_interval = [0.0, 20.0],
    ),
    interpolators = [InterpolatorAGPUQ],
    run_estimation = true,
)

#=============================================================================
  RESULTS SUMMARY
=============================================================================#

println()
println("=" ^ 72)
println("  RESULTS SUMMARY (201-point downsampled)")
println("=" ^ 72)
println()

r = report.best

println("  Difficulty:       $(r.difficulty)")
println("  Bottleneck:       $(r.bottleneck)")
println("  Best interpolator: $(report.best_interpolator)")
@printf("  Best eval point:   t = %.3f\n", report.best_eval_point)
println()

# Derivative accuracy
da = r.derivative_accuracy
println("─" ^ 72)
println("  DERIVATIVE ACCURACY (oracle vs production interpolant)")
println("─" ^ 72)
@printf("  Worst error: %s order %d → %.2e\n", da.worst_obs, da.worst_order, da.worst_rel_error)
println()
@printf("  %-20s  %5s  %12s  %12s  %12s\n", "Observable", "Order", "True", "Interpolant", "RelErr")
println("  " * "-" ^ 65)
for e in da.entries
    status = e.rel_error < 0.01 ? "  " : e.rel_error < 0.10 ? " *" : "**"
    @printf("  %s %-18s  %5d  %12.4e  %12.4e  %12.2e\n",
        status, e.obs, e.order, e.true_val, e.interp_val, e.rel_error)
end
println()

# Polynomial feasibility
pf = r.polynomial_feasibility
println("─" ^ 72)
println("  POLYNOMIAL FEASIBILITY")
println("─" ^ 72)
println("  System size: $(pf.n_equations) eqs × $(pf.n_variables) vars (square: $(pf.is_square))")
println("  Solutions with perfect data:    $(pf.n_solutions_perfect)")
println("  Solutions with production data: $(pf.n_solutions_production)")
@printf("  Closest to truth (perfect):     %.2e\n", pf.closest_distance_perfect)
@printf("  Closest to truth (production):  %.2e\n", pf.closest_distance_production)
println()

# Sensitivity
sr = r.sensitivity
println("─" ^ 72)
println("  SENSITIVITY ANALYSIS")
println("─" ^ 72)
@printf("  Jacobian condition number: %.2e\n", sr.jacobian_cond)
println("  Effective rank: $(sr.effective_rank) / $(length(sr.singular_values))")
if length(sr.singular_values) > 0
    @printf("  Singular values: [%.2e, ..., %.2e]\n",
        sr.singular_values[1], sr.singular_values[end])
end
@printf("  Root sensitivity (||dx||/||dd||): %.2e\n", sr.root_sensitivity)
println()

if length(sr.data_sensitivity_unknown_labels) > 0 && length(sr.data_sensitivity_data_labels) > 0
    println("  Data sensitivity matrix S (top entries by magnitude):")
    S = sr.data_sensitivity_matrix
    entries = [(abs(S[i,j]), sr.data_sensitivity_unknown_labels[i],
                sr.data_sensitivity_data_labels[j], S[i,j])
               for i in axes(S,1), j in axes(S,2)]
    sort!(entries, by = x -> x[1], rev = true)
    for (k, (mag, ulabel, dlabel, val)) in enumerate(entries[1:min(8, length(entries))])
        @printf("    S[%-12s, %-12s] = %+.4e\n", ulabel, dlabel, val)
    end
    println()
end

println("─" ^ 72)
println("  OUTPUT FILES")
println("─" ^ 72)
println("  HTML report: artifacts/diagnostics/$(report.model_name)/report.html")
println("  Summary:     artifacts/diagnostics/$(report.model_name)/summary.txt")
println()
println("=" ^ 72)
println("  Done.")
println("=" ^ 72)
