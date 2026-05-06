"""
Generate IFT Audit report for daisy_mamil3 instance 7 (noise 1e-4).
Outputs a Markdown file with full SP and MP analysis.
"""

using ODEParameterEstimation, ModelingToolkit, OrderedCollections, CSV, Printf, LinearAlgebra
using ModelingToolkit: t_nounits as t, D_nounits as D
const ODEPE = ODEParameterEstimation

# Build PEP from benchmark
parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)
state_equations = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
measured_quantities = [y1 ~ 0.5 * x1, y2 ~ x2]
ic = [0.139, 0.303, 0.457]
p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
model, mq = create_ordered_ode_system("daisy_mamil3", states, parameters, state_equations, measured_quantities)

datadir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4"
csv_data = CSV.read(joinpath(datadir, "data.csv"), Tuple, header = false)
data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end
pep = ParameterEstimationProblem("daisy_mamil3", model, mq, data_sample, [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

# Run comprehensive diagnose
println("Running diagnose...")
report = diagnose(pep; interpolators = [InterpolatorAAADGPR], save_to_disk = true, html_report = true)

sp = report.best.error_budget
mp = report.multipoint_error_budget
sp_sr = report.best.sensitivity
mpa = report.multipoint_analysis

# Write audit
rp = joinpath(@__DIR__, "..", "artifacts", "diagnostics", "daisy_mamil3", "ift_audit.md")
mkpath(dirname(rp))

open(rp, "w") do f
    println(f, "# IFT Audit: daisy_mamil3 instance 7 (noise 1e-4)\n")
    println(f, "## Question\n")
    println(f, "Can we explain the HC solution error (Δx = x_HC - x_true) as S·Δd,")
    println(f, "where S is the IFT sensitivity matrix and Δd = d_prod - d_true?\n")

    println(f, "## Model\n")
    println(f, "- **3 states** (x1, x2, x3), **5 parameters** (a12, a13, a21, a31, a01), **2 observables** (y1=0.5·x1, y2=x2)")
    println(f, "- **x3 is latent** (not directly observed)")
    println(f, "- Data: 1501 points, t ∈ [0, 20], noise 1e-4")
    println(f, "- True: a12=$(p_true[1]), a13=$(p_true[2]), a21=$(p_true[3]), a31=$(p_true[4]), a01=$(p_true[5]), x1=$(ic[1]), x2=$(ic[2]), x3=$(ic[3])\n")

    # ═══ SP ═══
    if !isnothing(sp)
        sp_nl = @sprintf("%.4f", sp.sensitivity_nonlinearity)
        sp_conc = @sprintf("%.1f", sp.sensitivity_concentration * 100)
        sp_kappa = @sprintf("%.2e", sp_sr.jacobian_cond)
        println(f, "## Single-Point (t=$(round(sp.t_eval; digits=3)), max order $(sp.max_deriv_order_used))\n")
        println(f, "- Nonlinearity mismatch: **$sp_nl** ($(sp.sensitivity_nonlinearity < 0.1 ? "linear regime — IFT reliable" : "IFT mismatch is material"))")
        println(f, "- Concentration: $sp_conc%")
        println(f, "- Jacobian κ: $sp_kappa\n")

        println(f, "### SP Data Variables\n")
        println(f, "| # | Variable | d_true | d_prod | Δd |")
        println(f, "|---|----------|--------|--------|----|")
        for j in 1:length(sp.data_labels)
            dt = j <= length(sp.data_true) ? @sprintf("%.4e", sp.data_true[j]) : "?"
            dp = j <= length(sp.data_prod) ? @sprintf("%.4e", sp.data_prod[j]) : "?"
            dd = j <= length(sp.delta_d) ? @sprintf("%+.4e", sp.delta_d[j]) : "?"
            println(f, "| $j | $(sp.data_labels[j]) | $dt | $dp | $dd |")
        end

        println(f, "\n### SP IFT Validation\n")
        println(f, "| Variable | Role | Δx_actual | Δx_predicted | |pred/actual| |")
        println(f, "|----------|------|-----------|--------------|--------------|")
        for e in sp.entries
            a = isnan(e.delta_x_actual) ? "—" : @sprintf("%+.4e", e.delta_x_actual)
            p = @sprintf("%+.4e", e.delta_x_predicted)
            r = isnan(e.prediction_ratio) ? "—" : @sprintf("%.3f", e.prediction_ratio)
            println(f, "| $(e.unknown_label) | $(e.unknown_role) | $a | $p | $r |")
        end

        # S matrix
        S = sp_sr.data_sensitivity_matrix
        xl = sp_sr.data_sensitivity_unknown_labels
        dl = sp_sr.data_sensitivity_data_labels
        if !isempty(S)
            println(f, "\n### SP Sensitivity Matrix S ($(size(S, 1))×$(size(S, 2)))\n")
            print(f, "| |")
            for d in dl
                print(f, " $d |")
            end
            println(f)
            print(f, "|---|")
            for _ in dl
                print(f, "---|")
            end
            println(f)
            for i in 1:size(S, 1)
                print(f, "| **$(xl[i])** |")
                for j in 1:size(S, 2)
                    print(f, " $(@sprintf("%.2e", S[i, j])) |")
                end
                println(f)
            end
        end
    end

    # ═══ MP ═══
    if !isnothing(mp)
        t_str = join([@sprintf("%.3f", t) for t in mp.t_eval], ", ")
        mp_nl = @sprintf("%.1f", mp.sensitivity_nonlinearity)
        mp_conc = @sprintf("%.1f", mp.sensitivity_concentration * 100)
        nl_desc = mp.sensitivity_nonlinearity < 0.1 ? "linear regime" :
                  mp.sensitivity_nonlinearity < 1.0 ? "mild first-order mismatch" : "**high first-order mismatch**"
        println(f, "\n## Multipoint 2-pt (t=[$t_str], max order $(mp.max_deriv_order_used))\n")
        println(f, "- Nonlinearity mismatch: **$mp_nl** ($nl_desc)")
        println(f, "- Concentration: $mp_conc%\n")

        if !isnothing(mpa)
            println(f, "### Multipoint Selection Metadata\n")
            println(f, "- Selection policy: `$(mpa.selection_policy)`")
            println(f, "- Comparison policy: `$(mpa.compare_policy)`")
            println(f, "- Selection reason: $(mpa.selection_reason)")
            println(f, "- Candidate combos examined: $(mpa.candidate_combo_count)")
            println(f, "- Solved combos: $(mpa.solved_combo_count)")
            println(f, "- Selected combo solved: $(mpa.selected_combo_solved)")
            println(f, "- Selected combo HC solutions: $(mpa.selected_combo_solution_count)")
            println(f, "- Selected combo worst derivative error: $(@sprintf("%.4e", mpa.selected_combo_worst_derivative_error))")
            println(f, "- Selected combo true residual: $(@sprintf("%.4e", mpa.selected_combo_true_residual))")
            println(f, "- Selected combo closest distance: $(@sprintf("%.4e", mpa.selected_combo_closest_distance))")
            println(f, "- Template strip: $(mpa.total_equation_count) total eqs → $(mpa.stripped_equation_count) kept; $(mpa.solve_var_count) solve vars, $(mpa.data_var_count) data vars")
            println(f, "- Comparison valid: $(mpa.compare_is_valid)")
            if !isempty(mpa.compare_invalid_reason)
                println(f, "- Comparison status detail: $(mpa.compare_invalid_reason)")
            end
            println(f)
        end

        println(f, "### MP Data Variables\n")
        println(f, "| # | Variable | d_true | d_prod | Δd |")
        println(f, "|---|----------|--------|--------|----|")
        for j in 1:length(mp.data_labels)
            dt = j <= length(mp.data_true) ? @sprintf("%.4e", mp.data_true[j]) : "?"
            dp = j <= length(mp.data_prod) ? @sprintf("%.4e", mp.data_prod[j]) : "?"
            dd = j <= length(mp.delta_d) ? @sprintf("%+.4e", mp.delta_d[j]) : "?"
            println(f, "| $j | $(mp.data_labels[j]) | $dt | $dp | $dd |")
        end

        println(f, "\n### MP IFT Validation\n")
        println(f, "| Variable | Role | Δx_actual | Δx_predicted | |pred/actual| | Note |")
        println(f, "|----------|------|-----------|--------------|--------------|------|")
        for e in mp.entries
            a = isnan(e.delta_x_actual) ? "—" : @sprintf("%+.4e", e.delta_x_actual)
            p = @sprintf("%+.4e", e.delta_x_predicted)
            r = isnan(e.prediction_ratio) ? "—" : @sprintf("%.1f", e.prediction_ratio)
            bad = !isnan(e.prediction_ratio) && e.prediction_ratio > 100
            note = bad ? "large mismatch" : ""
            println(f, "| $(e.unknown_label) | $(e.unknown_role) | $a | $p | $r | $note |")
        end
    end

    # ═══ Diagnosis ═══
    if !isnothing(sp) && !isnothing(mp)
        println(f, "\n## Diagnosis\n")
        bad = [e for e in mp.entries if !isnan(e.prediction_ratio) && e.prediction_ratio > 100]
        good = [e for e in mp.entries if !isnan(e.prediction_ratio) && 0.5 < e.prediction_ratio < 2.0]

        sp_nl_s = @sprintf("%.4f", sp.sensitivity_nonlinearity)
        mp_nl_s = @sprintf("%.0f", mp.sensitivity_nonlinearity)

        println(f, "- **SP nonlinearity mismatch = $sp_nl_s**")
        println(f, "- **MP nonlinearity mismatch = $mp_nl_s**")
        println(f, "- MP variables within 0.5x-2x prediction ratio: $(length(good)) / $(length(mp.entries))")
        println(f, "- MP variables with >100x mismatch: $(length(bad)) / $(length(mp.entries))")
        if !isnothing(mpa)
            println(f, "- Multipoint comparison validity: $(mpa.compare_is_valid)")
            if !isempty(mpa.compare_invalid_reason)
                println(f, "- Multipoint comparison detail: $(mpa.compare_invalid_reason)")
            end
            if !isempty(mpa.comparable_unknown_labels)
                println(f, "- Comparable unknowns: $(join(mpa.comparable_unknown_labels, ", "))")
            end
        end

        println(f, "\n### Interpretation\n")
        println(f, "This audit records the measured SP/MP first-order mismatch and template-strip facts.")
        println(f, "Any model-specific causal explanation should be drawn from the stored derivative tables,")
        println(f, "selection metadata, and strip summary above, not from hardcoded narrative claims.")
    end
end

println("Done! Report at: $rp")
println("HTML at: artifacts/diagnostics/daisy_mamil3/report.html")
