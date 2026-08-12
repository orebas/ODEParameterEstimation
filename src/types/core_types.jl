using OrderedCollections
using Symbolics
using OrdinaryDiffEq
using SciMLBase

"""
	AbstractInterpolator

Abstract type for interpolation function objects.
All interpolators should be callable with a single argument and return the interpolated value.

Defined here (not in core/derivatives.jl) so the type exists before any file that
annotates with it — `parameter_estimation.jl` (included earlier than derivatives.jl)
references `Dict{Num, AbstractInterpolator}`, which previously survived only by lazy
in-function evaluation.
"""
abstract type AbstractInterpolator end

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
const DEFAULT_BOUND_MULTIPLIER = 1e9  # Multiplier for data scale: blown-backsolve DETECTION threshold (kept wide on purpose)
const DEFAULT_POLISH_BOUND_MULTIPLIER = 1e6  # Narrower multiplier for the no-user-bounds POLISH search box (decoupled from detection; tune toward 1e3 if needed)
const UQ_CI_Z = 1.96                  # Normal 95% quantile — used for BOTH the displayed CI half-width and the coverage check (must stay identical)

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
- `template_status::Union{Nothing, Symbol}`: Template dimension status after structural fixing (2026-08: replaced the vestigial residual_fix_set + before/after status pair — no residual-repair mechanism ever existed, so the pair was identical by construction)
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
    template_status::Union{Nothing, Symbol}
    equations_dropped_by_rank_trimming::Vector{Int}
    practical_identifiability_status::Symbol
    numerical_advisory::Union{Nothing, NumericalIdentifiabilityAdvisory}
    notes::Vector{Symbol}
    # Multipoint provenance (SP/MP origin tracking)
    source_type::Symbol                                    # :single_point | :multipoint | :synthesized_aggregate | :imported | ...
    multipoint_time_indices::Union{Nothing, Vector{Int}}   # time indices in combo, e.g. [376, 1126]
    multipoint_combo_index::Union{Nothing, Int}            # which combo (1-based) produced this solution
    # Synthesized-aggregate provenance (set when source_type == :synthesized_aggregate)
    aggregation_strategy::Symbol                           # :median, :trim25_mean, :mean, :weighted_median, ... ; :none for non-synthesized candidates
    aggregation_source_indices::Vector{Int}                # indices into the upstream candidate pool that were aggregated
    # Polish-stage HC source index (set by _polish_batch_from_context after polish);
    # 1-based index into the raw HC candidate list passed to _polish_cluster_metadata.
    # Used for offline branch-clustering analysis (paired with EstimationOptions.dump_raw_candidates_path).
    polish_source_hc_idx::Union{Nothing, Int}
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
    template_status::Union{Nothing, Symbol} = nothing,
    equations_dropped_by_rank_trimming = Int[],
    practical_identifiability_status::Symbol = :not_assessed,
    numerical_advisory::Union{Nothing, NumericalIdentifiabilityAdvisory} = nothing,
    notes = Symbol[],
    source_type::Symbol = :single_point,
    multipoint_time_indices::Union{Nothing, Vector{Int}} = nothing,
    multipoint_combo_index::Union{Nothing, Int} = nothing,
    aggregation_strategy::Symbol = :none,
    aggregation_source_indices::AbstractVector = Int[],
    polish_source_hc_idx::Union{Nothing, Int} = nothing,
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
        template_status,
        Int[equations_dropped_by_rank_trimming...],
        practical_identifiability_status,
        isnothing(numerical_advisory) ? nothing : deepcopy(numerical_advisory),
        Symbol[notes...],
        source_type,
        isnothing(multipoint_time_indices) ? nothing : Int[multipoint_time_indices...],
        multipoint_combo_index,
        aggregation_strategy,
        Int[aggregation_source_indices...],
        polish_source_hc_idx,
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
    template_status = provenance.template_status,
    equations_dropped_by_rank_trimming = provenance.equations_dropped_by_rank_trimming,
    practical_identifiability_status = provenance.practical_identifiability_status,
    numerical_advisory = provenance.numerical_advisory,
    notes = provenance.notes,
    source_type = provenance.source_type,
    multipoint_time_indices = provenance.multipoint_time_indices,
    multipoint_combo_index = provenance.multipoint_combo_index,
    aggregation_strategy = provenance.aggregation_strategy,
    aggregation_source_indices = provenance.aggregation_source_indices,
    polish_source_hc_idx = provenance.polish_source_hc_idx,
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
        template_status = template_status,
        equations_dropped_by_rank_trimming = copy(equations_dropped_by_rank_trimming),
        practical_identifiability_status = practical_identifiability_status,
        numerical_advisory = isnothing(numerical_advisory) ? nothing : deepcopy(numerical_advisory),
        notes = copy(notes),
        source_type = source_type,
        multipoint_time_indices = isnothing(multipoint_time_indices) ? nothing : copy(multipoint_time_indices),
        multipoint_combo_index = multipoint_combo_index,
        aggregation_strategy = aggregation_strategy,
        aggregation_source_indices = copy(aggregation_source_indices),
        polish_source_hc_idx = polish_source_hc_idx,
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
    push!(parts, "source=$(prov.source_type)")
    if prov.source_type == :multipoint
        !isnothing(prov.multipoint_combo_index) && push!(parts, "combo=$(prov.multipoint_combo_index)")
        !isnothing(prov.multipoint_time_indices) && push!(parts, "mp_times=$(prov.multipoint_time_indices)")
    end
    prov.rescue_path != :none && push!(parts, "rescue=$(prov.rescue_path)")
    !isnothing(prov.source_shooting_index) && push!(parts, "shoot=$(prov.source_shooting_index)")
    !isnothing(prov.source_candidate_index) && push!(parts, "candidate=$(prov.source_candidate_index)")
    !isnothing(prov.interpolator_source) && push!(parts, "interp=$(prov.interpolator_source)")
    prov.polish_applied && push!(parts, "polished=true")
    !isempty(prov.representative_assignments) && push!(parts, "representative=$(length(prov.representative_assignments))")
    !isempty(prov.structural_fix_set) && push!(parts, "structural_fix=$(length(prov.structural_fix_set))")
    !isnothing(prov.template_status) && push!(parts, "template=$(prov.template_status)")
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
    branch_size::Int   # Phase B candidate-reduction: cluster size at output time (1 = singleton or undetected)
end

# Backward-compatible constructor (interpolator_source defaults to nothing, provenance to an empty record,
# branch_size to 1 = singleton)
# Note: parameter types are relaxed to allow MTK 11's BasicSymbolicImpl keys
# (Julia's inner struct constructor handles convert() to the declared field types)
function ParameterEstimationResult(
    parameters, states, at_time, err, return_code, datasize,
    report_time, unident_dict, all_unidentifiable, solution,
)
    return ParameterEstimationResult(
        parameters, states, at_time, err, return_code, datasize,
        report_time, unident_dict, all_unidentifiable, solution, nothing, ResultProvenance(), 1,
    )
end

# Constructor with interpolator_source + provenance (no branch_size) — for callers that
# already populate those but were written before branch_size was added.
function ParameterEstimationResult(
    parameters, states, at_time, err, return_code, datasize,
    report_time, unident_dict, all_unidentifiable, solution,
    interpolator_source, provenance,
)
    return ParameterEstimationResult(
        parameters, states, at_time, err, return_code, datasize,
        report_time, unident_dict, all_unidentifiable, solution,
        interpolator_source, provenance, 1,
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
    closest_solution_production::Vector{Float64}  # per-variable x_HC values (closest to truth)
    true_values::Vector{Float64}                   # per-variable x_true (oracle)
    # Data variable values for signed IFT validation
    data_var_labels::Vector{String}                # data variable names (d_1, d_2, ...)
    data_var_prod::Vector{Float64}                 # d_prod (from production interpolants)
    data_var_true::Vector{Float64}                 # d_true (from oracle Taylor coefficients)
end

# Backward-compatible 15-arg constructor (no data variable values)
function PolynomialFeasibilityReport(
    model_name, n_equations, n_variables, is_square,
    n_solutions_perfect, n_solutions_production,
    true_residual_perfect, true_residual_production,
    closest_distance_perfect, closest_distance_production,
    variable_names, equation_strings, variable_roles,
    closest_solution_production, true_values,
)
    return PolynomialFeasibilityReport(
        model_name, n_equations, n_variables, is_square,
        n_solutions_perfect, n_solutions_production,
        true_residual_perfect, true_residual_production,
        closest_distance_perfect, closest_distance_production,
        variable_names, equation_strings, variable_roles,
        closest_solution_production, true_values,
        String[], Float64[], Float64[],
    )
end

# Backward-compatible 13-arg constructor (no per-variable solution data or data vars)
function PolynomialFeasibilityReport(
    model_name, n_equations, n_variables, is_square,
    n_solutions_perfect, n_solutions_production,
    true_residual_perfect, true_residual_production,
    closest_distance_perfect, closest_distance_production,
    variable_names, equation_strings, variable_roles,
)
    return PolynomialFeasibilityReport(
        model_name, n_equations, n_variables, is_square,
        n_solutions_perfect, n_solutions_production,
        true_residual_perfect, true_residual_production,
        closest_distance_perfect, closest_distance_production,
        variable_names, equation_strings, variable_roles,
        Float64[], Float64[],
        String[], Float64[], Float64[],
    )
end

# Backward-compatible 11-arg constructor (minimal)
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
        Float64[], Float64[],
        String[], Float64[], Float64[],
    )
end

"""
    ErrorBudgetEntry

Per-unknown signed IFT validation: Δx_predicted = S·Δd vs Δx_actual = x_HC - x_true.
"""
struct ErrorBudgetEntry
    unknown_label::String
    unknown_role::Symbol                # :parameter, :state_ic, :state_derivative
    delta_x_actual::Float64             # x_HC[i] - x_true[i] (signed)
    delta_x_predicted::Float64          # Σⱼ S[i,j]·Δd[j] (signed)
    prediction_ratio::Float64           # |predicted|/|actual| (1.0 = perfect IFT)
    blame::Vector{@NamedTuple{data_label::String, s_times_dd::Float64, pct_of_predicted::Float64}}
end

"""
    ErrorBudgetReport

Signed IFT validation: explains HC solution errors (Δx = x_HC - x_true) as a linear
function of data errors (Δd = d_prod - d_true) via the sensitivity matrix S.

Also checks first-order validity by comparing the IFT prediction S·Δd against the
actual displacement Δx.
"""
struct ErrorBudgetReport
    model_name::String
    mode::Symbol                        # :single_point or :multipoint
    t_eval::Union{Float64, Vector{Float64}}
    interpolator_name::String
    entries::Vector{ErrorBudgetEntry}
    # Data variable details (signed)
    data_labels::Vector{String}
    data_true::Vector{Float64}          # oracle data values
    data_prod::Vector{Float64}          # production interpolant values
    delta_d::Vector{Float64}            # d_prod - d_true (signed)
    max_deriv_order_used::Int
    # Nonlinearity and concentration diagnostics
    sensitivity_nonlinearity::Float64   # ‖Δx_predicted - Δx_actual‖ / ‖Δx_actual‖
    sensitivity_concentration::Float64  # max column norm of S / ‖S‖_F
    is_pathological::Bool               # concentration > 0.5
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
    error_budget::Union{Nothing, ErrorBudgetReport}
end

# Backward-compatible 7-arg constructor (no error_budget)
function DiagnosticReport(name, da, pf, sr, diff, bn, ts)
    DiagnosticReport(name, da, pf, sr, diff, bn, ts, nothing)
end

"""
    MultipointDiagnosticAnalysis

Structured metadata for multipoint diagnostics and report rendering. This is the
canonical source of truth for how the multipoint section was selected, whether
the single-point vs multipoint comparison is trustworthy, and what the stripped
template actually used.
"""
struct MultipointDiagnosticAnalysis
    selection_policy::Symbol
    compare_policy::Symbol
    selection_reason::String
    selected_time_indices::Vector{Int}
    selected_t_values::Vector{Float64}
    candidate_combo_count::Int
    solved_combo_count::Int
    selected_combo_solved::Bool
    selected_combo_solution_count::Int
    selected_combo_worst_derivative_error::Float64
    selected_combo_true_residual::Float64
    selected_combo_closest_distance::Float64
    compare_is_valid::Bool
    compare_invalid_reason::String
    comparable_unknown_labels::Vector{String}
    actual_data_labels::Vector{String}
    actual_max_deriv_order::Int
    total_equation_count::Int
    stripped_equation_count::Int
    solve_var_count::Int
    data_var_count::Int
    kept_equation_indices::Vector{Int}
    dropped_equation_indices::Vector{Int}
    eq_metadata::Vector{@NamedTuple{point::Int, is_data::Bool, order::Int}}
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
    multipoint_error_budget::Union{Nothing, ErrorBudgetReport}
    multipoint_derivative_accuracy::Vector{DerivativeAccuracyReport}  # per MP eval point
    multipoint_analysis::Union{Nothing, MultipointDiagnosticAnalysis}
end

# Backward-compatible 8-arg constructor (no MP derivative accuracy)
function ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep, mp_eb)
    ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep, mp_eb, DerivativeAccuracyReport[], nothing)
end

# Backward-compatible 7-arg constructor (no multipoint at all)
function ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep)
    ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep, nothing, DerivativeAccuracyReport[], nothing)
end

# Backward-compatible 9-arg constructor (no multipoint analysis metadata)
function ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep, mp_eb, mp_da)
    ComprehensiveDiagnosticReport(name, frs, dg, ins, eps, bi, bep, mp_eb, mp_da, nothing)
end

"""Access the best (first) full diagnostic report."""
function Base.getproperty(comp::ComprehensiveDiagnosticReport, name::Symbol)
    if name === :best
        return getfield(comp, :full_reports)[1]
    end
    return getfield(comp, name)
end

"""
    JetInfluenceEstimate

Linear influence representation for observable jets estimated from data.

For fixed GP hyperparameters, the derivative estimator is linear in the raw
observations: `jet_mean = W * y`.  The estimator sampling covariance is then
`jet_covariance = W * observation_covariance * W'`.
"""
struct JetInfluenceEstimate{M<:AbstractMatrix{Float64}}
    observable_name::String
    t_eval::Float64
    orders::Vector{Int}
    labels::Vector{String}
    mean::Vector{Float64}
    W::Matrix{Float64}
    observation_covariance::M
    jet_covariance::Matrix{Float64}
    covariance_kind::Symbol
    noise_source::Symbol
    warnings::Vector{String}
end

"""
    PracticalIdentifiabilityIndex

Scale-normalized covariance summary for the selected physical unknowns.

`i_a = sqrt(lambda_max(normalized_covariance))`, where
`normalized_covariance = D^{-1} P Σ_x P' D^{-1}`.
"""
struct PracticalIdentifiabilityIndex
    labels::Vector{String}
    roles::Vector{Symbol}
    scale_values::Vector{Float64}
    projected_covariance::Matrix{Float64}
    normalized_covariance::Matrix{Float64}
    lambda_max::Float64
    i_a::Float64
    status::Symbol
    warnings::Vector{String}
end

"""
    LocalUQSnapshot

Audit copy of the direct IFT uncertainty calculation in the local algebraic
coordinates at `t_eval`.
"""
struct LocalUQSnapshot
    t_eval::Float64
    param_covariance::Matrix{Float64}
    param_std::Vector{Float64}
    param_labels::Vector{String}
    param_roles::Dict{String, Symbol}
    coordinate_values::Vector{Float64}
    correlation_matrix::Matrix{Float64}
    max_cv::Float64
    status::Symbol
    practical_identifiability_index::Union{Nothing, PracticalIdentifiabilityIndex}
end

"""
    UQBacksolveTransform

Linear delta-method map from local coordinates `[p, x(t_eval)]` to physical
coordinates `[p, x(t0)]`.
"""
struct UQBacksolveTransform
    t_eval::Float64
    t0::Float64
    source_labels::Vector{String}
    target_labels::Vector{String}
    source_roles::Dict{String, Symbol}
    target_roles::Dict{String, Symbol}
    transform_matrix::Matrix{Float64}
    amplification::Float64
    status::Symbol
    warnings::Vector{String}
end

"""
    UncertaintyReport

Propagated parameter uncertainty through the implicit function theorem
sensitivity matrix.

Σ_x = S · Σ_d · S' where S = -(∂F/∂x)⁻¹·(∂F/∂d).  For the default package UQ,
Σ_d is the estimator sampling covariance of the observable jet, conditional on
learned GP hyperparameters.  Legacy latent GP posterior covariance is kept as a
separate diagnostic concept.
"""
struct UncertaintyReport
    model_name::String
    t_eval::Float64
    # Per-observable jet estimate at t_eval
    obs_names::Vector{String}
    obs_posterior_mean::Vector{Vector{Float64}}    # [obs_idx][deriv_order+1]
    obs_posterior_std::Vector{Vector{Float64}}     # [obs_idx][deriv_order+1]
    # Data/jet covariance
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
    covariance_kind::Symbol                       # :estimator_sampling or :latent_gp_posterior
    noise_source::Symbol                          # e.g. :learned_gp_homoscedastic
    practical_identifiability_index::Union{Nothing, PracticalIdentifiabilityIndex}
    coordinate_system::Symbol                     # :physical_initial_conditions or :local_at_eval
    local_coordinate_report::Union{Nothing, LocalUQSnapshot}
    backsolve_transform::Union{Nothing, UQBacksolveTransform}
end

# Backward-compatible constructor for callers that predate explicit coordinate
# semantics. The direct IFT calculation lives in local coordinates at t_eval.
function UncertaintyReport(
    model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
    data_covariance, data_labels, param_covariance, param_std, param_labels,
    param_roles, param_true_values, correlation_matrix, max_cv, status,
    warnings, covariance_kind, noise_source, practical_identifiability_index,
)
    return UncertaintyReport(
        model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
        data_covariance, data_labels, param_covariance, param_std, param_labels,
        param_roles, param_true_values, correlation_matrix, max_cv, status,
        warnings, covariance_kind, noise_source, practical_identifiability_index,
        :local_at_eval, nothing, nothing,
    )
end

# Backward-compatible constructor for callers that predate explicit covariance
# semantics. New package-produced reports should pass these fields explicitly.
function UncertaintyReport(
    model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
    data_covariance, data_labels, param_covariance, param_std, param_labels,
    param_roles, param_true_values, correlation_matrix, max_cv, status,
    warnings,
)
    return UncertaintyReport(
        model_name, t_eval, obs_names, obs_posterior_mean, obs_posterior_std,
        data_covariance, data_labels, param_covariance, param_std, param_labels,
        param_roles, param_true_values, correlation_matrix, max_cv, status,
        warnings, :unspecified, :unspecified, nothing,
    )
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
    ParameterSpreadEntry

Per-parameter statistics across multiple HC solutions — measures practical
identifiability through cross-solution agreement.
"""
struct ParameterSpreadEntry
    name::String
    true_val::Float64
    median::Float64
    mean::Float64
    std::Float64
    cv::Float64              # std / |median| (coefficient of variation)
    iqr_low::Float64         # 25th percentile
    iqr_high::Float64        # 75th percentile
    min_val::Float64
    max_val::Float64
    n_solutions::Int
    is_unidentifiable::Bool
    classification::Symbol   # :tight (CV<5%), :moderate (5-50%), :loose (>50%)
end

"""
    CrossSolutionSpread

Practical identifiability report: how much do parameter estimates vary across
all HC solutions from different interpolators, shooting points, and SP/MP combos?
Small spread → practically identifiable. Large spread → practically non-identifiable.
"""
struct CrossSolutionSpread
    model_name::String
    n_solutions::Int
    param_spread::Vector{ParameterSpreadEntry}
    state_spread::Vector{ParameterSpreadEntry}
end

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
    spread::Union{Nothing, CrossSolutionSpread}
end

# Backward-compatible 7-arg constructor (no spread)
function EstimationResultsReport(name, n, err, time, pc, sc, best)
    EstimationResultsReport(name, n, err, time, pc, sc, best, nothing)
end

struct TimingPhaseEntry
    name::String
    seconds::Float64
    bytes::Int64
    gctime::Float64
end

Base.@kwdef struct TimingBreakdown
    label::Symbol = :unknown
    total_seconds::Float64 = 0.0
    phases::Vector{TimingPhaseEntry} = TimingPhaseEntry[]
    details::OrderedDict{Symbol, Any} = OrderedDict{Symbol, Any}()
end

"""
    BacksolveUQReport

Uncertainty propagation from shooting point through backward ODE integration
to initial conditions at t₀, using the delta method with a variational-equation
Jacobian.

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

# ─── Multi-point template types ──────────────────────────────────────

"""
    MultiPointTemplate

Pre-computed multi-point polynomial template. Built once per model from the
single-point SI template. Stores the structural recipe (which equations to keep)
so that evaluation at specific time points is cheap.

The template stores equations in **symbolic** form (data variables not substituted),
enabling HC.jl parameter homotopy across different time point pairs.

Invariant: `length(stripped_equations) == length(solve_vars)` (square system).
"""
struct MultiPointTemplate
    n_points::Int
    base_si_template::Any  # NamedTuple from prepare_si_template_with_structural_fix

    # Combined symbolic system (N copies, renamed, stripped to square)
    all_equations::Vector{Num}
    stripped_equations::Vector{Num}
    solve_vars::Vector{Any}    # Shared params + per-point state derivs (HC variables)
    data_vars::Vector{Any}     # Per-point observable derivs + _trfn_ vars (HC parameters)

    # Metadata for parameter extraction
    param_var_indices::Vector{Int}     # Indices into solve_vars that are shared parameters
    param_names::Vector{String}        # Clean parameter names (e.g., "a", "b") for error scoring

    # Equation metadata
    eq_metadata::Vector{@NamedTuple{point::Int, is_data::Bool, order::Int}}
    total_equation_count::Int
    kept_equation_indices::Vector{Int}
    dropped_equation_indices::Vector{Int}

    # For data evaluation at arbitrary time points
    per_point_data_var_ranges::Vector{UnitRange{Int}}  # data_vars[range] for each point
    template_DD::Any           # DerivativeData for observable → variable mapping
    measured_quantities::Vector{ModelingToolkit.Equation}
end

"""
    MultiPointEvaluation

Result of evaluating a MultiPointTemplate at specific time point indices.
Contains the data variable values needed for HC.jl parameter substitution or homotopy.
"""
struct MultiPointEvaluation
    template::MultiPointTemplate
    time_indices::Vector{Int}
    t_values::Vector{Float64}
    data_values::Vector{Float64}  # Ordered to match template.data_vars
end
