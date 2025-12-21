# Debug script to trace equation/variable count mismatch
using Logging

# Enable all debug logging
global_logger(ConsoleLogger(stderr, Logging.Debug))

using ODEParameterEstimation

# Include example models
include("src/examples/load_examples.jl")

println("=" ^ 80)
println("RUNNING: cstr_fixed_activation")
println("=" ^ 80)

# Create the problem
pep = cstr_fixed_activation()

# Create options
opts = EstimationOptions(
    datasize = 501,
    noise_level = 0.0,
    time_interval = [0.0, 20.0],
    shooting_points = 8,
)

# Run the estimation
@time results = analyze_parameter_estimation_problem(
    sample_problem_data(pep, opts),
    opts,
)

println("\n" * "=" ^ 80)
println("RESULTS:")
println("=" ^ 80)
println(results)
