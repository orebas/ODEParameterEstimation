# Private symbolic construction backend. No dependency on the parent package.
module SIANBackend
using Nemo
using Random
include("utilities.jl")
include("max_poly_system.jl")
include("get_x_eq.jl")
include("get_y_eq.jl")
include("sample_point.jl")
end
