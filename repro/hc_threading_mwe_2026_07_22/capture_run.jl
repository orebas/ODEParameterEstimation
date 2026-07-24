# capture_run.jl — run a real ODEPE estimation with the temp capture hook active,
# so convert_to_hc_format serializes each fresh HC system to a pure-HC .jl file.
# The hook is in src/core/homotopy_continuation.jl (reverted after capture).
#
# Usage: ODEPE_HC_DUMP=<dir> ODEPE_HC_DUMP_TAG=<tag> \
#          julia --startup-file=no -t 1 capture_run.jl <model_symbol>
# Run under `timeout`; -t 1 so the capture run itself can't deadlock in HC.

using ODEParameterEstimation
include(joinpath(pkgdir(ODEParameterEstimation), "src", "examples", "load_examples.jl"))

model = Symbol(ARGS[1])
haskey(ALL_MODELS, model) || error("unknown model $model")
println("=== capture: building model $model ===" ); flush(stdout)
pep = ALL_MODELS[model]()

opts = EstimationOptions(
	use_parameter_homotopy = false,   # multishot solves each shooting point fresh -> many captures
	datasize = 201,
	noise_level = 1e-6,
	system_solver = SolverHC,
	flow = FlowStandard,
	use_si_template = true,
	polish_solver_solutions = false,
	polish_solutions = false,
	interpolator = InterpolatorAAAD,
	nooutput = true,
	diagnostics = false,
	save_system = false,
)

println("=== sampling data ==="); flush(stdout)
pep_with_data = sample_problem_data(pep, opts)

println("=== analyze (capturing HC systems via hook) ==="); flush(stdout)
try
	res = analyze_parameter_estimation_problem(pep_with_data, opts)
	println("=== analyze returned $(length(res)) solutions ===")
catch err
	println("=== analyze threw (captures still written): $(typeof(err)) ===")
end
println("=== capture run complete for $model ==="); flush(stdout)
