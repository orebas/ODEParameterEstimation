# Audited Lotka--Volterra multipoint bias results

Date: 2026-08-16

Status: Stages 1--3 of the estimation/UQ research program are complete for the
frozen `lotka_volterra_5_1em6` discovery cell. These are deterministic
mechanism results and two matched one-draw production canaries. They do not
certify repeated-sampling coverage or justify changing a default.

The cell comes from the SHA-pinned paper benchmark, not the package's known-
flaky model registry. It has 750 observations, noise level `1e-6`, and a
historically excellent unpolished multipoint estimate.

## Executive result

The default estimator is genuinely good. Its selected rows are `[25, 635]`,
its worst relative parameter error is `1.02e-4` (0.0102%), and its exact IFT
solve is numerically trustworthy despite a raw Jacobian condition number of
`2.82e7`. Row-and-column equilibration reduces that diagnostic condition
number to `109`, and the Float64 sensitivity agrees with a 256-bit solve to
`3.4e-14` relative.

The remaining problem is statistical rather than a failed linear solve. The
fixed GP smoother has signed derivative bias, and after variational
physicalization the default report misses the initial state `r` at `2.57`
standard errors. Shortening the fixed SE lengthscale strongly reduces this
projected smoother bias, but widens intervals and changes adaptive pair/root
selection. The result is promising research evidence, not a Pareto
improvement.

## Numerical-consistency repair

Production estimation used to hide every interpolator behind an anonymous
closure before calling `nth_deriv`. For `AGPInterpolatorUQ`, that defeated its
analytic SE derivative dispatch even though estimator-aware UQ propagates the
corresponding analytic fixed-smoother influence matrix.

The estimation paths now call `_estimation_derivative`. Its generic method is
the historical TaylorDiff-through-callable route, while AGPUQ specializes it
to the existing analytic derivative. Thus ordinary estimator interpolators do
not change. On this LV cell the selected estimator lineage remains candidate
68 at rows `[25, 635]`.

The retained base factorization required no jitter and reconstructed its
advertised matrix to `1.09e-15` relative. Directly multiplying high-order raw
influence weights by raw observations is cancellation-prone, so deterministic
noiseless GP means in the diagnostic use the equivalent centered,
normalized-alpha evaluation. The influence matrix is still used for
covariance.

## Stage 1: production-pair mechanism map

The first pass inspected only the 15 pairs selected by each bounded strategy.
`max |bias z|` is the actual oracle-branch root displacement caused by the
fixed noiseless smoother, standardized by the exact fixed-smoother covariance.
`max |total z|` additionally includes this frozen data set's realized noise.

| Rows | Both local roots | max \|bias z\| | max \|total z\| | Worst relative parameter error | equilibrated cond2 |
|---|---:|---:|---:|---:|---:|
| `[25,635]` | yes | 0.854 | 0.905 | 0.0102% | 109 |
| `[8,635]` | yes | 0.519 | 0.853 | 0.0291% | 265 |
| `[36,635]` | yes | 6.52 | 5.84 | 0.0488% | 227 |
| `[16,635]` | yes | 6.58 | 6.59 | 0.0726% | 54.7 |
| `[1,635]` | yes | 14.5 | 16.4 | 16.2% | 47.3 |

The historical `:spread` top 15 therefore already contain accurate,
low-projected-bias branches. Expanding the homotopy sweep to all 190 pairs
cannot change the current decision and was not authorized.

The experimental `:boundary_order` ranking fails its gate. Only 8 of its 15
pairs reached both local roots; the best standardized total displacement was
still `2.64`, with 3.9% parameter error. Boundary distance alone removes the
worst endpoints but does not identify the accurate basin, so this strategy
must remain research-only.

## Stage 2: point-count frontier

| Points | Max observed derivative order | Solve variables | Data variables | Mixed volume | Construction time |
|---:|---:|---:|---:|---:|---:|
| 1 | 4 | 14 | 5 | not computed | 0.345 s |
| 2 | 3 | 25 | 8 | 3 | 0.848 s with MV |
| 3 | 2 | 36 | 9 | 3 | 6.63 s with MV |
| 4 | 2 | 47 | 12 | not computed | 9.92 s |

Three points pass the structural gate: they lower the maximum observed-jet
order from 3 to 2 with the same mixed volume. Four points add eleven solve
variables without lowering the derivative order again and were dropped.

Local fixed-combination screening is less favorable. Of six controlled
triples, only `[80,267,635]` and `[25,267,635]` reached both the noiseless-bias
and noisy local roots. The latter preserves the good selected pair and adds a
low-instability interior point. It has max physical total `|z| = 0.306` and
0.0187% worst parameter error, but coordinate standard errors are about
1.2--190 times the two-point values depending on coordinate. Its raw
condition number is `5.71e9`, yet equilibration gives `644` and Float64 agrees
with 256-bit arithmetic to `1.1e-15` relative. This is a centered but much less
precise robust arm, not a default candidate.

## Stage 3: fixed-recipe lengthscale mechanism screen

Rows `[25,635]`, the k=2 polynomial template, signal/noise variances, and the
oracle-seeded local branch were fixed. Only `ell / ell_ML` changed.

| `ell / ell_ML` | Both roots | max physical \|bias z\| | max physical \|total z\| | SE inflation vs 1.0 | Worst parameter error |
|---:|---:|---:|---:|---:|---:|
| 1.00 | yes | 3.29 | 2.56 | 1.00x | 0.0102% |
| 0.90 | yes | 2.84 | 2.83 | 1.25--1.29x | 0.0477% |
| 0.75 | yes | 0.250 | 1.59 | 2.02--2.15x | 0.0906% |
| 0.60 | yes | 0.0673 | 0.413 | 3.49--4.00x | 0.0407% |

The `0.75--0.6` region is a real bias-reduction lead: the signed noiseless
smoother displacement collapses coherently across parameters and states. It
also makes intervals wider, and none of the non-default arms improves this
draw's already excellent point estimate. Truth was used to diagnose this
region, so selecting `0.6` from this table and calling the same cell a coverage
validation would be circular.

## Matched adaptive production canaries

The two full production calls used identical frozen data and options except
for the lengthscale factor.

| Factor | Selected candidate/rows | Worst coordinate error | max \|z\| | Structured time | Wall time |
|---:|---|---:|---:|---:|---:|
| 1.0 | 68 / `[25,635]` | 0.0102% | 2.57 (`r`) | 68.50 s | 106.47 s |
| 0.6 | 62 / `[8,635]` | 0.0455% | 0.772 | 70.46 s | 108.54 s |

The opt-in arm costs only 2.9% more structured time in this matched pair, but
it changes the selected estimator. Its standard errors cannot be interpreted
as a simple widening of the default intervals: four coordinates widen while
the `r` interval narrows because the selected shooting geometry changes. Both
runs return available reports whose numerical-linearization axis is degraded
by the conservative raw-condition gate. A single draw cannot establish that
the 0.6 arm is calibrated.

The adaptive run also exposed a campaign-sidecar bug: completed timing payloads
can contain `nothing`, which TOML cannot encode. Atomic writing now maps such
optional values to the explicit string sentinel `__missing__`; the failed
write left no partial result, and the rerun completed.

## Decisions and next gate

- Keep the default estimator and `:spread` policy unchanged.
- Reject `:boundary_order` as a promotion candidate on this evidence.
- Keep k=3 as an opt-in structural research branch; do not spend an N=60
  campaign until production branch feasibility and its very wide intervals
  are understood.
- Treat fixed lengthscale factors 0.75 and 0.6 as discovery candidates only.
  Test them on a held-out audited panel where unpolished estimation is already
  known to be excellent (slow-fast SP, receptor-binding MP, and one of
  daisy_mamil4/biohydrogenation).
- Predeclare a fixed factor or an oracle-free stability rule before repeated-
  noise validation. Then run N=10 plumbing/failure screens followed by paired
  N=60 fixed-recipe coverage. Adaptive-selection N=200 comes only after that.

Exact atomic records and reproduction commands live under
`repro/uq_coverage_harness_2026_08/results/` and its README.
