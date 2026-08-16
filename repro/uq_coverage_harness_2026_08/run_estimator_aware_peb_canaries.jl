# Estimator-aware UQ canaries sourced from the audited PEB paper benchmark.
#
# This is intentionally not a benchmark sweep. The default three cells were
# selected from the frozen final-v2 PEB run because ODEPE historically produced
# accurate polished estimates and the saved metadata identifies the winning
# algebraic seed route: multipoint for LV/FHN and single-point for Van der Pol.
# The current run asks whether the selected trajectory estimator and its retained
# lineage/UQ artifact still tell that truth.
#
# The default uses all 750 frozen noisy observations. A reduced row count is an
# explicitly requested speed smoke, not a reproduction: FHN candidate ranking
# changed materially when the same cell was evenly reduced to 121 observations.

include(joinpath(@__DIR__, "run_estimator_aware_nonlinear.jl"))

using DelimitedFiles
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using SHA
using Symbolics: Num

const PEB_SNAPSHOT = "benchmark_final_v2_2026-06-12"
const PEB_RESULTS_SNAPSHOT = "results/final_v2_2026_06_12"
const PEB_FROZEN_SHA = "c94e0a3eb5bbd8ab95c73e30f203cbad73485d7b"

const PEB_AUDITED_CASES = Dict(
	"lotka_volterra_2_1em4" => (
		model = :lotka_volterra,
		instance = 2,
		noise = 1e-4,
		p_true = [0.467, 0.428, 0.825],
		ic = [0.606, 0.288],
		time_interval = [0.0, 20.0],
		data_sha256 = "2d32165c2153f481b948abb3fc5946792501f21c88461a2ddc5bfb54933cf24e",
		generator_sha256 = "12ecb6e437d7554809cc5ec59bcd02e995ddf0b4498fc49a2dd1a32d71864646",
		metadata_sha256 = "c739246934bcd95bae6bc12e73e61a3cb2e3bf34c30284db6974a31566098eb3",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [16, 635],
		historical_interpolator = :s3_adapt_se,
		historical_max_error = 1.513708871692881e-5,
	),
	"vanderpol_2_1em4" => (
		model = :vanderpol,
		instance = 2,
		noise = 1e-4,
		p_true = [0.685, 0.851],
		ic = [0.178, 0.689],
		time_interval = [0.0, 10.0],
		data_sha256 = "65ed9a23b41e07298a911dfc2f697621b6a815c12752b5f997c8e276a473ecbb",
		generator_sha256 = "51edc95bfcaf31d1ff9bf13e1ebe3dca6491edc900b8c1d753c39a7bd090c48b",
		metadata_sha256 = "29a109daef065b46fe4118acbc02c4dac958fd9574dde17e1db4835a21c61286",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :single_point_algebraic,
		historical_time_indices = [267],
		historical_interpolator = :aaad_gpr,
		historical_max_error = 1.5240685054897487e-6,
	),
	"fitzhugh_nagumo_1_1em4" => (
		model = :fitzhugh_nagumo,
		instance = 1,
		noise = 1e-4,
		p_true = [0.611, 0.855, 0.837],
		ic = [0.273, 0.772],
		time_interval = [0.0, 1.0],
		data_sha256 = "bddffad5e352f06057c55db44d1e5a67351fd729497030e159d70e58fb4bd111",
		generator_sha256 = "cdfcc9ad3b76856f027fafa142a765c9f72f515b39747c9415d83ce3121517bf",
		metadata_sha256 = "243d52ba8726ecbcd81104df997175cf48aca86797e421485e5967296703c487",
		historical_run = "odepe_v2_polish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [80, 750],
		historical_interpolator = :agp_robust_rq,
		historical_max_error = 0.0022960063372558215,
	),
	"lotka_volterra_5_1em6" => (
		model = :lotka_volterra,
		instance = 5,
		noise = 1e-6,
		p_true = [0.21, 0.778, 0.688],
		ic = [0.722, 0.879],
		time_interval = [0.0, 20.0],
		data_sha256 = "69bd0ba3d4cc4d188cf470591442542e1cf0ca7c5a074b75ff4d63a04ab469bb",
		generator_sha256 = "953d072fe9ce13f7ace2fa9ee6c211ff96c88edb33b0fd2e5e58616355e37a84",
		metadata_sha256 = "d9991ccd917b1cff9b4ca1a434a85c19eab682d670c74692eaa93556715193d3",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [36, 635],
		historical_interpolator = :s3_adapt_se,
		historical_max_error = 2.533684888894984e-5,
	),
	"fitzhugh_nagumo_9_1em6" => (
		model = :fitzhugh_nagumo,
		instance = 9,
		noise = 1e-6,
		p_true = [0.433, 0.602, 0.729],
		ic = [0.888, 0.603],
		time_interval = [0.0, 1.0],
		data_sha256 = "18eeb2b90c94199f81f24b850ff0eaed3a5b8ac581b1433ac83e1afda027f51a",
		generator_sha256 = "f2f8156c9d8435d9a51dc4adffa6526d8ec8a5d22af31eeb9b164aa8347a6084",
		metadata_sha256 = "3c64c4135209c92b139305ae1a9d7d234bf8be69027b775c49a50de1d57d8f65",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [80, 750],
		historical_interpolator = :s3_adapt_rq,
		historical_max_error = 0.0008993598587535475,
	),
	"slow_fast_5_1em6" => (
		model = :slow_fast,
		instance = 5,
		noise = 1e-6,
		p_true = [0.684, 0.259],
		ic = [0.463, 0.581, 0.276, 0.409, 0.119, 0.237],
		time_interval = [0.0, 10.0],
		data_sha256 = "970d1fea278a3f8266e0ef23fc9bfe10089a85df36a048e323222f8103cf2968",
		generator_sha256 = "87b7bf11be94302406b2c5b825992a97e9859d3dce8f1d75b64145e5020f3a16",
		metadata_sha256 = "92c44494ac91efa535f2cdac72c335fe7db56b556c93bcf776f79a80582fc5fa",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :single_point_algebraic,
		historical_time_indices = [223],
		historical_interpolator = :s3_adapt_se,
		historical_max_error = 3.375537494829148e-6,
	),
	"daisy_mamil4_7_1em6" => (
		model = :daisy_mamil4,
		instance = 7,
		noise = 1e-6,
		p_true = [0.499, 0.329, 0.81, 0.809, 0.732, 0.828, 0.262],
		ic = [0.766, 0.327, 0.605, 0.87],
		time_interval = [0.0, 10.0],
		data_sha256 = "fa0afa689c2fcda01bb5fe1000114fb2f9718b7c79a790e60f1636538a0769b9",
		generator_sha256 = "a2d6e5bee51351e983a9e8b2ecc165c1d3feb3fe447a6ff9ed29c5678ca05af7",
		metadata_sha256 = "1461e11da95e56ec5581e3ab77b84c381b225255c7d6af1d6063390d2bc25e6b",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [36, 635],
		historical_interpolator = :chebyshev_aicc,
		historical_max_error = 9.141657200545128e-6,
	),
	"biohydrogenation_7_1em6" => (
		model = :biohydrogenation,
		instance = 7,
		noise = 1e-6,
		p_true = [0.433, 0.456, 0.446, 0.399, 0.547, 0.822],
		ic = [0.271, 0.868, 0.212, 0.34],
		time_interval = [0.0, 10.0],
		data_sha256 = "63c16823d6a74e28387fd9e1f2ae418025a3b8004fa9ea3089af60cda8c05dca",
		generator_sha256 = "4ec8d1e05644a6bafa1f87e582f75a836657d4ce90735790acb97d283ac4a00a",
		metadata_sha256 = "1e19e1fe3c30a2c29c227a26f9b52a0896861073e6d847838ec7f1321bd054f0",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [25, 635],
		historical_interpolator = :chebyshev_bic,
		historical_max_error = 2.5865284235594527e-5,
	),
	"receptor_binding_5_1em6" => (
		model = :receptor_binding,
		instance = 5,
		noise = 1e-6,
		p_true = [0.162, 0.76, 0.711, 0.677, 0.896, 0.553],
		ic = [0.247, 0.542, 0.269],
		time_interval = [0.0, 8.0],
		data_sha256 = "1a2186b7111b385cc57f26b52daaabb49b627583d7110b1bf18b6ec3ae555201",
		generator_sha256 = "a772d838b3c3a76cafb1d8dd11a9ac044488b18d4e9c9f4c87eddbcd06d41887",
		metadata_sha256 = "3a0e45e4629affd34bf98b994b704efeedc999a8aa53276fe8f8c5d97bf64216",
		historical_run = "odepe_v2_nopolish_run",
		historical_kind = :multipoint_algebraic,
		historical_time_indices = [36, 635],
		historical_interpolator = :aaad_gpr,
		historical_max_error = 1.013147456952175e-5,
	),
)

function _default_peb_root()
	return normpath(joinpath(@__DIR__, "..", "..", "..", "..", "..",
		"ParameterEstimationBenchmark-local"))
end

_sha256_file(path::AbstractString) = bytes2hex(sha256(read(path)))

function _require_frozen_file(root::AbstractString, relative_path::AbstractString,
		expected_sha256::AbstractString)
	path = joinpath(root, relative_path)
	isfile(path) || throw(ArgumentError("missing frozen PEB artifact: $path"))
	actual = _sha256_file(path)
	actual == expected_sha256 || throw(ArgumentError(
		"PEB artifact hash mismatch for $path: expected $expected_sha256, got $actual"))
	return path
end

function _peb_paths(peb_root::AbstractString, case_id::String, case)
	model_instance = "$(case.model)_$(case.instance)"
	generator = _require_frozen_file(peb_root,
		joinpath(PEB_SNAPSHOT, "filetree", "data_generation", "$model_instance.jl"),
		case.generator_sha256)
	data = _require_frozen_file(peb_root,
		joinpath(PEB_RESULTS_SNAPSHOT, "results", "data_noisy", case_id, "data.csv"),
		case.data_sha256)
	metadata = _require_frozen_file(peb_root,
		joinpath(PEB_RESULTS_SNAPSHOT, "results", case.historical_run, case_id,
			"odepe_metadata.json"), case.metadata_sha256)
	return (; generator, data, metadata)
end

function _even_row_indices(n_rows::Int, max_observations::Int)
	(max_observations <= 0 || max_observations >= n_rows) && return collect(1:n_rows)
	max_observations >= 2 || throw(ArgumentError("max-observations must be 0 or at least 2"))
	indices = unique(round.(Int, range(1, n_rows; length = max_observations)))
	length(indices) == max_observations || throw(ArgumentError(
		"could not choose $max_observations unique rows from $n_rows observations"))
	return indices
end

function _peb_data_sample(path::AbstractString, mq, max_observations::Int)
	matrix = Matrix{Float64}(readdlm(path, ',', Float64))
	size(matrix, 2) == length(mq) + 1 || throw(ArgumentError(
		"$path has $(size(matrix, 2)) columns; expected $(length(mq) + 1)"))
	rows = _even_row_indices(size(matrix, 1), max_observations)
	data_sample = OrderedDict{Union{String, Num}, Vector{Float64}}()
	data_sample["t"] = collect(matrix[rows, 1])
	for (column, equation) in enumerate(mq)
		data_sample[Num(equation.rhs)] = collect(matrix[rows, column + 1])
	end
	return data_sample, rows, size(matrix, 1)
end

function _peb_lotka_volterra(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters k1 k2 k3
	states = @variables r(t) w(t)
	observables = @variables y1(t)
	equations = [
		D(r) ~ 2.0 * k1 * r - 2.0 * k2 * w * r,
		D(w) ~ -0.6 * k3 * w + 4.0 * k2 * w * r,
	]
	measured_quantities = [y1 ~ 4.0 * r]
	model, mq = create_ordered_ode_system(
		"lotka_volterra", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"lotka_volterra", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_vanderpol(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters a b
	states = @variables x1(t) x2(t)
	observables = @variables y1(t) y2(t)
	equations = [
		D(x1) ~ 0.5 * a * x2,
		D(x2) ~ -4.0 * x1 + 2.0 * b * x2 - 32.0 * b * x2 * x1^2,
	]
	measured_quantities = [y1 ~ 4.0 * x1, y2 ~ x2]
	model, mq = create_ordered_ode_system(
		"vanderpol", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"vanderpol", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_fitzhugh_nagumo(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters g a b
	states = @variables Vm(t) R(t)
	observables = @variables y1(t)
	equations = [
		D(Vm) ~ (-3.0) * g * (0.5 * R - 2.0 * Vm + (8.0 / 3.0) * Vm^3),
		D(R) ~ (-0.4 * a - 2.0 * Vm + 0.2 * b * R) / (3.0 * g),
	]
	measured_quantities = [y1 ~ -2.0 * Vm]
	model, mq = create_ordered_ode_system(
		"fitzhugh_nagumo", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"fitzhugh_nagumo", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_slow_fast(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters k1 k2
	states = @variables xA(t) xB(t) xC(t) eA(t) eC(t) eB(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t) y5(t)
	equations = [
		D(xA) ~ -0.5 * k1 * xA,
		D(xB) ~ (0.166 * k1 * xA - 0.666 * k2 * xB) / 0.666,
		D(xC) ~ 0.666 * k2 * xB,
		D(eA) ~ 0,
		D(eC) ~ 0,
		D(eB) ~ 0,
	]
	measured_quantities = [
		y1 ~ xC,
		y2 ~ 0.44222400000000006 * xA * eA + 0.9990000000000001 * eB * xB +
			1.666 * xC * eC,
		y3 ~ 1.332 * eA,
		y4 ~ 1.666 * eC,
		y5 ~ 0.9990000000000001 * eB,
	]
	model, mq = create_ordered_ode_system(
		"slow_fast", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"slow_fast", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_daisy_mamil4(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters k01 k12 k13 k14 k21 k31 k41
	states = @variables x1(t) x2(t) x3(t) x4(t)
	observables = @variables y1(t) y2(t) y3(t) y4(t)
	equations = [
		D(x1) ~ (-0.1 * k01 * x1 + 0.4 * k12 * x2 + 0.8999999999999999 * k13 * x3 +
			1.6 * k14 * x4 - 0.5 * k21 * x1 - 0.6000000000000001 * k31 * x1 -
			0.7000000000000001 * k41 * x1) / 0.4,
		D(x2) ~ (-0.4 * k12 * x2 + 0.5 * k21 * x1) / 0.8,
		D(x3) ~ (-0.8999999999999999 * k13 * x3 + 0.6000000000000001 * k31 * x1) / 1.2,
		D(x4) ~ (-1.6 * k14 * x4 + 0.7000000000000001 * k41 * x1) / 1.6,
	]
	measured_quantities = [
		y1 ~ 0.4 * x1,
		y2 ~ 0.8 * x2,
		y3 ~ 1.2 * x3 + 1.6 * x4,
		y4 ~ 1.2 * x3,
	]
	model, mq = create_ordered_ode_system(
		"daisy_mamil4", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"daisy_mamil4", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_biohydrogenation(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters k5 k6 k7 k8 k9 k10
	states = @variables x4(t) x5(t) x6(t) x7(t)
	observables = @variables y1(t) y2(t) y3(t)
	equations = [
		D(x4) ~ (-8.0 * k5 * x4) / (8.0 * (4.0 * k6 + 8.0 * x4)),
		D(x5) ~ ((-0.3 * k7 * x5) / (2.0 * k8 + 0.5 * x6 + 0.5 * x5) +
			(8.0 * k5 * x4) / (4.0 * k6 + 8.0 * x4)) / 0.5,
		D(x6) ~ ((-0.2 * (10.0 * k10 - 0.5 * x6) * k9 * x6) / (10.0 * k10) +
			(0.3 * k7 * x5) / (2.0 * k8 + 0.5 * x6 + 0.5 * x5)) / 0.5,
		D(x7) ~ (0.2 * (10.0 * k10 - 0.5 * x6) * k9 * x6) / (5.0 * k10),
	]
	measured_quantities = [y1 ~ 8.0 * x4, y2 ~ 0.5 * x5, y3 ~ 0.5 * x6]
	model, mq = create_ordered_ode_system(
		"biohydrogenation", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"biohydrogenation", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_receptor_binding(case, data_path::AbstractString, max_observations::Int)
	parameters = @parameters R1tot R2tot kon1 kon2 koff1 koff2
	states = @variables L(t) Ca(t) Cb(t)
	observables = @variables y1(t) y2(t) y3(t)
	equations = [
		D(L) ~ -kon1 * L * (R1tot - Ca) + koff1 * Ca -
			kon2 * L * (R2tot - Cb) + koff2 * Cb,
		D(Ca) ~ kon1 * L * (R1tot - Ca) - koff1 * Ca,
		D(Cb) ~ kon2 * L * (R2tot - Cb) - koff2 * Cb,
	]
	measured_quantities = [y1 ~ L, y2 ~ Ca, y3 ~ Cb]
	model, mq = create_ordered_ode_system(
		"receptor_binding", states, parameters, equations, measured_quantities)
	data_sample, rows, original_rows = _peb_data_sample(data_path, mq, max_observations)
	pep = ParameterEstimationProblem(
		"receptor_binding", model, mq, data_sample, case.time_interval, nothing,
		OrderedDict(parameters .=> case.p_true), OrderedDict(states .=> case.ic), 0)
	return pep, rows, original_rows
end

function _peb_problem(case, data_path::AbstractString, max_observations::Int)
	case.model == :lotka_volterra && return _peb_lotka_volterra(case, data_path, max_observations)
	case.model == :vanderpol && return _peb_vanderpol(case, data_path, max_observations)
	case.model == :fitzhugh_nagumo && return _peb_fitzhugh_nagumo(case, data_path, max_observations)
	case.model == :slow_fast && return _peb_slow_fast(case, data_path, max_observations)
	case.model == :daisy_mamil4 && return _peb_daisy_mamil4(case, data_path, max_observations)
	case.model == :biohydrogenation && return _peb_biohydrogenation(case, data_path, max_observations)
	case.model == :receptor_binding && return _peb_receptor_binding(case, data_path, max_observations)
	throw(ArgumentError("unsupported audited model $(case.model)"))
end

function _peb_output_path(out_dir::String, case_id::String, arm::String,
		max_observations::Int, interpolator_pool::String,
		pair_strategy::Symbol, lengthscale_factor::Float64)
	row_token = max_observations <= 0 ? "full" : "n$(max_observations)"
	variant = pair_strategy == :spread && lengthscale_factor == 1.0 ? "" :
		"__$(pair_strategy)__ls_$(_safe_token(lengthscale_factor))"
	return joinpath(out_dir,
		"$(case_id)__$(row_token)__$(interpolator_pool)__$(arm)$(variant).toml")
end

function _historical_interpolator(method::Symbol)
	method == :s3_adapt_se && return InterpolatorS3AdaptSE
	method == :s3_adapt_rq && return InterpolatorS3AdaptRQ
	method == :aaad_gpr && return InterpolatorAAADGPR
	method == :agp_robust_rq && return InterpolatorAGPRobustRQ
	method == :chebyshev_aicc && return InterpolatorChebyshevAICc
	method == :chebyshev_bic && return InterpolatorChebyshevBIC
	throw(ArgumentError("no InterpolatorMethod mapping for historical source $method"))
end

"""Hash-check and construct frozen cases without running parameter estimation."""
function _validate_peb_catalog(
	peb_root::String,
	case_ids::Vector{String};
	max_observations::Int = 0,
)
	for case_id in case_ids
		case = PEB_AUDITED_CASES[case_id]
		paths = _peb_paths(peb_root, case_id, case)
		pep, rows, original_rows = _peb_problem(case, paths.data, max_observations)
		original_rows == 750 || throw(ArgumentError(
			"$case_id has $original_rows rows; expected frozen 750-row design",
		))
		length(rows) == (max_observations <= 0 ? original_rows : max_observations) ||
			throw(ArgumentError("$case_id row selection count mismatch"))
		times = Float64.(pep.data_sample["t"])
		isapprox(first(times), first(case.time_interval); atol = 1e-12, rtol = 0) ||
			throw(ArgumentError("$case_id first observation time mismatch"))
		isapprox(last(times), last(case.time_interval); atol = 1e-12, rtol = 0) ||
			throw(ArgumentError("$case_id last observation time mismatch"))
		length(pep.measured_quantities) + 1 == length(pep.data_sample) ||
			throw(ArgumentError("$case_id measured-data column mismatch"))
		_historical_interpolator(case.historical_interpolator)
		println("VALID $case_id rows=$(length(rows)) hashes=data+generator+metadata")
	end
	return true
end

function _peb_arm_options(case, arm::String, shooting_points::Int, max_pairs::Int,
		interpolator_pool::String;
		pair_strategy::Symbol = :spread,
		lengthscale_factor::Float64 = 1.0)
	extra = _arm_options(arm, shooting_points, max_pairs;
		pair_strategy, lengthscale_factor)
	if interpolator_pool == "uq_only"
		return extra
	elseif interpolator_pool == "historical_plus_uq"
		historical = _historical_interpolator(case.historical_interpolator)
		methods = historical == InterpolatorAGPUQ ?
			InterpolatorMethod[InterpolatorAGPUQ] :
			InterpolatorMethod[historical, InterpolatorAGPUQ]
		return (; extra..., interpolator = first(methods), interpolators = methods,
			auto_filter_interpolators = false)
	end
	throw(ArgumentError(
		"unknown interpolator-pool '$interpolator_pool'; use historical_plus_uq or uq_only"))
end

function _record_peb_result!(payload::Dict{String, Any}, pep, raw, analysis, uq)
	payload["raw_candidate_count"] = isempty(raw) ? 0 : length(raw[1])
	payload["returned_candidate_count"] = length(analysis.returned_results)
	if isempty(analysis.returned_results)
		payload["outcome"] = "no_estimate"
		payload["message"] = "analysis.returned_results was empty"
		return payload
	end

	selected = first(analysis.returned_results)
	identity = selected.provenance.estimator_identity
	payload["selected_fit_error"] = isnothing(selected.err) ? Inf : Float64(selected.err)
	payload["selected_identity"] = _identity_dict(identity)
	payload["coordinates"] = _coordinate_records(pep, selected, uq)
	payload["candidate_diagnostics"] = _candidate_records(
		pep, isempty(raw) ? Any[] : raw[1], identity.candidate_id)

	_record_uq_outcome!(payload, uq)
	return payload
end

function _run_peb_canary(case_id::String, case, arm::String;
		peb_root::String, out_dir::String, max_observations::Int,
		shooting_points::Int, max_pairs::Int, interpolator_pool::String,
		pair_strategy::Symbol, lengthscale_factor::Float64, force::Bool)
	path = _peb_output_path(out_dir, case_id, arm, max_observations,
		interpolator_pool, pair_strategy, lengthscale_factor)
	if isfile(path) && !force
		println("SKIP completed: ", basename(path))
		return TOML.parsefile(path)
	end

	paths = _peb_paths(peb_root, case_id, case)
	pep, rows, original_rows = _peb_problem(case, paths.data, max_observations)
	extra = _peb_arm_options(case, arm, shooting_points, max_pairs, interpolator_pool;
		pair_strategy, lengthscale_factor)
	n_unknowns = length(case.p_true) + length(case.ic)
	opts = EstimationOptions(;
		datasize = length(rows),
		time_interval = case.time_interval,
		noise_level = case.noise,
		nooutput = true,
		diagnostics = false,
		shooting_warp = true,
		shooting_warp_beta = 3.0,
		use_parameter_homotopy = true,
		opt_lb = fill(1e-5, n_unknowns),
		opt_ub = fill(10.0, n_unknowns),
		extra...,
	)

	payload = Dict{String, Any}(
		"schema_version" => 1,
		"source" => "PEB audited paper snapshot",
		"peb_frozen_sha" => PEB_FROZEN_SHA,
		"peb_snapshot" => PEB_SNAPSHOT,
		"case_id" => case_id,
		"model" => string(case.model),
		"noise" => case.noise,
		"arm" => arm,
		"shooting_points" => shooting_points,
		"multipoint_max_pairs" => max_pairs,
		"multipoint_pair_strategy" => string(pair_strategy),
		"gp_derivative_lengthscale_factor" => lengthscale_factor,
		"interpolator_pool" => interpolator_pool,
		"replicate" => case.instance,
		"time_interval" => case.time_interval,
		"original_observations" => original_rows,
		"used_observations" => length(rows),
		"selected_source_rows" => rows,
		"data_sha256" => case.data_sha256,
		"generator_sha256" => case.generator_sha256,
		"metadata_sha256" => case.metadata_sha256,
		"historical_kind" => string(case.historical_kind),
		"historical_run" => case.historical_run,
		"historical_time_indices" => case.historical_time_indices,
		"historical_interpolator" => string(case.historical_interpolator),
		"historical_max_error" => case.historical_max_error,
		"started_at" => string(now()),
	)

	println("RUN  case=$case_id historical=$(case.historical_kind) arm=$arm " *
		"pool=$interpolator_pool rows=$(length(rows))/$original_rows")
	flush(stdout)
	started = time()
	try
		result, timing = _cov_quiet() do
			with_estimation_timing() do
				ODEParameterEstimation.analyze_parameter_estimation_problem(deepcopy(pep), opts)
			end
		end
		raw, analysis, uq = result
		payload["elapsed_seconds"] = time() - started
		payload["max_rss_bytes"] = Sys.maxrss()
		payload["structured_timing"] = timing_breakdown_to_dict(timing)
		_record_peb_result!(payload, pep, raw, analysis, uq)
	catch e
		e isa InterruptException && rethrow()
		payload["elapsed_seconds"] = time() - started
		payload["outcome"] = "error"
		payload["message"] = sprint(showerror, e, catch_backtrace())
	end

	_atomic_toml(path, payload)
	println("DONE ", basename(path), " outcome=", payload["outcome"],
		" elapsed=", round(payload["elapsed_seconds"]; digits = 1), "s")
	flush(stdout)
	return payload
end

function _print_peb_summary(payloads)
	println("\n", "="^126)
	println("AUDITED PEB ESTIMATOR/UQ CANARIES")
	println("="^126)
	@printf("%-29s %-18s %-22s %-22s %-15s %-11s %-9s\n",
		"case", "arm", "historical seed", "selected estimator", "UQ outcome",
		"worst err", "seconds")
	for payload in payloads
		identity = get(payload, "selected_identity", Dict{String, Any}())
		coordinates = get(payload, "coordinates", Dict{String, Any}[])
		worst_error = _finite_max(Float64[
			Float64(get(row, "relative_error", Inf)) for row in coordinates])
		@printf("%-29s %-18s %-22s %-22s %-15s %-11.3g %-9.1f\n",
			payload["case_id"], payload["arm"], payload["historical_kind"],
			get(identity, "estimator_kind", "—"), get(payload, "outcome", "—"),
			worst_error, get(payload, "elapsed_seconds", NaN))
	end
	println("="^126)
	return nothing
end

function main_peb_canaries()
	case_ids = _campaign_list("cases",
		"lotka_volterra_2_1em4,vanderpol_2_1em4,fitzhugh_nagumo_1_1em4")
	unknown = setdiff(case_ids, collect(keys(PEB_AUDITED_CASES)))
	isempty(unknown) || throw(ArgumentError("unknown audited cases: $(join(unknown, ", "))"))
	arms = _campaign_list("arms", "mp_polish")
	max_observations = parse(Int, _campaign_arg("max-observations", "0"))
	shooting_points = parse(Int, _campaign_arg("shooting-points", "20"))
	max_pairs = parse(Int, _campaign_arg("max-pairs", "15"))
	pair_strategy = Symbol(_campaign_arg("pair-strategy", "spread"))
	lengthscale_factor = parse(Float64, _campaign_arg("lengthscale-factor", "1.0"))
	interpolator_pool = _campaign_arg("interpolator-pool", "historical_plus_uq")
	force = lowercase(_campaign_arg("force", "false")) in ("true", "yes", "1")
	validate_only = lowercase(_campaign_arg("validate-only", "false")) in
		("true", "yes", "1")
	peb_root = normpath(_campaign_arg("peb-root", _default_peb_root()))
	if validate_only
		_validate_peb_catalog(peb_root, case_ids; max_observations)
		return nothing
	end
	out_name = _campaign_arg("out", "peb_audited_canaries_$(Dates.format(now(), "yyyymmdd_HHMMSS"))")
	out_dir = isabspath(out_name) ? out_name : joinpath(@__DIR__, "results", out_name)
	mkpath(out_dir)

	println("PEB root: ", peb_root)
	println("Output: ", out_dir)
	println("Cases: ", join(case_ids, ", "), " | arms: ", join(arms, ", "),
		" | pool: ", interpolator_pool, " | max observations: ", max_observations)
	payloads = Dict{String, Any}[]
	for case_id in case_ids, arm in arms
		push!(payloads, _run_peb_canary(case_id, PEB_AUDITED_CASES[case_id], arm;
			peb_root, out_dir, max_observations, shooting_points, max_pairs,
			interpolator_pool, pair_strategy, lengthscale_factor, force))
	end
	_print_peb_summary(payloads)
	println("Results saved under ", out_dir)
	return payloads
end

if abspath(PROGRAM_FILE) == @__FILE__
	main_peb_canaries()
end
