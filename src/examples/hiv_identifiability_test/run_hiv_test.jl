# Test script for HIV practical identifiability
# Compares parameter estimation with:
# 1. hiv_modified_ic: Modified ICs (y(0)=1, v(0)=10) + short window (0-10 days)
# 2. hiv_short_window: Original ICs (y(0)=0) + short window (for comparison)

using ODEParameterEstimation
using Logging

include("hiv_modified.jl")

using GaussianProcesses
using LineSearches
using Optim
using Statistics

# Create log directory
log_dir = joinpath(@__DIR__, "logs")
!isdir(log_dir) && mkpath(log_dir)

# Models to test
models_to_test = Dict(
	:hiv_modified_ic => hiv_modified_ic,
	:hiv_short_window => hiv_short_window,
)

# Estimation options - using standard workflow
opts = EstimationOptions(
	datasize = 501,
	noise_level = 0.000,
	system_solver = SolverHC,
	flow = FlowStandard,
	use_si_template = true,
	polish_solver_solutions = true,
	polish_solutions = false,
	polish_maxiters = 50,
	polish_method = PolishLBFGS,
	interpolator = InterpolatorAAADGPR,
	diagnostics = true,
)

original_stdout = stdout
original_stderr = stderr

for (model_name, model_fn) in models_to_test
	log_file_path = joinpath(log_dir, "$(model_name).log")

	println(original_stdout, "\n" * "="^60)
	println(original_stdout, "Running model: $model_name")
	println(original_stdout, "="^60)

	open(log_file_path, "w") do log_stream
		with_logger(ConsoleLogger(log_stream)) do
			redirect_stdout(log_stream) do
				redirect_stderr(log_stream) do
					try
						pep = model_fn()

						println("Model: $(pep.name)")
						println("Time interval: $(pep.recommended_time_interval)")
						println("True parameters: $(pep.p_true)")
						println("Initial conditions: $(pep.ic)")
						println()

						time_interval = pep.recommended_time_interval
						model_opts = merge_options(opts, time_interval = time_interval)

						println("Using standard workflow with SI template")
						println()

						@time results = analyze_parameter_estimation_problem(
							sample_problem_data(pep, model_opts),
							model_opts,
						)

						# Extract and display c and q estimates
						println("\n" * "="^40)
						println("FOCUS ON c AND q PARAMETERS:")
						println("="^40)
						println("True values: c = 0.05, q = 0.1")
						println()

						if !isempty(results)
							for (i, res) in enumerate(results)
								c_est = get(res.parameters, :c, nothing)
								q_est = get(res.parameters, :q, nothing)
								if !isnothing(c_est) && !isnothing(q_est)
									c_err = abs(c_est - 0.05) / 0.05 * 100
									q_err = abs(q_est - 0.1) / 0.1 * 100
									println("Result $i: c = $c_est ($(round(c_err, digits=1))% error), q = $q_est ($(round(q_err, digits=1))% error)")
								end
							end
						end

						println("\nSUCCESS")
						println(original_stdout, "Model $model_name ran successfully.")
						println(original_stdout, "Log saved to: $log_file_path")
					catch e
						println("FAILURE")
						println(original_stderr, "Model $model_name failed. See $log_file_path for details.")
						showerror(log_stream, e, catch_backtrace())
					end
				end
			end
		end
	end
end

println(original_stdout, "\n" * "="^60)
println(original_stdout, "Test complete. Check logs in: $log_dir")
println(original_stdout, "="^60)
