module ODEParameterEstimation

using ModelingToolkit
using SIAN
import StructuralIdentifiability: ODE
using AbstractAlgebra
using BaryRational
using Dates
using DynamicPolynomials
using ForwardDiff
using GaussianProcesses
using Groebner
using HomotopyContinuation
using LinearAlgebra
using Logging
using StructuralIdentifiability
using Nemo#using GLPK
using NonlinearSolve
using Optim, LineSearches
using Optimization, OptimizationOptimJL
using OrderedCollections
using OrdinaryDiffEq
using PolynomialRoots
using PrecompileTools
using Printf
using Random
using RationalUnivariateRepresentation
using RS
using Statistics
using Suppressor
using Symbolics
using TaylorDiff
#using CSV
#using DataFrames
#using DelimitedFiles
#using Oscar
#using Plots
#using Singular
#using SymbolicIndexingInterface


const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits
const package_wide_default_ode_solver = AutoVern9(Rodas4P())
#const package_wide_default_ode_solver = Vern9()


# Include core types first
include("untestedlinter.jl")
include("types/core_types.jl")
include("types/estimation_options.jl")  # New options struct

# Include utility modules
include("core/logging_utils.jl")
include("core/math_utils.jl")
include("core/model_utils.jl")
include("core/analysis_utils.jl")
include("core/derivative_utils.jl")

# Include core functionality
using SymbolicUtils
include("core/si_equation_builder.jl")  # StructuralIdentifiability integration
include("core/si_template_integration.jl")  # Template-based SI.jl integration
include("core/homotopy_continuation.jl")
include("core/robust_conversion.jl")  # New robust conversion utilities
include("core/pointpicker.jl")

include("core/parameter_estimation_helpers.jl")
include("core/parameter_estimation.jl")
include("core/multipoint_estimation.jl")
include("core/optimized_multishot_estimation.jl")  # New optimized workflow
include("core/derivatives.jl")
include("core/sampling.jl")
include("examples/load_examples.jl")

# Export types
export OrderedODESystem, ParameterEstimationProblem, ParameterEstimationResult, DerivativeData

# Export constants
export package_wide_default_ode_solver, CLUSTERING_THRESHOLD, MAX_ERROR_THRESHOLD, IMAG_THRESHOLD, MAX_SOLUTIONS

# Export core functions
export solve_with_hc, solve_with_monodromy, multipoint_parameter_estimation, multishot_parameter_estimation
export optimized_multishot_parameter_estimation, solve_with_rs_new, robust_exprs_to_AA_polys

# Export utility functions
export unpack_ODE, tag_symbol, create_ordered_ode_system
export add_relative_noise, sample_problem_data, calculate_error_stats
export analyze_estimation_result, print_stats_table, cluster_solutions
export clear_denoms, hmcs, analyze_parameter_estimation_problem, analyze_estimation_result
export aaad, aaad_in_testing, aaad_old_reliable, AAADapprox, GPRapprox, FHDapprox, nth_deriv_at, aaad_gpr_pivot, fhdn
export calculate_observable_derivatives, solve_with_rs, create_interpolants, AbstractInterpolator, FourierSeries, solve_with_nlopt, solve_with_nlopt_testing, solve_with_nlopt_quick, solve_with_fast_nlopt

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



@recompile_invalidations begin
	@compile_workload begin
		using ModelingToolkit
		using ModelingToolkit: t_nounits as t, D_nounits as D
		using OrdinaryDiffEq: Vern9
		using OrderedCollections: OrderedDict

		solver = Vern9()

		name = "lotka-volterra_0"
		@parameters k1
		@variables x(t) y1(t)
		states = [x]
		parameters = [k1]
		state_equations = [
			D(x) ~ k1 * x,
		]
		measured_quantities = [
			y1 ~ x,
		]
		ic = [0.536]
		p_true = [0.539]

		time_interval = [-0.5, 0.5]

		model, mq = create_ordered_ode_system(name, states, parameters, state_equations, measured_quantities)
		pep = ParameterEstimationProblem(name, model, mq, nothing, time_interval, nothing, OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

		# Create EstimationOptions with desired settings
		opts = EstimationOptions(
			datasize = 21,
			noise_level = 0.0,
			system_solver = SolverNLOpt,
			shooting_points = 1,
		)

		estimation_problem = sample_problem_data(pep, opts)
		res = analyze_parameter_estimation_problem(estimation_problem, opts)
	end
end


end # module

