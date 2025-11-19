module ODEParameterEstimationRSExt

using ODEParameterEstimation
using RationalUnivariateRepresentation
using RS
using AbstractAlgebra
using Symbolics
using SymbolicUtils
using PolynomialRoots

# Import necessary functions and types from ODEParameterEstimation
import ODEParameterEstimation: clear_denoms, rationalize_expr

# Make these functions available in the main package namespace when extension is loaded
function __init__()
    # Add the RS solver functions to the main module
    @eval ODEParameterEstimation begin
        # Functions from robust_conversion_rs.jl
        const solve_with_rs_new = $solve_with_rs_new
        const robust_exprs_to_AA_polys = $robust_exprs_to_AA_polys

        # Functions from homotopy_continuation_rs.jl
        const solve_with_rs = $solve_with_rs
        const solve_with_rs_old = $solve_with_rs_old
        const exprs_to_AA_polys = $exprs_to_AA_polys

        # Functions from optimized_multishot_rs.jl
        const try_rur_solve = $try_rur_solve
        const find_all_roots_polynomial_roots = $find_all_roots_polynomial_roots

        # Export the main solver functions
        export solve_with_rs, solve_with_rs_new, solve_with_rs_old
        export exprs_to_AA_polys, robust_exprs_to_AA_polys
        export try_rur_solve, find_all_roots_polynomial_roots
    end
    @debug "ODEParameterEstimation RS extension loaded"
end

# Include the functions from robust_conversion.jl
include("robust_conversion_rs.jl")

# Include the functions from homotopy_continuation.jl
include("homotopy_continuation_rs.jl")

# Include the optimized multishot estimation RS components
include("optimized_multishot_rs.jl")

end # module