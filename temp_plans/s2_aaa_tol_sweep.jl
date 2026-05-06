#!/usr/bin/env julia
# Probe: what does AAA produce as we relax aaa_tol on noisy forced_lv data?
using ODEParameterEstimation
using BaryRational
using DelimitedFiles
using Printf

data_path = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em2/data.csv"
raw = readdlm(data_path, ',')
ts = Vector{Float64}(raw[:, 1])
y1 = Vector{Float64}(raw[:, 2])

# 1% noise → optimal AAA tolerance is roughly 1% of |y|, i.e. tol≈1e-2 OR tol≈1e-3
# Production uses tol=1e-10 which is FAR below the noise floor.
println("AAA support-point count vs aaa_tol on noisy y1 (forced_lv 1% noise)")
for tol in [1e-1, 5e-2, 2e-2, 1e-2, 5e-3, 1e-3, 1e-4, 1e-6, 1e-8, 1e-10]
    r = BaryRational.aaa(ts, y1; tol = tol, mmax = 200)
    pol, res, zer = BaryRational.prz(r.x, r.f, r.w)
    in_dom = count(p -> abs(imag(p)) < 1e-3 && -0.5 <= real(p) <= 5.5, pol)
    @printf "  tol=%.0e:  m=%3d  in-domain real poles=%d\n" tol length(r.x) in_dom
end
