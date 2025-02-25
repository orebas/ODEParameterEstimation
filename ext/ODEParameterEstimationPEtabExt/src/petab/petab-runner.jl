using Catalyst, PEtab, OrdinaryDiffEq, Optim, Printf
#using Plots
#gr() # Use GR backend instead of PlotlyJS

# Create model from the SBML file
petab_dir = "hiv_petab_problem"
yaml_file = joinpath(petab_dir, "problem.yaml")
model = PEtabModel(yaml_file)

# Print model information
println("\nModel Information:")
#println("Model paths: ", model.paths)
#println("System: ", model.sys)
if !isnothing(model.parametermap)
	println("Parameter map: ", model.parametermap)
end
if !isnothing(model.speciemap)
	println("Species map: ", model.speciemap)
end
println("PEtab tables: ", keys(model.petab_tables))

# Create the PEtabODEProblem with appropriate solver
petab_prob = PEtabODEProblem(model;
	odesolver = ODESolver(AutoVern7(Rodas5P()); abstol = 1e-12, reltol = 1e-12))

# Get initial parameter values and check objective is computable
x0 = get_x(petab_prob)
obj = petab_prob.nllh(x0)

# Try evaluating the gradient at initial point
g = similar(x0)
petab_prob.grad!(g, x0)
println("\nGradient at initial point:")
for (i, grad_val) in enumerate(g)
	param_name = petab_prob.xnames[i]
	println("  $param_name: $grad_val")
end

println("\nInitial parameter values:")
for (i, val) in enumerate(x0)
	param_name = petab_prob.xnames[i]
	# Get parameter scale from PEtab
	param_df = model.petab_tables[:parameters]
	row = param_df[param_df.parameterId.==param_name, :]
	if size(row, 1) > 0
		param_scale = row.parameterScale[1]
		if param_scale == "log10"
			println("  $param_name = $(10^val) (log10 scale: $val)")
		else
			println("  $param_name = $val (linear scale)")
		end
	else
		# If parameter not found in table, assume linear scale
		println("  $param_name = $val (linear scale)")
	end
end
println("\nInitial objective value: $obj")

# Configure optimization options
#opt = BFGS()  # Required for multistart
opt = IPNewton()  # Required for multistart

options = Optim.Options(
	iterations = 2000,           # More iterations
	x_tol = 1e-8,
	f_tol = 1e-8,
	g_tol = 1e-8,
	show_trace = false,          # Show progress
)

# Parameter estimation using multiple starts
num_multistarts = 30
println("\nRunning optimization with ", num_multistarts, " multistarts...")
ms_res = calibrate_multistart(petab_prob, opt, num_multistarts;  # Reduced for debugging
	save_trace = true,
	options = options)

# Print results 
println("\nOptimization results:")
println("Best objective value: ", ms_res.fmin)
println("\nAll start points and their final objectives:")
for (i, run) in enumerate(ms_res.runs)
	if !isnothing(run)
		# Get initial and final values from the traces
		start_obj = run.ftrace[1]  # First objective value
		final_obj = run.fmin       # Final objective value
		println("Start $i: Initial obj = $start_obj, Final obj = $final_obj")

		# Print parameter values if there's significant improvement
		if abs(final_obj - start_obj) > 1e-6
			println("    Parameter values:")
			start_x = run.xtrace[1]
			final_x = run.xtrace[end]
			for (j, (start_val, final_val)) in enumerate(zip(start_x, final_x))
				param_name = petab_prob.xnames[j]
				println("    $param_name: $start_val -> $final_val")
			end
		end
	end
end

println("\nBest parameters found:")
println("  Parameter  Found Value (Scale)")
println("  ---------  ------------------")
for (i, val) in enumerate(ms_res.xmin)
	param_name = petab_prob.xnames[i]
	# Get parameter scale from PEtab
	param_df = model.petab_tables[:parameters]
	row = param_df[param_df.parameterId.==param_name, :]
	if size(row, 1) > 0
		param_scale = row.parameterScale[1]
		if param_scale == "log10"
			found_val = 10^val
			println(@sprintf("  %-9s  %11.4f (log10)", param_name, found_val))
		else
			found_val = val
			println(@sprintf("  %-9s  %11.4f (linear)", param_name, found_val))
		end
	else
		# If parameter not found in table, assume linear scale
		found_val = val
		println(@sprintf("  %-9s  %11.4f (linear)", param_name, found_val))
	end
end

# Try simulating with the found parameters
println("\nSimulating with found parameters...")
# Get timepoints from measurements table
timepoints = sort(unique(model.petab_tables[:measurements].time))
t = range(minimum(timepoints), maximum(timepoints), length = 50)
println("Getting ODE solution...")
sol = get_odesol(ms_res.xmin, petab_prob)
println("Solution values at selected timepoints:")
# Sample at evenly spaced points within the data range
sample_points = range(minimum(timepoints), maximum(timepoints), length = 6)
for t_val in sample_points
	vals = sol(t_val)
	println("  t=$t_val: ", join(vals, ", "))
end

# Generate plots
#println("\nGenerating plots...")
#aterfall_plot = plot(ms_res,
#= 	plot_type = :waterfall,
	title = "Waterfall Plot",
	ylabel = "Objective Value",
	xlabel = "Run Index")

fit_plot = plot(ms_res, petab_prob,
	title = "Fit Plot",
	ylabel = "Value",
	xlabel = "Time")

# Combine plots side by side
combined_plot = plot(waterfall_plot, fit_plot,
	layout = (1, 2),
	size = (1200, 500),
	margin = 10Plots.mm)

# Save the plot to a file
savefig(combined_plot, "optimization_results.png")
println("Plots saved to optimization_results.png")
 =#
