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

	# Debug controls
	debug = get(options, :debug, false)
	jac_mode = get(options, :jacobian, :none)

	# Define residual function for NonlinearLeastSquares (AD-safe; no Float64 forcing)
	res_evals_nlopt = Ref(0)
	function residual!(res, u, p)
		res_evals_nlopt[] += 1
		d = Dict(zip(mangled_varlist, u))
		for (i, eq) in enumerate(prepared_system)
			val = Symbolics.value(Symbolics.substitute(eq, d))
			res[i] = convert(eltype(u), val)
		end
		return nothing
	end

	# Set up optimization problem
	n = length(varlist)
	m = length(prepared_system)  # Number of equations
	x0 = if isnothing(start_point)
		randn(n)  # Random initialization if no start point provided
	else
		start_point
	end

	# Debug pre-solve
	if debug
		println("[NLOPT] equations=", m, " variables=", n)
		println("[NLOPT] optimizer=", typeof(optimizer))
		println("[NLOPT] jacobian_mode=", jac_mode)
		println("[NLOPT] eltype(x0)=", eltype(x0))
	end

	# Calculate initial residual
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = norm(initial_residual)

	# Create NonlinearLeastSquaresProblem
	prob = NonlinearLeastSquaresProblem(
		NonlinearFunction(residual!),
		x0,
		nothing,
	)

	# Set solver options based on polish_only
	solver_opts = if polish_only
		(abstol = 1e-12, reltol = 1e-12, maxiters = 1000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end

	# Merge with user options (only recognized keywords)
	user_opts = Dict{Symbol, Any}()
	for (k, v) in options
		if k in (:abstol, :reltol, :maxiters)
			user_opts[k] = v
		end
	end
	solver_opts = merge(solver_opts, user_opts)

	# Solve the problem with exception handling
	sol = try
		NonlinearSolve.solve(prob, optimizer; solver_opts...)
	catch e
		@error "solve_with_nlopt failed" exception=(e, catch_backtrace())
		println("SOLVER_ERROR: NonlinearSolve optimization threw exception:")
		println("  Type: ", typeof(e))
		println("  Message: ", e)
		bt = catch_backtrace()
		st = stacktrace(bt)
		for (i, frame) in enumerate(st[1:min(5, length(st))])
			println("  [$i] ", frame)
		end
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

	# Debug and Jacobian configuration
	debug = get(options, :debug, false)
	jac_mode = get(options, :jacobian, :none)

	# Define residual function for NonlinearLeastSquares (AD-safe)
	res_evals_nlopt_quick = Ref(0)
	function residual!(res, u, p)
		res_evals_nlopt_quick[] += 1
		d = Dict(zip(mangled_varlist, u))
		for (i, eq) in enumerate(prepared_system)
			val = Symbolics.value(Symbolics.substitute(eq, d))
			res[i] = convert(eltype(u), val)
		end
		return nothing
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
	nf = NonlinearFunction(residual!)
	prob = NonlinearLeastSquaresProblem(nf, x0, nothing)

	# Set solver options based on polish_only
	solver_opts = (abstol = 1e-3, reltol = 1e-3, maxiters = 50)

	# Merge with user options (only recognized keywords)
	user_opts = Dict{Symbol, Any}()
	for (k, v) in options
		if k in (:abstol, :reltol, :maxiters)
			user_opts[k] = v
		end
	end
	solver_opts = merge(solver_opts, user_opts)

	# Pre-solve debug
	if debug
		println("[NLOPT_quick] equations=", m, " variables=", n)
		println("[NLOPT_quick] optimizer=", typeof(optimizer))
		println("[NLOPT_quick] jacobian_mode=", jac_mode)
		println("[NLOPT_quick] eltype(x0)=", eltype(x0))
	end

	# Solve the problem (no additional fallbacks)
	callback = if debug
		(state, res) -> begin
			println("[NLOPT_quick Iter $(state.iter)] res_norm=$(state.fu_norm)")
			return false
		end
	else
		nothing
	end
	sol = NonlinearSolve.solve(prob, optimizer; callback = callback, solver_opts...)

	# Check if solution is valid
	if SciMLBase.successful_retcode(sol)
		# Calculate final residual
		final_residual = zeros(m)
		residual!(final_residual, sol.u, nothing)
		final_norm = norm(final_residual)

		improvement = initial_norm - final_norm
		if debug
			println("[NLOPT_quick] residual_norm initial=", initial_norm,
				" final=", final_norm,
				" improvement=", improvement,
				" res_evals=", res_evals_nlopt_quick[])
		end

		# Return all four expected values: solutions, variables, trivial_dict, trimmed_varlist
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	else
		if debug
			@warn "[NLOPT_quick] Optimization did not converge" retcode=sol.retcode res_evals=res_evals_nlopt_quick[]
		end
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


	println("solving in NLOPT_fast")

	# Prepare system for optimization
	prepared_system, mangled_varlist = (poly_system, varlist)
	m = length(prepared_system)
	n = length(mangled_varlist)

	# Always use fallback residual via Symbolics substitution (Dual-safe)
	eval_count = Ref(0)
	function residual!(res, u, p)
		eval_count[] += 1
		d = Dict(zip(mangled_varlist, u))
		for i in 1:m
			res[i] = Symbolics.value(Symbolics.substitute(prepared_system[i], d))
		end
		return nothing
	end

	# Initial guess and initial residual norm
	x0 = isnothing(start_point) ? randn(n) : copy(start_point)
	initial_residual = zeros(m)
	residual!(initial_residual, x0, nothing)
	initial_norm = LinearAlgebra.norm(initial_residual)

	# Jacobian via ForwardDiff over the residual (Dual-safe)
	function jacobian!(J, u, p)
		g(u_) = begin
			r = Vector{eltype(u_)}(undef, m)
			residual!(r, u_, nothing)
			r
		end
		ForwardDiff.jacobian!(J, g, u)
		return nothing
	end

	nf = NonlinearFunction(residual!; resid_prototype = zeros(m), jac = jacobian!)
	prob = NonlinearLeastSquaresProblem(nf, x0, nothing)

	# Solver options (filter to recognized keywords)
	solver_opts = if polish_only
		(abstol = 1e-10, reltol = 1e-10, maxiters = 2000)
	else
		(abstol = 1e-8, reltol = 1e-8, maxiters = 10000)
	end
	user_opts = Dict{Symbol, Any}()
	for (k, v) in options
		if k in (:abstol, :reltol, :maxiters)
			user_opts[k] = v
		end
	end
	solver_opts = merge(solver_opts, user_opts)

	# Solve (measure wall time)
	solve_ms = 0.0
	sol = try
		local t0 = time()
		local out = NonlinearSolve.solve(prob, optimizer; solver_opts...)
		solve_ms = (time() - t0) * 1000
		out
	catch e
		@error "solve_with_fast_nlopt failed" exception=(e, catch_backtrace())
		println("SOLVER_ERROR: solve_with_fast_nlopt threw exception:")
		println("  Type: ", typeof(e))
		println("  Message: ", e)
		bt = catch_backtrace()
		st = stacktrace(bt)
		for (i, frame) in enumerate(st[1:min(5, length(st))])
			println("  [$i] ", frame)
		end
		return [], mangled_varlist, Dict(), mangled_varlist
	end

	# Retry on MaxIters with a robust polyalgorithm
	if (!SciMLBase.successful_retcode(sol)) && (sol.retcode == SciMLBase.ReturnCode.MaxIters)
		@info "Fast NLLS hit MaxIters; retrying with FastShortcutNLLSPolyalg()"
		retry_opts = (abstol = 1e-10, reltol = 1e-10, maxiters = 5000)
		for (k, v) in options
			if k in (:abstol, :reltol, :maxiters)
				retry_opts = merge(retry_opts, (k => v,))
			end
		end
		try
			local t0 = time()
			sol = NonlinearSolve.solve(prob, NonlinearSolve.FastShortcutNLLSPolyalg(); retry_opts...)
			solve_ms += (time() - t0) * 1000
		catch e
			@error "solve_with_fast_nlopt retry failed" exception=(e, catch_backtrace())
			println("SOLVER_ERROR: solve_with_fast_nlopt retry threw exception:")
			println("  Type: ", typeof(e))
			println("  Message: ", e)
			bt = catch_backtrace()
			st = stacktrace(bt)
			for (i, frame) in enumerate(st[1:min(5, length(st))])
				println("  [$i] ", frame)
			end
		end
	end

	# Compute final residual norm regardless of convergence
	final_residual = zeros(m)
	try
		residual!(final_residual, sol.u, nothing)
	catch e
		@debug "Final residual evaluation failed, using initial residual" exception = e
		final_residual .= initial_residual
	end
	final_norm = LinearAlgebra.norm(final_residual)
	improvement = initial_norm - final_norm
	println("[NLOPT_fast] residual_norm initial=", initial_norm,
		" final=", final_norm,
		" improvement=", improvement,
		" (compiled=", false,
		" compile_ms=", 0.0,
		" solve_ms=", solve_ms,
		" evals=", eval_count[], ")")

	# If solver failed but improved significantly, accept the improvement as a polished point
	if (!SciMLBase.successful_retcode(sol)) && (improvement > 0)
		@warn "Optimization did not fully converge (RetCode=$(sol.retcode)) but improved residual by $(improvement). Returning best-so-far iterate."
		return [sol.u], mangled_varlist, Dict(), mangled_varlist
	end

	if SciMLBase.successful_retcode(sol)
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
				val = Symbolics.value(Symbolics.substitute(prepared_system[i], d))
				res[i] = convert(eltype(u), val)
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
	# Strip any keys we don't want to pass to the solver.
	user_pairs = filter(p -> first(p) in (:abstol, :reltol, :maxiters), collect(pairs(options)))
	user_named = (; user_pairs...)
	solver_opts = merge(solver_opts, user_named)

	# Algorithm: recommended polyalgorithm unless user supplied one.
	# FastShortcutNLLSPolyalg(): tries Gauss-Newton, falls back to LM/TrustRegion. :contentReference[oaicite:3]{index=3}
	alg = isnothing(optimizer) ? NonlinearSolve.FastShortcutNLLSPolyalg() : optimizer

	# Dense forward-mode AD is the safest default for problems of this size. :contentReference[oaicite:4]{index=4}
	# Solve (let NonlinearSolve pick AD default compatible with function)
	callback = if get(options, :debug, false)
		(state, res) -> begin
			println("[NLOPT_testing Iter $(state.iter)] res_norm=$(state.fu_norm)")
			return false
		end
	else
		nothing
	end
	sol = try
		NonlinearSolve.solve(prob, alg; callback = callback, solver_opts...)
	catch e
		@error "solve_with_nlopt_testing failed" exception=(e, catch_backtrace())
		println("SOLVER_ERROR: solve_with_nlopt_testing threw exception:")
		println("  Type: ", typeof(e))
		println("  Message: ", e)
		bt = catch_backtrace()
		st = stacktrace(bt)
		for (i, frame) in enumerate(st[1:min(5, length(st))])
			println("  [$i] ", frame)
		end
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
		@error "solve_with_hc failed" exception=(e, catch_backtrace())
		println("SOLVER_ERROR: HomotopyContinuation.solve threw exception:")
		println("  Type: ", typeof(e))
		println("  Message: ", e)
		# Print abbreviated stacktrace (first 5 frames)
		bt = catch_backtrace()
		st = stacktrace(bt)
		for (i, frame) in enumerate(st[1:min(5, length(st))])
			println("  [$i] ", frame)
		end
		return [], varlist, Dict(), varlist
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
		vars_str = join(string.(varlist), ", ")
		write(f, "varlist = [" * vars_str * "]\n\n")


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
=#
