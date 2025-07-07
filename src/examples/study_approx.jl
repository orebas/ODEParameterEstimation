using ODEParameterEstimation
#using PEtab
using Statistics
using Plots
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using Symbolics
using DataFrames
using OrderedCollections
using OrdinaryDiffEq
using GaussianProcesses
using Loess
using BaryRational
using Printf
using Dierckx
using LinearSolve
using LinearAlgebra
using LineSearches
using Optim
using ForwardDiff
using Suppressor
using TaylorDiff
using Random




include("load_examples.jl")

"""
    test_gpr_function(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}

Creates a Gaussian Process Regression interpolator for testing purposes.
This is a simple wrapper around GPR functionality for use in approximation studies.

# Arguments
- `xs::AbstractArray{T}`: X coordinates
- `ys::AbstractArray{T}`: Y coordinates (function values)

# Returns
- Callable function that evaluates the GPR prediction at a given point
"""
function test_gpr_function(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}
    @assert length(xs) == length(ys) "Input arrays must have same length"
    
    # Normalize y values
    y_mean = mean(ys)
    y_std = std(ys)
    ys_normalized = (ys .- y_mean) ./ max(y_std, 1e-8)
    
    # Add small noise to avoid conditioning issues
    ys_std = std(ys_normalized)
    noise_level = 1e-6 * max(ys_std, 1.0)
    ys_noisy = ys_normalized .+ noise_level * randn(length(ys))
    
    # Initial kernel parameters
    initial_lengthscale = log(std(xs) / 8)
    initial_variance = 0.0
    initial_noise = -2.0
    
    kernel = SEIso(initial_lengthscale, initial_variance)
    gp = GP(xs, ys_noisy, MeanZero(), kernel, initial_noise)
    
    # Optimize hyperparameters
    try
        GaussianProcesses.optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))
    catch e
        @warn "GP optimization failed, using unoptimized GP" exception = e
    end
    
    # Create callable function that denormalizes output
    gpr_func = x -> begin
        pred, _ = predict_f(gp, [x])
        return y_std * pred[1] + y_mean
    end
    
    return gpr_func
end

"""
	auto_aaa_bic(Z, F; mmax=50, do_sort=true)

Calls `aaa` multiple times, from m=1 to m=mmax, 
and picks whichever final approximation minimizes the BIC.

Returns the best approximation as an `AAAapprox`.
"""
function auto_aaa_bic(Z, F; mmax = 200, do_sort = true, verbose = true)
	println("starting auto_aaa_bic")
	M        = length(Z)
	best_bic = Inf
	best_r   = nothing
	best_m   = 0

	inittol = 0.25
	for m in 1:48
		inittol = inittol / 2.0
		#println("m = $m")
		# Use `tol=0.0` so it never breaks early,
		# and set `mmax=m` so the rational degree is exactly m-1 at final.
		r_m = aaa(Z, F; verbose = false, tol = inittol)

		# Evaluate on the sample points:
		Rm  = r_m.(Z)
		SSR = sum(abs2.(F .- Rm))        # sum of squared residuals

		# Let's do the BIC measure.
		# A quick parameter count for a type-(m-1,m-1) rational:
		#    k ≈ 2m  (if you want to be more precise, feel free!)
		k   = 2 * length(r_m.x)
		bic = k * log(M) + M * log(SSR / M + 1e-100)  # +1e-300 to avoid log(0)

		# Calculate AIC measure
		aic = 2 * k + M * log(SSR / M + 1e-100)

		# Debug output
		#println("  m = $m:")
		#println("    tol = $inittol")
		#println("    SSR = $SSR")
		#println("    k (params) = $k")
		#println("    BIC = $bic")
		#println("    AIC = $aic")

		if verbose
			println("m = $m : SSR = $SSR, BIC = $bic")
		end

		# Update best if improved:
		if bic < best_bic
			best_bic = bic
			best_r   = r_m
			best_m   = m
		end
	end

	if verbose
		println("Best BIC at m=$best_m  =>  BIC=$best_bic")
	end

	# Optionally sort the final approximation so that bary(...) is efficient.
	# Or do Froissart cleanups if you like.

	return best_r
end





function aaad_gpr_pivot(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}
	@assert length(xs) == length(ys)

	# 1. Normalize y values
	y_mean = mean(ys)
	y_std = std(ys)
	ys_normalized = (ys .- y_mean) ./ y_std

	initial_lengthscale = log(std(xs) / 8)
	initial_variance = 0.0
	initial_noise = -2.0

	kernel = SEIso(initial_lengthscale, initial_variance)
	jitter = 1e-8
	ys_jitter = ys_normalized .+ jitter * randn(length(ys))

	# 2. Do GPR approximation on normalized data
	gp = GP(xs, ys_jitter, MeanZero(), kernel, initial_noise)
	GaussianProcesses.optimize!(gp; method = LBFGS(linesearch = LineSearches.BackTracking()))

	noise_level = exp(gp.logNoise.value)
	if (noise_level < 1e-5)
		println("Noise level is too low, using  AAA")

		return aaad(xs, ys)
	else
		function denormalized_gpr(x)
			return y_std * predict_y(gp, x)[1] + y_mean
		end
		return denormalized_gpr
	end

end


function aaad_lowpres(xs::AbstractArray{T}, ys::AbstractArray{T}) where {T}
	@assert length(xs) == length(ys)

	# 1. Normalize y values
	y_mean = mean(ys)
	y_std = std(ys)
	ys_normalized = (ys .- y_mean) ./ y_std
	lowtol = 0.1
	# 2. Do low tolerance AAA approximation on normalized data
	internalApprox = BaryRational.aaa(xs, ys_normalized, verbose = false, tol = lowtol)
	unusedinternalApprox = BaryRational.aaa(xs, ys_normalized, verbose = false, tol = 1e-14)
	aaa_bic = auto_aaa_bic(xs, ys_normalized, do_sort = true, verbose = false)



	# Function to calculate adjusted noise estimate
	function adjusted_noise(resid, m_support, y_std)
		n = length(resid)
		m = m_support
		# Avoid division by zero or negative values
		effective_df = max(n - m, 1)
		noise_normalized = sqrt(sum(resid .^ 2) / effective_df)
		return noise_normalized * y_std  # Denormalize
	end


	# Calculate residuals and noise estimates for each approximation
	println("\nNoise level estimates (standard deviation of residuals):")

	# Low precision AAA
	low_resid = ys_normalized .- [ODEParameterEstimation.baryEval(x, internalApprox.f, internalApprox.x, internalApprox.w) for x in xs]
	low_noise = adjusted_noise(low_resid, length(internalApprox.x), y_std)
	println("  Low precision AAA (tol=$lowtol): ", @sprintf("%.2e", low_noise))

	# High precision AAA
	high_resid = ys_normalized .- [ODEParameterEstimation.baryEval(x, unusedinternalApprox.f, unusedinternalApprox.x, unusedinternalApprox.w) for x in xs]
	high_noise = adjusted_noise(high_resid, length(unusedinternalApprox.x), y_std)
	println("  High precision AAA (tol=1e-14): ", @sprintf("%.2e", high_noise))

	# BIC-selected AAA
	bic_resid = ys_normalized .- [ODEParameterEstimation.baryEval(x, aaa_bic.f, aaa_bic.x, aaa_bic.w) for x in xs]
	bic_noise = adjusted_noise(bic_resid, length(aaa_bic.x), y_std)
	println("  BIC-selected AAA: ", @sprintf("%.2e", bic_noise))

	# Add debugging information
	println("\nAAA Approximation Comparison:")
	println("Low precision (tol=$lowtol) support points: ", length(internalApprox.x))
	println("High precision (tol=1e-14) support points: ", length(unusedinternalApprox.x))
	println("BIC support points: ", length(aaa_bic.x))
	println("Support points difference: ", length(unusedinternalApprox.x) - length(internalApprox.x))

	# Compare evaluations at a few test points
	test_points = range(minimum(xs), maximum(xs), length = 5)
	println("\nEvaluation comparison at test points:")
	for x in test_points
		low_prec = ODEParameterEstimation.baryEval(x, internalApprox.f, internalApprox.x, internalApprox.w)
		high_prec = ODEParameterEstimation.baryEval(x, unusedinternalApprox.f, unusedinternalApprox.x, unusedinternalApprox.w)
		diff = abs(low_prec - high_prec)
		println(@sprintf("  x=%.3f: diff=%.2e", x, diff))
	end

	callable_struct = AAADapprox(internalApprox)

	# 3. Create wrapper to denormalize output
	function denormalize(x)
		return y_std * callable_struct(x) + y_mean
	end

	return denormalize
end








"""
	calculate_observable_derivatives(equations, measured_quantities, nderivs=5)

Calculate symbolic derivatives of observables up to the specified order using ModelingToolkit.
Returns the expanded measured quantities with derivatives and the derivative variables.
"""
function calculate_observable_derivatives(equations, measured_quantities, nderivs = 5)
	# Create equation dictionary for substitution
	equation_dict = Dict(eq.lhs => eq.rhs for eq in equations)

	n_observables = length(measured_quantities)

	# Create symbolic variables for derivatives
	ObservableDerivatives = Symbolics.variables(:d_obs, 1:n_observables, 1:nderivs)

	# Initialize vector to store derivative equations
	SymbolicDerivs = Vector{Vector{Equation}}(undef, nderivs)

	# Calculate first derivatives
	SymbolicDerivs[1] = [ObservableDerivatives[i, 1] ~ substitute(expand_derivatives(D(measured_quantities[i].rhs)), equation_dict) for i in 1:n_observables]

	# Calculate higher order derivatives
	for j in 2:nderivs
		SymbolicDerivs[j] = [ObservableDerivatives[i, j] ~ substitute(expand_derivatives(D(SymbolicDerivs[j-1][i].rhs)), equation_dict) for i in 1:n_observables]
	end

	# Create new measured quantities with derivatives
	expanded_measured_quantities = copy(measured_quantities)
	append!(expanded_measured_quantities, vcat(SymbolicDerivs...))

	return expanded_measured_quantities, ObservableDerivatives
end


#below copied from all_examples.jl



"""
	generate_comparison_datasets(example_func, petab_dir; 
							   datasize=1001, 
							   time_interval=[0.0, 5.0], 
							   additiverelative_noise=0.01)

Generate three datasets for comparison:
1. Clean data from Julia simulation
2. Data with additive noise
3. PEtab data

Also computes true derivatives for the clean data.

Returns a tuple containing:
- clean: OrderedDict with clean data
- noisy: OrderedDict with noisy data
- petab: OrderedDict with PEtab data
- derivatives: OrderedDict with true derivatives
"""
function generate_comparison_datasets(example_func, petab_dir;
	datasize,
	time_interval,
	additive_noise, nderivs = 5, tolerance = 1e-14)
	# Get original problem
	pep = example_func()

	# Calculate derivatives symbolically
	expanded_mq, obs_derivs = calculate_observable_derivatives(equations(pep.model.system),
		pep.measured_quantities, nderivs)  # Get up to 2nd derivatives

	# Create new ODESystem with derivative observables
	@named new_sys = ODESystem(equations(pep.model.system), t; observed = expanded_mq)

	# Create and solve ODE problem with derivatives
	prob = ODEProblem(structural_simplify(new_sys), pep.ic, (time_interval[1], time_interval[2]), pep.p_true)
	sol = solve(prob, AutoVern9(Rodas4P()), abstol = tolerance, reltol = tolerance, saveat = range(time_interval[1], time_interval[2], length = datasize))

	# 1. Generate clean data with derivatives
	clean_data = OrderedDict{Any, Vector{Float64}}()
	clean_data["t"] = sol.t

	# Store original observables and create mapping from observable to its key
	obs_to_key = Dict()  # Store mapping of observable to its key in clean_data
	for mq in pep.measured_quantities
		key = Num(mq.rhs)
		clean_data[key] = sol[mq.lhs]
		obs_to_key[mq.lhs] = key
	end

	# Store derivatives in a separate dictionary
	derivatives = OrderedDict{Any, Vector{Float64}}()
	derivatives["t"] = sol.t
	# Store derivatives up to nderivs for each observable
	for i in 1:length(pep.measured_quantities)
		obs_key = obs_to_key[pep.measured_quantities[i].lhs]
		# Store each derivative order
		for d in 1:nderivs
			derivatives["d$(d)_$obs_key"] = sol[obs_derivs[i, d]]
		end
	end

	# 2. Generate data with relative noise
	noisy_data = OrderedDict{Any, Vector{Float64}}()
	for (key, values) in clean_data
		if key == "t"
			noisy_data[key] = values  # Keep time points as is
		else
			# Add additive noise proportional to mean signal magnitude
			noise_scale = additive_noise * mean(abs.(values))
			noise = noise_scale * randn(length(values))
			noisy_data[key] = values + noise
		end
	end

	petab_data = nothing
	# 3. Get PEtab data
	if (!isnothing(petab_dir))
		yaml_file = joinpath(petab_dir, "problem.yaml")
		petab_model = PEtabModel(yaml_file)
		meas_df = petab_model.petab_tables[:measurements]

		# Convert PEtab data to same format as other datasets
		petab_data = OrderedDict{Any, Vector{Float64}}()
		petab_data["t"] = sort(unique(meas_df.time))
		# For each observable in the problem
		for mq in pep.measured_quantities
			obs_name = string(mq.lhs)
			obs_name = replace(obs_name, "(t)" => "")
			obs_id = "obs_$obs_name"

			# Initialize array for this observable's measurements
			obs_values = Vector{Float64}(undef, length(petab_data["t"]))

			# Fill in measurements
			for (i, t) in enumerate(petab_data["t"])
				measurements = meas_df[meas_df.time.==t.&&meas_df.observableId.==obs_id, :measurement]
				obs_values[i] = isempty(measurements) ? NaN : mean(measurements)
			end

			petab_data[Num(mq.rhs)] = obs_values
		end
	end


	return (clean = clean_data, noisy = noisy_data, petab = petab_data, derivatives = derivatives)
end

"""
	evaluate_approximation_methods(datasets, t_eval, sol, obs_derivs, measured_quantities)

Evaluate different approximation methods on the datasets.
Returns a dictionary of results for each method, including:
- Function approximation
- First through fifth derivatives
- Error metrics for each
"""
function evaluate_approximation_methods(datasets, t_eval, sol, obs_derivs, measured_quantities)
	# Initialize with explicit types
	println("DEBUG")
	display(measured_quantities)
	results = Dict{Any, Dict{String, Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}}}()

	# Helper function to compute error metrics
	function compute_errors(pred, true_data)
		rmse = sqrt(mean((pred .- true_data) .^ 2))
		mae = mean(abs.(pred .- true_data))
		max_err = maximum(abs.(pred .- true_data))
		return (rmse = rmse, mae = mae, max_error = max_err)
	end

	# For each observable
	for (i, mq) in enumerate(measured_quantities)
		key = Num(mq.rhs)
		if key == "t"
			continue
		end

		#display(datasets)
		results[key] = Dict{String, Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}}()
		t = datasets.clean["t"]
		println("DEBUG")
		display(datasets.noisy)
		y = datasets.noisy[key]  # Use noisy data for fitting

		# 2. LOESS
		model_lowess_rough = loess(collect(t), y, span = 0.2)
		#		lowess_func_rough = x -> model_lowess_rough([x])[1]
		lowess_func = aaad(t, Loess.predict(model_lowess_rough, t))

		# Evaluate function and derivatives
		pred_y = [lowess_func(x) for x in t_eval]
		preds = Dict{String, Vector{Float64}}("y" => pred_y)
		for d in 1:5
			preds["d$d"] = [nth_deriv_at(lowess_func, d, x) for x in t_eval]
		end

		#results[key]["LOESS"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
		#	"y" => preds["y"],
		#	"d1" => preds["d1"],
		#	"d2" => preds["d2"],
		#	"d3" => preds["d3"],
		#	"d4" => preds["d4"],
		#	"d5" => preds["d5"],
		#)

		# 1. Gaussian Process Regression
		try

			# Use test_gpr_function from run_examples.jl
			gpr_func = test_gpr_function(t, y)

			#kernel = SEIso(log(std(t) / 8), 0.0)
			#gp = GP(t, y, MeanZero(), kernel, -2.0)
			#optimize!(gp)

			# Create callable function
			#gpr_func = x -> begin
			#	pred, _ = predict_y(gp, [x])
			#	return pred[1]
			#end

			# Evaluate function and derivatives
			pred_y = [gpr_func(x) for x in t_eval]
			preds = Dict{String, Vector{Float64}}("y" => pred_y)
			for d in 1:5
				preds["d$d"] = [nth_deriv_at(gpr_func, d, x) for x in t_eval]
			end

			results[key]["GPR"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
				"y" => preds["y"],
				"d1" => preds["d1"],
				"d2" => preds["d2"],
				"d3" => preds["d3"],
				"d4" => preds["d4"],
				"d5" => preds["d5"],
			)
		catch e
			@warn "GPR failed for $key" exception = e
		end

		# 3. AAA
		try
			# Use aaad from bary_derivs.jl
			aaa_func = aaad(t, y)

			# Evaluate function and derivatives
			pred_y = [aaa_func(x) for x in t_eval]
			preds = Dict{String, Vector{Float64}}("y" => pred_y)
			for d in 1:5
				preds["d$d"] = [nth_deriv_at(aaa_func, d, x) for x in t_eval]
			end

			results[key]["AAA"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
				"y" => preds["y"],
				"d1" => preds["d1"],
				"d2" => preds["d2"],
				"d3" => preds["d3"],
				"d4" => preds["d4"],
				"d5" => preds["d5"],
			)
		catch e
			@warn "AAA failed for $key" exception = e
		end

		# 3(a). AAA low precision
		try
			# Use aaad from bary_derivs.jl
			aaa_func2 = aaad_lowpres(t, y)

			# Evaluate function and derivatives
			pred_y = [aaa_func2(x) for x in t_eval]
			preds = Dict{String, Vector{Float64}}("y" => pred_y)
			for d in 1:5
				preds["d$d"] = [nth_deriv_at(aaa_func2, d, x) for x in t_eval]
			end

			results[key]["AAA-lowpres"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
				"y" => preds["y"],
				"d1" => preds["d1"],
				"d2" => preds["d2"],
				"d3" => preds["d3"],
				"d4" => preds["d4"],
				"d5" => preds["d5"],
			)
		catch e
			@warn "AAA-lowpres failed for $key" exception = e
		end




		# 4. B-Splines (5th order using Dierckx)
		try
			# Calculate reasonable smoothing parameter based on noise level
			n = length(t)
			mean_y = mean(abs.(y))
			noise_level = 0.0 # 1% noise
			s = n * (noise_level * mean_y)^2  # Expected sum of squared residuals

			# Create 5th order spline interpolation (k=5)
			spl = Spline1D(t, y; k = 5, s = s)  # Smoothing based on noise level

			# Create callable function that matches our interface
			spline_func = x -> evaluate(spl, x)

			# Evaluate function and derivatives
			pred_y = [spline_func(x) for x in t_eval]
			preds = Dict{String, Vector{Float64}}("y" => pred_y)

			# Use Dierckx's built-in derivative function for better accuracy
			for d in 1:5
				preds["d$d"] = [derivative(spl, x, nu = d) for x in t_eval]
			end

			results[key]["Dierckx5"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
				"y" => preds["y"],
				"d1" => preds["d1"],
				"d2" => preds["d2"],
				"d3" => preds["d3"],
				"d4" => preds["d4"],
				"d5" => preds["d5"],
			)
		catch e
			@warn "Dierckx spline failed for $key" exception = e
		end

		# 5. Savitzky-Golay filtering
		#try
		# Parameters for SG filter
		#window_length = 21  # Must be odd
		#poly_order = 5     # Must be less than window_length

		# Create SG filter constructor for reuse
		#sgfilter = SGolay(window_length, poly_order)

		# Get filtered data and derivatives
		#dt = t[2] - t[1]  # Time step for scaling derivatives
		#preds = Dict{String, Vector{Float64}}()

		# Original function (0th derivative)
		#sg_result = sgfilter(y)
		#preds["y"] = sg_result.y

		# Higher derivatives (need to account for time scaling)
		#for d in 1:5
		# Create filter for each derivative order
		#	sg_deriv = SGolay(window_length, poly_order, d, 1 / dt)  # Include rate=1/dt for proper scaling
		#	sg_result = sg_deriv(y)
		#	preds["d$d"] = sg_result.y
		#end

		#results[key]["SavGol"] = Dict{String, Union{Vector{Float64}, Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}}}(
		#	"y" => preds["y"],
		#	"d1" => preds["d1"],
		#	"d2" => preds["d2"],
		#	"d3" => preds["d3"],
		#	"d4" => preds["d4"],
		#	"d5" => preds["d5"],
		#)
		#catch e
		#	@warn "Savitzky-Golay filtering failed for $key" exception = e
		#end

		# Calculate error metrics for each method
		for (method, preds) in results[key]
			# Get true values directly from the solution
			error_dict = Dict{String, NamedTuple{(:rmse, :mae, :max_error), Tuple{Float64, Float64, Float64}}}()

			# Function value errors
			error_dict["y"] = compute_errors(preds["y"], sol(t_eval, idxs = mq.lhs))

			# Derivative errors
			for d in 1:5
				error_dict["d$d"] = compute_errors(preds["d$d"], sol(t_eval, idxs = obs_derivs[i, d]))
			end

			results[key][method]["errors"] = error_dict
		end
	end

	return results
end

"""
	print_summary_statistics(results, datasets)

Print comprehensive summary statistics for each observable and its derivatives.
Includes data characteristics and error metrics for each approximation method.
"""
function print_summary_statistics(approx_results, datasets)
	for (obs_key, methods) in approx_results
		println("\n================================================================")
		println("OBSERVABLE: $obs_key")
		println("----------------------------------------------------------------")

		# Data characteristics for this observable
		true_vals = datasets.clean[obs_key]
		println("Data Characteristics:")
		println("  Mean:           $(round(mean(true_vals), digits=6))")
		println("  Median:         $(round(median(true_vals), digits=6))")
		println("  Std Deviation:  $(round(std(true_vals), digits=6))")
		println("  Range:          [$(round(minimum(true_vals), digits=6)), $(round(maximum(true_vals), digits=6))]")
		println("  Time span:      [$(minimum(datasets.clean["t"])), $(maximum(datasets.clean["t"]))]")
		println("  Number of points: $(length(true_vals))")

		# Function value and derivatives analysis
		for d in 0:5
			d_key = d == 0 ? "y" : "d$d"
			println("\n$(d == 0 ? "ORIGINAL FUNCTION" : "$(d)$(d==1 ? "ST" : d==2 ? "ND" : d==3 ? "RD" : "TH") DERIVATIVE")")

			# Get true values for this derivative level
			true_deriv = if d == 0
				datasets.clean[obs_key]
			else
				datasets.derivatives["d$(d)_$obs_key"]
			end

			# Print characteristics of the derivative
			println("  Derivative Characteristics:")
			println("    Mean:          $(round(mean(true_deriv), digits=6))")
			println("    Range:         [$(round(minimum(true_deriv), digits=6)), $(round(maximum(true_deriv), digits=6))]")
			println("    Std Deviation: $(round(std(true_deriv), digits=6))")

			# Method comparison
			println("\n  Method Performance:")
			println("    Method      |    MAE     |  Max Error |    RMSE   ")
			println("    -----------|------------|------------|------------")

			# Sort methods by RMSE for easier comparison
			sorted_methods = sort(collect(keys(methods)),
				by = m -> methods[m]["errors"][d_key].rmse)

			for method in sorted_methods
				errors = methods[method]["errors"][d_key]
				@printf("    %-10s | %10.2e | %10.2e | %10.2e\n",
					method,
					errors.mae,
					errors.max_error,
					errors.rmse)
			end
		end
		println("\n================================================================")
	end
end

example_function = lv_periodic
pep = example_function()

datasize = 21
time_interval = pep.recommended_time_interval
if isnothing(time_interval)
	time_interval = [0.0, 5.0]
end
additive_noise = 1e-6
#petab_dir = "petab_lv_periodic"
petab_dir = nothing
# Test the approximation methods
datasets = generate_comparison_datasets(example_function, petab_dir, datasize = datasize, time_interval = time_interval, additive_noise = additive_noise)  # Set noise to 0

t_eval = range(minimum(datasets.clean["t"]), maximum(datasets.clean["t"]), length = datasize)

# Get the solution and derivatives from generate_comparison_datasets
expanded_mq, obs_derivs = calculate_observable_derivatives(equations(pep.model.system), pep.measured_quantities, 5)
@named new_sys = ODESystem(equations(pep.model.system), t; observed = expanded_mq)
prob = ODEProblem(structural_simplify(new_sys), pep.ic, (minimum(t_eval), maximum(t_eval)), pep.p_true)
sol = solve(prob, Tsit5(), saveat = t_eval)

approx_results = evaluate_approximation_methods(datasets, t_eval, sol, obs_derivs, pep.measured_quantities)

# Print summary statistics
if false
	print_summary_statistics(approx_results, datasets)

	# Plot comparison of methods
	observables = [key for (key, values) in datasets.clean if key != "t"]
	n_obs = length(observables)
	# Create one large plot grid for all observables
	p = plot(layout = (n_obs, 6), size = (2400, 400 * n_obs))

	# Colors for different methods
	colors = [:red, :blue, :green, :purple]

	for (obs_idx, key) in enumerate(observables)
		# Original data and fits
		plot!(p[obs_idx, 1], datasets.clean["t"], datasets.clean[key],
			label = "True", title = "$(key) Data Fits")
		scatter!(p[obs_idx, 1], datasets.clean["t"], datasets.noisy[key],
			label = "Noisy", markersize = 2)

		# All five derivatives
		for d in 1:5
			plot!(p[obs_idx, d+1], datasets.clean["t"], datasets.derivatives["d$(d)_$key"],
				label = "True", title = "$(key) $(d)$(d==1 ? "st" : d==2 ? "nd" : d==3 ? "rd" : "th") Derivative")
		end

		# Plot each method except AAA
		for (i, (method, color)) in enumerate(zip(keys(approx_results[key]), colors))
			if method != "AAA"
				res = approx_results[key][method]

				# Data fits
				plot!(p[obs_idx, 1], t_eval, res["y"], label = method, color = color)

				# All derivatives
				for d in 1:5
					plot!(p[obs_idx, d+1], t_eval, res["d$d"], label = method, color = color)
				end
			end
		end
	end
end

#display(p)
