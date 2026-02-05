#=============================================================================
                    FIRST EXAMPLE: Getting Started with ODEParameterEstimation

This file demonstrates the basic usage pattern for parameter estimation.
For more examples, see load_examples.jl and models/*.jl
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                         STEP 1: DEFINE YOUR MODEL

Create a function that returns a ParameterEstimationProblem.
This includes the ODE system, observed quantities, and true parameter values.
=============================================================================#

function quadratic_test()
	# Define symbolic parameters and state variables
	parameters = @parameters a
	states = @variables x1(t) 
	observables = @variables y1(t) 

	# True parameter values (what we're trying to recover)
	p_true = [0.1]
	ic_true = [2.0]

	# Define the ODE system
	equations = [
		D(x1) ~ -a * x1,
	]

	# Define which quantities are measured/observed
	measured_quantities = [y1 ~ x1]

	# Create the ordered ODE system (maintains parameter ordering)
	model, mq = create_ordered_ode_system("quadratic_test", states, parameters, equations, measured_quantities)

	# Return the ParameterEstimationProblem
	return ParameterEstimationProblem(
		"quadratic_test",                    # name
		model,                               # ODE model
		mq,                                  # measured quantities
		nothing,                             # data (will be sampled)
		[0.0, 2.0],                          # recommended time interval
		nothing,                             # solver (use default)
		OrderedDict(parameters .=> p_true),  # true parameters
		OrderedDict(states .=> ic_true),     # true initial conditions
		0,                                   # unidentifiable count
	)
end

#=============================================================================
                         STEP 2: RUN THE ESTIMATION

Configure estimation options and run the analysis.
=============================================================================#

function run_first_example()
	# Create the problem definition
	estimation_problem = quadratic_test()

	# Configure estimation options
	opts = EstimationOptions(
        datasize = 201,
        noise_level = 0,
        system_solver = SolverHC,
        flow = FlowStandard,
        use_si_template = true,
        polish_solver_solutions = true,
        polish_solutions = false,
        polish_maxiters = 50,
        polish_method = PolishLBFGS,
        opt_ad_backend = :enzyme,
        #interpolator = InterpolatorAGP,
        #interpolator = InterpolatorAAADGPR,
        interpolator = InterpolatorAAAD,
        diagnostics = true)
	# Determine time interval
	time_interval = isnothing(estimation_problem.recommended_time_interval) ?
		[0.0, 5.0] : estimation_problem.recommended_time_interval

	# Update options with the time interval
	opts = merge_options(opts, time_interval = time_interval)

	# Sample synthetic data from the problem
	estimation_problem_with_data = sample_problem_data(estimation_problem, opts)

	# Run the parameter estimation analysis
	results = analyze_parameter_estimation_problem(estimation_problem_with_data, opts)

	return results
end

# Run the example
results = run_first_example()

#=============================================================================
                         ALTERNATIVE CONFIGURATIONS

Examples of different estimation settings you can use:
=============================================================================#

# High-accuracy estimation with more data points:
# opts = EstimationOptions(
#     datasize = 1001,
#     noise_level = 0.0,
#     interpolator = InterpolatorAAADGPR,  # Gaussian process interpolation
#     system_solver = SolverHC,
#     flow = FlowStandard,
# )

# Noisy data estimation:
# opts = EstimationOptions(
#     datasize = 501,
#     noise_level = 0.01,  # 1% noise
#     interpolator = InterpolatorAAADGPR,
# )

# Direct optimization (no polynomial solving):
# opts = EstimationOptions(
#     datasize = 501,
#     flow = FlowDirectOpt,
#     opt_maxiters = 100000,
# )
