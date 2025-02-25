module ODEParameterEstimationPEtabExt

using ODEParameterEstimation
using PEtab
using ModelingToolkit

# Re-export both the original and new names for compatibility
export load_model, load_petab_model, convert_petab_model, validate_petab_model

include("petab/loader.jl")
include("petab/convert_petab.jl")
include("petab/validate_petab.jl")
include("petab/petab-runner.jl")

end # module 