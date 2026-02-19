# Pole Deflation Prototype Results — 2026-02-19

## What Was Tested

Three strategies for removing spurious pole contributions from AAAD boundary derivatives,
plus Fornberg FD and FHD5 as baselines. All evaluated on ERK model with 2001 data points.

Script: `pole_deflation_test.jl`

## Strategies

**(a) Deflate nearest**: Subtract the single closest dangerous near-real pole from the
rational interpolant, then re-differentiate with TaylorDiff.

**(b) Deflate all dangerous**: Subtract ALL near-real poles within a danger radius,
then re-differentiate.

**(c) Analytical correction**: Don't re-differentiate. Compute raw TaylorDiff derivative,
then subtract the analytically known pole derivative contribution:
`correction = Σ (-1)^n * n! * R / (t - p)^(n+1)` for each dangerous pole.

## Results at t=0 (left boundary — the catastrophic case)

### S0'(0) (true: -37.375)

| Method | d0 (value) | d1 (deriv) | d0 error | d1 error |
|--------|-----------|-----------|----------|----------|
| Ground truth | 5.000000 | -37.375000 | — | — |
| AAAD raw | 5.000000 | -504,988 | 0.0% | 13,510× |
| FHD5 | 5.000000 | -23.234 | 0.0% | 37.85% |
| Deflate nearest (r=0.1) | 5.000000 | -504,988 | 0.0% | 13,510× |
| Deflate nearest (r=1.0) | 4.904 | -1.577 | 1.92% | 95.78% |
| Deflate nearest (r=5.0) | 4.904 | -1.577 | 1.92% | 95.78% |
| All dangerous (r=1.0, n=3) | 4.906 | -1.577 | 1.88% | 95.78% |
| All dangerous (r=5.0, n=5) | 4.952 | -1.487 | 0.96% | 96.02% |
| Analytic corr (r=1.0, n=3) | 4.906 | -1.577 | 1.88% | 95.78% |
| Analytic corr (r=5.0, n=5) | 4.952 | -1.487 | 0.96% | 96.02% |
| Fornberg 30pt | 5.000000 | -33.731 | 0.0% | 9.75% |
| **Fornberg 50pt** | **5.000000** | **-36.317** | **0.0%** | **2.83%** |

### S1'(0) (true: 0.0)

| Method | d1 (deriv) | d1 abs error |
|--------|-----------|-------------|
| AAAD raw | 10.07 | 10.07 |
| FHD5 | -0.0284 | 0.0284 |
| Deflate nearest (r=1.0) | -0.1039 | 0.1039 |
| Fornberg 50pt | -0.0001 | 0.0001 |

### S2'(0) (true: 0.0)

| Method | d1 (deriv) | d1 abs error |
|--------|-----------|-------------|
| AAAD raw | -4,858 | 4,858 |
| FHD5 | -0.1265 | 0.1265 |
| Deflate nearest (r=1.0) | -1.0306 | 1.0306 |
| Fornberg 50pt | -0.0006 | 0.0006 |

### Results at t=10 and t=20

All methods agree at interior points. At t=20, no methods have issues (no nearby poles).

## Key Findings

1. **Deflation reduces absolute error by 14,000×** (from 505K to ~36) but still leaves
   95.8% relative error. The remaining error after pole subtraction comes from the
   "smooth part" of the rational function being wrong near the boundary.

2. **Strategies (b) and (c) are mathematically equivalent** — both give -1.577.
   This confirms the analytical correction is correct.

3. **Deflation introduces d0 error** — the function VALUE changes by 1-2% after
   pole subtraction. This is because the poles, while spurious for derivatives,
   do contribute to function accuracy.

4. **d2 (2nd derivatives) remain terrible** — 3.9M after deflation vs 5.5e12 raw.
   The smooth part of the rational function has the wrong curvature.

5. **FHD5 is better than deflation** — 38% d1 error vs 96%. Being pole-free
   inherently avoids the problem.

6. **Fornberg 50pt FD is the winner** — 2.8% d1 error using raw data directly.
   No interpolation artifacts.

7. **The r=0.1 deflation does nothing** for S0 because the nearest pole (-1.9e-7)
   is at distance 1.9e-7, but the AAAD support point at t=0 is closer. The classification
   finds no dangerous poles within r=0.1.

## Implications for ODEPE

Pole deflation alone is insufficient for fixing the ERK re-solve. The 95.8% residual
error in S0'(0) would still create an inconsistent algebraic system (the C2_0
overdetermination needs accuracy better than ~50% to produce real solutions).

**Fornberg FD is the most promising** — 2.8% error could be sufficient, especially if
the re-solve system is only mildly overdetermined for C2_0. Implementation would be:
- Detect boundary shooting points (t at first/last data point)
- Use Fornberg 50-point stencil for derivatives instead of `nth_deriv(interp, ...)`
- Only a ~20-line code change in `si_template_integration.jl`
