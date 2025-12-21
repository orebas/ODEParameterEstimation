"""
	solve_with_robust(poly_system, varlist; kwargs...)

A robust polynomial system solver that uses the best algorithms from our benchmarking.
Supports both solving from scratch and polishing mode.

This is a plug-in replacement for `solve_with_nlopt` with improved robustness.

# Arguments
- `poly_system`: Vector of polynomial equations (Symbolics expressions)
- `varlist`: Vector of variables (Symbolics variables)

# Keywords
- `start_point=nothing`: Initial guess. If nothing, uses random or multistart
- `polish_only=false`: If true, only does quick local refinement
- `options=Dict()`: Additional options including:
  - `:debug => true/false`: Print debug information
  - `:jacobian => :symbolic/:forwarddiff/:finitediff/:none`: Jacobian method
  - `:abstol => 1e-8`: Absolute tolerance
  - `:reltol => 1e-6`: Relative tolerance
  - `:maxiters => 1000`: Maximum iterations
  - `:algorithm => :auto/:trustregion/:bfgs/:bobyqa/:levenberg`: Force specific algorithm
  - `:multistart => true/false`: Use multiple starting points
  - `:timeout => 30.0`: Maximum time in seconds

# Returns
Same format as solve_with_nlopt: (solutions, varmap, stats, varlist)
where solutions is a vector of solution dictionaries.
"""
function solve_with_robust(poly_system, varlist;
	start_point = nothing,
	polish_only = false,
	options = Dict())


	# Extract options
	debug = get(options, :debug, false)
	jac_mode = get(options, :jacobian, :symbolic)  # Default to symbolic!
	abstol = get(options, :abstol, polish_only ? 1e-6 : 1e-8)
	reltol = get(options, :reltol, polish_only ? 1e-4 : 1e-6)
	maxiters = get(options, :maxiters, polish_only ? 100 : 1000)
	algorithm = get(options, :algorithm, :auto)
	multistart = get(options, :multistart, !polish_only && isnothing(start_point))
	timeout = get(options, :timeout, 300.0)
	debug = true

	# System dimensions
	m = length(poly_system)
	n = length(varlist)

	if debug
		println("[ROBUST] System: $m equations, $n variables")
		println("[ROBUST] Polish mode: $polish_only")
		println("[ROBUST] Algorithm: $algorithm")
		println("[ROBUST] Jacobian: $jac_mode")
	end

	# Create residual function
	function residual!(res, u, p = nothing)
		d = Dict(zip(varlist, u))
		for (i, eq) in enumerate(poly_system)
			val = Symbolics.value(Symbolics.substitute(eq, d))
			res[i] = convert(eltype(res), val)
		end
		return nothing
	end

	# Create objective function for optimization methods
	function objective(u)
		res = zeros(m)
		residual!(res, u)
		return 0.5 * sum(res .^ 2)
	end

	# Build Jacobian if requested
	jac_func = nothing
	grad_func = nothing

	if jac_mode == :symbolic
		try
			if debug
				println("[ROBUST] Building symbolic Jacobian...")
			end
			J_expr = Symbolics.jacobian(poly_system, varlist)
			jac_func = Symbolics.build_function(J_expr, varlist, expression = Val(false))[2]

			# Also build gradient for optimization methods
			grad_expr = J_expr' * poly_system
			grad_func = Symbolics.build_function(grad_expr, varlist, expression = Val(false))[2]

			if debug
				println("[ROBUST] ✓ Symbolic Jacobian built successfully")
			end
		catch e
			@error "[ROBUST] Symbolic Jacobian failed" exception=(e, catch_backtrace())
			println("SOLVER_ERROR: solve_with_robust Jacobian build threw exception:")
			println("  Type: ", typeof(e))
			println("  Message: ", e)
			println("[ROBUST] Falling back to ForwardDiff")
			jac_mode = :forwarddiff
		end
	end

	if jac_mode == :forwarddiff
		jac_func = function (J, u)
			ForwardDiff.jacobian!(J,
				u_ -> (r = similar(u_, m); residual!(r, u_); r), u)
		end
		grad_func = function (g, u)
			ForwardDiff.gradient!(g, objective, u)
		end
	elseif jac_mode == :finitediff
		cache = FiniteDiff.JacobianCache(zeros(m), zeros(n))
		jac_func = function (J, u)
			FiniteDiff.finite_difference_jacobian!(J,
				(r, u_) -> residual!(r, u_), u, cache)
		end
		grad_func = function (g, u)
			FiniteDiff.finite_difference_gradient!(g, objective, u)
		end
	end

	# Generate starting points
	if multistart
		# Use diverse starting points
		starts = [
			isnothing(start_point) ? randn(n) : start_point,
			ones(n),
			zeros(n) .+ 0.1,
			ones(n) * 0.5,
			randn(n) * 0.1,
			rand(n) * 2.0 .- 1.0,
		]
	else
		starts = [isnothing(start_point) ? randn(n) : start_point]
	end

	# Select algorithm based on mode and options
	function select_algorithm()
		if algorithm != :auto
			return algorithm
		end

		if polish_only
			# For polishing, use fast local methods
			if jac_func !== nothing
				return :trustregion  # Most robust with Jacobian
			else
				return :bobyqa  # Fast derivative-free
			end
		else
			# For solving from scratch
			if jac_func !== nothing
				return :trustregion  # Most robust overall
			else
				return :bobyqa  # Best derivative-free we found
			end
		end
	end

	selected_algo = select_algorithm()

	# Storage for solutions
	all_solutions = []
	best_solution = nothing
	best_residual = Inf
	stats = Dict{Symbol, Any}()

	# Try each starting point
	start_time = time()
	for (idx, x0) in enumerate(starts)
		if time() - start_time > timeout
			if debug
				println("[ROBUST] Timeout reached")
			end
			break
		end

		if debug && length(starts) > 1
			println("[ROBUST] Trying start point $idx/$(length(starts))")
		end

		# Test initial residual
		res0 = zeros(m)
		residual!(res0, x0)
		if any(isnan, res0) || any(isinf, res0)
			continue
		end

		sol = nothing
		success = false

		try
			if selected_algo == :trustregion
				# Use NonlinearSolve.TrustRegion (most robust)
				if jac_func !== nothing
					nf = NonlinearFunction(residual!; jac = (J, u, p) -> jac_func(J, u))
				else
					nf = NonlinearFunction(residual!)
				end

				prob = if m == n
					NonlinearProblem(nf, x0)
				else
					NonlinearLeastSquaresProblem(nf, x0)
				end

				sol = NonlinearSolve.solve(prob, TrustRegion();
					abstol = abstol,
					reltol = reltol,
					maxiters = maxiters)

				success = SciMLBase.successful_retcode(sol)

			elseif selected_algo == :bfgs
				# Use Optim.BFGS (very robust for optimization)
				if grad_func !== nothing
					result = Optim.optimize(objective,
						(g, u) -> grad_func(g, u), x0,
						Optim.BFGS(linesearch = Optim.LineSearches.BackTracking()),
						Optim.Options(g_tol = abstol, iterations = maxiters))
				else
					result = Optim.optimize(objective, x0, Optim.BFGS())
				end

				sol = (u = result.minimizer,
					resid = sqrt(2 * result.minimum),
					retcode = Optim.converged(result) ? :Success : :MaxIters)
				success = Optim.converged(result)

			elseif selected_algo == :bobyqa
				# Use NLopt.BOBYQA (best derivative-free)
				opt = NLopt.Opt(:LN_BOBYQA, n)
				opt.min_objective = (x, grad) -> objective(x)
				opt.lower_bounds = fill(-100.0, n)
				opt.upper_bounds = fill(100.0, n)
				opt.ftol_abs = abstol^2  # Since we're minimizing ||f||^2
				opt.maxeval = maxiters

				(minf, minx, ret) = NLopt.optimize(opt, x0)

				sol = (u = minx, resid = sqrt(2 * minf),
					retcode = ret == :SUCCESS ? :Success : Symbol(ret))
				success = (ret == :SUCCESS || ret == :FTOL_REACHED || ret == :XTOL_REACHED)

			elseif selected_algo == :levenberg
				# Use NonlinearSolve.LevenbergMarquardt
				if jac_func !== nothing
					nf = NonlinearFunction(residual!; jac = (J, u, p) -> jac_func(J, u))
				else
					nf = NonlinearFunction(residual!)
				end

				prob = NonlinearLeastSquaresProblem(nf, x0)
				sol = NonlinearSolve.solve(prob, LevenbergMarquardt();
					abstol = abstol,
					reltol = reltol,
					maxiters = maxiters)

				success = SciMLBase.successful_retcode(sol)

			else
				# Fallback to NLsolve trust region
				function f!(F, x)
					residual!(F, x)
				end

				if jac_func !== nothing
					function j!(J, x)
						jac_func(J, x)
					end
					result = NLsolve.nlsolve(f!, j!, x0,
						method = :trust_region,
						autodiff = :forward,
						ftol = abstol,
						iterations = maxiters)
				else
					result = NLsolve.nlsolve(f!, x0,
						method = :trust_region,
						autodiff = :forward,
						ftol = abstol,
						iterations = maxiters)
				end

				sol = (u = result.zero,
					resid = result.residual_norm,
					retcode = result.f_converged ? :Success : :MaxIters)
				success = result.f_converged
			end

			# Check solution quality
			if success && !isnothing(sol)
				res_final = zeros(m)
				residual!(res_final, sol.u)
				final_norm = norm(res_final)

				if final_norm < best_residual
					best_residual = final_norm
					best_solution = sol.u

					# Create solution dictionary
					sol_dict = Dict(zip(varlist, sol.u))
					push!(all_solutions, sol_dict)

					if debug
						println("[ROBUST] Found solution with residual: $final_norm")
					end

					# If we found a good solution, maybe stop (unless multistart)
					if final_norm < abstol && !multistart
						break
					end
				end
			end

		catch e
			@error "[ROBUST] Algorithm failed" exception=(e, catch_backtrace())
			println("SOLVER_ERROR: solve_with_robust algorithm threw exception:")
			println("  Type: ", typeof(e))
			println("  Message: ", e)
			bt = catch_backtrace()
			st = stacktrace(bt)
			for (i, frame) in enumerate(st[1:min(5, length(st))])
				println("  [$i] ", frame)
			end
		end
	end

	# Prepare output in same format as solve_with_nlopt
	if isempty(all_solutions)
		if debug
			println("[ROBUST] No solutions found")
		end
		# Return empty result
		return ([], Dict(), stats, varlist)
	end

	# Remove duplicate solutions
	unique_solutions = []
	for sol in all_solutions
		is_duplicate = false
		for unique_sol in unique_solutions
			diff = norm([sol[v] - unique_sol[v] for v in varlist])
			if diff < 1e-6
				is_duplicate = true
				break
			end
		end
		if !is_duplicate
			push!(unique_solutions, sol)
		end
	end

	# Update stats
	stats[:algorithm] = selected_algo
	stats[:jacobian] = jac_mode
	stats[:best_residual] = best_residual
	stats[:num_solutions] = length(unique_solutions)
	stats[:multistart] = multistart

	if debug
		println("[ROBUST] Found $(length(unique_solutions)) unique solution(s)")
		println("[ROBUST] Best residual: $best_residual")
	end

	# Convert solutions from Dicts to Vectors to match other solvers' output format
	solutions_as_vectors = Vector{Vector{Float64}}()
	for sol_dict in unique_solutions
		# Ensure the order is correct according to varlist
		sol_vec = [sol_dict[v] for v in varlist]
		push!(solutions_as_vectors, sol_vec)
	end

	# Return in same format as other solvers: (solutions, varlist, trivial_dict, trimmed_varlist)
	return (solutions_as_vectors, varlist, Dict(), varlist)
end

# Export the function
export solve_with_robust
