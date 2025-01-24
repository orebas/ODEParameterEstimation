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
