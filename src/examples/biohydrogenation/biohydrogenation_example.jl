"""
Biohydrogenation Example

This example demonstrates parameter estimation for a biohydrogenation model
with 4 states, 6 parameters, and 2 observables.

The model represents a biochemical reaction system with Michaelis-Menten kinetics.
"""

using ODEParameterEstimation
using ModelingToolkit, DifferentialEquations
# using BenchmarkTools  # Uncomment if benchmarking
using OrderedCollections
using ModelingToolkit: t_nounits as t, D_nounits as D
using CSV
using ParameterEstimation

# The following packages are imported by ODEParameterEstimation as needed:
# using GaussianProcesses
# using Statistics  
# using Optim, LineSearches

name = "biohydrogenation"
parameters = @parameters k5 k6 k7 k8 k9 k10
states = @variables x4(t) x5(t) x6(t) x7(t)
observables = @variables y1(t) y2(t)
state_equations = [
	D(x4) ~ - k5 * x4 / (k6 + x4),
	D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5/(k8 + x5 + x6),
	D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
	D(x7) ~ k9 * x6 * (k10 - x6) / k10,
]
measured_quantities = [
	y1 ~ x4,
	y2 ~ x5,
]
ic = [0.45, 0.813, 0.871, 0.407]
p_true = [0.539, 0.672, 0.582, 0.536, 0.439, 0.617]

time_interval = [-1.0, 1.0]
datasize = 1001

model, mq = create_ordered_ode_system(
	name,
	states,
	parameters,
	state_equations,
	measured_quantities,
)

data_sample = Dict(vcat("t", map(x -> x.rhs, measured_quantities)) .=> CSV.read(joinpath(@__DIR__, "data.csv"), Tuple, header = false))

pep = ParameterEstimationProblem(
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

meta, results = analyze_parameter_estimation_problem(
	pep,
	nooutput = true,
	shooting_points = 0,  # Use single point at 0.5 (midpoint)
)

(solutions_vector, besterror,
	best_min_error,
	best_mean_error,
	best_median_error,
	best_max_error,
	best_approximation_error,
	best_rms_error) = results

table = merge(
	Dict((string(x) => [each.states[x] for each in solutions_vector] for x in states)),
	Dict((string(x) => [each.parameters[x] for each in solutions_vector] for x in parameters)),
)

# Save results to CSV
result_file = joinpath(@__DIR__, "result.csv")
CSV.write(result_file, table, header = string.(collect(keys(table))))

println("Parameter estimation complete!")
println("Results saved to: ", result_file)
println("Number of solutions found: ", length(solutions_vector))
if !isempty(solutions_vector)
	println("\nBest solution from ODEPE:")
	best_sol = solutions_vector[1]
	println("  States: ", best_sol.states)
	println("  Parameters: ", best_sol.parameters)
	println("  Error: ", besterror)
end

println("\n" * "="^40)
println("RUNNING WITH OLD ParameterEstimation.jl")
println("="^40 * "\n")

# --- Code adapted from user for ParameterEstimation.jl ---
pe_solver = Tsit5()

@named pe_model = ODESystem([
		D(x4) ~ - k5 * x4 / (k6 + x4),
		D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5/(k8 + x5 + x6),
		D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
		D(x7) ~ k9 * x6 * (k10 - x6) / k10,
	], t, states, parameters)

p_constraints = Dict((k5=>(0.0, 1.0)), (k6=>(0.0, 1.0)), (k7=>(0.0, 1.0)), (k8=>(0.0, 1.0)), (k9=>(0.0, 1.0)), (k10=>(0.0, 1.0)))
ic_constraints = Dict((x4=>(0.0, 1.0)), (x5=>(0.0, 1.0)), (x6=>(0.0, 1.0)), (x7=>(0.0, 1.0)))

@time pe_res = ParameterEstimation.estimate(pe_model, measured_quantities, data_sample;
	solver = pe_solver, interpolators = Dict("AAA" => ParameterEstimation.aaad), parameter_constraints = p_constraints, ic_constraints = ic_constraints)

if !isempty(pe_res)
	pe_table = merge(
		Dict((string(x) => [each.states[x] for each in pe_res] for x in states)),
		Dict((string(x) => [each.parameters[x] for each in pe_res] for x in parameters)),
	)

	pe_result_file = joinpath(@__DIR__, "result_pe.csv")
	CSV.write(pe_result_file, pe_table, header = string.(collect(keys(pe_table))))

	println("\nParameterEstimation.jl complete!")
	println("Results saved to: ", pe_result_file)
	println("Number of solutions found: ", length(pe_res))
	println("\nBest solution from PE:")
	best_pe_sol = pe_res[1]
	println("  States: ", best_pe_sol.states)
	println("  Parameters: ", best_pe_sol.parameters)
else
	println("\nParameterEstimation.jl found no solutions.")
end
