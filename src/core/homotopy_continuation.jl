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

	# Try to compile the system into a fast native function; fall back to substitute/value
	compiled_residual! = nothing
	try
		_f_oop, _f_ip = Symbolics.build_function(prepared_system, mangled_varlist;
			expression = Val(false))
		compiled_residual! = (res, u, p) -> (_f_ip(res, u); nothing)
	catch err
		@warn "build_function failed in solve_with_nlopt; falling back to substitute/value" err
	end

	# Define residual function for NonlinearLeastSquares (AD-safe; no Float64 forcing)
	res_evals_nlopt = Ref(0)
	function residual!(res, u, p)
		res_evals_nlopt[] += 1
		if compiled_residual! !== nothing
			compiled_residual!(res, u, p)
		else
			d = Dict{Num, eltype(u)}(zip(mangled_varlist, u))
			for (i, eq) in enumerate(prepared_system)
				val = Symbolics.value(Symbolics.substitute(eq, d))
				res[i] = convert(eltype(u), val)
			end
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

	# Try to compile the system into a fast native function; fall back to substitute/value
	compiled_residual_quick! = nothing
	try
		_f_oop, _f_ip = Symbolics.build_function(prepared_system, mangled_varlist;
			expression = Val(false))
		compiled_residual_quick! = (res, u, p) -> (_f_ip(res, u); nothing)
	catch err
		@warn "build_function failed in solve_with_nlopt_quick; falling back to substitute/value" err
	end

	# Define residual function for NonlinearLeastSquares (AD-safe)
	res_evals_nlopt_quick = Ref(0)
	function residual!(res, u, p)
		res_evals_nlopt_quick[] += 1
		if compiled_residual_quick! !== nothing
			compiled_residual_quick!(res, u, p)
		else
			d = Dict{Num, eltype(u)}(zip(mangled_varlist, u))
			for (i, eq) in enumerate(prepared_system)
				val = Symbolics.value(Symbolics.substitute(eq, d))
				res[i] = convert(eltype(u), val)
			end
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

	# Try to compile the system into a fast native function; fall back to substitute/value
	compiled_residual_fast! = nothing
	try
		_f_oop, _f_ip = Symbolics.build_function(prepared_system, mangled_varlist;
			expression = Val(false))
		compiled_residual_fast! = (res, u, p) -> (_f_ip(res, u); nothing)
	catch err
		@warn "build_function failed in solve_with_fast_nlopt; falling back to substitute/value" err
	end

	eval_count = Ref(0)
	function residual!(res, u, p)
		eval_count[] += 1
		if compiled_residual_fast! !== nothing
			compiled_residual_fast!(res, u, p)
		else
			d = Dict{Num, eltype(u)}(zip(mangled_varlist, u))
			for i in 1:m
				res[i] = Symbolics.value(Symbolics.substitute(prepared_system[i], d))
			end
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
		" (compiled=", compiled_residual_fast! !== nothing,
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



# ============================================================================
# Parameter Homotopy Functions
# ============================================================================

"""
	convert_to_hc_format_with_params(poly_system, solve_vars, data_vars)

Convert a polynomial system to HomotopyContinuation.System with both variables and parameters.

# Arguments
- `poly_system`: System of polynomial equations (Symbolics expressions)
- `solve_vars`: Variables to solve for (unknowns - parameters and states)
- `data_vars`: Variables that become HC parameters (interpolated observable values)

# Returns
- `hc_system`: HomotopyContinuation.System with parameters
- `hc_variables`: HC variable list (corresponding to solve_vars)
- `hc_params`: HC parameter list (corresponding to data_vars)
"""
function convert_to_hc_format_with_params(poly_system, solve_vars, data_vars)
	# Convert expressions to strings
	string_target = string.(poly_system)

	# Sanitize variable names (both solve_vars and data_vars)
	sanitized_solve = sanitize_vars(solve_vars)
	sanitized_data = sanitize_vars(data_vars)

	# Build mapping from original variable string to hmcs("sanitized_name") placeholder
	variable_string_mapping = Dict{String, String}()

	# Map solve variables
	for (i, v) in enumerate(solve_vars)
		orig_name = string(v)
		sanitized_name = sanitized_solve[i]
		variable_string_mapping[orig_name] = "hmcs(\"" * sanitized_name * "\")"
	end

	# Map data variables (parameters in HC)
	for (i, v) in enumerate(data_vars)
		orig_name = string(v)
		sanitized_name = sanitized_data[i]
		variable_string_mapping[orig_name] = "hmcs(\"p_" * sanitized_name * "\")"
	end

	# Apply textual replacement
	for i in eachindex(string_target)
		string_target[i] = replace(string_target[i], variable_string_mapping...)
	end

	# Parse and eval into HC expressions
	parsed = eval.(Meta.parse.(string_target))
	HomotopyContinuation.set_default_compile(:all)

	# Build variables list in the same order as solve_vars
	hc_variables = [HomotopyContinuation.ModelKit.Variable(Symbol(sanitized_solve[i])) for i in eachindex(solve_vars)]

	# Build parameters list in the same order as data_vars (with p_ prefix)
	hc_params = [HomotopyContinuation.ModelKit.Variable(Symbol("p_" * sanitized_data[i])) for i in eachindex(data_vars)]

	# Construct the parameterized system
	hc_system = HomotopyContinuation.System(parsed, variables = hc_variables, parameters = hc_params)

	return hc_system, hc_variables, hc_params
end

"""
	solve_with_hc_parameterized(poly_system, solve_vars, data_vars, param_values_list; options=Dict())

Solve a polynomial system at multiple parameter values using parameter homotopy.

This function provides significant speedup when solving the same polynomial structure
at multiple shooting points, as it tracks existing solutions instead of computing
fresh start systems for each point.

# Arguments
- `poly_system`: Symbolic equations (structure fixed, coefficients vary)
- `solve_vars`: Variables to solve for (parameters and states)
- `data_vars`: Variables that become HC parameters (interpolated observables like y1(t), y1'(t))
- `param_values_list`: Vector of parameter value vectors, one per shooting point

# Keyword Arguments
- `options::Dict`: Solver options (e.g., :show_progress, :real_tol)

# Returns
Vector of vectors of real solutions, one per shooting point.

# Algorithm
1. First point: Fresh solve with HC.solve(), collect ALL solutions (real + complex)
2. Subsequent points: Parameter homotopy tracking ALL solutions from previous point
3. At each point: Filter to real solutions for output
4. Track ALL solutions to next point (solutions can transition between real/complex)

# Fallback
If parameter homotopy tracking loses solutions, falls back to fresh solve at that point
and emits a warning.
"""
function solve_with_hc_parameterized(poly_system, solve_vars, data_vars, param_values_list; options = Dict())
	# Convert to HC format with parameters
	hc_system, hc_variables, hc_params = convert_to_hc_format_with_params(
		poly_system, solve_vars, data_vars
	)

	# Get options
	show_progress = get(options, :show_progress, false)
	real_tol = get(options, :real_tol, 1e-9)
	debug = get(options, :debug, false)

	all_real_results = Vector{Vector{Vector{Float64}}}()
	prev_all_solutions = nothing  # Track ALL solutions (real + complex)
	prev_params = nothing
	initial_solution_count = 0

	for (i, current_params) in enumerate(param_values_list)
		if i == 1 || isnothing(prev_all_solutions) || isempty(prev_all_solutions)
			# Fresh solve at first point - get ALL solutions
			if debug
				println("[HC-PARAM] Point $i: Fresh solve with $(length(current_params)) parameters")
			end

			result = HomotopyContinuation.solve(hc_system;
				target_parameters = current_params,
				show_progress = show_progress)

			all_solutions = HomotopyContinuation.solutions(result)  # ALL, not just real
			initial_solution_count = length(all_solutions)

			if debug
				real_count = length(HomotopyContinuation.solutions(result, only_real = true, real_tol = real_tol))
				println("[HC-PARAM] Point $i: Fresh solve found $(length(all_solutions)) total solutions ($real_count real)")
			end
		else
			# Parameter homotopy from previous point - track ALL solutions
			if debug
				println("[HC-PARAM] Point $i: Parameter homotopy tracking $(length(prev_all_solutions)) solutions")
			end

			result = HomotopyContinuation.solve(hc_system, prev_all_solutions;
				start_parameters = prev_params,
				target_parameters = current_params,
				show_progress = show_progress)

			all_solutions = HomotopyContinuation.solutions(result)

			# Check if tracking lost significant solutions
			if length(all_solutions) < length(prev_all_solutions) * 0.9  # Lost more than 10%
				@warn "Parameter homotopy: solution count dropped from $(length(prev_all_solutions)) to $(length(all_solutions)) at point $i. Falling back to fresh solve."

				# Fresh solve fallback
				result = HomotopyContinuation.solve(hc_system;
					target_parameters = current_params,
					show_progress = show_progress)
				all_solutions = HomotopyContinuation.solutions(result)

				if debug
					println("[HC-PARAM] Point $i: Fallback fresh solve found $(length(all_solutions)) solutions")
				end
			elseif debug
				real_count = length(HomotopyContinuation.solutions(result, only_real = true, real_tol = real_tol))
				println("[HC-PARAM] Point $i: Tracked $(length(all_solutions)) solutions ($real_count real)")
			end
		end

		# Filter for REAL solutions at this point (for output)
		real_solutions_hc = HomotopyContinuation.solutions(result, only_real = true, real_tol = real_tol)

		# Convert to Float64 vectors
		real_solutions = Vector{Vector{Float64}}()
		for s in real_solutions_hc
			vals = Float64[real(s[j]) for j in 1:length(hc_variables)]
			push!(real_solutions, vals)
		end
		push!(all_real_results, real_solutions)

		# Track ALL solutions to next point (real + complex)
		prev_all_solutions = all_solutions
		prev_params = current_params
	end

	return all_real_results
end

"""
	extract_data_variables_from_DD(DD::DerivativeData)

Extract all observable derivative variables from the DerivativeData structure.
These are the variables that should become HC parameters in parameter homotopy.

# Returns
Vector of Symbolics variables representing y_i^(j) for all observables and derivative levels.
"""
function extract_data_variables_from_DD(DD)
	data_vars = Vector{Any}()

	if isnothing(DD)
		return data_vars
	end

	# DD.obs_lhs[level+1][obs_idx] gives the variable for derivative level of observable obs_idx
	for level_vars in DD.obs_lhs
		for v in level_vars
			push!(data_vars, v)
		end
	end

	return data_vars
end

"""
	evaluate_data_vars_at_point(interpolants, data_vars, DD, measured_quantities, t_point)

Evaluate all data variables (observable derivatives) at a specific time point.

# Arguments
- `interpolants`: Dict mapping observable RHS to interpolation functions
- `data_vars`: Vector of data variables (from extract_data_variables_from_DD)
- `DD`: DerivativeData structure containing obs_lhs mapping
- `measured_quantities`: Vector of measured quantity equations
- `t_point`: Time point at which to evaluate

# Returns
Vector of Float64 values corresponding to data_vars order.
"""
function evaluate_data_vars_at_point(interpolants, data_vars, DD, measured_quantities, t_point)
	values = Vector{Float64}()

	# Build a mapping from data_var -> (obs_idx, deriv_level)
	var_to_obs = Dict{Any, Tuple{Int, Int}}()
	for (level_idx, level_vars) in enumerate(DD.obs_lhs)
		deriv_level = level_idx - 1  # 0-indexed derivative level
		for (obs_idx, v) in enumerate(level_vars)
			var_to_obs[v] = (obs_idx, deriv_level)
		end
	end

	for v in data_vars
		if haskey(var_to_obs, v)
			obs_idx, deriv_level = var_to_obs[v]

			# Get the interpolant for this observable
			obs_rhs = ModelingToolkit.diff2term(measured_quantities[obs_idx].rhs)

			if haskey(interpolants, obs_rhs)
				interp_func = interpolants[obs_rhs]
				val = nth_deriv(x -> interp_func(x), deriv_level, t_point)
				push!(values, Float64(val))
			else
				# Try with wrapped LHS
				obs_lhs_wrapped = Symbolics.wrap(measured_quantities[obs_idx].lhs)
				if haskey(interpolants, obs_lhs_wrapped)
					interp_func = interpolants[obs_lhs_wrapped]
					val = nth_deriv(x -> interp_func(x), deriv_level, t_point)
					push!(values, Float64(val))
				else
					@warn "No interpolant found for observable $obs_idx at derivative level $deriv_level"
					push!(values, 0.0)
				end
			end
		else
			@warn "Data variable $v not found in DD.obs_lhs mapping"
			push!(values, 0.0)
		end
	end

	return values
end
