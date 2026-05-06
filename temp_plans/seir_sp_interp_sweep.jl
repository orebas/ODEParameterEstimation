# SEIR_2_1em4 SP × interpolator sweep — per-(SP, interp, param) CSV for
# aggregation experiment. Sloppier case than forced_lv per project memory.

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

# ── Build the bilby seir_2_1em4 PEP ──
parameters = @parameters a b nu
states = @variables S(t) E(t) In(t) Npop(t)
observables = @variables y1(t) y2(t)
eqs = [
    D(S) ~ (-15840.0*b*In*S) / (3960000.0*Npop),
    D(E) ~ ((15840.0*b*In*S) / (2000.0*Npop) - 6.0*nu*E) / 20.0,
    D(In) ~ (-4.0*a*In + 6.0*nu*E) / 10.0,
    D(Npop) ~ 0,
]
mq_orig = [y1 ~ 10.0*In, y2 ~ 2000.0*Npop]
ic = [0.647, 0.182, 0.418, 0.321]      # bilby seir_2 IC (S, E, In, Npop)
p_true_vals = [0.187, 0.414, 0.277]    # bilby seir_2 truth (a, b, nu)

model, mq = ODEPE.create_ordered_ode_system("seir", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4"
pep = ParameterEstimationProblem(
    "seir_sp_sweep", model, mq, _load_bilby_data(case_dir, mq),
    nothing, nothing,  # default time interval / solver
    OrderedDict(parameters .=> p_true_vals),
    OrderedDict(states .=> ic),
    0,
)

# Compute bilby's actual shooting points
n_total = length(pep.data_sample["t"])
shoot_indices = ODEPE.compute_shooting_indices(12, n_total; warp = true, beta = 3.0)
t_vec_data = pep.data_sample["t"]
all_bilby_sps = [t_vec_data[i] for i in shoot_indices]
println("Bilby's 12 shooting points: $all_bilby_sps")
flush(stdout)

# Pick 3 representative SPs (interior emphasis)
sp_subset = [all_bilby_sps[4], all_bilby_sps[7], all_bilby_sps[10]]
println("SP subset for sweep: $sp_subset")

# 3 representative interpolators (drop S2 + Chebyshev for speed; per prior Froissart + boundary findings)
interp_methods = [
    ODEPE.InterpolatorAAADGPR,
    ODEPE.InterpolatorAGPRobust,
    ODEPE.InterpolatorAGPRobustSExRQ,
]
interp_names = ["aaad_gpr", "agp_robust", "agp_robust_se_rq"]

# ── Run the comprehensive diagnose ──
println("\n[", Dates.format(now(), "HH:MM:SS"), "] Starting seir SP×interp sweep ($(length(interp_methods))×$(length(sp_subset)) = $(length(interp_methods)*length(sp_subset)) combos)...")
flush(stdout)

elapsed = @elapsed begin
    diag_report = with_logger(NullLogger()) do
        ODEPE.diagnose(pep;
            interpolators = interp_methods,
            t_eval_points = collect(sp_subset),
            full_analysis = :all,
            save_to_disk = true,
            html_report = false,    # skip HTML to save time
        )
    end
end
@printf("[%s] Sweep done in %.1f s (%.1f min)\n",
    Dates.format(now(), "HH:MM:SS"), elapsed, elapsed/60)
flush(stdout)

# ── Extract per-(SP, interp, param) records and dump to CSV ──
@assert diag_report isa ODEPE.ComprehensiveDiagnosticReport

p_true_dict = Dict(:a => 0.187, :b => 0.414, :nu => 0.277)
ic_truth_dict = Dict(:S => 0.647, :E => 0.182, :In => 0.418, :Npop => 0.321)

# Per-record CSV: SP, interp, param, role, truth, estimate, Δ_actual, Δ_predicted, ift_mismatch
csv_path = "artifacts/diagnostics/seed_strategy_recon_2026_05_04/seir_per_record.csv"
mkpath(dirname(csv_path))

n_records_ref = Ref(0)
open(csv_path, "w") do io
    println(io, "sp,interp,param_or_ic_label,role,truth_val,estimate,actual_delta,predicted_delta,ift_mismatch,worst_dd_rel,cond_J,n_solutions_prod,closest_dist")
    for sub in diag_report.full_reports
        pf = sub.polynomial_feasibility
        sr = sub.sensitivity
        da = sub.derivative_accuracy
        eb = sub.error_budget
        t_eval = da.t_eval
        interp_name = da.interpolator_name
        worst_rel_err = isempty(da.entries) ? NaN : maximum(getfield.(da.entries, :rel_error))
        cond_J = sr.jacobian_cond
        n_prod = pf.n_solutions_production
        closest_dist = pf.closest_distance_production

        if !isnothing(eb)
            for entry in eb.entries
                label = string(entry.unknown_label)
                role = string(entry.unknown_role)
                # truth: pull from p_true_dict or ic_truth_dict if recognizable
                trim = replace(label, "_0" => "")
                truth_val = if entry.unknown_role == :parameter && haskey(p_true_dict, Symbol(trim))
                    p_true_dict[Symbol(trim)]
                elseif (entry.unknown_role == :state_ic || entry.unknown_role == :state_derivative) && haskey(ic_truth_dict, Symbol(trim))
                    ic_truth_dict[Symbol(trim)]
                else
                    NaN
                end
                estimate = isfinite(truth_val) ? truth_val + entry.delta_x_actual : NaN
                ift_mismatch = isfinite(entry.delta_x_actual) && entry.delta_x_actual != 0 ?
                    abs(entry.delta_x_predicted - entry.delta_x_actual) / abs(entry.delta_x_actual) : NaN
                @printf(io, "%.5f,%s,%s,%s,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%.6e,%d,%.6e\n",
                    t_eval, interp_name, label, role,
                    truth_val, estimate, entry.delta_x_actual, entry.delta_x_predicted,
                    ift_mismatch, worst_rel_err, cond_J, n_prod, closest_dist)
                n_records_ref[] += 1
            end
        end
    end
end

@printf("Wrote %d records to %s\n", n_records_ref[], csv_path)
println("[", Dates.format(now(), "HH:MM:SS"), "] SEIR_SP_INTERP_SWEEP_DONE")
