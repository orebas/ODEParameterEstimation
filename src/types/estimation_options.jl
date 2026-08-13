# estimation_options.jl
# Comprehensive options struct for ODEParameterEstimation.jl

# Enums for type-safe option selection
"""
	SystemSolverMethod

Enum for selecting the polynomial system solver method.
"""
@enum SystemSolverMethod begin
	SolverRS           # solve_with_rs - RealSolutions/RUR based solver (requires extension)
	SolverHC           # solve_with_hc - HomotopyContinuation solver (default)
	SolverNLOpt        # solve_with_nlopt - NonlinearSolve optimization
	SolverFastNLOpt    # solve_with_fast_nlopt - Fast compiled NLOpt
	SolverRobust       # solve_with_robust - Robust solver with multiple fallbacks
end

"""
	InterpolatorMethod

Enum for selecting the data interpolation method.
"""
@enum InterpolatorMethod begin
	InterpolatorAAAD           # aaad - Basic AAA rational interpolation
	InterpolatorAAADGPR        # aaad_gpr_pivot - GPR-based AAA (default)
	InterpolatorAAADOld        # aaad_old_reliable - Conservative AAA
	InterpolatorFHD            # Floater-Hormann interpolation
	InterpolatorAGPRobust      # agp_gpr_robust - Robust GP that handles smooth/noiseless data
	InterpolatorAGPRobustRQ    # agp_gpr_robust with Rational Quadratic kernel
	InterpolatorAGPRobustSEpRQ # agp_gpr_robust with SE + RQ sum kernel
	InterpolatorAGPRobustSExRQ # agp_gpr_robust with SE * RQ product kernel
	InterpolatorAGPRobustMatern52 # agp_gpr_robust with Matérn-5/2 kernel
	InterpolatorS2AAAMLE           # S2 composite: AAA(raw data) → MLE (no GP)
	InterpolatorS3SE               # S3 composite: GP(SE) → AAA → MLE (deprecated — forwards to AdaptSE)
	InterpolatorS3RQ               # S3 composite: GP(RQ) → AAA → MLE (deprecated — forwards to AdaptRQ)
	InterpolatorS3SEpRQ            # S3 composite: GP(SE+RQ) → AAA → MLE (deprecated — forwards to AdaptSEpRQ)
	InterpolatorS3SExRQ            # S3 composite: GP(SE×RQ) → AAA → MLE (deprecated — forwards to AdaptSExRQ)
	InterpolatorS3Matern52         # S3 composite: GP(Matérn-5/2) → AAA → MLE (deprecated — forwards to AdaptMatern52)
	InterpolatorS3AdaptSE          # S3 adaptive-tol: GP(SE) → AAA(adaptive) → MLE
	InterpolatorS3AdaptRQ          # S3 adaptive-tol: GP(RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptSEpRQ       # S3 adaptive-tol: GP(SE+RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptSExRQ       # S3 adaptive-tol: GP(SE×RQ) → AAA(adaptive) → MLE
	InterpolatorS3AdaptMatern52    # S3 adaptive-tol: GP(Matérn-5/2) → AAA(adaptive) → MLE
	InterpolatorS3BICSE            # S3 BIC: GP(SE) → AAA(BIC-selected) → MLE
	InterpolatorS3BICRQ            # S3 BIC: GP(RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICSEpRQ         # S3 BIC: GP(SE+RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICSExRQ         # S3 BIC: GP(SE×RQ) → AAA(BIC-selected) → MLE
	InterpolatorS3BICMatern52      # S3 BIC: GP(Matérn-5/2) → AAA(BIC-selected) → MLE
	InterpolatorAGPUQ          # agp_gpr_uq - GP with full UQ (for calibrated uncertainty)
	InterpolatorChebyshevAICc  # Chebyshev polynomial with AICc degree selection (spectral)
	InterpolatorChebyshevBIC   # Chebyshev polynomial with BIC degree selection (spectral)
	InterpolatorFourierAdaptive # FFT spectral differentiation with adaptive filtering
	InterpolatorCustom         # User-provided custom interpolator
end

"""
	PolishMethod

Enum for selecting the optimization method for solution polishing.
Note: These correspond to NonlinearSolve.jl and Optim.jl methods.
"""
@enum PolishMethod begin
	PolishNewtonTrust      # NewtonTrustRegion from NonlinearSolve (legacy default)
	PolishLevenberg        # LevenbergMarquardt
	PolishGaussNewton      # GaussNewton
	PolishBFGS             # BFGS from Optim.jl
	PolishLBFGS            # LBFGS from Optim.jl
	# Residual-mode polishers operating in per-variable transformed coordinates
	# (`:auto` policy: log for positive bounds, shifted-log for signed bounds, linear
	# for unbounded). Switch back to `PolishNewtonTrust` to restore the legacy scalar
	# polish path; the dispatch is fully reversible at runtime.
	PolishLSOBoundedLog        # LeastSquaresOptim.LevenbergMarquardt() with bounds
	PolishFastLMBoundedLog     # FastLevenbergMarquardt.lmsolve!() with bounds
end

"""
	is_residual_polish_method(method::PolishMethod) -> Bool

True when `method` uses the residual-vector polish path (`_polish_single_residual`)
rather than the scalar-loss `Optimization.solve` path.
"""
function is_residual_polish_method(method::PolishMethod)
	return method === PolishLSOBoundedLog || method === PolishFastLMBoundedLog
end

"""
	EstimationFlow

Enum selecting the high-level workflow used during estimation.

- `FlowStandard`: New optimized multishot workflow (default)
- `FlowDirectOpt`: Direct local optimization workflow (BFGS from random start)
"""
@enum EstimationFlow begin
	FlowStandard     # optimized_multishot_parameter_estimation
	FlowDirectOpt    # direct_optimization_parameter_estimation
end

const SI_PLACEHOLDER_CATEGORY_ALIASES = Dict{Symbol, Symbol}(
	:dd_derivative_unmapped => :observable_derivative_overflow,
	:nonobservable_derivative => :support_jet,
	:state_or_input_jet => :support_jet,
	:unknown_variable => :true_unknown_variable,
)

const SI_PLACEHOLDER_CANONICAL_CATEGORIES = Set((
	:dd_observable_index_oob,
	:observable_derivative_overflow,
	:measured_rhs_jet,
	:state_jet,
	:parameter_or_ic_symbol,
	:transformed_analytic_support,
	:support_jet,
	:no_dd_derivative,
	:sian_auxiliary,
	:true_unknown_variable,
	:late_map_miss,
))

const SI_PLACEHOLDER_VALID_CATEGORIES = union(
	SI_PLACEHOLDER_CANONICAL_CATEGORIES,
	Set(keys(SI_PLACEHOLDER_CATEGORY_ALIASES)),
)

canonicalize_si_placeholder_category(category::Symbol) = get(SI_PLACEHOLDER_CATEGORY_ALIASES, category, category)

normalize_si_placeholder_fail_categories(categories) =
	unique(Symbol[canonicalize_si_placeholder_category(cat) for cat in categories])

"""
	EstimationOptions

A comprehensive options struct that centralizes all configuration parameters for the 
ODEParameterEstimation package. This struct consolidates tolerances, solver selections,
algorithm parameters, and debugging flags into a single, type-stable structure.

# Fields

## Solver and Algorithm Selection
- `system_solver::SystemSolverMethod`: Main polynomial system solver (default: `SolverHC`)
- `ode_solver`: ODE solver for simulation (default: `AutoVern9(Rodas5P())`)
- `interpolator::InterpolatorMethod`: Data interpolation method (default: `InterpolatorAAADGPR`)
- `custom_interpolator::Union{Nothing, Function}`: Custom interpolation function when `interpolator=InterpolatorCustom`

## Numerical Tolerances
- `abstol::Float64`: Absolute tolerance for ODE solving and optimization (default: 1e-14)
- `reltol::Float64`: Relative tolerance for ODE solving and optimization (default: 1e-14)
- `rtol::Float64`: Relative tolerance for matrix rank calculations (default: 1e-12)
- `output_precision::Int32`: Output precision for RUR solver (default: 20)

## Solution Filtering and Validation
- `imag_threshold::Float64`: Threshold for ignoring imaginary components (default: 1e-8)
- `clustering_threshold::Float64`: Threshold for solution clustering (default: 1e-5)

## Multi-shot Parameters
- `shooting_points::Int`: Number of shooting points for multi-shot estimation (default: 12)
- `shooting_warp::Bool`: Use exponential warp to cluster points near t=0 (default: true)
- `shooting_warp_beta::Float64`: Warp strength; 0≈uniform, 3=default (default: 3.0)
- `point_hint::Float64`: Hint for time point selection, in [0,1] range (default: 0.5)

## Derivative and Reconstruction Parameters
- `max_deriv_level::Int`: Maximum allowed derivative level (default: 10)

## Optimization Parameters
- `polish_solutions::Bool`: Whether to polish solutions using optimization (default: false)
- `polish_solver_solutions::Bool`: Polish raw solver solutions with fast NLLS (default: true)
- `polish_method::PolishMethod`: Optimization method for polishing (default: `PolishLSOBoundedLog` — bounded LSO LevenbergMarquardt in per-variable log-space, recommended after the 2026-05 polish bake-off; pass `PolishNewtonTrust` to restore the legacy scalar polish)
- `polish_maxiters::Int`: Maximum iterations for solution polishing (default: 100)
- `opt_maxiters::Int`: Maximum iterations for general optimization (default: 10000)
- `opt_lb::Union{Nothing, Vector{Float64}}`: Lower bounds for optimization (default: nothing)
- `opt_ub::Union{Nothing, Vector{Float64}}`: Upper bounds for optimization (default: nothing)
- `opt_ad_backend::Symbol`: AD backend for optimization: `:forward` (default), `:enzyme`, `:finite`
- `polish_maxtime::Float64`: Per-solution wall-clock timeout in seconds (default: 3600.0)
- `polish_max_concurrency::Int`: Cap on the number of polish tasks running in parallel (default: `Threads.nthreads()`). With too many candidates spawned at once, each polish's ForwardDiff-Jacobian step contends for cores and slows ~N/T× — the per-polish deadline then fires before convergence. Set to a smaller number to cap concurrency below `nthreads()`.
- `polish_divergence_factor::Float64`: Stop polish if loss exceeds initial_loss * this factor (default: 10.0)
- `polish_stagnation_window::Int`: Stop polish if no improvement in this many iterations (default: 50)
- `polish_ode_maxiters::Int`: ODE solver maxiters inside polish loss function (default: 5000). DiffEq default is 100000 but successful stiff solves typically use 500-2000 steps. Capping at 5000 fails fast on hopeless parameter regions.
- `polish_coordinate_policy::Symbol`: per-variable transform policy for the polish step: `:auto` (default), `:linear`, `:log_only`, `:shifted_log_only`.
- `polish_regularization_lambda::Float64`: optional L2 regularization on internal coordinates for residual-mode polish (default: 0.0). Nonzero values can help on ill-conditioned cases but hurt well-posed ones.
- `polish_softwall_lambda::Float64`: soft-wall penalty strength for residual-mode polish (default: 1e-2). When > 0, augments the residual with a penalty that activates when a parameter is within `polish_softwall_epsilon` of either bound (measured in transformed internal coords). Targets bound-saturation pathologies (e.g. biohydrogenation k10) without biasing interior solutions. **Verified safe on 2026-05-15 fresh-look investigation**: zero penalty for typical benchmark truth values (which sit well inside the bound interval). Set to 0.0 to disable entirely.
- `polish_softwall_epsilon::Float64`: width of the soft-wall band in transformed internal coords, as a fraction of the half-range (default: 0.10). Parameters with `|p_internal - midpoint| > (1 - epsilon) * halfrange` incur the penalty. With benchmark bounds `[1e-5, 10]`, ε=0.10 means values outside roughly `[3e-5, 5]` start incurring penalty — outside the typical truth range.
- `polish_lso_delta::Float64`: LSO trust-region radius (default: 10.0).
- `polish_lso_x_tol::Float64`/`polish_lso_f_tol::Float64`/`polish_lso_g_tol::Float64`: LSO/FastLM tolerances (default: -1.0 = inherit from `reltol`/`abstol`).
- `terminal_fallback::Symbol`: Terminal rescue if algebraic search yields no candidates: `:none` or `:direct_opt` (default: `:direct_opt`)
- `backsolve_recovery::Symbol`: Recovery policy for blown backsolves: `:none` or `:algebraic_resolve` (default: `:algebraic_resolve`)
- `t0_state_completion::Symbol`: State completion policy during `t=0` rescue: `:strict` or `:seed_for_polish` (default: `:strict`)

## Data Sampling Parameters
- `datasize::Int`: Number of data points to generate (default: 21)
- `time_interval::Vector{Float64}`: Time interval for sampling (default: [-0.5, 0.5])
- `noise_level::Float64`: Level of noise to add to synthetic data (default: 0.0)
- `noise_model::Symbol`: Synthetic noise model: `:additive`/`:homoskedastic` or `:relative`/`:multiplicative` (default: `:additive`)
- `uneven_sampling::Bool`: Whether to use uneven time sampling (default: false)
- `uneven_sampling_times::Vector{Float64}`: Custom sampling times (default: Float64[])

## Debug and Output Flags
- `nooutput::Bool`: Suppress output messages (default: false)
- `diagnostics::Bool`: Enable diagnostic output (default: true)
- `debug_solver::Bool`: Enable solver debugging (default: false)
- `debug_cas_diagnostics::Bool`: Enable CAS system diagnostics (default: false)
- `debug_dimensional_analysis::Bool`: Enable dimensional analysis debugging (default: false)
- `trap_debug::Bool`: Enable debug trapping with file output (default: false)
- `profile_phases::Bool`: Print per-phase timing/allocation breakdown (default: false)

## Feature Flags
- `flow::EstimationFlow`: Which workflow to run (default: `FlowStandard`)
- `use_si_template::Bool`: Use StructuralIdentifiability.jl templates (default: true)
- `system_construction_policy::Symbol`: Polynomial construction policy. `:noise_frontier` selects low-derivative full-rank systems, then minimizes mixed volume within that frontier; pass `:legacy` to restore the pre-frontier construction.
- `construction_candidate_limit::Int`: Maximum number of same-derivative-cap frontier bases to evaluate in noise-frontier probes.
- `construction_beam_width::Int`: Basis-exchange beam width for noise-frontier probes.
- `construction_compute_mixed_volume::Bool`: Whether noise-frontier probes compute actual HC mixed volume for candidate bases.
- `save_system::Bool`: Save polynomial systems to files (default: true)
- `display_system::Bool`: Display system being solved (default: false)
- `polish_only::Bool`: Only polish existing solutions (default: false)
- `ideal::Bool`: Use ideal (noise-free) system construction (default: false)
- `compute_uncertainty::Bool`: Compute parameter uncertainty via GP covariance + IFT (default: false)
- `uq_failure_policy::Symbol`: Experimental UQ sidecar failure policy: `:return_failed` or `:throw` (default: `:return_failed`)
- `si_placeholder_fail_categories::Vector{Symbol}`: Temporary strictness gate for SI mapping categories. Accepts canonical semantic names and recent compatibility aliases. Empty preserves current behavior.
- `auto_handle_transcendentals::Bool`: Automatically detect and handle sin/cos/exp(c*t) in equations (default: true)
- `auto_rescale::Bool`: Power-of-2 rescaling of states/params/observables/data to O(1) before estimation, with results un-rescaled after (default: true; near-identity on already-O(1) models, rescues ill-scaled ones). Set false to disable. See core/problem_rescaling.jl.
- `auto_filter_interpolators::Bool`: When true, filters AAA-family interpolators (S2AAAMLE, AAAD, AAADOld) out of the user's `interpolators` list when the data's estimated relative noise σ̂ exceeds method-specific thresholds (1e-4 for S2, 1e-5 for AAAD/AAADOld). These methods produce catastrophic derivative errors at noise > threshold (verified empirically); GP-family methods are kept regardless. If filtering empties the list, falls back to `InterpolatorAAADGPR`. Default: `true`. Set to `false` to bypass and run all user-specified methods unconditionally.
- `synthesize_aggregate_candidates::Bool`: When true, injects extra synthetic candidates derived by per-component aggregating (median / mean / 25%-trimmed mean) of the existing SP and MP candidates' parameters and ICs. Each synthetic candidate is tagged with `provenance.source_type = :synthesized_aggregate` and `provenance.aggregation_strategy`; full lineage written to `artifacts/diagnostics/<model>/synthesis_log.csv`. Default: `true`. Set to `false` to skip synthesis entirely.

## HomotopyContinuation Specific
- `use_monodromy::Bool`: Use monodromy for HomotopyContinuation (default: false)
- `use_parameter_homotopy::Bool`: Use parameter homotopy for multi-shot estimation (default: true). When enabled, tracks solutions between shooting points instead of solving from scratch at each point. Can provide 2-20x speedup for shooting_points >= 3.
- `hc_real_tol::Float64`: Tolerance for real solutions in HC (default: 1e-9)
- `hc_show_progress::Bool`: Show HC solving progress (default: false)

## StructuralIdentifiability Parameters
- `si_probability::Float64`: Probability threshold for identifiability analysis (default: 0.99)
- `si_infolevel::Int`: Information level for SI.jl output (default: 0)

## File I/O
- `log_dir::String`: Directory for log files (default: "logs")
- `save_filepath::String`: Path for saving polynomial systems (default: "")

# Constructors

```julia
# Create with all defaults
opts = EstimationOptions()

# Create with custom tolerances
opts = EstimationOptions(abstol=1e-12, reltol=1e-12)

# Create with custom solver and interpolator
opts = EstimationOptions(
	system_solver=solve_with_hc,
	interpolator=aaad,
	use_monodromy=true
)

# Create with debugging enabled
opts = EstimationOptions(
	diagnostics=true,
	debug_solver=true,
	debug_cas_diagnostics=true
)
```

# Notes

- This struct is designed to be immutable for thread safety and performance
- Default values are chosen based on extensive testing and should work well for most problems
- For challenging problems, use an explicit `interpolators = [...]` list rather than relying on hidden retries
- When debugging, enable relevant debug flags and set `nooutput=false`
"""
Base.@kwdef struct EstimationOptions
	# Solver and Algorithm Selection
	system_solver::SystemSolverMethod = SolverHC
	ode_solver::Any = AutoVern9(Rodas5P())  # Any type due to ODE solver type complexity
	interpolator::InterpolatorMethod = InterpolatorAAADGPR
	custom_interpolator::Union{Nothing, Function} = nothing

	# Multi-interpolator support: when non-empty, overrides `interpolator` field
	interpolators::Vector{InterpolatorMethod} = InterpolatorMethod[
		InterpolatorAGPRobust,        # SE kernel — robust GP baseline
		InterpolatorAGPRobustRQ,      # RQ kernel — Rational Quadratic (heavier-tail length-scale mixture)
		InterpolatorS3AdaptSE,        # GP→AAA(adaptive)→MLE
		InterpolatorS3AdaptRQ,        # GP→AAA(adaptive)→MLE with RQ kernel
		InterpolatorChebyshevBIC,     # Spectral, BIC degree selection
		InterpolatorChebyshevAICc,    # Spectral, AICc degree selection
		InterpolatorAAADGPR,          # GPR-pivoted AAA — proven for ill-conditioned systems
		InterpolatorAAAD,             # Pure AAA rational interpolation
		InterpolatorS2AAAMLE,         # AAA→MLE (no GP step)
	]
	custom_interpolators::Vector{Function} = Function[]

	# Numerical Tolerances
	abstol::Float64 = 1e-14
	reltol::Float64 = 1e-14
	rtol::Float64 = 1e-12
	output_precision::Int32 = 20

	# Solution Filtering and Validation
	imag_threshold::Float64 = 1e-8
	clustering_threshold::Float64 = 1e-5

	# Branch detection (Phase B candidate-reduction). When enabled, replaces the
	# legacy "cluster threshold 0.001 + oracle sort" pipeline with two stages:
	#   pre-polish: drop candidates with err > branch_err_factor × min(err);
	#               L-inf normalized clustering in identifiable-only variable space
	#               at branch_cluster_eps; one rep per cluster polished.
	#   post-polish: re-cluster polished reps in id-only space; drop clusters with
	#                median_err > branch_resid_factor × best_cluster_median_err;
	#                drop clusters with size < branch_min_size; each surviving
	#                cluster surfaces as one "algebraic branch", branch_size attached.
	branch_detection::Bool = true
	branch_cluster_eps::Float64 = 0.001            # Tightened 0.05→0.001 in 2026-05-13: read as a "target precision in MAD-normalized identifiable space." The 0.05 default was merging truth-near clusters with non-truth-near ones for low-noise cells; 0.001 preserves distinct basins (cost: roughly 2× more rows in nopolish result.csv, mitigated by branch_top_k).
	branch_err_factor::Float64 = 100.0
	branch_resid_factor::Float64 = 100.0
	branch_min_size::Int = 1
	branch_top_k::Int = 20                         # Maximum cluster reps to return at the output stage. Sorted by `rank_strategy` (default `:err_only`; the retired S2 = (saturation_count, is_neg1, err) remains selectable) before slicing. **Dropped 100→20 on 2026-05-17** after probe4c K-recall analysis on the full 2026-05-14 numbat benchmark (1136 cells): under S2 sort, K=20 already saturates the candidate-set ceiling at the ≤10% threshold (83.5% K-recall at K=20 = 83.5% set ceiling); K=100 buys nothing further. K=10 catches 99.4% of the ceiling; K=5 catches 98.8%. Earlier 2026-05-14 setting of 100 was based on the legacy "within 2× of 06" recovery metric (74% at K=20, 77% at K=100) which is more conservative than absolute K-recall. Set to 0 to disable (return all reps). **Acts as a safety cap** when `algebraic_multiplicity` is set: actual output is `min(algebraic_multiplicity, branch_top_k, length(cluster_reps))`.

	# Algebraic multiplicity of the parameter-estimation problem — the number of
	# distinct (params, IC) tuples in the identifiable subspace that produce
	# identical observations. When set, the output is truncated to this many rows
	# (capped above by `branch_top_k` as a safety net). When `nothing`, output is
	# the full top-K candidate list (length up to `branch_top_k`).
	#
	# AUTO-COMPUTED since 2026-07: when this field is left `nothing`, ODEPE
	# detects M during the SI template build (si_equation_builder.jl —
	# `Groebner.quotient_basis` on the SIAN ideal; gauge/positive-dimensional
	# systems via projection to finite-valued coordinates) and hands it off
	# through the scoped RunContext (`_run_ctx_take_auto_m!`, consumed once in
	# `analyze_parameter_estimation_problem`). A caller-supplied value always
	# overrides auto-detection — PEB's per-cell template may still inject the
	# hand-curated `config/systems.json[*].algebraic_multiplicity` (derived via
	# HC root-counting, `repro/multiplicity_complete_2026_05_19/`). Detection
	# failure leaves the field `nothing`: no truncation, no M≥2 full-space
	# clustering protection.
	#
	# Type: positive Int (the multiplicity), or `nothing` (use full top-K).
	algebraic_multiplicity::Union{Int, Nothing} = nothing

	# Ranking strategy for the top-K cluster reps returned in result.csv.
	#
	# DEFAULT `:err_only` (2026-06-12) — rank candidates by data residual `err` (SSE)
	# ascending. Lowest residual wins.
	#
	# WHY (and why NOT the old `:sat_neg1_err` "S2"): the older S2 default and the whole
	# threshold trade-off it was tuned on (wallaby 2026-05-17) were measured on a BROKEN
	# `err` metric — candidate `err` was computed in two incompatible units
	# (`process_raw_solution` used ‖resid‖/N while polish/synth/seed/optimizer used Σresid²),
	# so cross-source comparisons were apples-vs-oranges and the `saturation`/`is_untagged`
	# keys were a band-aid for an untrustworthy residual. That was unified to SSE in 2026-06
	# (commit b543946). With `err` now ONE consistent unit, the 2026-06-12 ranking study
	# (`repro/ranking_study_2026_06_12/`) found the lowest-`err` candidate is the truth-near
	# one in EVERY M1 "matter" cell at 1em6 — `:err_only`, the full production
	# `:sat_neg1_err` path, and every other scheme give IDENTICAL 10/10 top-1 capture (even
	# when truth-near rows are only 3/244 of the pool). So the simplest honest scheme is the
	# default; the S2 cleverness is unnecessary on a correct residual.
	# (Pre-fix trade-off, retained for context only — reflects the broken err: ≤1e-4
	#  `:err_only` 69.7% vs `:sat_neg1_err` 60.2%; ≤1e-2 `:err_only` ~83.6% vs ~86.6%.
	#  See repro/polish_regression_2026_05_19/FINDINGS.md.)
	#
	# Options:
	#   :err_only         — DEFAULT. Sort by data residual `err` (SSE) ascending. Correct +
	#                       simplest now that `err` is one consistent unit across all sources.
	#   :sat_neg1_err     — (saturation_count, is_untagged, err). Legacy "S2": demote
	#                       bound-pegged rows first, then untagged provenance
	#                       (`polish_source_hc_idx == -1`/nothing), then residual. Built for
	#                       the broken-err candidate distribution; kept selectable. Requires
	#                       user-provided opt_lb/opt_ub to fully activate.
	#   :sat_err          — (saturation_count, err). Saturation-demotion without is_untagged.
	#   :lognorm_err      — (Σ log²(p), err). Bound-free experimental. Falsified in probe4b
	#                       (truth values genuinely far from 1 get penalized).
	#   :lognorm_neg1_err — (Σ log²(p), is_untagged, err).
	rank_strategy::Symbol = :err_only

	# Output-stage clustering method. `:identifiable_subspace` (default) does
	# two-stage clustering: rough basin separation at a coarse threshold, then
	# within-basin MAD-normalized L∞ merging at `subspace_cluster_eps`. This
	# collapses 50+ near-duplicate rows along practical-non-identifiability axes
	# (e.g. slow_fast's 50 mirror-basin rows that differ only on xA/xB/eB) while
	# preserving algebraically-distinct basins. `:bit_identical` restores the
	# legacy 1e-5 relative-distance dedup. Full-space dedup ALWAYS applies when
	# algebraic siblings may be present — pools produced by successful branch
	# completion AND any pool with detected/declared algebraic_multiplicity ≥ 2
	# (raw M≥2 pools carry siblings too; completion can fail on its single
	# default anchor). Merely enabling `branch_completion` does not override
	# this option. See `cluster_solutions_identifiable_subspace` and
	# `_cluster_output_candidates`.
	cluster_method::Symbol = :identifiable_subspace
	# Rough-cluster threshold for stage-1 (basin identification). 1.0 = parameters
	# differ by more than the mean magnitude (i.e. different basins). Tight
	# enough that distinct algebraic solutions stay separate.
	rough_cluster_eps::Float64 = 1.0
	# Stage-2 within-basin MAD-normalized L∞ threshold. 0.05 ≈ "5% of MAD-scaled
	# spread" — coarser than the 1e-5 bit-identical dedup but tight enough to
	# preserve genuine sub-basin structure.
	subspace_cluster_eps::Float64 = 0.05

	# Output-stage M-selection diversity. When algebraic_multiplicity asks for
	# multiple returned rows, prefer candidates separated by at least this
	# relative solution-distance threshold before filling remaining slots from
	# the original rank order. This is best-effort: it cannot invent a missing
	# branch, and it deliberately falls back to ranked near-duplicates if too few
	# separated candidates exist.
	branch_diversity_selection::Bool = true
	branch_diversity_eps::Float64 = 0.01

	# Algebraic branch completion (default-on as of 2026-05-27). When a system has
	# algebraic_multiplicity > 1, ODEPE uses the normal candidate pool only to
	# choose an anchor, then solves the SI-template equations with exact jets
	# implied by that anchor and replaces the returned pool with the verified
	# algebraic sibling set. Regression-clean with it on; generic-branch-coverage
	# benefit is being confirmed by the Wallaby/Quoll M>1 ablations.
	branch_completion::Bool = true
	branch_completion_max_anchors::Int = 1
	branch_completion_residual_tol::Float64 = 1e-6

	# Instrumentation (opt-in): if non-nothing, dump the raw HC candidate list
	# (after process_raw_solution err computation, before pre-polish clustering)
	# as a CSV to this path. Used for offline branch-clustering analysis.
	dump_raw_candidates_path::Union{Nothing, String} = nothing

	# Instrumentation (opt-in): if non-nothing, dump the full polished candidate
	# list from `_polish_batch_from_context` (one row per polished cluster rep)
	# BEFORE any downstream clustering (cluster_solutions / _detect_branches).
	# Each row carries `polish_source_hc_idx` linking back to a raw_candidates.csv row.
	dump_polished_path::Union{Nothing, String} = nothing

	# Multi-shot Parameters
	shooting_points::Int = 12
	shooting_warp::Bool = true                   # true = exponential warp, false = equidistant
	shooting_warp_beta::Float64 = 3.0            # warp strength (0≈uniform, 3=default)
	point_hint::Float64 = 0.5

	# Derivative and Reconstruction Parameters
	max_deriv_level::Int = 10

	# Optimization Parameters
	polish_solutions::Bool = false
	polish_solver_solutions::Bool = true
	# Default chosen 2026-05 after the polish bake-off
	# (see temp_plans/2026-05-01_local_polish_default_recommendation.md): bounded
	# LeastSquaresOptim Levenberg-Marquardt in per-variable transformed coordinates.
	# Switch to `PolishNewtonTrust` to restore the legacy scalar-loss polish path.
	polish_method::PolishMethod = PolishLSOBoundedLog
	polish_maxiters::Int = 100
	opt_maxiters::Int = 10000
	opt_lb::Union{Nothing, Vector{Float64}} = nothing
	opt_ub::Union{Nothing, Vector{Float64}} = nothing
	opt_ad_backend::Symbol = :forward
	polish_maxtime::Float64 = 3600.0         # Per-solution wall-clock timeout (seconds). Bumped 300→3600 in 2026-05-13: with bounded concurrency each polish sees a fair CPU share and converges in <100s on most cells, but stiff/multi-basin cases (flexible_arm, fhn) need substantially more wall-time to escape singular limits.
	polish_max_concurrency::Int = Threads.nthreads()  # Maximum number of polish tasks running in parallel. Defaults to Threads.nthreads() so each polish gets a fair CPU share. Prevents thread contention from slowing each polish ~N/T× when many candidates are submitted at once (each polish does heavy ForwardDiff Jacobian assembly via ODE integration; competing for cores left every polish stuck at maxtime in the 2026-05 numbat benchmark).
	polish_divergence_factor::Float64 = 10.0 # Stop if loss > initial_loss * this
	polish_stagnation_window::Int = 50       # Stop if no improvement in N iters
	polish_ode_maxiters::Int = 5000          # ODE solver maxiters inside polish loss (DiffEq default: 100000)

	# Per-variable polish coordinate transform policy. `:auto` selects per variable:
	#  - `:log` for `lb > 0 && isfinite(ub)`
	#  - `:shifted_log` for finite signed bounds
	#  - `:linear` for unbounded variables
	# Other accepted values: `:linear`, `:log_only`, `:shifted_log_only`.
	polish_coordinate_policy::Symbol = :auto

	# Optional log-space L2 regularization for residual-mode polish. Augments the
	# residual with `√λ · x_internal`, pulling toward `x = 1` (or `x = -shift+1`)
	# in scaled coordinates. Default off; nonzero values can rescue ill-conditioned
	# `crauste`/`seir`/`hiv`-style cases at the cost of bias on well-posed ones.
	# No robust auto-selection across models exists yet.
	polish_regularization_lambda::Float64 = 0.0

	# Soft-wall penalty near bounds for residual-mode polish. When
	# `polish_softwall_lambda > 0`, augments the residual with one row per parameter:
	# zero in the interior of the bound interval, growing quadratically as the
	# parameter approaches either bound. Targets bound-saturation pathologies
	# (e.g. biohydrogenation k10 hitting upper bound) without biasing interior
	# solutions. Default ON after 2026-05-15 fresh-look investigation showed:
	# (1) on bioh_6_1em6, eliminates k10 saturation 97/100 → 0/100 and lifts
	#     rank-1 oracle 9.18 → 4.19 (2.2× improvement);
	# (2) λ is essentially on/off — any nonzero value past ~1e-4 gives the same
	#     effect; ε is the dominant knob;
	# (3) the penalty zone (at ε=0.10 with bounds [1e-5, 10]) is values outside
	#     roughly [3e-5, 5] — well outside typical benchmark truth values, so
	#     this is a no-op on cells without saturation pathology.
	# Set both to 0.0 to disable. See polish_residual.jl for the exact form.
	polish_softwall_lambda::Float64 = 1e-2
	polish_softwall_epsilon::Float64 = 0.10

	# LSO (LeastSquaresOptim.LevenbergMarquardt) trust-region & tolerance knobs.
	# Negative tolerances mean "use `reltol`/`abstol`". `polish_lso_delta` is the
	# initial trust-region radius (LSO default is 1.0; the bake-off used 10.0).
	polish_lso_delta::Float64 = 10.0
	polish_lso_x_tol::Float64 = -1.0
	polish_lso_f_tol::Float64 = -1.0
	polish_lso_g_tol::Float64 = -1.0

	# SHADE+LM baseline (`src/baselines/shade_lm.jl`). Hybrid global/local optimizer
	# used as a comparison baseline alongside the multishot / direct-opt flows.
	# `shade_population = 0` triggers auto-sizing `max(50, 10 * (n_states + n_params))`.
	# `shade_seed = nothing` lets Metaheuristics pick a random seed.
	shade_total_max_evals::Int = 200_000
	shade_total_max_time::Float64 = 600.0
	shade_global_eval_fraction::Float64 = 0.7
	shade_n_local_starts::Int = 5
	shade_population::Int = 0
	shade_seed::Union{Nothing, UInt} = nothing

	terminal_fallback::Symbol = :direct_opt   # :none | :direct_opt
	backsolve_recovery::Symbol = :algebraic_resolve  # :none | :algebraic_resolve
	t0_state_completion::Symbol = :strict    # :strict | :seed_for_polish

	# Sensitivity-based seed generation (σ_d-aware probing). Off by default until
	# validation sweep confirms it captures the existing synthesized_finalizer wins.
	# When enabled, computes per-candidate Σ_x = S · diag(σ_d²) · S' and emits
	# additional polish seeds along significant eigenvectors (sloppy directions),
	# plus pairwise Mahalanobis-gated blends between candidates.
	use_sensitivity_seeds::Bool = false
	# Multiplier on √λ for eigenvector probes. 1.0 emits ±1σ along sloppy directions;
	# larger values explore farther at the cost of more polish budget.
	sensitivity_seed_probe_scale::Float64 = 1.0
	# Eigenvalue significance: only emit probes for eigenvalues with λ_i / λ_max above
	# this fraction. Tighter = fewer probes.
	sensitivity_seed_eigenvalue_threshold::Float64 = 0.01
	# Mahalanobis distance² threshold for cross-candidate blending. Negative means
	# "use chi² 95% quantile for n_unknowns degrees of freedom."
	sensitivity_seed_mahalanobis_threshold::Float64 = -1.0
	# Order-decay floor parameter for σ_d construction: σ_d_floor(order) = noise_level · κ^order.
	sensitivity_sigma_d_kappa::Float64 = 2.0

	# Data Sampling Parameters
	datasize::Int = 21
	time_interval::Vector{Float64} = [-0.5, 0.5]
	noise_level::Float64 = 0.0
	noise_model::Symbol = :additive
	uneven_sampling::Bool = false
	uneven_sampling_times::Vector{Float64} = Float64[]

	# Debug and Output Flags
	nooutput::Bool = false
	diagnostics::Bool = true
	debug_solver::Bool = false
	debug_cas_diagnostics::Bool = false
	debug_dimensional_analysis::Bool = false
	trap_debug::Bool = false
	profile_phases::Bool = false  # Print per-phase timing/allocation breakdown
	heartbeat::Bool = true        # Live flushed [HB] phase markers (suppressed by nooutput)

	# Feature Flags
	flow::EstimationFlow = FlowStandard
	use_si_template::Bool = true
	system_construction_policy::Symbol = :noise_frontier
	construction_candidate_limit::Int = 64
	construction_beam_width::Int = 16
	construction_compute_mixed_volume::Bool = true
	save_system::Bool = true
	display_system::Bool = false
	polish_only::Bool = false
	ideal::Bool = false
	compute_uncertainty::Bool = false  # Experimental GP/IFT sidecar
	uq_failure_policy::Symbol = :return_failed  # :return_failed | :throw
	si_placeholder_fail_categories::Vector{Symbol} = Symbol[]
	auto_handle_transcendentals::Bool = true  # Automatically detect and handle sin/cos/exp in equations
	auto_rescale::Bool = true  # Power-of-2 rescale states/params/observables/data to O(1) before estimation, un-rescale results after (see core/problem_rescaling.jl). Near-identity (mild powers of 2) on already-O(1) models; rescues ill-scaled ones (e.g. raw hiv 43.7→1.2e-3). Set false to disable.
	auto_filter_interpolators::Bool = true  # Filter AAA-family interpolators (S2/AAAD/AAADOld) by data-driven σ̂ before the SP loop
	synthesize_aggregate_candidates::Bool = true  # Inject per-component median/mean/trim25 aggregates of SP, MP, SP∪MP candidates as extra polish seeds before clustering. Sidecar at artifacts/diagnostics/<model>/synthesis_log.csv.
	gp_s3_refinement::Bool = false  # If true, each GP interpolator also produces an S3 (GP→AAA→MLE) barycentric
	s3_adapt_k::Float64 = 10.0     # Noise multiplier for S3 adaptive tolerance (higher = fewer support points)

	# HomotopyContinuation Specific
	use_monodromy::Bool = false
	use_parameter_homotopy::Bool = true  # Use parameter homotopy for multi-shot (track solutions between points)
	use_column_scaling::Bool = true  # Data-driven per-order column (variable) rescaling for the parameterized HC
	# solve. ON by default (validated: regression 446/446 unchanged, no recovery regression on the 9-system
	# benchmark; see docs/2026-05-27_column_scaling_and_backsolve_resolve.md). Rescales each unknown x = s.*x̂ using per-derivative-order observable-derivative
	# magnitudes (order-0 vars left at 1.0), solves the rescaled system (Newton polytopes / mixed volume unchanged),
	# and unscales solutions by s. Benign (~identity) when observable-derivative magnitudes are ~O(1). Tames the
	# ~1e7 jet-coordinate dynamic range that defeats unscaled polyhedral tracking on stiff/transient systems.
	hc_real_tol::Float64 = 1e-9
	# Per-analysis HC solver config, carried to _hc_solve via the scoped
	# RunContext (run_context.jl). The module Refs HC_SOLVE_THREADING /
	# HC_COMPILE_MODE remain the manual/global escape hatch when no context
	# is bound (bare solver calls outside analyze_*).
	hc_threading::Bool = true
	hc_compile_mode::Symbol = :all  # :all | :none | :mixed (HC compile policy)
	hc_show_progress::Bool = false
	# Multi-shot parameter-transition tracking mode (points i>1). :gamma_straight tracks
	# F(·;p_start)→F(·;p_target) via HC.jl's fixed-system StraightLineHomotopy WITH the γ-trick
	# (H = γ·t·F(·;p_start) + (1−t)·F(·;p_target)) — a discriminant-avoiding path that lands EXACTLY at
	# the real target; robust where the old straight parameter path collapses (receptor: truth+swap
	# 10/10 vs 4/16). :parameter = HC.jl ParameterHomotopy (old straight real parameter path, no γ — for
	# A/B + escape). :gamma_straight_fallback = :parameter first, then γ-straight instead of a fresh
	# solve on path loss (strictly dominates :parameter). :generic_start (NOW DEFAULT, aggressive quoll build) seeds from a
	# generic COMPLEX parameter point p0 (off the discriminant ⇒ full generic root count N, well-conditioned)
	# then fans out by tracking p0→each real point — robust to a deficient point-1 solve, and makes the count
	# target the true N (fixing the initial_solution_count anchor). Falls back to per-point fresh+γ chain.
	homotopy_tracking_mode::Symbol = :generic_start  # DEFAULT flipped gamma_straight→generic_start for the aggressive quoll build; generic solve is hoisted to run ONCE over all interpolators (single-point + multipoint)
	gamma_max_seeds::Int = 5  # γ-straight: try up to this many random γ seeds, keep the most-complete result
	gamma_seed::Int = 0       # γ RNG seed: 0 ⇒ deterministic per-problem auto-seed (reproducible); >0 ⇒ that exact seed; <0 ⇒ entropy

	# Multi-point template (combines polynomial systems from N time points)
	use_multipoint::Bool = true   # Enable multi-point polynomial template system
	multipoint_n_points::Int = 2  # Number of time points per evaluation (2 recommended)
	multipoint_max_pairs::Int = 20  # Maximum number of time point pairs to solve

	# StructuralIdentifiability Parameters
	si_probability::Float64 = 0.99
	si_infolevel::Int = 0

	# File I/O
	log_dir::String = "logs"
	save_filepath::String = ""
end

# Single source of truth for option-bridge fallbacks: internal solver paths that
# receive a plain options Dict must default missing keys to THESE struct
# defaults, never to hardcoded literals (which silently drift — the 2026-07
# review found `use_column_scaling` falling back to false and
# `homotopy_tracking_mode` to :gamma_straight while the struct defaults are
# true / :generic_start). Constructed once at load; read-only.
const _OPT_STRUCT_DEFAULTS = EstimationOptions()

"""
	get_solver_function(method::SystemSolverMethod) -> Function

Convert SystemSolverMethod enum to actual solver function.
"""
function get_solver_function(method::SystemSolverMethod)
	if method == SolverRS
		# Check if RS extension is loaded
		if !isdefined(@__MODULE__, :solve_with_rs)
			error("RS solver requested but RS extension is not loaded. Install RS and RationalUnivariateRepresentation packages to use this solver.")
		end
		return solve_with_rs
	elseif method == SolverHC
		return solve_with_hc
	elseif method == SolverNLOpt
		return solve_with_nlopt
	elseif method == SolverFastNLOpt
		return solve_with_fast_nlopt
	elseif method == SolverRobust
		return solve_with_robust
	else
		error("Unknown solver method: $method")
	end
end

"""
	get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function}=nothing; s3_adapt_k=10.0) -> Function

Convert InterpolatorMethod enum to actual interpolator function.
The `s3_adapt_k` keyword controls the noise multiplier for S3 adaptive-tolerance methods.
"""
function get_interpolator_function(method::InterpolatorMethod, custom::Union{Nothing, Function} = nothing;
                                   s3_adapt_k::Float64 = 10.0)
	if method == InterpolatorCustom
		if isnothing(custom)
			error("InterpolatorCustom selected but no custom_interpolator provided")
		end
		return custom
	end
	# If a custom override was provided (e.g., from GP caching layer), use it
	if custom !== nothing
		return custom
	end
	if method == InterpolatorAAAD
		return aaad
	elseif method == InterpolatorAAADGPR
		return aaad_gpr_pivot
	elseif method == InterpolatorAAADOld
		return aaad_old_reliable
	elseif method == InterpolatorFHD
		return fhdn(5)  # Default to degree 5 FHD
	elseif method == InterpolatorAGPUQ
		return agp_gpr_uq
	elseif method == InterpolatorAGPRobust
		return agp_gpr_robust
	elseif method == InterpolatorAGPRobustRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:rq)
	elseif method == InterpolatorAGPRobustSEpRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:se_plus_rq)
	elseif method == InterpolatorAGPRobustSExRQ
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:se_times_rq)
	elseif method == InterpolatorAGPRobustMatern52
		return (xs, ys) -> agp_gpr_robust(xs, ys; kernel_type=:matern52)
	elseif method == InterpolatorS2AAAMLE
		return s2_aaa_mle_interpolator
	# --- S3 Adaptive tolerance ---
	elseif method == InterpolatorS3AdaptSE
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptSEpRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_plus_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptSExRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_times_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3AdaptMatern52
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_matern52_interpolator(xs, ys; k = k)
	# --- S3 BIC model selection ---
	elseif method == InterpolatorS3BICSE
		return s3_bic_se_interpolator
	elseif method == InterpolatorS3BICRQ
		return s3_bic_rq_interpolator
	elseif method == InterpolatorS3BICSEpRQ
		return s3_bic_se_plus_rq_interpolator
	elseif method == InterpolatorS3BICSExRQ
		return s3_bic_se_times_rq_interpolator
	elseif method == InterpolatorS3BICMatern52
		return s3_bic_matern52_interpolator
	# --- Old S3 names (deprecated, forward to adaptive) ---
	elseif method == InterpolatorS3SE
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3RQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3SEpRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_plus_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3SExRQ
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_se_times_rq_interpolator(xs, ys; k = k)
	elseif method == InterpolatorS3Matern52
		k = s3_adapt_k
		return (xs, ys) -> s3_adapt_matern52_interpolator(xs, ys; k = k)
	elseif method == InterpolatorChebyshevAICc
		return chebyshev_aicc
	elseif method == InterpolatorChebyshevBIC
		return chebyshev_bic
	elseif method == InterpolatorFourierAdaptive
		return fourier_adaptive
	else
		error("Unknown interpolator method: $method")
	end
end

"""
	interpolator_method_to_symbol(method::InterpolatorMethod) -> Symbol

Convert an InterpolatorMethod enum value to a Symbol for tagging results.
"""
function interpolator_method_to_symbol(method::InterpolatorMethod)
	method == InterpolatorAAAD && return :aaad
	method == InterpolatorAAADGPR && return :aaad_gpr
	method == InterpolatorAAADOld && return :aaad_old
	method == InterpolatorFHD && return :fhd
	method == InterpolatorAGPUQ && return :agp_uq
	method == InterpolatorAGPRobust && return :agp_robust
	method == InterpolatorAGPRobustRQ && return :agp_robust_rq
	method == InterpolatorAGPRobustSEpRQ && return :agp_robust_se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :agp_robust_se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :agp_robust_matern52
	method == InterpolatorS2AAAMLE && return :s2_aaa_mle
	method == InterpolatorS3SE && return :s3_se
	method == InterpolatorS3RQ && return :s3_rq
	method == InterpolatorS3SEpRQ && return :s3_se_plus_rq
	method == InterpolatorS3SExRQ && return :s3_se_times_rq
	method == InterpolatorS3Matern52 && return :s3_matern52
	method == InterpolatorS3AdaptSE && return :s3_adapt_se
	method == InterpolatorS3AdaptRQ && return :s3_adapt_rq
	method == InterpolatorS3AdaptSEpRQ && return :s3_adapt_se_plus_rq
	method == InterpolatorS3AdaptSExRQ && return :s3_adapt_se_times_rq
	method == InterpolatorS3AdaptMatern52 && return :s3_adapt_matern52
	method == InterpolatorS3BICSE && return :s3_bic_se
	method == InterpolatorS3BICRQ && return :s3_bic_rq
	method == InterpolatorS3BICSEpRQ && return :s3_bic_se_plus_rq
	method == InterpolatorS3BICSExRQ && return :s3_bic_se_times_rq
	method == InterpolatorS3BICMatern52 && return :s3_bic_matern52
	method == InterpolatorChebyshevAICc && return :chebyshev_aicc
	method == InterpolatorChebyshevBIC && return :chebyshev_bic
	method == InterpolatorFourierAdaptive && return :fourier_adaptive
	method == InterpolatorCustom && return :custom
	return :unknown
end

"""
	is_gp_interpolator(method::InterpolatorMethod) -> Bool

Returns true if the interpolator method is a GP-based method that supports S3 refinement.
"""
function is_gp_interpolator(method::InterpolatorMethod)::Bool
	return method in (InterpolatorAGPRobust, InterpolatorAGPRobustRQ,
	                  InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ,
	                  InterpolatorAGPRobustMatern52,
	                  InterpolatorAGPUQ)
end

"""
	is_matern_interpolator(method::InterpolatorMethod) -> Bool

Returns true if the interpolator is Matérn-5/2, which is only C² smooth and
cannot produce valid 3rd+ order derivatives from raw GP output.
"""
function is_matern_interpolator(method::InterpolatorMethod)::Bool
	return method in (InterpolatorAGPRobustMatern52,
	                  InterpolatorS3Matern52, InterpolatorS3AdaptMatern52, InterpolatorS3BICMatern52)
end

"""
	s3_symbol(method::InterpolatorMethod) -> Symbol

Map a GP interpolator method to its S3 companion tag symbol.
"""
function s3_symbol(method::InterpolatorMethod)::Symbol
	method == InterpolatorAGPRobust && return :s3_adapt_se
	method == InterpolatorAGPRobustRQ && return :s3_adapt_rq
	method == InterpolatorAGPRobustSEpRQ && return :s3_adapt_se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :s3_adapt_se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :s3_adapt_matern52
	return :s3_unknown
end

"""
	resolve_interpolator_list(opts::EstimationOptions) -> Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}}

Resolve the list of interpolators to run. If `opts.interpolators` is empty, falls back to
the single `opts.interpolator` field for backward compatibility.

Returns a vector of `(method, custom_func_or_nothing)` tuples.
"""
function resolve_interpolator_list(opts::EstimationOptions)
	if isempty(opts.interpolators)
		result = Tuple{InterpolatorMethod, Union{Nothing, Function}}[(opts.interpolator, opts.custom_interpolator)]
	else
		result = Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}}()
		custom_idx = 0
		for method in opts.interpolators
			if method == InterpolatorCustom
				custom_idx += 1
				func = custom_idx <= length(opts.custom_interpolators) ? opts.custom_interpolators[custom_idx] : nothing
				push!(result, (method, func))
			else
				push!(result, (method, nothing))
			end
		end
	end

	# Backward compat: auto-expand GP methods when gp_s3_refinement=true
	if opts.gp_s3_refinement
		@warn "gp_s3_refinement is deprecated. Add InterpolatorS3AdaptSE etc. to your interpolators list directly." maxlog=1
		gp_to_s3 = Dict(
			InterpolatorAGPRobust => InterpolatorS3AdaptSE,
			InterpolatorAGPRobustRQ => InterpolatorS3AdaptRQ,
			InterpolatorAGPRobustSEpRQ => InterpolatorS3AdaptSEpRQ,
			InterpolatorAGPRobustSExRQ => InterpolatorS3AdaptSExRQ,
			InterpolatorAGPRobustMatern52 => InterpolatorS3AdaptMatern52,
		)
		for (m, _) in copy(result)
			haskey(gp_to_s3, m) && push!(result, (gp_to_s3[m], nothing))
		end
	end

	# Inject GP caching for shared kernels
	_inject_gp_caching!(result; s3_adapt_k = opts.s3_adapt_k)

	return result
end

"""
	_apply_noise_filter(list, σ̂) -> Vector

Remove AAA-family interpolators that produce catastrophic derivative errors
above their respective noise thresholds. Logs a `@warn` for each method
dropped. Returns the filtered list (possibly empty — caller is responsible
for fallback).

Thresholds (empirically calibrated on `forced_lotka_volterra_0_1em2`,
2026-05-05):
- `InterpolatorS2AAAMLE`: drop when σ̂ > 1e-4
- `InterpolatorAAAD`, `InterpolatorAAADOld`: drop when σ̂ > 1e-5
"""
function _apply_noise_filter(list::AbstractVector, σ̂::Float64)
	THRESHOLD_S2     = 1e-4
	THRESHOLD_AAAD   = 1e-5
	out = empty(list)
	for entry in list
		method = entry[1]
		if method == InterpolatorS2AAAMLE && σ̂ > THRESHOLD_S2
			@warn "[INTERP-GATE] Skipping S2AAAMLE: σ̂=$σ̂ > threshold $THRESHOLD_S2"
			continue
		end
		if (method == InterpolatorAAAD || method == InterpolatorAAADOld) && σ̂ > THRESHOLD_AAAD
			@warn "[INTERP-GATE] Skipping $method: σ̂=$σ̂ > threshold $THRESHOLD_AAAD"
			continue
		end
		push!(out, entry)
	end
	return out
end

"""
	_gp_kernel_of(method::InterpolatorMethod) -> Union{Nothing, Symbol}

Map any GP-based interpolator method to its kernel type, or `nothing` if not GP-based.
"""
function _gp_kernel_of(method::InterpolatorMethod)::Union{Nothing, Symbol}
	method == InterpolatorAGPRobust && return :se
	method == InterpolatorAGPRobustRQ && return :rq
	method == InterpolatorAGPRobustSEpRQ && return :se_plus_rq
	method == InterpolatorAGPRobustSExRQ && return :se_times_rq
	method == InterpolatorAGPRobustMatern52 && return :matern52
	# Old S3 names
	method == InterpolatorS3SE && return :se
	method == InterpolatorS3RQ && return :rq
	method == InterpolatorS3SEpRQ && return :se_plus_rq
	method == InterpolatorS3SExRQ && return :se_times_rq
	method == InterpolatorS3Matern52 && return :matern52
	# S3 Adaptive
	method == InterpolatorS3AdaptSE && return :se
	method == InterpolatorS3AdaptRQ && return :rq
	method == InterpolatorS3AdaptSEpRQ && return :se_plus_rq
	method == InterpolatorS3AdaptSExRQ && return :se_times_rq
	method == InterpolatorS3AdaptMatern52 && return :matern52
	# S3 BIC
	method == InterpolatorS3BICSE && return :se
	method == InterpolatorS3BICRQ && return :rq
	method == InterpolatorS3BICSEpRQ && return :se_plus_rq
	method == InterpolatorS3BICSExRQ && return :se_times_rq
	method == InterpolatorS3BICMatern52 && return :matern52
	return nothing
end

"""
	_is_s3_method(method::InterpolatorMethod) -> Bool

Returns true if the interpolator method is an S3 composite (GP→AAA→MLE).
"""
function _is_s3_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3SE, InterpolatorS3RQ, InterpolatorS3SEpRQ,
	                  InterpolatorS3SExRQ, InterpolatorS3Matern52,
	                  InterpolatorS3AdaptSE, InterpolatorS3AdaptRQ, InterpolatorS3AdaptSEpRQ,
	                  InterpolatorS3AdaptSExRQ, InterpolatorS3AdaptMatern52,
	                  InterpolatorS3BICSE, InterpolatorS3BICRQ, InterpolatorS3BICSEpRQ,
	                  InterpolatorS3BICSExRQ, InterpolatorS3BICMatern52)
end

"""
	_is_s3_adapt_method(method::InterpolatorMethod) -> Bool

Returns true for S3 adaptive-tolerance methods (including deprecated old S3 names).
"""
function _is_s3_adapt_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3AdaptSE, InterpolatorS3AdaptRQ, InterpolatorS3AdaptSEpRQ,
	                  InterpolatorS3AdaptSExRQ, InterpolatorS3AdaptMatern52,
	                  InterpolatorS3SE, InterpolatorS3RQ, InterpolatorS3SEpRQ,
	                  InterpolatorS3SExRQ, InterpolatorS3Matern52)
end

"""
	_is_s3_bic_method(method::InterpolatorMethod) -> Bool

Returns true for S3 BIC model-selection methods.
"""
function _is_s3_bic_method(method::InterpolatorMethod)::Bool
	return method in (InterpolatorS3BICSE, InterpolatorS3BICRQ, InterpolatorS3BICSEpRQ,
	                  InterpolatorS3BICSExRQ, InterpolatorS3BICMatern52)
end

"""
	_make_cached_gp_func(kernel_type, cache) -> Function

Create a closure that fits a GP and stores it in the shared cache, keyed by `hash(ys)`.
"""
function _make_cached_gp_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return function(xs, ys)
		key = hash(ys)
		gp = agp_gpr_robust(Vector{Float64}(xs), Vector{Float64}(ys); kernel_type = kernel_type)
		cache[key] = gp
		return gp
	end
end

"""
	_make_cached_s3_func(kernel_type, cache) -> Function

Create a closure that reuses a cached GP (if available) for S3 refinement.
On cache miss, fits the GP internally.
DEPRECATED: use `_make_cached_s3_adapt_func` instead.
"""
function _make_cached_s3_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return _make_cached_s3_adapt_func(kernel_type, cache)
end

"""
	_make_cached_s3_adapt_func(kernel_type, cache; k=10.0) -> Function

Create a closure that reuses a cached GP for S3 adaptive-tolerance refinement.
"""
function _make_cached_s3_adapt_func(kernel_type::Symbol, cache::Dict{UInt64, Any}; k::Float64 = 10.0)
	return function(xs, ys)
		key = hash(ys)
		t_vec = Vector{Float64}(xs)
		y_vec = Vector{Float64}(ys)
		gp = get(cache, key, nothing)
		if gp === nothing
			gp = agp_gpr_robust(t_vec, y_vec; kernel_type = kernel_type)
		end
		return s3_refine_gp_adaptive(gp, t_vec, y_vec; k = k)
	end
end

"""
	_make_cached_s3_bic_func(kernel_type, cache) -> Function

Create a closure that reuses a cached GP for S3 BIC model-selection refinement.
"""
function _make_cached_s3_bic_func(kernel_type::Symbol, cache::Dict{UInt64, Any})
	return function(xs, ys)
		key = hash(ys)
		t_vec = Vector{Float64}(xs)
		y_vec = Vector{Float64}(ys)
		gp = get(cache, key, nothing)
		if gp === nothing
			gp = agp_gpr_robust(t_vec, y_vec; kernel_type = kernel_type)
		end
		return s3_refine_gp_bic(gp, t_vec, y_vec)
	end
end

"""
	_inject_gp_caching!(interpolator_list; s3_adapt_k=10.0)

For interpolator methods that share a GP kernel (e.g., AGPRobust + S3SE both use SE),
inject closure-wrapped functions that share a `Dict` cache so the GP is fitted only once.
"""
function _inject_gp_caching!(interpolator_list::Vector{Tuple{InterpolatorMethod, Union{Nothing, Function}}};
                              s3_adapt_k::Float64 = 10.0)
	# Count how many methods share each GP kernel
	kernel_counts = Dict{Symbol, Int}()
	for (method, _) in interpolator_list
		kt = _gp_kernel_of(method)
		kt !== nothing && (kernel_counts[kt] = get(kernel_counts, kt, 0) + 1)
	end
	shared_kernels = Set(k for (k, c) in kernel_counts if c > 1)
	isempty(shared_kernels) && return

	# Create per-kernel caches
	caches = Dict(k => Dict{UInt64, Any}() for k in shared_kernels)

	# Replace functions for methods that share a kernel
	for i in eachindex(interpolator_list)
		method, custom = interpolator_list[i]
		custom !== nothing && continue  # don't override user-provided functions
		kt = _gp_kernel_of(method)
		kt === nothing && continue
		kt ∉ shared_kernels && continue
		cache = caches[kt]
		if _is_s3_bic_method(method)
			interpolator_list[i] = (method, _make_cached_s3_bic_func(kt, cache))
		elseif _is_s3_method(method)  # covers adapt + old S3
			interpolator_list[i] = (method, _make_cached_s3_adapt_func(kt, cache; k = s3_adapt_k))
		else
			interpolator_list[i] = (method, _make_cached_gp_func(kt, cache))
		end
	end
end

"""
	compute_shooting_indices(n_points, n_total; warp=true, beta=3.0) -> Vector{Int}

Compute shooting point indices across a time vector of length `n_total`.

When `warp=true` and `beta > 0`, uses an exponential warp to cluster more points
near the start of the interval (where transient dynamics are typically richest).
When `warp=false` or `beta ≈ 0`, returns equidistant indices.

Returns a sorted vector of unique indices in `[1, n_total]`.
"""
function compute_shooting_indices(n_points::Int, n_total::Int; warp::Bool = true, beta::Float64 = 3.0)
	n_total <= 0 && return Int[]
	n_total == 1 && return [1]
	n_total == 2 && return [1, 2]
	n_points <= 0 && return [max(1, n_total ÷ 2)]
	n_points == 1 && return [1]
	n_points >= n_total && return collect(1:n_total)

	if !warp || abs(beta) < 1e-10
		# Equidistant
		indices = round.(Int, range(1, n_total, length = n_points))
	else
		u = range(0.0, 1.0, length = n_points)
		frac = (exp.(beta .* u) .- 1) ./ (exp(beta) - 1)
		indices = round.(Int, 1 .+ frac .* (n_total - 1))
		indices = clamp.(indices, 1, n_total)
	end
	return unique(indices)
end

"""
	get_polish_optimizer(method::PolishMethod)

Convert PolishMethod enum to actual optimizer object/type.

For scalar `Optimization.solve`-based methods (legacy default `PolishNewtonTrust`,
plus `PolishLevenberg`/`PolishGaussNewton`/`PolishBFGS`/`PolishLBFGS`) returns a
zero-arg constructor — the call site does `optimizer_type()` to instantiate.

For residual-mode methods (`PolishLSOBoundedLog`, `PolishFastLMBoundedLog`) returns
a tagged tuple `(kind::Symbol, factory)` consumed by `_polish_single_residual`.
The kinds are `:lso_direct` (LeastSquaresOptim) and `:fastlm_direct` (FastLevenbergMarquardt).
"""
function get_polish_optimizer(method::PolishMethod)
	if method == PolishNewtonTrust
		return NewtonTrustRegion
	elseif method == PolishLevenberg
		return LevenbergMarquardt
	elseif method == PolishGaussNewton
		return GaussNewton
	elseif method == PolishBFGS
		return BFGS
	elseif method == PolishLBFGS
		return LBFGS
	elseif method == PolishLSOBoundedLog
		return (:lso_direct, () -> LeastSquaresOptim.LevenbergMarquardt())
	elseif method == PolishFastLMBoundedLog
		return (:fastlm_direct, () -> nothing)
	else
		error("Unknown polish method: $method")
	end
end

"""
	get_ad_backend(backend::Symbol)

Convert AD backend symbol to an Optimization.jl AD type.

# Supported backends
- `:forward` → `AutoForwardDiff()` (default, works with most problems)
- `:enzyme` → `AutoEnzyme()` (compiler-based AD)
- `:finite` → `AutoFiniteDiff()` (fallback, no AD required)

Note: `:zygote` was removed — Zygote segfaults Julia 1.12's JIT compiler.
ForwardDiff is the recommended backend (only one that works through adaptive ODE solvers).
"""
function get_ad_backend(backend::Symbol)
	backend === :forward && return Optimization.AutoForwardDiff()
	# backend === :zygote && return Optimization.AutoZygote()  # Disabled: segfaults Julia 1.12
	backend === :enzyme && return Optimization.AutoEnzyme()
	backend === :finite && return Optimization.AutoFiniteDiff()
	error("Unknown AD backend :$backend. Supported backends: :forward, :enzyme, :finite")
end

"""
	merge_options(base::EstimationOptions; kwargs...) -> EstimationOptions

Create a new EstimationOptions struct by merging keyword arguments with an existing options struct.
This is useful for temporarily overriding specific options.

# Examples
```julia
base_opts = EstimationOptions()
new_opts = merge_options(base_opts; abstol=1e-10, debug_solver=true)
```
"""
function merge_options(base::EstimationOptions; kwargs...)
	# Get all field names and their values from base
	fields = fieldnames(EstimationOptions)
	values = Dict(f => getfield(base, f) for f in fields)

	# Override with any provided kwargs
	for (k, v) in kwargs
		if k in fields
			values[k] = v
		else
			error("Unknown option: $k")
		end
	end

	# Create new struct
	return EstimationOptions(; values...)
end

"""
	validate_options(opts::EstimationOptions) -> Bool

Validate that the options struct has sensible values.
Throws warnings for potentially problematic configurations.

# Returns
- `true` if options are valid
- `false` if there are critical issues
"""
function validate_options(opts::EstimationOptions)
	valid = true

	# Check algorithm selections that otherwise fail only after expensive setup.
	if !(opts.opt_ad_backend in (:forward, :enzyme, :finite))
		@error "opt_ad_backend must be :forward, :enzyme, or :finite (got $(opts.opt_ad_backend))"
		valid = false
	end

	if !(opts.hc_compile_mode in (:all, :none, :mixed))
		@error "hc_compile_mode must be :all, :none, or :mixed (got $(opts.hc_compile_mode))"
		valid = false
	end

	if isempty(opts.interpolators)
		if opts.interpolator == InterpolatorCustom && isnothing(opts.custom_interpolator)
			@error "InterpolatorCustom requires custom_interpolator when interpolators is empty"
			valid = false
		end
	else
		required_custom = count(==(InterpolatorCustom), opts.interpolators)
		if length(opts.custom_interpolators) < required_custom
			@error "interpolators contains $required_custom InterpolatorCustom entr$(required_custom == 1 ? "y" : "ies"), but only $(length(opts.custom_interpolators)) custom_interpolators function(s) were provided"
			valid = false
		end
	end

	# Check tolerances
	if opts.abstol <= 0 || opts.reltol <= 0
		@error "Tolerances must be positive"
		valid = false
	end

	if opts.abstol < 1e-16 || opts.reltol < 1e-16
		@warn "Extremely small tolerances may cause numerical issues"
	end

	# Check thresholds
	if opts.imag_threshold < 0 || opts.clustering_threshold < 0
		@error "Thresholds must be non-negative"
		valid = false
	end

	if opts.shooting_points < 0
		@error "shooting_points must be non-negative"
		valid = false
	end

	# Check point_hint
	if opts.point_hint < 0 || opts.point_hint > 1
		@error "point_hint must be in [0, 1]"
		valid = false
	end

	# Check derivative level
	if opts.max_deriv_level < 2
		@error "max_deriv_level must be at least 2"
		valid = false
	end

	if opts.max_deriv_level > 20
		@warn "Very high derivative levels (>20) may cause numerical instability"
	end

	# Check optimization bounds
	if !isnothing(opts.opt_lb) && !isnothing(opts.opt_ub)
		if length(opts.opt_lb) != length(opts.opt_ub)
			@error "Optimization bounds must have the same length"
			valid = false
		end
		if any(opts.opt_lb .> opts.opt_ub)
			@error "Lower bounds must not exceed upper bounds"
			valid = false
		end
	end

	# Check polish safeguard parameters
	if opts.polish_maxtime <= 0
		@warn "polish_maxtime must be positive; using default (3600s)"
	end
	if opts.polish_stagnation_window < 5
		@warn "polish_stagnation_window < 5 is too aggressive; may stop prematurely"
	end
	if opts.polish_max_concurrency < 1
		@warn "polish_max_concurrency must be ≥ 1 (got $(opts.polish_max_concurrency)); will treat as 1"
	end

	# Polish coordinate transform policy
	if !(opts.polish_coordinate_policy in (:auto, :linear, :log_only, :shifted_log_only))
		@error "polish_coordinate_policy must be one of :auto, :linear, :log_only, :shifted_log_only (got $(opts.polish_coordinate_policy))"
		valid = false
	end

	# Polish regularization
	if opts.polish_regularization_lambda < 0
		@error "polish_regularization_lambda must be non-negative (got $(opts.polish_regularization_lambda))"
		valid = false
	end

	# Polish soft-wall
	if opts.polish_softwall_lambda < 0
		@error "polish_softwall_lambda must be non-negative (got $(opts.polish_softwall_lambda))"
		valid = false
	end
	if !(0.0 <= opts.polish_softwall_epsilon < 0.5)
		@error "polish_softwall_epsilon must be in [0, 0.5) (got $(opts.polish_softwall_epsilon))"
		valid = false
	end

	# LSO trust-region delta must be positive
	if opts.polish_lso_delta <= 0
		@error "polish_lso_delta must be positive (got $(opts.polish_lso_delta))"
		valid = false
	end

	# SHADE+LM baseline knobs
	if opts.shade_total_max_evals <= 0
		@error "shade_total_max_evals must be positive (got $(opts.shade_total_max_evals))"
		valid = false
	end
	if opts.shade_total_max_time <= 0
		@error "shade_total_max_time must be positive (got $(opts.shade_total_max_time))"
		valid = false
	end
	if !(0.0 < opts.shade_global_eval_fraction < 1.0)
		@error "shade_global_eval_fraction must be in (0, 1) (got $(opts.shade_global_eval_fraction))"
		valid = false
	end
	if opts.shade_n_local_starts <= 0
		@error "shade_n_local_starts must be positive (got $(opts.shade_n_local_starts))"
		valid = false
	end
	if opts.shade_population < 0
		@error "shade_population must be non-negative (0 = auto) (got $(opts.shade_population))"
		valid = false
	end

	# Sensitivity-seed parameters
	if opts.sensitivity_seed_probe_scale <= 0
		@error "sensitivity_seed_probe_scale must be positive (got $(opts.sensitivity_seed_probe_scale))"
		valid = false
	end
	if opts.sensitivity_seed_eigenvalue_threshold < 0 || opts.sensitivity_seed_eigenvalue_threshold > 1
		@error "sensitivity_seed_eigenvalue_threshold must be in [0, 1] (got $(opts.sensitivity_seed_eigenvalue_threshold))"
		valid = false
	end
	if opts.sensitivity_sigma_d_kappa < 1.0
		@warn "sensitivity_sigma_d_kappa < 1.0 implies higher derivatives are MORE certain than lower (got $(opts.sensitivity_sigma_d_kappa))"
	end
	if !(opts.terminal_fallback in (:none, :direct_opt))
		@error "terminal_fallback must be :none or :direct_opt"
		valid = false
	end
	if !(opts.rank_strategy in (:sat_neg1_err, :sat_err, :err_only, :lognorm_err, :lognorm_neg1_err))
		@error "rank_strategy must be one of :sat_neg1_err, :sat_err, :err_only, :lognorm_err, :lognorm_neg1_err (got $(opts.rank_strategy))"
		valid = false
	end
	if !(opts.cluster_method in (:identifiable_subspace, :bit_identical))
		@error "cluster_method must be :identifiable_subspace or :bit_identical (got $(opts.cluster_method))"
		valid = false
	end
	if !(opts.homotopy_tracking_mode in (:parameter, :gamma_straight, :gamma_straight_fallback, :generic_start))
		@error "homotopy_tracking_mode must be :parameter, :gamma_straight, :gamma_straight_fallback, or :generic_start (got $(opts.homotopy_tracking_mode))"
		valid = false
	end
	if opts.gamma_max_seeds < 1
		@error "gamma_max_seeds must be ≥ 1 (got $(opts.gamma_max_seeds))"
		valid = false
	end
	if !isnothing(opts.algebraic_multiplicity) && opts.algebraic_multiplicity <= 0
		@error "algebraic_multiplicity must be a positive integer or `nothing` (got $(opts.algebraic_multiplicity))"
		valid = false
	end
	if opts.rough_cluster_eps <= 0
		@error "rough_cluster_eps must be positive (got $(opts.rough_cluster_eps))"
		valid = false
	end
	if opts.subspace_cluster_eps <= 0
		@error "subspace_cluster_eps must be positive (got $(opts.subspace_cluster_eps))"
		valid = false
	end
	if opts.branch_diversity_eps < 0
		@error "branch_diversity_eps must be non-negative (got $(opts.branch_diversity_eps))"
		valid = false
	end
	if opts.branch_completion_max_anchors <= 0
		@error "branch_completion_max_anchors must be positive (got $(opts.branch_completion_max_anchors))"
		valid = false
	end
	if opts.branch_completion_residual_tol < 0
		@error "branch_completion_residual_tol must be non-negative (got $(opts.branch_completion_residual_tol))"
		valid = false
	end
	if !(opts.backsolve_recovery in (:none, :algebraic_resolve))
		@error "backsolve_recovery must be :none or :algebraic_resolve"
		valid = false
	end
	if !(opts.t0_state_completion in (:strict, :seed_for_polish))
		@error "t0_state_completion must be :strict or :seed_for_polish"
		valid = false
	end

	# Check data parameters
	if opts.datasize < 3
		@warn "Very small datasize (<3) may lead to underdetermined systems"
	end

	if length(opts.time_interval) != 2 || opts.time_interval[1] >= opts.time_interval[2]
		@error "time_interval must be [t_start, t_end] with t_start < t_end"
		valid = false
	end

	if opts.noise_level < 0
		@error "noise_level must be non-negative"
		valid = false
	end
	if !(opts.noise_model in (:relative, :multiplicative, :additive, :homoskedastic, :additive_homoskedastic, :none))
		@error "noise_model must be :relative, :multiplicative, :additive, :homoskedastic, :additive_homoskedastic, or :none"
		valid = false
	end

	# Check SI parameters
	if opts.si_probability <= 0 || opts.si_probability > 1
		@error "si_probability must be in (0, 1]"
		valid = false
	end

	# Warn about conflicting options
	if opts.polish_only && !opts.polish_solutions
		@warn "polish_only=true but polish_solutions=false; no polishing will occur"
	end

	if opts.nooutput && opts.diagnostics
		@info "diagnostics=true but nooutput=true; diagnostic output will be suppressed"
	end

	if opts.terminal_fallback != :none && opts.flow == FlowDirectOpt
		@warn "terminal_fallback is ignored when flow=FlowDirectOpt (FlowDirectOpt already is the terminal optimizer)"
	end

	if opts.backsolve_recovery != :none && opts.flow != FlowStandard
		@info "backsolve_recovery is ignored outside FlowStandard"
	end

	if opts.t0_state_completion != :strict && opts.flow != FlowStandard
		@info "t0_state_completion is ignored outside FlowStandard"
	end

	if opts.t0_state_completion == :seed_for_polish && !opts.polish_solutions
		@warn "t0_state_completion=:seed_for_polish requires polish_solutions=true to be useful"
	end

	if !(opts.system_construction_policy in (:legacy, :noise_frontier))
		@error "system_construction_policy must be :legacy or :noise_frontier (got $(opts.system_construction_policy))"
		valid = false
	end
	if opts.construction_candidate_limit <= 0
		@error "construction_candidate_limit must be positive (got $(opts.construction_candidate_limit))"
		valid = false
	end
	if opts.construction_beam_width <= 0
		@error "construction_beam_width must be positive (got $(opts.construction_beam_width))"
		valid = false
	end

	if !(opts.uq_failure_policy in (:return_failed, :throw))
		@error "uq_failure_policy must be :return_failed or :throw"
		valid = false
	end

	invalid_placeholder_categories = [cat for cat in opts.si_placeholder_fail_categories if !(cat in SI_PLACEHOLDER_VALID_CATEGORIES)]
	if !isempty(invalid_placeholder_categories)
		@error "Unknown si_placeholder_fail_categories: $(invalid_placeholder_categories)"
		valid = false
	end

	if opts.ideal && opts.noise_level > 0
		@warn "ideal=true but noise_level > 0; these options may conflict"
	end

	return valid
end

"""
	print_options(io::IO, opts::EstimationOptions; compact=false)

Pretty-print the options struct.

# Arguments
- `io::IO`: Output stream
- `opts::EstimationOptions`: Options to print
- `compact::Bool`: If true, only print non-default values
"""
function print_options(io::IO, opts::EstimationOptions; compact = false)
	defaults = EstimationOptions()

	println(io, "EstimationOptions:")

	categories = [
		("Solver and Algorithm", [:system_solver, :ode_solver, :interpolator, :interpolators]),
		("Tolerances", [:abstol, :reltol, :rtol, :output_precision]),
		("Solution Validation", [:imag_threshold, :clustering_threshold]),
		("Multi-shot", [:shooting_points, :shooting_warp, :shooting_warp_beta, :point_hint]),
		("Derivatives and Reconstruction", [:max_deriv_level]),
		("Optimization", [:polish_solutions, :polish_solver_solutions, :polish_method, :polish_maxiters, :opt_maxiters,
			:opt_lb, :opt_ub, :opt_ad_backend, :polish_maxtime, :polish_divergence_factor, :polish_stagnation_window, :polish_ode_maxiters]),
		("SHADE+LM Baseline", [:shade_total_max_evals, :shade_total_max_time, :shade_global_eval_fraction,
			:shade_n_local_starts, :shade_population, :shade_seed]),
		("Rescue Policy", [:terminal_fallback, :backsolve_recovery, :t0_state_completion]),
		("Data Sampling", [:datasize, :time_interval, :noise_level, :uneven_sampling,
			:uneven_sampling_times]),
		("Debug Flags", [:nooutput, :diagnostics, :debug_solver, :debug_cas_diagnostics,
			:debug_dimensional_analysis, :trap_debug, :profile_phases]),
		("Feature Flags", [:flow, :use_si_template, :save_system,
			:display_system, :polish_only, :ideal, :compute_uncertainty, :uq_failure_policy, :si_placeholder_fail_categories, :auto_handle_transcendentals, :gp_s3_refinement]),
		("System Construction", [:system_construction_policy, :construction_candidate_limit,
			:construction_beam_width, :construction_compute_mixed_volume]),
		("HomotopyContinuation", [:use_monodromy, :use_parameter_homotopy, :hc_real_tol, :hc_show_progress, :homotopy_tracking_mode, :gamma_max_seeds, :gamma_seed, :use_multipoint, :multipoint_n_points, :multipoint_max_pairs]),
		("StructuralIdentifiability", [:si_probability, :si_infolevel]),
		("File I/O", [:log_dir, :save_filepath]),
	]

	for (category, fields) in categories
		printed_header = false
		for field in fields
			val = getfield(opts, field)
			default_val = getfield(defaults, field)

			if !compact || val != default_val
				if !printed_header
					println(io, "\n  $category:")
					printed_header = true
				end

				# Special formatting for functions
				if isa(val, Function)
					val_str = string(val)
				else
					val_str = repr(val)
				end

				if compact && val != default_val
					println(io, "    $field: $val_str (default: $(repr(default_val)))")
				else
					println(io, "    $field: $val_str")
				end
			end
		end
	end
end

# Define show method for pretty printing
Base.show(io::IO, opts::EstimationOptions) = print_options(io, opts; compact = true)

# get_solver_options_dict (the legacy options::Dict bridge) was removed 2026-06-10:
# exported but had zero callers anywhere (src/, test/, PEB). The fields it forwarded
# (:display_system, :polish_only, :use_monodromy, :save_filepath, :output_precision)
# are wave-2 cleanup candidates — no solver consumes those Dict keys.
