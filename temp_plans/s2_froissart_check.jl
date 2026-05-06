#!/usr/bin/env julia
# s2_froissart_check.jl
# Diagnostic for whether the s2_aaa_mle_interpolator on forced_lv (1% noise)
# carries Froissart doublets, and whether deflation can rescue it.
#
# Run with:
#   julia --startup-file=no /home/orebas/.julia/dev/ODEParameterEstimation/temp_plans/s2_froissart_check.jl

using ODEParameterEstimation
using BaryRational
using TaylorDiff
using OrdinaryDiffEq
using LinearAlgebra
using Printf
using DelimitedFiles

println("="^70)
println("S2 Froissart-doublet diagnostic on forced_lotka_volterra (noise=1e-2)")
println("="^70)

# ---------------------------------------------------------------------------
# 1) Load data
# ---------------------------------------------------------------------------
data_path = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2/data.csv"
raw = readdlm(data_path, ',')
ts = Vector{Float64}(raw[:, 1])
y1 = Vector{Float64}(raw[:, 2])  # = 2*x
y2 = Vector{Float64}(raw[:, 3])  # = 2*yv
@printf "Data points: %d, t in [%.4f, %.4f]\n" length(ts) ts[1] ts[end]

# ---------------------------------------------------------------------------
# 2) Build oracle reference: integrate forced_lv with truth params
#    at high accuracy, then compute Taylor derivatives via TaylorDiff
# ---------------------------------------------------------------------------
const _alpha = 0.103
const _beta  = 0.243
const _delta = 0.59
const _gamma = 0.165

function forced_lv!(du, u, p, t)
    x, yv = u
    du[1] = (-0.3 * sin(2.0 * t) + 6.0 * _alpha * x - 8.0 * _beta * x * yv) / 2.0
    du[2] = (-12.0 * _gamma * yv + 4.0 * _delta * x * yv) / 2.0
    return nothing
end

ic = [0.806, 0.676]
tspan = (0.0, 5.0)
prob = ODEProblem(forced_lv!, ic, tspan)
sol = solve(prob, Vern9(); abstol = 1e-14, reltol = 1e-14, dense = true)

# Oracle: y1(t) = 2*x(t),  y2(t) = 2*yv(t).  We need n-th derivative at t.
function oracle_deriv(component::Int, n::Int, t::Float64)
    # Build a smooth function of t by Hermite-style ODE re-integration is overkill;
    # we leverage TaylorDiff on the SOLUTION itself which is interpolated dense.
    # The dense interpolant of Vern9 is high-order so derivatives are accurate
    # for moderate orders.  We confirm by comparing two methods if needed.
    f = t_in -> 2.0 * sol(t_in, idxs = component)
    return TaylorDiff.derivative(f, t, Val(n))
end

# ---------------------------------------------------------------------------
# 3) Build s2_aaa_mle interpolant for y1 and y2.
#    We use the EXACT same path as production: BaryRational.aaa(...) with tol=1e-10.
# ---------------------------------------------------------------------------
println("\n--- Building S2 interpolants (BaryRational.aaa + MLE) ---")
aaa_y1 = BaryRational.aaa(ts, y1; tol = 1e-10, mmax = 200)  # default clean=1
aaa_y2 = BaryRational.aaa(ts, y2; tol = 1e-10, mmax = 200)
@printf "y1: %d AAA support points after default cleanup\n" length(aaa_y1.x)
@printf "y2: %d AAA support points after default cleanup\n" length(aaa_y2.x)

# Probe: try with clean=false to count what was cleaned up
aaa_y1_dirty = BaryRational.aaa(ts, y1; tol = 1e-10, mmax = 200, clean = 0)
aaa_y2_dirty = BaryRational.aaa(ts, y2; tol = 1e-10, mmax = 200, clean = 0)
@printf "y1 with clean=0: %d support points (%d cleaned by default)\n" length(aaa_y1_dirty.x) (length(aaa_y1_dirty.x) - length(aaa_y1.x))
@printf "y2 with clean=0: %d support points (%d cleaned by default)\n" length(aaa_y2_dirty.x) (length(aaa_y2_dirty.x) - length(aaa_y2.x))

# Probe: aggressive cleanup (clean=2, Chebfun-style)
aaa_y1_clean2 = BaryRational.aaa(ts, y1; tol = 1e-10, mmax = 200, clean = 2)
aaa_y2_clean2 = BaryRational.aaa(ts, y2; tol = 1e-10, mmax = 200, clean = 2)
@printf "y1 with clean=2 (Chebfun): %d support points\n" length(aaa_y1_clean2.x)
@printf "y2 with clean=2 (Chebfun): %d support points\n" length(aaa_y2_clean2.x)

# ---------------------------------------------------------------------------
# 4) Examine pole/zero structure
# ---------------------------------------------------------------------------
function analyze_prz(name, r; t_lo = 0.0, t_hi = 5.0)
    pol, res, zer = BaryRational.prz(r.x, r.f, r.w)
    println("\n  [$name] $(length(pol)) poles, $(length(zer)) zeros")
    # Filter near-real poles inside [t_lo, t_hi] extended by 0.5
    domain_lo, domain_hi = t_lo - 0.5, t_hi + 0.5
    in_range_real = filter(p -> abs(imag(p)) < 1e-3 && domain_lo <= real(p) <= domain_hi, pol)
    in_range_any = filter(p -> domain_lo <= real(p) <= domain_hi, pol)
    @printf "  poles with |Im|<1e-3 in domain: %d\n" length(in_range_real)
    @printf "  any poles in domain real-range: %d\n" length(in_range_any)
    if !isempty(pol)
        min_imag = minimum(abs.(imag.(pol)))
        @printf "  min |Im(pole)| over ALL poles: %.3e\n" min_imag
    end

    # Doublet test: for each near-real in-domain pole, find closest zero.
    # Threshold: 1e-3 of data range (= 5.0).
    threshold = 1e-3 * (t_hi - t_lo)  # 5e-3
    n_doublets = 0
    println("  Doublet candidates (|pole-zero|<", threshold, "):")
    for (k, p) in enumerate(in_range_real)
        if isempty(zer)
            continue
        end
        d = minimum(abs.(zer .- p))
        rj_idx = findfirst(==(p), pol)
        rmag = isnothing(rj_idx) ? NaN : abs(res[rj_idx])
        marker = d < threshold ? " <-- DOUBLET" : ""
        if k <= 12  # limit output
            @printf "    pole=%.4e+%.2ei,  res=%.3e,  min|zero-pole|=%.3e%s\n" real(p) imag(p) rmag d marker
        end
        d < threshold && (n_doublets += 1)
    end
    @printf "  TOTAL doublets (|p-z|<%g): %d\n" threshold n_doublets
    return pol, res, zer, n_doublets
end

println("\n--- AAA(default clean=1) pole structure ---")
pol_y1, res_y1, zer_y1, nd_y1 = analyze_prz("y1 default", aaa_y1)
pol_y2, res_y2, zer_y2, nd_y2 = analyze_prz("y2 default", aaa_y2)

println("\n--- AAA(clean=0, no cleanup) pole structure ---")
pol_y1d, res_y1d, zer_y1d, nd_y1d = analyze_prz("y1 dirty", aaa_y1_dirty)
pol_y2d, res_y2d, zer_y2d, nd_y2d = analyze_prz("y2 dirty", aaa_y2_dirty)

println("\n--- AAA(clean=2, Chebfun aggressive) pole structure ---")
pol_y1c, res_y1c, zer_y1c, nd_y1c = analyze_prz("y1 clean2", aaa_y1_clean2)
pol_y2c, res_y2c, zer_y2c, nd_y2c = analyze_prz("y2 clean2", aaa_y2_clean2)

# ---------------------------------------------------------------------------
# 5) Now apply MLE refinement (production path) and compare derivatives
#    We have to get at the helpers; ODEPE exports s2_aaa_mle_interpolator
#    and aaad_gpr_pivot. Use those directly.
# ---------------------------------------------------------------------------
println("\n" * "="^70)
println("Production interpolators: derivative accuracy at SP=1.083 and t=4.95")
println("="^70)

# Build production interpolants
s2_y1 = ODEParameterEstimation.s2_aaa_mle_interpolator(ts, y1)
s2_y2 = ODEParameterEstimation.s2_aaa_mle_interpolator(ts, y2)
gpr_y1 = ODEParameterEstimation.aaad_gpr_pivot(ts, y1)
gpr_y2 = ODEParameterEstimation.aaad_gpr_pivot(ts, y2)

# Look at s2's poles/zeros AFTER MLE
s2_inner_y1 = s2_y1.internalAAA  # _BaryResult
s2_inner_y2 = s2_y2.internalAAA
println("\n--- After MLE refinement (production S2) ---")
analyze_prz("y1 S2-MLE", (x = s2_inner_y1.x, f = s2_inner_y1.f, w = s2_inner_y1.w))
analyze_prz("y2 S2-MLE", (x = s2_inner_y2.x, f = s2_inner_y2.f, w = s2_inner_y2.w))

# Pick test points and orders.  The G3 sweep mentioned SP=0.083, 0.333, 1.083, 2.787.
# We'll test 1.083 and 4.95 as requested.
test_points = [1.083, 4.95, 0.083]
max_order = 4  # forced_lv typically needs orders up to ~3

function rel_err(approx, truth)
    den = max(abs(truth), 1e-12)
    return abs(approx - truth) / den
end

function deriv_table(name, interp, component, ts, max_order)
    println("  [$name, comp $component]")
    for tt in test_points
        for n in 0:max_order
            try
                approx = TaylorDiff.derivative(t -> interp(t), tt, Val(n))
                truth  = oracle_deriv(component, n, tt)
                @printf "    t=%.3f order=%d: approx=% .4e  truth=% .4e  rel=% .3e\n" tt n approx truth rel_err(approx, truth)
            catch e
                @printf "    t=%.3f order=%d: ERROR %s\n" tt n string(e)
            end
        end
    end
end

println("\n--- S2 (production aaa_mle) derivative errors ---")
deriv_table("S2 y1", s2_y1, 1, ts, max_order)
deriv_table("S2 y2", s2_y2, 2, ts, max_order)

println("\n--- aaad_gpr_pivot (GP only, no AAA) derivative errors ---")
deriv_table("GPR y1", gpr_y1, 1, ts, max_order)
deriv_table("GPR y2", gpr_y2, 2, ts, max_order)

# ---------------------------------------------------------------------------
# 6) Prototype: deflation BEFORE MLE.  Build modified S2 by deflating
#    Froissart doublets, then re-running MLE.  Compare derivative errors.
# ---------------------------------------------------------------------------
println("\n" * "="^70)
println("PROTOTYPE: AAA + manual deflation + MLE (s2_deflated)")
println("="^70)

# Helper: identify support points to drop based on doublet criterion.
function deflate_support(z::Vector{Float64}, w::Vector{Float64}, f::Vector{Float64};
                          threshold = 5e-3, t_lo = 0.0, t_hi = 5.0)
    # Compute poles, residues, zeros from current barycentric form
    pol, res, zer = BaryRational.prz(z, f, w)
    domain_lo, domain_hi = t_lo - 0.5, t_hi + 0.5
    bad_poles = ComplexF64[]
    for (k, p) in enumerate(pol)
        # Near-real, in domain
        if abs(imag(p)) < 1e-3 && domain_lo <= real(p) <= domain_hi
            d = isempty(zer) ? Inf : minimum(abs.(zer .- p))
            if d < threshold
                push!(bad_poles, p)
            end
        end
    end
    println("  Identified $(length(bad_poles)) doublet poles to deflate (threshold=$threshold)")

    # For each bad pole, drop the nearest support point (mirrors BaryRational.cleanup!)
    drop_idx = Int[]
    z_remaining = copy(z)
    avail = collect(1:length(z))
    for p in bad_poles
        if isempty(avail)
            break
        end
        # find the support point in `avail` closest to real(p)
        dists = [abs(z[i] - real(p)) for i in avail]
        _, k = findmin(dists)
        push!(drop_idx, avail[k])
        deleteat!(avail, k)
    end
    keep = setdiff(1:length(z), drop_idx)
    return z[keep], w[keep], f[keep], length(bad_poles)
end

# Solve for new w at the trimmed support points (Loewner LSQ with original data)
function refit_weights(z_new::Vector{Float64}, f_new::Vector{Float64},
                       Z::Vector{Float64}, F::Vector{Float64})
    # Remove support points from sample set
    keep = trues(length(Z))
    for zs in z_new
        idx = findfirst(==(zs), Z)
        if !isnothing(idx)
            keep[idx] = false
        end
    end
    Zr = Z[keep]
    Fr = F[keep]
    m = length(z_new)
    # Loewner matrix
    C = 1.0 ./ (Zr .- transpose(z_new))
    A = (Fr .* C) - (C .* transpose(f_new))
    G = svd(A)
    return G.V[:, m]
end

function build_s2_deflated(ts::Vector{Float64}, y::Vector{Float64})
    # Step 1: AAA (with default cleanup, since that's what production uses)
    r = BaryRational.aaa(ts, y; tol = 1e-10, mmax = 200)
    z = copy(r.x); w = copy(r.w); f = copy(r.f)
    @printf "  Before our deflation: %d support points\n" length(z)

    # Step 2: deflation (in case default cleanup left some)
    z2, w2, f2, n_dropped = deflate_support(z, w, f; threshold = 5e-3)
    @printf "  After deflation: %d support points (dropped %d)\n" length(z2) (length(z) - length(z2))

    # If we dropped any, refit weights via Loewner LSQ
    if length(z2) < length(z)
        w2 = refit_weights(z2, f2, ts, y)
    end

    # Step 3: MLE refinement
    z3, w3, f3 = ODEParameterEstimation._mle_refine_bary(z2, w2, f2, ts, y;
                                                         maxiter = 20000, g_tol = 1e-15)
    return ODEParameterEstimation.AAADapprox(ODEParameterEstimation._BaryResult(z3, w3, f3))
end

println("\n--- Building deflated S2 for y1, y2 ---")
s2d_y1 = build_s2_deflated(ts, y1)
s2d_y2 = build_s2_deflated(ts, y2)

println("\n--- After deflation+MLE (s2_deflated) pole structure ---")
analyze_prz("y1 S2d", (x = s2d_y1.internalAAA.x, f = s2d_y1.internalAAA.f, w = s2d_y1.internalAAA.w))
analyze_prz("y2 S2d", (x = s2d_y2.internalAAA.x, f = s2d_y2.internalAAA.f, w = s2d_y2.internalAAA.w))

println("\n--- Deflated S2 derivative errors ---")
deriv_table("S2d y1", s2d_y1, 1, ts, max_order)
deriv_table("S2d y2", s2d_y2, 2, ts, max_order)

println("\n" * "="^70)
println("DONE.")
println("="^70)
