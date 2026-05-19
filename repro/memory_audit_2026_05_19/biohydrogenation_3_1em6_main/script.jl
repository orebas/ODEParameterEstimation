### Adapted from wallaby benchmark_wallaby_2026-05-17/odepe_v2_nopolish_run/biohydrogenation_3_1em6/script.jl
### Differences from wallaby:
###   - Removed `Pkg.activate(...)` cluster-specific line; uses global env per CLAUDE.md
###   - Removed `using MKL` (works without it; MKL is optional)
### Intended use: time-boxed local run via /usr/bin/time -v to capture peak RSS.
### Run: /usr/bin/time -v timeout 1800 julia --startup-file=no script.jl

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using JSON

using GaussianProcesses
using Statistics
using Optim, LineSearches
using Symbolics: Num

name = "biohydrogenation"
parameters = @parameters k5 k6 k7 k8 k9 k10
states = @variables  x4(t) x5(t) x6(t) x7(t)
observables = @variables  y1(t) y2(t)
state_equations = [
    D(x4) ~ (-8.0*k5*x4) / (8.0*(4.0*k6 + 8.0*x4)),
    D(x5) ~ ((-0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5) + (8.0*k5*x4) / (4.0*k6 + 8.0*x4)) / 0.5,
    D(x6) ~ ((-0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (10.0*k10) + (0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5)) / 0.5,
    D(x7) ~ (0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (5.0*k10),
]
measured_quantities = [
    y1 ~ 8.0*x4,
    y2 ~ 0.5*x5,
]
ic = [0.68, 0.81, 0.703, 0.684]
p_true = [0.407, 0.554, 0.488, 0.524, 0.562, 0.785]

time_interval = [0.0, 10.0]
datasize = 750

model, mq = create_ordered_ode_system(
    name,
    states,
    parameters,
    state_equations,
    measured_quantities
)

csv_data = CSV.read(joinpath(@__DIR__, "data.csv"), Tuple, header=false)
data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
data_sample["t"] = collect(Float64, csv_data[1])
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
end

pep = ParameterEstimationProblem(
    name,
    model,
    mq,
    data_sample,
    time_interval,
    nothing,
    OrderedDict(parameters .=> p_true),
    OrderedDict(states .=> ic),
    0,
)

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
    polish_solutions = false,
    polish_maxiters = 5000,
    polish_method = PolishLSOBoundedLog,
    opt_maxiters = 200000,
    opt_lb = 1e-05 * ones(length(ic) + length(p_true)),
    opt_ub = 10.0 * ones(length(ic) + length(p_true)),
    abstol = 1e-12,
    reltol = 1e-12,
    polish_maxtime = 600.0,
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    diagnostics = false,
)

# Strip the per-iter chatty diagnostics from the original wallaby script -- we only
# care about pipeline progress markers and any errors.
t_start = time()
analysis_failed = false
besterror = NaN

try
    raw_results, analysis, _ = analyze_parameter_estimation_problem(pep, opts)
    (solutions_vector, besterror, _, _, _, _, _, _) = analysis
    println("RESULT: solutions=", length(solutions_vector), " besterror=", besterror)
catch err
    analysis_failed = true
    err_str = sprint(showerror, err, catch_backtrace())
    println("ANALYSIS_ERROR: ", err_str)
finally
    elapsed = time() - t_start
    println("Wall: ", elapsed, " sec  besterror: ", besterror)
end

println("===END===")
exit(analysis_failed ? 1 : 0)
