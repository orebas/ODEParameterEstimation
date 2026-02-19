#=
ERK with full polish (forward-simulate + BFGS optimization)
============================================================
Tests whether loss-based polishing can recover correct parameters
even though the algebraic backsolve fails catastrophically.
=#

using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation
using OrderedCollections

@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1 * E * S0 + kr1 * C1,
    D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
    D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
    D(S1) ~ -kf2 * E * S1 + kr2 * C2,
    D(S2) ~ kc2 * C2,
    D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]
@named model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
ic = [5.0, 0, 0, 0, 0, 0.65]
time_interval = [0.0, 20.0]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]

solver = Vern9()
datasize = 100

data_sample = ODEParameterEstimation.sample_data(
    model, measured_quantities, time_interval,
    Dict(parameters .=> p_true), Dict(states .=> ic),
    datasize; solver=solver
)

name = "erk_polish_test"
ordered_model, mq = ODEParameterEstimation.create_ordered_ode_system(
    name, states, parameters, eqs, measured_quantities
)

pep = ParameterEstimationProblem(
    name, ordered_model, mq, data_sample, time_interval, nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0,
)

# KEY: polish_solutions = true, using ForwardDiff (not Enzyme)
opts = EstimationOptions(
    use_parameter_homotopy = false,
    datasize = 101,
    noise_level = 0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    polish_solver_solutions = true,    # quick NLLS polish of HC solutions
    polish_solutions = true,           # FULL forward-simulate + BFGS polish
    polish_maxiters = 200,             # generous iteration budget
    polish_method = PolishLBFGS,
    opt_ad_backend = :forward,         # ForwardDiff (Enzyme fails on adaptive solvers)
    interpolator = InterpolatorAGPRobust,
    diagnostics = true
)

println("Starting ERK estimation WITH full polish...")
println("(polish_solutions=true, polish_maxiters=200, ForwardDiff)")
meta, results = analyze_parameter_estimation_problem(pep, opts)
println("\nDone!")
