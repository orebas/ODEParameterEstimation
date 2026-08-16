module ODEParameterEstimation

using ModelingToolkit
using SIAN
import StructuralIdentifiability: ODE
using AbstractAlgebra
using BaryRational
using Dates
using DynamicPolynomials
using ForwardDiff
using KernelFunctions
using AbstractGPs
using GaussianProcesses
using Groebner
using HomotopyContinuation
using LinearAlgebra
using Logging
using StructuralIdentifiability
using Nemo#using GLPK
import Metaheuristics  # SHADE+LM baseline (`src/baselines/shade_lm.jl`); imported, not used, to avoid clobbering `optimize`/`minimum`/`minimizer` from Optim
using NonlinearSolve
using Optim, LineSearches
using Optimization, OptimizationOptimJL
using LeastSquaresOptim
using FastLevenbergMarquardt
using OrderedCollections
using OrdinaryDiffEq
using PolynomialRoots
using PrecompileTools
using Printf
using Random
using Statistics
using Symbolics
using TaylorDiff


using NonlinearSolve, Symbolics, ForwardDiff, FiniteDiff, LinearAlgebra
using NLopt, Optim, NLSolversBase
using SciMLSensitivity
# using Zygote  # Disabled: segfaults Julia 1.12 JIT compiler. ForwardDiff is used instead.
using Enzyme
#using OptimizationEnzyme
using SymbolicUtils
using PDMats

# Disambiguation for GaussianProcesses.jl / PDMats.jl ldiv! conflict.
# Registry GaussianProcesses.jl defines ldiv!(::PDMat, ::Any), while PDMats.jl
# defines ldiv!(::AbstractPDMat, ::AbstractVecOrMat).  Matrix RHS dispatch is
# ambiguous unless an exact PDMat/AbstractVecOrMat method exists.  Some patched
# GP forks already provide this method, so only install the local bridge when it
# is absent.
import LinearAlgebra: ldiv!
function _odepe_has_pdmat_ldiv_disambiguation()
	target = Tuple{typeof(ldiv!), PDMats.PDMat, AbstractVecOrMat}
	return any(m -> m.sig == target, methods(ldiv!))
end
if !_odepe_has_pdmat_ldiv_disambiguation()
	LinearAlgebra.ldiv!(A::PDMats.PDMat, B::AbstractVecOrMat) = ldiv!(A.chol, B)
end

#using CSV
#using DataFrames
#using DelimitedFiles
#using Oscar
#using Plots
#using Singular
#using SymbolicIndexingInterface


const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits
const package_wide_default_ode_solver = AutoVern9(Rodas5P())
#const package_wide_default_ode_solver = Vern9()


# Include core types first
include("types/core_types.jl")
include("types/estimation_options.jl")  # New options struct

# Include utility modules
include("core/logging_utils.jl")
include("core/run_context.jl")  # per-run scoped state (RunContext; replaces run-state globals)
include("core/math_utils.jl")
include("core/model_utils.jl")
include("core/analysis_utils.jl")
include("core/derivative_utils.jl")

# Include core functionality
include("core/si_equation_builder.jl")  # StructuralIdentifiability integration
include("core/transcendental_utils.jl")  # Transcendental function handling (sin/cos/exp) — after si_equation_builder for parse_derivative_variable_name
include("core/problem_rescaling.jl")  # Opt-in power-of-2 problem rescaling (states/params/observables/data → O(1))
include("core/si_template_integration.jl")  # Template-based SI.jl integration
include("core/homotopy_continuation.jl")
include("core/solve_with_robust.jl")  # Robust solver with multiple fallbacks
include("core/pointpicker.jl")

include("core/parameter_estimation_helpers.jl")
include("core/parameter_estimation.jl")
include("core/polish_residual.jl")
include("core/branch_completion.jl")
include("core/optimized_multishot_estimation.jl")  # New optimized workflow
include("baselines/shade_lm.jl")                   # SHADE+LM hybrid baseline (uses _build_polish_context, _polish_single_from_context)
include("core/multipoint_template.jl")  # Multi-point polynomial template system
include("core/noise_frontier_construction.jl")  # Probe-only noise-first system construction
include("core/derivatives.jl")
include("core/sigma_d.jl")  # Per-(observable, order) derivative uncertainty σ_d
include("core/sensitivity_seeds.jl")  # σ_d-aware seed generation (Layer 2)
include("core/synthesize_aggregates.jl")  # Per-component median/mean/trim25 synthesis of SP+MP aggregates
include("core/uncertainty_quantification.jl")  # UQ via GP derivative covariances and IFT
include("core/sampling.jl")
include("core/svg_plots.jl")
# diagnostics.jl (5,443 lines) split 2026-06-10 along its section seams (Phase F2);
# original include order preserved.
include("core/diagnostics/taylor_oracle.jl")
include("core/diagnostics/feasibility_sensitivity.jl")
include("core/diagnostics/multipoint_sensitivity.jl")  # estimate-conditioned S over multipoint templates
include("core/diagnostics/error_budget.jl")
include("core/diagnostics/orchestrators.jl")
include("core/diagnostics/html_report.jl")
include("core/diagnostics/uq_and_reports.jl")
include("core/diagnostics/estimator_aware_uq.jl")
# Research / benchmark-only consensus + sweep tooling (NOT in the estimation pipeline).
# Moved to src/research/ on 2026-06-09; reachable via the package namespace and used
# only by benchmark_sweeps and test/generate_* harnesses. See docs/2026-06-09_code_review.md.
include("research/research_types.jl")
include("research/consensus_estimation.jl")
include("research/consensus_reporting.jl")
include("research/synthesized_finalizer.jl")
include("research/branch_consensus_v1.jl")
include("research/benchmark_sweeps.jl")
include("research/block_consensus_v2.jl")
include("examples/load_examples.jl")

# Export types
export OrderedODESystem, ParameterEstimationProblem, ParameterEstimationResult, ResultProvenance, EstimatorIdentity, NumericalIdentifiabilityAdvisory, DerivativeData, UnsupportedModelClassError, SamplingFailureError, UnsupportedDerivativeOrderError, TAYLORDIFF_MAX_DERIVATIVE_ORDER
export provenance_metadata_dict, uq_metadata_dict

# Export constants
export package_wide_default_ode_solver, CLUSTERING_THRESHOLD, MAX_ERROR_THRESHOLD, IMAG_THRESHOLD, MAX_SOLUTIONS

# Export core functions
export solve_with_hc
export optimized_multishot_parameter_estimation, solve_with_robust
export direct_optimization_parameter_estimation
export shade_lm_estimate

# Export utility functions
export unpack_ODE, tag_symbol, create_ordered_ode_system
export add_relative_noise, add_additive_noise, add_synthetic_noise, sample_problem_data, calculate_error_stats
export analyze_estimation_result, print_stats_table, cluster_solutions
export clear_denoms, hmcs, analyze_parameter_estimation_problem
export aaad, aaad_old_reliable, AAADapprox, GPRapprox, FHDapprox, nth_deriv, nth_deriv_at, aaad_gpr_pivot, fhdn
export ChebyshevApprox, chebyshev_aicc, chebyshev_bic, FourierApprox, fourier_adaptive
export InterpolatorMethod, InterpolatorAAAD, InterpolatorAAADGPR, InterpolatorAAADOld, InterpolatorFHD
export InterpolatorAGPRobust, InterpolatorAGPRobustRQ, InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ, InterpolatorAGPRobustMatern52
export InterpolatorS2AAAMLE, InterpolatorS3AdaptSE, InterpolatorS3AdaptRQ, InterpolatorS3AdaptSEpRQ, InterpolatorS3AdaptSExRQ, InterpolatorS3AdaptMatern52
export InterpolatorS3BICSE, InterpolatorS3BICRQ, InterpolatorS3BICSEpRQ, InterpolatorS3BICSExRQ, InterpolatorS3BICMatern52
export InterpolatorChebyshevAICc, InterpolatorChebyshevBIC, InterpolatorFourierAdaptive, InterpolatorAGPUQ, InterpolatorCustom
export AGPInterpolator, agp_gpr, agp_gpr_robust, mean_and_var
export calculate_observable_derivatives, create_interpolants, AbstractInterpolator, solve_with_nlopt, solve_with_fast_nlopt
export solve_with_hc_parameterized, convert_to_hc_format_with_params, extract_data_variables_from_DD, evaluate_data_vars_at_point
export MultiPointTemplate, MultiPointEvaluation, build_multipoint_template, evaluate_multipoint_template, solve_multipoint_direct, solve_multipoint_parameterized, select_time_point_pairs
export select_time_point_pairs_gp_quality, select_time_point_pairs_sensitivity, select_time_point_pairs_homotopy_probed
export select_time_points_by_conditioning, solve_multipoint_overdetermined
export NoiseFrontierCandidate, NoiseFrontierResult, build_noise_frontier_system, build_noise_frontier_multipoint_template, evaluate_noise_frontier_data_vars_at_point, instantiate_noise_frontier_candidate, validate_noise_frontier_instantiation, validate_noise_frontier_candidate_at_values, noise_frontier_rows, write_noise_frontier_csv

# Export logging functions
export configure_logging, log_matrix, log_equations, log_dict

# Export derivative utilities
export calculate_higher_derivatives, calculate_higher_derivative_terms

# Export transcendental handling
export detect_transcendentals, transform_pep_for_estimation, TranscendentalInfo

# Export problem rescaling
export rescale_pep, unrescale_results, ScaleInfo, choose_scales

# Export diagnostic functions and types
export diagnose, diagnose_model, diagnose_derivative_accuracy, diagnose_polynomial_system, diagnose_sensitivity
export PerfectInterpolant, DiagnosticReport, ComprehensiveDiagnosticReport, DerivativeAccuracyReport, PolynomialFeasibilityReport, SensitivityReport, MultipointDiagnosticAnalysis
export EstimationResultsReport, BacksolveUQReport, AbstractUQOutcome, UncertaintyReport, UQUnavailable, UQComputationError, UQTargetSnapshot, UQLinearizationDiagnostics, JetInfluenceEstimate, StackedJetInfluenceEstimate, PracticalIdentifiabilityIndex, LocalUQSnapshot, UQBacksolveTransform
export DerivativeUncertaintyEstimate, compute_sigma_d, get_sigma_d, sigma_d_diagonal
export SensitivitySeedReport, generate_sensitivity_seeds, seed_vectors_to_candidates
export ErrorBudgetEntry, ErrorBudgetReport, compute_error_budget, compute_multipoint_error_budget
export ParameterSpreadEntry, CrossSolutionSpread, compute_cross_solution_spread
export build_perfect_interpolants, compute_oracle_taylor_coefficients, compute_observable_taylor_coefficients
export ConsensusOptions, CandidateEvidence, CandidateFamily, ConsensusEstimationReport, research_consensus_estimation
export SynthesizedFinalizerOptions, SynthesizedSeed, SynthesizedFinalizerReport, research_synthesized_finalizer
export TimingPhaseEntry, TimingBreakdown, with_estimation_timing, timing_breakdown_to_dict
export BranchConsensusOptions, BranchVariableSupport, BranchBlockSupport, BranchHypothesis, BranchConsensusReport, research_branch_consensus_v1
export BlockConsensusOptions, BlockCluster, BlockDecomposition, BlockVariableConfidence, AssembledHypothesis, BlockConsensusReport, research_block_consensus_v2
export TryhardFinalistOptions, TryhardFinalist, TryhardFinalistReport, research_tryhard_finalists

# Export UQ (Uncertainty Quantification) functions
export AGPInterpolatorUQ, agp_gpr_uq
export se_kernel_derivative, se_kernel_prior_covariance_matrix, se_kernel_cross_time_covariance_matrix
export joint_derivative_covariance, joint_derivative_covariance_cross_time, build_observation_covariance
export gp_derivative_influence_matrix, joint_derivative_estimator_covariance, stacked_jet_index, learned_observation_noise_variance, compute_practical_identifiability_index, physicalize_uncertainty_report, unrescale_uncertainty_report
export print_uncertainty_results

# Export example models
# Simple models
export simple, simple_linear_combination, onesp_cubed, threesp_cubed
export lotka_volterra, vanderpol, brusselator, harmonic, fitzhugh_nagumo, forced_decay
export seir, seir_m1, treatment, biohydrogenation, biohydrogenation_m1, repressilator
export crauste, daisy_mamil3, daisy_mamil4, daisy_mamil4_m1, hiv
export latent_subpopulation_branch, latent_subpopulation_observed_control
export receptor_subtype_binding_branch, receptor_subtype_binding_observed_control
export slow_fast_m1, slowfast_m1
export substr_test, global_unident_test, sum_test, trivial_unident


# Export the main types and functions
export EstimationOptions, SystemSolverMethod, PolishMethod, EstimationFlow
export FlowStandard, FlowDirectOpt
export SolverRS, SolverHC, SolverNLOpt, SolverFastNLOpt, SolverRobust
export InterpolatorS3SE, InterpolatorS3RQ, InterpolatorS3SEpRQ, InterpolatorS3SExRQ, InterpolatorS3Matern52
export PolishNewtonTrust, PolishLevenberg, PolishGaussNewton, PolishBFGS, PolishLBFGS,
       PolishLSOBoundedLog, PolishFastLMBoundedLog
export get_solver_function, get_interpolator_function, get_polish_optimizer, get_ad_backend
export interpolator_method_to_symbol, resolve_interpolator_list, setup_identifiability, compute_shooting_indices
export is_gp_interpolator, is_matern_interpolator, s3_symbol, s3_refine_gp, s3_refine_gp_adaptive, s3_refine_gp_bic
export merge_options, validate_options, print_options
export compatibility_return_code, sync_result_contract!, lineage_summary


# Precompilation workload - runs during package precompilation to reduce first-run latency
@compile_workload begin
	# Use local t/D to avoid polluting namespace
	local _t = ModelingToolkit.t_nounits
	local _D = ModelingToolkit.D_nounits

	# Simple 1-state model to precompile core code paths
	local _k1 = only(@parameters k1)
	local _x = only(@variables x(_t))
	local _y1 = only(@variables y1(_t))

	local _states = [_x]
	local _parameters = [_k1]
	local _state_equations = [_D(_x) ~ _k1 * _x]
	local _measured_quantities = [_y1 ~ _x]

	local _model, _mq = create_ordered_ode_system(
		"precompile_simple", _states, _parameters, _state_equations, _measured_quantities
	)
	local _pep = ParameterEstimationProblem(
		"precompile_simple", _model, _mq, nothing, [-0.5, 0.5], nothing,
		OrderedDict(_parameters .=> [0.5]), OrderedDict(_states .=> [0.5]), 0
	)

	# Run with HC solver (most common) and minimal settings
	local _opts = EstimationOptions(
		datasize = 11,
		noise_level = 0.0,
		system_solver = SolverHC,
		interpolator = InterpolatorAAAD,
		shooting_points = 0,
		nooutput = true,
		diagnostics = false,
		save_system = false,
		use_parameter_homotopy = false,
		polish_solver_solutions = false,
		polish_solutions = false,
	)

	local _est_problem = sample_problem_data(_pep, _opts)
	try
		redirect_stdout(devnull) do
			redirect_stderr(devnull) do
				with_logger(NullLogger()) do
					analyze_parameter_estimation_problem(_est_problem, _opts)
				end
			end
		end
	catch err
		_rethrow_if_interrupt(err)
		# Ignore errors during precompilation - we just want to trigger compilation
	end
end

end # module
