# magnetic_levitation_sinusoidal_scaled: known-broken (SIAN overflow / excessive derivative levels)
# Saved from benchmark suite for future debugging
# Run with: julia run_magnetic_levitation.jl (global environment, NOT --project)

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using Symbolics: Num
using ModelingToolkit: t_nounits as t, D_nounits as D

name = "magnetic_levitation_sinusoidal_scaled"
parameters = @parameters m_lin k_lin b_lin
states = @variables x(t) vel(t) i(t)
observables = @variables y1(t)
state_equations = [
    D(x) ~ 5.0 * vel,
    D(vel) ~ (10.0 * (-2.5 + 5.0 * i) - 0.2 * b_lin * vel - k_lin * x) / (0.010000000000000002 * m_lin),
    D(i) ~ (5.0 - 10.0 * i + sin(5.0 * t)) / 0.25,
]
measured_quantities = [
    y1 ~ 0.01 * x,
]
p_true = [0.5, 0.5, 0.5]
ic = [0.5, 0.5, 0.5]

time_interval = [0.0, 5.0]
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
