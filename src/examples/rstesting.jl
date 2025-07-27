using AbstractAlgebra
using RationalUnivariateRepresentation
# using RS

"""
	exprs_to_AA_polys(exprs, vars)

Convert each symbolic expression in `exprs` into a polynomial in an
AbstractAlgebra polynomial ring in the variables `vars`. This returns
both the ring `R` and the vector of polynomials in `R`.
"""
function exprs_to_AA_polys(exprs, vars)
	# Create a polynomial ring over QQ, using the variable names

	M = Module()
	Base.eval(M, :(using AbstractAlgebra))
	#Base.eval(M, :(using Nemo))
	#	Base.eval(M, :(using RationalUnivariateRepresentation))
	#	Base.eval(M, :(using RS))

	var_names = string.(vars)
	ring_command = "R = @polynomial_ring(QQ, $var_names)"
	#approximation_command = "R(expr::Float64) = R(Nemo.rational_approx(expr, 1e-4))"
	ring_object = Base.eval(M, Meta.parse(ring_command))
	#display(temp)
	#Base.eval(M, Meta.parse(approximation_command))


	a = string.(exprs)
	AA_polys = []
	for expr in exprs
		push!(AA_polys, Base.eval(M, Meta.parse(string(expr))))
	end
	return ring_object, AA_polys

end






function solve_with_rs(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	options = Dict())

	#try
	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist)

	println("aa_system")
	println(aa_system)
	println("R")
	println(R)
	# Compute RUR and get separating element
	rur, sep = zdim_parameterization(aa_system, get_separating_element = true)

	# Find solutions
	output_precision = get(options, :output_precision, Int32(20))
	sol = # RS.rs_isolate(rur, sep, output_precision = output_precision)

	# Convert solutions back to our format
	solutions = []
	display(sol)
	for s in sol
		# Extract real solutions
		#display(s)
		real_sol = [convert(Float64, real(v[1])) for v in s]
		push!(solutions, real_sol)
	end

	#return solutions, varlist, Dict(), varlist
	return solutions, varlist, Dict(), varlist
end

@variables a b
poly_system = [(a^2 + b^2 - 5), (a - 2 * b)]
varlist = [a, b]

display(solve_with_rs(poly_system, varlist))
