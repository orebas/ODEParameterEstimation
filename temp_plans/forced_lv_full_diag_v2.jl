# Full diagnose() run on forced_lotka_volterra_0_1em2 at the bilby production config
# (5 interpolators × 6 t_eval × top3). Now possible because diagnose() auto-applies
# the trfn transform.
#
# Output: HTML report + JSON in artifacts/diagnostics/<model>/, plus a markdown extract
# at artifacts/diagnostics/seed_strategy_recon_2026_05_04/G3_forced_lv_diagnostic.md.

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

# ── PEP construction (matches bilby script.jl for forced_lotka_volterra_0_1em2) ──
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
    "forced_lv_diag_v2", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 5.0], nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

# ── Run diagnose() at production-ish config ──
println("[", Dates.format(now(), "HH:MM:SS"), "] Starting diagnose() on forced_lv_0_1em2 (5 interp × 6 t × top3)")
flush(stdout)

interpolator_methods = [
    ODEPE.InterpolatorAAADGPR,
    ODEPE.InterpolatorAGPRobust,
    ODEPE.InterpolatorAGPRobustSExRQ,
    ODEPE.InterpolatorAGPUQ,
    ODEPE.InterpolatorChebyshevBIC,
]
t_eval_points = [0.05, 0.5, 1.5, 2.5, 4.5, 4.95]

elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep;
            interpolators = interpolator_methods,
            t_eval_points = t_eval_points,
            full_analysis = :top3,
            save_to_disk = true,
            html_report = true,
        )
    end
end

@printf("[%s] Done in %.1f s (%.1f min)\n",
    Dates.format(now(), "HH:MM:SS"), elapsed, elapsed/60)
flush(stdout)

# ── Markdown extraction ──
out_path = "artifacts/diagnostics/seed_strategy_recon_2026_05_04/G3_forced_lv_diagnostic.md"
mkpath(dirname(out_path))

open(out_path, "w") do io
    println(io, "# G3 — forced_lotka_volterra_0_1em2 full diagnostic")
    println(io, "")
    println(io, "Generated: $(Dates.format(now(), "yyyy-mm-dd HH:MM"))")
    println(io, "")
    println(io, "Driver: `temp_plans/forced_lv_full_diag_v2.jl`")
    println(io, "")
    println(io, "Config: 5 interpolators × 6 t_eval × top3 full reports.")
    println(io, "Total elapsed: $(round(elapsed; digits = 1)) s.")
    println(io, "")
    println(io, "## Per-(interpolator, t_eval) summary")
    println(io, "")

    if hasfield(typeof(diag_report), :full_reports) && !isnothing(diag_report.full_reports)
        for (key, sub) in diag_report.full_reports
            println(io, "### Source: $(key)")
            println(io, "")
            if !isnothing(sub.polynomial_feasibility)
                pf = sub.polynomial_feasibility
                println(io, "**Polynomial feasibility:**")
                @printf(io, "- equations × unknowns: %d × %d (square=%s)\n",
                    pf.n_equations, pf.n_unknowns, pf.is_square)
                @printf(io, "- HC solutions (perfect data):    %d\n", pf.n_solutions_perfect)
                @printf(io, "- HC solutions (production data): %d\n", pf.n_solutions_production)
                @printf(io, "- ‖F(x_truth, d_perfect)‖:    %.4g\n", pf.true_residual_perfect)
                @printf(io, "- ‖F(x_truth, d_obs)‖:        %.4g\n", pf.true_residual_production)
                @printf(io, "- closest-distance from truth (production roots): %.4g\n",
                    pf.closest_distance)
                println(io, "")
            end
            if !isnothing(sub.sensitivity)
                sr = sub.sensitivity
                println(io, "**Sensitivity:**")
                @printf(io, "- Jacobian condition: %.4g\n", sr.jacobian_cond)
                @printf(io, "- effective rank: %d\n", sr.effective_rank)
                if !isempty(sr.singular_values)
                    sv = sort(sr.singular_values; rev = true)
                    @printf(io, "- σ values: %s\n", join(map(s -> @sprintf("%.3g", s), sv), ", "))
                end
                if !isempty(sr.data_sensitivity_matrix)
                    S = sr.data_sensitivity_matrix
                    rl = sr.data_sensitivity_unknown_labels
                    cl = sr.data_sensitivity_data_labels
                    println(io, "")
                    println(io, "  S row norms (per unknown, sorted desc):")
                    rn = [(rl[k], norm(S[k, :])) for k in 1:size(S, 1)]
                    sort!(rn; by = x -> -x[2])
                    for (label, nrm) in rn[1:min(end, 8)]
                        @printf(io, "  - `%-30s`  %.4g\n", label, nrm)
                    end
                    println(io, "")
                    println(io, "  S col norms (per data input, sorted desc, top 8):")
                    cn = [(cl[k], norm(S[:, k])) for k in 1:size(S, 2)]
                    sort!(cn; by = x -> -x[2])
                    for (label, nrm) in cn[1:min(end, 8)]
                        @printf(io, "  - `%-50s`  %.4g\n", label, nrm)
                    end
                end
                println(io, "")
            end
            if !isnothing(sub.error_budget)
                eb = sub.error_budget
                println(io, "**Error budget (signed IFT):**")
                if hasfield(typeof(eb), :predicted_norm) && hasfield(typeof(eb), :actual_norm)
                    @printf(io, "- ‖S·Δd‖ (predicted): %.4g\n", eb.predicted_norm)
                    @printf(io, "- ‖Δx_actual‖:        %.4g\n", eb.actual_norm)
                end
                if hasfield(typeof(eb), :nonlinearity_metric)
                    @printf(io, "- nonlinearity ‖Δx_pred - Δx_act‖/‖Δx_act‖: %.4g\n",
                        eb.nonlinearity_metric)
                end
                println(io, "")
            end
            println(io, "---")
            println(io, "")
        end
    else
        println(io, "(no per-source full reports — check raw HTML output)")
    end

    println(io, "## Notes")
    println(io, "")
    println(io, "- Sin(2t) forcing was auto-polynomialized (sin_term, cos_term auxiliary states).")
    println(io, "- Production MP concatenates SP templates with shared params; equation count")
    println(io, "  scales as K·M (M shooting points, K eqs per SP) for N unknowns. See HTML")
    println(io, "  report for actual equation dump.")
end

println("Markdown extract: $out_path")
println("FORCED_LV_FULL_DIAG_V2_DONE")
