# build_function_eval_minimal.jl
# Minimal reproducer: compare compiled evaluation vs substitution for 1 variable.
# No Jacobians, no solvers. Print raw evaluation results and differences.

using Symbolics
using LinearAlgebra

println("\n=== Minimal build_function evaluation test (1 variable) ===")

# Single variable
a = 3.14
@variables x
varlist = [x]

# Different residual expressions to test
exprs = Dict(
	:identity => [x],
	:affine   => [x - a],
	:square   => [x^2 - a],
	:purequad => [x^2],
)

# Test points
pts = [0.0, 0.1, -0.5, 2.3]

for (name, eqs) in exprs
	println("\n-- Case: ", name, " --")
	# Build compiled residual
	_f_oop, f_ip = Symbolics.build_function(eqs, varlist; expression = Val(false))

	# Fallback residual evaluator
	function residual_fallback(u::Real)
		d = Dict(x => u)
		Symbolics.value(Symbolics.substitute(eqs[1], d))
	end

	for u in pts
		rc = Vector{Float64}(undef, length(eqs))
		f_ip(rc, u)  # compiled eval into rc
		rf = residual_fallback(u)
		println("x=", u, "  compiled=", rc[1], "  fallback=", rf,
			"  diff=", rc[1] - rf)
	end
end

println("\nNote: If any diff != 0, compiled evaluation differs from substitution for this 1D case.")
