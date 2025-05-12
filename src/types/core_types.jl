using ModelingToolkit
using OrderedCollections
using Symbolics
using OrdinaryDiffEq

"""
    OrderedODESystem

Struct representing an ODESystem with ordered parameters and states.

# Fields
- `system::ODESystem`: ModelingToolkit ODESystem
- `original_parameters::Vector{Num}`: Vector of original parameters in specific order
- `original_states::Vector{Num}`: Vector of original state variables in specific order
"""
struct OrderedODESystem
    system::ODESystem
    original_parameters::Vector{Num}
    original_states::Vector{Num}
end

"""
    ParameterEstimationProblem

Struct representing a parameter estimation problem.

# Fields
- `name::String`: Name of the estimation problem
- `model::OrderedODESystem`: Model system with equations
- `measured_quantities::Vector{Equation}`: Equations defining measured quantities
- `data_sample::Union{Nothing, OrderedDict{Any, Vector{Float64}}}`: Measured data or nothing
- `recommended_time_interval::Union{Nothing, Vector{Float64}}`: [start_time, end_time] or nothing for default
- `solver::OrdinaryDiffEq.AbstractODEAlgorithm`: ODE solver to use
- `p_true::OrderedDict{Num, Float64}`: True parameter values if known
- `ic::OrderedDict{Num, Float64}`: Initial conditions for states
- `unident_count::Int`: Number of unidentifiable parameters
"""
struct ParameterEstimationProblem
    name::String
    model::OrderedODESystem
    measured_quantities::Vector{Equation}
    data_sample::Union{Nothing, OrderedDict{Any, Vector{Float64}}}
    recommended_time_interval::Union{Nothing, Vector{Float64}}
    solver::Any  # Use Any for now since the exact type hierarchy can be complex
    p_true::OrderedDict{Num, Float64}
    ic::OrderedDict{Num, Float64}
    unident_count::Int
end

# Constants for analysis and clustering
const CLUSTERING_THRESHOLD = 0.00001  # 0.001% relative difference threshold
const MAX_ERROR_THRESHOLD = 0.5       # Maximum acceptable error
const IMAG_THRESHOLD = 1e-8           # Threshold for ignoring imaginary components
const MAX_SOLUTIONS = 20              # Maximum number of solutions to consider if no good ones found

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
- `all_unidentifiable::Set`: Set of all parameters detected as unidentifiable during analysis
- `solution::Union{Nothing, Any}`: The ODE solution (optional)
"""
mutable struct ParameterEstimationResult
    parameters::OrderedDict
    states::OrderedDict
    at_time::Float64
    err::Union{Nothing, Float64}
    return_code::Union{Nothing, Symbol}  # Changed to allow Nothing
    datasize::Int64
    report_time::Union{Nothing, Float64}
    unident_dict::Union{Nothing, Dict}
    all_unidentifiable::Set
    solution::Union{Nothing, Any}  # Keep this as Any for now since ODESolution type might vary
end

"""
    DerivativeData

Struct to store derivative data of state variable equations and measured quantity equations.
No substitutions are made.
The "cleared" versions are produced from versions of the state equations and measured quantity equations
which have had their denominators cleared, i.e. they should be polynomial and never rational.

# Fields
- `states_lhs_cleared::Any`: Left-hand side of cleared state equations
- `states_rhs_cleared::Any`: Right-hand side of cleared state equations
- `obs_lhs_cleared::Any`: Left-hand side of cleared observation equations
- `obs_rhs_cleared::Any`: Right-hand side of cleared observation equations
- `states_lhs::Any`: Left-hand side of state equations
- `states_rhs::Any`: Right-hand side of state equations
- `obs_lhs::Any`: Left-hand side of observation equations
- `obs_rhs::Any`: Right-hand side of observation equations
- `all_unidentifiable::Set{Any}`: Set of all unidentifiable parameters
"""
mutable struct DerivativeData
    states_lhs_cleared::Any
    states_rhs_cleared::Any
    obs_lhs_cleared::Any
    obs_rhs_cleared::Any
    states_lhs::Any
    states_rhs::Any
    obs_lhs::Any
    obs_rhs::Any
    all_unidentifiable::Set{Any}
end

