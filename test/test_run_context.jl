# Contract tests for the scoped RunContext (run_context.jl, 2026-07-24):
# per-run isolated state replacing the run-state globals (auto-M hand-off,
# timing capture, timing sinks). Pure/fast — no estimation runs.

using ODEParameterEstimation
using Test

const _OPE = ODEParameterEstimation

@testset "RunContext scoped state" begin
	# With no context bound, every helper is a safe no-op.
	@test _OPE._run_ctx() === nothing
	@test _OPE._run_ctx_capture_timing() === false
	@test _OPE._run_ctx_take_auto_m!() === nothing
	_OPE._run_ctx_set_auto_m!(3)              # no-op without a context
	@test _OPE._run_ctx_take_auto_m!() === nothing
	@test _OPE._run_ctx_resolve_sink() === nothing
	@test _OPE._run_ctx_detailed_sink() === nothing

	# Scoped set/take + consume-once semantics.
	value, ctx = _OPE._with_run_context() do
		@test _OPE._run_ctx() !== nothing
		_OPE._run_ctx_set_auto_m!(2)
		@test _OPE._run_ctx_take_auto_m!() == 2
		@test _OPE._run_ctx_take_auto_m!() === nothing   # consumed
		_OPE._run_ctx_set_auto_m!(5)
		:done
	end
	@test value === :done
	@test ctx.auto_m == 5                     # ctx object outlives the scope
	@test _OPE._run_ctx() === nothing         # scope exited cleanly

	# Sinks install onto the bound context and clear with the scope.
	_, ctx_s = _OPE._with_run_context() do
		recs = NamedTuple[]
		dets = NamedTuple[]
		_OPE._run_ctx_install_sinks!(recs, dets)
		@test _OPE._run_ctx_resolve_sink() === recs
		@test _OPE._run_ctx_detailed_sink() === dets
		nothing
	end
	@test _OPE._run_ctx_detailed_sink() === nothing

	# Child tasks inherit the binding (ScopedValues semantics) — this is what
	# lets spawned polish workers see the run's sinks.
	inherited, _ = _OPE._with_run_context() do
		fetch(Threads.@spawn _OPE._run_ctx() !== nothing)
	end
	@test inherited === true

	# Two concurrent contexts are fully isolated (the cross-run contamination
	# class this refactor removes).
	results = Dict{Int, Union{Nothing, Int}}()
	lk = ReentrantLock()
	@sync for k in (10, 20)
		Threads.@spawn _OPE._with_run_context() do
			_OPE._run_ctx_set_auto_m!(k)
			sleep(0.05)                        # overlap the two scopes
			got = _OPE._run_ctx_take_auto_m!()
			lock(() -> results[k] = got, lk)
		end
	end
	@test results[10] == 10
	@test results[20] == 20

	# Public API contract: with_estimation_timing passes the value through and
	# yields timing === nothing when f performs no estimation.
	v, timing = _OPE.with_estimation_timing(() -> 42)
	@test v == 42
	@test timing === nothing

	# HC solver-config carry: nothing-fallback without a context, carried values
	# inside one, cleared with the scope (2026-08-12 hardening).
	@test _OPE._run_ctx_hc_threading() === nothing
	@test _OPE._run_ctx_hc_compile_mode() === nothing
	_OPE._run_ctx_set_hc_opts!(false, :none)          # no-op without a context
	@test _OPE._run_ctx_hc_threading() === nothing
	_, ctx_hc = _OPE._with_run_context() do
		_OPE._run_ctx_set_hc_opts!(false, :none)
		@test _OPE._run_ctx_hc_threading() === false
		@test _OPE._run_ctx_hc_compile_mode() === :none
		nothing
	end
	@test ctx_hc.hc_compile_mode === :none
	@test _OPE._run_ctx_hc_threading() === nothing    # scope exited

	# Timing context-label stacks: per-run when bound, module fallback bare.
	@test _OPE._current_detailed_timing_context() === :unspecified
	_OPE._with_run_context() do
		_OPE._with_detailed_timing_context(:outer) do
			@test _OPE._current_detailed_timing_context() === :outer
			_OPE._with_detailed_timing_context(:inner) do
				@test _OPE._current_detailed_timing_context() === :inner
			end
			@test _OPE._current_detailed_timing_context() === :outer
		end
		@test _OPE._current_detailed_timing_context() === :unspecified
		nothing
	end
	# Bare-call fallback still functions (module stacks).
	_OPE._with_resolve_timing_context(:bare) do
		@test _OPE._current_resolve_timing_context() === :bare
	end
	@test _OPE._current_resolve_timing_context() === :unspecified
end
