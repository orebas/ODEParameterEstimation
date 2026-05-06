# Verify flex_arm_0_1em4 against current code with bilby config.
# If rel-err improves vs the bilby-saved 7.5%, the gate bug may have been fixed.
# If it stays at ~7.5% or worse, the gate fix is still pending.

using CSV
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf

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

parameters = @parameters Jm Jt bm bt k
states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)
observables = @variables y1(t) y2(t)
eqs = [
    D(theta_m) ~ omega_m,
    D(omega_m) ~ (0.5 - 0.1*bm*omega_m - 20.0*k*(-0.5*theta_t + 0.5*theta_m)) / (0.1*Jm),
    D(theta_t) ~ omega_t,
    D(omega_t) ~ (-0.05*bt*omega_t - 20.0*k*(0.5*theta_t - 0.5*theta_m)) / (0.05*Jt),
]
mq_orig = [y1 ~ 0.5*theta_m, y2 ~ 0.5*theta_t]
ic = [0.623, 0.681, 0.53, 0.188]
p_true = [0.419, 0.445, 0.592, 0.156, 0.758]
model, mq = ODEPE.create_ordered_ode_system("flexible_arm", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/flexible_arm_0_1em4"
pep = ParameterEstimationProblem("flexible_arm_0_1em4", model, mq, _load_bilby_data(case_dir, mq), [0.0, 10.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

opts = EstimationOptions(
    datasize = length(pep.data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    interpolators = InterpolatorMethod[
        InterpolatorAAAD, InterpolatorAAADGPR, InterpolatorS2AAAMLE,
        InterpolatorAGPRobust, InterpolatorAGPRobustRQ,
        InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ,
        InterpolatorS3SE, InterpolatorS3RQ,
        InterpolatorS3SEpRQ, InterpolatorS3SExRQ, InterpolatorFHD,
    ],
    shooting_points = 12,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 5000,
    polish_method = PolishBFGS,
    abstol = 1e-13, reltol = 1e-13,
    polish_maxtime = 1200.0,
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    diagnostics = false,
    nooutput = true,
    save_system = false,
    use_sensitivity_seeds = false,
)

println("Running flex_arm_0_1em4 on current code with bilby config...")
flush(stdout)
elapsed = @elapsed begin
    results = with_logger(NullLogger()) do
        ODEPE.analyze_parameter_estimation_problem(pep, opts)
    end
end

solutions_vector = results[2][1]
besterror = results[2][2]
best_max_error = results[2][6]

@printf("\nElapsed: %.1fs\n", elapsed)
@printf("Pipeline returned: %d cluster reps\n", length(solutions_vector))
@printf("besterror = %.4g, best_max_error = %.4g\n", besterror, best_max_error)

println("\nSolutions_vector[1] (the winner):")
println("  parameters: ", solutions_vector[1].parameters)
println("  states:     ", solutions_vector[1].states)
println("  err:        ", solutions_vector[1].err)

# rel-err
function _max_rel(c, truth)
    rels = Float64[]
    for (sym, true_val) in truth
        for (k, v) in c.parameters
            if string(k) == string(sym)
                push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v)-Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v)-Float64(true_val)))
                break
            end
        end
        for (k, v) in c.states
            if string(k) == string(sym)
                push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v)-Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v)-Float64(true_val)))
                break
            end
        end
    end
    return isempty(rels) ? NaN : maximum(rels)
end

truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

@printf("\nrel-err of winner: %.4g\n", _max_rel(solutions_vector[1], truth))
println("\nbilby reported (2026-03-09): rel-err = 0.075 (= 7.5%)")
@printf("Current code rel-err: %.4g (= %.2f%%)\n",
    _max_rel(solutions_vector[1], truth), 100*_max_rel(solutions_vector[1], truth))

# Compare top 5 by rel
all_rels = [(i, _max_rel(c, truth), c.err) for (i, c) in enumerate(solutions_vector)]
println("\nTop 5 cluster reps by rel-err:")
sorted = sort(all_rels; by = t -> isfinite(t[2]) ? t[2] : Inf)
for (i, rel, err) in first(sorted, 5)
    @printf("  pos %d in solutions_vector: rel=%.4g, err=%.4g\n", i, rel, err)
end

println("\nFLEX_ARM_CURRENT_DONE")
