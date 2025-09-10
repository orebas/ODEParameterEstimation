# A definitive script to diagnose float-to-rational conversion issues by analyzing the expression tree.
# Usage:
#   julia --project scripts/diagnostics_debug.jl [path_to_saved_system.jl]

using Pkg
Pkg.instantiate()

try
	using Symbolics
	using AbstractAlgebra
	using Oscar
	using Singular
	using Nemo
catch e
	println("ERROR: Required packages not found. Run `julia --project` from the project root.")
	rethrow(e)
end

# --- Robust Conversion and Analysis ---

function rationalize_floats(expr)
	SymbolicUtils.Rewriters.Prewalk(x -> x isa Float64 ? rationalize(BigInt, x) : x)(expr)
end

function analyze_expression_tree(expr)
	println("\n--- Detailed Tree Analysis for Expression ---")
	println("Expression: ", expr)
	found_float = Ref(false)
	SymbolicUtils.Postwalk(x -> begin
		println("  - Node: `", repr(x), "` | Type: `", typeof(x), "`")
		if x isa Float64
			found_float[] = true
		end
		return x
	end)(expr)
	println("----------------------------------------")
	return !found_float[]
end


function main()
	# --- System Loading ---
	poly_system = nothing
	varlist = nothing

	if length(ARGS) > 0
		system_file = ARGS[1]
		println("[INFO] Loading system from: ", system_file)
		if isfile(system_file)
			loaded_module = @eval Module() begin
				include($system_file)
				(poly_system, varlist)
			end
			poly_system, varlist = loaded_module
		else
			println("[ERROR] File not found: ", system_file)
			exit(1)
		end
	else
		println("[INFO] No system file provided. Using a simple default system for testing.")
		@variables x y
		poly_system = [1.5*x^2 + 2.0*y - 3.0, 0.5*x - y^2 + 1.0]
		varlist = [x, y]
	end

	println("\n[INFO] System details:")
	println("  Num variables: ", length(varlist))
	println("  Num equations: ", length(poly_system))

	# --- Main Execution ---

	println("\n[STEP 1] Unwrapping Num types to get raw symbolic expressions...")
	unwrapped_system = Symbolics.value.(poly_system)
	println("[SUCCESS] Unwrapping complete.")

	println("\n[STEP 2] Converting all Float64s in the unwrapped expressions to Rationals...")
	rationalized_system = rationalize_floats.(unwrapped_system)
	println("[SUCCESS] Conversion step complete.")

	println("\n[STEP 3] Performing detailed type analysis on all rationalized expressions...")
	all_verified = true
	for (i, expr) in enumerate(rationalized_system)
		println("\n--- Analyzing Expression #$i ---")
		if !analyze_expression_tree(expr)
			all_verified = false
			println("!!! A Float64 was found in the tree for expression #$i.")
		end
	end

	if !all_verified
		println("\n[FATAL] Verification failed. Lingering Float64s were detected in the trees above. Cannot proceed.")
		exit(1)
	end

	println("\n[SUCCESS] Verification passed. No Float64s found in any expression tree.")

	println("\n[STEP 4] Running Oscar diagnostics...")
	try
		sanitized_vars = string.(varlist)
		Rosc, ovars = Oscar.polynomial_ring(Oscar.QQ, sanitized_vars)

		sub_dict = Dict(varlist[i] => ovars[i] for i in eachindex(varlist))

		# We substitute into the verified, rationalized system
		opolys = [Symbolics.value(Symbolics.substitute(p, sub_dict)) for p in rationalized_system]

		Iosc = Oscar.ideal(Rosc, opolys...)
		Gosc = Oscar.groebner_basis(Iosc)
		println("[SUCCESS] Oscar diagnostics complete. Groebner basis has ", length(Oscar.gens(Gosc)), " elements.")
	catch e
		println("[ERROR] Oscar diagnostics failed.")
		rethrow(e)
	end
end

main()
