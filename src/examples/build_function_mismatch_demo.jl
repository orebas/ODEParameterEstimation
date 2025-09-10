# build_function_mismatch_demo.jl
# Minimal reproducer to compare Symbolics.build_function against a substitution-based residual.
# No try/catch: any failure will surface. Share this output with Symbolics.jl authors if needed.

using Symbolics
using ForwardDiff
using LinearAlgebra
using Random

#println("\n=== Environment ===")
#versioninfo()

# -------------------------
# Problem: small polynomial system (no trig/exp)
# -------------------------
@variables x y z w
varlist = [x, y, z, w]

# Residual-form equations (each should be 0 at solution)
eqs = [
	x^2 + y^2 - 1.0,        # circle-like
	x + y - z,              # linear coupling
	z / 5.0 - w - 0.8,        # linear scaling
	x * y + z*w - 0.5,        # bilinear
]

m = length(eqs)

# Build compiled residual (in-place function): f_ip(res, x, y, z, w)
println("\n=== Building compiled residual via Symbolics.build_function ===")
_f_oop, f_ip = Symbolics.build_function(eqs, varlist; expression = Val(false))

# Fallback residual via substitution
function residual_fallback!(res, u::AbstractVector)
	d = Dict(varlist .=> u)
	for i in 1:m
		res[i] = Symbolics.value(Symbolics.substitute(eqs[i], d))
	end
	return nothing
end

# Wrapper for compiled residual
function residual_compiled!(res, u::AbstractVector)
	f_ip(res, u...)
	return nothing
end

# AD Jacobians (Dual-safe) for both paths
function jacobian_ad!(J, residual!, u)
	g(u_) = begin
		r = Vector{eltype(u_)}(undef, m)
		residual!(r, u_)
		r
	end
	ForwardDiff.jacobian!(J, g, u)
	return nothing
end

# -------------------------
# Compare compiled vs fallback on a grid of test points
# -------------------------
println("\n=== Residual value comparison at test points ===")
pts = [
	[0.0, 0.0, 0.0, 0.0],
	[0.1, 0.2, -0.3, 0.4],
	[0.5, -0.2, 0.9, -0.1],
	[0.2217, -0.9751, -0.7534, -0.9507],
]

for (k, p) in enumerate(pts)
	rc = zeros(m);
	rf = zeros(m)
	residual_compiled!(rc, p)
	residual_fallback!(rf, p)
	println("pt$k u=", p, "\n  compiled=", rc, "\n  fallback=", rf,
		"\n  ||compiled - fallback|| = ", norm(rc .- rf))
end

# -------------------------
# Compare Jacobians at the same points
# -------------------------
println("\n=== Jacobian comparison at test points ===")
for (k, p) in enumerate(pts)
	Jc = zeros(m, length(varlist))
	Jf = zeros(m, length(varlist))
	jacobian_ad!(Jc, residual_compiled!, p)
	jacobian_ad!(Jf, residual_fallback!, p)
	println("pt$k u=", p,
		"\n  ||J_compiled - J_fallback|| = ", norm(Jc .- Jf),
		"\n  J_compiled=\n", Jc,
		"\n  J_fallback=\n", Jf)
end

println("\n=== Notes ===")
println("If residual or Jacobian differences are nonzero, compiled build_function does not match substitution")
println("varlist order used by build_function: ", varlist)
