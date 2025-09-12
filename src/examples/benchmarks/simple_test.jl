using ODEParameterEstimation
using Symbolics
using NonlinearSolve
using ForwardDiff
using LinearAlgebra
using Dates

# Load the simple test system
println("Loading system...")
include("saved_systems/system_point_1_2025-09-11T00:02:53.925.jl")

println("System loaded with $(length(poly_system)) equations and $(length(varlist)) variables")
println("Equations:")
for (i, eq) in enumerate(poly_system)
    println("  $i: $eq")
end
println("Variables: $varlist")

m = length(poly_system)
n = length(varlist)

# Create residual function
function residual!(res, u, p)
    d = Dict(zip(varlist, u))
    for (i, eq) in enumerate(poly_system)
        val = Symbolics.value(Symbolics.substitute(eq, d))
        res[i] = convert(eltype(res), val)  # Use convert instead of Float64 constructor
    end
    return nothing
end

# Test with NewtonRaphson first
println("\n" * "="^60)
println("Testing NewtonRaphson with ForwardDiff Jacobian")
println("="^60)

x0 = ones(n) * 0.5
println("Initial guess: $x0")

# Test residual
test_res = zeros(m)
residual!(test_res, x0, nothing)
println("Initial residual: $test_res")
println("Initial residual norm: $(norm(test_res))")

# Create Jacobian with ForwardDiff
function jacobian!(J, u, p)
    g = u_ -> begin
        r = similar(u_, m)
        residual!(r, u_, p)
        r
    end
    ForwardDiff.jacobian!(J, g, u)
end

# Test Jacobian
test_J = zeros(m, n)
jacobian!(test_J, x0, nothing)
println("\nJacobian at initial point:")
display(test_J)

# Create problem - since m == n, use NonlinearProblem
nf = NonlinearFunction(residual!; jac = jacobian!)
prob = NonlinearProblem(nf, x0)

println("\nSolving with NewtonRaphson (this may take several minutes)...")
println("Starting at: $(Dates.now())")
flush(stdout)

sol = solve(prob, NewtonRaphson(); abstol=1e-6, reltol=1e-6, maxiters=1000)

println("Finished at: $(Dates.now())")
println("\nSolution found: $(sol.u)")
println("Success: $(SciMLBase.successful_retcode(sol))")

# Check final residual
final_res = zeros(m)
residual!(final_res, sol.u, nothing)
println("Final residual: $final_res")
println("Final residual norm: $(norm(final_res))")