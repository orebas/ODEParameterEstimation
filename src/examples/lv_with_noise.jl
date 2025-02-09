using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using GaussianProcesses
using LineSearches
using Optim
using Statistics

include("load_examples.jl")




function custom_gpr_function(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}
	# For 1D input data, we need a matrix of size 1 × (degree+1)
	# The +1 is because we include the constant term (degree 0)
	#degree = 2
	#β = zeros(1, degree + 1)  # Initialize coefficients matrix
	#poly_mean = MeanPoly(β)

	# Add small noise proportional to y standard deviation to avoid conditioning issues
	ys_std = Statistics.std(ys)
	noise_level = 1e-6 * ys_std
	ys_noisy = ys .+ noise_level * randn(length(ys))


	kernel = SEIso(log(std(xs) / 8), 0.0)
	gp = GP(xs, ys_noisy, MeanZero(), kernel, -2.0)
	optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))

	# Create callable function
	gpr_func = x -> begin
		pred, _ = predict_f(gp, [x])
		return pred[1]
	end
	return gpr_func
end




#  interesting noise levels:
# 0.000001
#

function run_lv_with_noise()
	estimation_problem = lotka_volterra()
	datasize = 1001

	time_interval = isnothing(estimation_problem.recommended_time_interval) ? [0.0, 5.0] : estimation_problem.recommended_time_interval
	estimation_problem_with_data = sample_problem_data(estimation_problem, datasize = datasize, time_interval = time_interval, noise_level = 0.000001)
	res = analyze_parameter_estimation_problem(estimation_problem_with_data, test_mode = false, nooutput = true, interpolator = aaad)
	res2 = analyze_parameter_estimation_problem(estimation_problem_with_data, test_mode = false, nooutput = true, interpolator = custom_gpr_function)

	#if you switch "nooutput = true" to "nooutput = false", you can see analysis for how good the estimation is
	analysis_result = analyze_estimation_result(estimation_problem_with_data, res, nooutput = false)
	analysis_result2 = analyze_estimation_result(estimation_problem_with_data, res2, nooutput = false)

	#display(sol.solution)  #this contains the entire ODE solution, you probably don't want to display this

	#display(analysis_result[1])
	return 0
end

run_lv_with_noise()
