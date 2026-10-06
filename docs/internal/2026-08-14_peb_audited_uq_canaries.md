# Audited PEB estimator/UQ canaries — 2026-08-14

Start here for the current LV/Van der Pol/FitzHugh–Nagumo result. The earlier
[`simple nonlinear estimator pilot`](2026-08-14_simple_nonlinear_estimator_pilot.md)
used package example constructors whose equations, constants, and time windows
are not the audited paper fixtures. It remains useful as routing stress, but it
is not evidence about those models' benchmark performance.

## Scope and source boundary

This is deliberately not a benchmark sweep. Five individual cells were mined
from the frozen paper benchmark because the saved result was accurate and its
metadata recorded a useful estimator route. The canary driver copies the exact
frozen equations, parameters, initial conditions, time window, and noisy data,
and validates the generator, data, and metadata files by SHA-256 before a run:

- PEB snapshot: `benchmark_final_v2_2026-06-12`
- frozen PEB commit: `c94e0a3eb5bbd8ab95c73e30f203cbad73485d7b`
- ODEPE commit used by the frozen run:
  `96721a334d94ec20d219c5b921a81fa20980e824`
- observations per exact cell: 750
- current driver:
  `repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl`

The package FHN constructor's `[0, 0.03]` window is stale relative to the
audited benchmark. PEB changed that window to `[0, 1]` in commit `936b78ffc`
on 2026-03-11 and uses scaled equations. The ad hoc `[0, 3]` screen in the old
pilot must not be read as a benchmark correction.

The driver's default is now all 750 observations. An explicit reduced row
count is only a speed smoke: reducing the audited FHN cell to 121 evenly spaced
rows changed the selected basin and worsened maximum coordinate error from
`0.00230` to `0.435`. That is a different estimation problem, not a faithful
canary.

## Suite A: reproduce selected full-trajectory estimators

These three `1e-4` cells use the historical winning interpolator plus AGP-UQ,
20 shooting anchors, 15 pairs, and full-trajectory polish. Current error is
compared with the frozen paper result from the same model and data.

| audited cell | current max error | frozen max error | selected estimator and current seed | UQ outcome |
|---|---:|---:|---|---|
| `lotka_volterra_2_1em4` | `1.51382e-5` | `1.51371e-5` | trajectory polish ← SP AGP-UQ, row 453 | `:ok`, exact target |
| `vanderpol_2_1em4` | `1.52407e-6` | `1.52407e-6` | trajectory polish ← SP AAAD-GPR, row 267 | `:ok`, exact target |
| `fitzhugh_nagumo_1_1em4` | `0.00229787` | `0.00229601` | trajectory polish ← SP AGP-RQ, row 453 | unavailable: weak observed-Hessian curvature |

LV and Van der Pol reproduce the frozen errors essentially digit for digit.
Their UQ reports target the returned trajectory-polish rows, with condition
numbers `2.23e4` and `1.61e3`, respectively. FHN also reproduces the frozen
estimate, but covariance is refused because minimum observed-Hessian curvature
is `1.963e-6`, below the required `3.892e-5`. That is an honest reliability
gate, not an estimation failure.

The frozen LV and FHN metadata named multipoint algebraic parents, whereas the
current rank-one polished duplicates descend from single-point parents. This is
not a contradiction: several algebraic seeds converge to numerically the same
full-trajectory optimum, and tiny score/clustering differences decide which
duplicate retains rank one. The public estimator is `trajectory_polish`; seed
type and points remain lineage, and should not be promoted to a claim that MP
was necessary for these two polished cells.

## Suite B: exact multipoint provenance and UQ

To exercise multipoint as the selected estimator rather than merely a polish
seed, two accurate frozen no-trajectory-polish cells were chosen at `1e-6`.
The current canary uses only AGP-UQ, permits local algebraic-root polishing, and
does not run full-trajectory polish.

| audited cell | selected MP rows (times) | max error | artifact | report status | algebraic Jacobian condition |
|---|---|---:|---|---|---:|
| `lotka_volterra_5_1em6` | `[25, 635]` (`[0.64085, 16.92924]`) | `3.26565e-4` | exact | `:degenerate` | `2.816e7` |
| `fitzhugh_nagumo_9_1em6` | `[80, 750]` (`[0.10547, 1.0]`) | `0.0333533` | exact | `:degenerate` | `3.955e6` |

Both returned rows are genuinely `multipoint_algebraic`. UQ used the retained
unprojected root, exact two-point system, exact AGP-UQ interpolants, and the
same selected point set. Root residuals are `5.16e-14` and `4.43e-14`.

Both reports are nevertheless marked `:degenerate` because the linearization
conditioning gate is degraded. Their reported maximum CVs (`2.42e-4` for LV,
`0.0427` for FHN) do not override that gate. The covariance is useful for
debugging, but is not a calibration claim.

A subsequent LV tunnel-through separates the warning from its mechanism. The
raw `2.816e7` condition falls to `109` after row/column equilibration, and the
Float64 IFT solve agrees with a 256-bit solve to `1.1e-14`; the inverse itself
is numerically stable. The forced intervals still contain truth for only one of
five coordinates because the first selected point's GP jets have roughly
`10`--`22` sampling-sigma of deterministic smoother bias. The IFT predicts the
resulting root error with `3.1e-4` relative disagreement. Thus the cautionary
status is right for this cell, but raw conditioning is not the demonstrated
failure mechanism. See
[`Audited LV multipoint UQ: conditioning tunnel-through`](2026-08-14_lv_multipoint_uq_conditioning.md).

When the historical S3 interpolator is allowed to win these algebraic cells,
UQ returns typed `unsupported_interpolator`; exact algebraic covariance is only
implemented for a winning AGP-UQ artifact. Enabling UQ does not silently change
the estimator pool.

## What this changes

- The apparent across-the-board LV/VDP/FHN failure from package constructors is
  not a sound model conclusion. Exact audited cells estimate well.
- Full-trajectory polish is the selected estimator in the three paper-level
  reproduction cells. UQ correctly follows that estimator, not an independently
  chosen algebraic row.
- Exact multipoint identity, source rows/times, artifact matching, and UQ routing
  work end to end on audited data.
- The remaining nonlinear UQ problem is numerical/statistical reliability:
  weak optimizer curvature for FHN polish, scale-sensitive raw algebraic
  conditioning gates, and (in the audited LV MP cell) a GP derivative-bias
  floor that the fixed-hyperparameter sampling covariance does not include.
  Lower noise can make that bias more visible in standardized units.
- These are single-cell canaries, not coverage studies. The N=60 single-point
  result remains the only calibrated campaign; nonlinear MP/polish coverage is
  still open.

## Reproduce

Exact selected-estimator reproduction (the driver default):

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl \
  --out=peb_audited_canaries
```

Exact multipoint-algebraic/UQ route:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl \
  --cases=lotka_volterra_5_1em6,fitzhugh_nagumo_9_1em6 \
  --arms=mp_solver_polish --interpolator-pool=uq_only \
  --out=peb_audited_canaries
```

The raw records from this session are under
`repro/uq_coverage_harness_2026_08/results/peb_audited_canaries_20260814/`.
Each TOML file contains the selected identity, full lineage, candidate fit and
oracle diagnostics, exact source rows/times, coordinate errors, and UQ gates.

## Reading order

1. This note for what was actually run and what it establishes.
2. [`Estimator-aware UQ contract`](2026-08-14_estimator_aware_uq.md) for the
   production estimand, identity/artifact lifecycle, supported routes, and
   typed failure policy.
3. [`UQ session recap`](2026-08-14_uq_session_recap.md) §5 for the N=60
   single-point calibration evidence and remaining statistical leads.
4. The [`package-constructor pilot`](2026-08-14_simple_nonlinear_estimator_pilot.md)
   only as historical routing stress, not as audited model evidence.
