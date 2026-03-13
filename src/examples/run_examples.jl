include("load_examples.jl")

using Random

const EXCLUDED_MODELS = Set([
	:swing_equation,
	:two_tank,
	:ball_beam,
	:crauste,
	:cstr,
	:crauste_revised,
	:cart_pole,
	:magnetic_levitation,
	:boost_converter,
])

function default_example_models(; include_hard = false)
	model_pool = include_hard ? collect(keys(ALL_MODELS)) : collect(keys(STANDARD_MODELS))
	return sort(filter(model -> model ∉ EXCLUDED_MODELS, model_pool))
end

function default_example_options(; smoke = false)
	return EstimationOptions(
		use_parameter_homotopy = !smoke,
		datasize = smoke ? 31 : 1001,
		noise_level = 1e-8,
		system_solver = SolverHC,
		flow = FlowStandard,
		use_si_template = true,
		polish_solver_solutions = !smoke,
		polish_solutions = false,
		polish_maxiters = 50,
		polish_method = PolishLBFGS,
		opt_ad_backend = :enzyme,
		interpolator = smoke ? InterpolatorAAAD : InterpolatorAGPRobust,
		nooutput = smoke,
		diagnostics = !smoke,
		save_system = false,
	)
end

function parse_model_selection(raw)
	isempty(strip(raw)) && return Symbol[]
	return Symbol.(split(raw, ','))
end

function run_example_driver(;
	models = nothing,
	smoke = false,
	include_hard = false,
	shuffle_models = true,
	opts = nothing,
	log_dir = nothing,
	doskip = false,
)
	selected_models = isnothing(models) ? default_example_models(include_hard = include_hard) : collect(models)
	if shuffle_models
		Random.shuffle!(selected_models)
	end

	run_opts = isnothing(opts) ? default_example_options(smoke = smoke) : opts
	resolved_log_dir = isnothing(log_dir) ? joinpath(@__DIR__, "logs") : log_dir

	return run_parameter_estimation_examples(
		models = selected_models,
		opts = run_opts,
		log_dir = resolved_log_dir,
		doskip = doskip,
	)
end

if abspath(PROGRAM_FILE) == @__FILE__
	env_models = get(ENV, "ODEPE_EXAMPLE_MODELS", "")
	selected_models = isempty(env_models) ? nothing : parse_model_selection(env_models)
	smoke = get(ENV, "ODEPE_EXAMPLE_SMOKE", "0") == "1"
	include_hard = get(ENV, "ODEPE_EXAMPLE_INCLUDE_HARD", "0") == "1"
	shuffle_models = get(ENV, "ODEPE_EXAMPLE_SHUFFLE", "1") == "1"
	doskip = get(ENV, "ODEPE_EXAMPLE_DOSKIP", "0") == "1"
	run_example_driver(
		models = selected_models,
		smoke = smoke,
		include_hard = include_hard,
		shuffle_models = shuffle_models,
		doskip = doskip,
	)
end
