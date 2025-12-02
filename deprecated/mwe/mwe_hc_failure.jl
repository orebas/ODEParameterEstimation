# MWE: Groebner.jl threading bug during identifiability checking
#
# Bug Location: Groebner.jl _groebner_learn_and_apply_threaded
# File: ~/.julia/packages/Groebner/k40dp/src/groebner/groebner.jl:450
#
# Error: BoundsError: attempt to access 7-element Vector at index [8]
#
# Key observation: With JULIA_NUM_THREADS=7, error tries to access index 8
# This suggests an off-by-one error or miscounted thread index in Groebner.jl
#
# Root cause: Thread indexing issue in Groebner basis computation
# Called from: StructuralIdentifiability.field_contains_algebraic
#
# Workaround: Try with JULIA_NUM_THREADS=1
#   julia -t 1 --startup-file=no --project mwe_hc_failure.jl
#
# To report: https://github.com/sumiya11/Groebner.jl/issues

using ODEParameterEstimation

# Use the simplest model
pep = simple()

# Get the time interval
time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

# Options that trigger the failure
opts = EstimationOptions(
    datasize = 101,
    noise_level = 0.0,
    time_interval = time_interval,
    system_solver = SolverHC,  # This solver triggers the issue
    flow = FlowStandard,
    use_si_template = true,
    diagnostics = true,
)

println("=" ^ 60)
println("MWE: Groebner.jl threading bug")
println("=" ^ 60)
println("\nModel: simple")
println("Solver: SolverHC (HomotopyContinuation)")
println("Julia version: $(VERSION)")
println("Threads: $(Threads.nthreads())")
println()

# Sample data
println("Sampling problem data...")
pep_with_data = sample_problem_data(pep, opts)

# This should fail at "Checking identifiability" step
println("\nRunning parameter estimation (expect failure at identifiability check)...")
try
    result = analyze_parameter_estimation_problem(pep_with_data, opts)
    println("SUCCESS: Got $(length(result)) solutions")
    for (i, r) in enumerate(result)
        println("  Solution $i: err=$(r.err)")
    end
catch e
    println("\nFAILED with error:")
    println("  Type: $(typeof(e))")
    if e isa CompositeException
        println("  Inner exceptions:")
        for (i, inner) in enumerate(e.exceptions)
            println("    [$i] $(typeof(inner))")
            if inner isa TaskFailedException
                println("        Task error: $(inner.task.result)")
            end
        end
    else
        println("  Message: $e")
    end
    println()
    println("Full stacktrace:")
    showerror(stdout, e, catch_backtrace())
end

println("\n" * "=" ^ 60)
println("MWE complete")
println("=" ^ 60)
