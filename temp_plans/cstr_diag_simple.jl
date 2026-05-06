# Single-interpolator diagnose() on cstr_1_0 (zero-noise bilby case).
# Now possible because diagnose() auto-applies trfn for sin(0.5*t) forcing.

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

# ── PEP construction (matches bilby script.jl for cstr_1_0) ──
parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
states = @variables C(t) Temp(t) r_eff(t)
observables = @variables y1(t)
eqs = [
    D(C)     ~ (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C,
    D(Temp)  ~ (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp
               + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t),
    D(r_eff) ~ 12.5*r_eff/(Temp^2) * ((Tin - Temp) / (2.0*tau)
               + 0.0285694845222117*dH_rhoCP*r_eff*C
               - 2.0*UA_VrhoCP*Temp
               + 0.8571428571428571*UA_VrhoCP
               + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)),
]
mq_orig = [y1 ~ 700.0*Temp]
ic = [0.843, 0.18, 0.856]
p_true = [0.385, 0.113, 0.248, 0.421]

model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep = ParameterEstimationProblem(
    "cstr_diag_simple", model, mq, _load_bilby_data(case_dir, mq),
    [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

println("[", Dates.format(now(), "HH:MM:SS"), "] Starting diagnose() on cstr_1_0 (single interp, single t_eval)")
flush(stdout)

elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep; save_to_disk = true, html_report = true)
    end
end

@printf("[%s] Done in %.1f s\n", Dates.format(now(), "HH:MM:SS"), elapsed)
flush(stdout)

# ── Print summary directly ──
println("\n=== POLYNOMIAL FEASIBILITY ===")
if !isnothing(diag_report.polynomial_feasibility)
    pf = diag_report.polynomial_feasibility
    @printf("equations × unknowns: %d × %d (square=%s)\n", pf.n_equations, pf.n_unknowns, pf.is_square)
    @printf("HC solutions (perfect data):    %d\n", pf.n_solutions_perfect)
    @printf("HC solutions (production data): %d\n", pf.n_solutions_production)
    @printf("‖F(x_truth, d_perfect)‖:    %.4g\n", pf.true_residual_perfect)
    @printf("‖F(x_truth, d_obs)‖:        %.4g\n", pf.true_residual_production)
    @printf("closest-distance from truth: %.4g\n", pf.closest_distance)
    if hasfield(typeof(pf), :variable_names)
        println("Variables:")
        for v in pf.variable_names
            println("  $v")
        end
    end
end

println("\n=== SENSITIVITY ===")
if !isnothing(diag_report.sensitivity)
    sr = diag_report.sensitivity
    @printf("Jacobian condition: %.4g\n", sr.jacobian_cond)
    @printf("Effective rank: %d\n", sr.effective_rank)
    if !isempty(sr.singular_values)
        sv = sort(sr.singular_values; rev = true)
        @printf("σ values (sorted desc): %s\n", join(map(s -> @sprintf("%.3g", s), sv), ", "))
    end
    if !isempty(sr.data_sensitivity_matrix)
        S = sr.data_sensitivity_matrix
        rl = sr.data_sensitivity_unknown_labels
        cl = sr.data_sensitivity_data_labels
        println("\nS row norms (per unknown, sorted desc):")
        rn = [(rl[k], norm(S[k, :])) for k in 1:size(S, 1)]
        sort!(rn; by = x -> -x[2])
        for (label, nrm) in rn
            @printf("  %-30s  %.4g\n", label, nrm)
        end
        println("\nS col norms (per data input, sorted desc, top 8):")
        cn = [(cl[k], norm(S[:, k])) for k in 1:size(S, 2)]
        sort!(cn; by = x -> -x[2])
        for (label, nrm) in cn[1:min(end, 8)]
            @printf("  %-50s  %.4g\n", label, nrm)
        end
        # Sloppy direction: smallest singular vector of full Jacobian
        if !isempty(sr.singular_values) && hasfield(typeof(sr), :sloppy_direction)
            println("\nSloppy direction (right-singular vec of smallest σ):")
            for (lbl, val) in zip(sr.sloppy_unknown_labels, sr.sloppy_direction)
                @printf("  %-30s  % .4g\n", lbl, val)
            end
        end
    end
end

println("\n=== ERROR BUDGET ===")
if !isnothing(diag_report.error_budget)
    eb = diag_report.error_budget
    for f in fieldnames(typeof(eb))
        v = getfield(eb, f)
        if v isa Real
            @printf("  %-30s  %.4g\n", string(f), v)
        elseif v isa AbstractVector{<:Real} && length(v) <= 8
            @printf("  %-30s  %s\n", string(f), join(map(x -> @sprintf("%.3g", x), v), ", "))
        end
    end
end

@printf("\nDifficulty: %s\n", diag_report.difficulty)
@printf("Bottleneck: %s\n", diag_report.bottleneck)
println("\nCSTR_DIAG_DONE")
