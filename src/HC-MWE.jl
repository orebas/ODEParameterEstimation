using HomotopyContinuation

function MonodromyTest()
	# Create a simple system with two parameters
	@var x p q

	# Define the system: q*(x³ - 8) - p = 0
	F = System([q * (x^3 - 8.0) - p], parameters = [p, q])

	println("\n=== Regular solving ===")
	# Solve with p = 0, q = 1
	result = solve(F, target_parameters = [0.0, 1.0])

	# Display all solutions
	println("All solutions from regular solve:")
	display(solutions(result))

	println("\n=== Monodromy solving ===")
	# Now try with monodromy
	# First find a start pair
	found_start_pair = false
	pair_attempts = 0
	newx = nothing
	param_final = [0.0, 1.0]  # Target parameters: p = 0, q = 1

	while (!found_start_pair && pair_attempts < 50)
		testx, testp = find_start_pair(F)
		newx = solve(F, testx, start_parameters = testp, target_parameters = param_final,
			tracker_options = TrackerOptions(automatic_differentiation = 3))
		startpsoln = solutions(newx)
		pair_attempts += 1
		if (!isempty(startpsoln))
			found_start_pair = true
		end
	end

	# Now do monodromy solve with modified parameters
	result_mono = monodromy_solve(F, solutions(newx), param_final,
		show_progress = true,
		timeout = 300.0,
		max_loops_no_progress = 50,
		target_solutions_count = 3,
		unique_points_rtol = 1e-8,
		unique_points_atol = 1e-8,
		trace_test = true,
		trace_test_tol = 1e-10,
		min_solutions = 3,
		tracker_options = TrackerOptions(automatic_differentiation = 3))

	println("\nSolutions from monodromy:")
	display(solutions(result_mono))
	display(certify(F, result_mono))

	# Verify these are actually solutions
	println("\nVerification for monodromy solutions (should all be close to 0):")
	for sol in solutions(result_mono)
		residual = abs(sol[1]^3 - 8)
		println("x = ", sol[1], " => residual = ", residual)
	end
end

MonodromyTest()
