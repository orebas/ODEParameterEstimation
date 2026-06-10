# Archived 2026-06-10 from src/core/homotopy_continuation.jl — NOT part of the build.
# Experimental NLopt-style NLLS solver variants superseded by solve_with_nlopt /
# solve_with_fast_nlopt (the two enum-reachable ones). These were exported but only
# referenced by benchmark example scripts; reference only.
# ============================================================================

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
