# fitzhugh_nagumo: 0 solutions found, maxrel=Inf
# Failing benchmark from survey_benchmark/fitzhugh_nagumo_scaled_0_0
# Run with: julia run_fitzhugh_nagumo.jl (global environment, NOT --project)

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq
using OrderedCollections
using CSV
using Symbolics: Num
using ModelingToolkit: t_nounits as t, D_nounits as D

name = "fitzhugh_nagumo_scaled"
parameters = @parameters g a b
states = @variables Vm(t) R(t)
observables = @variables y1(t)
state_equations = [
    D(Vm) ~ (-3.0)*g*(0.5*R - 2.0*Vm + (2.6666666666666665)*(Vm^3)),
    D(R) ~ (-0.4*a - 2.0*Vm + 0.2*b*R) / (3.0*g),
]
measured_quantities = [
    y1 ~ -2.0*Vm,
]
ic = [0.519, 0.175]
p_true = [0.654, 0.553, 0.312]

time_interval = [0.0, 0.03]
datasize = 1001

model, mq = create_ordered_ode_system(
    name,
    states,
    parameters,
    state_equations,
    measured_quantities
)

# Load data from CSV
csv_data = CSV.read(joinpath(@__DIR__, "fitzhugh_nagumo_scaled_0_0_data.csv"), Tuple, header=false)
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

# Run the analysis
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
    println("\nBest solution:")
    best_sol = solutions_vector[1]
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
