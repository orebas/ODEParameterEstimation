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
include("analysis/clustering.jl")
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

"""
	handle_simple_substitutions(eqns, varlist)

Look for equations like a-5.5 and replace a with 5.5.

# Arguments
- `eqns`: Equations to process
- `varlist`: List of variables

# Returns
- Tuple containing filtered equations, reduced variable list, trivial variables, and trivial dictionary
"""
function handle_simple_substitutions(eqns, varlist)
	trivial_dict = Dict()
	filtered_eqns = typeof(eqns)()
	trivial_vars = []
	for i in eqns
		g = Symbolics.get_variables(i)
		if (length(g) == 1 && Symbolics.degree(i) == 1)
			thisvar = g[1]
			td = (polynomial_coeffs(i, (thisvar,)))[1]
			if (1 in Set(keys(td)))
				thisvarvalue = (-td[1] / td[thisvar])
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			else
				thisvarvalue = 0
				trivial_dict[thisvar] = thisvarvalue
				push!(trivial_vars, thisvar)
			end
		else
			push!(filtered_eqns, i)
		end
	end
	reduced_varlist = filter(x -> !(x in Set(trivial_vars)), varlist)
	filtered_eqns = Symbolics.substitute.(filtered_eqns, Ref(trivial_dict))
	return filtered_eqns, reduced_varlist, trivial_vars, trivial_dict
end

"""
	populate_derivatives(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict)

Populate a DerivativeData object by taking derivatives of state variable and measured quantity equations.
diff2term is applied everywhere, so we will be left with variables like x_tttt etc.

# Arguments
- `model::ODESystem`: The ODE system
- `measured_quantities_in`: Input measured quantities
- `max_deriv_level`: Maximum derivative level
- `unident_dict`: Dictionary of unidentifiable variables

# Returns
- DerivativeData object
"""
function populate_derivatives(model::ODESystem, measured_quantities_in, max_deriv_level, unident_dict)
	(t, model_eq, model_states, model_ps) = unpack_ODE(model)
	measured_quantities = deepcopy(measured_quantities_in)

	DD = DerivativeData([], [], [], [], [], [], [], [], Set{Any}())

	#First, we fully substitute values we have chosen for an unidentifiable variables.
	unident_subst!(model_eq, measured_quantities, unident_dict)

	model_eq_cleared = clear_denoms.(model_eq)
	measured_quantities_cleared = clear_denoms.(measured_quantities)

	DD.states_lhs = [[eq.lhs for eq in model_eq], expand_derivatives.(D.([eq.lhs for eq in model_eq]))]
	DD.states_rhs = [[eq.rhs for eq in model_eq], expand_derivatives.(D.([eq.rhs for eq in model_eq]))]
	DD.obs_lhs = [[eq.lhs for eq in measured_quantities], expand_derivatives.(D.([eq.lhs for eq in measured_quantities]))]
	DD.obs_rhs = [[eq.rhs for eq in measured_quantities], expand_derivatives.(D.([eq.rhs for eq in measured_quantities]))]

	DD.states_lhs_cleared = [[eq.lhs for eq in model_eq_cleared], expand_derivatives.(D.([eq.lhs for eq in model_eq_cleared]))]
	DD.states_rhs_cleared = [[eq.rhs for eq in model_eq_cleared], expand_derivatives.(D.([eq.rhs for eq in model_eq_cleared]))]
	DD.obs_lhs_cleared = [[eq.lhs for eq in measured_quantities_cleared], expand_derivatives.(D.([eq.lhs for eq in measured_quantities_cleared]))]
	DD.obs_rhs_cleared = [[eq.rhs for eq in measured_quantities_cleared], expand_derivatives.(D.([eq.rhs for eq in measured_quantities_cleared]))]

	for i in 1:(max_deriv_level-2)
		push!(DD.states_lhs, expand_derivatives.(D.(DD.states_lhs[end])))
		temp = DD.states_rhs[end]
		temp2 = D.(temp)
		temp3 = deepcopy(temp2)
		temp4 = []
		for j in 1:length(temp3)
			temptemp = expand_derivatives(temp3[j])
			push!(temp4, deepcopy(temptemp))
		end
		push!(DD.states_rhs, temp4)
		push!(DD.states_lhs_cleared, expand_derivatives.(D.(DD.states_lhs_cleared[end])))
		push!(DD.states_rhs_cleared, expand_derivatives.(D.(DD.states_rhs_cleared[end])))
	end

	for i in eachindex(DD.states_rhs), j in eachindex(DD.states_rhs[i])
		DD.states_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs[i][j]))
		DD.states_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs[i][j]))
		DD.states_rhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_rhs_cleared[i][j]))
		DD.states_lhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.states_lhs_cleared[i][j]))
	end

	for i in 1:(max_deriv_level-1)
		push!(DD.obs_lhs, expand_derivatives.(D.(DD.obs_lhs[end])))
		push!(DD.obs_rhs, expand_derivatives.(D.(DD.obs_rhs[end])))
		push!(DD.obs_lhs_cleared, expand_derivatives.(D.(DD.obs_lhs_cleared[end])))
		push!(DD.obs_rhs_cleared, expand_derivatives.(D.(DD.obs_rhs_cleared[end])))
	end

	for i in eachindex(DD.obs_rhs), j in eachindex(DD.obs_rhs[i])
		DD.obs_rhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_rhs[i][j]))
		DD.obs_lhs[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_lhs[i][j]))
		DD.obs_rhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_rhs_cleared[i][j]))
		DD.obs_lhs_cleared[i][j] = ModelingToolkit.diff2term(expand_derivatives(DD.obs_lhs_cleared[i][j]))
	end
	return DD
end

end # module
