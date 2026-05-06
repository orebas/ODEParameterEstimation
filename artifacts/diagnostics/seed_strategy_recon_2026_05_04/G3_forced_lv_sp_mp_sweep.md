# G3 — forced_lotka_volterra_0_1em2: SP × interpolator sweep + MP

Generated: 2026-05-05 19:17

Truth: alpha=0.103, beta=0.243, delta=0.59, gamma=0.165, IC x=0.806, yv=0.676
Noise: 1e-2 relative.

## Per-(SP, interp) summary table

| SP | interp | worst Δd rel | n_perf | n_prod | dist→truth | cond(J) | rank | β actual Δ | β IFT pred | α actual Δ | α IFT pred |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0.083 | aaad_gpr | 2.08e-01 | 1 | 1 | 3.397e-01 | 6.310e+01 | 12/12 | -2.112e-01 | -1.836e-01 | -1.879e-01 | -1.630e-01 |
| 0.083 | agp_robust | 2.08e-01 | 1 | 1 | 3.397e-01 | 6.310e+01 | 12/12 | -2.112e-01 | -1.836e-01 | -1.879e-01 | -1.630e-01 |
| 0.083 | agp_robust_se_times_rq | 2.10e-01 | 1 | 1 | 3.407e-01 | 6.310e+01 | 12/12 | -2.126e-01 | -1.853e-01 | -1.891e-01 | -1.646e-01 |
| 0.083 | chebyshev_bic | 8.84e-01 | 1 | 1 | 1.488e+00 | 6.310e+01 | 12/12 | -9.975e-01 | -9.178e-01 | -8.902e-01 | -8.185e-01 |
| 0.083 | s2_aaa_mle | 5.38e+00 | 1 | 1 | 1.389e+00 | 6.310e+01 | 12/12 | +2.161e-01 | +1.486e+00 | +1.823e-01 | +1.307e+00 |
| 0.333 | aaad_gpr | 8.76e-02 | 1 | 1 | 4.614e-02 | 2.897e+01 | 12/12 | -2.137e-02 | -2.166e-02 | -1.864e-02 | -1.887e-02 |
| 0.333 | agp_robust | 8.76e-02 | 1 | 1 | 4.614e-02 | 2.897e+01 | 12/12 | -2.137e-02 | -2.166e-02 | -1.864e-02 | -1.887e-02 |
| 0.333 | agp_robust_se_times_rq | 8.99e-02 | 1 | 1 | 4.596e-02 | 2.897e+01 | 12/12 | -2.182e-02 | -2.210e-02 | -1.903e-02 | -1.926e-02 |
| 0.333 | chebyshev_bic | 1.15e-01 | 1 | 1 | 5.235e-02 | 2.897e+01 | 12/12 | -3.189e-02 | -3.206e-02 | -2.896e-02 | -2.909e-02 |
| 0.333 | s2_aaa_mle | 4.33e+00 | 1 | 1 | 1.073e+00 | 2.897e+01 | 12/12 | +2.025e-01 | +4.875e-01 | +1.706e-01 | +4.191e-01 |
| 1.083 | aaad_gpr | 5.38e-02 | 1 | 1 | 1.550e-02 | 2.483e+01 | 12/12 | +5.494e-04 | +5.501e-04 | +9.400e-04 | +9.409e-04 |
| 1.083 | agp_robust | 5.38e-02 | 1 | 1 | 1.550e-02 | 2.483e+01 | 12/12 | +5.494e-04 | +5.501e-04 | +9.400e-04 | +9.409e-04 |
| 1.083 | agp_robust_se_times_rq | 5.25e-02 | 1 | 1 | 1.507e-02 | 2.483e+01 | 12/12 | +6.710e-04 | +6.713e-04 | +1.037e-03 | +1.038e-03 |
| 1.083 | chebyshev_bic | 8.98e-02 | 1 | 1 | 2.505e-02 | 2.483e+01 | 12/12 | -7.613e-03 | -7.573e-03 | -4.400e-03 | -4.374e-03 |
| 1.083 | s2_aaa_mle | 2.73e+00 | 1 | 1 | 8.519e-01 | 2.483e+01 | 12/12 | -3.027e-01 | -2.535e-01 | -2.089e-01 | -1.867e-01 |
| 2.787 | aaad_gpr | 1.92e-02 | 1 | 1 | 2.034e-02 | 5.003e+01 | 12/12 | +1.864e-02 | +1.850e-02 | +6.639e-03 | +6.597e-03 |
| 2.787 | agp_robust | 1.92e-02 | 1 | 1 | 2.034e-02 | 5.003e+01 | 12/12 | +1.864e-02 | +1.850e-02 | +6.639e-03 | +6.597e-03 |
| 2.787 | agp_robust_se_times_rq | 1.91e-02 | 1 | 1 | 2.014e-02 | 5.003e+01 | 12/12 | +1.838e-02 | +1.825e-02 | +6.568e-03 | +6.528e-03 |
| 2.787 | chebyshev_bic | 2.11e-02 | 1 | 1 | 3.223e-02 | 5.003e+01 | 12/12 | +1.743e-02 | +1.724e-02 | +6.160e-03 | +6.105e-03 |
| 2.787 | s2_aaa_mle | 5.50e-01 | 1 | 1 | 7.572e-01 | 5.003e+01 | 12/12 | -1.438e-01 | -1.597e-01 | -6.604e-02 | -6.715e-02 |
| 5.000 | aaad_gpr | 5.66e-02 | 1 | 1 | 2.081e-01 | 7.096e+01 | 12/12 | -2.012e-01 | -2.048e-01 | -3.395e-02 | -3.459e-02 |
| 5.000 | agp_robust | 5.66e-02 | 1 | 1 | 2.081e-01 | 7.096e+01 | 12/12 | -2.012e-01 | -2.048e-01 | -3.395e-02 | -3.459e-02 |
| 5.000 | agp_robust_se_times_rq | 5.29e-02 | 1 | 1 | 1.936e-01 | 7.096e+01 | 12/12 | -1.880e-01 | -1.909e-01 | -3.174e-02 | -3.227e-02 |
| 5.000 | chebyshev_bic | 2.38e+00 | 1 | 1 | 2.122e+00 | 7.096e+01 | 12/12 | +4.693e-01 | +6.557e-01 | +7.797e-02 | +1.088e-01 |
| 5.000 | s2_aaa_mle | 1.14e+00 | 1 | 1 | 3.612e+00 | 7.096e+01 | 12/12 | -2.334e+00 | -2.542e+00 | -4.497e-01 | -5.360e-01 |

## Per-parameter statistics across all (SP, interp) combos

**alpha** (truth = 0.1030, n=25 combos):
- mean Δ = -0.0764 → mean estimate = 0.0266 (rel 7.41e-01)
- median Δ = -0.0186 → median estimate = 0.0844 (rel 1.81e-01)
- min |Δ| = 0.0009 at estimate = 0.1039 (rel 9.13e-03)
- max |Δ| = 0.8902 at estimate = -0.7872 (rel 8.64e+00)
- std Δ = 0.2118
- IFT prediction quality: median |pred/actual - 1| = 1.65e-02

**beta** (truth = 0.2430, n=25 combos):
- mean Δ = -0.1658 → mean estimate = 0.0772 (rel 6.82e-01)
- median Δ = -0.0214 → median estimate = 0.2216 (rel 8.80e-02)
- min |Δ| = 0.0005 at estimate = 0.2435 (rel 2.26e-03)
- max |Δ| = 2.3336 at estimate = -2.0906 (rel 9.60e+00)
- std Δ = 0.5175
- IFT prediction quality: median |pred/actual - 1| = 1.57e-02

**delta** (truth = 0.5900, n=25 combos):
- mean Δ = -0.0643 → mean estimate = 0.5257 (rel 1.09e-01)
- median Δ = -0.0028 → median estimate = 0.5872 (rel 4.67e-03)
- min |Δ| = 0.0023 at estimate = 0.5877 (rel 3.83e-03)
- max |Δ| = 2.6417 at estimate = 3.2317 (rel 4.48e+00)
- std Δ = 0.7294
- IFT prediction quality: median |pred/actual - 1| = 9.40e-03

**gamma** (truth = 0.1650, n=25 combos):
- mean Δ = -0.0089 → mean estimate = 0.1561 (rel 5.41e-02)
- median Δ = -0.0010 → median estimate = 0.1640 (rel 6.06e-03)
- min |Δ| = 0.0009 at estimate = 0.1641 (rel 5.58e-03)
- max |Δ| = 0.5198 at estimate = 0.6848 (rel 3.15e+00)
- std Δ = 0.1410
- IFT prediction quality: median |pred/actual - 1| = 9.46e-03

## Per-interpolator: aggregated across SPs

| interp | n_combos | mean β err | median β err | mean α err | best dist→truth | mean cond(J) |
|---|---:|---:|---:|---:|---:|---:|
| aaad_gpr | 5 | 0.0906 | 0.0214 | 0.0496 | 0.0155 | 4.76e+01 |
| chebyshev_bic | 5 | 0.3048 | 0.0319 | 0.2015 | 0.0250 | 4.76e+01 |
| s2_aaa_mle | 5 | 0.6397 | 0.2161 | 0.2155 | 0.7572 | 4.76e+01 |

## Per-SP: aggregated across interpolators

| SP | n_combos | best interp | best dist→truth | best β err | mean β err |
|---:|---:|---|---:|---:|---:|
| 0.083 | 5 | aaad_gpr | 0.3397 | 0.2112 | 0.3697 |
| 0.333 | 5 | agp_robust_se_times_rq | 0.0460 | 0.0214 | 0.0598 |
| 1.083 | 5 | agp_robust_se_times_rq | 0.0151 | 0.0005 | 0.0624 |
| 2.787 | 5 | agp_robust_se_times_rq | 0.0201 | 0.0174 | 0.0434 |
| 5.000 | 5 | agp_robust_se_times_rq | 0.1936 | 0.1880 | 0.6787 |
