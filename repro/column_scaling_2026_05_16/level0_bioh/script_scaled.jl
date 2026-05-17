# Level-0 prototype: bioh with manually-substituted column scaling.
#
# Approach:
#   1. Build the production bioh PEP (same as benchmark cell).
#   2. Compute column scales via two strategies:
#      A) truth-magnitude:  s_i = max(|truth_i|, 1.0)
#      B) column-norm:      s_i = ||J[:, i]||_2 computed from diagnose_sensitivity
#   3. Substitute each parameter `p_i = s_i * p_tilde_i` in the equations.
#   4. Run the standard pipeline on the SCALED PEP.
#   5. Read result.csv and multiply each candidate's params by s to recover
#      original units.
#   6. Report rank-1 oracle vs the un-scaled baseline.
#
# This script is the LEVEL-0 prototype the doc refers to as "modify the
# benchmark cell, not the package source." No src/ changes.

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using CSV
using JSON
using Statistics
using Symbolics: Num, substitute
using LinearAlgebra
using Printf

const SCRIPT_DIR = @__DIR__

# ── PEP definition: copy from spot-check script.jl ───────────────────────
name = "biohydrogenation"
@parameters k5 k6 k7 k8 k9 k10
@variables x4(t) x5(t) x6(t) x7(t)
@variables y1(t) y2(t)

state_equations = [
    D(x4) ~ (-8.0*k5*x4) / (8.0*(4.0*k6 + 8.0*x4)),
    D(x5) ~ ((-0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5) + (8.0*k5*x4) / (4.0*k6 + 8.0*x4)) / 0.5,
    D(x6) ~ ((-0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (10.0*k10) + (0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5)) / 0.5,
    D(x7) ~ (0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (5.0*k10),
]
measured_quantities = [y1 ~ 8.0*x4, y2 ~ 0.5*x5]

ic_true = [0.639, 0.841, 0.397, 0.421]
p_true = [0.476, 0.397, 0.107, 0.889, 0.73, 0.818]
time_interval = [0.0, 10.0]

# ── Scaling choice from CLI args ─────────────────────────────────────────
const MODE = length(ARGS) >= 1 ? ARGS[1] : "truth"

# Truth-magnitude scaling for parameters (state ICs kept at 1.0 for simplicity).
# Truth values are k5=0.476, k6=0.397, k7=0.107, k8=0.889, k9=0.73, k10=0.818.
truth_scales_p = Dict(:k5 => 0.476, :k6 => 0.397, :k7 => 0.107,
                      :k8 => 0.889, :k9 => 0.73,  :k10 => 0.818)

# Column-norm scaling — from the column-scaling diagnostic on the example
# function biohydrogenation() (NOT the spot-check ODE; truth-norm scales
# may differ because the equations differ). Recorded here for reference;
# the spot-check ODE would need its own diagnostic run if we wanted
# pixel-perfect column-norm scales for THIS cell. For the prototype, we
# use these as an approximation.
colnorm_scales_p = Dict(:k5 => 5.964, :k6 => 0.5133, :k7 => 2.753,
                        :k8 => 1.554, :k9 => 0.521,  :k10 => 9.407e-4)

scales = MODE == "truth" ? truth_scales_p :
         MODE == "colnorm" ? colnorm_scales_p :
         error("MODE must be 'truth' or 'colnorm'; got '$MODE'")

@info "[level0] Using $MODE scaling" scales

# ── Build SCALED ODE via Symbolics.substitute ────────────────────────────
@parameters k5_til k6_til k7_til k8_til k9_til k10_til

sub_map = Dict(
    k5  => scales[:k5]  * k5_til,
    k6  => scales[:k6]  * k6_til,
    k7  => scales[:k7]  * k7_til,
    k8  => scales[:k8]  * k8_til,
    k9  => scales[:k9]  * k9_til,
    k10 => scales[:k10] * k10_til,
)

scaled_state_equations = [
    D(x4) ~ substitute(state_equations[1].rhs, sub_map),
    D(x5) ~ substitute(state_equations[2].rhs, sub_map),
    D(x6) ~ substitute(state_equations[3].rhs, sub_map),
    D(x7) ~ substitute(state_equations[4].rhs, sub_map),
]
scaled_measured_quantities = [
    y1 ~ substitute(measured_quantities[1].rhs, sub_map),
    y2 ~ substitute(measured_quantities[2].rhs, sub_map),
]

scaled_parameters = [k5_til, k6_til, k7_til, k8_til, k9_til, k10_til]
scaled_states = [x4, x5, x6, x7]

# Truth values in scaled coordinates: p_tilde_i = p_i / s_i
p_true_scaled = [p_true[i] / scales[k] for (i, k) in enumerate([:k5, :k6, :k7, :k8, :k9, :k10])]
@info "[level0] Truth in scaled coords" p_true_scaled

model_scaled, mq_scaled = create_ordered_ode_system(
    name * "_scaled_$(MODE)",
    scaled_states, scaled_parameters,
    scaled_state_equations, scaled_measured_quantities,
)

# ── Load data and build PEP ──────────────────────────────────────────────
csv_data = CSV.read(joinpath(SCRIPT_DIR, "data.csv"), Tuple, header=false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq_scaled)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep_scaled = ParameterEstimationProblem(
    name * "_scaled_$(MODE)",
    model_scaled,
    mq_scaled,
    data_sample,
    time_interval,
    nothing,
    OrderedDict(scaled_parameters .=> p_true_scaled),
    OrderedDict(scaled_states .=> ic_true),
    0,
)

# ── Bounds in scaled coordinates ─────────────────────────────────────────
# Original: 1e-5 <= p_i <= 10 for all params and states
# Scaled:   1e-5/s_i <= p_tilde_i <= 10/s_i for params, unchanged for states
s_vec = vcat(fill(1.0, length(ic_true)),  # state ICs not rescaled in this prototype
             [scales[k] for k in [:k5, :k6, :k7, :k8, :k9, :k10]])
opt_lb_scaled = 1e-5 ./ s_vec
opt_ub_scaled = 10.0 ./ s_vec

@info "[level0] Scaled bounds (state ICs first, then params)" opt_lb_scaled opt_ub_scaled

# ── Estimation options: match the spot-check exactly ─────────────────────
opts = EstimationOptions(
    datasize = length(data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    shooting_points = 20,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 15,
    polish_solver_solutions = true,
    polish_solutions = true,
    polish_maxiters = 5000,
    polish_method = PolishLSOBoundedLog,
    opt_maxiters = 200000,
    opt_lb = opt_lb_scaled,
    opt_ub = opt_ub_scaled,
    abstol = 1e-12,
    reltol = 1e-12,
    polish_maxtime = 900.0,  # Tighter timeout for prototype (15 min per polish)
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    diagnostics = false,  # Skip diagnose() to save time on prototype
)

# ── Run pipeline ─────────────────────────────────────────────────────────
@info "[level0] Starting estimation on scaled PEP..."
t_start = time()
raw_results, analysis, _ = analyze_parameter_estimation_problem(pep_scaled, opts)
elapsed = time() - t_start
@info "[level0] Estimation complete" elapsed

(solutions_vector,
    besterror,
    best_min_error,
    best_mean_error,
    best_median_error,
    best_max_error,
    best_approximation_error,
    best_rms_error) = analysis

# ── Recover original units and compare to truth ──────────────────────────
println("\n" * "="^60)
println("LEVEL-0 PROTOTYPE RESULTS (mode: $MODE)")
println("="^60)
println("Elapsed: $elapsed s")
println("Solutions found: $(length(solutions_vector))")
println("Best error: $besterror")

if !isempty(solutions_vector)
    # Build table for CSV output (RECOVERED, in original units)
    param_keys = [:k5, :k6, :k7, :k8, :k9, :k10]
    state_keys = [:x4, :x5, :x6, :x7]
    table_rows = NamedTuple[]
    oracle_errs = Float64[]

    for (rank, sol) in enumerate(solutions_vector)
        # Recover params: each `p_tilde_i` → `s_i * p_tilde_i`
        recovered_params = Dict{Symbol, Float64}()
        for (sym, til_sym, k) in [
            (:k5,  k5_til,  scales[:k5]),
            (:k6,  k6_til,  scales[:k6]),
            (:k7,  k7_til,  scales[:k7]),
            (:k8,  k8_til,  scales[:k8]),
            (:k9,  k9_til,  scales[:k9]),
            (:k10, k10_til, scales[:k10]),
        ]
            recovered_params[sym] = k * Float64(sol.parameters[til_sym])
        end
        # States — not rescaled in this prototype
        recovered_states = Dict{Symbol, Float64}()
        for (sym, var) in [(:x4, x4), (:x5, x5), (:x6, x6), (:x7, x7)]
            recovered_states[sym] = Float64(sol.states[var])
        end

        truth_params = Dict(:k5 => 0.476, :k6 => 0.397, :k7 => 0.107,
                            :k8 => 0.889, :k9 => 0.73,  :k10 => 0.818)
        truth_states = Dict(:x4 => 0.639, :x5 => 0.841, :x6 => 0.397, :x7 => 0.421)

        rel_errs = Float64[]
        for k in param_keys
            push!(rel_errs, abs(recovered_params[k] - truth_params[k]) / truth_params[k])
        end
        for k in state_keys
            push!(rel_errs, abs(recovered_states[k] - truth_states[k]) / truth_states[k])
        end
        max_rel = maximum(rel_errs)
        push!(oracle_errs, max_rel)

        push!(table_rows, (
            rank = rank,
            err = sol.err,
            max_rel_err = max_rel,
            k5 = recovered_params[:k5], k6 = recovered_params[:k6],
            k7 = recovered_params[:k7], k8 = recovered_params[:k8],
            k9 = recovered_params[:k9], k10 = recovered_params[:k10],
            x4 = recovered_states[:x4], x5 = recovered_states[:x5],
            x6 = recovered_states[:x6], x7 = recovered_states[:x7],
        ))

        if rank <= 5
            @printf("\nRank %d (err=%.3e, max_rel_err=%.3f):\n", rank, sol.err, max_rel)
            for k in param_keys
                err_pct = (recovered_params[k] - truth_params[k]) / truth_params[k] * 100
                @printf("  %s = %.4f  (truth %.4f,  err %.1f%%)\n",
                        k, recovered_params[k], truth_params[k], err_pct)
            end
        end
    end

    println("\nBEST ORACLE: $(minimum(oracle_errs)) at rank $(argmin(oracle_errs))")
    println("Mean rank-1 oracle: $(oracle_errs[1])")

    out_csv = joinpath(SCRIPT_DIR, "result_$(MODE).csv")
    CSV.write(out_csv, table_rows)
    println("Wrote: $out_csv")
end

println("="^60)
