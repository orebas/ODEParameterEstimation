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
  - `:jacobian => :forwarddiff/:symbolic/:finitediff/:none`: Jacobian method (default :forwarddiff)
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


	robust_t0 = time()
	robust_stages = OrderedDict{Symbol, Float64}()
	timing_enabled = _DETAILED_TIMING_SINK[] !== nothing
	residual_call_count = 0
	residual_seconds = 0.0
	jacobian_call_count = 0
	jacobian_seconds = 0.0
	starts_attempted = 0
	starts_skipped_bad_residual = 0
	successful_start_count = 0
	algorithm_failure_count = 0

	# Extract options
	debug = get(options, :debug, false)
	# Default to :forwarddiff: avoids per-call Symbolics.jacobian + 2x build_function
	# (each build_function leaves a fresh RuntimeGeneratedFunction in the JIT code
	# cache that never reclaims, so the :symbolic path grew ~1 MB/iter peak RSS
	# in the candidate loop -- see repro/memory_audit_2026_05_19/mwe_run.txt).
	# ForwardDiff propagates duals through the already-compiled native residual at
	# lines ~60-66, returns the exact Jacobian, and grows ~0 MB/iter.
	jac_mode = get(options, :jacobian, :forwarddiff)
	abstol = get(options, :abstol, polish_only ? 1e-6 : 1e-8)
	reltol = get(options, :reltol, polish_only ? 1e-4 : 1e-6)
	maxiters = get(options, :maxiters, polish_only ? 100 : 1000)
	algorithm = get(options, :algorithm, :auto)
	multistart = get(options, :multistart, !polish_only && isnothing(start_point))
	timeout = get(options, :timeout, 300.0)

	# System dimensions
	m = length(poly_system)
	n = length(varlist)

	if debug
		println("[ROBUST] System: $m equations, $n variables")
		println("[ROBUST] Polish mode: $polish_only")
		println("[ROBUST] Algorithm: $algorithm")
		println("[ROBUST] Jacobian: $jac_mode")
	end

	# Try to compile the system into a fast native function; fall back to substitute/value
	compiled_residual_robust! = nothing
	_build_residual_t0 = time()
	try
		_f_oop, _f_ip = Symbolics.build_function(poly_system, varlist;
			expression = Val(false))
		compiled_residual_robust! = (res, u, p) -> (_f_ip(res, u); nothing)
	catch err
		@warn "build_function failed in solve_with_robust; falling back to substitute/value" err
	finally
		robust_stages[:build_residual_function] = get(robust_stages, :build_residual_function, 0.0) + (time() - _build_residual_t0)
	end

	# Create residual function
	function residual!(res, u, p = nothing)
		if timing_enabled
			_residual_t0 = time()
			try
				if compiled_residual_robust! !== nothing
					compiled_residual_robust!(res, u, p)
				else
					d = Dict{Num, eltype(u)}(zip(varlist, u))
					for (i, eq) in enumerate(poly_system)
						val = Symbolics.value(Symbolics.substitute(eq, d))
						res[i] = convert(eltype(res), val)
					end
				end
			finally
				residual_call_count += 1
				residual_seconds += time() - _residual_t0
			end
		elseif compiled_residual_robust! !== nothing
			compiled_residual_robust!(res, u, p)
		else
			d = Dict{Num, eltype(u)}(zip(varlist, u))
			for (i, eq) in enumerate(poly_system)
				val = Symbolics.value(Symbolics.substitute(eq, d))
				res[i] = convert(eltype(res), val)
			end
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

	_jacobian_setup_t0 = time()
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
			if timing_enabled
				_jac_t0 = time()
				try
					ForwardDiff.jacobian!(J,
						u_ -> (r = similar(u_, m); residual!(r, u_); r), u)
				finally
					jacobian_call_count += 1
					jacobian_seconds += time() - _jac_t0
				end
			else
				ForwardDiff.jacobian!(J,
					u_ -> (r = similar(u_, m); residual!(r, u_); r), u)
			end
		end
		grad_func = function (g, u)
			if timing_enabled
				_jac_t0 = time()
				try
					ForwardDiff.gradient!(g, objective, u)
				finally
					jacobian_call_count += 1
					jacobian_seconds += time() - _jac_t0
				end
			else
				ForwardDiff.gradient!(g, objective, u)
			end
		end
	elseif jac_mode == :finitediff
		cache = FiniteDiff.JacobianCache(zeros(m), zeros(n))
		jac_func = function (J, u)
			if timing_enabled
				_jac_t0 = time()
				try
					FiniteDiff.finite_difference_jacobian!(J,
						(r, u_) -> residual!(r, u_), u, cache)
				finally
					jacobian_call_count += 1
					jacobian_seconds += time() - _jac_t0
				end
			else
				FiniteDiff.finite_difference_jacobian!(J,
					(r, u_) -> residual!(r, u_), u, cache)
			end
		end
		grad_func = function (g, u)
			if timing_enabled
				_jac_t0 = time()
				try
					FiniteDiff.finite_difference_gradient!(g, objective, u)
				finally
					jacobian_call_count += 1
					jacobian_seconds += time() - _jac_t0
				end
			else
				FiniteDiff.finite_difference_gradient!(g, objective, u)
			end
		end
	end
	robust_stages[:jacobian_setup] = get(robust_stages, :jacobian_setup, 0.0) + (time() - _jacobian_setup_t0)

	# Generate starting points
	_generate_starts_t0 = time()
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
	robust_stages[:generate_starts] = get(robust_stages, :generate_starts, 0.0) + (time() - _generate_starts_t0)

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
		starts_attempted += 1
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
		_initial_residual_t0 = time()
		res0 = zeros(m)
		try
			residual!(res0, x0)
		finally
			robust_stages[:initial_residual] = get(robust_stages, :initial_residual, 0.0) + (time() - _initial_residual_t0)
		end
		if any(isnan, res0) || any(isinf, res0)
			starts_skipped_bad_residual += 1
			continue
		end

		sol = nothing
		success = false

		_nonlinear_solve_t0 = time()
		_nonlinear_solve_recorded = false
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
				# Fallback: NonlinearSolve.TrustRegion
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
			end
			robust_stages[:nonlinear_solve] = get(robust_stages, :nonlinear_solve, 0.0) + (time() - _nonlinear_solve_t0)
			_nonlinear_solve_recorded = true

			# Check solution quality
			if success && !isnothing(sol)
				successful_start_count += 1
				_final_residual_t0 = time()
				res_final = zeros(m)
				final_norm = try
					residual!(res_final, sol.u)
					norm(res_final)
				finally
					robust_stages[:final_residual] = get(robust_stages, :final_residual, 0.0) + (time() - _final_residual_t0)
				end

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
			_rethrow_if_interrupt(e)
			algorithm_failure_count += 1
			if !_nonlinear_solve_recorded
				robust_stages[:nonlinear_solve] = get(robust_stages, :nonlinear_solve, 0.0) + (time() - _nonlinear_solve_t0)
			end
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

	function _record_robust_timing!(unique_count)
		_record_detailed_timing!((
			category = :solve_with_robust,
			context = _current_detailed_timing_context(),
			total_seconds = time() - robust_t0,
			stage_seconds = copy(robust_stages),
			equation_count = m,
			variable_count = n,
			polish_only = polish_only,
			algorithm = selected_algo,
			jacobian = jac_mode,
			multistart = multistart,
			start_count = length(starts),
			starts_attempted = starts_attempted,
			starts_skipped_bad_residual = starts_skipped_bad_residual,
			successful_start_count = successful_start_count,
			algorithm_failure_count = algorithm_failure_count,
			residual_call_count = residual_call_count,
			residual_seconds = residual_seconds,
			jacobian_call_count = jacobian_call_count,
			jacobian_seconds = jacobian_seconds,
			raw_solution_count = length(all_solutions),
			unique_solution_count = unique_count,
			best_residual = isfinite(best_residual) ? best_residual : nothing,
			used_compiled_residual = compiled_residual_robust! !== nothing,
		))
		return nothing
	end

	# Prepare output in same format as solve_with_nlopt
	if isempty(all_solutions)
		if debug
			println("[ROBUST] No solutions found")
		end
		_record_robust_timing!(0)
		# Return empty result
		return ([], Dict(), stats, varlist)
	end

	# Remove duplicate solutions
	_deduplicate_t0 = time()
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
	robust_stages[:deduplicate_solutions] = get(robust_stages, :deduplicate_solutions, 0.0) + (time() - _deduplicate_t0)

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
	_materialize_vectors_t0 = time()
	solutions_as_vectors = Vector{Vector{Float64}}()
	for sol_dict in unique_solutions
		# Ensure the order is correct according to varlist
		sol_vec = [sol_dict[v] for v in varlist]
		push!(solutions_as_vectors, sol_vec)
	end
	robust_stages[:materialize_solution_vectors] = get(robust_stages, :materialize_solution_vectors, 0.0) + (time() - _materialize_vectors_t0)

	_record_robust_timing!(length(unique_solutions))

	# Return in same format as other solvers: (solutions, varlist, trivial_dict, trimmed_varlist)
	return (solutions_as_vectors, varlist, Dict(), varlist)
end

# Export the function
export solve_with_robust
