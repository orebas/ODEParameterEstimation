using Pkg

# List of packages to install for the mega benchmark
packages = [
    # Standard solvers
    "NLsolve",
    "Optim",
    "JuMP",
    "Ipopt",
    "NLopt",
    
    # Metaheuristic and evolutionary algorithms
    "Metaheuristics",
    "BlackBoxOptim", 
    "Evolutionary",
    
    # Interval and symbolic methods
    "IntervalRootFinding",
    "IntervalArithmetic",
    
    # Bayesian optimization
    "BayesianOptimization",
    
    # Additional optimization
    "Optimization",
    "OptimizationNLopt",
    "OptimizationOptimJL",
    "OptimizationBBO",
    
    # Manifold optimization
    "Manifolds",
    "Manopt",
    
    # Surrogate modeling
    "Surrogates",
    
    # Additional specialized packages
    "BifurcationKit",
    "EAGO",
    
    # Utilities
    "QuasiMonteCarlo",
    "LinearAlgebra",
    "Random",
    "Statistics"
]

println("Installing packages for mega benchmark...")
for pkg in packages
    try
        println("Installing $pkg...")
        Pkg.add(pkg)
        println("✓ $pkg installed")
    catch e
        println("✗ Could not install $pkg: ", e)
    end
end

println("\nInstallation complete!")