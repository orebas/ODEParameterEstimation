using PETAB
using DataFrames
using CSV

"""
	save_as_petab(problem::ParameterEstimationProblem, output_dir::String)

Convert a ParameterEstimationProblem to PETAB format and save it to the specified directory.
This is an initial implementation that handles basic cases.
"""
function save_as_petab(problem::ParameterEstimationProblem, output_dir::String)
	# Create output directory if it doesn't exist
	mkpath(output_dir)

	# Create parameters table
	parameters_df = DataFrame(
		parameterId = String[],
		parameterScale = String[],
		lowerBound = Float64[],
		upperBound = Float64[],
		nominalValue = Float64[],
		estimate = Int[],
	)

	# Add parameters
	for (param, value) in problem.p_true
		push!(parameters_df, (
			string(param),  # parameterId
			"lin",         # parameterScale (linear)
			0.0,          # lowerBound (default)
			10.0,         # upperBound (default)
			value,        # nominalValue
			1,            # estimate (1 = yes)
		))
	end

	# Save parameters table
	CSV.write(joinpath(output_dir, "parameters.tsv"), parameters_df, delim = '\t')

	# Create observables table
	observables_df = DataFrame(
		observableId = String[],
		observableFormula = String[],
		noiseFormula = String[],
	)

	# Add observables
	for eq in problem.measured_quantities
		obs_name = string(eq.lhs)
		obs_formula = string(eq.rhs)
		push!(observables_df, (
			obs_name,           # observableId
			obs_formula,        # observableFormula
			"1.0",              # noiseFormula (constant)
		))
	end

	# Save observables table
	CSV.write(joinpath(output_dir, "observables.tsv"), observables_df, delim = '\t')

	# TODO: Add measurement data table once we have sample data
	# TODO: Add model file (SBML format) - this will require additional work

	return nothing
end
