using ODEParameterEstimation
using Dates
using Printf
using Random
using OrderedCollections: OrderedDict
using Symbolics
using NonlinearSolve
using ForwardDiff
using LinearAlgebra

const DerivativeFreeAlgos = Union{Broyden, Klement, DFSane}

# Simple timing helper returning (result, ms)
function timeit(f)
	local t0 = time()
	local res = f()
	local ms = (time() - t0) * 1000
	return res, ms
end

# Resolve a saved system path. Prefer argument; otherwise default to examples/saved_systems file included by user.
function resolve_system_path()
	if length(ARGS) >= 1
		return ARGS[1]
	end
	# Default to the example file path in repo
	default_path = joinpath(@__DIR__, "..", "saved_systems", "system_point_358_2025-09-10T20:04:58.699.jl")
	return default_path
end

#/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/saved_systems/system_point_72_2025-09-10T20:12:52.457.jl

# Robustly load a saved system file by including it into an isolated module.
# If the saved varlist is malformed, reconstruct it from varlist_str.
function load_system(path::AbstractString)
	m = Module(:LoadedSystem)
	Base.include(m, path)
	# Extract poly_system and attempt to extract varlist
	poly_system = getfield(m, :poly_system)
	varlist = isdefined(m, :varlist) ? getfield(m, :varlist) : nothing
	# Validate varlist
	valid = isa(varlist, AbstractVector) && all(v -> typeof(v) <: Symbolics.Num || typeof(v) <: Symbolics.SymbolicUtils.Symbolic, varlist)
	if !valid
		# Try reconstructing from varlist_str and module bindings
		if isdefined(m, :varlist_str)
			raw = String(getfield(m, :varlist_str))
			names = filter(!isempty, strip.(split(raw, '\n')))
			vars = Vector{Any}(undef, length(names))
			for (i, nm) in enumerate(names)
				vars[i] = getfield(m, Symbol(nm))
			end
			varlist = vars
		else
			# As a last resort, extract symbols from the polynomial system
			# Note: preserves a deterministic order by sorting by string rep
			seen = Dict{Symbol, Any}()
			for eq in poly_system
				for v in Symbolics.get_variables(eq)
					seen[Symbol(string(v))] = v
				end
			end
			varlist = [seen[k] for k in sort!(collect(keys(seen)))]
		end
	end
	return poly_system, varlist
end

# Use a local dictionary instead of a constant to avoid redefinition warnings on repeated includes
function available_solvers()
	return OrderedDict{String, Function}(
		"solve_with_rs"            => ODEParameterEstimation.solve_with_rs,
		"solve_with_hc"            => ODEParameterEstimation.solve_with_hc,
		"solve_with_nlopt"         => ODEParameterEstimation.solve_with_nlopt,
		"solve_with_fast_nlopt"    => ODEParameterEstimation.solve_with_fast_nlopt,
		"solve_with_nlopt_quick"   => ODEParameterEstimation.solve_with_nlopt_quick,
		"solve_with_nlopt_testing" => ODEParameterEstimation.solve_with_nlopt_testing,
	)
end

# Run all solvers, timing each. Returns a vector of NamedTuples.
function benchmark_solvers(poly_system, varlist; rng_seed::Int = 123)
	Random.seed!(rng_seed)
	results = Vector{NamedTuple}(undef, 0)

	# Allow jacobian mode selection via ENV var for experimentation
	jac_mode_str = get(ENV, "ODEPE_JACOBIAN_MODE", "none")
	jac_mode = Symbol(jac_mode_str)

	for (name, solver) in available_solvers()
		println("Running ", name, "...")
		res = nothing
		t_ms = NaN
		try
			# Pass debug=true always, and jacobian mode to nlopt solvers
			opts = Dict{Symbol, Any}(:debug => true)
			if occursin("nlopt", name)
				opts[:jacobian] = jac_mode
			end
			(res, t_ms) = timeit(() -> solver(poly_system, varlist; options = opts))
		catch err
			@warn "Solver failed" name error=err
		end
		push!(results, (name = name, time_ms = t_ms, result = res))
	end
	return results
end

function summarize(results)
	println("\n=== Benchmark Summary ===")
	for r in results
		# Attempt to count solutions when tuple-like from solvers: (solutions, varmap, stats, varlist)
		num_solutions = try
			isa(r.result, Tuple) && length(r.result) >= 1 ? length(r.result[1]) : missing
		catch
			missing
		end
		@printf("%-26s  %10.3f ms  solutions=%s\n", r.name, r.time_ms, string(num_solutions))
	end
end

function run_extended_benchmark(poly_system, varlist; rng_seed::Int = 123)
	println("\n\n--- Running Extended Benchmark Suite ---")
	Random.seed!(rng_seed)
	results = []

	optimizers = OrderedDict(
		"GaussNewton" => GaussNewton(),
		"LevenbergMarquardt" => LevenbergMarquardt(),
		"TrustRegion" => TrustRegion(),
		"NewtonRaphson" => NewtonRaphson(),
		"Broyden" => Broyden(),
		"Klement" => Klement(),
		"DFSane" => DFSane(),
	)

	jacobian_methods = [:none, :forwarddiff, :symbolic]

	m = length(poly_system)
	n = length(varlist)
	x0 = randn(n)

	res_evals = Ref(0)
	function residual!(res, u, p)
		res_evals[] += 1
		d = Dict(zip(varlist, u))
		for (i, eq) in enumerate(poly_system)
			val = Symbolics.value(Symbolics.substitute(eq, d))
			res[i] = convert(eltype(u), val)
		end
		return nothing
	end

	jac_ip!_symbolic = try
		J_expr = Symbolics.jacobian(poly_system, varlist)
		_, f = Symbolics.build_function(J_expr, varlist; expression = Val(false))
		f
	catch err
		@warn "Symbolic Jacobian compilation failed, will skip." error=err
		nothing
	end

	for (opt_name, optimizer) in optimizers
		for jac_mode in jacobian_methods
			if jac_mode != :none && optimizer isa DerivativeFreeAlgos
				continue # Skip Jacobian modes for derivative-free methods
			end
			if jac_mode == :symbolic && isnothing(jac_ip!_symbolic)
				continue
			end

			print("Testing Optimizer: ", rpad(opt_name, 20), " Jacobian: ", rpad(string(jac_mode), 12))

			res_evals[] = 0
			jac_evals = Ref(0)

			jacobian! = nothing
			if jac_mode == :forwarddiff
				function jacobian_forwarddiff!(J, u, p)
					jac_evals[] += 1
					g = u_ -> (r = similar(u_, m); residual!(r, u_, p); r)
					ForwardDiff.jacobian!(J, g, u)
				end
				jacobian! = jacobian_forwarddiff!
			elseif jac_mode == :symbolic
				function jacobian_symbolic!(J, u, p)
					jac_evals[] += 1
					jac_ip!_symbolic(J, u)
				end
				jacobian! = jacobian_symbolic!
			end

			nf = isnothing(jacobian!) ? NonlinearFunction(residual!) : NonlinearFunction(residual!; jac = jacobian!)
			prob = NonlinearLeastSquaresProblem(nf, x0)

			t_ms = NaN
			sol = nothing
			try
				sol, t_ms = timeit(() -> NonlinearSolve.solve(prob, optimizer; abstol = 1e-6, reltol = 1e-6, maxiters = 1000))
			catch e
				# Do nothing, sol remains nothing
			end

			success = !isnothing(sol) && SciMLBase.successful_retcode(sol)
			final_norm = success ? sol.resid : (sol !== nothing ? norm(sol.resid) : NaN)
			push!(results, (optimizer = opt_name, jacobian = jac_mode, time_ms = t_ms, success = success, res_evals = res_evals[], jac_evals = jac_evals[], final_norm = final_norm))
			println(" -> Done")
		end
	end
	return results
end

function summarize_extended_results(results)
	println("\n--- Extended Benchmark Summary ---")
	@printf("%-20s | %-12s | %12s | %-8s | %-10s | %-10s | %-15s\n", "Optimizer", "Jacobian", "Time (ms)", "Success", "Res Evals", "Jac Evals", "Final Norm")
	println("-"^95)
	for r in results
		@printf("%-20s | %-12s | %12.3f | %-8s | %-10d | %-10d | %-15.6e\n", r.optimizer, r.jacobian, r.time_ms, r.success, r.res_evals, r.jac_evals, r.final_norm)
	end
end

function main()
	path = resolve_system_path()
	println("[Info] Loading saved system from: ", path)
	(poly_system, varlist) = load_system(path)
	println("[Info] Loaded system with ", length(poly_system), " equations and ", length(varlist), " variables.")

	println("\n--- Running Package Solver Benchmarks (Control Group) ---")
	results = benchmark_solvers(poly_system, varlist)
	summarize(results)

	extended_results = run_extended_benchmark(poly_system, varlist)
	summarize_extended_results(extended_results)
end


main()
