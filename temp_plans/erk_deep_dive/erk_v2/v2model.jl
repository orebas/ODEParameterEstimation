using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# Additional dependencies for advanced solvers
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
using AbstractAlgebra
using KernelFunctions
using GaussianProcesses
using LineSearches
using Optim
using Statistics

function erk()
	parameters = @parameters kf1 kr1 kc1 kf2 kr2 kc2
	states = @variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t)
	observables = @variables y0(t) y1(t) y2(t)
	p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
	ic_true = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]

	equations = [
		D(S0) ~ -kf1 * E * S0 + kr1 * C1,
		D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
		D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
		D(S1) ~ -kf2 * E * S1 + kr2 * C2,
		D(S2) ~ kc2 * C2,
		D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
	]
	measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]

	model, mq = create_ordered_ode_system("erk", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"erk",
		model,
		mq,
		nothing,
		[-0.5, 0.5],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

# Estimation options matching run_examples.jl standard_opts
opts = EstimationOptions(
	use_parameter_homotopy = true,
	datasize = 1001,
	noise_level = 0.0,
	system_solver = SolverHC,
	flow = FlowStandard,
	use_si_template = true,
	polish_solver_solutions = true,
	polish_solutions = false,
	polish_maxiters = 50,
	polish_method = PolishLBFGS,
	opt_ad_backend = :enzyme,
	interpolator = InterpolatorAGPRobust,
	diagnostics = true,
)

# Run estimation
pep = erk()
time_interval = pep.recommended_time_interval
model_opts = merge_options(opts, time_interval = time_interval)
sampled = sample_problem_data(pep, model_opts)
@time meta, results = analyze_parameter_estimation_problem(sampled, model_opts)

println("\n=== ERK v2 Results ===")
println("Meta: ", meta)
println("Number of result sets: ", length(results))
for (i, r) in enumerate(results)
	println("Result $i: ", r)
end
