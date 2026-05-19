#!/usr/bin/env julia
# Minimal reproducer for the per-iteration memory growth suspected in
# solve_with_robust.jl:98-103 (the :symbolic Jacobian path).
#
# Compares two modes side-by-side, each iter:
#   :symbolic      -- mirrors :symbolic path: substitute -> jacobian -> 2x build_function
#                     (matches solve_with_robust.jl lines 60-66 + 98-103)
#   :forwarddiff   -- mirrors :forwarddiff path: substitute -> 1x build_function (residual only)
#                     (matches solve_with_robust.jl lines 60-66 only;
#                      the ForwardDiff jac/grad funcs at 118-125 are pure closures over
#                      the compiled residual, no extra build_function call)
#
# If :symbolic's gc_live/maxrss slope is steeper than :forwarddiff's, that
# confirms the per-call jacobian + 2x build_function is the dominant per-iter
# memory contributor and Phase 1 will help.
#
# Run: julia --startup-file=no repro/memory_audit_2026_05_19/symbolics_jac_mwe.jl

using Symbolics
using ForwardDiff
using Printf
using Random

const N_VARS = 20
const N_DATA = 12
const N_EQS  = 20
const N_ITERS = 200
const REPORT_EVERY = 25

Random.seed!(0)

@variables x[1:N_VARS] d[1:N_DATA]
const VARLIST = [x[i] for i in 1:N_VARS]
const DATALIST = [d[i] for i in 1:N_DATA]

# Build a representative template once.  Mix products of vars, products with
# data, and a couple of transcendentals -- shapes typical of SI-template eqs
# after _trfn_ expansion.
function build_template()
    eqs = Vector{Num}(undef, N_EQS)
    for i in 1:N_EQS
        a = sum(x[mod1(i + j, N_VARS)] * x[mod1(i - j + 5, N_VARS)] for j in 1:3)
        b = sum(d[mod1(i + j, N_DATA)] * x[mod1(i + 2j, N_VARS)] for j in 1:4)
        c = sin(d[mod1(i, N_DATA)] * x[mod1(i, N_VARS)])
        e = cos(d[mod1(i + 1, N_DATA)]) * x[mod1(i + 3, N_VARS)]^2
        eqs[i] = a + b + c + e + d[mod1(i, N_DATA)]
    end
    return eqs
end

const TEMPLATE_EQS = build_template()

# Mirrors solve_with_robust.jl:60-66 (residual) + 98-103 (symbolic jacobian + grad).
function run_iter_symbolic!(template_eqs, varlist, data_dict)
    poly_system = Symbolics.substitute.(template_eqs, Ref(data_dict))
    _, f_ip = Symbolics.build_function(poly_system, varlist; expression = Val(false))
    J_expr = Symbolics.jacobian(poly_system, varlist)
    jac_func = Symbolics.build_function(J_expr, varlist; expression = Val(false))[2]
    grad_expr = J_expr' * poly_system
    grad_func = Symbolics.build_function(grad_expr, varlist; expression = Val(false))[2]
    return nothing
end

# Mirrors solve_with_robust.jl:60-66 (residual) + 118-125 (ForwardDiff closures).
# Per-iter delta vs the :symbolic path: no jacobian, no grad_expr, no 2x build_function.
function run_iter_forwarddiff!(template_eqs, varlist, data_dict)
    poly_system = Symbolics.substitute.(template_eqs, Ref(data_dict))
    _, f_ip = Symbolics.build_function(poly_system, varlist; expression = Val(false))
    residual! = (res, u) -> (f_ip(res, u); nothing)
    # ForwardDiff "jac_func" and "grad_func" are pure closures -- no extra
    # build_function call.  Construct them so any closure-allocation cost is
    # accounted for, but never invoke them (matches solve_with_robust's flow
    # when no candidate is solved).
    m = length(poly_system)
    jac_func = function (J, u)
        ForwardDiff.jacobian!(J, u_ -> (r = similar(u_, m); residual!(r, u_); r), u)
    end
    grad_func = function (g, u)
        ForwardDiff.gradient!(g, u_ -> begin
            r = similar(u_, m)
            residual!(r, u_)
            0.5 * sum(r .^ 2)
        end, u)
    end
    return nothing
end

function report(label, iter)
    GC.gc(true); GC.gc(true); GC.gc(true)
    sym_size = Base.summarysize(Symbolics)
    base_live = Base.gc_live_bytes()
    rss = Sys.maxrss()
    @printf("[%-12s] iter=%4d  summarysize(Symbolics)=%6.2f MB  gc_live=%7.2f MB  maxrss=%8.2f MB\n",
        label, iter, sym_size / 1e6, base_live / 1e6, rss / 1e6)
end

function run_mode(mode_label, iter_fn)
    @info "=== Mode: $mode_label  ($N_ITERS iters, report every $REPORT_EVERY) ==="
    # Warm-up to pay one-time JIT costs before we measure the slope.
    data_dict = Dict(DATALIST[i] => rand() for i in 1:N_DATA)
    iter_fn(TEMPLATE_EQS, VARLIST, data_dict)
    report(mode_label, 0)
    base_rss = Sys.maxrss()
    base_live = Base.gc_live_bytes()
    for iter in 1:N_ITERS
        data_dict = Dict(DATALIST[i] => rand() for i in 1:N_DATA)
        iter_fn(TEMPLATE_EQS, VARLIST, data_dict)
        if iter % REPORT_EVERY == 0
            report(mode_label, iter)
        end
    end
    GC.gc(true); GC.gc(true); GC.gc(true)
    final_rss = Sys.maxrss()
    final_live = Base.gc_live_bytes()
    slope_rss = (final_rss - base_rss) / N_ITERS
    slope_live = (final_live - base_live) / N_ITERS
    @info @sprintf("[%s] post-warmup -> final: Δmaxrss=%+.2f MB (%.2f MB/iter), Δgc_live=%+.2f MB (%.2f MB/iter)",
        mode_label, (final_rss - base_rss) / 1e6, slope_rss / 1e6,
        (final_live - base_live) / 1e6, slope_live / 1e6)
    return (slope_rss = slope_rss, slope_live = slope_live)
end

function main()
    @info "Symbolics path comparison MWE: $N_VARS vars, $N_DATA data, $N_EQS eqs, $N_ITERS iters"
    sym_slopes = run_mode("symbolic", run_iter_symbolic!)
    fd_slopes = run_mode("forwarddiff", run_iter_forwarddiff!)
    @info "===== Summary ====="
    @info @sprintf("  :symbolic     slope: %.2f KB/iter rss, %.2f KB/iter gc_live",
        sym_slopes.slope_rss / 1024, sym_slopes.slope_live / 1024)
    @info @sprintf("  :forwarddiff  slope: %.2f KB/iter rss, %.2f KB/iter gc_live",
        fd_slopes.slope_rss / 1024, fd_slopes.slope_live / 1024)
    if sym_slopes.slope_rss > 0 && fd_slopes.slope_rss < sym_slopes.slope_rss / 4
        @info "VERDICT: switching to :forwarddiff should reduce per-iter memory growth by >4×."
    elseif sym_slopes.slope_rss > 0 && fd_slopes.slope_rss < sym_slopes.slope_rss / 2
        @info "VERDICT: :forwarddiff shows >2× lower per-iter growth -- Phase 1 should help."
    elseif sym_slopes.slope_rss <= 0
        @info "VERDICT: :symbolic shows no growth -- the leak is elsewhere; Phase 1 may not help."
    else
        @info "VERDICT: paths grow similarly -- the leak isn't in the jac/grad build chain."
    end
end

main()
