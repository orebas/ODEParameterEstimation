# ── Per-run estimation context ────────────────────────────────────────────────
# Replaces the module-global run-state Refs (_TIMING_CAPTURE_ENABLED,
# _LAST_ESTIMATION_TIMING, _LAST_ESTIMATION_AUTO_M, and the two timing-sink
# Refs) with a dynamically-scoped, task-inherited context (Base.ScopedValues —
# child tasks spawned inside a run inherit the binding). This removes the
# cross-run contamination class flagged in the 2026-07 review: two analyses in
# one process can no longer read each other's auto-M or timing, and the sink
# save/install/restore dance disappears entirely.
#
# Deliberately NOT migrated:
#   - `_LAST_ESTIMATION_REUSE` (optimized_multishot_estimation.jl): a CROSS-run
#     hand-off consumed after the run completes (consensus/benchmark flows via
#     `_last_estimation_reuse()`). Global by design.
#   - the `_*_TIMING_CONTEXT_STACK` label stacks (si_template_integration.jl):
#     module-global; worst case under concurrent runs is mislabeled timing
#     rows. Follow-up candidate.

using Base.ScopedValues: ScopedValue

mutable struct RunContext
	capture_timing::Bool
	timing::Union{Nothing, TimingBreakdown}
	auto_m::Union{Nothing, Int}
	resolve_timing_sink::Union{Nothing, Vector{NamedTuple}}
	detailed_timing_sink::Union{Nothing, Vector{NamedTuple}}
	# Per-analysis HC solver config (from EstimationOptions; nothing = fall back
	# to the module Refs HC_SOLVE_THREADING / HC_COMPILE_MODE).
	hc_threading::Union{Nothing, Bool}
	hc_compile_mode::Union{Nothing, Symbol}
	# Timing context-label stacks (formerly module-global in
	# si_template_integration.jl; per-run here so concurrent runs cannot
	# mislabel each other's timing rows).
	resolve_timing_labels::Vector{Symbol}
	detailed_timing_labels::Vector{Symbol}
end
RunContext(; capture_timing::Bool = false) =
	RunContext(capture_timing, nothing, nothing, nothing, nothing,
		nothing, nothing, Symbol[], Symbol[])

const RUN_CONTEXT = ScopedValue{Union{Nothing, RunContext}}(nothing)

_run_ctx() = RUN_CONTEXT[]
_run_ctx_capture_timing() = (c = RUN_CONTEXT[]; c !== nothing && c.capture_timing)
_run_ctx_set_timing!(tb) = (c = RUN_CONTEXT[]; c === nothing || (c.timing = tb); nothing)
_run_ctx_set_auto_m!(m) = (c = RUN_CONTEXT[]; c === nothing || (c.auto_m = m); nothing)

"""
	_run_ctx_take_auto_m!() -> Union{Nothing, Int}

Consume-once read of the run's auto-detected algebraic multiplicity: returns
the value and clears it, so it can never leak into a later analysis sharing an
outer scope. Returns `nothing` when no context is bound.
"""
function _run_ctx_take_auto_m!()
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	m = c.auto_m
	c.auto_m = nothing
	return m
end

function _run_ctx_install_sinks!(resolve_records::Vector{NamedTuple}, detailed_records::Vector{NamedTuple})
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	c.resolve_timing_sink = resolve_records
	c.detailed_timing_sink = detailed_records
	return nothing
end
_run_ctx_resolve_sink() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.resolve_timing_sink)
_run_ctx_detailed_sink() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.detailed_timing_sink)

function _run_ctx_set_hc_opts!(threading::Bool, compile_mode::Symbol)
	c = RUN_CONTEXT[]
	c === nothing && return nothing
	c.hc_threading = threading
	c.hc_compile_mode = compile_mode
	return nothing
end
_run_ctx_hc_threading() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.hc_threading)
_run_ctx_hc_compile_mode() = (c = RUN_CONTEXT[]; c === nothing ? nothing : c.hc_compile_mode)

"""
	_with_run_context(f; capture_timing=false) -> (value, ctx)

Bind a fresh `RunContext` for the duration of `f()`; return `(f(), ctx)`. The
ctx object stays readable after the scope exits (it is an ordinary mutable
struct), which is how `with_estimation_timing` retrieves the timing breakdown.
"""
function _with_run_context(f::Function; capture_timing::Bool = false)
	ctx = RunContext(; capture_timing)
	value = Base.ScopedValues.with(f, RUN_CONTEXT => ctx)
	return value, ctx
end
