#=============================================================================
         DIAGNOSTIC FRAMEWORK TUTORIAL — Runnable Examples

Run this script to see `diagnose()` on three models of increasing difficulty:
  Section 1: simple()         → :easy
  Section 2: lotka_volterra() → :moderate
  Section 3: CSTR (bilby)     → :hard

  Section 4: Standalone oracle Taylor coefficient demo
  Section 5: Programmatic access to report fields

Run: julia tutorials/diagnostics/run_diagnostics.jl
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using Printf
using Logging

# Suppress the hundreds of @info/@warn lines from SIAN / StructuralIdentifiability.
# Also suppress PosDefException spam from GP kernel search (printed to stderr by dependencies).
# The diagnostic summary tables still print via println() to stdout.
global_logger(ConsoleLogger(stderr, Logging.Error))
redirect_stderr(devnull)

println("=" ^ 72)
println("  DIAGNOSTIC FRAMEWORK TUTORIAL")
println("=" ^ 72)
println()

#=============================================================================
  SECTION 1: Easy Model — simple()

  Two states, two parameters, two observables (fully observed).
  Well-conditioned Jacobian, accurate GP derivatives.
  Expected difficulty: :easy
=============================================================================#

println("─" ^ 72)
println("  Section 1: simple() — expected :easy")
println("─" ^ 72)
println()

# diagnose_model handles: sample data → transform transcendentals → shooting points → diagnose
report_simple = diagnose_model(simple();
    opts = EstimationOptions(datasize = 101, time_interval = [-0.5, 0.5]))

println("  ► Difficulty: $(report_simple.best.difficulty)")
println("  ► Bottleneck: $(report_simple.best.bottleneck)")
println()

#=============================================================================
  SECTION 2: Moderate Model — lotka_volterra()

  Two states, three parameters, one observable (partially observed).
  Oscillatory dynamics require higher derivative orders.
  Expected difficulty: :moderate
=============================================================================#

println("─" ^ 72)
println("  Section 2: lotka_volterra() — expected :moderate")
println("─" ^ 72)
println()

report_lv = diagnose_model(lotka_volterra();
    opts = EstimationOptions(datasize = 201, time_interval = [0.0, 20.0]))

println("  ► Difficulty: $(report_lv.best.difficulty)")
println("  ► Bottleneck: $(report_lv.best.bottleneck)")
println()

#=============================================================================
  SECTION 3: Hard Model — CSTR (bilby benchmark, nondimensionalized)

  Three states (C, Temp, r_eff), four parameters, one observable.
  Has sin(0.5*t) forcing → requires transform_pep_for_estimation.
  r_eff decays catastrophically, Jacobian cond ~ 10^18.
  Expected difficulty: :hard or :infeasible

  Note: diagnose_model handles the transcendental transform automatically.
=============================================================================#

println("─" ^ 72)
println("  Section 3: CSTR (bilby nondimensionalized) — expected :hard")
println("─" ^ 72)
println()

# Define the exact nondimensionalized CSTR model
@parameters tau Tin dH_rhoCP UA_VrhoCP
@variables C(t) Temp(t) r_eff(t) y1(t)

alpha1 = 1.999863916554819     # rate scaling
alpha2 = 0.0285694845222117    # heat generation
alpha3 = 6 / 7                 # coolant base term (≈ 0.857)
alpha4 = 2 / 35                # coolant oscillation (≈ 0.057)
E_R_nondim = 12.5              # nondimensionalized activation energy

cstr_eqs = [
    D(C) ~ (1.0 - C) / (2.0 * tau) - alpha1 * r_eff * C,
    D(Temp) ~ (Tin - Temp) / (2.0 * tau) + alpha2 * dH_rhoCP * r_eff * C -
              2.0 * UA_VrhoCP * Temp + alpha3 * UA_VrhoCP +
              alpha4 * UA_VrhoCP * sin(0.5 * t),
    D(r_eff) ~ E_R_nondim * r_eff / (Temp^2) * (
        (Tin - Temp) / (2.0 * tau) + alpha2 * dH_rhoCP * r_eff * C -
        2.0 * UA_VrhoCP * Temp + alpha3 * UA_VrhoCP +
        alpha4 * UA_VrhoCP * sin(0.5 * t)
    ),
]
cstr_mq = [y1 ~ 700.0 * Temp]

cstr_p_true = OrderedDict(
    [tau, Tin, dH_rhoCP, UA_VrhoCP] .=> [0.15, 0.439, 0.307, 0.779],
)
cstr_ic = OrderedDict(
    [C, Temp, r_eff] .=> [0.127, 0.867, 0.384],
)

cstr_model, cstr_measured = create_ordered_ode_system(
    "cstr_nondim",
    [C, Temp, r_eff],
    [tau, Tin, dH_rhoCP, UA_VrhoCP],
    cstr_eqs,
    cstr_mq,
)

pep_cstr = ParameterEstimationProblem(
    "cstr_nondim", cstr_model, cstr_measured, nothing,
    [0.0, 20.0], nothing, cstr_p_true, cstr_ic, 0,
)

# diagnose_model handles sampling + transcendental transform + shooting points
report_cstr = diagnose_model(pep_cstr;
    opts = EstimationOptions(datasize = 1501, time_interval = [0.0, 20.0]),
    interpolators = [InterpolatorAAADGPR, InterpolatorAAAD, InterpolatorAGPRobust],
)

println("  ► Difficulty: $(report_cstr.best.difficulty)")
println("  ► Bottleneck: $(report_cstr.best.bottleneck)")
println("  ► Best interpolator: $(report_cstr.best_interpolator) at t=$(round(report_cstr.best_eval_point; digits=3))")
println("  ► Full reports: $(length(report_cstr.full_reports))")
println("  ► HTML report: artifacts/diagnostics/$(report_cstr.model_name)/report.html")
println()

#=============================================================================
  SECTION 4: Standalone Oracle Taylor Coefficients

  The lower-level API lets you compute oracle derivatives independently
  of the full diagnostic pipeline.
=============================================================================#

println("─" ^ 72)
println("  Section 4: Oracle Taylor coefficient demo")
println("─" ^ 72)
println()

# Sample data for simple model for use in demo
pep_demo = sample_problem_data(simple(), EstimationOptions(datasize = 101, time_interval = [-0.5, 0.5]))
t_eval = 0.0
max_order = 3

state_coeffs = compute_oracle_taylor_coefficients(pep_demo, t_eval, max_order)

println("  Oracle Taylor coefficients at t = $t_eval (order $max_order):")
for (state, coeffs) in state_coeffs
    println("    $state:")
    for k in 0:max_order
        actual_deriv = coeffs[k+1] * factorial(k)
        @printf("      order %d: Taylor coeff = %+.8e  (derivative = %+.8e)\n",
            k, coeffs[k+1], actual_deriv)
    end
end

obs_coeffs = compute_observable_taylor_coefficients(pep_demo, state_coeffs, t_eval, max_order)
println("\n  Observable Taylor coefficients:")
for (obs, coeffs) in obs_coeffs
    println("    $obs: ", round.(coeffs; digits = 10))
end

perfect = build_perfect_interpolants(pep_demo, t_eval, max_order)
println("\n  PerfectInterpolant evaluation at t = $(t_eval + 0.01):")
for (key, interp) in perfect
    println("    $key($(t_eval + 0.01)) = $(interp(t_eval + 0.01))")
end
println()

#=============================================================================
  SECTION 5: Programmatic Access to Report Fields

  The DiagnosticReport struct provides full programmatic access to every
  number computed during diagnosis.
=============================================================================#

println("─" ^ 72)
println("  Section 5: Programmatic access to report fields")
println("─" ^ 72)
println()

# Use the simple() report as an example
r = report_simple.best

println("  Model: $(r.model_name)")
println("  Difficulty: $(r.difficulty)")
println("  Timestamp: $(r.timestamp)")
println()

# Derivative accuracy
da = r.derivative_accuracy
println("  Derivative accuracy at t = $(da.t_eval):")
println("    Worst error: $(da.worst_obs) order $(da.worst_order) → $(@sprintf("%.2e", da.worst_rel_error))")
println("    Number of entries: $(length(da.entries))")
for e in da.entries
    status = e.rel_error < 0.01 ? "OK" : e.rel_error < 0.10 ? "WARN" : "FAIL"
    @printf("    [%4s] %s order %d: rel_error = %.2e\n", status, e.obs, e.order, e.rel_error)
end
println()

# Polynomial feasibility
pf = r.polynomial_feasibility
println("  Polynomial system: $(pf.n_equations) eqs × $(pf.n_variables) vars")
println("    Square: $(pf.is_square)")
println("    Solutions (perfect): $(pf.n_solutions_perfect)")
println("    Solutions (production): $(pf.n_solutions_production)")
@printf("    Closest distance to truth (perfect): %.2e\n", pf.closest_distance_perfect)
@printf("    Closest distance to truth (production): %.2e\n", pf.closest_distance_production)
println("    Variable names: ", join(pf.variable_names, ", "))
println("    Equation count: ", length(pf.equation_strings))
println("    Variable roles: ", length(pf.variable_roles), " classified")
println()

# Sensitivity
sr = r.sensitivity
@printf("  Jacobian condition number: %.2e\n", sr.jacobian_cond)
println("  Effective rank: $(sr.effective_rank) / $(length(sr.singular_values))")
if length(sr.singular_values) > 0
    @printf("  Singular values: [%.2e, ..., %.2e]\n",
        sr.singular_values[1], sr.singular_values[end])
end
println()

#=============================================================================
  SUMMARY
=============================================================================#

println("=" ^ 72)
println("  SUMMARY")
println("=" ^ 72)
println()
@printf("  %-20s  %-12s  %s\n", "Model", "Difficulty", "Bottleneck")
println("  " * "-" ^ 68)
for (name, diff, neck) in [
    ("simple", report_simple.best.difficulty, report_simple.best.bottleneck),
    ("lotka_volterra", report_lv.best.difficulty, report_lv.best.bottleneck),
    ("cstr_nondim", report_cstr.best.difficulty, report_cstr.best.bottleneck),
]
    @printf("  %-20s  %-12s  %s\n", name, diff, neck)
end
println()
println("  Artifacts saved to: artifacts/diagnostics/")
println()
