# Data-Driven Column Scaling — Implementation & Validation Conclusion

Date: 2026-05-27. Feature: `EstimationOptions.use_column_scaling::Bool = false` (off by default).
Scope of changes (solver layer only — `si_equation_builder.jl` / the rank-trim untouched):
- `src/types/estimation_options.jl` — new option field.
- `src/core/homotopy_continuation.jl` — `compute_column_scales` + `scale_hc_system` helpers, wired
  into `solve_with_hc_parameterized` (scale the variables once before the solve loop; unscale each
  returned solution).
- `src/core/optimized_multishot_estimation.jl` — thread `opts.use_column_scaling` into `solver_options`.

What it does: rescales each polynomial-jet unknown `x = D·x̂` using per-derivative-order observable
magnitudes (order-0 vars left at 1.0), solves the rescaled system (Newton polytopes / mixed_volume
unchanged), and unscales solutions. Tames the huge dynamic range of high-order jet coordinates that
defeats unscaled polyhedral path-tracking on stiff/transient systems.

---

## Goal 1 — Do no harm: SETTLED

- **Regression green, off-path is a byte-identical no-op.** `test/fast_core.jl` 313/313 and
  `test/feature_regressions.jl` 133/133 pass unchanged. When off, `col_scales = ones` ⇒ the unscale
  step is `1.0*x` and `scale_hc_system` is never called ⇒ zero added work, identical numerics.
- **Helper unit tests:** `test/column_scaling.jl` 12/12.
- **Benign AND inert on normal systems** (controlled, same data off vs on — `run_sweep_v3.jl`):

  | system | noise | best_max OFF | best_max ON |
  |---|---|---|---|
  | biohydrogenation | 1e-8 | 6.356e-1 | 6.356e-1 |
  | daisy_mamil4 | 1e-8 | 2.440e-1 | 2.440e-1 |
  | lotka_volterra | 1e-8 | 8.789e-5 | 8.789e-5 |

  Off == on to every digit, every rep. (The v2 apparent "8× bioh improvement under noise" was a
  noise-realization artifact — different data per run — and vanished once the data was held fixed.)
- **Wall-time:** zero when off; on ≈ off on normal systems (e.g. bioh noise=0: 391 vs 387 s) since
  mixed_volume is invariant; the only added cost is a one-time `subs` rebuild.

## The theory (why the results are what they are)

Column scaling is the change of variables `x = D·x̂` with `D` a **constant nonsingular diagonal**.
Two consequences, both observed:
- It changes `∂F/∂x̂ = (∂F/∂x)·D` — the conditioning the **path-tracker** sees — so it helps HC
  **reach roots it otherwise can't** (extreme-coordinate targets). → helps **fresh polyhedral solves**.
- It leaves `∂x/∂data` **invariant** (the `D`/`D⁻¹` cancel), and leaves the **fold/singular points of
  any homotopy path invariant** (same parameter values). → it **cannot** reduce noise amplification,
  and **cannot** fix parameter-homotopy tracking failures.

**Net: column scaling is a solver-*reach* aid, not a data-sensitivity fix.** This single fact explains
every result below.

## Goal 2 — Receptor as a benchmark system: ACHIEVED

`receptor_subtype_binding_branch` (M=2, a↔b swap) — the system whose 10⁷-span jet coordinates made the
pipeline fail. End-to-end through the production pipeline (`receptor_e2e.jl`, noise=0, 2 reps):

| `use_column_scaling` | truth recovered | swap recovered | best rel-err | n_cand | wall |
|---|---|---|---|---|---|
| **false** | **0/2** | **0/2** | 8.50e-2 | 192 | 3480 s |
| **true** | **2/2** | **2/2** | **4.08e-3** | 207 | 5340 s |

**With scaling, receptor recovers both M=2 branches at 0.4%; without it, neither.** Receptor graduates
from "pathological/failing" to a solvable M=2 benchmark case that showcases branch recovery.

### Mechanism (rigorously explained, not assumed)

`receptor_homotopy_diag.jl` seeded a full solution set at t=0 and tracked leftward into the blind
region, scaled vs unscaled, logging per-path return codes:

```
UNSCALED: fresh 16 (T+S) → track t=-0.1: 16→2 | terminated_max_steps=11, step_size_too_small=3, success=2 | T/S LOST
SCALED:   fresh 18 (T+S) → track t=-0.1: 18→2 | terminated_max_steps=12, step_size_too_small=4, success=2 | T/S LOST
```

- The homotopy **collapses via numerical tracking failure** (`terminated_*`, NOT `at_infinity`) — the
  paths die (step size → 0) as the parameter path approaches a fold near the blind region.
- **Scaling does not fix this** (collapses identically scaled vs unscaled) — exactly as the theory
  requires: column scaling can't move a homotopy path's folds.
- **The win comes from the fresh-fallback:** when the homotopy collapses, the pipeline re-solves fresh
  in the **scaled** system, which (per the standalone Exp K: 6/6 at t=-0.3) finds truth+swap where the
  unscaled fresh solve misses them. So scaling recovers receptor via *fresh-solve reach*, routed
  through the fallback — never by rescuing the homotopy.

## Default-ON verification (2026-05-27)

Flipped `use_column_scaling` default to `true` and re-ran the gates:
- **Regression with ON: 446/446** (fast_core 313 + feature 133) — unchanged from OFF.
- **Broad off-vs-on benchmark** (`benchmark_off_vs_on.jl`, 9 systems, same data): **`best_max` identical off→on on every system** (no recovery regression, `on_worse=0` everywhere). Candidate-**set** similarity (`set-Δ` = max nearest-neighbor rel-dist of an ON candidate to the OFF set): **~1e-13 (identical sets) on well-conditioned systems** (simple, lotka, vanderpol, harmonic, daisy_mamil3, slowfast); **0.34–0.97 on ill-conditioned ones** (daisy_mamil4, seir, biohydrogenation) — i.e. the *spurious tail* reshuffles where conditioning is bad, but the **best/recovered candidate is byte-identical**.

**Verdict:** default-ON is safe on *recovery* everywhere and identical on clean systems. Caveat: on
ill-conditioned / **M>1** systems the *full* candidate list (→ `result.csv` ordering / UQ) can shift in
the spurious tail, so re-baseline full-output comparisons there (primary branch appears stable; the
discarded tail moves). The 2nd physical branch on M>1 systems was not explicitly diffed.

## Receptor `[RESOLVE]`/backsolve — real-and-necessary? NO (for receptor)

`receptor_backsolve_test.jl`: backsolving receptor's **physical** solution (truth params + exact states
at a shooting point) to t0 with a stiff/auto solver (`AutoVern9(Rodas5P())`) recovers the ICs to
**machine precision (1e-14)** and is **well-conditioned** (a 1e-6 state perturbation → ~1e-6 IC error;
amplification ≈1–4× over the full interval, *not* 1e9). There is **no backward instability** for the
real solution. But a **non-physical** start (negative occupancies — a spurious root) backsolves to
**~1e163**. So receptor's `[RESOLVE]` (~26 SIAN re-runs/run, the 88-min bottleneck) fires **only on
spurious candidates whose backsolves blow up** — garbage we'd reject anyway — *not* on truth (truth
backsolves cleanly and is recovered by the scaled main solve + clean backsolve). **`[RESOLVE]` is
therefore unnecessary for receptor's recovery.** Cheapest speed fix: **filter out-of-bounds /
non-physical candidates before backsolving** (the pipeline currently backsolves everything, detects
the 1e163 blow-ups via `compute_default_bounds`, then `[RESOLVE]`s them — `optimized_multishot:2037`).
*Caveat:* `[RESOLVE]` may still be genuinely needed for truly-stiff systems (ERK-class) where the
*physical* backsolve fails — untested; the fix is "filter before backsolve" so it only fires when real.

## Two orthogonal receptor levers
- **Recovery** (find truth+swap): **column scaling** (done — flips 0/2 → 2/2).
- **Speed** (kill the `[RESOLVE]` tax): **pre-backsolve physicality/bounds filtering** (proposed; targets
  the actual bottleneck — spurious candidates blowing up the backsolve).

## Recommendations

1. **Default is `use_column_scaling = true`** (flipped 2026-05-27 and validated: regression 446/446 with ON,
   no recovery regression on the 9-system off-vs-on benchmark, candidate sets identical on well-conditioned
   systems). It is a benign solver-reach aid — provably inert where HC already finds truth, decisive on
   extreme-jet (receptor-class) systems. (Earlier draft said "off by default"; superseded.)
2. **To slot receptor into the benchmark:** run it with `use_column_scaling = true`. It recovers both
   M=2 branches (branch-aware). Note it is *recoverable but slow* — the homotopy still collapses and
   the fallback does the work. For speed, pair with fresh-solve-per-point (skip homotopy; scaling makes
   each point's fresh solve find truth) or monodromy completion — these address the *homotopy*, which
   column scaling provably cannot.
3. **Do not expect column scaling to help noisy recovery on bioh/daisy** — that's noise amplification,
   governed by the scale-invariant `∂x/∂data`; it's out of scope by construction.

## Reproduce
```bash
cd /home/orebas/.julia/dev/ODEParameterEstimation
julia --startup-file=no -e 'using ODEParameterEstimation, Test; include("test/column_scaling.jl")'   # 12/12
julia --startup-file=no repro/column_scaling_impl_2026_05_26/probe_scales.jl                          # engagement (scale ranges)
julia --startup-file=no repro/column_scaling_impl_2026_05_26/run_sweep_v3.jl                          # benign+inert (controlled)
julia --startup-file=no repro/column_scaling_impl_2026_05_26/receptor_homotopy_diag.jl                # mechanism (return codes)
julia --startup-file=no repro/column_scaling_impl_2026_05_26/receptor_e2e.jl                          # receptor recovery (truth+swap)
```
Logs + CSVs alongside each script in this directory.
