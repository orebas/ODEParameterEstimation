using OrderedCollections
using Symbolics
using OrdinaryDiffEq
using SciMLBase

"""
    OrderedODESystem

Struct representing an ODESystem with ordered parameters and states.

# Fields
- `system::ModelingToolkit.AbstractSystem`: ModelingToolkit ODESystem
- `original_parameters::Vector{Num}`: Vector of original parameters in specific order
- `original_states::Vector{Num}`: Vector of original state variables in specific order
"""
struct OrderedODESystem
    system::ModelingToolkit.AbstractSystem
    original_parameters::Vector{Num}
    original_states::Vector{Num}
end

#function remake(pep::OrderedODESystem; p=nothing, u0=nothing)
#    sys = pep.system
#    if !isnothing(p)
#        sys = remake(sys, p=p)
#    end
#    if !isnothing(u0)
#        sys = remake(sys, u0=u0)
#    end
#    return OrderedODESystem(sys, pep.original_parameters, pep.original_states)
#end

"""
    ParameterEstimationProblem

Struct representing a parameter estimation problem.

# Fields
- `name::String`: Name of the estimation problem
- `model::OrderedODESystem`: Model system with equations
- `measured_quantities::Vector{Equation}`: Equations defining measured quantities
- `data_sample::Union{Nothing, OrderedDict{Union{String, Num}, Vector{Float64}}}`: Measured data or nothing
- `recommended_time_interval::Union{Nothing, Vector{Float64}}`: [start_time, end_time] or nothing for default
- `solver::OrdinaryDiffEq.AbstractODEAlgorithm`: ODE solver to use
- `p_true::OrderedDict{Num, Float64}`: True parameter values if known
- `ic::OrderedDict{Num, Float64}`: Initial conditions for states
- `unident_count::Int`: Number of unidentifiable parameters
"""
struct ParameterEstimationProblem
    name::String
    model::OrderedODESystem
    measured_quantities::Vector{ModelingToolkit.Equation}
    data_sample::Union{Nothing, OrderedDict{Union{String, Num}, Vector{Float64}}}
    recommended_time_interval::Union{Nothing, Vector{Float64}}
    solver::Any  # Use Any for now since the exact type hierarchy can be complex
    p_true::OrderedDict{Symbolics.Num, Float64}
    ic::OrderedDict{Symbolics.Num, Float64}
    unident_count::Int
end

# Constants for analysis and clustering
const CLUSTERING_THRESHOLD = 0.00001  # 0.001% relative difference threshold
const MAX_ERROR_THRESHOLD = 0.5       # Maximum acceptable error
const IMAG_THRESHOLD = 1e-8           # Threshold for ignoring imaginary components
const MAX_SOLUTIONS = 20              # Maximum number of solutions to consider if no good ones found
const DEFAULT_BOUND_MULTIPLIER = 1e9  # Multiplier for data scale to compute default optimization bounds

"""
    NumericalIdentifiabilityAdvisory

Structured best-effort numerical identifiability diagnostics.

# Fields
- `status::Symbol`: `:available`, `:failed`, or `:unavailable`
- `recommended_num_points::Union{Nothing, Int}`: Recommended point count heuristic
- `recommended_deriv_level::Dict{Int, Int}`: Recommended derivative depth by observable index
- `flagged_variables::Set{Num}`: Variables flagged as numerically fragile at the probe point
- `notes::Vector{Symbol}`: Advisory notes such as `:heuristic_fallback`
- `failure_reason::Union{Nothing, String}`: Best-effort failure summary when advisory analysis failed
"""
struct NumericalIdentifiabilityAdvisory
    status::Symbol
    recommended_num_points::Union{Nothing, Int}
    recommended_deriv_level::Dict{Int, Int}
    flagged_variables::Set{Num}
    notes::Vector{Symbol}
    failure_reason::Union{Nothing, String}
end

function NumericalIdentifiabilityAdvisory(;
    status::Symbol = :unavailable,
    recommended_num_points::Union{Nothing, Integer} = nothing,
    recommended_deriv_level = Dict{Int, Int}(),
    flagged_variables = Set{Num}(),
    notes = Symbol[],
    failure_reason::Union{Nothing, AbstractString} = nothing,
)
    return NumericalIdentifiabilityAdvisory(
        status,
        isnothing(recommended_num_points) ? nothing : Int(recommended_num_points),
        Dict{Int, Int}(Int(k) => Int(v) for (k, v) in pairs(recommended_deriv_level)),
        Set{Num}(flagged_variables),
        Symbol[notes...],
        isnothing(failure_reason) ? nothing : String(failure_reason),
    )
end

"""
    ResultProvenance

Structured lineage metadata for a parameter-estimation result.

# Fields
- `primary_method::Symbol`: `:algebraic` or `:direct_opt`
- `interpolator_source::Union{Nothing, Symbol}`: Which interpolator produced the candidate
- `rescue_path::Symbol`: `:none`, `:algebraic_resolve_t0`, `:algebraic_resolve_seeded`, `:direct_opt_fallback`
- `source_shooting_index::Union{Nothing, Int}`: Shooting-point index that produced the candidate
- `source_candidate_index::Union{Nothing, Int}`: Stable candidate index within the producing phase
- `pre_polish_error::Union{Nothing, Float64}`: Error before polishing, when applicable
- `post_polish_error::Union{Nothing, Float64}`: Error after polishing, when applicable
- `polish_applied::Bool`: Whether a polishing stage was applied
- `representative_assignments::OrderedDict{Num, Float64}`: Values assigned only because variables were already known structurally unidentifiable
- `structural_fix_set::OrderedDict{Num, Float64}`: Representative structural fix set derived from SI structural outputs
- `residual_fix_set::OrderedDict{Num, Float64}`: Additional heuristic fix set applied only to repair residual template underdetermination
- `template_status_before_residual_fix::Union{Nothing, Symbol}`: Template dimension status immediately after structural fixing
- `template_status_after_residual_fix::Union{Nothing, Symbol}`: Final template dimension status after any residual template repair
- `equations_dropped_by_rank_trimming::Vector{Int}`: Equation indices removed by rank-based template trimming
- `practical_identifiability_status::Symbol`: Practical/numerical identifiability assessment status for this flow
- `numerical_advisory::Union{Nothing, NumericalIdentifiabilityAdvisory}`: Best-effort advisory numerical diagnostics and heuristic recommendations
- `notes::Vector{Symbol}`: Additional lineage/debug notes
"""
mutable struct ResultProvenance
    primary_method::Symbol
    interpolator_source::Union{Nothing, Symbol}
    rescue_path::Symbol
    source_shooting_index::Union{Nothing, Int}
    source_candidate_index::Union{Nothing, Int}
    pre_polish_error::Union{Nothing, Float64}
    post_polish_error::Union{Nothing, Float64}
    polish_applied::Bool
    representative_assignments::OrderedDict{Num, Float64}
    structural_fix_set::OrderedDict{Num, Float64}
    residual_fix_set::OrderedDict{Num, Float64}
    template_status_before_residual_fix::Union{Nothing, Symbol}
    template_status_after_residual_fix::Union{Nothing, Symbol}
    equations_dropped_by_rank_trimming::Vector{Int}
    practical_identifiability_status::Symbol
    numerical_advisory::Union{Nothing, NumericalIdentifiabilityAdvisory}
    notes::Vector{Symbol}
end

function ResultProvenance(;
    primary_method::Symbol = :algebraic,
    interpolator_source::Union{Nothing, Symbol} = nothing,
    rescue_path::Symbol = :none,
    source_shooting_index::Union{Nothing, Int} = nothing,
    source_candidate_index::Union{Nothing, Int} = nothing,
    pre_polish_error::Union{Nothing, Real} = nothing,
    post_polish_error::Union{Nothing, Real} = nothing,
    polish_applied::Bool = false,
    representative_assignments = OrderedDict{Num, Float64}(),
    structural_fix_set = OrderedDict{Num, Float64}(),
    residual_fix_set = OrderedDict{Num, Float64}(),
    template_status_before_residual_fix::Union{Nothing, Symbol} = nothing,
    template_status_after_residual_fix::Union{Nothing, Symbol} = nothing,
    equations_dropped_by_rank_trimming = Int[],
    practical_identifiability_status::Symbol = :not_assessed,
    numerical_advisory::Union{Nothing, NumericalIdentifiabilityAdvisory} = nothing,
    notes = Symbol[],
)
    return ResultProvenance(
        primary_method,
        interpolator_source,
        rescue_path,
        source_shooting_index,
        source_candidate_index,
        isnothing(pre_polish_error) ? nothing : Float64(pre_polish_error),
        isnothing(post_polish_error) ? nothing : Float64(post_polish_error),
        polish_applied,
        OrderedDict{Num, Float64}(k => Float64(v) for (k, v) in representative_assignments),
        OrderedDict{Num, Float64}(k => Float64(v) for (k, v) in structural_fix_set),
        OrderedDict{Num, Float64}(k => Float64(v) for (k, v) in residual_fix_set),
        template_status_before_residual_fix,
        template_status_after_residual_fix,
        Int[equations_dropped_by_rank_trimming...],
        practical_identifiability_status,
        isnothing(numerical_advisory) ? nothing : deepcopy(numerical_advisory),
        Symbol[notes...],
    )
end

function copy_provenance(
    provenance::ResultProvenance;
    primary_method = provenance.primary_method,
    interpolator_source = provenance.interpolator_source,
    rescue_path = provenance.rescue_path,
    source_shooting_index = provenance.source_shooting_index,
    source_candidate_index = provenance.source_candidate_index,
    pre_polish_error = provenance.pre_polish_error,
    post_polish_error = provenance.post_polish_error,
    polish_applied = provenance.polish_applied,
    representative_assignments = provenance.representative_assignments,
    structural_fix_set = provenance.structural_fix_set,
    residual_fix_set = provenance.residual_fix_set,
    template_status_before_residual_fix = provenance.template_status_before_residual_fix,
    template_status_after_residual_fix = provenance.template_status_after_residual_fix,
    equations_dropped_by_rank_trimming = provenance.equations_dropped_by_rank_trimming,
    practical_identifiability_status = provenance.practical_identifiability_status,
    numerical_advisory = provenance.numerical_advisory,
    notes = provenance.notes,
)
    return ResultProvenance(
        primary_method = primary_method,
        interpolator_source = interpolator_source,
        rescue_path = rescue_path,
        source_shooting_index = source_shooting_index,
        source_candidate_index = source_candidate_index,
        pre_polish_error = pre_polish_error,
        post_polish_error = post_polish_error,
        polish_applied = polish_applied,
        representative_assignments = deepcopy(representative_assignments),
        structural_fix_set = deepcopy(structural_fix_set),
        residual_fix_set = deepcopy(residual_fix_set),
        template_status_before_residual_fix = template_status_before_residual_fix,
        template_status_after_residual_fix = template_status_after_residual_fix,
        equations_dropped_by_rank_trimming = copy(equations_dropped_by_rank_trimming),
        practical_identifiability_status = practical_identifiability_status,
        numerical_advisory = isnothing(numerical_advisory) ? nothing : deepcopy(numerical_advisory),
        notes = copy(notes),
    )
end

"""
    compatibility_return_code(provenance::ResultProvenance) -> Symbol

Map canonical provenance metadata onto the legacy `return_code` compatibility field.
"""
function compatibility_return_code(provenance::ResultProvenance)::Symbol
    provenance.rescue_path != :none && return provenance.rescue_path
    provenance.primary_method == :direct_opt && return :direct_opt
    return :algebraic
end

"""
    sync_result_contract!(result) -> result

Synchronize compatibility fields that are now derived from provenance.
"""
function sync_result_contract!(result)
    result.interpolator_source = result.provenance.interpolator_source
    result.return_code = compatibility_return_code(result.provenance)
    return result
end

"""
    lineage_summary(result) -> String

Compact human-readable summary of result provenance for logs and diagnostics.
"""
function lineage_summary(result)::String
    prov = result.provenance
    parts = String["method=$(prov.primary_method)"]
    prov.rescue_path != :none && push!(parts, "rescue=$(prov.rescue_path)")
    !isnothing(prov.source_shooting_index) && push!(parts, "shoot=$(prov.source_shooting_index)")
    !isnothing(prov.source_candidate_index) && push!(parts, "candidate=$(prov.source_candidate_index)")
    !isnothing(prov.interpolator_source) && push!(parts, "interp=$(prov.interpolator_source)")
    prov.polish_applied && push!(parts, "polished=true")
    !isempty(prov.representative_assignments) && push!(parts, "representative=$(length(prov.representative_assignments))")
    !isempty(prov.structural_fix_set) && push!(parts, "structural_fix=$(length(prov.structural_fix_set))")
    !isempty(prov.residual_fix_set) && push!(parts, "residual_fix=$(length(prov.residual_fix_set))")
    !isnothing(prov.template_status_after_residual_fix) && push!(parts, "template=$(prov.template_status_after_residual_fix)")
    prov.practical_identifiability_status != :not_assessed && push!(parts, "practical=$(prov.practical_identifiability_status)")
    !isnothing(prov.numerical_advisory) && push!(parts, "advisory=$(prov.numerical_advisory.status)")
    return join(parts, ", ")
end

"""
    ParameterEstimationResult

Struct to store the results of parameter estimation.

# Fields
- `parameters::OrderedDict{Num, Float64}`: Estimated parameters
- `states::OrderedDict{Num, Float64}`: Estimated states
- `at_time::Float64`: Time at which estimation is done
- `err::Union{Nothing, Float64}`: Error of estimation
- `return_code::Union{Nothing, Symbol}`: Return code of the estimation process
- `datasize::Int64`: Size of the data used
- `report_time::Union{Nothing, Float64}`: Time at which the result is reported
- `unident_dict::Union{Nothing, OrderedDict{Num, Float64}}`: Dictionary of unidentifiable parameters and their values
- `all_unidentifiable::Set{Num}`: Set of all parameters detected as unidentifiable during analysis
- `solution::Union{Nothing, SciMLBase.AbstractODESolution}`: The ODE solution (optional)
- `interpolator_source::Union{Nothing, Symbol}`: Which interpolator produced this result
- `provenance::ResultProvenance`: Structured lineage/provenance metadata
"""
mutable struct ParameterEstimationResult
    parameters::OrderedDict{Num, Float64}
    states::OrderedDict{Num, Float64}
    at_time::Float64
    err::Union{Nothing, Float64}
    return_code::Union{Nothing, Symbol}
    datasize::Int64
    report_time::Union{Nothing, Float64}
    unident_dict::Union{Nothing, OrderedDict{Num, Float64}}
    all_unidentifiable::Set{Num}
    solution::Union{Nothing, SciMLBase.AbstractODESolution}
    interpolator_source::Union{Nothing, Symbol}   # Which interpolator produced this result
    provenance::ResultProvenance
end

# Backward-compatible constructor (interpolator_source defaults to nothing, provenance to an empty record)
# Note: parameter types are relaxed to allow MTK 11's BasicSymbolicImpl keys
# (Julia's inner struct constructor handles convert() to the declared field types)
function ParameterEstimationResult(
    parameters, states, at_time, err, return_code, datasize,
    report_time, unident_dict, all_unidentifiable, solution,
)
    return ParameterEstimationResult(
        parameters, states, at_time, err, return_code, datasize,
        report_time, unident_dict, all_unidentifiable, solution, nothing, ResultProvenance(),
    )
end

"""
    DerivativeData

Struct to store derivative data of state variable equations and measured quantity equations.
No substitutions are made.
The "cleared" versions are produced from versions of the state equations and measured quantity equations
which have had their denominators cleared, i.e. they should be polynomial and never rational.

# Fields
- `states_lhs_cleared::Vector{Vector{Num}}`: Left-hand side of cleared state equations (indexed by [derivative_order+1])
- `states_rhs_cleared::Vector{Vector{Num}}`: Right-hand side of cleared state equations
- `obs_lhs_cleared::Vector{Vector{Num}}`: Left-hand side of cleared observation equations
- `obs_rhs_cleared::Vector{Vector{Num}}`: Right-hand side of cleared observation equations
- `states_lhs::Vector{Vector{Num}}`: Left-hand side of state equations
- `states_rhs::Vector{Vector{Num}}`: Right-hand side of state equations
- `obs_lhs::Vector{Vector{Num}}`: Left-hand side of observation equations
- `obs_rhs::Vector{Vector{Num}}`: Right-hand side of observation equations
- `all_unidentifiable::Set{Num}`: Set of all unidentifiable parameters
"""
mutable struct DerivativeData
    states_lhs_cleared::Vector{Vector{Num}}
    states_rhs_cleared::Vector{Vector{Num}}
    obs_lhs_cleared::Vector{Vector{Num}}
    obs_rhs_cleared::Vector{Vector{Num}}
    states_lhs::Vector{Vector{Num}}
    states_rhs::Vector{Vector{Num}}
    obs_lhs::Vector{Vector{Num}}
    obs_rhs::Vector{Vector{Num}}
    all_unidentifiable::Set{Num}
end

# ─── Diagnostic types ──────────────────────────────────────────────────

"""
    PerfectInterpolant

Stores Taylor coefficients `c[k+1] = f^(k)(t0) / k!` and evaluates as a
polynomial via Horner's method.  TaylorDiff on this interpolant yields
machine-precision derivatives up to the stored order.
"""
struct PerfectInterpolant
    t0::Float64
    coeffs::Vector{Float64}  # coeffs[k+1] = f^(k)(t0) / k!
end

function (p::PerfectInterpolant)(t)
    dt = t - p.t0
    result = p.coeffs[end]
    for k in (length(p.coeffs) - 1):-1:1
        result = muladd(result, dt, p.coeffs[k])
    end
    return result
end

"""
    DerivativeAccuracyReport

Per-observable, per-order comparison of oracle (Taylor) vs production interpolant derivatives.
"""
struct DerivativeAccuracyReport
    model_name::String
    t_eval::Float64
    max_required_order::Int
    entries::Vector{@NamedTuple{obs::String, order::Int, true_val::Float64, interp_val::Float64, rel_error::Float64}}
    worst_obs::String
    worst_order::Int
    worst_rel_error::Float64
    interpolator_name::String
end

# Backward-compatible 7-arg constructor (interpolator_name defaults to "unknown")
function DerivativeAccuracyReport(name, t_eval, max_order, entries, worst_obs, worst_order, worst_err)
    DerivativeAccuracyReport(name, t_eval, max_order, entries, worst_obs, worst_order, worst_err, "unknown")
end

"""
    PolynomialFeasibilityReport

Compares polynomial-system solution counts and residuals when instantiated
with perfect (oracle) vs production interpolant data.

# Fields
- `equation_strings`: Human-readable string representation of each polynomial equation
- `variable_roles`: Maps variable name → role (:parameter, :state_ic, :state_derivative,
  :data_derivative, :transcendental)
"""
struct PolynomialFeasibilityReport
    model_name::String
    n_equations::Int
    n_variables::Int
    is_square::Bool
    n_solutions_perfect::Int
    n_solutions_production::Int
    true_residual_perfect::Float64
    true_residual_production::Float64
    closest_distance_perfect::Float64
    closest_distance_production::Float64
    variable_names::Vector{String}
    equation_strings::Vector{String}
    variable_roles::Dict{String, Symbol}
end

# Backward-compatible constructor (no equation_strings or variable_roles)
function PolynomialFeasibilityReport(
    model_name, n_equations, n_variables, is_square,
    n_solutions_perfect, n_solutions_production,
    true_residual_perfect, true_residual_production,
    closest_distance_perfect, closest_distance_production,
    variable_names,
)
    return PolynomialFeasibilityReport(
        model_name, n_equations, n_variables, is_square,
        n_solutions_perfect, n_solutions_production,
        true_residual_perfect, true_residual_production,
        closest_distance_perfect, closest_distance_production,
        variable_names, String[], Dict{String, Symbol}(),
    )
end

"""
    SensitivityReport

Jacobian conditioning and root-displacement analysis at the true solution.

# Fields
- `model_name::String`: Name of the model
- `jacobian_cond::Float64`: Condition number of the Jacobian
- `effective_rank::Int`: Numerical rank (SVs above 1e-10 * σ_max)
- `singular_values::Vector{Float64}`: Full singular value spectrum
- `root_sensitivity::Float64`: Root displacement ratio
- `jacobian_matrix::Matrix{Float64}`: Full n_eqs × n_vars Jacobian (rows=equations, cols=variables)
- `jacobian_row_labels::Vector{String}`: Equation labels, length = n_eqs
- `jacobian_col_labels::Vector{String}`: Variable names, length = n_vars
- `jacobian_col_roles::Dict{String, Symbol}`: Variable name → :parameter | :state_ic | etc.
- `data_sensitivity_matrix::Matrix{Float64}`: n_unknowns × n_data sensitivity dx*/dd via IFT
- `data_sensitivity_data_labels::Vector{String}`: Data variable names (columns of S)
- `data_sensitivity_data_roles::Dict{String, Symbol}`: Data var name → role
"""
struct SensitivityReport
    model_name::String
    jacobian_cond::Float64
    effective_rank::Int
    singular_values::Vector{Float64}
    root_sensitivity::Float64
    jacobian_matrix::Matrix{Float64}
    jacobian_row_labels::Vector{String}
    jacobian_col_labels::Vector{String}
    jacobian_col_roles::Dict{String, Symbol}
    data_sensitivity_matrix::Matrix{Float64}
    data_sensitivity_data_labels::Vector{String}
    data_sensitivity_data_roles::Dict{String, Symbol}
    data_sensitivity_unknown_labels::Vector{String}
    data_sensitivity_unknown_roles::Dict{String, Symbol}
end

# 12-arg constructor (Phase 2 callers without unknown labels)
function SensitivityReport(name, cond, rank, svs, sens, jac_mat, row_labels, col_labels, col_roles,
        s_mat, d_labels, d_roles)
    SensitivityReport(name, cond, rank, svs, sens, jac_mat, row_labels, col_labels, col_roles,
        s_mat, d_labels, d_roles, String[], Dict{String, Symbol}())
end

# Backward-compatible 9-arg constructor (Phase 2 callers without data sensitivity)
function SensitivityReport(name, cond, rank, svs, sens, jac_mat, row_labels, col_labels, col_roles)
    SensitivityReport(name, cond, rank, svs, sens, jac_mat, row_labels, col_labels, col_roles,
        Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}())
end

# Backward-compatible 5-arg constructor (legacy callers pass only the first 5 fields)
function SensitivityReport(name, cond, rank, svs, sens)
    SensitivityReport(name, cond, rank, svs, sens,
        Matrix{Float64}(undef, 0, 0), String[], String[], Dict{String, Symbol}(),
        Matrix{Float64}(undef, 0, 0), String[], Dict{String, Symbol}(), String[], Dict{String, Symbol}())
end

"""
    DiagnosticReport

Top-level report aggregating derivative accuracy, polynomial feasibility,
and sensitivity analyses for a single model.
"""
struct DiagnosticReport
    model_name::String
    derivative_accuracy::DerivativeAccuracyReport
    polynomial_feasibility::PolynomialFeasibilityReport
    sensitivity::SensitivityReport
    difficulty::Symbol          # :easy, :moderate, :hard, :infeasible
    bottleneck::String          # human-readable summary
    timestamp::Dates.DateTime
end

"""
    ComprehensiveDiagnosticReport

Extended diagnostic report with multi-point, multi-interpolator derivative
accuracy grid.  `full_reports` holds the full 3-stage reports (best first).

Access the best report via `comp.full_reports[1]` or the `best` property.
"""
struct ComprehensiveDiagnosticReport
    model_name::String
    full_reports::Vector{DiagnosticReport}     # best first; at least one entry
    derivative_grid::Vector{DerivativeAccuracyReport}  # one per (interp, t_eval)
    interpolator_names::Vector{String}
    eval_points::Vector{Float64}
    best_interpolator::String
    best_eval_point::Float64
end

"""Access the best (first) full diagnostic report."""
function Base.getproperty(comp::ComprehensiveDiagnosticReport, name::Symbol)
    if name === :best
        return getfield(comp, :full_reports)[1]
    end
    return getfield(comp, name)
end

"""
    UncertaintyReport

Propagated parameter uncertainty from GP posterior covariance through the
implicit function theorem sensitivity matrix.

Σ_x = S · Σ_d · S' where S = -(∂F/∂x)⁻¹·(∂F/∂d) and Σ_d = GP posterior
covariance at the shooting point.
"""
struct UncertaintyReport
    model_name::String
    t_eval::Float64
    # Per-observable GP posterior at t_eval
    obs_names::Vector{String}
    obs_posterior_mean::Vector{Vector{Float64}}    # [obs_idx][deriv_order+1]
    obs_posterior_std::Vector{Vector{Float64}}     # [obs_idx][deriv_order+1]
    # Block-diagonal data covariance
    data_covariance::Matrix{Float64}              # Σ_d (n_data × n_data)
    data_labels::Vector{String}
    # Parameter covariance from IFT
    param_covariance::Matrix{Float64}             # Σ_x (n_unknowns × n_unknowns)
    param_std::Vector{Float64}                    # √diag(Σ_x)
    param_labels::Vector{String}
    param_roles::Dict{String, Symbol}
    param_true_values::Vector{Float64}
    # Correlation matrix
    correlation_matrix::Matrix{Float64}           # Σ_x normalized to [-1,1]
    # Quality
    max_cv::Float64                               # max coefficient of variation
    status::Symbol                                # :ok, :wide_ci, :degenerate
    warnings::Vector{String}
end

# Backward-compatible constructor (warnings defaults to empty)
function UncertaintyReport(
    model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
    data_covariance, data_labels, param_covariance, param_std, param_labels,
    param_roles, param_true_values, correlation_matrix, max_cv, status,
)
    return UncertaintyReport(
        model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
        data_covariance, data_labels, param_covariance, param_std, param_labels,
        param_roles, param_true_values, correlation_matrix, max_cv, status,
        String[],
    )
end

"""
    EstimationResultsReport

Summary of estimation results for inclusion in diagnostic reports.
Compares estimated parameter/state values against known truth.

# Fields
- `model_name::String`: Name of the model
- `n_results::Int`: Total number of estimation results returned
- `best_error::Float64`: Error of the best (lowest-error) result
- `estimation_time_seconds::Float64`: Wall-clock time for estimation
- `param_comparison`: Per-parameter comparison (name, true, estimated, relative error, CI coverage)
- `state_comparison`: Per-state comparison (name, true, estimated, relative error, CI coverage)
- `best_result::ParameterEstimationResult`: The full best result object
"""
struct EstimationResultsReport
    model_name::String
    n_results::Int
    best_error::Float64
    estimation_time_seconds::Float64
    param_comparison::Vector{@NamedTuple{
        name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool, is_unidentifiable::Bool}}
    state_comparison::Vector{@NamedTuple{
        name::String, true_val::Float64, est_val::Float64,
        rel_error::Float64, within_ci::Bool}}
    best_result::ParameterEstimationResult
end

"""
    BacksolveUQReport

Uncertainty propagation from shooting point through backward ODE integration
to initial conditions at t₀, using the delta method with ForwardDiff Jacobian.

Σ_{s(t₀)} = J_g · Σ_{p, s(t_eval)} · J_g' where J_g = ∂g/∂(p, s(t_eval)).
"""
struct BacksolveUQReport
    t_shoot::Float64
    t0::Float64
    ic_names::Vector{String}
    ic_estimated::Vector{Float64}
    ic_true::Vector{Float64}
    ic_std::Vector{Float64}          # propagated σ at t=0
    ic_ci_covers::Vector{Bool}       # |true - est| < 2σ?
    backsolve_jacobian::Matrix{Float64}  # J_g
    amplification::Float64           # max singular value of J_g
    success::Bool
end
