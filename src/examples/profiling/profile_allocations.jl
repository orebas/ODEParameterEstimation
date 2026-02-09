# Allocation profiling script for ODEParameterEstimation
#
# Usage: julia src/examples/profiling/profile_allocations.jl
#
# Prerequisites:
#   julia -e 'using Pkg; Pkg.add("PProf")'
#
# This script:
#   1. Loads a model from the example registry
#   2. Runs once to warm up (JIT compile everything)
#   3. Runs again under Profile.Allocs to capture allocation call stacks
#   4. Saves a pprof file and opens the interactive web viewer
#
# The web viewer shows an interactive flamegraph where you can drill into
# which function calls are responsible for the most allocations.

# ─── Configuration ───────────────────────────────────────────────────────
MODEL_NAME = :simple              # Change this to profile different models
SAMPLE_RATE = 0.1                 # 0.01 = fast/coarse, 1.0 = slow/complete
DATASIZE = 201
SOLVER = :SolverHC
SHOOTING_POINTS = 1
NOISE_LEVEL = 0.0
# ─────────────────────────────────────────────────────────────────────────

# Check for PProf before doing expensive loading
pprof_available = try
	@eval using PProf
	true
catch
	false
end

if !pprof_available
	println("""
	ERROR: PProf.jl not found in your environment.

	Install it with:
	    julia -e 'using Pkg; Pkg.add("PProf")'

	PProf is intentionally NOT a dependency of ODEParameterEstimation.
	It only needs to be in your global Julia environment.
	""")
	exit(1)
end

using Profile

# Load the package and examples
println("Loading ODEParameterEstimation...")
using ODEParameterEstimation
include(joinpath(@__DIR__, "..", "load_examples.jl"))

# Look up the model
if !haskey(ALL_MODELS, MODEL_NAME)
	println("ERROR: Model :$MODEL_NAME not found. Available models:")
	for name in sort(collect(keys(ALL_MODELS)))
		println("  :$name")
	end
	exit(1)
end

model_fn = ALL_MODELS[MODEL_NAME]
solver_enum = getfield(ODEParameterEstimation, SOLVER)

# Create the problem
println("Setting up model: $MODEL_NAME")
pep = model_fn()
opts = EstimationOptions(
	datasize = DATASIZE,
	system_solver = solver_enum,
	shooting_points = SHOOTING_POINTS,
	noise_level = NOISE_LEVEL,
	profile_phases = true,  # Also show the per-phase breakdown
)
sampled = sample_problem_data(pep, opts)

# Warmup run (compile everything)
println("\n", "="^60)
println("=== Warmup run (compiling) ===")
println("="^60)
@time analyze_parameter_estimation_problem(sampled, opts)

# Clear allocation data and GC
GC.gc()
Profile.Allocs.clear()

# Profiled run
println("\n", "="^60)
println("=== Profiled run (sample_rate=$SAMPLE_RATE) ===")
println("="^60)
Profile.Allocs.@profile sample_rate = SAMPLE_RATE begin
	@time analyze_parameter_estimation_problem(sampled, opts)
end

# Save and view
outpath = "alloc_profile_$(MODEL_NAME).pb.gz"
println("\nGenerating pprof flamegraph...")
PProf.Allocs.pprof(from_c = false, web = true, out = outpath)
println("\nProfile saved to: $outpath")
println("Web viewer should open automatically.")
println("If not, navigate to: http://localhost:57599")
println("\nPress Ctrl+C to stop the web server when done.")

# Keep the script alive so the web server stays running
try
	while true
		sleep(1)
	end
catch e
	if isa(e, InterruptException)
		println("\nShutting down.")
	else
		rethrow(e)
	end
end
