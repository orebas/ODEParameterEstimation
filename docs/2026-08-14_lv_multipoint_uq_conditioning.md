# Audited LV multipoint UQ: conditioning tunnel-through

This note follows the exact `lotka_volterra_5_1em6` canary in
[`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md).
It asks what happens when we retain the covariance even though the raw
algebraic Jacobian condition exceeds the production reliability threshold.

The experiment changes no production threshold. The `:degenerate` report
already contains the covariance for audit; the diagnostic script merely keeps
the selected multipoint artifact in memory and inspects it.

## Cell and selected estimator

- Frozen audited PEB cell: `lotka_volterra_5_1em6`, all 750 observations.
- Additive observation noise: design sigma `1.50333e-7` in original units;
  realized sample sigma `1.46273e-7`.
- Selected estimator: exact AGP-UQ multipoint algebraic root, rows `[25, 635]`,
  times `[0.6408545, 16.9292390]`.
- Maximum physical-coordinate error: `3.26565e-4`.
- Relative root residual: `6.38e-18`.

## The raw condition number is not an arithmetic failure

The production diagnostic reports `cond2(Jx) = 2.8164e7`. That number is
strongly coordinate dependent because this square polynomial system contains
state jets through order five. The selected root includes coordinates as large
as `r_5 = 1.686e3` and as small as `w_4_pt2 = 1.568e-3`.

| Jacobian coordinates | condition number |
|---|---:|
| raw | `2.8164e7` |
| row equilibrated | `3.0648e5` |
| column equilibrated | `1.6241e4` |
| row + column equilibrated | `1.0871e2` |
| relative-coordinate + row equilibrated | `1.4294e3` |

The factorized production solve is stable on this instance:

- Float64 LU sensitivity versus a 256-bit solve: `1.06e-14` relative difference;
- SVD sensitivity versus the 256-bit solve: `2.41e-12`;
- LU equation residual: `1.05e-13` relative;
- `cond(Jx) * eps(Float64) = 6.25e-9`.

The weakest raw singular direction is dominated by the fifth-order `r` jet.
After relative-coordinate and row scaling, the weak direction is dominated by
the small `w` jet chain at the second shooting point. Physical LV parameters
have only small loadings. Thus the raw `1e6` gate is conservative and
scale-sensitive here; it does not demonstrate that the IFT calculation lost
meaningful Float64 digits.

## What the forced covariance says

The report remains `:degenerate`, but its covariance gives these one-cell
diagnostics:

| coordinate | estimate | truth | sigma | z | nominal 95% contains truth? |
|---|---:|---:|---:|---:|---|
| `k1` | `0.210026498` | `0.210` | `5.075e-5` | `0.52` | yes |
| `k2` | `0.777850200` | `0.778` | `3.461e-5` | `-4.33` | no |
| `k3` | `0.687874671` | `0.688` | `3.830e-5` | `-3.27` | no |
| `r(0)` | `0.722033076` | `0.722` | `2.459e-6` | `13.45` | no |
| `w(0)` | `0.879287050` | `0.879` | `9.533e-5` | `3.01` | no |

This is one realization, not a coverage rate. It nevertheless shows that
simply removing the conditioning status would produce misleadingly reassuring
intervals for this cell.

The variational backsolve is not badly conditioned: its spectral amplification
is `3.88` and its condition number is `9.95`. It expands the local `r` standard
deviation substantially through parameter/state coupling, but the parameter
misses are already present before the backsolve.

## The dominant mechanism is GP-jet smoothing bias

ODEPE's default covariance for this estimator propagates repeated-observation
sampling variance through a fixed-hyperparameter GP smoother and the exact
selected-root IFT. It does not include the smoother's deterministic derivative
bias.

The internal power-of-two observable scale for this cell is `0.125`
(`original = scale * internal`). In matched internal units:

- benchmark design noise sigma: `1.20266e-6`;
- realized sample sigma: `1.17019e-6`;
- GP-learned sigma: `1.21141e-6`, only `0.73%` above design;
- residual/EDF sigma: `1.51836e-6`, `26.3%` above design.

Noise-scale estimation is therefore not the cause. Replacing the learned sigma
with the known design sigma leaves the failed coordinates essentially
unchanged; the more conservative residual/EDF source still contains only `k1`.

At the first selected point, the retained fixed-hyperparameter GP jet errors
are dominated by noiseless smoother bias:

| derivative | total error / sampling sigma | smoother-bias contribution | noise-draw contribution |
|---|---:|---:|---:|
| order 0 | `-9.96` | `-9.56 sigma` | `-0.40 sigma` |
| order 1 | `9.24` | `9.61 sigma` | `-0.37 sigma` |
| order 2 | `21.74` | `22.48 sigma` | `-0.75 sigma` |
| order 3 | `-20.59` | `-20.60 sigma` | `0.01 sigma` |

At the second point, smoother bias is small and the observed jet errors are
mostly ordinary noise-draw effects (`0.35`, `-2.13`, `0.41`, and `1.26` total
standard deviations for orders zero through three).

Most decisively, applying the exact selected-root IFT to the signed GP-jet bias
predicts the full retained algebraic root error with `3.06e-4` relative
disagreement. The nonlinear map is behaving almost perfectly linearly on this
perturbation. The problem is the center of the jet estimator, not failed IFT
arithmetic or nonlinear remainder.

## Interpretation and next decisions

There is no contradiction between excellent estimation and poor UQ here.
Errors around `1e-4` are excellent point recovery, while the observation noise
is so low that the fixed-GP sampling covariance implies much smaller standard
errors. A small interpolation-bias floor is therefore several to tens of
nominal sigmas. The algebraic inverse transfers that bias into parameters and
initial conditions accurately.

For now:

1. Keep the production `:degenerate` outcome. Its caution is warranted even
   though the raw-condition explanation is incomplete.
2. Do not interpret `2.8e7` alone as a failed inverse-Jacobian calculation.
   Future numerical gates should consider equilibrated conditioning and
   backward error, not only raw `cond2`.
3. Do not fix this by increasing the observation-noise estimate: the matched
   learned noise is already correct, and residual/EDF inflation is insufficient.
4. The next LV experiment should compare candidate point pairs for GP-jet bias
   and then run repeated-noise, fixed-pair coverage. That separates point
   selection and smoother bias from candidate-selection variability.

## Reproduce

Full selected-root audit:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl
```

Fast fixed-GP jet-bias decomposition only:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl --gp-only
```
