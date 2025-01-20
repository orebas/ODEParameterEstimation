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
	# Get parameters in the correct order from the model
	ordered_params = [p_true[p] for p in ModelingToolkit.parameters(model)]
	ordered_u0 = [u0[s] for s in ModelingToolkit.unknowns(model)]

	problem = ODEProblem(ModelingToolkit.complete(model), ordered_u0, time_interval, ordered_params)
	solution_true = ModelingToolkit.solve(problem, solver,
		saveat = sampling_times;
		abstol, reltol)

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

