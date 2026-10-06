# Simple nonlinear estimator/UQ pilot — 2026-08-14

> **Superseded for model-quality conclusions.** This pilot used package example
> constructors with known legacy discrepancies, not the audited paper
> benchmark fixtures. Start with
> [`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md),
> where exact frozen LV/VDP/FHN cells estimate well. This note remains a useful
> routing stress record only.

This note records the first production-path comparison after estimator-aware
UQ was wired to the selected rank-one result. It is a routing and accuracy
pilot, not an empirical calibration claim: each cell has only five matched
noise draws.

## Design

- Models: Lotka–Volterra (LV), Van der Pol (VDP), and FitzHugh–Nagumo (FHN).
- Additive noise: `1e-4` and `1e-5`; 121 observations; five deterministic
  model-specific seeds per cell.
- Default windows for LV (`[0, 20]`) and VDP (`[0, 10]`). The nominal FHN
  window `[0, 0.03]` is nearly static (`V` moves only about 0.06), so a window
  screen was run first and the matched campaign uses `[0, 3]`.
- Every arm sees the identical noisy data for a `(model, noise, replicate)`.
- `sp`: the legacy one-shooting-point pool, without final polish.
- `mp`: six shooting anchors plus at most six two-point algebraic systems,
  without final polish. This arm can still select one of the additional
  single-point candidates when its trajectory SSE wins.
- `mp_polish`: the same expanded pool plus retained full-trajectory residual
  polish. UQ targets that polished estimator, while its lineage records the
  algebraic seed and exact selected point(s).
- Branch completion, aggregate synthesis, and terminal fallback were disabled
  to isolate these routes.

The checkpointed driver is
`repro/uq_coverage_harness_2026_08/run_estimator_aware_nonlinear.jl`; the
summarizer is `summarize_estimator_aware_nonlinear.jl`. Each completed cell is
an atomic TOML file containing the selected estimator identity, exact points,
lineage, all candidate fit/oracle errors, and the selected estimator's UQ
outcome.

## Accuracy result

Values below are median and maximum, across five draws, of the worst scaled
coordinate error in each returned estimate. Percentages are for readability;
near-zero truth coordinates use the package's absolute-error convention.

| model / noise | single point | expanded SP+MP pool | expanded pool + trajectory polish |
|---|---:|---:|---:|
| LV, `1e-4` | 0/5 estimates | 5.51% median, 7.51% max | **0.0103% median, 0.0113% max** |
| LV, `1e-5` | 1/5 estimates; that draw 32.3% | 0.797% median, 1.30% max | **0.00103% median, 0.00113% max** |
| VDP, `1e-4` | 230% median, 934% max | 1.90% median, 4.39% max | **0.00554% median, 0.00937% max** |
| VDP, `1e-5` | 23.6% median, 44.5% max | 0.0614% median, 0.134% max | **0.000554% median, 0.000937% max** |
| FHN `[0,3]`, `1e-4` | 1,670% median, 3,310% max | 40.2% median, 62.6% max | **0.304% median, 2.66% max** |
| FHN `[0,3]`, `1e-5` | 4/5 estimates; 1,850% median, 4,030% max | 6.73% median, 10.4% max | **0.0304% median, 0.266% max** |

The tenfold noise reduction produces an approximately tenfold polished-error
reduction in all three systems. The residual single-point failures therefore
are not explained by noise alone.

## What “multipoint helped” means by model

### Lotka–Volterra

The expanded arm selected a genuine multipoint algebraic root in all ten
draws, consistently using times approximately `[0.8333, 10.5]`. The literal
single-point arm returned no estimate in nine of ten draws, and its lone
low-noise estimate had 32.3% worst-coordinate error. This is the cleanest case
where multipoint is structurally necessary for a usable algebraic seed.

Final trajectory polish is another two orders of magnitude better than the raw
multipoint root. Its winning seed lineage is not fixed: the `1e-4` winners
descended from three SP and two MP roots, while `1e-5` used one SP and four MP
roots. The public estimator is correctly identified as `trajectory_polish`;
the seed route remains auditable in its lineage.

### Van der Pol

The expanded pool helps decisively, but not always by selecting a multipoint
root. At `1e-4`, all five winners were single-point roots chosen from the six
available anchors rather than the legacy midpoint. At `1e-5`, two winners were
multipoint and three were single-point. Thus the important intervention is
multi-anchor candidate generation and trajectory scoring; hard-wiring “the
winner must be multipoint” would make this model worse.

Trajectory polish is extremely accurate in every draw. Its five winning seed
lineages split two MP / three SP at both noise levels.

### FitzHugh–Nagumo

On the package's nominal `[0, 0.03]` window, neither SP nor MP can identify the
latent-state/parameter block reliably. A one-draw window screen at `1e-4`
showed raw worst errors of roughly 100× at `T=0.3`, 0.77× at `T=1`, 0.35× at
`T=3`, and non-monotonic failure again by `T=10`. More time is necessary, but
arbitrarily more is not sufficient for the algebraic route.

At `T=3`, the expanded arm selected a genuine multipoint root in all ten
draws. Trajectory polish then changed median error from 40.2% to 0.304% at
`1e-4`, and from 6.73% to 0.0304% at `1e-5`. Seven of ten polished winners were
seeded by a multipoint root (four of five at `1e-4`, three of five at `1e-5`).

## UQ reading

- VDP trajectory UQ returned a report in all ten polished runs. All coordinates
  happened to lie within their nominal 95% intervals, with median absolute z
  values of roughly 0.2–1.3 depending on coordinate and noise.
- FHN trajectory UQ also returned a report in all ten polished runs and covered
  every coordinate in this small pilot. Several reports are marked
  `:degenerate` or `:wide_ci`, largely because CV is unstable for the near-zero
  initial `R`; the retained Hessian diagnostics themselves are separately
  recorded.
- Raw LV multipoint UQ passed numerical status gates, but the five-draw cells
  visibly under-cover several coordinates. `status=:ok` is a numerical/regime
  status, not an empirical calibration certificate.
- LV trajectory estimates exposed a deterministic score-diagnostic mismatch:
  five different draws all produced a finite-difference score norm near
  `0.00316` despite successful first-order LM convergence and different data.
  The UQ implementation now uses the same first-order AD Jacobian as production
  for the score and data influence, retaining finite differences only for the
  full observed Hessian. Across the ten corrected reruns, exact score norms are
  `1e-12`–`3.3e-9`, observed-Hessian condition is stable near `2.44e5`, and all
  ten reports have `status=:ok`. At `1e-5`, all five draws cover every
  coordinate; at `1e-4`, four coordinates cover 5/5 and `r` covers 4/5. This is
  encouraging small-N evidence, not a replacement for the N=60 campaign.

Five draws are enough to establish estimator routing and gross failure modes;
they are not enough to claim 95% coverage. Any publication-level nonlinear UQ
claim still needs an N=60 campaign for the selected polished estimator.

## Operational conclusion

The original surprise was justified: these are not three intrinsically broken
models. The old comparison mixed a one-point algebraic uncertainty estimand
with a different, much stronger reported estimator. The evidence here supports
the following production policy:

1. generate multiple anchors and multipoint candidates;
2. rank them by common trajectory SSE;
3. polish the best viable basins on the full trajectory;
4. report UQ for the selected estimator itself; and
5. retain exact seed type, points, and lineage without forcing the same seed
   class on every model.
