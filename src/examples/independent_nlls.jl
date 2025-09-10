# independent_nlls.jl
# Standalone least-squares test using Symbolics + NonlinearSolve (no ODEParameterEstimation).

using Symbolics
using NonlinearSolve
using ForwardDiff
using LinearAlgebra

# -------------------------
# Problem setup (nonlinear system)
# -------------------------
@variables x y z w
varlist = [x, y, z, w]

# Residual-form equations (each should be ~0 at solution)
# This is a nonlinear system with trigonometric, exponential, and polynomial terms
eqs = [
	x^2 + y^2 - 1.0,                    # Circle constraint
	x + y - z,                # Trigonometric coupling
	z / 5.0 - w - 0.8,                 # Exponential term
	x * y + z*w - 0.5,                    # Bilinear coupling
]

m = length(eqs)

# Starting point
x0 = zeros(length(varlist))

# -------------------------
# Compiled residual via Symbolics.build_function
# -------------------------
println("\n=== Compiled residual + AD Jacobian ===")
_f_oop, f_ip = Symbolics.build_function(eqs, varlist; expression = Val(false))

# In-place residual that preserves element types (Dual-safe)
function residual_compiled!(res, u, p)
	f_ip(res, u...)
	return nothing
end

# AD Jacobian (Dual-safe), allocate output with correct element type
function jacobian_ad_compiled!(J, u, p)
	g(u_) = begin
		r = Vector{eltype(u_)}(undef, m)
		residual_compiled!(r, u_, nothing)
		r
	end
	ForwardDiff.jacobian!(J, g, u)
	return nothing
end

nf_compiled = NonlinearFunction(residual_compiled!; resid_prototype = zeros(m), jac = jacobian_ad_compiled!)
prob_compiled = NonlinearLeastSquaresProblem(nf_compiled, x0, nothing)

# Initial residual norm
r0c = zeros(m);
residual_compiled!(r0c, x0, nothing);
n0c = norm(r0c)

# Solve (LM)
alg = NonlinearSolve.LevenbergMarquardt()
solc = NonlinearSolve.solve(prob_compiled, alg; abstol = 1e-12, reltol = 1e-12, maxiters = 5000)

# Final residual norm
rfc = zeros(m);
residual_compiled!(rfc, solc.u, nothing);
nfc = norm(rfc)
# Robust iterations retrieval (if available)
iters_c = (hasproperty(solc, :stats) && hasproperty(solc.stats, :iterations)) ? solc.stats.iterations : missing
println("compiled: initial_norm=", n0c, " final_norm=", nfc, " improvement=", n0c - nfc)
println("compiled: retcode=", solc.retcode, " iters=", iters_c)
println("compiled: solution=", solc.u)

# -------------------------
# Fallback residual via Symbolics substitution (no compilation)
# -------------------------
println("\n=== Fallback residual + AD Jacobian ===")
function residual_fallback!(res, u, p)
	d = Dict(varlist .=> u)
	for i in 1:m
		res[i] = Symbolics.value(Symbolics.substitute(eqs[i], d))
	end
	return nothing
end

function jacobian_ad_fallback!(J, u, p)
	g(u_) = begin
		r = Vector{eltype(u_)}(undef, m)
		residual_fallback!(r, u_, nothing)
		r
	end
	ForwardDiff.jacobian!(J, g, u)
	return nothing
end

nf_fallback = NonlinearFunction(residual_fallback!; resid_prototype = zeros(m), jac = jacobian_ad_fallback!)
prob_fallback = NonlinearLeastSquaresProblem(nf_fallback, x0, nothing)

r0f = zeros(m);
residual_fallback!(r0f, x0, nothing);
n0f = norm(r0f)
solf = NonlinearSolve.solve(prob_fallback, alg; abstol = 1e-12, reltol = 1e-12, maxiters = 5000)
rf = zeros(m);
residual_fallback!(rf, solf.u, nothing);
nff = norm(rf)
iters_f = (hasproperty(solf, :stats) && hasproperty(solf.stats, :iterations)) ? solf.stats.iterations : missing
println("fallback: initial_norm=", n0f, " final_norm=", nff, " improvement=", n0f - nff)
println("fallback: retcode=", solf.retcode, " iters=", iters_f)
println("fallback: solution=", solf.u)
