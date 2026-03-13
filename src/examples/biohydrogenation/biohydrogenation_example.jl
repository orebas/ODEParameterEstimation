"""
Biohydrogenation Example

This example demonstrates parameter estimation for a biohydrogenation model
with 4 states, 6 parameters, and 2 observables.
"""

using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV

function biohydrogenation_problem()
	name = "biohydrogenation"
	parameters = @parameters k5 k6 k7 k8 k9 k10
	states = @variables x4(t) x5(t) x6(t) x7(t)
	observables = @variables y1(t) y2(t)
	state_equations = [
		D(x4) ~ -k5 * x4 / (k6 + x4),
		D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5 / (k8 + x5 + x6),
		D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
		D(x7) ~ k9 * x6 * (k10 - x6) / k10,
	]
	measured_quantities = [y1 ~ x4, y2 ~ x5]
	ic = [0.45, 0.813, 0.871, 0.407]
	p_true = [0.539, 0.672, 0.582, 0.536, 0.439, 0.617]
	time_interval = [-1.0, 1.0]

	model, mq = create_ordered_ode_system(
		name,
		states,
		parameters,
		state_equations,
		measured_quantities,
	)

	csv_columns = CSV.read(joinpath(@__DIR__, "data.csv"), Tuple, header = false)
	data_keys = Any["t"; Num.(map(x -> x.lhs, measured_quantities))]
	data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}(
		data_keys[i] => collect(Float64, csv_columns[i]) for i in eachindex(data_keys)
	)

	return ParameterEstimationProblem(
		name,
		model,
		mq,
		data_sample,
		time_interval,
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic),
		0,
	)
end

function biohydrogenation_options(; smoke = false)
	return EstimationOptions(
		datasize = smoke ? 101 : 1001,
		noise_level = 0.0,
		time_interval = [-1.0, 1.0],
		system_solver = SolverHC,
		interpolator = InterpolatorAAAD,
		flow = FlowStandard,
		use_si_template = true,
		save_system = false,
		nooutput = smoke,
		diagnostics = !smoke,
		polish_solver_solutions = false,
		polish_solutions = false,
	)
end

function biohydrogenation_results_table(results, states, parameters)
	isempty(results) && return Dict{String, Vector{Float64}}()
	return merge(
		Dict(string(x) => [Float64(each.states[x]) for each in results] for x in states),
		Dict(string(x) => [Float64(each.parameters[x]) for each in results] for x in parameters),
	)
end

function run_biohydrogenation_example(;
	smoke = false,
	opts = nothing,
	write_csv = false,
	result_filename = "result.csv",
)
	pep = biohydrogenation_problem()
	run_opts = isnothing(opts) ? biohydrogenation_options(smoke = smoke) : opts
	raw_results, analysis, uq = analyze_parameter_estimation_problem(pep, run_opts)

	if write_csv && !isempty(analysis[1])
		table = biohydrogenation_results_table(
			analysis[1],
			collect(keys(pep.ic)),
			collect(keys(pep.p_true)),
		)
		CSV.write(joinpath(@__DIR__, result_filename), table)
	end

	return (raw_results, analysis, uq)
end

if abspath(PROGRAM_FILE) == @__FILE__
	run_biohydrogenation_example(write_csv = true)
end
