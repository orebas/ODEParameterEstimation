"""
	solve_with_nlopt(poly_system, varlist; 
					start_point=nothing,
					optimizer=BFGS(),
					polish_only=false,
					options=Dict())

Solves a polynomial system using traditional nonlinear optimization methods.
Can be used either as a standalone solver or to polish solutions from other methods.

# Arguments
- `poly_system`: System of polynomial equations to solve
- `varlist`: List of variables in the system
- `start_point`: Optional starting point. If not provided, random initialization is used
- `optimizer`: The optimization algorithm to use (default: BFGS)
- `polish_only`: If true, assumes start_point is close to solution and uses more local methods
- `options`: Dictionary of additional options for the optimizer

# Returns
- `solutions`: Array of solutions found
- `hc_variables`: Variables in HomotopyContinuation format
"""
function solve_with_nlopt(poly_system, varlist;
	start_point = nothing,
	optimizer = NonlinearSolve.LevenbergMarquardt(),
	polish_only = false,
	options = Dict())

	# Check if we received Nemo polynomials instead of Symbolics expressions
	if !isempty(poly_system) && poly_system[1] isa Nemo.QQMPolyRingElem
		error("solve_with_nlopt received Nemo polynomials instead of Symbolics expressions. This suggests a conversion issue in SI.jl integration.")
	end

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)

	# Define residual function for NonlinearLeastSquares
	function residual!(res, u, p)
		for (i, eq) in enumerate(prepared_system)
			ddict = Dict(zip(mangled_varlist, u))

			println("eq: $eq")
			println("type of eq: $(typeof(eq))")
			println("ddict: $ddict")
			println("type of ddict: $(typeof(ddict))")

			substres = Symbolics.substitute(eq, ddict)
			symbval = Symbolics.value(substres)
			realval = real(symbval)
			println("realval: $realval")
			println("type of realval: $(typeof(realval))")
			res[i] = Float64(realval)
		end
	end

	# Set up optimization problem
	n = length(varlist)
	m = length(prepared_system)  # Number of equations
	x0 = if isnothing(start_point)
		randn(n)  # Random initialization if no start point provided
	else
		start_point
	end

	# Calculate initial residual
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Create NonlinearLeastSquaresProblem
	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!, resid_prototype = zeros(m)),
		x0,
		nothing;  # no parameters needed
	)

	# Set solver options based on polish_only
	solver_opts = if polish_only
		(abstol = 1e-12, reltol = 1e-12, maxiters = 1000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end

	# Merge with user options
	solver_opts = merge(solver_opts, options)

	# Solve the problem with exception handling
	sol = try
		NonlinearSolve.solve(prob, optimizer; solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		# Calculate final residual
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)

		improvement = initial_norm - final_norm
		if improvement > 0
			println("Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))")
		else
			println("Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))")
		end

		# Return all four expected values: solutions, variables, trivial_dict, trimmed_varlist
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end



function solve_with_nlopt_quick(poly_system, varlist;
	start_point = nothing,
	optimizer = NonlinearSolve.LevenbergMarquardt(),
	polish_only = false,
	options = Dict())

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)



	# Define residual function for NonlinearLeastSquares
	function residual!(res, u, p)
		for (i, eq) in enumerate(prepared_system)
			res[i] = Float64(real(Symbolics.value(Symbolics.substitute(eq, Dict(zip(mangled_varlist, u))))))
		end
	end

	# Set up optimization problem
	n = length(varlist)
	m = length(prepared_system)  # Number of equations
	x0 = if isnothing(start_point)
		randn(n)  # Random initialization if no start point provided
	else
		start_point
	end

	# Calculate initial residual
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Create NonlinearLeastSquaresProblem
	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!, resid_prototype = zeros(m)),
		x0,
		nothing;  # no parameters needed
	)

	# Set solver options based on polish_only
	solver_opts = (abstol = 1e-3, reltol = 1e-3, maxiters = 50)

	# Merge with user options
	solver_opts = merge(solver_opts, options)

	# Solve the problem with exception handling
	sol = try
		NonlinearSolve.solve(prob, optimizer; solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		# Calculate final residual
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)

		improvement = initial_norm - final_norm
		if improvement > 0
			println("Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))")
		else
			println("Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))")
		end

		# Return all four expected values: solutions, variables, trivial_dict, trimmed_varlist
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end

"""
	solve_with_fast_nlopt(poly_system, varlist; kwargs...)

Fast NonlinearLeastSquares solver using compiled symbolic functions.
Uses Symbolics.build_function to compile the system into efficient Julia code.
Falls back to substitute/value method if compilation fails.
"""
function solve_with_fast_nlopt(poly_system, varlist;
	start_point = nothing,
	optimizer = NonlinearSolve.LevenbergMarquardt(),
	polish_only = false,
	options = Dict())

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)
	m = length(prepared_system)
	n = length(mangled_varlist)

	# --- NEW: Fast, compiled residual function using build_function ---
	f_ip = try
		# This compiles the symbolic system into a highly efficient Julia function
		_, ip = Symbolics.build_function(prepared_system, mangled_varlist; expression = Val(false))
		ip
	catch err
		@warn "Symbolics.build_function failed; falling back to slower substitute/value method." err
		nothing
	end

	function residual!(res, u, p)
		if !isnothing(f_ip)
			# Fast Path: Use the pre-compiled function
			f_ip(res, u...)
			res .= real.(res) # Safeguard against spurious complex numbers
		else
			# Fallback Path: The original, allocation-heavy method
			d = Dict(zip(mangled_varlist, u))
			for i in 1:m
				res[i] = Float64(real(Symbolics.value(Symbolics.substitute(prepared_system[i], d))))
			end
		end
	end
	# --- END NEW SECTION ---

	# Set up optimization problem
	x0 = isnothing(start_point) ? randn(n) : copy(start_point)

	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = LinearAlgebra.norm(initial_residual)

	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!, resid_prototype = zeros(m)),
		x0,
		nothing;
	)

	# Set solver options
	solver_opts = if polish_only
		(abstol = 1e-13, reltol = 1e-13, maxiters = 1000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end
	solver_opts = merge(solver_opts, options)

	# Solve the problem
	sol = try
		NonlinearSolve.solve(prob, optimizer; solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = LinearAlgebra.norm(final_residual)

		improvement = initial_norm - final_norm
		if improvement > 0
			@debug "Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))"
		else
			@debug "Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))"
		end

		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end

function solve_with_nlopt_testing(poly_system, varlist;
	start_point = nothing,
	optimizer   = nothing,  # default set below to FastShortcutNLLSPolyalg()
	polish_only = false,
	options     = Dict())

	# Minimal deps locally; assumes these packages are in your environment.
	#	using NonlinearSolve
	#	using Symbolics
	#	using ADTypes  # provides AutoForwardDiff()

	# Prepare
	prepared_system, mangled_varlist = (poly_system, varlist)
	m = length(prepared_system)
	n = length(mangled_varlist)

	# --- Fast compiled residual (prefer) with safe fallback -------------------
	compiled_residual! = nothing
	begin
		try
			# For a vector of expressions, build_function returns (oop, iip) functions.
			# We use the in-place version f!(res, x1, x2, ...).
			f_oop, f_ip = Symbolics.build_function(prepared_system, mangled_varlist;
				expression = Val(false))
			#compiled_residual! = (res, u, p) -> (f_ip(res, u...); nothing)
			# Unpack `u` into a tuple of arguments for `f_ip`.
			# This is now compatible with the splatting (`...`) that `build_function` expects.
			compiled_residual! = (res, u, p) -> (f_ip(res, u); nothing)
		catch err
			@warn "Symbolics.build_function failed; falling back to substitute/value" err
			compiled_residual! = nothing
		end
	end

	function residual!(res, u, p)
		if compiled_residual! !== nothing
			compiled_residual!(res, u, p)
		else
			# Slow but robust fallback; keeps your original semantics.
			d = Dict(zip(mangled_varlist, u))
			@inbounds for i in 1:m
				# Avoid `real(...)` so autodiff can work; assume expressions are real-valued.
				res[i] = Float64(Symbolics.value(Symbolics.substitute(prepared_system[i], d)))
			end
			nothing
		end
	end

	# Initial guess
	x0 = isnothing(start_point) ? randn(n) : copy(start_point)

	# Initial residual norm (for reporting)
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Problem definition
	nf = NonlinearFunction(residual!; resid_prototype = zeros(m))  # size hint only. :contentReference[oaicite:2]{index=2}
	prob = NonlinearLeastSquaresProblem(nf, x0, nothing)

	# Tolerances
	solver_opts = polish_only ?
				  (abstol = 1e-12, reltol = 1e-12, maxiters = 1_000) :
				  (abstol = 1e-8, reltol = 1e-8, maxiters = 10_000)

	# Merge user options (convert Dict -> NamedTuple for keyword splatting)
	# Strip any keys we handle explicitly.
	user_pairs = collect(pairs(options))
	# nothing to strip currently
	user_named = (; user_pairs...)
	solver_opts = merge(solver_opts, user_named)

	# Algorithm: recommended polyalgorithm unless user supplied one.
	# FastShortcutNLLSPolyalg(): tries Gauss-Newton, falls back to LM/TrustRegion. :contentReference[oaicite:3]{index=3}
	alg = isnothing(optimizer) ? NonlinearSolve.FastShortcutNLLSPolyalg() : optimizer

	# Dense forward-mode AD is the safest default for problems of this size. :contentReference[oaicite:4]{index=4}
	ad_backend = AutoForwardDiff()

	# Solve
	sol = try
		NonlinearSolve.solve(prob, alg; autodiff = ad_backend, solver_opts...)
	catch e
		@warn "Error during optimization: $(e)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Post-process
	if SciMLBase.successful_retcode(sol)
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)
		improvement = initial_norm - final_norm
		if improvement > 0
			println("Optimization improved residual by $(improvement) (from $(initial_norm) to $(final_norm))")
		else
			println("Optimization did not improve residual (initial: $(initial_norm), final: $(final_norm))")
		end
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		@warn "Optimization did not converge. RetCode: $(sol.retcode)"
		return [], mangled_varlist, Dict(), mangled_varlist
	end
end









"""
	exprs_to_AA_polys(exprs, vars)

Convert each symbolic expression in `exprs` into a polynomial in an
AbstractAlgebra polynomial ring in the variables `vars`. This returns
both the ring `R` and the vector of polynomials in `R`.
"""
function round_floats(expr, digits)
	r = SymbolicUtils.Rewriters.Prewalk(x -> x isa Float64 ? rationalize(x, tol = 1.0/(10^digits)) : x)
	return r(expr)
end

function sanitize_vars(varlist)
	var_names = string.(varlist)
	sanitize = name -> begin
		s = replace(name, r"[^A-Za-z0-9_]" => "_")
		startswith(s, r"[0-9]") ? "v_" * s : s
	end
	sanitized = sanitize.(var_names)
	return sanitized
end


function exprs_to_AA_polys(exprs, vars, digits; debug_aa = false)
	# Create a polynomial ring over QQ, using the variable names

	M = Module()
	Base.eval(M, :(using AbstractAlgebra))
	#Base.eval(M, :(using Nemo))
	Base.eval(M, :(using RationalUnivariateRepresentation))
	Base.eval(M, :(using RS))

	var_names = string.(vars)
	# Create the polynomial ring with polynomial_ring function
	ring_command = "R, poly_vars = polynomial_ring(QQ, $var_names)"
	#approximation_command = "R(expr::Float64) = R(Nemo.rational_approx(expr, 1e-4))"
	result = Base.eval(M, Meta.parse(ring_command))
	ring_object = result[1]  # The ring is the first element
	poly_vars = result[2]  # The polynomial variables

	# Assign each polynomial variable to its name in the module
	for (name, var) in zip(var_names, poly_vars)
		sym = Symbol(name)
		Base.eval(M, :($sym = $var))
	end

	# Debug: verify variables were created
	if debug_aa
		println("[DEBUG-AA] Ring created: ", ring_object)
		println("[DEBUG-AA] Created $(length(poly_vars)) polynomial variables")
		# Test if first variable is accessible
		if length(var_names) > 0
			test_var = Base.eval(M, Meta.parse(var_names[1]))
			println("[DEBUG-AA] First variable $(var_names[1]) type: ", typeof(test_var))
		end
	end

	exprs = round_floats.(exprs, digits)
	a = string.(exprs)

	# Debug: check what we're trying to parse
	if debug_aa
		println("[DEBUG-AA] Converting $(length(exprs)) expressions to AbstractAlgebra polynomials")
		println("[DEBUG-AA] Ring type: ", typeof(ring_object))
	end

	# Initialize AA_polys as a properly typed array after we know the ring type
	# We'll start with an empty Any array and convert later
	AA_polys_temp = []

	for (i, expr) in enumerate(exprs)
		expr_str = string(expr)

		# Debug: show what we're parsing for problematic expressions
		if debug_aa && (i <= 3 || length(expr_str) > 100)  # Show first few or complex ones
			println("[DEBUG-AA] Expression $i string length: $(length(expr_str))")
			if length(expr_str) < 200
				println("[DEBUG-AA]   Content: $expr_str")
			else
				println("[DEBUG-AA]   Content (truncated): $(expr_str[1:100])...$(expr_str[end-50:end])")
			end

			# Check for large rationals that might cause issues
			if occursin("//", expr_str)
				# Extract and check the size of rationals
				rational_matches = eachmatch(r"(\d+)//(\d+)", expr_str)
				for m in rational_matches
					num_str, den_str = m.captures
					if length(num_str) > 10 || length(den_str) > 10
						println("[DEBUG-AA]   Large rational detected: $(length(num_str)) digit numerator, $(length(den_str)) digit denominator")
					end
				end
			end
		end

		try
			parsed_poly = Base.eval(M, Meta.parse(expr_str))
			if debug_aa
				println("[DEBUG-AA]   Parsed type: ", typeof(parsed_poly))
			end
			push!(AA_polys_temp, parsed_poly)
		catch e
			if debug_aa
				println("[DEBUG-AA] ERROR parsing expression $i: ", e)
				println("[DEBUG-AA]   Failed expression: ", expr_str[1:min(200, length(expr_str))])

				# Try to understand what went wrong
				if occursin("//", expr_str)
					println("[DEBUG-AA]   Expression contains rationals - checking if this is the issue")
					# Try evaluating just a simple rational to see if QQ is available
					try
						test_rational = Base.eval(M, Meta.parse("QQ(1,2)"))
						println("[DEBUG-AA]   QQ is available, type: ", typeof(test_rational))
					catch e2
						println("[DEBUG-AA]   QQ is NOT available: ", e2)
					end
				end
			end

			rethrow(e)
		end
	end

	if debug_aa
		println("[DEBUG-AA] Successfully converted $(length(AA_polys_temp)) polynomials")
	end

	# Now convert the AA_polys_temp array to the proper type
	if !isempty(AA_polys_temp)
		if debug_aa
			println("[DEBUG-AA] First polynomial type before conversion: ", typeof(AA_polys_temp[1]))
		end

		# Get the element type of the ring
		elem_t = elem_type(ring_object)
		if debug_aa
			println("[DEBUG-AA] Expected element type: ", elem_t)
			println("[DEBUG-AA] Checking if polynomials are already correct type...")
			println("[DEBUG-AA]   First poly isa elem_t? ", AA_polys_temp[1] isa elem_t)
		end

		# Try to create a properly typed array
		try
			# Convert to the proper type
			AA_polys = elem_t[p for p in AA_polys_temp]
			if debug_aa
				println("[DEBUG-AA] Successfully created typed array of type: ", typeof(AA_polys))
			end
		catch e
			if debug_aa
				println("[DEBUG-AA] WARNING: Could not create typed array: ", e)
				println("[DEBUG-AA] Falling back to untyped array")
			end
			AA_polys = AA_polys_temp
		end
	else
		AA_polys = AA_polys_temp
	end

	if debug_aa
		println("[DEBUG-AA] Final AA_polys type: ", typeof(AA_polys))
		if !isempty(AA_polys)
			println("[DEBUG-AA] First polynomial type after conversion: ", typeof(AA_polys[1]))
		end
	end

	return ring_object, AA_polys

end





function poly_evaluate(poly, x)
	if poly isa AbstractVector
		value = 0.0 + 0.0im
		for (i, coeff) in enumerate(poly)
			value += Float64(coeff) * x^(i - 1)
		end
		return value
	else
		return evaluate(poly, x)
	end
end

function evaluate_rur_subs(rur, v_val, vars)
	#println("\nDEBUG [evaluate_rur_subs]: Processing RUR substitutions")
	#println("Input root value: $v_val")

	# Get the first polynomial (f₁) and compute its derivative coefficients
	f1 = rur[1]
	if f1 isa AbstractVector
		f1_derivative_coeffs = [(i - 1) * f1[i] for i in 2:length(f1)]
	else
		error("Unsupported polynomial type for derivative")
	end

	# Evaluate derivative at root
	normalization = poly_evaluate(f1_derivative_coeffs, v_val)
	#println("Normalization factor (f₁'(x₀)): $normalization")

	# Create solution dictionary
	sol_dict = Dict{Symbol, Any}()

	# Instead of splitting vars into parameters and states by name, preserve the original order
	ordered_vars = vars  # FIX: Use the original ordering rather than reordering by filtering

	#println("\nDEBUG [evaluate_rur_subs]: Variable ordering:")
	#for (i, v) in enumerate(ordered_vars)
	#	println("$i: $v")
	#end

	# Process RUR substitutions (skip first polynomial which was used to find roots)
	for (i, u_poly) in enumerate(rur[2:end])
		if i <= length(ordered_vars)
			var = ordered_vars[i]
			u_val = poly_evaluate(u_poly, v_val)
			computed_val = u_val / normalization
			sol_dict[var] = computed_val
		end
	end

	#println("\nDEBUG [evaluate_rur_subs]: Solution verification:")
	#for (var, val) in sol_dict
	#	println("$var => $val")
	#end

	return sol_dict
end

function solve_rur_complex(poly)
	coeffs = isa(poly, AbstractVector) ? poly : coefficients(poly)
	# Make polynomial square-free first
	# This is a simplified version - ideally we'd use gcd with derivative like in your colleague's code
	complex_coeffs = Complex{Float64}[Float64(c) for c in coeffs]
	roots_found = PolynomialRoots.roots(complex_coeffs)
	return roots_found
end

"""
	add_random_linear_equation_direct(poly_system, varlist)

Returns a modified polynomial system with an additional random linear equation.
This tries to lower the dimension by 1, hopefully making the solution set finite.

# Arguments
- `poly_system`: The system of polynomial equations
- `varlist`: List of variables in the system

# Returns
- A new polynomial system with an additional random linear equation
"""
function add_random_linear_equation_direct(poly_system, varlist)
	# Get the number of variables
	n = length(varlist)

	# Generate random coefficients for the linear equation
	coeffs = rand(Float64, n)

	# Create the linear equation
	linear_equation = sum(coeffs[i] * varlist[i] for i in 1:n) - rand(Float64)

	# Add the new equation to the system
	new_poly_system = [poly_system; linear_equation]

	return new_poly_system
end


"""
	convert_to_hc_format(poly_system, varlist)

Convert a polynomial system (as Symbolics expressions) to a HomotopyContinuation.System
along with its variable list. This uses a lightweight string replacement strategy
via `hmcs(::String)` to construct ModelKit variables deterministically.
"""
function convert_to_hc_format(poly_system, varlist)
	# Convert expressions to strings and replace variable names with hmcs("name")
	string_target = string.(poly_system)

	# Sanitize variable names to be HC-friendly (alphanumeric and underscores)
	sanitized = sanitize_vars(varlist)

	# Build mapping from original variable string to hmcs("sanitized_name") placeholder
	variable_string_mapping = Dict{String, String}()
	for (i, v) in enumerate(varlist)
		orig_name = string(v)
		sanitized_name = sanitized[i]
		variable_string_mapping[orig_name] = "hmcs(\"" * sanitized_name * "\")"
	end

	# Apply textual replacement so parsed expressions call hmcs(...) for variables
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], variable_string_mapping...)
	end

	# Parse and eval into HC expressions; hmcs returns ModelKit.Variable
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)

	# Build variables list in the same order as varlist for consistent output
	hc_variables = [HomotopyContinuation.ModelKit.Variable(Symbol(sanitized[i])) for i in eachindex(varlist)]

	# Construct the system (variables are provided to preserve ordering)
	hc_system = HomotopyContinuation.System(parsed, variables = hc_variables)

	return hc_system, hc_variables
end


"""
	solve_with_hc(poly_system, varlist; options=Dict(), use_monodromy=false, display_system=false)

Solve a square polynomial system using HomotopyContinuation.jl. Returns the same
tuple layout as other solvers: (solutions, hcvarlist, trivial_dict, trimmed_varlist).
Solutions are vectors of Float64 in the order of `varlist`.
"""
function solve_with_hc(poly_system, varlist; options = Dict(), use_monodromy = false, display_system = false)
	try
		# Convert to HC format
		hc_system, hc_variables = convert_to_hc_format(poly_system, varlist)

		if display_system
			println("[HC] Solving system with $(length(poly_system)) equations and $(length(varlist)) variables")
			println("[HC] System to be solved:")
			println(hc_system)
		end

		# Solve (prefer real solutions first)
		res = HomotopyContinuation.solve(hc_system, show_progress = false)
		sols = HomotopyContinuation.solutions(res, only_real = true, real_tol = 1e-9)

		# If no real solutions, allow complex and project to real parts
		if isempty(sols)
			sols = HomotopyContinuation.solutions(res)
		end

		# Map solutions to plain Float64 vectors in the same order as varlist
		solutions = Vector{Vector{Float64}}()
		for s in sols
			vals = Float64[real(s[j]) for j in 1:length(hc_variables)]
			push!(solutions, vals)
		end

		return solutions, varlist, Dict(), varlist
	catch e
		@warn "solve_with_hc failed: $e"
		return [], varlist, Dict(), varlist
	end
end

function solve_with_rs(poly_system, varlist;
	start_point = nothing,  # Not used but kept for interface consistency
	options = Dict(),
	_recursion_depth = 0, digits = 10)

	# Extract debug options with defaults
	debug_solver = get(options, :debug_solver, false)
	debug_cas_diagnostics = get(options, :debug_cas_diagnostics, false)
	debug_dimensional_analysis = get(options, :debug_dimensional_analysis, false)

	@debug "solve_with_rs: Starting with system:" equations=length(poly_system) variables=length(varlist) recursion_depth=_recursion_depth digits=digits start_point=start_point options=options
	if debug_solver || get(ENV, "ODEPE_DEEP_DEBUG", "false") == "true"
		println("solve_with_rs: System equations:")
		for eq in poly_system
			println("\t", eq)
		end
		println("Variables: ", varlist)
	end

	if _recursion_depth > 5
		@warn "solve_with_rs: Maximum recursion depth exceeded. System may have no solutions."
		return [], varlist, Dict(), varlist
	end

	# Add comprehensive dimensional analysis for debugging
	if debug_dimensional_analysis && length(poly_system) == length(varlist) && length(poly_system) >= 20
		@warn "[DEBUG-ODEPE] === DIMENSIONAL ANALYSIS ($(length(poly_system))x$(length(varlist)) system) ==="
		try
			# Analyze variable participation
			var_participation = Dict()
			for v in varlist
				count = 0
				for eq in poly_system
					if occursin(string(v), string(eq))
						count += 1
					end
				end
				var_participation[v] = count
			end

			# Find weakly constrained variables
			weakly_constrained = []
			for (v, count) in var_participation
				if count <= 3
					push!(weakly_constrained, (v, count))
				end
			end

			if !isempty(weakly_constrained)
				@warn "[DEBUG-ODEPE] Potentially unconstrained variables:"
				for (v, count) in sort(weakly_constrained, by = x->x[2])
					@warn "[DEBUG-ODEPE]   $v appears in $count equations"
				end
			end

			# Count equation patterns
			unique_var_sets = Set()
			for eq in poly_system
				vars_in_eq = Set()
				for v in varlist
					if occursin(string(v), string(eq))
						push!(vars_in_eq, v)
					end
				end
				push!(unique_var_sets, vars_in_eq)
			end
			@warn "[DEBUG-ODEPE] Unique variable patterns in equations: $(length(unique_var_sets))"

			# Check for decoupled subsystems
			coupled_groups = []
			for v1 in varlist
				group = Set([v1])
				for eq in poly_system
					if occursin(string(v1), string(eq))
						for v2 in varlist
							if v2 != v1 && occursin(string(v2), string(eq))
								push!(group, v2)
							end
						end
					end
				end
				push!(coupled_groups, group)
			end

			# Find minimal coupled groups
			unique_groups = unique(coupled_groups)
			if length(unique_groups) > 1
				@warn "[DEBUG-ODEPE] Found $(length(unique_groups)) potentially decoupled variable groups"
			end

		catch e
			@warn "[DEBUG-ODEPE] Dimensional analysis error: $e"
		end
		@warn "[DEBUG-ODEPE] ================================"
	end

	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist, digits; debug_aa = debug_cas_diagnostics)

	if debug_solver
		println("\n[DEBUG-SOLVER] Polynomial ring and system created")
		println("[DEBUG-SOLVER] Ring: ", R)
		println("[DEBUG-SOLVER] Ring type: ", typeof(R))
		println("[DEBUG-SOLVER] Number of generators: ", length(gens(R)))
		println("[DEBUG-SOLVER] AA system has ", length(aa_system), " polynomials")
		println("[DEBUG-SOLVER] AA system type: ", typeof(aa_system))
		if !isempty(aa_system)
			println("[DEBUG-SOLVER] First poly in aa_system type: ", typeof(aa_system[1]))
			# Check if it's the right type
			if !(aa_system[1] isa elem_type(R))
				println("[DEBUG-SOLVER] WARNING: Polynomial type mismatch!")
				println("[DEBUG-SOLVER]   Expected: ", elem_type(R))
				println("[DEBUG-SOLVER]   Got: ", typeof(aa_system[1]))
			end
		end
	end

	# --- Algebraic Diagnostics ---
	if debug_cas_diagnostics
		println("[DEBUG-SOLVER] Running algebraic diagnostics...")
	end

	# Step 1: Unwrap Num wrappers to get raw symbolic expressions
	unwrapped_system = Symbolics.value.(poly_system)

	# Step 2: Convert all floats in the unwrapped expressions to Rationals
	rationalized_system = [round_floats(p, digits) for p in unwrapped_system]

	# Step 3: Sanitize variable names for the CAS
	sanitized = sanitize_vars(varlist)

	# Oscar diagnostics
	if debug_cas_diagnostics
		try
			println("\n[DEBUG-SOLVER] --- Oscar Diagnostics ---")
			Rosc, ovars = Oscar.polynomial_ring(Oscar.QQ, sanitized)
			sub_dict_osc = Dict(varlist[i] => ovars[i] for i in eachindex(varlist))
			opolys = [Symbolics.value(Symbolics.substitute(p, sub_dict_osc)) for p in rationalized_system]
			Iosc = Oscar.ideal(Rosc, opolys...)
			Gosc = Oscar.groebner_basis(Iosc)
			println("[DEBUG-SOLVER] Oscar GB computed, length: ", length(Oscar.gens(Gosc)))
			is_inconsistent_osc = (length(Oscar.gens(Gosc)) == 1 && string(Oscar.gens(Gosc)[1]) == "1")
			if is_inconsistent_osc
				println("[DEBUG-SOLVER] *** Oscar: Groebner basis is {1} - system inconsistent ***")
			else
				dim_val_osc = Oscar.dim(Iosc)
				println("[DEBUG-SOLVER] Oscar reported dimension: ", dim_val_osc)
			end
		catch e
			println("[WARN-SOLVER] Oscar diagnostics failed: ", e)
		end
	end

	# Singular diagnostics
	if debug_cas_diagnostics
		try
			println("\n[DEBUG-SOLVER] --- Singular Diagnostics ---")
			Rsing, svars = Singular.polynomial_ring(Nemo.QQ, sanitized)
			sub_dict_sing = Dict(varlist[i] => svars[i] for i in eachindex(varlist))
			spolys = [Symbolics.value(Symbolics.substitute(p, sub_dict_sing)) for p in rationalized_system]
			Ising = Singular.Ideal(Rsing, spolys...)
			Gsing = Singular.std(Ising)
			println("[DEBUG-SOLVER] Singular GB computed, length: ", length(Singular.gens(Gsing)))
			is_inconsistent_sing = (length(Singular.gens(Gsing)) == 1 && string(Singular.gens(Gsing)[1]) == "1")
			if is_inconsistent_sing
				println("[DEBUG-SOLVER] *** Singular: Groebner basis is {1} - system inconsistent ***")
			else
				dim_val_sing = Singular.dimension(Gsing)
				println("[DEBUG-SOLVER] Singular reported dimension: ", dim_val_sing)
			end
		catch e
			println("[WARN-SOLVER] Singular diagnostics failed: ", e)
		end
	end

	# Groebner.jl diagnostics
	if debug_cas_diagnostics
		try
			println("\n[DEBUG-SOLVER] --- Groebner.jl Diagnostics ---")
			# Create a temporary module to define the polynomial variables in
			dp_mod = Module()
			Core.eval(dp_mod, :(using DynamicPolynomials))
			polyvar_expr = Meta.parse("@polyvar " * join(sanitized, " "))
			Core.eval(dp_mod, polyvar_expr)

			sub_dict_dp = Core.eval(dp_mod, :(Dict($(varlist[1]) => $(Symbol(sanitized[1])))))
			for i in 2:length(varlist)
				sub_dict_dp[varlist[i]] = Core.eval(dp_mod, Symbol(sanitized[i]))
			end

			dpolys_any = [Symbolics.value(Symbolics.substitute(p, sub_dict_dp)) for p in rationalized_system]

			# Ensure the vector has a concrete type for Groebner.jl
			if !isempty(dpolys_any)
				T = typeof(dpolys_any[1])
				dpolys = Vector{T}(dpolys_any)
				gb = Groebner.groebner(dpolys)
				println("[DEBUG-SOLVER] Groebner.jl GB computed, length: ", length(gb))
			else
				println("[DEBUG-SOLVER] Groebner.jl: No polynomials to process.")
			end
		catch e
			println("[WARN-SOLVER] Groebner.jl diagnostics failed: ", e)
		end
	end

	# Compute RUR and get separating element
	if debug_solver
		println("\n[DEBUG-SOLVER] Computing RUR (Rational Univariate Representation)...")
	end
	try
		rur, sep = zdim_parameterization(aa_system, get_separating_element = true)

		# Find solutions
		output_precision = get(options, :output_precision, Int32(20))
		sol = RS.rs_isolate(rur, sep, output_precision = output_precision)

		# Convert solutions back to our format
		solutions = []
		for s in sol
			# Extract real solutions
			#display(s)
			real_sol = [convert(Float64, real(v[1])) for v in s]
			push!(solutions, real_sol)
		end
		@debug "RAW SOLVER SOLUTIONS from solve_with_rs" num_solutions=length(solutions) varlist=varlist solutions=solutions

		return solutions, varlist, Dict(), varlist
	catch e
		if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
			@warn "System is not zero-dimensional, needs reconstruction with higher derivative levels."

			# Try to extract dimension information from error message
			error_msg = string(e)
			dim_match = match(r"(\d+)-dimensional", error_msg)
			if dim_match !== nothing
				dim = parse(Int, dim_match[1])
				@warn "[DEBUG-ODEPE] System has dimension $dim (expected 0)"

				# Analyze which variables might be unconstrained
				if length(poly_system) == length(varlist)
					@warn "[DEBUG-ODEPE] Square system ($(length(poly_system))x$(length(varlist))) but $dim-dimensional"
					@warn "[DEBUG-ODEPE] This suggests $dim variables are algebraically unconstrained"

					# Try to identify which variables are likely free
					if dim <= 5  # Only for small dimensions
						@warn "[DEBUG-ODEPE] Analyzing variable constraints to identify free parameters..."

						# Count how many equations each variable appears in
						var_counts = Dict()
						for v in varlist
							count = 0
							for eq in poly_system
								if occursin(string(v), string(eq))
									count += 1
								end
							end
							var_counts[v] = count
						end

						# Sort by participation count
						sorted_vars = sort(collect(var_counts), by = x->x[2])
						@warn "[DEBUG-ODEPE] Variables by equation participation (lowest first):"
						for (v, count) in sorted_vars[1:min(dim+2, length(sorted_vars))]
							@warn "[DEBUG-ODEPE]   $v: appears in $count equations"
						end

						# The variables with lowest participation are likely free
						likely_free = [v for (v, c) in sorted_vars[1:min(dim, length(sorted_vars))]]
						@warn "[DEBUG-ODEPE] Most likely free variables: $likely_free"
					end
				end
			end

			# Return special status indicating reconstruction is needed
			# Format: (status_symbol, empty_solutions, empty_dict, varlist)
			return :needs_reconstruction, varlist, Dict(), varlist
		else
			@warn "solve_with_rs failed: $e"
			return [], varlist, Dict(), varlist
		end
	end
end


"""
	save_poly_system(filepath, poly_system, varlist;
					 param_map=nothing, pep=nothing, metadata=nothing)

Saves a polynomial system and its variables to a file as Julia code.

# Arguments
- `filepath`: Path to save the file.
- `poly_system`: The polynomial system (an array of symbolic expressions).
- `varlist`: The list of symbolic variables.
- `param_map` (optional): A dictionary mapping parameter names to their estimated values.
- `pep` (optional): The `ParameterEstimationProblem` object.
- `metadata` (optional): A dictionary for any other metadata to save.
"""
function save_poly_system(filepath, poly_system, varlist;
	param_map = nothing, pep = nothing, metadata = nothing)
	open(filepath, "w") do f
		# Write header
		write(f, "# Polynomial system saved on $(now())\n")
		if !isnothing(pep)
			write(f, "# Original problem: $(pep.name)\n")
		end
		write(f, "using Symbolics\n")
		write(f, "using StaticArrays\n\n")

		# Write metadata
		if !isnothing(metadata)
			write(f, "# Metadata\n")
			for (key, value) in metadata
				write(f, "# $key: $value\n")
			end
			write(f, "\n")
		end

		# Write varlist
		write(f, "# Variables\n")
		write(f, "varlist_str = \"\"\"\n$(join(varlist, "\n"))\n\"\"\"\n")
		write(f, "@variables ")
		for (i, var) in enumerate(varlist)
			write(f, string(var))
			if i < length(varlist)
				write(f, " ")
			end
		end
		write(f, "\n")
		write(f, "varlist = [$([Symbol(v) for v in varlist]...)]\n\n")


		# Write polynomial system
		write(f, "# Polynomial System\n")
		write(f, "poly_system = [\n")
		for (i, poly) in enumerate(poly_system)
			# Use repr to get a string representation that can be parsed back
			poly_str = repr(poly)
			write(f, "    $poly_str")
			if i < length(poly_system)
				write(f, ",\n")
			end
		end
		write(f, "\n]\n\n")

		# Write param_map if available
		if !isnothing(param_map)
			write(f, "# Parameter Map\n")
			write(f, "param_map = Dict(\n")
			for (param, val) in param_map
				write(f, "    Symbol(\"$param\") => $val,\n")
			end
			write(f, ")\n\n")
		end

		# Write PEP if available
		if !isnothing(pep)
			# This is a bit tricky, we might just save the name and key fields
			write(f, "# Original Problem Info\n")
			write(f, "problem_name = \"$(pep.name)\"\n")
			# You might need to reconstruct the PEP object manually if needed
		end
	end
end

"""
	load_poly_system(filepath)

Loads a polynomial system from a Julia source file.

# Arguments
- `filepath`: Path to the file to load.

# Returns
A tuple containing:
- `poly_system`: The loaded polynomial system.
- `varlist`: The list of variables.
"""
function load_poly_system(filepath)
	# The file is expected to define `poly_system` and `varlist`
	loaded_module = @eval Module() begin
		include($filepath)
		(poly_system, varlist)
	end
	return loaded_module
end



#=
function solve_with_rs_old(poly_system, varlist;
						start_point = nothing,
						polish_solutions = true,
						debug = false,
						verify_solutions = true,
						is_augmented_system = false)  # New parameter to track if system was augmented

	if debug
		println("DEBUG [solve_with_rs]: Starting with system:")
		for eq in poly_system
			println("\t", eq)
		end
		println("Variables: ", varlist)
	end

	# Convert symbolic expressions to AA polynomials using existing infrastructure
	R, aa_system = exprs_to_AA_polys(poly_system, varlist, 10)  # Use default digits=10

	if debug
		println("DEBUG [solve_with_rs]: Abstract Algebra system:")
		for eq in aa_system
			println("\t", eq)
		end
	end

	# Round coefficients to improve numerical stability
	sys_toround = deepcopy(aa_system)
	sys_rounded = map(f -> map_coefficients(c -> rationalize(BigInt, round(BigFloat(c), digits = 5)), f), sys_toround)

	solutions = []

	# Try to compute RUR with fallback to adding a random linear equation
	try
		# Compute RUR and get separating element
		if debug
			println("DEBUG [solve_with_rs]: Computing RUR...")
		end

		rur, sep = zdim_parameterization(sys_rounded, get_separating_element = true)

		if debug
			println("DEBUG [solve_with_rs]: Got RUR, separating element: ", sep)
		end

		# Find solutions using PolynomialRoots instead of RS
		tosolve = rur[1]
		roots_found = solve_rur_complex(tosolve)

		if debug
			println("DEBUG [solve_with_rs]: Found roots: ", roots_found)
		end

		# Convert variables to symbols for RUR substitution
		var_symbols = [Symbol(v) for v in varlist]

		# Process solutions with more careful handling of the root
		for v_val in roots_found
			if debug
				println("DEBUG [solve_with_rs]: Processing root v_val = ", v_val)
			end

			sol_dict = evaluate_rur_subs(rur, v_val, var_symbols)

			# Extract solution values in original variable order
			sol_vector = []
			for v in varlist
				val = get(sol_dict, Symbol(v), nothing)
				if isnothing(val)
					# If this variable isn't in the RUR substitutions, check if it's the root variable
					if Symbol(v) == Symbol(sep) # Compare against the separating element found during RUR computation
						val = v_val
					else
						# For any other missing variables, use 0.0 as fallback
						val = 0.0
					end
				end
				push!(sol_vector, real(val)) # Store real part only
			end

			if debug
				println("DEBUG [solve_with_rs]: Solution vector: ", sol_vector)
			end

			push!(solutions, sol_vector)
		end
	catch e
		if debug
			println("DEBUG [solve_with_rs]: Caught exception: ", e)
		end

		if isa(e, DomainError) && occursin("zerodimensional ideal", string(e))
			if debug
				println("DEBUG [solve_with_rs_old]: System is not zero-dimensional, needs reconstruction")
			end

			# Return special status indicating reconstruction is needed
			# Random hyperplane addition has been disabled in favor of systematic derivative level increases
			return :needs_reconstruction, varlist, Dict(), varlist
		else
			if debug
				println("DEBUG [solve_with_rs]: Unhandled exception: ", e)
				println("DEBUG [solve_with_rs]: Solution method failed, no fallback available")
			end
			# Return empty solutions since the method failed
			return [], varlist, Dict(), varlist
		end
	end

	# Verify all found solutions against the original system
	if verify_solutions && !isempty(solutions)
		verified_solutions = []
		for sol in solutions
			all_valid = true

			# Determine which equations to verify against
			verification_system = if is_augmented_system
				# If we know this is an augmented system, only verify against original equations
				# The last equation is the random one we added
				poly_system[1:end-1]
			else
				poly_system
			end

			for eq in verification_system
				subst_dict = Dict([v => sol[i] for (i, v) in enumerate(varlist)])
				residual = abs(Symbolics.value(Symbolics.substitute(eq, subst_dict)))

				if debug
					println("DEBUG [solve_with_rs]: For solution ", sol)
					println("\tEquation: ", eq)
					println("\tResidual: ", residual)
				end

				if residual > 1e-8
					all_valid = false
					break
				end
			end

			if all_valid
				push!(verified_solutions, sol)
			else
				if debug
					println("DEBUG [solve_with_rs]: Solution failed verification: ", sol)
				end
			end
		end

		solutions = verified_solutions
	end

	# Polish solutions if requested
	if polish_solutions && !isempty(solutions)
		polished_solutions = []
		for sol in solutions
			# Extract real part as starting point for polishing
			start_pt = real.(sol)

			if debug
				println("DEBUG [solve_with_rs]: Polishing solution: ", start_pt)
			end

			# Polish the solution
			polished_sol, _, _, _ = solve_with_nlopt(poly_system, varlist,
													start_point = start_pt,
													polish_only = true,
													options = Dict(:abstol => 1e-12, :reltol => 1e-12))

			# If polishing succeeded, add polished solution to list
			if !isempty(polished_sol)
				push!(polished_solutions, polished_sol[1])

				if debug
					println("DEBUG [solve_with_rs]: Polished solution: ", polished_sol[1])
				end
			else
				push!(polished_solutions, sol)

				if debug
					println("DEBUG [solve_with_rs]: Polishing failed, keeping original solution")
				end
			end
		end
		solutions = polished_solutions
	end

	if debug
		println("DEBUG [solve_with_rs]: Final solutions: ", solutions)
	end

	return solutions, varlist, Dict(), varlist
end
=#
