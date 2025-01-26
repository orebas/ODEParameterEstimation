include("load_examples.jl")

run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000)
run_parameter_estimation_examples(datasize = 1501, noise_level = 0.000, models = :hard)
