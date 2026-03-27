# verify_s3_derivatives.jl
#
# Independent verification of S3 vs GP derivative accuracy.
# Tests whether S3's higher-order derivative blow-up (order 2+) is real
# or an artifact of the derivative estimation study's methodology.
#
# Run: julia src/examples/verify_s3_derivatives.jl

using ODEParameterEstimation
using TaylorDiff
using Statistics
using Printf
using Random
using LinearAlgebra
using OrdinaryDiffEq
using DelimitedFiles

# Access unexported functions
const s3_se = ODEParameterEstimation.s3_se_interpolator
const s2_aaa_mle = ODEParameterEstimation.s2_aaa_mle_interpolator
const nth_deriv = ODEParameterEstimation.nth_deriv

# ─────────────────────────────────────────────────────────────
# Test functions with known analytic derivatives
# ─────────────────────────────────────────────────────────────

"""Sinusoidal: f(x) = sin(2πx) on [0, 1]"""
struct SinTest end
domain(::SinTest) = (0.0, 1.0)
label(::SinTest) = "sin(2πx)"

function true_deriv(::SinTest, x::Real, order::Int)
	ω = 2π
	# d^n/dx^n sin(ωx) = ω^n sin(ωx + nπ/2)
	return ω^order * sin(ω * x + order * π / 2)
end

"""Gaussian bump: f(x) = exp(-x²) on [-2, 2]"""
struct GaussTest end
domain(::GaussTest) = (-2.0, 2.0)
label(::GaussTest) = "exp(-x²)"

function true_deriv(::GaussTest, x::Real, order::Int)
	# Use TaylorDiff on the analytic function for ground truth
	if order == 0
		return exp(-x^2)
	end
	return TaylorDiff.derivative(z -> exp(-z^2), x, Val(order))
end

"""Lotka-Volterra y1 component: dy1/dt = αy1 - βy1y2"""
struct LVTest end
domain(::LVTest) = (0.0, 10.0)
label(::LVTest) = "LV_y1"

# We'll generate LV data and ground truth derivatives via dense ODE solution
# Ground truth derivatives computed via the ODE RHS + chain rule

# ─────────────────────────────────────────────────────────────
# Generate LV reference solution
# ─────────────────────────────────────────────────────────────

function generate_lv_reference()
	α, β, γ, δ = 1.5, 1.0, 3.0, 1.0
	u0 = [1.0, 1.0]
	tspan = (0.0, 10.0)

	function lv!(du, u, p, t)
		du[1] = α * u[1] - β * u[1] * u[2]
		du[2] = δ * u[1] * u[2] - γ * u[2]
	end

	prob = ODEProblem(lv!, u0, tspan)
	sol = solve(prob, Vern9(); abstol = 1e-14, reltol = 1e-14, saveat = 0.001)
	return sol
end

# ─────────────────────────────────────────────────────────────
# LV ground truth derivatives via TaylorDiff on the dense solution
# ─────────────────────────────────────────────────────────────

function lv_true_deriv(sol, x::Real, order::Int)
	if order == 0
		return sol(x)[1]
	end
	# Differentiate the interpolated ODE solution
	return TaylorDiff.derivative(t -> sol(t)[1], x, Val(order))
end

# ─────────────────────────────────────────────────────────────
# Support point analysis
# ─────────────────────────────────────────────────────────────

function count_support_points(interp)
	if interp isa AAADapprox
		return length(interp.internalAAA.x)
	end
	return -1  # Not applicable (GP)
end

function get_support_points(interp)
	if interp isa AAADapprox
		return interp.internalAAA.x
	end
	return Float64[]
end

function min_distance_to_support(eval_pt, support_pts)
	if isempty(support_pts)
		return Inf
	end
	return minimum(abs.(eval_pt .- support_pts))
end

# ─────────────────────────────────────────────────────────────
# Error metric: NRMSE
# ─────────────────────────────────────────────────────────────

function nrmse(predicted, truth)
	if all(truth .== 0)
		return norm(predicted) < 1e-12 ? 0.0 : Inf
	end
	scale = max(std(truth), mean(abs.(truth)), 1e-15)
	return sqrt(mean((predicted .- truth) .^ 2)) / scale
end

# ─────────────────────────────────────────────────────────────
# Evaluation points: interior, on-data, boundary
# ─────────────────────────────────────────────────────────────

function make_eval_points(a, b, n_data)
	h = (b - a) / (n_data - 1)
	# Interior: midpoints of every 10th interval, away from boundaries
	interior_start = a + 5 * h
	interior_end = b - 5 * h
	n_interior = 20
	interior = range(interior_start, interior_end, length = n_interior) |> collect
	# Shift by h/3 to avoid landing on data points
	interior .+= h / 3

	# On-data: every 10th data point (starting from 6th to avoid boundary)
	on_data_indices = 6:max(1, n_data ÷ 20):(n_data - 5)
	on_data = [a + (i - 1) * h for i in on_data_indices]

	# Boundary: first and last few points, slightly interior
	boundary = [a + h, a + 2h, b - 2h, b - h]

	return (interior = interior, on_data = on_data, boundary = boundary)
end

# ─────────────────────────────────────────────────────────────
# Fit one interpolator safely
# ─────────────────────────────────────────────────────────────

function fit_interpolator(name::Symbol, xs, ys)
	try
		if name == :s3_se
			return s3_se(xs, ys)
		elseif name == :agp_robust
			return agp_gpr_robust(xs, ys; kernel_type = :se)
		elseif name == :aaad
			return aaad(xs, ys)
		elseif name == :s2_aaa_mle
			return s2_aaa_mle(xs, ys)
		end
	catch e
		@warn "Failed to fit $name: $e"
		return nothing
	end
end

# ─────────────────────────────────────────────────────────────
# Compute derivative safely
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
# Main comparison
# ─────────────────────────────────────────────────────────────

function run_comparison()
	Random.seed!(42)

	# Configuration
	test_functions = [SinTest(), GaussTest()]
	data_sizes = [51, 101, 501, 1501]
	noise_levels = [0.0, 1e-8, 1e-4, 1e-2]
	interp_names = [:agp_robust, :aaad, :s2_aaa_mle, :s3_se]
	max_order = 7

	# LV reference (generated once)
	println("Generating Lotka-Volterra reference solution...")
	lv_sol = generate_lv_reference()

	# Results storage
	results = []

	println("\n" * "="^120)
	println("S3 vs GP Derivative Accuracy: Independent Verification")
	println("="^120)

	# Run analytic test functions
	for tf in test_functions
		a, b = domain(tf)
		println("\n" * "─"^120)
		println("Test function: $(label(tf))   domain: [$a, $b]")
		println("─"^120)

		for n_data in data_sizes
			for noise in noise_levels
				xs = range(a, b, length = n_data) |> collect
				ys_true = [true_deriv(tf, x, 0) for x in xs]
				ys = ys_true .+ noise * randn(n_data) .* max.(abs.(ys_true), 1.0)

				eval_pts = make_eval_points(a, b, n_data)

				# Fit all interpolators
				interps = Dict{Symbol,Any}()
				for iname in interp_names
					interps[iname] = fit_interpolator(iname, xs, ys)
				end

				# Header for this configuration
				n_support = Dict{Symbol,Int}()
				for iname in interp_names
					if interps[iname] !== nothing
						n_support[iname] = count_support_points(interps[iname])
					else
						n_support[iname] = -1
					end
				end

				@printf("\n  n=%4d  noise=%.0e  |  support_pts: aaad=%d  s2=%d  s3=%d\n",
					n_data, noise,
					n_support[:aaad], n_support[:s2_aaa_mle], n_support[:s3_se])

				# Evaluate derivatives at interior points
				@printf("  %5s  ", "order")
				for iname in interp_names
					@printf("  %12s", iname)
				end
				println("  |  min_d_s3   min_d_aaad")

				for order in 0:max_order
					# True derivatives at interior eval points
					truth = [true_deriv(tf, x, order) for x in eval_pts.interior]

					@printf("    %d    ", order)
					for iname in interp_names
						if interps[iname] === nothing
							@printf("  %12s", "FAIL")
							continue
						end
						predicted = [safe_nth_deriv(interps[iname], order, x) for x in eval_pts.interior]
						err = nrmse(predicted, truth)
						push!(results, (func = label(tf), n = n_data, noise = noise,
							interp = iname, order = order, eval_type = :interior,
							nrmse = err, n_support = n_support[iname]))
						if err < 1e-12
							@printf("  %12s", "<1e-12")
						elseif err > 1e6
							@printf("  %10.2e!!", err)
						else
							@printf("  %12.3e", err)
						end
					end

					# Min distance from eval points to support points
					s3_pts = get_support_points(interps[:s3_se] !== nothing ? interps[:s3_se] : interps[:aaad])
					aaad_pts = get_support_points(interps[:aaad] !== nothing ? interps[:aaad] : interps[:s3_se])
					min_d_s3 = minimum(min_distance_to_support(x, s3_pts) for x in eval_pts.interior)
					min_d_aaad = minimum(min_distance_to_support(x, aaad_pts) for x in eval_pts.interior)
					@printf("  |  %.2e  %.2e", min_d_s3, min_d_aaad)
					println()
				end

				# Also evaluate at on-data points for comparison
				if length(eval_pts.on_data) > 0
					println("  --- on-data evaluation ---")
					for order in [0, 2, 4, 6]
						order > max_order && continue
						truth = [true_deriv(tf, x, order) for x in eval_pts.on_data]
						@printf("    %d    ", order)
						for iname in interp_names
							if interps[iname] === nothing
								@printf("  %12s", "FAIL")
								continue
							end
							predicted = [safe_nth_deriv(interps[iname], order, x) for x in eval_pts.on_data]
							err = nrmse(predicted, truth)
							push!(results, (func = label(tf), n = n_data, noise = noise,
								interp = iname, order = order, eval_type = :on_data,
								nrmse = err, n_support = n_support[iname]))
							if err < 1e-12
								@printf("  %12s", "<1e-12")
							elseif err > 1e6
								@printf("  %10.2e!!", err)
							else
								@printf("  %12.3e", err)
							end
						end
						println()
					end
				end
			end
		end
	end

	# Run LV test
	println("\n" * "─"^120)
	println("Test function: LV_y1   domain: [0, 10]")
	println("─"^120)

	for n_data in [101, 501]
		for noise in [0.0, 1e-4]
			xs = range(0.0, 10.0, length = n_data) |> collect
			ys_true = [lv_sol(x)[1] for x in xs]
			ys = ys_true .+ noise * randn(n_data) .* max.(abs.(ys_true), 1.0)

			eval_pts = make_eval_points(0.0, 10.0, n_data)

			interps = Dict{Symbol,Any}()
			for iname in interp_names
				interps[iname] = fit_interpolator(iname, xs, ys)
			end

			n_support = Dict{Symbol,Int}()
			for iname in interp_names
				n_support[iname] = interps[iname] !== nothing ? count_support_points(interps[iname]) : -1
			end

			@printf("\n  n=%4d  noise=%.0e  |  support_pts: aaad=%d  s2=%d  s3=%d\n",
				n_data, noise,
				n_support[:aaad], n_support[:s2_aaa_mle], n_support[:s3_se])

			@printf("  %5s  ", "order")
			for iname in interp_names
				@printf("  %12s", iname)
			end
			println()

			for order in 0:min(5, max_order)  # LV: only up to order 5
				truth = [lv_true_deriv(lv_sol, x, order) for x in eval_pts.interior]
				@printf("    %d    ", order)
				for iname in interp_names
					if interps[iname] === nothing
						@printf("  %12s", "FAIL")
						continue
					end
					predicted = [safe_nth_deriv(interps[iname], order, x) for x in eval_pts.interior]
					err = nrmse(predicted, truth)
					push!(results, (func = "LV_y1", n = n_data, noise = noise,
						interp = iname, order = order, eval_type = :interior,
						nrmse = err, n_support = n_support[iname]))
					if err < 1e-12
						@printf("  %12s", "<1e-12")
					elseif err > 1e6
						@printf("  %10.2e!!", err)
					else
						@printf("  %12.3e", err)
					end
				end
				println()
			end
		end
	end

	# ─────────────────────────────────────────────────────────
	# Targeted diagnostic: S3 support point density experiment
	# ─────────────────────────────────────────────────────────
	println("\n" * "="^120)
	println("DIAGNOSTIC: S3 with varying aaa_tol (support point density)")
	println("="^120)

	xs = range(0.0, 1.0, length = 501) |> collect
	ys = sin.(2π .* xs)

	aaa_tols = [1e-4, 1e-6, 1e-8, 1e-10, 1e-12, 1e-14]
	eval_x = 0.3 + 1e-3  # Single interior point, away from data

	println("\n  aaa_tol    n_support   ", join([@sprintf("order_%d     ", o) for o in 0:7]))
	for tol in aaa_tols
		try
			interp = s2_aaa_mle(xs, ys; aaa_tol = tol)
			n_sup = count_support_points(interp)
			@printf("  %.0e    %5d      ", tol, n_sup)
			for order in 0:7
				val = safe_nth_deriv(interp, order, eval_x)
				truth_val = true_deriv(SinTest(), eval_x, order)
				rel_err = abs(truth_val) > 1e-15 ? abs(val - truth_val) / abs(truth_val) : abs(val - truth_val)
				if rel_err < 1e-12
					@printf("  <1e-12    ")
				else
					@printf("  %.2e  ", rel_err)
				end
			end
			println()
		catch e
			@printf("  %.0e    FAILED: %s\n", tol, e)
		end
	end

	# Also test: evaluate AWAY from support points vs ON support points
	println("\n" * "="^120)
	println("DIAGNOSTIC: Near-support-point vs far-from-support-point evaluation")
	println("="^120)

	xs501 = range(0.0, 1.0, length = 501) |> collect
	ys501 = sin.(2π .* xs501)
	s3_interp = s3_se(xs501, ys501)
	aaad_interp = aaad(xs501, ys501)
	gp_interp = agp_gpr_robust(xs501, ys501; kernel_type = :se)

	s3_sup = get_support_points(s3_interp)
	aaad_sup = get_support_points(aaad_interp)

	println("\n  S3 support points: $(length(s3_sup))")
	println("  AAAD support points: $(length(aaad_sup))")

	# Find a point maximally far from S3 support points
	candidates = range(0.1, 0.9, length = 10000)
	far_pt = candidates[argmax([min_distance_to_support(c, s3_sup) for c in candidates])]
	near_pt = candidates[argmin([min_distance_to_support(c, s3_sup) for c in candidates])]
	far_dist = min_distance_to_support(far_pt, s3_sup)
	near_dist = min_distance_to_support(near_pt, s3_sup)

	println("  Far point: x=$(round(far_pt, digits=6)), min_dist_to_S3_support=$(far_dist)")
	println("  Near point: x=$(round(near_pt, digits=6)), min_dist_to_S3_support=$(near_dist)")

	println("\n  Order    S3@far        S3@near       GP@far        GP@near       AAAD@far      AAAD@near     truth@far     truth@near")
	for order in 0:7
		tf_far = true_deriv(SinTest(), far_pt, order)
		tf_near = true_deriv(SinTest(), near_pt, order)

		s3_far = safe_nth_deriv(s3_interp, order, far_pt)
		s3_near = safe_nth_deriv(s3_interp, order, near_pt)
		gp_far = safe_nth_deriv(gp_interp, order, far_pt)
		gp_near = safe_nth_deriv(gp_interp, order, near_pt)
		aaad_far = safe_nth_deriv(aaad_interp, order, far_pt)
		aaad_near = safe_nth_deriv(aaad_interp, order, near_pt)

		# Print relative errors
		@printf("    %d    ", order)
		for (val, truth) in [(s3_far, tf_far), (s3_near, tf_near),
			(gp_far, tf_far), (gp_near, tf_near),
			(aaad_far, tf_far), (aaad_near, tf_near)]
			re = abs(truth) > 1e-15 ? abs(val - truth) / abs(truth) : abs(val - truth)
			if re < 1e-12
				@printf("  <1e-12     ")
			else
				@printf("  %.3e  ", re)
			end
		end
		@printf("  %.3e  %.3e", tf_far, tf_near)
		println()
	end

	# ─────────────────────────────────────────────────────────
	# Summary table
	# ─────────────────────────────────────────────────────────
	println("\n" * "="^120)
	println("SUMMARY: Median NRMSE by interpolator and order (interior eval, noise=0, n=501)")
	println("="^120)

	for order in 0:max_order
		@printf("  order %d: ", order)
		for iname in interp_names
			subset = filter(r -> r.interp == iname && r.order == order &&
								  r.eval_type == :interior && r.noise == 0.0 && r.n == 501, results)
			if !isempty(subset)
				med = median([r.nrmse for r in subset])
				if med < 1e-12
					@printf("  %10s=<1e-12", iname)
				else
					@printf("  %10s=%.2e", iname, med)
				end
			end
		end
		println()
	end

	# Write CSV
	csv_path = joinpath(dirname(@__FILE__), "..", "..", "artifacts", "s3_derivative_verification.csv")
	mkpath(dirname(csv_path))
	open(csv_path, "w") do io
		println(io, "func,n,noise,interp,order,eval_type,nrmse,n_support")
		for r in results
			println(io, "$(r.func),$(r.n),$(r.noise),$(r.interp),$(r.order),$(r.eval_type),$(r.nrmse),$(r.n_support)")
		end
	end
	println("\nResults written to: $csv_path")
end

# Run
run_comparison()
