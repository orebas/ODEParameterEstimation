module ODEParameterEstimationPEtabExt

using ModelingToolkit, OrdinaryDiffEq
using ODEParameterEstimation, PEtab, Symbolics, OrderedCollections, Random, LinearAlgebra
import ODEParameterEstimation: load_petab_problem, estimate_petab_problem

const ODEPE = ODEParameterEstimation
const t = ModelingToolkit.t_nounits
const D = ModelingToolkit.D_nounits

include("petab/adapter.jl")
include("petab/experiment_blocks.jl")
include("petab/estimation.jl")

end # module
