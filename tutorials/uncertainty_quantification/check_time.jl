using ODEParameterEstimation
using Statistics

pep = simple()
time_interval = [-0.5, 0.5]
opts = EstimationOptions(
    datasize = 51,
    noise_level = 0.05,
    time_interval = time_interval,
    flow = FlowDirectOpt,
    compute_uncertainty = true,
    nooutput = true,
)

pep_sampled = sample_problem_data(pep, opts)
ts = pep_sampled.data_sample["t"]

println("Time points mean: ", mean(ts))
println("Time points range: ", minimum(ts), " to ", maximum(ts))

