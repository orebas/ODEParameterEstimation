using ODEParameterEstimation
using Dates
using Printf
using Random
using OrderedCollections: OrderedDict
using Symbolics
using NonlinearSolve
using ForwardDiff
using FiniteDiff
using LinearAlgebra
using SparseArrays

# Timing helper
function timeit(f)
    local t0 = time()
    local res = f()
    local ms = (time() - t0) * 1000
    return res, ms
end

# Load system function
function load_system(path::AbstractString)
    m = Module(:LoadedSystem)
    Base.include(m, path)
    poly_system = getfield(m, :poly_system)
    varlist = isdefined(m, :varlist) ? getfield(m, :varlist) : nothing
    
    # Validate varlist
    valid = isa(varlist, AbstractVector) && all(v -> typeof(v) <: Symbolics.Num || typeof(v) <: Symbolics.SymbolicUtils.Symbolic, varlist)
    if !valid
        if isdefined(m, :varlist_str)
            raw = String(getfield(m, :varlist_str))
            names = filter(!isempty, strip.(split(raw, '\n')))
            vars = Vector{Any}(undef, length(names))
            for (i, nm) in enumerate(names)
                vars[i] = getfield(m, Symbol(nm))
            end
            varlist = vars
        else
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

# Package solvers benchmark
function benchmark_package_solvers(poly_system, varlist; rng_seed::Int = 123)
    Random.seed!(rng_seed)
    results = Vector{NamedTuple}(undef, 0)
    
    solvers = OrderedDict{String, Function}(
        "solve_with_rs"            => ODEParameterEstimation.solve_with_rs,
        "solve_with_hc"            => ODEParameterEstimation.solve_with_hc,
        "solve_with_nlopt"         => ODEParameterEstimation.solve_with_nlopt,
        "solve_with_fast_nlopt"    => ODEParameterEstimation.solve_with_fast_nlopt,
        "solve_with_nlopt_quick"   => ODEParameterEstimation.solve_with_nlopt_quick,
        "solve_with_nlopt_testing" => ODEParameterEstimation.solve_with_nlopt_testing,
    )
    
    for (name, solver) in solvers
        println("Running ", name, "...")
        res = nothing
        t_ms = NaN
        try
            opts = Dict{Symbol, Any}(:debug => true)
            (res, t_ms) = timeit(() -> solver(poly_system, varlist; options = opts))
        catch err
            @warn "Solver failed" name error=err
        end
        push!(results, (name = name, time_ms = t_ms, result = res))
    end
    return results
end

# Build different Jacobian functions
function build_jacobians(poly_system, varlist)
    m = length(poly_system)
    n = length(varlist)
    
    # Create residual function that works with ForwardDiff
    function residual!(res, u, p)
        d = Dict(zip(varlist, u))
        for (i, eq) in enumerate(poly_system)
            val = Symbolics.value(Symbolics.substitute(eq, d))
            res[i] = convert(eltype(res), val)
        end
        return nothing
    end
    
    jacobians = OrderedDict{String, Any}()
    
    # 1. No Jacobian
    jacobians["none"] = nothing
    
    # 2. ForwardDiff Jacobian
    function jacobian_forwarddiff!(J, u, p)
        g = u_ -> begin
            r = similar(u_, m)
            residual!(r, u_, p)
            r
        end
        ForwardDiff.jacobian!(J, g, u)
    end
    jacobians["forwarddiff"] = jacobian_forwarddiff!
    
    # 3. Finite Differences Jacobian
    function jacobian_finitediff!(J, u, p)
        # Create a cache for finite differences
        cache = FiniteDiff.JacobianCache(zeros(m), u)
        function f!(res, u_)
            residual!(res, u_, p)
        end
        FiniteDiff.finite_difference_jacobian!(J, f!, u, cache)
    end
    jacobians["finitediff"] = jacobian_finitediff!
    
    # 4. Symbolic Jacobian
    try
        println("Building symbolic Jacobian...")
        J_expr = Symbolics.jacobian(poly_system, varlist)
        jac_func = Symbolics.build_function(J_expr, varlist, expression=Val(false))[2]
        
        function jacobian_symbolic!(J, u, p)
            # Convert to Float64 array if needed
            u_float = Float64.(u)
            jac_func(J, u_float)
            # Ensure J is filled with proper types
            for i in eachindex(J)
                J[i] = convert(eltype(J), J[i])
            end
        end
        jacobians["symbolic"] = jacobian_symbolic!
        println("  ✓ Symbolic Jacobian built successfully")
    catch e
        println("  ✗ Could not build symbolic Jacobian: ", e)
        jacobians["symbolic"] = nothing
    end
    
    # 5. Sparse ForwardDiff Jacobian
    function jacobian_sparse_forwarddiff!(J, u, p)
        g = u_ -> begin
            r = similar(u_, m)
            residual!(r, u_, p)
            r
        end
        # For small systems, sparse might not be beneficial, but we'll include it
        ForwardDiff.jacobian!(J, g, u)
    end
    jacobians["sparse_forwarddiff"] = jacobian_sparse_forwarddiff!
    
    return residual!, jacobians
end

# Build Hessian for second-order methods
function build_hessian(poly_system, varlist)
    m = length(poly_system)
    n = length(varlist)
    
    # For nonlinear least squares, we need the Hessian of the objective function
    # obj(u) = 0.5 * ||residual(u)||^2
    
    function hessian_forwarddiff!(H, u, p)
        # Build the objective function
        function obj(u_)
            res = zeros(eltype(u_), m)
            d = Dict(zip(varlist, u_))
            for (i, eq) in enumerate(poly_system)
                val = Symbolics.value(Symbolics.substitute(eq, d))
                res[i] = convert(eltype(res), val)
            end
            return 0.5 * sum(res.^2)
        end
        
        ForwardDiff.hessian!(H, obj, u)
    end
    
    return hessian_forwarddiff!
end

# NonlinearSolve optimizers benchmark
function benchmark_nlsolve_optimizers(poly_system, varlist; rng_seed::Int = 123)
    Random.seed!(rng_seed)
    results = []
    
    m = length(poly_system)
    n = length(varlist)
    
    # Build all Jacobian functions
    residual!, jacobians = build_jacobians(poly_system, varlist)
    
    # Build Hessian for second-order methods
    hessian! = build_hessian(poly_system, varlist)
    
    # First-order optimizers
    first_order_optimizers = OrderedDict(
        "NewtonRaphson" => (NewtonRaphson(), true, 1000),
        "TrustRegion" => (TrustRegion(), true, 1000),
        "Broyden" => (Broyden(), false, 2000),
        "Klement" => (Klement(), false, 2000),  # Including unreliable ones
        "DFSane" => (DFSane(), false, 2000),
        "LimitedMemoryBroyden" => (LimitedMemoryBroyden(), false, 2000),
        # Simple versions (often more stable for small problems)
        "SimpleNewtonRaphson" => (SimpleNewtonRaphson(), true, 1000),
        "SimpleTrustRegion" => (SimpleTrustRegion(), true, 1000),
        "SimpleBroyden" => (SimpleBroyden(), false, 2000),
        "SimpleKlement" => (SimpleKlement(), false, 2000),
        "SimpleDFSane" => (SimpleDFSane(), false, 2000),
        "SimpleLimitedMemoryBroyden" => (SimpleLimitedMemoryBroyden(), false, 2000),
    )
    
    # Add least squares optimizers if m != n
    if m != n
        first_order_optimizers["GaussNewton"] = (GaussNewton(), true, 1000)
        first_order_optimizers["LevenbergMarquardt"] = (LevenbergMarquardt(), true, 1000)
        first_order_optimizers["SimpleGaussNewton"] = (SimpleGaussNewton(), true, 1000)
    end
    
    # Try to add more advanced optimizers if available
    try
        # These might not all be available in all versions
        first_order_optimizers["PseudoTransient"] = (PseudoTransient(), false, 2000)
    catch e
        println("Note: Some advanced optimizers not available: ", e)
    end
    
    # Try adding Halley method (uses second derivatives)
    try
        first_order_optimizers["SimpleHalley"] = (SimpleHalley(), true, 1000)
    catch e
        # SimpleHalley might not be available
    end
    
    # Test with multiple initial points
    initial_points = [
        ones(n) * 0.5,
        rand(n),
        ones(n) * 0.1,
        ones(n),
        [fill(0.5, n-1)..., 0.2]
    ]
    
    # Test each optimizer with different Jacobian methods
    for (opt_name, (optimizer, needs_jacobian, maxiters)) in first_order_optimizers
        for (jac_name, jac_func) in jacobians
            # Skip invalid combinations
            if needs_jacobian && isnothing(jac_func)
                continue
            end
            if !needs_jacobian && jac_name != "none"
                continue  # Derivative-free methods don't use Jacobians
            end
            
            best_result = nothing
            best_norm = Inf
            best_time = NaN
            res_evals = Ref(0)
            jac_evals = Ref(0)
            
            for x0 in initial_points
                # Modified residual to count evaluations
                function counted_residual!(res, u, p)
                    res_evals[] += 1
                    residual!(res, u, p)
                end
                
                # Setup problem
                nf = if !isnothing(jac_func)
                    function counted_jacobian!(J, u, p)
                        jac_evals[] += 1
                        jac_func(J, u, p)
                    end
                    NonlinearFunction(counted_residual!; jac = counted_jacobian!)
                else
                    NonlinearFunction(counted_residual!)
                end
                
                prob = if m == n
                    NonlinearProblem(nf, x0)
                else
                    NonlinearLeastSquaresProblem(nf, x0)
                end
                
                # Try to solve
                t_ms = NaN
                sol = nothing
                try
                    sol, t_ms = timeit(() -> NonlinearSolve.solve(prob, optimizer; 
                                                                   abstol = 1e-6, 
                                                                   reltol = 1e-6, 
                                                                   maxiters = maxiters))
                    
                    # Check solution quality
                    final_res = zeros(m)
                    residual!(final_res, sol.u, nothing)
                    final_norm = norm(final_res)
                    
                    if final_norm < best_norm
                        best_norm = final_norm
                        best_result = sol
                        best_time = t_ms
                    end
                    
                    # If we found a good solution, stop trying other initial points
                    if final_norm < 1e-4
                        break
                    end
                catch e
                    # Record the failure but continue
                end
            end
            
            # Record the result
            success = !isnothing(best_result) && best_norm < 1e-3
            push!(results, (
                optimizer = opt_name,
                jacobian = jac_name,
                time_ms = best_time,
                success = success,
                res_evals = res_evals[],
                jac_evals = jac_evals[],
                final_norm = best_norm,
                solution = best_result !== nothing ? best_result.u : nothing
            ))
        end
    end
    
    # Test second-order methods (with Hessian)
    println("\nTesting second-order methods...")
    second_order_optimizers = OrderedDict()
    
    # Try Newton with Hessian if we can construct appropriate problem
    # Note: Most NonlinearSolve optimizers don't directly use Hessian,
    # but we can try optimization-based approaches
    
    return results
end

# Summary functions
function summarize_package_results(results)
    println("\n=== Package Solver Benchmark ===")
    @printf("%-26s | %12s | %s\n", "Solver", "Time (ms)", "Solutions")
    println("-"^60)
    for r in results
        num_solutions = try
            isa(r.result, Tuple) && length(r.result) >= 1 ? length(r.result[1]) : missing
        catch
            missing
        end
        @printf("%-26s | %12.3f | %s\n", r.name, r.time_ms, string(num_solutions))
    end
end

function summarize_nlsolve_results(results)
    println("\n=== NonlinearSolve Optimizer Benchmark (All Jacobian Methods) ===")
    @printf("%-20s | %-18s | %10s | %-7s | %8s | %8s | %-15s\n", 
            "Optimizer", "Jacobian", "Time (ms)", "Success", "ResEvals", "JacEvals", "Final Norm")
    println("-"^110)
    
    # Group by optimizer for better readability
    optimizers = unique([r.optimizer for r in results])
    
    for opt in optimizers
        opt_results = filter(r -> r.optimizer == opt, results)
        for (i, r) in enumerate(opt_results)
            opt_display = i == 1 ? r.optimizer : ""
            @printf("%-20s | %-18s | %10.3f | %-7s | %8d | %8d | %15.6e\n", 
                    opt_display, r.jacobian, r.time_ms, 
                    r.success ? "✓" : "✗", r.res_evals, r.jac_evals, r.final_norm)
        end
        if opt != optimizers[end]
            println("." * "-"^109)
        end
    end
    
    working_count = sum(r.success for r in results)
    println("\n$(working_count) out of $(length(results)) optimizer-jacobian combinations successfully solved the system")
    
    # Summary by Jacobian method
    println("\n=== Success Rate by Jacobian Method ===")
    jac_methods = unique([r.jacobian for r in results])
    for jac in jac_methods
        jac_results = filter(r -> r.jacobian == jac, results)
        successes = sum(r.success for r in jac_results)
        total = length(jac_results)
        @printf("%-18s: %d/%d (%.1f%%)\n", jac, successes, total, 100.0 * successes / total)
    end
    
    # Find best performer
    successful_results = filter(r -> r.success, results)
    if !isempty(successful_results)
        best = argmin(r -> r.time_ms, successful_results)
        println("\nFastest successful solve: $(best.optimizer) with $(best.jacobian) jacobian ($(round(best.time_ms, digits=2)) ms)")
    end
end

function main()
    # Allow system file selection via command line or use default
    system_file = if length(ARGS) >= 1
        ARGS[1]
    else
        joinpath(@__DIR__, "saved_systems", "system_point_1_2025-09-11T00:02:53.925.jl")
    end
    
    println("[Info] Loading saved system from: ", system_file)
    (poly_system, varlist) = load_system(system_file)
    println("[Info] Loaded system with ", length(poly_system), " equations and ", length(varlist), " variables.")
    println("\nSystem equations:")
    for (i, eq) in enumerate(poly_system)
        println("  $i: $eq")
    end
    println("\nVariables: $varlist")
    
    # Run package solver benchmarks
    println("\n" * "="^80)
    println("RUNNING PACKAGE SOLVER BENCHMARKS")
    println("="^80)
    package_results = benchmark_package_solvers(poly_system, varlist)
    summarize_package_results(package_results)
    
    # Run NonlinearSolve optimizer benchmarks with all Jacobian methods
    println("\n" * "="^80)
    println("RUNNING NONLINEARSOLVE OPTIMIZER BENCHMARKS WITH MULTIPLE JACOBIAN METHODS")
    println("="^80)
    nlsolve_results = benchmark_nlsolve_optimizers(poly_system, varlist)
    summarize_nlsolve_results(nlsolve_results)
    
    println("\n" * "="^80)
    println("BENCHMARK COMPLETE")
    println("="^80)
end

main()