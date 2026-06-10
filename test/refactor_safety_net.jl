# Refactor safety net — added 2026-06-09, BEFORE the code-review cleanup
# (see docs/2026-06-09_code_review.md and docs/2026-06-09_test_safety_net.md).
#
# Purpose: give the upcoming refactors (dead-code removal, dedup, type annotations,
# file splits) a behavior lock, and give the P0 bug fixes a concrete target.
#
# Convention:
#   @test        -> behavior to LOCK (green now, must stay green through refactors)
#   @test_broken -> CORRECT behavior the P0 fix should produce (red now -> flips on fix)

using ODEParameterEstimation
using Test
using LinearAlgebra
import ModelingToolkit

@testset "Refactor safety net (pre-cleanup)" begin

	# --- P0#4 (caller-side): lock the parser's documented behavior ------------
	# The parser is correct per its docstring ("last _N is always the derivative
	# order"); the real bug is callers applying it to bare param/state names that
	# legitimately end in _<digit>. Lock current behavior so the caller-side fix
	# (classify_si_ring_variable / _multipoint_deriv_order checking known params
	# first) is a deliberate, visible change.
	@testset "parse_derivative_variable_name documented behavior" begin
		P = ODEParameterEstimation.parse_derivative_variable_name
		@test P("y1_2") == ("y1", 2)
		@test P("y_2") == ("y", 2)
		@test P("y1_0") == ("y1", 0)
		@test P("_obs_trfn_cos_5_0_cos_3") == ("_obs_trfn_cos_5_0_cos", 3)
		@test P("y1") === nothing            # no _N suffix -> nothing
		# Ambiguity at the heart of P0#4: a parameter literally named k_2 parses as
		# d^2/dt^2 of k. Documented here so the fix lands caller-side, not here.
		@test P("k_2") == ("k", 2)
	end

	# --- P0#3: lock AAA interior accuracy so the baryEval tolerance fix can't
	# regress the common case (normal grid spacing, well clear of the ~5.6e-4
	# special-case window). ----------------------------------------------------
	@testset "aaad/baryEval interior accuracy lock" begin
		x = collect(range(0.0, 2.0; length = 41))   # spacing 0.05 >> 5.6e-4
		f = sin.(2.0 .* x)
		F = ODEParameterEstimation.aaad(x, f)
		for z in (0.123, 0.777, 1.314, 1.951)        # interior, off-node
			@test F(z) ≈ sin(2.0 * z) atol = 1e-7
		end
		@test F(x[20]) ≈ f[20] atol = 1e-10          # exactly on a node
		# first derivative via the production accessor
		@test ODEParameterEstimation.nth_deriv_at(F, 1, 0.777) ≈ 2.0 * cos(2.0 * 0.777) atol = 1e-5
	end

	# --- P0#1: process_raw_solution error divisor ------------------------------
	# simple() has TWO observables, so data_sample has 3 keys ("t", y1, y2).
	# The bug divides the per-observable error sum by length(data_sample)=3
	# instead of the observable count 2. Offset both observables by a known δ so
	# the per-observable residual is large and clean, then recompute the sum from
	# the SAME ode_solution the function returned (robust to solver tolerance).
	@testset "process_raw_solution error divisor" begin
		opts = EstimationOptions()
		sampled = ODEParameterEstimation.sample_problem_data(ODEParameterEstimation.simple(), opts)
		current_states = ModelingToolkit.unknowns(sampled.model.system)
		current_params = ModelingToolkit.parameters(sampled.model.system)
		raw_sol = vcat(
			[Float64(sampled.ic[s]) for s in current_states],
			[Float64(sampled.p_true[p]) for p in current_params],
		)

		δ = 0.1
		offset_data = deepcopy(sampled.data_sample)
		obs_keys = [k for k in keys(offset_data) if !isequal(k, "t")]
		n_obs = length(obs_keys)                     # == 2 for simple()
		@test n_obs == 2
		for k in obs_keys
			offset_data[k] = offset_data[k] .+ δ
		end

		_, _, ode_solution, err = ODEParameterEstimation.process_raw_solution(
			raw_sol, sampled.model, offset_data, sampled.solver,
			abstol = opts.abstol, reltol = opts.reltol,
		)
		@test ode_solution !== nothing

		# Recompute the per-observable error sum exactly as the source does.
		t = offset_data["t"]
		my_sum = 0.0
		for k in obs_keys
			my_sum += norm(ode_solution(t)[k] .- offset_data[k]) / length(t)
		end

		# Fixed 2026-06-09 (review P0#1): err is the mean over observables; the
		# "t" key in data_sample no longer deflates the divisor.
		@test err ≈ my_sum / n_obs rtol = 1e-6
	end
end
