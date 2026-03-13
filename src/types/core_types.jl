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
