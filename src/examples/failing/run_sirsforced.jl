# sirsforced_scaled: known-broken (SIAN overflow / excessive derivative levels)
# Saved from benchmark suite for future debugging
# Run with: julia run_sirsforced.jl (global environment, NOT --project)

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using Symbolics: Num
using ModelingToolkit: t_nounits as t, D_nounits as D

name = "sirsforced_scaled"
parameters = @parameters b0 b1 g M mu nu
states = @variables i(t) r(t) s(t) x1(t) x2(t)
observables = @variables y1(t) y2(t)
state_equations = [
    D(i) ~ (-0.334 * (1.428 * mu + 1.714 * nu) * i + 0.095524 * b0 * (1.0 + 0.763048 * b1 * x1) * s * i) / 0.334,
    D(r) ~ (-0.666 * (0.858 * g + 1.428 * mu) * r + 0.572476 * nu * i) / 0.666,
    D(s) ~ 1.428 * mu + 0.571428 * g * r - 1.428 * mu * s - 0.095524 * b0 * (1.0 + 0.763048 * b1 * x1) * s * i,
    D(x1) ~ -1.4262158920539727 * M * x2,
    D(x2) ~ 0.9144225690276111 * M * x1,
]
measured_quantities = [
    y1 ~ 0.334 * i,
    y2 ~ 0.666 * r,
]
p_true = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
ic = [0.5, 0.5, 0.5, 0.5, 0.5]

time_interval = [0.0, 30.0]
datasize = 1001

model, mq = create_ordered_ode_system(
    name,
    states,
    parameters,
    state_equations,
    measured_quantities
)

# Generate synthetic data
solver = AutoVern9(Rodas4P())
prob = ODEProblem(
    model,
    OrderedDict(states .=> ic),
    (time_interval[1], time_interval[2]),
    OrderedDict(parameters .=> p_true),
)
ode_solution = solve(prob, solver, saveat = range(time_interval[1], time_interval[2], length = datasize),
    abstol = 1e-14, reltol = 1e-14)

data_sample = OrderedDict{Union{String,Num}, Vector{Float64}}()
data_sample["t"] = ode_solution.t
for (i, eq) in enumerate(mq)
    data_sample[Num(eq.lhs)] = [Symbolics.substitute(eq.rhs, OrderedDict(states .=> ode_solution[:, j])) for j in 1:length(ode_solution.t)]
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
    datasize = datasize,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 200000,
    polish_method = PolishBFGS,
    opt_maxiters = 200000,
    opt_lb = 1e-5 * ones(length(ic) + length(p_true)),
    opt_ub = 10.0 * ones(length(ic) + length(p_true)),
    abstol = 1e-13,
    reltol = 1e-13,
    diagnostics = true,
    profile_phases = true,
)

meta, results = analyze_parameter_estimation_problem(pep, opts)

(solutions_vector, besterror,
    best_min_error,
    best_mean_error,
    best_median_error,
    best_max_error,
    best_approximation_error,
    best_rms_error) = results

println("\n" * "="^60)
println("Parameter Estimation Complete!")
println("="^60)
println("\nNumber of solutions found: ", length(solutions_vector))
if !isempty(solutions_vector)
    best_sol = solutions_vector[1]
    println("\nBest solution:")
    println("  States: ", best_sol.states)
    println("  Parameters: ", best_sol.parameters)
    println("  Error metrics:")
    println("    Best error: ", besterror)
    println("    Min error: ", best_min_error)
    println("    Mean error: ", best_mean_error)
    println("    Median error: ", best_median_error)
    println("    Max error: ", best_max_error)
    println("    Approximation error: ", best_approximation_error)
    println("    RMS error: ", best_rms_error)
end
