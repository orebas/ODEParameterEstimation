using ODEParameterEstimation
using Dates
using Printf
using Random
using OrderedCollections: OrderedDict
using Symbolics
using NonlinearSolve
using ForwardDiff
using LinearAlgebra

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

# NonlinearSolve optimizers benchmark
function benchmark_nlsolve_optimizers(poly_system, varlist; rng_seed::Int = 123)
    Random.seed!(rng_seed)
    results = []
    
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
    
    # Create Jacobian with ForwardDiff
    function jacobian_forwarddiff!(J, u, p)
        g = u_ -> begin
            r = similar(u_, m)
            residual!(r, u_, p)
            r
        end
        ForwardDiff.jacobian!(J, g, u)
    end
    
    # Optimizer configurations
    # Note: Klement seems unreliable for this problem, so we'll skip it
    optimizers = OrderedDict(
        "NewtonRaphson" => (NewtonRaphson(), true, 1000),
        "TrustRegion" => (TrustRegion(), true, 1000),
        "Broyden" => (Broyden(), false, 2000),
        "DFSane" => (DFSane(), false, 2000),
    )
    
    # Add least squares optimizers if m != n
    if m != n
        optimizers["GaussNewton"] = (GaussNewton(), true, 1000)
        optimizers["LevenbergMarquardt"] = (LevenbergMarquardt(), true, 1000)
    end
    
    # Test with multiple initial points to find one that works
    initial_points = [
        ones(n) * 0.5,
        rand(n),
        ones(n) * 0.1,
        ones(n),
        [fill(0.5, n-1)..., 0.2]
    ]
    
    for (opt_name, (optimizer, use_jacobian, maxiters)) in optimizers
        best_result = nothing
        best_norm = Inf
        best_time = NaN
        best_x0 = nothing
        
        for x0 in initial_points
            res_evals = Ref(0)
            jac_evals = Ref(0)
            
            # Modified residual to count evaluations
            function counted_residual!(res, u, p)
                res_evals[] += 1
                residual!(res, u, p)
            end
            
            # Setup problem
            nf = if use_jacobian
                function counted_jacobian!(J, u, p)
                    jac_evals[] += 1
                    jacobian_forwarddiff!(J, u, p)
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
                    best_x0 = x0
                end
                
                # If we found a good solution, stop trying other initial points
                if final_norm < 1e-4
                    break
                end
            catch e
                # Silently skip failed attempts
            end
        end
        
        # Record the best result found
        success = !isnothing(best_result) && best_norm < 1e-3
        push!(results, (
            optimizer = opt_name,
            jacobian = use_jacobian ? "ForwardDiff" : "None",
            time_ms = best_time,
            success = success,
            final_norm = best_norm,
            solution = best_result !== nothing ? best_result.u : nothing
        ))
    end
    
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
    println("\n=== NonlinearSolve Optimizer Benchmark ===")
    @printf("%-20s | %-12s | %12s | %-8s | %-15s\n", 
            "Optimizer", "Jacobian", "Time (ms)", "Success", "Final Norm")
    println("-"^80)
    for r in results
        @printf("%-20s | %-12s | %12.3f | %-8s | %15.6e\n", 
                r.optimizer, r.jacobian, r.time_ms, 
                r.success ? "✓" : "✗", r.final_norm)
    end
    
    working_count = sum(r.success for r in results)
    println("\n$(working_count) out of $(length(results)) optimizers successfully solved the system")
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
    
    # Run NonlinearSolve optimizer benchmarks
    println("\n" * "="^80)
    println("RUNNING NONLINEARSOLVE OPTIMIZER BENCHMARKS")
    println("="^80)
    nlsolve_results = benchmark_nlsolve_optimizers(poly_system, varlist)
    summarize_nlsolve_results(nlsolve_results)
    
    println("\n" * "="^80)
    println("BENCHMARK COMPLETE")
    println("="^80)
end

main()