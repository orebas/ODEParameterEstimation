module ODEParameterEstimation

using ModelingToolkit
using OrdinaryDiffEq
using LinearAlgebra
using OrderedCollections
using BaryRational
using HomotopyContinuation
using TaylorDiff
using PrecompileTools
using ForwardDiff
using Random
using DelimitedFiles
using DataFrames
using CSV
using Printf
using GaussianProcesses
using Statistics
using Optim, LineSearches
using Optimization, OptimizationOptimJL
using Plots
using Dates
using ModelingToolkit
using Random
using Statistics
using SymbolicIndexingInterface
using NonlinearSolve
using PolynomialRoots
using Suppressor
using Logging

using AbstractAlgebra
using RationalUnivariateRepresentation
using RS

const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits
const package_wide_default_ode_solver = AutoVern9(Rodas4P())
#const package_wide_default_ode_solver = Vern9()


# Include core types first
include("untestedlinter.jl")
include("types/core_types.jl")

# Include utility modules
include("core/logging_utils.jl")
include("core/math_utils.jl")
include("core/model_utils.jl")
include("core/analysis_utils.jl")
include("core/derivative_utils.jl")

# Include core functionality
include("core/homotopy_continuation.jl")
include("core/pointpicker.jl")

include("core/parameter_estimation_helpers.jl")
include("core/parameter_estimation.jl")
include("core/multipoint_estimation.jl")
include("core/derivatives.jl")
include("core/sampling.jl")
include("examples/load_examples.jl")

# Export types
export OrderedODESystem, ParameterEstimationProblem, ParameterEstimationResult, DerivativeData

# Export constants
export package_wide_default_ode_solver, CLUSTERING_THRESHOLD, MAX_ERROR_THRESHOLD, IMAG_THRESHOLD, MAX_SOLUTIONS

# Export core functions
export solve_with_hc, solve_with_monodromy, multipoint_parameter_estimation, multishot_parameter_estimation

# Export utility functions
export unpack_ODE, tag_symbol, create_ordered_ode_system
export add_relative_noise, sample_problem_data, calculate_error_stats
export analyze_estimation_result, print_stats_table, cluster_solutions
export clear_denoms, hmcs, analyze_parameter_estimation_problem, analyze_estimation_result
export aaad, aaad_in_testing, aaad_old_reliable, AAADapprox, GPRapprox, FHDapprox, nth_deriv_at, aaad_gpr_pivot, fhdn
export calculate_observable_derivatives, solve_with_rs, create_interpolants, AbstractInterpolator, FourierSeries, solve_with_nlopt

# Export logging functions
export configure_logging, log_matrix, log_equations, log_dict

# Export derivative utilities
export calculate_higher_derivatives, calculate_higher_derivative_terms

# Export example models
# Simple models
export simple, simple_linear_combination, onesp_cubed, threesp_cubed
export lotka_volterra, vanderpol, brusselator, harmonic, fitzhugh_nagumo
export seir, treatment, biohydrogenation, repressilator
export crauste, seir, daisy_mamil3, daisy_mamil4, hiv
export substr_test, global_unident_test, sum_test, trivial_unident




#=
@recompile_invalidations begin
	@compile_workload begin
		using ModelingToolkit
		using ModelingToolkit: t_nounits as t, D_nounits as D
		using OrdinaryDiffEq: Vern9
		using OrderedCollections: OrderedDict

		solver = Vern9()

		name = "lotka-volterra_0"
		@parameters k1 k2 k3
		@variables r(t) w(t) y1(t)
		states = [r, w]
		parameters = [k1, k2, k3]
		state_equations = [
			D(r) ~ k1 * r - k2 * r * w,
			D(w) ~ k2 * r * w - k3 * w,
		]
		measured_quantities = [
			y1 ~ r,
		]
		ic = [0.536, 0.439]
		p_true = [0.539, 0.672, 0.582]


		time_interval = [-0.5, 0.5]
		datasize = 21

		model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)
		pep = ParameterEstimationProblem(name, model, mq, nothing, time_interval, nothing, OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)
		# data_sample = load("/home/ad7760/parameter_estimation_tests/data/julia/lotka-volterra_0.jld2", "data")

		estimation_problem = sample_problem_data(pep, datasize = datasize, time_interval = time_interval, noise_level = 0.0)
		res = analyze_parameter_estimation_problem(estimation_problem, nooutput = true, system_solver = solve_with_nlopt)
		analysis_result, besterror = analyze_estimation_result(estimation_problem, res, nooutput = true)


	end
end
=#


end # module

