#= Regenerate diagnostic reports — unified GP interpolator (InterpolatorAGPUQ only)
   Tests that robust + UQ share hyperparams and CSTR _obs_trfn_ sensitivity is fixed.
=#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

println("=" ^ 72)
println("  Regenerating diagnostic reports (unified GP, InterpolatorAGPUQ only)")
println("=" ^ 72)

# ── 1. simple (21 pts, 1% noise) ─────────────────────────────────────
println("\n─── simple (21 pts, 1% noise) ───")
report_simple = diagnose_model(simple();
    run_estimation = true,
    opts = EstimationOptions(
        datasize = 21, time_interval = [-0.5, 0.5],
        noise_level = 0.01,
        interpolator = InterpolatorAGPUQ),
    interpolators = [InterpolatorAGPUQ])
println("  Difficulty: $(report_simple.best.difficulty)  Bottleneck: $(report_simple.best.bottleneck)")

# ── 2. lotka_volterra (101 pts, 1% noise) ─────────────────────────────
println("\n─── lotka_volterra (101 pts, 1% noise) ───")
report_lv = diagnose_model(lotka_volterra();
    run_estimation = true,
    opts = EstimationOptions(
        datasize = 101, time_interval = [0.0, 20.0],
        noise_level = 0.01,
        interpolator = InterpolatorAGPUQ),
    interpolators = [InterpolatorAGPUQ])
println("  Difficulty: $(report_lv.best.difficulty)  Bottleneck: $(report_lv.best.bottleneck)")

# ── 3. biohydrogenation (201 pts, noiseless) ─────────────────────────
println("\n─── biohydrogenation (201 pts) ───")
report_bio = diagnose_model(biohydrogenation();
    run_estimation = true,
    opts = EstimationOptions(
        datasize = 201, time_interval = [0.0, 1.0],
        interpolator = InterpolatorAGPUQ),
    interpolators = [InterpolatorAGPUQ])
println("  Difficulty: $(report_bio.best.difficulty)  Bottleneck: $(report_bio.best.bottleneck)")

# ── 4. CSTR bilby nondim (1501 pts, noiseless) ───────────────────────
println("\n─── CSTR bilby nondim (1501 pts) ───")

@parameters tau Tin dH_rhoCP UA_VrhoCP
@variables C(t) Temp(t) r_eff(t) y1(t)

alpha1 = 1.999863916554819
alpha2 = 0.0285694845222117
alpha3 = 6 / 7
alpha4 = 2 / 35
E_R_nondim = 12.5

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
    "cstr_nondim", [C, Temp, r_eff], [tau, Tin, dH_rhoCP, UA_VrhoCP],
    cstr_eqs, cstr_mq,
)

pep_cstr = ParameterEstimationProblem(
    "cstr_nondim", cstr_model, cstr_measured, nothing,
    [0.0, 20.0], nothing, cstr_p_true, cstr_ic, 0,
)

report_cstr = diagnose_model(pep_cstr;
    run_estimation = true,
    opts = EstimationOptions(
        datasize = 1501, time_interval = [0.0, 20.0],
        interpolator = InterpolatorAGPUQ),
    interpolators = [InterpolatorAGPUQ])
println("  Difficulty: $(report_cstr.best.difficulty)  Bottleneck: $(report_cstr.best.bottleneck)")

println("\n" * "=" ^ 72)
println("  All reports saved to artifacts/diagnostics/*/report.html")
println("=" ^ 72)
