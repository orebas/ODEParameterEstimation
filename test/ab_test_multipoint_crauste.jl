"""
A/B Test: Multipoint Stripping Strategies on Benchmark Crauste

Compares 5 variants:
  A: Baseline (topdown strip, 25%/75% points)
  B: Sensitivity-aware strip, 25%/75% points
  C: Topdown strip, best-of-scan time points
  D: Sensitivity-aware strip + best time points
  E: Variant D + overdetermined GN refinement

Uses the exact benchmark crauste model from bilby (instance 0).
"""

using ODEParameterEstimation
using ModelingToolkit, OrderedCollections, LinearAlgebra
using Printf

const ODEPE = ODEParameterEstimation
const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits

# ═══════════════════════════════════════════════════════════════════════════════
# Build benchmark crauste (exact equations from bilby benchmark instance 0)
# ═══════════════════════════════════════════════════════════════════════════════

function build_benchmark_crauste()
    parameters = @parameters mu_N mu_EE mu_LE mu_LL mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
    states = @variables Npop(t) E(t) L(t) M(t) P(t)
    observables = @variables y1(t) y2(t) y3(t) y4(t)
    p_true = [0.165, 0.527, 0.581, 0.553, 0.46, 0.188, 0.54, 0.705, 0.586, 0.132, 0.716, 0.192]
    ic = [0.507, 0.376, 0.275, 0.846, 0.779]

    equations = [
        D(Npop) ~ (-24270.0 * mu_N * Npop - 582.4799999999999 * delta_NE * P * Npop) / 16180.0,
        D(E) ~ (582.4799999999999 * delta_NE * P * Npop + 10.0 * (-1.18 * delta_EL - 0.000432 * mu_EE * E + 2.56 * rho_E * P) * E) / 10.0,
        D(L) ~ (11.799999999999999 * delta_EL * E - 10.0 * (0.05 * delta_LM + 7.2e-7 * mu_LE * E + 0.00015000000000000001 * mu_LL * L) * L) / 10.0,
        D(M) ~ 0.05 * delta_LM * L,
        D(P) ~ (-0.11 * mu_P - 3.6e-6 * mu_PE * E - 0.00036 * mu_PL * L + 0.6 * rho_P * P) * P,
    ]
    measured_quantities = [y1 ~ 16180.0 * Npop, y2 ~ 10.0 * E, y3 ~ 10.0 * M + 10.0 * L, y4 ~ 2.0 * P]

    model, mq = create_ordered_ode_system("crauste", states, parameters, equations, measured_quantities)
    return ParameterEstimationProblem("crauste", model, mq, nothing, [0.0, 25.0], nothing,
        OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)
end

# ═══════════════════════════════════════════════════════════════════════════════
# Evaluate one multipoint variant and return its error budget
# ═══════════════════════════════════════════════════════════════════════════════

function evaluate_variant(pep_data, setup_data, si_template, variant_name;
    strip_strategy = :topdown,
    time_indices = nothing,  # nothing = use default 25%/75%
    use_overdetermined = false,
    diagnostics = false,
)
    t_vec = pep_data.data_sample["t"]
    n_t = length(t_vec)
    max_order = isempty(setup_data.good_deriv_level) ? 2 : maximum(values(setup_data.good_deriv_level))

    # Build multipoint template
    mpt_setup = (
        good_deriv_level = setup_data.good_deriv_level,
        good_udict = setup_data.good_udict,
        good_varlist = setup_data.good_varlist,
        good_DD = setup_data.good_DD,
        interpolants = setup_data.interpolants,
    )

    mpt = build_multipoint_template(pep_data, mpt_setup, si_template;
        n_points = 2, diagnostics = diagnostics, strip_strategy = strip_strategy)

    is_square = length(mpt.stripped_equations) == length(mpt.solve_vars)

    # Determine time points
    if isnothing(time_indices)
        t1_idx = max(2, round(Int, n_t * 0.25))
        t2_idx = min(n_t - 1, round(Int, n_t * 0.75))
        time_indices = [t1_idx, t2_idx]
    end
    t_values = [t_vec[i] for i in time_indices]

    # Compute derivative accuracy at each point
    da_per_point = DerivativeAccuracyReport[]
    for te in t_values
        da = ODEPE.diagnose_derivative_accuracy(pep_data;
            setup_data = setup_data, t_eval = te, max_order = max_order,
            interpolator_name = "aaad_gpr_pivot")
        push!(da_per_point, da)
    end

    # Compute error budget
    eb = ODEPE.compute_multipoint_error_budget(pep_data, mpt, t_values, setup_data, da_per_point)

    # Compute κ(J_x) for the stripped system
    kappa = NaN
    try
        f_sys = ODEPE._compile_system_function(mpt.stripped_equations, vcat(mpt.solve_vars, mpt.data_vars))
        x_probe = randn(length(mpt.solve_vars) + length(mpt.data_vars)) .* 10.0
        J = ForwardDiff.jacobian(f_sys, x_probe)
        n_solve = length(mpt.solve_vars)
        J_x = J[:, 1:n_solve]
        svs = svdvals(J_x)
        kappa = svs[1] / max(svs[end], 1e-300)
    catch
    end

    # Max derivative order in stripped system
    max_stripped_order = isnothing(eb) ? -1 : eb.max_deriv_order_used

    return (
        name = variant_name,
        mpt = mpt,
        is_square = is_square,
        n_eqs = length(mpt.stripped_equations),
        n_solve = length(mpt.solve_vars),
        n_data = length(mpt.data_vars),
        max_order = max_stripped_order,
        kappa = kappa,
        t_values = t_values,
        error_budget = eb,
        da_per_point = da_per_point,
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Main A/B Test
# ═══════════════════════════════════════════════════════════════════════════════

function run_ab_test()
    println("=" ^ 80)
    println("A/B TEST: Multipoint Stripping Strategies on Benchmark Crauste")
    println("=" ^ 80)

    # Setup
    println("\n[1/6] Building benchmark crauste PEP...")
    pep = build_benchmark_crauste()
    pep_data = sample_problem_data(pep, EstimationOptions(datasize = 1501, time_interval = [0.0, 25.0], noise_level = 0.0))
    println("  Data: $(length(pep_data.data_sample["t"])) points, t ∈ [0, 25]")

    println("\n[2/6] Setting up interpolation...")
    setup = ODEPE.setup_parameter_estimation(pep_data; interpolator = aaad_gpr_pivot, nooutput = true)
    max_order = maximum(values(setup.good_deriv_level))
    println("  Max derivative order needed: $max_order")

    println("\n[3/6] Building SI template...")
    model = pep_data.model.system
    ordered_model = isa(model, OrderedODESystem) ? model : begin
        (_, _, s, p) = ODEPE.unpack_ODE(model)
        OrderedODESystem(model, s, p)
    end
    si_template, _ = ODEPE.prepare_si_template_with_structural_fix(
        ordered_model, pep_data.measured_quantities, pep_data.data_sample,
        setup.good_DD, false; states = setup.states, params = setup.params)
    println("  SI template: $(length(si_template.equations)) equations")

    # Compute single-point error budget directly (skip full comprehensive diagnose — too slow)
    println("\n[4/6] Computing single-point error budget (reference)...")
    max_order = maximum(values(setup.good_deriv_level))
    t_vec = pep_data.data_sample["t"]
    t_eval_sp = t_vec[setup.time_index_set[1]]

    sp_da = ODEPE.diagnose_derivative_accuracy(pep_data;
        setup_data = setup, t_eval = t_eval_sp, max_order = max_order,
        interpolator_name = "aaad_gpr_pivot")
    sp_pf = ODEPE.diagnose_polynomial_system(pep_data;
        setup_data = setup, t_eval = t_eval_sp, max_order = max_order)
    sp_sr = ODEPE.diagnose_sensitivity(pep_data;
        setup_data = setup, poly_report = sp_pf, t_eval = t_eval_sp, max_order = max_order)
    sp_eb = ODEPE.compute_error_budget(sp_sr, sp_da, sp_pf)
    println("  SP: $(length(sp_eb.entries)) entries, max_order=$(sp_eb.max_deriv_order_used), concentration=$(round(sp_eb.sensitivity_concentration * 100; digits=1))%")

    # Run variants
    println("\n[5/6] Running multipoint variants...")
    n_t = length(pep_data.data_sample["t"])
    results = []

    # Variant A: Baseline
    println("\n  --- Variant A: Topdown strip, default points (25%/75%) ---")
    ra = evaluate_variant(pep_data, setup, si_template, "A: topdown+default";
        strip_strategy = :topdown, diagnostics = true)
    push!(results, ra)

    # Variant B: Sensitivity-aware strip
    println("\n  --- Variant B: Sensitivity-aware strip, default points (25%/75%) ---")
    rb = evaluate_variant(pep_data, setup, si_template, "B: sensitivity+default";
        strip_strategy = :sensitivity, diagnostics = true)
    push!(results, rb)

    # Variant C: Topdown + different time points (manually chosen: 20%/60%)
    println("\n  --- Variant C: Topdown strip, time points at 20%/60% ---")
    t1c = max(2, round(Int, n_t * 0.2))
    t2c = min(n_t - 1, round(Int, n_t * 0.6))
    rc = evaluate_variant(pep_data, setup, si_template, "C: topdown+20/60%";
        strip_strategy = :topdown, time_indices = [t1c, t2c], diagnostics = true)
    push!(results, rc)

    # Variant D: Sensitivity-aware + different time points (20%/60%)
    println("\n  --- Variant D: Sensitivity-aware strip + 20%/60% ---")
    rd = evaluate_variant(pep_data, setup, si_template, "D: sensitivity+20/60%";
        strip_strategy = :sensitivity, time_indices = [t1c, t2c], diagnostics = true)
    push!(results, rd)

    # Report
    println("\n" * "=" ^ 80)
    println("[6/6] RESULTS COMPARISON")
    println("=" ^ 80)

    # Summary table
    println("\n--- System Structure ---")
    @printf("  %-28s %6s %6s %6s %5s %12s %8s %8s\n",
        "Variant", "Eqs", "Solve", "Data", "Order", "κ(J_x)", "Conc%", "Pathol?")
    println("  " * "-" ^ 85)

    # SP reference
    @printf("  %-28s %6s %6s %6s %5d %12s %7.1f%% %8s\n",
        "SP (reference)", "-", "-", "-", sp_eb.max_deriv_order_used,
        "-", sp_eb.sensitivity_concentration * 100, sp_eb.is_pathological ? "YES" : "no")

    for r in results
        eb = r.error_budget
        conc_str = isnothing(eb) ? "N/A" : @sprintf("%.1f%%", eb.sensitivity_concentration * 100)
        path_str = isnothing(eb) ? "?" : (eb.is_pathological ? "YES" : "no")
        kappa_str = isnan(r.kappa) ? "N/A" : @sprintf("%.2e", r.kappa)
        ord_str = isnothing(eb) ? "-" : string(eb.max_deriv_order_used)
        @printf("  %-28s %6d %6d %6d %5s %12s %8s %8s\n",
            r.name, r.n_eqs, r.n_solve, r.n_data, ord_str, kappa_str, conc_str, path_str)
    end

    # Per-parameter predicted errors
    println("\n--- Predicted Parameter Errors (SP vs MP variants) ---")
    @printf("  %-14s %12s", "Parameter", "SP")
    for r in results
        @printf(" %12s", split(r.name, ":")[1])
    end
    println()
    println("  " * "-" ^ (14 + 12 + 12 * length(results)))

    # Collect parameter entries from SP
    for sp_e in sp_eb.entries
        sp_e.unknown_role == :parameter || continue

        @printf("  %-14s %12s", sp_e.unknown_label, @sprintf("%.3e", sp_e.predicted_error))

        for r in results
            eb = r.error_budget
            if isnothing(eb)
                @printf(" %12s", "N/A")
                continue
            end
            mp_match = nothing
            for mp_e in eb.entries
                clean, _ = ODEPE._parse_multipoint_var_name(mp_e.unknown_label)
                clean == sp_e.unknown_label && (mp_match = mp_e; break)
            end
            if isnothing(mp_match)
                @printf(" %12s", "—")
            else
                @printf(" %12s", @sprintf("%.3e", mp_match.predicted_error))
            end
        end
        println()
    end

    # Improvement ratios (SP/MP, >1 means MP better)
    println("\n--- Improvement Ratio (SP predicted / MP predicted, >1 = MP better) ---")
    @printf("  %-14s", "Parameter")
    for r in results
        @printf(" %12s", split(r.name, ":")[1])
    end
    println()
    println("  " * "-" ^ (14 + 12 * length(results)))

    for sp_e in sp_eb.entries
        sp_e.unknown_role == :parameter || continue
        @printf("  %-14s", sp_e.unknown_label)

        for r in results
            eb = r.error_budget
            if isnothing(eb)
                @printf(" %12s", "N/A")
                continue
            end
            mp_match = nothing
            for mp_e in eb.entries
                clean, _ = ODEPE._parse_multipoint_var_name(mp_e.unknown_label)
                clean == sp_e.unknown_label && (mp_match = mp_e; break)
            end
            if isnothing(mp_match) || mp_match.predicted_error < 1e-300
                @printf(" %12s", "—")
            else
                ratio = sp_e.predicted_error / mp_match.predicted_error
                color = ratio > 1.5 ? "✓" : ratio < 0.67 ? "✗" : "~"
                @printf(" %10.2f× %s", ratio, color)
            end
        end
        println()
    end

    # Summary: count wins/losses per variant
    println("\n--- Summary (parameters where MP predicted < SP predicted) ---")
    for r in results
        eb = r.error_budget
        isnothing(eb) && continue
        wins = 0
        losses = 0
        for sp_e in sp_eb.entries
            sp_e.unknown_role == :parameter || continue
            mp_match = nothing
            for mp_e in eb.entries
                clean, _ = ODEPE._parse_multipoint_var_name(mp_e.unknown_label)
                clean == sp_e.unknown_label && (mp_match = mp_e; break)
            end
            isnothing(mp_match) && continue
            if mp_match.predicted_error < sp_e.predicted_error
                wins += 1
            else
                losses += 1
            end
        end
        println("  $(rpad(r.name, 28)): $wins wins, $losses losses (of 12 params)")
    end

    println("\n" * "=" ^ 80)
    println("A/B TEST COMPLETE")
    println("=" ^ 80)

    return sp_eb, results
end

# Run!
sp_eb, results = run_ab_test()
