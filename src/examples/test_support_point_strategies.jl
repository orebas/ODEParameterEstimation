# test_support_point_strategies.jl
#
# Experiment: compare 5 strategies for controlling AAA support point count
# in the S3 pipeline (GP → AAA → MLE). The goal is to find a mechanism that
# makes noisy data recover approximately the same support point count as
# noiseless data, avoiding the derivative blow-up caused by excessive support
# points when aaa_tol=1e-14 fits GP kernel artifacts.
#
# Run: julia src/examples/test_support_point_strategies.jl

using ODEParameterEstimation
using BaryRational
using TaylorDiff
using Statistics
using Printf
using Random
using LinearAlgebra
using OrdinaryDiffEq
using DelimitedFiles
using Optim

# Access unexported functions
const s3_refine_gp = ODEParameterEstimation.s3_refine_gp
const agp_gpr_robust = ODEParameterEstimation.agp_gpr_robust
const nth_deriv = ODEParameterEstimation.nth_deriv
const baryEval = ODEParameterEstimation.baryEval
const _mle_refine_bary = ODEParameterEstimation._mle_refine_bary
const _BaryResult = ODEParameterEstimation._BaryResult

# ═════════════════════════════════════════════════════════════
# Section 1: Test functions and metrics
# ═════════════════════════════════════════════════════════════

abstract type TestFunction end

struct SinTest <: TestFunction end
domain(::SinTest) = (0.0, 1.0)
label(::SinTest) = "sin2pix"
max_deriv_order(::SinTest) = 7
function true_deriv(::SinTest, x::Real, order::Int)
	ω = 2π
	return ω^order * sin(ω * x + order * π / 2)
end

struct GaussTest <: TestFunction end
domain(::GaussTest) = (-2.0, 2.0)
label(::GaussTest) = "exp_negx2"
max_deriv_order(::GaussTest) = 7
function true_deriv(::GaussTest, x::Real, order::Int)
	order == 0 && return exp(-x^2)
	return TaylorDiff.derivative(z -> exp(-z^2), x, Val(order))
end

struct RungeTest <: TestFunction end
domain(::RungeTest) = (-1.0, 1.0)
label(::RungeTest) = "runge"
max_deriv_order(::RungeTest) = 7
function true_deriv(::RungeTest, x::Real, order::Int)
	order == 0 && return 1.0 / (1.0 + 25.0 * x^2)
	return TaylorDiff.derivative(z -> 1.0 / (1.0 + 25.0 * z^2), x, Val(order))
end

struct SigmoidTest <: TestFunction end
domain(::SigmoidTest) = (-1.0, 1.0)
label(::SigmoidTest) = "tanh8x"
max_deriv_order(::SigmoidTest) = 7
function true_deriv(::SigmoidTest, x::Real, order::Int)
	order == 0 && return tanh(8.0 * x)
	return TaylorDiff.derivative(z -> tanh(8.0 * z), x, Val(order))
end

struct MixedFreqTest <: TestFunction end
domain(::MixedFreqTest) = (0.0, 1.0)
label(::MixedFreqTest) = "mixed_freq"
max_deriv_order(::MixedFreqTest) = 7
function true_deriv(::MixedFreqTest, x::Real, order::Int)
	order == 0 && return sin(2π * x) + 0.3 * sin(14π * x)
	return TaylorDiff.derivative(z -> sin(2π * z) + 0.3 * sin(14π * z), x, Val(order))
end

struct LVTest <: TestFunction end
domain(::LVTest) = (0.0, 10.0)
label(::LVTest) = "LV_y1"
max_deriv_order(::LVTest) = 5

# LV reference solution (generated once, stored globally)
const LV_SOL = Ref{Any}(nothing)

function generate_lv_reference()
	if LV_SOL[] !== nothing
		return LV_SOL[]
	end
	α, β, γ, δ = 1.5, 1.0, 3.0, 1.0
	u0 = [1.0, 1.0]
	tspan = (0.0, 10.0)
	function lv!(du, u, p, t)
		du[1] = α * u[1] - β * u[1] * u[2]
		du[2] = δ * u[1] * u[2] - γ * u[2]
	end
	prob = ODEProblem(lv!, u0, tspan)
	sol = solve(prob, Vern9(); abstol = 1e-14, reltol = 1e-14, saveat = 0.001)
	LV_SOL[] = sol
	return sol
end

function true_deriv(::LVTest, x::Real, order::Int)
	sol = generate_lv_reference()
	order == 0 && return sol(x)[1]
	return TaylorDiff.derivative(t -> sol(t)[1], x, Val(order))
end

# ─────────────────────────────────────────────────────────────
# NRMSE metric
# ─────────────────────────────────────────────────────────────

function nrmse(predicted, truth)
	if all(truth .== 0)
		return norm(predicted) < 1e-12 ? 0.0 : Inf
	end
	scale = max(std(truth), mean(abs.(truth)), 1e-15)
	return sqrt(mean((predicted .- truth) .^ 2)) / scale
end

# ─────────────────────────────────────────────────────────────
# Evaluation points (interior only, away from boundaries)
# ─────────────────────────────────────────────────────────────

function make_interior_eval_points(a, b, n_data; n_pts = 20)
	h = (b - a) / (n_data - 1)
	start = a + 5 * h
	stop = b - 5 * h
	pts = range(start, stop, length = n_pts) |> collect
	pts .+= h / 3  # shift to avoid landing on data points
	return pts
end

# ─────────────────────────────────────────────────────────────
# Safe derivative evaluation
# ─────────────────────────────────────────────────────────────

function safe_nth_deriv(interp, order, t)
	try
		val = nth_deriv(x -> interp(x), order, t)
		return isfinite(val) ? val : NaN
	catch
		return NaN
	end
end

# ─────────────────────────────────────────────────────────────
# Support point helpers
# ─────────────────────────────────────────────────────────────

function count_support_points(interp)
	interp isa AAADapprox ? length(interp.internalAAA.x) : -1
end

# ═════════════════════════════════════════════════════════════
# Section 2: Strategy implementations
# ═════════════════════════════════════════════════════════════

"""
Strategy A: Adaptive tolerance based on GP noise estimate.
After fitting GP, estimate residual noise and set aaa_tol proportionally.
"""
function strategy_adaptive_tol(gp, t_vec, y_raw; k = 1.0)
	y_gp = [gp(t) for t in t_vec]
	noise_std = std(y_raw .- y_gp)
	data_scale = maximum(abs.(y_gp))
	aaa_tol = max(k * noise_std / data_scale, 1e-14)
	return s3_refine_gp(gp, t_vec, y_raw; aaa_tol = aaa_tol)
end

"""
Strategy B: Hard mmax cap on support point count.
Run AAA with tight tolerance but limit maximum support points.
"""
function strategy_hard_mmax(gp, t_vec, y_raw; mmax = 20)
	return s3_refine_gp(gp, t_vec, y_raw; aaa_tol = 1e-14, mmax = mmax)
end

"""
Strategy C: BIC model selection across tolerances.
Run AAA at multiple tolerances, pick the one minimizing BIC evaluated
against raw data (not GP-denoised data).
"""
function strategy_bic(gp, t_vec, y_raw)
	y_gp = [gp(t) for t in t_vec]
	M = length(t_vec)

	best_bic = Inf
	best_z, best_w, best_f = Float64[], Float64[], Float64[]

	# Sweep tolerances
	for log_tol in -3:-1:-14
		tol = 10.0^log_tol
		try
			aaa_result = BaryRational.aaa(t_vec, y_gp; tol = tol, mmax = 200)
			z = copy(aaa_result.x)
			w = copy(aaa_result.w)
			f = copy(aaa_result.f)

			# Evaluate against RAW data for BIC
			predicted = [baryEval(t, f, z, w) for t in t_vec]
			SSR = sum(abs2.(y_raw .- predicted))

			n_params = 2 * length(z)
			bic = n_params * log(M) + M * log(SSR / M + 1e-100)

			if bic < best_bic
				best_bic = bic
				best_z, best_w, best_f = z, w, f
			end
		catch
			continue
		end
	end

	if isempty(best_z)
		# Fallback: use default s3
		return s3_refine_gp(gp, t_vec, y_raw)
	end

	# MLE refine the BIC-selected approximation
	z, w, f = _mle_refine_bary(best_z, best_w, best_f, t_vec, y_raw)
	return AAADapprox(_BaryResult(z, w, f))
end

"""
Strategy D: Bisection to match loose-tolerance support count.
Run AAA with tol=1e-4 to get reference count N₀, then binary search
for a tighter tolerance that gives approximately the same count.
"""
function strategy_bisect(gp, t_vec, y_raw)
	y_gp = [gp(t) for t in t_vec]

	# Reference count at loose tolerance
	ref_result = BaryRational.aaa(t_vec, y_gp; tol = 1e-4, mmax = 200)
	n_ref = length(ref_result.x)
	target = n_ref + 2  # small margin

	# Binary search on log(tol) in [-14, -4]
	lo, hi = -14.0, -4.0  # log10 scale
	best_z, best_w, best_f = copy(ref_result.x), copy(ref_result.w), copy(ref_result.f)

	for _ in 1:30
		mid = (lo + hi) / 2.0
		tol = 10.0^mid
		try
			r = BaryRational.aaa(t_vec, y_gp; tol = tol, mmax = 200)
			n = length(r.x)
			if n <= target
				# Tolerance is still loose enough, try tighter
				best_z, best_w, best_f = copy(r.x), copy(r.w), copy(r.f)
				hi = mid
			else
				# Too many points, relax tolerance
				lo = mid
			end
		catch
			lo = mid
		end
		(hi - lo) < 0.01 && break
	end

	# MLE refine
	z, w, f = _mle_refine_bary(best_z, best_w, best_f, t_vec, y_raw)
	return AAADapprox(_BaryResult(z, w, f))
end

"""
Strategy E: Support point pruning by weight magnitude.
Run AAA with tight tolerance (many points), then remove smallest-weight
points until count ≤ target, then MLE-refine on remaining.
"""
function strategy_prune(gp, t_vec, y_raw; target_n = 20)
	y_gp = [gp(t) for t in t_vec]

	aaa_result = BaryRational.aaa(t_vec, y_gp; tol = 1e-14, mmax = 200)
	z = copy(aaa_result.x)
	w = copy(aaa_result.w)
	f = copy(aaa_result.f)

	# Prune: remove smallest-weight support points
	if length(z) > target_n
		# Sort by |weight| descending, keep top target_n
		perm = sortperm(abs.(w); rev = true)
		keep = sort(perm[1:target_n])  # sort by position for stability
		z = z[keep]
		w = w[keep]
		f = f[keep]
	end

	# MLE refine the pruned approximation
	z, w, f = _mle_refine_bary(z, w, f, t_vec, y_raw)
	return AAADapprox(_BaryResult(z, w, f))
end

"""Baseline: S3 with default settings (aaa_tol=1e-14, mmax=200)."""
function strategy_baseline(gp, t_vec, y_raw)
	return s3_refine_gp(gp, t_vec, y_raw)
end

# ═════════════════════════════════════════════════════════════
# Section 3: Main experiment loop
# ═════════════════════════════════════════════════════════════

function run_experiment()
	Random.seed!(42)

	# Configuration
	test_functions = [SinTest(), GaussTest(), RungeTest(), SigmoidTest(), MixedFreqTest(), LVTest()]
	data_sizes = [101, 501]
	noise_levels = [0.0, 1e-8, 1e-4, 1e-2]

	# Strategy configurations
	# (name, function, description)
	strategies = [
		("baseline", (gp, t, y) -> strategy_baseline(gp, t, y), "S3 default"),
		("adapt_k0.01", (gp, t, y) -> strategy_adaptive_tol(gp, t, y; k = 0.01), "adaptive tol k=0.01"),
		("adapt_k0.1", (gp, t, y) -> strategy_adaptive_tol(gp, t, y; k = 0.1), "adaptive tol k=0.1"),
		("adapt_k1.0", (gp, t, y) -> strategy_adaptive_tol(gp, t, y; k = 1.0), "adaptive tol k=1.0"),
		("adapt_k10", (gp, t, y) -> strategy_adaptive_tol(gp, t, y; k = 10.0), "adaptive tol k=10"),
		("adapt_k100", (gp, t, y) -> strategy_adaptive_tol(gp, t, y; k = 100.0), "adaptive tol k=100"),
		("mmax10", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 10), "mmax=10"),
		("mmax15", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 15), "mmax=15"),
		("mmax20", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 20), "mmax=20"),
		("mmax25", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 25), "mmax=25"),
		("mmax30", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 30), "mmax=30"),
		("mmax40", (gp, t, y) -> strategy_hard_mmax(gp, t, y; mmax = 40), "mmax=40"),
		("bic", (gp, t, y) -> strategy_bic(gp, t, y), "BIC model selection"),
		("bisect", (gp, t, y) -> strategy_bisect(gp, t, y), "bisect to match noiseless"),
		("prune15", (gp, t, y) -> strategy_prune(gp, t, y; target_n = 15), "prune to 15"),
		("prune20", (gp, t, y) -> strategy_prune(gp, t, y; target_n = 20), "prune to 20"),
		("prune25", (gp, t, y) -> strategy_prune(gp, t, y; target_n = 25), "prune to 25"),
	]

	# Generate LV reference
	println("Generating Lotka-Volterra reference solution...")
	generate_lv_reference()

	# Results storage: each row = one measurement
	results = Vector{NamedTuple}()

	total_configs = length(test_functions) * length(data_sizes) * length(noise_levels)
	config_num = 0

	println("\n" * "="^100)
	println("SUPPORT POINT STRATEGY COMPARISON EXPERIMENT")
	println("="^100)
	println("  Functions: ", join([label(tf) for tf in test_functions], ", "))
	println("  Data sizes: ", data_sizes)
	println("  Noise levels: ", noise_levels)
	println("  Strategies: ", length(strategies))
	println("  Total configs: $total_configs")
	println("="^100)

	for tf in test_functions
		a, b = domain(tf)
		max_ord = max_deriv_order(tf)

		println("\n" * "━"^100)
		println("  Function: $(label(tf))   domain: [$a, $b]   max_order: $max_ord")
		println("━"^100)

		for n_data in data_sizes
			for noise in noise_levels
				config_num += 1

				# Generate data
				xs = range(a, b, length = n_data) |> collect
				ys_true = [true_deriv(tf, x, 0) for x in xs]
				ys = ys_true .+ noise * randn(n_data) .* max.(abs.(ys_true), 1.0)

				eval_pts = make_interior_eval_points(a, b, n_data)

				# Fit GP once (shared by all strategies)
				gp = nothing
				try
					gp = agp_gpr_robust(Vector{Float64}(xs), Vector{Float64}(ys); kernel_type = :se)
				catch e
					@warn "GP fit failed for $(label(tf)) n=$n_data noise=$noise: $e"
					continue
				end

				# Also compute pure GP results as reference
				gp_nrmses = Float64[]
				for order in 0:max_ord
					truth = [true_deriv(tf, x, order) for x in eval_pts]
					predicted = [safe_nth_deriv(gp, order, x) for x in eval_pts]
					push!(gp_nrmses, nrmse(predicted, truth))
				end

				# Print header
				@printf("\n  [%d/%d] %s  n=%d  noise=%.0e\n", config_num, total_configs,
					label(tf), n_data, noise)
				@printf("  %-16s  %5s  ", "strategy", "n_sup")
				for o in 0:min(max_ord, 7)
					@printf("  ord_%d     ", o)
				end
				println()

				# Print GP reference line
				@printf("  %-16s  %5s  ", "GP(ref)", "N/A")
				for o in 0:min(max_ord, 7)
					fmt_nrmse(gp_nrmses[o + 1])
				end
				println()

				# Run all strategies
				for (sname, sfunc, sdesc) in strategies
					try
						interp = sfunc(gp, Vector{Float64}(xs), Vector{Float64}(ys))
						n_sup = count_support_points(interp)

						@printf("  %-16s  %5d  ", sname, n_sup)

						for order in 0:min(max_ord, 7)
							truth = [true_deriv(tf, x, order) for x in eval_pts]
							predicted = [safe_nth_deriv(interp, order, x) for x in eval_pts]
							err = nrmse(predicted, truth)

							push!(results, (
								func = label(tf),
								n = n_data,
								noise = noise,
								strategy = sname,
								order = order,
								nrmse = err,
								n_support = n_sup,
							))

							fmt_nrmse(err)
						end
						println()
					catch e
						@printf("  %-16s  FAILED: %s\n", sname, sprint(showerror, e))
					end
				end
			end
		end
	end

	# ═════════════════════════════════════════════════════════
	# Section 4: Summary tables and CSV output
	# ═════════════════════════════════════════════════════════

	println("\n\n" * "="^100)
	println("SUMMARY: Median support point count by strategy and noise level")
	println("="^100)

	strat_names = unique([r.strategy for r in results])
	@printf("  %-16s", "strategy")
	for noise in noise_levels
		@printf("  noise=%.0e", noise)
	end
	println()

	for sname in strat_names
		@printf("  %-16s", sname)
		for noise in noise_levels
			subset = filter(r -> r.strategy == sname && r.noise == noise && r.order == 0, results)
			if !isempty(subset)
				med_n = median([r.n_support for r in subset])
				@printf("  %10.0f", med_n)
			else
				@printf("  %10s", "N/A")
			end
		end
		println()
	end

	println("\n" * "="^100)
	println("SUMMARY: Median NRMSE by strategy and derivative order (noise=1e-4, n=501)")
	println("="^100)

	@printf("  %-16s  %5s", "strategy", "n_sup")
	for o in 0:7
		@printf("  ord_%d     ", o)
	end
	println()

	for sname in strat_names
		subset_0 = filter(r -> r.strategy == sname && r.noise == 1e-4 && r.n == 501 && r.order == 0, results)
		med_n = isempty(subset_0) ? -1.0 : median([r.n_support for r in subset_0])
		@printf("  %-16s  %5.0f", sname, med_n)

		for o in 0:7
			subset = filter(r -> r.strategy == sname && r.noise == 1e-4 && r.n == 501 && r.order == o, results)
			if !isempty(subset)
				med = median([r.nrmse for r in subset])
				fmt_nrmse(med)
			else
				@printf("  %10s ", "N/A")
			end
		end
		println()
	end

	println("\n" * "="^100)
	println("SUMMARY: Median NRMSE by strategy and derivative order (noise=0, n=501)")
	println("="^100)

	@printf("  %-16s  %5s", "strategy", "n_sup")
	for o in 0:7
		@printf("  ord_%d     ", o)
	end
	println()

	for sname in strat_names
		subset_0 = filter(r -> r.strategy == sname && r.noise == 0.0 && r.n == 501 && r.order == 0, results)
		med_n = isempty(subset_0) ? -1.0 : median([r.n_support for r in subset_0])
		@printf("  %-16s  %5.0f", sname, med_n)

		for o in 0:7
			subset = filter(r -> r.strategy == sname && r.noise == 0.0 && r.n == 501 && r.order == o, results)
			if !isempty(subset)
				med = median([r.nrmse for r in subset])
				fmt_nrmse(med)
			else
				@printf("  %10s ", "N/A")
			end
		end
		println()
	end

	# Strategy comparison: support count ratio (noisy / noiseless)
	println("\n" * "="^100)
	println("SUMMARY: Support count ratio (noisy / noiseless) — closer to 1.0 is better")
	println("="^100)

	@printf("  %-16s", "strategy")
	for noise in noise_levels[2:end]  # skip noise=0
		@printf("  noise=%.0e", noise)
	end
	println()

	for sname in strat_names
		@printf("  %-16s", sname)
		ref_subset = filter(r -> r.strategy == sname && r.noise == 0.0 && r.order == 0, results)
		n_ref = isempty(ref_subset) ? 0.0 : median([r.n_support for r in ref_subset])

		for noise in noise_levels[2:end]
			subset = filter(r -> r.strategy == sname && r.noise == noise && r.order == 0, results)
			if !isempty(subset) && n_ref > 0
				n_noisy = median([r.n_support for r in subset])
				ratio = n_noisy / n_ref
				@printf("  %10.2f", ratio)
			else
				@printf("  %10s", "N/A")
			end
		end
		println()
	end

	# Write CSV
	csv_path = joinpath(dirname(@__FILE__), "..", "..", "artifacts", "support_point_strategies.csv")
	mkpath(dirname(csv_path))
	open(csv_path, "w") do io
		println(io, "func,n,noise,strategy,order,nrmse,n_support")
		for r in results
			println(io, "$(r.func),$(r.n),$(r.noise),$(r.strategy),$(r.order),$(r.nrmse),$(r.n_support)")
		end
	end
	println("\nResults written to: $csv_path")
	println("Total measurements: $(length(results))")
end

# ─────────────────────────────────────────────────────────────
# Formatting helper
# ─────────────────────────────────────────────────────────────

function fmt_nrmse(err)
	if isnan(err)
		@printf("  %10s ", "NaN")
	elseif err < 1e-12
		@printf("  %10s ", "<1e-12")
	elseif err > 1e6
		@printf(" %9.1e! ", err)
	elseif err > 1.0
		@printf("  %9.2e ", err)
	else
		@printf("  %9.2e ", err)
	end
end

# Run
run_experiment()
