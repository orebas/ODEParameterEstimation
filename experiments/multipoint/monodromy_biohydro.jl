# Try monodromy solving on biohydrogenation 2-point system
# Skip polyhedral and total degree (both fail/too slow)
# Go straight to Newton-found start + monodromy
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; using Random; using HomotopyContinuation; include("experiments/multipoint/monodromy_biohydro.jl")'

using ODEParameterEstimation
using ModelingToolkit
using Symbolics
using OrderedCollections
using LinearAlgebra
using ForwardDiff
using Printf
using Random
using HomotopyContinuation

# Reuse the build function from save_and_solve_biohydro.jl
include("save_and_solve_biohydro.jl")  # This will run the full script...

# Actually, let's not include that. Let me just copy the build logic inline.
# (The include would re-run everything including the failing solve attempts)
