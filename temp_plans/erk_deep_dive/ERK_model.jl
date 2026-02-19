

using ModelingToolkit, DifferentialEquations
#using Sundials
using ODEParameterEstimation
using OrderedCollections
# , ParameterEstimation
# solver = CVODE_BDF()
solver = AutoVern9(Rodas4P())
@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [ kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [ 
			D(S0) ~ -kf1*E*S0 + kr1*C1,
			D(C1) ~ kf1*E*S0 - (kr1 + kc1 )*C1,
			D(C2) ~ kc1*C1 - (kr2 + kc2 )*C2 + kf2*E*S1,
			D(S1) ~ -kf2*E*S1 + kr2*C2,
			D(S2) ~ kc2*C2,
			D(E) ~ -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2 )*C2,
			]
@named model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2 ] 
ic = [5.0, 0, 0, 0, 0, 0.65 ]
time_interval = [0., 20.]
# time_points = [0, 0.5, 2, 3.25, 3.75, 5, 10, 20]
# datasize = 20
datasize = 1000
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13, ] # 98.80] # True Parameters
# p_true = rand(0.0:0.01:1.0, 6)

data_sample = ODEParameterEstimation.sample_data(model, 
	measured_quantities, time_interval, 
	Dict(parameters .=> p_true), Dict(states .=> ic), 
	datasize; solver = solver)
	# uneven_sampling = true, uneven_sampling_times = time_points)

name="test"

model, mq = create_ordered_ode_system(
    name,
    states,
    parameters,
    eqs,
    measured_quantities
)

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

# Create EstimationOptions with desired settings
# You can customize these options based on your needs
opts = EstimationOptions(


   use_parameter_homotopy = true,
        datasize = 2001,
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
        #interpolator = InterpolatorAAAD,
        interpolator = InterpolatorAGPRobust,
        diagnostics = true,
	try_more_methods=false,

    # datasize = length(data_sample["t"]),
    #noise_level = 0.000,
#   interpolator = InterpolatorAAADGPR,
    # system_solver = SolverHC,
    # flow = FlowStandard,
    # use_si_template = true,
    # polish_solver_solutions = false,
    # polish_solutions = false,
    # polish_maxiters = 50,
    # polish_method = PolishLBFGS,
    # opt_ad_backend = :enzyme,
    # diagnostics = true
)








# Run the analysis with the selected options
meta, results = analyze_parameter_estimation_problem(
    pep,
    opts,  # Use the main opts, or replace with opts_fast, opts_accurate, or opts_noisy
)

nothing

