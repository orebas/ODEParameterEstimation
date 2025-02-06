"""
	define_vars_in_module(mod::Module, var_specs::Vector{String})

Define symbolic variables in a given module using ModelingToolkit's @variables macro.

# Arguments
- `mod::Module`: The module to define the variables in
- `var_specs::Vector{String}`: Vector of variable specifications as strings (e.g. ["x(t)", "y(t)", "a", "b"])

# Details
Takes a list of variable specifications and defines them as symbolic variables in the given module.
For example, passing ["x(t)", "y(t)"] will define time-dependent variables x(t) and y(t).
This is equivalent to writing @variables x(t) y(t) directly in the module.

# Example

"""

function define_vars_in_module(mod::Module, var_specs::Vector{String})
	# Example: var_specs might be ["x(t)", "y(t)", "a", "b"]
	# We want to build "@variables x(t) y(t) a b"
	vars_str = "@variables " * join(var_specs, " ")
	println("Defining in module $(mod): ", vars_str)

	# Evaluate that code in the desired module
	temp = Base.eval(mod, Meta.parse(vars_str))
	println("temp: ", temp)
end


function create_scratch_module(var_specs::Vector{String})
	M = Module()  # an empty scratch module

	# Bring in the needed symbols from ModelingToolkit
	Base.eval(M, :(using ModelingToolkit))
	Base.eval(M, :(using ModelingToolkit: t_nounits as t, D_nounits as D))    # Now define the user's variables:
	vars_str = "@variables " * join(var_specs, " ")
	temp = Base.eval(M, Meta.parse(vars_str))
	println("temp: ", temp)
	return M
end



"""
	convert_petab_to_odepe(petab_dir::String)

Convert a PEtab problem into ODEParameterEstimation's format.
"""
function convert_petab_to_odepe(petab_dir::String)
	# Load PEtab problem
	yaml_file = joinpath(petab_dir, "problem.yaml")
	petab_model = PEtabModel(yaml_file)
	petab_prob = PEtabODEProblem(petab_model)

	# Extract system components
	sys = petab_model.sys
	states = ModelingToolkit.unknowns(sys)
	all_params = ModelingToolkit.parameters(sys)

	# Filter parameters (exclude init_ params and default_compartment)
	parameters = filter(p -> !startswith(string(p), "init_") && string(p) != "default_compartment", all_params)

	# Convert parameters and states to Num type
	parameters = convert(Vector{Num}, parameters)
	states = convert(Vector{Num}, states)

	# Get equations
	equations = ModelingToolkit.equations(sys)

	# Process observables
	obs_table = petab_model.petab_tables[:observables]
	measured_quantities = []

	# Create list of all variables we need in our scratch module
	var_specs = String[]

	# Add state variables as callable functions
	for state in states
		push!(var_specs, string(state))  #* "(t)"
	end

	# Add parameters (these don't need to be callable)
	for param in parameters
		push!(var_specs, string(param))
	end

	# Add observables as callable functions
	for row in eachrow(obs_table)
		obs_id = replace(row.observableId, "obs_" => "")
		push!(var_specs, obs_id * "(t)")
	end

	# Create single scratch module with all variables
	println("Variable specs: ", var_specs)
	M = create_scratch_module(var_specs)

	# Process each observable using the scratch module
	for row in eachrow(obs_table)
		obs_id = replace(row.observableId, "obs_" => "")
		obs_formula = row.observableFormula

		println("Processing formula: ", obs_formula)
		# Parse formula in scratch module's scope
		expr = Symbolics.parse_expr_to_symbolic(Meta.parse(obs_formula), M)

		println("expr: ", expr)

		# Get the observable variable from the scratch module
		obs_var = Base.eval(M, Meta.parse(obs_id))

		# Create equation
		push!(measured_quantities, Equation(obs_var, expr))
	end

	# Extract measurement data
	meas_df = petab_model.petab_tables[:measurements]
	unique_times = sort(unique(meas_df.time))
	data_sample = OrderedDict{Any, Vector{Float64}}()
	data_sample["t"] = unique_times

	# Process measurement data for each observable
	for mq in measured_quantities
		obs_id = replace(string(mq.lhs), "(t)" => "")
		obs_data = Vector{Float64}(undef, length(unique_times))

		for (j, t) in enumerate(unique_times)
			measurements = meas_df[(meas_df.time.==t).&(meas_df.observableId.==("obs_"*obs_id)), :measurement]
			obs_data[j] = isempty(measurements) ? NaN : mean(measurements)
		end
		data_sample[Num(mq.rhs)] = obs_data
	end

	# Get parameter values and create parameter dictionary
	x0 = get_x(petab_prob)
	param_dict = OrderedDict{Num, Float64}()

	# Process parameters and their scales
	param_df = petab_model.petab_tables[:parameters]
	for (i, param) in enumerate(parameters)
		param_id = string(param)
		row = param_df[param_df.parameterId.==param_id, :]

		if !isempty(row) && row.parameterScale[1] == "log10"
			param_dict[param] = i <= length(x0) ? 10^x0[i] : 1.0
		else
			param_dict[param] = i <= length(x0) ? x0[i] : 0.0
		end
	end

	# Get initial conditions
	ic_dict = OrderedDict{Num, Float64}()
	for state in states
		state_name = replace(string(state), "(t)" => "")

		init_param_name = "init_" * state_name

		# Check sources for initial conditions in order of priority
		if haskey(petab_model.petab_tables, :conditions)
			cond_df = petab_model.petab_tables[:conditions]
			if state_name in names(cond_df)
				ic_dict[state] = cond_df[1, state_name]
				continue
			end
		end

		if haskey(petab_model.petab_tables, :species)
			species_df = petab_model.petab_tables[:species]
			row = species_df[species_df.speciesId.==state_name, :]
			if !isempty(row) && !ismissing(row.initialConcentration[1])
				ic_dict[state] = row.initialConcentration[1]
				continue
			end
		end

		ic_dict[state] = 0.0  # Default value if no initial condition found
	end

	# Create OrderedODESystem and return ParameterEstimationProblem
	ordered_system, mq = create_ordered_ode_system(
		basename(petab_dir),
		states,
		parameters,
		equations,
		measured_quantities,
	)

	return ParameterEstimationProblem(
		basename(petab_dir),
		ordered_system,
		mq,
		data_sample,
		nothing,  # solver will be set later
		param_dict,
		ic_dict,
		0,  # The unidentifiable parameters are already detected in the analysis
	)
end

# Test with petab_simple
#println("Testing conversion with petab_simple...")
#prob = convert_petab_to_odepe("petab_threesp_cubed")
