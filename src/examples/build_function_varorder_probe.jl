# build_function_varorder_probe.jl
# Probe build_function argument ordering: test all permutations of variables
# and compare compiled vs substitution evaluation per equation at multiple points.

using Symbolics
using LinearAlgebra
using Combinatorics

println("\n=== build_function varorder probe ===")

# Variables and equations
@variables x y z w
vars = [x, y, z, w]

# Equations chosen to make variable roles obvious
# Each eq uses distinct coefficients of each var so order mismatches show clearly.
eqs = [
	1.0*x + 2.0*y + 3.0*z + 4.0*w - 1.23,
	5.0*x - 6.0*y + 7.0*z - 8.0*w + 0.42,
	0.5*x + 0.0*y - 1.5*z + 2.5*w - 3.14,
	-2.0*x + 4.0*y + 0.0*z + 1.0*w + 2.71,
]

m = length(eqs)

# Test points
pts = [
	[0.0, 0.0, 0.0, 0.0],
	[0.1, 0.2, -0.3, 0.4],
	[0.5, -0.2, 0.9, -0.1],
]

# Fallback residual
function eval_fallback(eqs, varorder, u)
	d = Dict(varorder .=> u)
	[Symbolics.value(Symbolics.substitute(eq, d)) for eq in eqs]
end

# Try all permutations of var orderings for build_function
for (perm_idx, varorder) in enumerate(permutations(vars))
	_f, f_ip = Symbolics.build_function(eqs, collect(varorder); expression = Val(false))
	ok = true
	worst = 0.0
	which_pt = 0
	which_eq = 0
	for (pi, p) in enumerate(pts)
		rc = zeros(m)
		f_ip(rc, p...)
		rf = eval_fallback(eqs, collect(varorder), p)
		diffs = rc .- rf
		nd = maximum(abs.(diffs))
		if nd > worst
			worst = nd
			which_pt = pi
			which_eq = argmax(abs.(diffs))
		end
		if nd > 1e-12
			ok = false
		end
	end
	println("perm #", perm_idx, " varorder=", varorder, " match=", ok,
		" worst_diff=", worst, " at pt#", which_pt, " eq#", which_eq)
end

println("\nNote: If any permutation reports match=false, compiled eval differs from substitution for that ordering.")
