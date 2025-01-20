using ModelingToolkit, DifferentialEquations
using ODEParameterEstimation
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# This is a simple example showing how to set up a parameter estimation problem
# It demonstrates a basic 2-state system with 2 parameters

function simple()
	# Define the parameters and state variables
	parameters = @parameters a b c d      # Parameters to be estimated
	states = @variables x1(t) x2(t) x3(t)   # State variables that evolve with time
	observables = @variables y1(t) y2(t) y3(t)  # Variables that we can measure

	# True parameter values (used to generate synthetic data)
	p_true = [0.4, 0.8, 2.0, 0.1]
	# Initial conditions for the state variables
	ic_true = [0.333, 0.667, 0.5]

	# Define the differential equations
	equations = [
		D(x1) ~ -a * x2,    # dx1/dt = -a * x2
		D(x2) ~ b * b * x1,      # dx2/dt = b * x1
		D(x3) ~ (c^2 + d^2) * x3,
	]
	# Define which variables we can measure
	measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3]

	# Create the ODESystem using the helper function
	model, mq = create_ordered_ode_system("simple", states, parameters, equations, measured_quantities)

	# Return a ParameterEstimationProblem object
	# The last argument (0) indicates no special handling for this problem
	return ParameterEstimationProblem(
		"simple",           # Name of the problem
		model,             # The ODESystem
		mq,               # Measured quantities
		nothing,          # No specific data sample (will be generated)
		nothing,          # No specific solver
		OrderedDict(p => v for (p, v) in zip(parameters, p_true)),  # True parameters
		OrderedDict(s => v for (s, v) in zip(states, ic_true)),     # Initial conditions
		2,                 # Problem type (0 for standard problem)
	)
end

# Create the problem and run parameter estimation
prob = simple()
# Generate synthetic data with 21 points in time interval [-0.5, 0.5]
prob_with_data = sample_problem_data(prob, datasize = 21, time_interval = [-0.5, 0.5])
# Run the parameter estimation and analyze results
result = analyze_parameter_estimation_problem(prob_with_data)
