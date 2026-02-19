# Standalone CSTR benchmark replication
#
# This runs ODEPE on the CSTR model that matches the ParameterEstimationBenchmarking
# "cstr" system (config/systems.json). The benchmark version has:
#   - 5 parameters: tau, Tin, Cin, dH_rhoCP, UA_VrhoCP
#   - E_R (activation energy) baked in as a constant (8750 K)
#   - k0 absorbed into r_eff state variable
#   - Sinusoidal coolant input Tc(t) = 300 + 10*sin(0.5t)
#
# In the benchmark, all params are scaled so p_true = 0.5 maps to the
# realistic values below. This script uses the original (unscaled) values.
#
# Usage: julia run_cstr_benchmark.jl

include("load_examples.jl")

using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
using AbstractAlgebra
using Random

# cstr_fixed_activation() is the ODEPE model matching the benchmark:
#   params: tau=1.0, Tin=350.0, Cin=1.0, dH_rhoCP=5.0, UA_VrhoCP=1.0
#   states: C(0)=0.5, T(0)=350.0, r_eff(0)≈1.0, u_sin(0)=0, u_cos(0)=1
#   observes: T, u_sin, u_cos

opts = EstimationOptions(
    use_parameter_homotopy = true,
    datasize = 1001,
    noise_level = 0.0,        # noiseless first
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 50,
    polish_method = PolishLBFGS,
    interpolator = InterpolatorAGPRobust,
    diagnostics = true,
)

println("=" ^ 70)
println("CSTR Benchmark Replication")
println("=" ^ 70)
println("Model: cstr_fixed_activation (matches benchmark 'cstr')")
println("True parameters:")
println("  tau       = 1.0    (residence time, s)")
println("  Tin       = 350.0  (inlet temperature, K)")
println("  Cin       = 1.0    (inlet concentration, mol/L)")
println("  dH_rhoCP  = 5.0    (heat release parameter)")
println("  UA_VrhoCP = 1.0    (heat transfer parameter)")
println("  E_R       = 8750.0 (FIXED, not estimated)")
println()
println("True initial conditions:")
println("  C(0)     = 0.5")
println("  T(0)     = 350.0")
println("  r_eff(0) = $(7.2e10 * exp(-8750.0/350.0))")
println("  u_sin(0) = 0.0")
println("  u_cos(0) = 1.0")
println("=" ^ 70)
println()

# Delete cached log so it doesn't skip
log_path = joinpath("logs", "cstr_fixed_activation.log")
isfile(log_path) && rm(log_path)

run_parameter_estimation_examples(models = [:cstr_fixed_activation], opts = opts)

# Print the log file so results appear on console
if isfile(log_path)
    println("\n" * "=" ^ 70)
    println("RESULTS (from $log_path)")
    println("=" ^ 70)
    print(read(log_path, String))
end
