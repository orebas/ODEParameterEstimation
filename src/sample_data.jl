#This is a utility function which fills in observed data by solving an ODE.

function sample_data(model::ModelingToolkit.ODESystem,
	measured_data::Vector{ModelingToolkit.Equation},
	time_interval::Vector{T},
	p_true,
	u0,
	num_points::Int;
	uneven_sampling = false,
	uneven_sampling_times = Vector{T}(),
	solver = package_wide_default_ode_solver, inject_noise = false, mean_noise = 0,
	stddev_noise = 1, abstol = 1e-14, reltol = 1e-14) where {T <: Number}
	if uneven_sampling
		if length(uneven_sampling_times) == 0
			error("No uneven sampling times provided")
		end
		if length(uneven_sampling_times) != num_points
			error("Uneven sampling times must be of length num_points")
		end
		sampling_times = uneven_sampling_times
	else
		sampling_times = range(time_interval[1], time_interval[2], length = num_points)
	end
	problem = ODEProblem(ModelingToolkit.complete(model), u0, time_interval, p_true)
	solution_true = ModelingToolkit.solve(problem, solver,
		saveat = sampling_times;
		abstol, reltol)

	#println("\nDEBUG: Solution Info:")
	#println("Type of solution_true: ", typeof(solution_true))
	#println("\nFirst timepoint solution:")
	#display(solution_true(sampling_times[1]))
	#println("\nSolution keys:")
	#display(keys(solution_true))   #this gives an error, keys is not defined on the solution object
	#println("\nMeasured data equations:")
	#for v in measured_data
	#	println("\nEquation: ", v)
	#	println("RHS: ", v.rhs)
	#	println("RHS type: ", typeof(v.rhs))
	#	println("Num(RHS): ", Num(v.rhs))
	#	println("Solution value at first timepoint: ", solution_true[Num(v.rhs)][1])
	#end

	data_sample = OrderedDict{Any, Vector{T}}(Num(v.rhs) => solution_true[Num(v.rhs)]
											  for v in measured_data)
	if inject_noise
		for (key, sample) in data_sample
			data_sample[key] = sample + randn(num_points) .* stddev_noise .+ mean_noise
		end
	end
	data_sample["t"] = sampling_times
	return data_sample
end

