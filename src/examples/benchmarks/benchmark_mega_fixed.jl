using ODEParameterEstimation
using Dates
using Printf
using Random
using OrderedCollections: OrderedDict
using Symbolics
using LinearAlgebra

# Import all the solver packages we can
packages_to_try = [
    :NLsolve,
    :Optim, 
    :NLopt,
    :Metaheuristics,
    :BlackBoxOptim,
    :Evolutionary,
    :IntervalRootFinding,
    :IntervalArithmetic,
]

# Try to import each package
available_packages = Symbol[]
for pkg in packages_to_try
    try
        @eval using $pkg
        push!(available_packages, pkg)
        println("✓ Loaded $pkg")
    catch e
        println("✗ Could not load $pkg: ", typeof(e))
    end
end

# Already loaded: NonlinearSolve, ForwardDiff, FiniteDiff

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

# Create residual function
function create_residual_function(poly_system, varlist)
    function residual!(res, u, p=nothing)
        d = Dict(zip(varlist, u))
        for (i, eq) in enumerate(poly_system)
            val = Symbolics.value(Symbolics.substitute(eq, d))
            res[i] = convert(eltype(res), val)
        end
        return nothing
    end
    
    # Also create scalar objective for optimization
    function objective(u)
        res = zeros(length(poly_system))
        residual!(res, u)
        return 0.5 * sum(res.^2)
    end
    
    return residual!, objective
end

# Test a solver with error handling
function test_solver(name, solver_func, poly_system, varlist; max_time=30.0, verbose=true)
    if verbose
        println("\nTesting: $name")
    end
    
    m = length(poly_system)
    n = length(varlist)
    x0 = ones(n) * 0.5
    
    residual!, objective = create_residual_function(poly_system, varlist)
    
    sol = nothing
    t_ms = NaN
    success = false
    final_norm = Inf
    error_msg = ""
    
    try
        sol, t_ms = timeit(() -> solver_func(poly_system, varlist, residual!, objective, x0))
        
        if !isnothing(sol)
            # Extract solution vector - handle different result types
            x_sol = if isa(sol, Vector)
                sol
            elseif hasproperty(sol, :u)
                sol.u
            elseif hasproperty(sol, :minimizer)
                sol.minimizer
            elseif hasproperty(sol, :zero)
                sol.zero
            elseif hasproperty(sol, :x)
                sol.x
            elseif hasproperty(sol, :best_candidate)
                # BlackBoxOptim specific
                sol.best_candidate
            else
                nothing
            end
            
            if !isnothing(x_sol) && length(x_sol) == n
                res = zeros(m)
                residual!(res, x_sol)
                final_norm = norm(res)
                success = final_norm < 1e-3
            elseif verbose
                println("  Warning: Could not extract solution vector from result type: ", typeof(sol))
            end
        end
    catch e
        error_msg = string(typeof(e))
        if verbose
            println("  Error: ", typeof(e))
            if isa(e, MethodError)
                println("    Method: ", e.f)
                println("    Args types: ", typeof.(e.args))
            end
            # Uncomment to see full error:
            # showerror(stdout, e)
            # println()
        end
    end
    
    return (name=name, time_ms=t_ms, success=success, final_norm=final_norm, error=error_msg)
end

# Collection of solver implementations
function get_all_solvers()
    solvers = OrderedDict{String, Function}()
    
    # 1. NLsolve.jl solvers
    if :NLsolve in available_packages
        solvers["NLsolve_newton"] = function(poly_system, varlist, residual!, objective, x0)
            m = length(poly_system)
            n = length(varlist)
            
            function f!(F, x)
                residual!(F, x)
            end
            
            result = NLsolve.nlsolve(f!, x0, method=:newton, autodiff=:forward)
            return result
        end
        
        solvers["NLsolve_trust_region"] = function(poly_system, varlist, residual!, objective, x0)
            function f!(F, x)
                residual!(F, x)
            end
            result = NLsolve.nlsolve(f!, x0, method=:trust_region, autodiff=:forward)
            return result
        end
        
        solvers["NLsolve_anderson"] = function(poly_system, varlist, residual!, objective, x0)
            function f!(F, x)
                residual!(F, x)
            end
            # Anderson needs a better initial guess or different parameters
            result = NLsolve.nlsolve(f!, x0, method=:anderson, m=5, autodiff=:forward)
            return result
        end
        
        solvers["NLsolve_broyden"] = function(poly_system, varlist, residual!, objective, x0)
            function f!(F, x)
                residual!(F, x)
            end
            result = NLsolve.nlsolve(f!, x0, method=:broyden, autodiff=:forward)
            return result
        end
    end
    
    # 2. Optim.jl solvers (minimize ||F||^2)
    if :Optim in available_packages
        solvers["Optim_BFGS"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.BFGS(), autodiff=:forward)
            return result
        end
        
        solvers["Optim_LBFGS"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.LBFGS())
            return result
        end
        
        solvers["Optim_NelderMead"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.NelderMead())
            return result
        end
        
        solvers["Optim_SimulatedAnnealing"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.SimulatedAnnealing())
            return result
        end
        
        solvers["Optim_ParticleSwarm"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            lower = fill(-10.0, n)
            upper = fill(10.0, n)
            result = Optim.optimize(objective, lower, upper, x0, Optim.ParticleSwarm())
            return result
        end
        
        solvers["Optim_Newton"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.Newton(), autodiff=:forward)
            return result
        end
        
        solvers["Optim_ConjugateGradient"] = function(poly_system, varlist, residual!, objective, x0)
            result = Optim.optimize(objective, x0, Optim.ConjugateGradient())
            return result
        end
    end
    
    # 3. Metaheuristics.jl algorithms - FIXED API
    if :Metaheuristics in available_packages
        # Helper to extract solution from Metaheuristics result
        function extract_metaheuristics_solution(result)
            # Use minimizer function for Metaheuristics results
            try
                return Metaheuristics.minimizer(result)
            catch
                # Fallback to positions if minimizer doesn't work
                try
                    pos = Metaheuristics.positions(result)
                    return pos[1, :]  # First row is best solution
                catch
                    return nothing
                end
            end
        end
        
        # Differential Evolution
        solvers["Metaheuristics_DE"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.DE())
            # Return a custom object with the solution
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Particle Swarm Optimization
        solvers["Metaheuristics_PSO"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.PSO())
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Simulated Annealing
        solvers["Metaheuristics_SA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.SA())
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Genetic Algorithm - Fix the API call
        solvers["Metaheuristics_GA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            # GA needs specific parameters
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.GA(N=100))
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Evolutionary Centers Algorithm
        solvers["Metaheuristics_ECA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.ECA())
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Whale Optimization Algorithm
        solvers["Metaheuristics_WOA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.WOA())
            return (minimizer = extract_metaheuristics_solution(result))
        end
        
        # Add more exotic algorithms
        solvers["Metaheuristics_ABC"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            bounds = Metaheuristics.BoxConstrainedSpace(lb=fill(-10.0, n), ub=fill(10.0, n))
            result = Metaheuristics.optimize(objective, bounds, Metaheuristics.ABC())  # Artificial Bee Colony
            return (minimizer = extract_metaheuristics_solution(result))
        end
    end
    
    # 4. BlackBoxOptim.jl - FIXED API
    if :BlackBoxOptim in available_packages
        solvers["BlackBoxOptim_default"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            result = BlackBoxOptim.bboptimize(objective; 
                                             SearchRange = [(-10.0, 10.0) for _ in 1:n],
                                             MaxTime = 5.0,
                                             TraceMode = :silent)
            # Use best_candidate function
            return (minimizer = BlackBoxOptim.best_candidate(result))
        end
        
        solvers["BlackBoxOptim_adaptive_de"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            result = BlackBoxOptim.bboptimize(objective; 
                                             SearchRange = [(-10.0, 10.0) for _ in 1:n],
                                             Method = :adaptive_de_rand_1_bin,
                                             MaxTime = 5.0,
                                             TraceMode = :silent)
            return (minimizer = BlackBoxOptim.best_candidate(result))
        end
        
        solvers["BlackBoxOptim_xnes"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            result = BlackBoxOptim.bboptimize(objective; 
                                             SearchRange = [(-10.0, 10.0) for _ in 1:n],
                                             Method = :xnes,
                                             MaxTime = 5.0,
                                             TraceMode = :silent)
            return (minimizer = BlackBoxOptim.best_candidate(result))
        end
        
        solvers["BlackBoxOptim_borg"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            result = BlackBoxOptim.bboptimize(objective; 
                                             SearchRange = [(-10.0, 10.0) for _ in 1:n],
                                             Method = :borg_moea,
                                             MaxTime = 5.0,
                                             TraceMode = :silent)
            return (minimizer = BlackBoxOptim.best_candidate(result))
        end
    end
    
    # 5. Evolutionary.jl - FIX API
    if :Evolutionary in available_packages
        solvers["Evolutionary_CMAES"] = function(poly_system, varlist, residual!, objective, x0)
            result = Evolutionary.optimize(objective, x0, Evolutionary.CMAES(μ = 10, λ = 20))
            return result
        end
        
        # GA needs bounds
        solvers["Evolutionary_GA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            # Create a constrained version
            cons = Evolutionary.BoxConstraints(fill(-10.0, n), fill(10.0, n))
            result = Evolutionary.optimize(objective, cons, x0, 
                                          Evolutionary.GA(populationSize = 100,
                                                        selection = Evolutionary.tournament(5),
                                                        crossover = Evolutionary.intermediate(0.5),
                                                        mutation = Evolutionary.gaussian(0.1)))
            return result
        end
        
        solvers["Evolutionary_DE"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            cons = Evolutionary.BoxConstraints(fill(-10.0, n), fill(10.0, n))
            result = Evolutionary.optimize(objective, cons, x0, Evolutionary.DE())
            return result
        end
    end
    
    # 6. IntervalRootFinding.jl
    if :IntervalRootFinding in available_packages && :IntervalArithmetic in available_packages
        solvers["IntervalRootFinding"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            m = length(poly_system)
            
            # Create interval function
            function F(x)
                res = zeros(m)
                residual!(res, x)
                return res
            end
            
            # Define search box
            X = IntervalArithmetic.IntervalBox(-10..10, n)
            
            # Find roots
            roots = IntervalRootFinding.roots(F, X, IntervalRootFinding.Newton, 1e-5)
            
            if !isempty(roots)
                # Return the midpoint of the first root found
                root = roots[1]
                return (minimizer = IntervalArithmetic.mid.(root.interval))
            else
                return nothing
            end
        end
    end
    
    # 7. NLopt.jl algorithms
    if :NLopt in available_packages
        solvers["NLopt_LN_COBYLA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:LN_COBYLA, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
        
        solvers["NLopt_LN_BOBYQA"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:LN_BOBYQA, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
        
        solvers["NLopt_GN_DIRECT"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:GN_DIRECT, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            opt.maxeval = 10000
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
        
        solvers["NLopt_GN_CRS2"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:GN_CRS2_LM, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
        
        solvers["NLopt_GN_ISRES"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:GN_ISRES, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            opt.maxeval = 10000
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
        
        solvers["NLopt_GN_ESCH"] = function(poly_system, varlist, residual!, objective, x0)
            n = length(x0)
            opt = NLopt.Opt(:GN_ESCH, n)
            opt.min_objective = (x, grad) -> objective(x)
            opt.lower_bounds = fill(-10.0, n)
            opt.upper_bounds = fill(10.0, n)
            opt.ftol_abs = 1e-8
            
            (minf, minx, ret) = NLopt.optimize(opt, x0)
            return (minimizer = minx, minimum = minf)
        end
    end
    
    return solvers
end

# Main benchmark function
function run_mega_benchmark(poly_system, varlist; verbose=true)
    println("\n" * "="^80)
    println("MEGA BENCHMARK - Testing All Available Solvers")
    println("="^80)
    
    solvers = get_all_solvers()
    results = []
    
    for (name, solver_func) in solvers
        result = test_solver(name, solver_func, poly_system, varlist, verbose=verbose)
        push!(results, result)
        
        if verbose
            @printf("  %-30s: %8.2f ms | Success: %s | Norm: %.6e\n", 
                    result.name, result.time_ms, 
                    result.success ? "✓" : "✗", result.final_norm)
        end
    end
    
    return results
end

# Summary function
function summarize_results(results)
    println("\n" * "="^80)
    println("MEGA BENCHMARK SUMMARY")
    println("="^80)
    
    # Sort by success and time
    successful = filter(r -> r.success, results)
    sort!(successful, by = r -> r.time_ms)
    
    failed = filter(r -> !r.success, results)
    
    println("\n=== Successful Solvers (sorted by time) ===")
    @printf("%-30s | %10s | %15s\n", "Solver", "Time (ms)", "Final Norm")
    println("-"^60)
    for r in successful
        @printf("%-30s | %10.3f | %15.6e\n", r.name, r.time_ms, r.final_norm)
    end
    
    if !isempty(failed)
        println("\n=== Failed Solvers ===")
        @printf("%-30s | %10s | %15s | %s\n", "Solver", "Time (ms)", "Final Norm", "Error")
        println("-"^80)
        for r in failed
            @printf("%-30s | %10.3f | %15.6e | %s\n", 
                    r.name, isnan(r.time_ms) ? 0.0 : r.time_ms, r.final_norm, r.error)
        end
    end
    
    println("\n=== Statistics ===")
    println("Total solvers tested: $(length(results))")
    println("Successful: $(length(successful))")
    println("Failed: $(length(failed))")
    if !isempty(successful)
        println("Fastest: $(successful[1].name) ($(round(successful[1].time_ms, digits=2)) ms)")
        println("Average time (successful): $(round(mean([r.time_ms for r in successful]), digits=2)) ms")
    end
end

# Main function
function main()
    # Load system
    system_file = joinpath(@__DIR__, "saved_systems", "system_point_1_2025-09-11T00:02:53.925.jl")
    
    println("[Info] Loading saved system from: ", system_file)
    (poly_system, varlist) = load_system(system_file)
    println("[Info] Loaded system with ", length(poly_system), " equations and ", length(varlist), " variables.")
    
    # Run mega benchmark
    results = run_mega_benchmark(poly_system, varlist, verbose=true)
    
    # Summarize
    summarize_results(results)
end

# Helper to compute mean
function mean(x)
    return sum(x) / length(x)
end

main()