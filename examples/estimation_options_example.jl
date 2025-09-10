# Example of using the new EstimationOptions struct
using ODEParameterEstimation
using ModelingToolkit

# Create a simple ODE system for demonstration
@parameters a b
@variables t x(t) y(t)
D = Differential(t)

eqs = [
    D(x) ~ -a * x + b,
    D(y) ~ a * x - b * y
]

@named sys = ODESystem(eqs, t)

# Create a parameter estimation problem
# (This is just for demonstration - you'd normally have real data)
model = OrderedODESystem(sys, [a, b], [x, y])
measured_quantities = [x ~ x, y ~ y]
p_true = [1.0, 0.5]
p_init = [2.0, 1.0]
u0 = [1.0, 0.0]

PEP = ParameterEstimationProblem(
    "Example System",
    model,
    measured_quantities,
    nothing,  # data_sample - would be filled with real data
    nothing,  # solver
    p_true,
    p_init,
    u0
)

# Example 1: Using EstimationOptions with defaults
println("Example 1: Default options")
opts = EstimationOptions()
println("System solver: ", opts.system_solver)
println("Interpolator: ", opts.interpolator)
println("Tolerances: abstol=$(opts.abstol), reltol=$(opts.reltol)")
println()

# Example 2: Creating options with specific settings
println("Example 2: Custom options")
opts_custom = EstimationOptions(
    system_solver = SolverHC,           # Use HomotopyContinuation
    interpolator = InterpolatorAAAD,    # Use basic AAAD interpolation
    abstol = 1e-12,
    reltol = 1e-12,
    polish_solutions = true,
    polish_method = PolishLBFGS,
    shooting_points = 12,
    max_num_points = 3,
    diagnostics = true
)
println("Custom system solver: ", opts_custom.system_solver)
println("Custom interpolator: ", opts_custom.interpolator)
println("Polish method: ", opts_custom.polish_method)
println()

# Example 3: Using options with actual functions
println("Example 3: Using with estimation functions")

# First generate some synthetic data
PEP_with_data = sample_problem_data(PEP, opts)

# Method 1: Pass EstimationOptions directly
# results = analyze_parameter_estimation_problem(PEP_with_data, opts_custom)

# Method 2: Still works with old keyword syntax for backward compatibility
# results = analyze_parameter_estimation_problem(
#     PEP_with_data,
#     system_solver = solve_with_hc,
#     abstol = 1e-12,
#     polish_solutions = true
# )

println("EstimationOptions can be used with:")
println("  - analyze_parameter_estimation_problem(PEP, opts)")
println("  - multipoint_parameter_estimation(PEP, opts)")
println("  - multishot_parameter_estimation(PEP, opts)")
println("  - optimized_multishot_parameter_estimation(PEP, opts)")
println("  - sample_problem_data(PEP, opts)")
println()

# Example 4: Merging options
println("Example 4: Merging options")
opts_base = EstimationOptions(abstol = 1e-10)
opts_merged = merge_options(opts_base, 
    system_solver = SolverNLOpt,
    polish_solutions = true
)
println("Merged options - solver: ", opts_merged.system_solver)
println("Merged options - abstol: ", opts_merged.abstol)
println("Merged options - polish: ", opts_merged.polish_solutions)
println()

# Example 5: Getting actual functions from enums
println("Example 5: Converting enums to functions")
solver_func = get_solver_function(opts_custom.system_solver)
interp_func = get_interpolator_function(opts_custom.interpolator)
polish_opt = get_polish_optimizer(opts_custom.polish_method)
println("Solver function: ", solver_func)
println("Interpolator function: ", interp_func)
println("Polish optimizer: ", polish_opt)
println()

# Example 6: Validation
println("Example 6: Validating options")
if validate_options(opts_custom)
    println("Options are valid!")
else
    println("Options have issues - check warnings above")
end