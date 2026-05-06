# Run the pipeline on daisy_mamil3_7 with bilby config and print solutions_vector[1].
# Resolves whether the wild row-1 in result.csv comes from the pipeline or the CSV write.

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

parameters = @parameters a12 a13 a21 a31 a01
states = @variables x1(t) x2(t) x3(t)
observables = @variables y1(t) y2(t)
eqs = [
    D(x1) ~ (0.5 * (-1.666 * a01 - a21 - 1.334 * a31) * x1 + 0.334 * a12 * x2 + 0.999 * a13 * x3) / 0.5,
    D(x2) ~ -0.334 * a12 * x2 + 0.5 * a21 * x1,
    D(x3) ~ (-0.999 * a13 * x3 + 0.667 * a31 * x1) / 1.5,
]
mq_orig = [y1 ~ 0.5 * x1, y2 ~ x2]
ic = [0.139, 0.303, 0.457]
p_true = [0.52, 0.7, 0.367, 0.839, 0.79]
model, mq = ODEPE.create_ordered_ode_system("daisy_mamil3", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4"
pep = ParameterEstimationProblem("daisy_mamil3_7_1em4", model, mq, _load_bilby_data(case_dir, mq), [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

# Bilby config (subset that matters for selection)
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

println("Running pipeline ...")
results = with_logger(NullLogger()) do
    ODEPE.analyze_parameter_estimation_problem(pep, opts)
end

# Unpack: results = (results_tuple, results_tuple_to_return, uq_result)
solutions_vector = results[2][1]   # results_tuple_to_return[1]
besterror = results[2][2]
best_max_error = results[2][6]

@printf("Pipeline returned: %d cluster reps. besterror=%.4g, best_max_error=%.4g\n",
    length(solutions_vector), besterror, best_max_error)

println("\nSolutions_vector[1] (the official 'winner'):")
println("  parameters: ", solutions_vector[1].parameters)
println("  states:     ", solutions_vector[1].states)
println("  err:        ", solutions_vector[1].err)

println("\nSolutions_vector[end] (the official 'worst' rep):")
println("  parameters: ", solutions_vector[end].parameters)
println("  states:     ", solutions_vector[end].states)

# Compute rel-err for solutions_vector[1] vs truth
function _max_rel(c, truth)
    rels = Float64[]
    for (sym, true_val) in truth
        for (k, v) in c.parameters
            if string(k) == string(sym)
                push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v) - Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v) - Float64(true_val)))
                break
            end
        end
        for (k, v) in c.states
            if string(k) == string(sym)
                push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v) - Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v) - Float64(true_val)))
                break
            end
        end
    end
    return isempty(rels) ? NaN : maximum(rels)
end

truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

@printf("\nrel-err of solutions_vector[1]:    %.4g\n", _max_rel(solutions_vector[1], truth))
@printf("rel-err of solutions_vector[end]:  %.4g\n", _max_rel(solutions_vector[end], truth))

# rel-err per cluster rep
println("\nAll cluster reps sorted by rel-err:")
all_rels = [(i, _max_rel(c, truth), c.err) for (i, c) in enumerate(solutions_vector)]
sorted = sort(all_rels; by = t -> isfinite(t[2]) ? t[2] : Inf)
for (i, rel, err) in first(sorted, 10)
    @printf("  pos %d in solutions_vector: rel=%.4g, err=%.4g\n", i, rel, err)
end

println("\nDAISY_CHECK_DONE")
