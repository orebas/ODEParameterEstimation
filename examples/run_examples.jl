include("load_examples.jl")

run_parameter_estimation_examples(datasize = 301, noise_level = 0.001, interpolator = test_gpr_function)
