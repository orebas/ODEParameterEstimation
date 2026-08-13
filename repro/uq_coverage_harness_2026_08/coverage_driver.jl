# UQ coverage/calibration harness (Stream B item 2, 2026-08-13).
#
# Measures empirical CI coverage of the UQ chain over N independent noise
# replicates: noisy draw → estimate → GP jets → Σ_d → sensitivity S → Σ_x →
# physicalized report → z = (estimate − truth)/σ̂ per physical coordinate.
#
# Two conditioning modes for S (diagnose_sensitivity value_source):
#   :estimate — the production path (θ̂/x̂ jets + GP data jets). DEFAULT.
#   :oracle   — truth-conditioned; the TAC-theory two_exp anchor numbers
#               (95% well-conditioned block / 82% weak block) were this mode.
#
# Two estimators:
#   :nls_polish    — forward-solve least squares started at truth (fast; the
#                    estimator itself is not under test, the UQ chain is).
#   :full_pipeline — analyze_parameter_estimation_problem with
#                    compute_uncertainty=true (paper-grade; slow per replicate).
#
# Usage (from the repo root):
#   julia --startup-file=no -e 'using ODEParameterEstimation;
#       include("repro/uq_coverage_harness_2026_08/coverage_driver.jl");
#       res = run_coverage(two_exp_pep; N = 100, noise_level = 0.01);
#       print_coverage(res)'
#
# The gate smoke (test/test_uq_coverage_smoke.jl) includes this file — keep it
# load-light and side-effect free.

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using OrdinaryDiffEq
using SciMLBase
using Optim
using Random
using Statistics
using Logging

# ─── Anchor model: two decaying exponentials, summed observation ──────
# y = x1 + x2 with k2 >> k1 makes (x2, k2) the weakly-identified block at
# late shooting times (the fast mode has died) — the 82%-coverage residual
# documented in the TAC-theory PHASE3_CALIBRATION anchor.

function two_exp_pep(; x01_true = 2.0, x02_true = 1.5, k1_true = 0.6, k2_true = 3.0)
	parameters = @parameters k1 k2
	states = @variables x1(t) x2(t)
	@variables y1(t)
	equations = [
		D(x1) ~ -k1 * x1,
		D(x2) ~ -k2 * x2,
	]
	measured_quantities = [y1 ~ x1 + x2]
	model, mq = ODEParameterEstimation.create_ordered_ode_system(
		"two_exp", states, parameters, equations, measured_quantities)
	return ParameterEstimationProblem(
		"two_exp", model, mq, nothing, nothing, nothing,
		OrderedDict(parameters .=> [k1_true, k2_true]),
		OrderedDict(states .=> [x01_true, x02_true]),
		0,
	)
end

# Well-conditioned companion: both states observed directly (simple rotation).
two_state_observed_pep() = ODEParameterEstimation.simple()

# ─── Quiet wrapper ────────────────────────────────────────────────────

function _cov_quiet(f)
	redirect_stdout(devnull) do
		redirect_stderr(devnull) do
			with_logger(NullLogger()) do
				return f()
			end
		end
	end
end

# ─── Estimators ───────────────────────────────────────────────────────

"""
Forward-solve least-squares fit of (t0 states, params), started at truth.
Returns a `ParameterEstimationResult` (states = t0 ICs, `at_time = t_eval`).
Not the production estimator — a cheap stand-in so N replicates are viable;
the UQ chain downstream is exactly the production one.

Assumes observable RHS are time-invariant expressions of (states, params).
"""
function nls_polish_estimate(pep_data::ParameterEstimationProblem, t_eval::Float64)
	sys = pep_data.model.system
	completed = ModelingToolkit.complete(sys)
	states = ModelingToolkit.unknowns(completed)
	params = ModelingToolkit.parameters(completed)
	n_x, n_p = length(states), length(params)

	t_vec = Float64.(pep_data.data_sample["t"])
	tspan = (t_vec[1], t_vec[end])

	obs_keys = [ModelingToolkit.diff2term(mq.rhs) for mq in pep_data.measured_quantities]
	y_data = [Float64.(pep_data.data_sample[k]) for k in obs_keys]

	p_truth = [pep_data.p_true[p] for p in params]
	x0_truth = [pep_data.ic[s] for s in states]

	obs_fns = [ModelingToolkit.build_function(mq.rhs, states, params; expression = Val(false))
	           for mq in pep_data.measured_quantities]

	base_prob = ODEProblem(completed,
		merge(Dict(states .=> x0_truth), Dict(params .=> p_truth)), tspan)

	function sse(θ::Vector{Float64})
		x0 = θ[1:n_x]
		pv = θ[(n_x + 1):(n_x + n_p)]
		prob = remake(base_prob;
			u0 = Dict(states .=> x0), p = Dict(params .=> pv),
			build_initializeprob = false)
		sol = try
			ModelingToolkit.solve(prob, AutoVern9(Rodas5P());
				abstol = 1e-10, reltol = 1e-10, saveat = t_vec)
		catch
			return 1e100
		end
		SciMLBase.successful_retcode(sol) || return 1e100
		total = 0.0
		for (oi, fn) in enumerate(obs_fns)
			for ti in eachindex(t_vec)
				total += (fn(sol.u[ti], pv) - y_data[oi][ti])^2
			end
		end
		return total
	end

	θ0 = vcat(x0_truth, p_truth)
	res = Optim.optimize(sse, θ0, Optim.NelderMead(),
		Optim.Options(iterations = 4000))
	θ̂ = Optim.minimizer(res)

	est_states = OrderedDict{Num, Float64}(s => θ̂[i] for (i, s) in enumerate(states))
	est_params = OrderedDict{Num, Float64}(p => θ̂[n_x + i] for (i, p) in enumerate(params))
	return ODEParameterEstimation.ParameterEstimationResult(
		est_params, est_states, t_eval, Optim.minimum(res), :NLSPolish,
		length(t_vec), nothing, nothing, Set{Num}(), nothing)
end

# ─── Single replicate ─────────────────────────────────────────────────

struct CoverageReplicate
	labels::Vector{String}
	truth::Vector{Float64}
	center::Vector{Float64}
	sigma::Vector{Float64}
	status::Symbol
end

_base_name(x) = replace(string(x), r"\(.*\)" => "")

function _truth_for_label(pep::ParameterEstimationProblem, label::String)
	base = _base_name(label)
	for (p, v) in pep.p_true
		_base_name(p) == base && return v
	end
	for (s, v) in pep.ic
		_base_name(s) == base && return v
	end
	return NaN
end

function _center_for_label(est, label::String)
	base = _base_name(label)
	for (p, v) in est.parameters
		_base_name(p) == base && return v
	end
	for (s, v) in est.states
		_base_name(s) == base && return v
	end
	return NaN
end

function run_replicate(pep_ctor, opts::EstimationOptions;
	value_source::Symbol = :estimate,
	estimator::Symbol = :nls_polish,
)
	pep = pep_ctor()
	pep_data = ODEParameterEstimation.sample_problem_data(pep, opts)

	if estimator === :full_pipeline
		raw, analysis, uq = _cov_quiet() do
			ODEParameterEstimation.analyze_parameter_estimation_problem(pep_data, opts)
		end
		isnothing(uq) && return CoverageReplicate(String[], Float64[], Float64[], Float64[], :no_report)
		best = ODEParameterEstimation._best_scored_result(raw[1])
		isnothing(best) && return CoverageReplicate(String[], Float64[], Float64[], Float64[], :no_estimate)
		labels = uq.param_labels
		return CoverageReplicate(labels,
			[_truth_for_label(pep_data, l) for l in labels],
			[_center_for_label(best, l) for l in labels],
			copy(uq.param_std), uq.status)
	end

	setup = _cov_quiet() do
		ODEParameterEstimation.setup_parameter_estimation(
			pep_data; interpolator = ODEParameterEstimation.agp_gpr_uq, nooutput = true)
	end
	t_vec = pep_data.data_sample["t"]
	t_eval = t_vec[setup.time_index_set[1]]

	est = _cov_quiet() do
		nls_polish_estimate(pep_data, t_eval)
	end

	sens = _cov_quiet() do
		if value_source === :estimate
			ODEParameterEstimation.diagnose_sensitivity(
				pep_data; setup_data = setup, t_eval = t_eval, estimate_result = est)
		else
			ODEParameterEstimation.diagnose_sensitivity(
				pep_data; setup_data = setup, t_eval = t_eval)
		end
	end

	r = _cov_quiet() do
		ODEParameterEstimation.diagnose_uncertainty(pep_data, setup, t_eval, sens)
	end
	isnothing(r) && return CoverageReplicate(String[], Float64[], Float64[], Float64[], :no_report)
	uq_local = first(r)
	uq = _cov_quiet() do
		ODEParameterEstimation.physicalize_uncertainty_report(pep_data, est, uq_local)
	end
	isnothing(uq) && return CoverageReplicate(String[], Float64[], Float64[], Float64[], :no_physicalization)

	labels = uq.param_labels
	return CoverageReplicate(labels,
		[_truth_for_label(pep_data, l) for l in labels],
		[_center_for_label(est, l) for l in labels],
		copy(uq.param_std), uq.status)
end

# ─── N-replicate aggregation ──────────────────────────────────────────

struct CoverageResult
	labels::Vector{String}
	n_total::Int
	n_reported::Int
	covered::Dict{String, Int}        # |z| ≤ z_crit count per label
	usable::Dict{String, Int}         # finite-z replicate count per label
	zs::Dict{String, Vector{Float64}}
	z_crit::Float64
	statuses::Vector{Symbol}
end

function run_coverage(pep_ctor;
	N::Int = 20,
	noise_level::Float64 = 0.01,
	datasize::Int = 121,
	time_interval::Vector{Float64} = [0.0, 1.0],
	value_source::Symbol = :estimate,
	estimator::Symbol = :nls_polish,
	seed0::Int = 7000,
	z_crit::Float64 = ODEParameterEstimation.UQ_CI_Z,
	extra_opts::NamedTuple = NamedTuple(),
)
	base = (datasize = datasize, time_interval = time_interval,
		noise_level = noise_level, nooutput = true, diagnostics = false)
	uq_flag = estimator === :full_pipeline ? (compute_uncertainty = true,) : NamedTuple()
	opts = EstimationOptions(; base..., uq_flag..., extra_opts...)

	covered = Dict{String, Int}()
	usable = Dict{String, Int}()
	zs = Dict{String, Vector{Float64}}()
	statuses = Symbol[]
	labels_seen = String[]
	n_reported = 0

	for i in 1:N
		Random.seed!(seed0 + i)
		rep = run_replicate(pep_ctor, opts; value_source, estimator)
		push!(statuses, rep.status)
		rep.status in (:no_report, :no_estimate, :no_physicalization) && continue
		n_reported += 1
		for (j, l) in enumerate(rep.labels)
			l in labels_seen || push!(labels_seen, l)
			z = (rep.center[j] - rep.truth[j]) / rep.sigma[j]
			isfinite(z) || continue
			usable[l] = get(usable, l, 0) + 1
			push!(get!(zs, l, Float64[]), z)
			abs(z) <= z_crit && (covered[l] = get(covered, l, 0) + 1)
		end
	end

	return CoverageResult(labels_seen, N, n_reported, covered, usable, zs, z_crit, statuses)
end

coverage_fraction(res::CoverageResult, label::String) =
	get(res.usable, label, 0) == 0 ? NaN :
	get(res.covered, label, 0) / res.usable[label]

function print_coverage(res::CoverageResult)
	println("UQ coverage: $(res.n_reported)/$(res.n_total) replicates produced a report; z_crit = $(res.z_crit)")
	println(rpad("coordinate", 16), rpad("coverage", 12), rpad("n", 6),
		rpad("mean z", 10), "sd z")
	for l in res.labels
		zv = get(res.zs, l, Float64[])
		cov = coverage_fraction(res, l)
		println(rpad(l, 16),
			rpad(isnan(cov) ? "—" : string(round(100 * cov; digits = 1), "%"), 12),
			rpad(string(length(zv)), 6),
			rpad(string(round(mean(zv); digits = 3)), 10),
			string(round(std(zv); digits = 3)))
	end
	return nothing
end
