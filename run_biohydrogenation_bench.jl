#!/usr/bin/env julia
# Single biohydrogenation run with SLURM benchmark-equivalent settings
# (polish_solutions=true, BFGS 200k iters, matching SciML polisher)

include("src/examples/load_examples.jl")

using SciMLBase
using Optimization
using OptimizationOptimJL
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim

# Match SLURM benchmark settings exactly
bench_opts = EstimationOptions(
    datasize = 1001,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    use_parameter_homotopy = true,
    polish_solver_solutions = true,
    polish_solutions = true,          # KEY: enable polishing
    polish_maxiters = 200000,         # KEY: match SciML's 200k iterations
    polish_method = PolishBFGS,       # KEY: full BFGS Hessian
    opt_maxiters = 200000,
    opt_lb = 1e-5 * ones(10),        # 6 params + 4 states = 10 unknowns
    opt_ub = 10.0 * ones(10),
    abstol = 1e-13,
    reltol = 1e-13,
    diagnostics = true,
    profile_phases = true,            # Show phase timing table
)

println("="^60)
println("Biohydrogenation benchmark run")
println("  polish_solutions = true")
println("  polish_maxiters  = 200000")
println("  polish_method    = PolishBFGS")
println("  profile_phases   = true")
println("="^60)
println()

t_total = @elapsed begin
    run_parameter_estimation_examples(
        models = [:biohydrogenation],
        opts = bench_opts,
    )
end

println()
println("="^60)
println("Total wall time: $(round(t_total; digits=1))s")
println("="^60)
