# Probe 3: trace slow_fast_6_1em4 aggregate synthesis.
#
# Runs ODEPE on slow_fast_6_1em4 with diagnostics on, triggering writing of
# artifacts/diagnostics/slow_fast/synthesis_log.csv (and an aggregates pool).
# Output goes to the current working directory (artifacts/...), so we cd to a
# probe-specific output dir before running.

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON
using Symbolics: Num

const CELL_DIR = "/home/orebas/rsync-readonly-PEB/benchmark_numbat_2026-05-14/filetree/odepe_v2_polish_run/slow_fast_6_1em4"
const PROBE_DIR = joinpath(@__DIR__, "probe3_outputs")
isdir(PROBE_DIR) || mkdir(PROBE_DIR)
cd(PROBE_DIR)

println("# Probe 3: slow_fast_6_1em4 aggregate synthesis trace")
println("# Working directory: $(pwd())")
println("# (synthesis_log.csv will be written to ./artifacts/diagnostics/slow_fast/)")

# --- slow_fast model ---
name = "slow_fast"
parameters = @parameters k1 k2
states = @variables xA(t) xB(t) xC(t) eA(t) eC(t) eB(t)
observables = @variables y1(t) y2(t) y3(t) y4(t)
state_equations = [
    D(xA) ~ -0.5*k1*xA,
    D(xB) ~ (0.166*k1*xA - 0.666*k2*xB) / 0.666,
    D(xC) ~ 0.666*k2*xB,
    D(eA) ~ 0,
    D(eC) ~ 0,
    D(eB) ~ 0,
]
measured_quantities = [
    y1 ~ xC,
    y2 ~ 0.4422 * xA * eA + 0.999 * eB * xB + 1.666 * xC * eC,
    y3 ~ 1.332 * eA,
    y4 ~ 1.666 * eC,
]
ic = [0.418, 0.341, 0.358, 0.118, 0.563, 0.768]
p_true = [0.104, 0.876]
time_interval = [0.0, 10.0]

model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)
csv_data = CSV.read(joinpath(CELL_DIR, "data.csv"), Tuple, header=false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep = ParameterEstimationProblem(
    name, model, mq, data_sample, time_interval, nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

# Reduced settings for a quick run
opts = EstimationOptions(
    datasize = length(data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    shooting_points = 10,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    use_multipoint = true,
    multipoint_n_points = 2,
    multipoint_max_pairs = 5,
    synthesize_aggregate_candidates = true,  # explicit
    polish_solver_solutions = true,
    polish_solutions = true,
    polish_maxiters = 2000,
    polish_method = PolishLSOBoundedLog,
    opt_maxiters = 100000,
    opt_lb = 1e-05 * ones(length(ic) + length(p_true)),
    opt_ub = 10.0 * ones(length(ic) + length(p_true)),
    abstol = 1e-12,
    reltol = 1e-12,
    polish_maxtime = 600.0,
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    diagnostics = true,                      # crucial: enables sidecars
    nooutput = false,
)

println("\n# Running analyze_parameter_estimation_problem(pep, opts)...")
t0 = time()
raw_results, analysis, _ = analyze_parameter_estimation_problem(pep, opts)
elapsed = time() - t0
println("\n# Done in $(round(elapsed; digits=1)) s.")

# Check that synthesis_log.csv was written
synth_path = joinpath("artifacts", "diagnostics", "slow_fast", "synthesis_log.csv")
if isfile(synth_path)
    println("# synthesis_log.csv written: $synth_path")
    n_lines = countlines(synth_path)
    println("#   has $n_lines lines (1 header + $(n_lines-1) candidates)")
else
    println("# WARNING: $synth_path was NOT created.")
    println("#   Maybe synthesize_aggregate_candidates produced no candidates this run?")
end

# Also report on final solutions vector
(solutions_vector, besterror, _, _, _, _, _, _) = analysis
println("# Final solutions returned: $(length(solutions_vector))")
println("# Best error: $besterror")
