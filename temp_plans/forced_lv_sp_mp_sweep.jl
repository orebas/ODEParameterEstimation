# forced_lv_0_1em2 — full (SP × interpolator) statistics, plus MP comparison.
# Output: aggregated table to artifacts/diagnostics/seed_strategy_recon_2026_05_04/
# G3_forced_lv_sp_mp_sweep.md

using CSV
using LinearAlgebra
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf
using Statistics
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
p_true = Dict(:alpha => 0.103, :beta => 0.243, :delta => 0.59, :gamma => 0.165)
ic_true = Dict(:x => 0.806, :yv => 0.676)

model, mq = ODEPE.create_ordered_ode_system("forced_lv", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2"
pep = ParameterEstimationProblem(
    "forced_lv_sp_mp_sweep", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 5.0], nothing,
    OrderedDict(parameters .=> [0.103, 0.243, 0.59, 0.165]),
    OrderedDict(states .=> [0.806, 0.676]),
    0,
)

# Compute bilby's actual shooting points for [0, 5]
n_total = 1501
shoot_indices = ODEPE.compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
t_vec_data = pep.data_sample["t"]
all_bilby_sps = [t_vec_data[i] for i in shoot_indices]
println("Bilby's 12 shooting points: $all_bilby_sps")
flush(stdout)

# Pick 5 representative SPs (early/mid/late, skipping exact boundaries that often fail)
sp_subset = [all_bilby_sps[2], all_bilby_sps[4], all_bilby_sps[7], all_bilby_sps[10], all_bilby_sps[12]]
println("SP subset for sweep: $sp_subset")

# 5 representative interpolators covering the families
interp_methods = [
    ODEPE.InterpolatorAAADGPR,
    ODEPE.InterpolatorAGPRobust,
    ODEPE.InterpolatorAGPRobustSExRQ,
    ODEPE.InterpolatorChebyshevBIC,
    ODEPE.InterpolatorS2AAAMLE,
]
interp_names = ["aaad_gpr", "agp_robust_se", "agp_robust_se_rq", "chebyshev_bic", "s2_aaa_mle"]

# ── Run the comprehensive diagnose ──
println("\n[", Dates.format(now(), "HH:MM:SS"), "] Starting SP×interpolator sweep ($(length(interp_methods))×$(length(sp_subset)) = $(length(interp_methods)*length(sp_subset)) combos)...")
flush(stdout)

elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep;
            interpolators = interp_methods,
            t_eval_points = collect(sp_subset),
            full_analysis = :all,
            save_to_disk = true,
            html_report = true,
        )
    end
end
@printf("[%s] Sweep done in %.1f s (%.1f min)\n",
    Dates.format(now(), "HH:MM:SS"), elapsed, elapsed/60)
flush(stdout)

# ── Extract per-combo data ──
@assert diag_report isa ODEPE.ComprehensiveDiagnosticReport
@printf("Got %d full sub-reports\n", length(diag_report.full_reports))

# Build per-(SP, interp) records
records = NamedTuple[]
for (k, sub) in enumerate(diag_report.full_reports)
    pf = sub.polynomial_feasibility
    sr = sub.sensitivity
    da = sub.derivative_accuracy
    eb = sub.error_budget

    # Identify which (SP, interp) this corresponds to via the worst-error rec metadata
    # We'll use t_eval and interpolator_name from da
    t_eval = da.t_eval
    interp_name = da.interpolator_name

    # Worst rel error in derivative inputs
    worst_rel_err = isempty(da.entries) ? NaN : maximum(getfield.(da.entries, :rel_error))
    n_data_inputs = length(da.entries)

    # HC outcome
    n_perfect = pf.n_solutions_perfect
    n_prod = pf.n_solutions_production
    closest_dist = pf.closest_distance_production
    truth_residual = pf.true_residual_production

    # Sensitivity
    cond_J = sr.jacobian_cond
    eff_rank = sr.effective_rank

    # Per-parameter Δx + IFT prediction
    param_deltas = Dict{Symbol, NamedTuple}()
    if !isnothing(eb)
        for entry in eb.entries
            label = string(entry.unknown_label)
            if entry.unknown_role == :parameter
                # alpha_0, beta_0, delta_0, gamma_0 → :alpha, :beta, ...
                psym = Symbol(replace(label, "_0" => ""))
                param_deltas[psym] = (
                    actual = entry.delta_x_actual,
                    predicted = entry.delta_x_predicted,
                    ratio = entry.prediction_ratio,
                )
            end
        end
    end

    push!(records, (
        sp = round(t_eval; digits = 4),
        interp = interp_name,
        worst_rel_err = worst_rel_err,
        n_perfect = n_perfect,
        n_prod = n_prod,
        closest_dist = closest_dist,
        truth_residual = truth_residual,
        cond_J = cond_J,
        eff_rank = eff_rank,
        n_total_vars = length(pf.variable_names),
        params = param_deltas,
    ))
end

# ── Aggregate and write markdown ──
out_path = "artifacts/diagnostics/seed_strategy_recon_2026_05_04/G3_forced_lv_sp_mp_sweep.md"
mkpath(dirname(out_path))

p_true_vals = Dict(:alpha => 0.103, :beta => 0.243, :delta => 0.59, :gamma => 0.165)

open(out_path, "w") do io
    println(io, "# G3 — forced_lotka_volterra_0_1em2: SP × interpolator sweep + MP")
    println(io, "")
    println(io, "Generated: $(Dates.format(now(), "yyyy-mm-dd HH:MM"))")
    println(io, "")
    println(io, "Truth: alpha=0.103, beta=0.243, delta=0.59, gamma=0.165, IC x=0.806, yv=0.676")
    println(io, "Noise: 1e-2 relative.")
    println(io, "")
    println(io, "## Per-(SP, interp) summary table")
    println(io, "")
    println(io, "| SP | interp | worst Δd rel | n_perf | n_prod | dist→truth | cond(J) | rank | β actual Δ | β IFT pred | α actual Δ | α IFT pred |")
    println(io, "|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for r in sort(records; by = x -> (x.sp, x.interp))
        β = get(r.params, :beta, (actual = NaN, predicted = NaN))
        α = get(r.params, :alpha, (actual = NaN, predicted = NaN))
        @printf(io, "| %.3f | %s | %.2e | %d | %d | %.3e | %.3e | %d/%d | %+.3e | %+.3e | %+.3e | %+.3e |\n",
            r.sp, r.interp, r.worst_rel_err, r.n_perfect, r.n_prod,
            r.closest_dist, r.cond_J, r.eff_rank, r.n_total_vars,
            β.actual, β.predicted, α.actual, α.predicted)
    end

    println(io, "")
    println(io, "## Per-parameter statistics across all (SP, interp) combos")
    println(io, "")
    for psym in [:alpha, :beta, :delta, :gamma]
        actuals = Float64[]
        preds = Float64[]
        for r in records
            if haskey(r.params, psym) && isfinite(r.params[psym].actual)
                push!(actuals, r.params[psym].actual)
                push!(preds, r.params[psym].predicted)
            end
        end
        if isempty(actuals)
            println(io, "**$psym**: no data"); continue
        end
        true_val = p_true_vals[psym]
        # estimated values = truth + actual delta
        ests = true_val .+ actuals
        @printf(io, "**%s** (truth = %.4f, n=%d combos):\n", psym, true_val, length(actuals))
        @printf(io, "- mean Δ = %+.4f → mean estimate = %.4f (rel %.2e)\n",
            mean(actuals), mean(ests), abs(mean(ests) - true_val) / abs(true_val))
        @printf(io, "- median Δ = %+.4f → median estimate = %.4f (rel %.2e)\n",
            median(actuals), median(ests), abs(median(ests) - true_val) / abs(true_val))
        @printf(io, "- min |Δ| = %.4f at estimate = %.4f (rel %.2e)\n",
            minimum(abs.(actuals)), ests[argmin(abs.(actuals))],
            abs(ests[argmin(abs.(actuals))] - true_val) / abs(true_val))
        @printf(io, "- max |Δ| = %.4f at estimate = %.4f (rel %.2e)\n",
            maximum(abs.(actuals)), ests[argmax(abs.(actuals))],
            abs(ests[argmax(abs.(actuals))] - true_val) / abs(true_val))
        @printf(io, "- std Δ = %.4f\n", std(actuals))
        @printf(io, "- IFT prediction quality: median |pred/actual - 1| = %.2e\n",
            median(abs.(preds ./ actuals .- 1.0)))
        println(io, "")
    end

    println(io, "## Per-interpolator: aggregated across SPs")
    println(io, "")
    println(io, "| interp | n_combos | mean β err | median β err | mean α err | best dist→truth | mean cond(J) |")
    println(io, "|---|---:|---:|---:|---:|---:|---:|")
    for iname in interp_names
        rows = [r for r in records if r.interp == iname]
        if isempty(rows); continue; end
        β_errs = [abs(get(r.params, :beta, (actual = NaN,)).actual) for r in rows]
        α_errs = [abs(get(r.params, :alpha, (actual = NaN,)).actual) for r in rows]
        β_errs = filter(isfinite, β_errs); α_errs = filter(isfinite, α_errs)
        @printf(io, "| %s | %d | %.4f | %.4f | %.4f | %.4f | %.2e |\n",
            iname, length(rows),
            isempty(β_errs) ? NaN : mean(β_errs),
            isempty(β_errs) ? NaN : median(β_errs),
            isempty(α_errs) ? NaN : mean(α_errs),
            minimum(getfield.(rows, :closest_dist)),
            mean(getfield.(rows, :cond_J)))
    end

    println(io, "")
    println(io, "## Per-SP: aggregated across interpolators")
    println(io, "")
    println(io, "| SP | n_combos | best interp | best dist→truth | best β err | mean β err |")
    println(io, "|---:|---:|---|---:|---:|---:|")
    sps_seen = unique(getfield.(records, :sp))
    for sp in sort(sps_seen)
        rows = [r for r in records if r.sp == sp]
        β_errs = [abs(get(r.params, :beta, (actual = NaN,)).actual) for r in rows]
        β_errs_finite = filter(isfinite, β_errs)
        bestidx = argmin(getfield.(rows, :closest_dist))
        @printf(io, "| %.3f | %d | %s | %.4f | %.4f | %.4f |\n",
            sp, length(rows), rows[bestidx].interp,
            rows[bestidx].closest_dist,
            isempty(β_errs_finite) ? NaN : minimum(β_errs_finite),
            isempty(β_errs_finite) ? NaN : mean(β_errs_finite))
    end
end

println("\n=== SP sweep complete. Markdown: $out_path ===\n")
flush(stdout)

# ── MP comparison ──
println("\n[", Dates.format(now(), "HH:MM:SS"), "] Building MP template at all 12 bilby SPs...")
flush(stdout)

# Use the polynomialized PEP for MP (transcendentals already handled)
t_var = ModelingToolkit.get_iv(pep.model.system)
pep_t, _ = ODEPE.transform_pep_for_estimation(pep, t_var)

# Run setup once with multiple shooting points
mp_setup = with_logger(NullLogger()) do
    ODEPE.setup_parameter_estimation(pep_t;
        max_num_points = 12, interpolator = ODEPE.aaad_gpr_pivot, nooutput = true,
    )
end

println("MP setup: good_num_points = $(mp_setup.good_num_points), good_varlist length = $(length(mp_setup.good_varlist))")
println("MP good_deriv_level: $(mp_setup.good_deriv_level)")
println("MP time_index_set: $(mp_setup.time_index_set)")

# Try to solve the MP polynomial system using build_multipoint_template
mp_t_indices = shoot_indices  # bilby's 12 SPs
println("MP shooting indices: $mp_t_indices")

if isdefined(ODEPE, :build_multipoint_template) && isdefined(ODEPE, :solve_multipoint_direct)
    println("Using build_multipoint_template / solve_multipoint_direct")
    try
        mp_template = with_logger(NullLogger()) do
            ODEPE.build_multipoint_template(pep_t, mp_setup, mp_t_indices)
        end
        @printf("MP template: %d eqs × %d vars\n",
            length(mp_template.equations), length(mp_template.variables))

        mp_eval = with_logger(NullLogger()) do
            ODEPE.evaluate_multipoint_template(pep_t, mp_template, mp_t_indices)
        end
        # Try to solve
        mp_solutions = with_logger(NullLogger()) do
            ODEPE.solve_multipoint_direct(mp_eval; max_solutions = 10)
        end
        @printf("MP solutions found: %d\n", length(mp_solutions))
        if !isempty(mp_solutions)
            for (k, sol) in enumerate(mp_solutions)
                println("  Solution $k:")
                for (param, val) in pairs(sol)
                    println("    $param = $val")
                end
            end
        end
    catch e
        println("MP template/solve failed: $e")
        println(stacktrace(catch_backtrace())[1:min(5, end)])
    end
else
    println("build_multipoint_template / solve_multipoint_direct not exported — skipping MP solve")
    println("Available MP-related: ", filter(n -> contains(string(n), "multipoint") || contains(string(n), "mp_"), names(ODEPE; all = false)))
end

println("\n[", Dates.format(now(), "HH:MM:SS"), "] FORCED_LV_SP_MP_SWEEP_DONE")
