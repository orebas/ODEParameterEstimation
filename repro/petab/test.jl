using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
include(joinpath(@__DIR__, "..", "..", "test", "petab", "runtests.jl"))
