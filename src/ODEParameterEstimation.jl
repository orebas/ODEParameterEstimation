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
using Plots


using ModelingToolkit
using OrderedCollections
using LinearAlgebra
using Random
using ForwardDiff



using ModelingToolkit, OrdinaryDiffEq, DataFrames, Optim
using PEtab
using OrderedCollections
using Statistics
using SymbolicIndexingInterface
using ODEParameterEstimation







const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits
const package_wide_default_ode_solver = AutoVern9(Rodas4P())

# Remove old includes
#include("utils.jl")
#include("SharedUtils.jl")
#include("bary_derivs.jl")
#include("sample_data.jl")
#include("equation_solvers.jl")
#include("test_utils.jl")

# Include core types first
include("types/core_types.jl")

# Include utility modules
include("utils/math_utils.jl")
include("utils/model_utils.jl")
include("utils/data_utils.jl")
include("utils/analysis_utils.jl")

# Include core functionality
include("core/solvers/homotopy_continuation.jl")
include("core/solvers/parameter_estimation.jl")
include("data/derivatives.jl")
include("data/sampling.jl")
include("petab/loader.jl")
include("utils/testing_utils.jl")

# Export types
export OrderedODESystem, ParameterEstimationProblem, ParameterEstimationResult, DerivativeData

# Export constants
export package_wide_default_ode_solver, CLUSTERING_THRESHOLD, MAX_ERROR_THRESHOLD, IMAG_THRESHOLD, MAX_SOLUTIONS

# Export core functions
export solve_with_hc, solve_with_monodromy, multipoint_parameter_estimation

# Export utility functions
export unpack_ODE, tag_symbol, create_ordered_ode_system
export add_relative_noise, sample_problem_data, calculate_error_stats
export analyze_estimation_result, print_stats_table
export clear_denoms, hmcs, analyze_parameter_estimation_problem, analyze_estimation_result
export aaad, aaad_in_testing, aaad_old_reliable, AAADapprox, nth_deriv_at

# Export PEtab integration
export load_model
#=
@recompile_invalidations begin
	@compile_workload begin
		using ModelingToolkit: t_nounits as t, D_nounits as D

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
		res = analyze_parameter_estimation_problem(estimation_problem, test_mode = false, nooutput = true, interpolator = aaad)
		analysis_result, besterror = analyze_estimation_result(estimation_problem, res, nooutput = true)


	end
end
=#


end # module

