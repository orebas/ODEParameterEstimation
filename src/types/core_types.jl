using ModelingToolkit
using OrderedCollections
using Symbolics

struct OrderedODESystem
	system::ODESystem
	original_parameters::Vector
	original_states::Vector
end

struct ParameterEstimationProblem
	name::String
	model::OrderedODESystem
	measured_quantities::Vector{Equation}
	data_sample::Union{Nothing, OrderedDict}
	recommended_time_interval::Union{Nothing, Vector{Float64}}  # [start_time, end_time] or nothing for default
	solver::Any
	p_true::Any
	ic::Any
	unident_count::Int
end

# Constants for analysis and clustering
const CLUSTERING_THRESHOLD = 0.01  # 1% relative difference threshold
const MAX_ERROR_THRESHOLD = 0.5    # Maximum acceptable error
const IMAG_THRESHOLD = 1e-8        # Threshold for ignoring imaginary components
const MAX_SOLUTIONS = 20           # Maximum number of solutions to consider if no good ones found



"""
	ParameterEstimationResult

Struct to store the results of parameter estimation.

# Fields
- `parameters::AbstractDict`: Estimated parameters
- `states::AbstractDict`: Estimated states
- `at_time::Float64`: Time at which estimation is done
- `err::Union{Nothing, Float64}`: Error of estimation
- `return_code::Any`: Return code of the estimation process
- `datasize::Int64`: Size of the data used
- `report_time::Any`: Time at which the result is reported
- `unident_dict::Union{Nothing, AbstractDict}`: Dictionary of unidentifiable parameters and their values
- `all_unidentifiable::Set{Any}`: Set of all parameters detected as unidentifiable during analysis
- `solution::Union{Nothing, Any}`: The ODE solution (optional)
"""
mutable struct ParameterEstimationResult
	parameters::AbstractDict
	states::AbstractDict
	at_time::Float64
	err::Union{Nothing, Float64}
	return_code::Any
	datasize::Int64
	report_time::Any
	unident_dict::Any
	all_unidentifiable::Set{Any}
	solution::Union{Nothing, Any}
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

