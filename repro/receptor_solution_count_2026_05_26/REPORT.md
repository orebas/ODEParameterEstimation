# Receptor Solution-Count: Full Diagnosis

> **UPDATE (see Part II at the bottom).** Part I below calls t≈−0.3 a "robust geometric blind
> spot." That framing is **superseded**: follow-up forensics (Exp G–K) + a two-model PAL consult
> proved truth is an *exact root* there (residual 1e−11) that the polyhedral solver simply fails to
> *track*, because truth's coordinates span ~10⁷ in magnitude (a **column-scaling** pathology, not
> geometry). Data-driven column scaling recovers truth **6/6 seeds** at t=−0.3 (vs 0/8); monodromy
> completion also recovers it. Read Part II for the corrected verdict.

Date: 2026-05-26. System: `receptor_subtype_binding_branch` (2-site competitive
binding; 3 states `L,Ca,Cb`, 6 params `R1tot,R2tot,kon1,kon2,koff1,koff2`; observe
`y1=L`, `y2=Ca+Cb`; structural multiplicity **M=2** = a↔b swap). Data sampled over
`t ∈ [-0.5, 0.5]` (IC at the left end), 101 points, noise 0.

SI template: **32 equations / 32 solve-vars / 22 data-vars**; full (untrimmed) = 40
equations, 8 dropped by rank-trimming; algebraic multiplicity reported M=2.

Scripts: `run_diagnostic.jl` (this dir). Raw log: `run_diagnostic.log`. All HC solves
use the same parametrized system `convert_to_hc_format_with_params(template, solve_vars, data_vars)`;
"oracle" data = exact derivative jet via `build_perfect_interpolants` + `evaluate_data_vars_at_point`;
"AAAD" data = production interpolant. Full breakdown via `ntracked / nat_infinity / nsolutions / nsingular / nreal`.

---

## Executive summary — answers to the five questions

1. **True generic solution count = 18** (not 6402). `mixed_volume` (BKK torus) = 6402 is
   a *path* bound; the total-degree bound is **94,143,178,827**. Solving at random complex
   parameters gives exactly **18 finite** solutions every time — ~6000+ of the 6402 paths
   **diverge to infinity**. So the variety has degree 18; 6402 is a loose upper bound, not a
   solution count. *The "willies" are unfounded.*

2. **With exact (oracle) derivatives, the full count is ≈10–18 finite per time point** (0
   singular, ~4–5 complex, 5–14 real), with the rest of the 6402 paths at infinity. At t=0:
   16 finite (12 real + 4 complex), and **both truth and swap are present**.

3. **Fresh polyhedral solve ≫ parameter tracking.** Per-point fresh polyhedral (oracle) finds
   10–18 finite and recovers truth/swap at most t. **Parameter tracking collapses** (e.g.
   seed t=−0.5: 11→2; generic→leftward: →0) — *even with exact data*.

4. **Seed location matters but no seed avoids collapse.** Tracking *rightward* (toward +0.5)
   preserves the most (seed t=0 → 6); *leftward* (toward the degenerate left boundary) always
   collapses (→0–2). The left region (t ≤ −0.3) is where paths die.

5. **The pathology is primarily ALGEBRAIC/GEOMETRIC, not interpolation.** Tracking collapses
   with *exact* data (Exp D) just as with AAAD (Exp E); and even fresh polyhedral *robustly
   misses truth at t≈−0.3 with exact data* (5/5 HC seeds — Exp F). Interpolation error is a
   **secondary aggravator**: it roughly halves the truth-recovery rate (oracle finds truth/swap
   at ~8/11 t; AAAD at ~4/11).

---

## Exp A — Generic solution count vs BKK bound

```
mixed_volume (BKK torus path bound) = 6402
paths_to_track(polyhedral)          = 6402
paths_to_track(total_degree)        = 94,143,178,827   (≈9.4e10 — absurdly loose)

random-complex seed #1: paths=6402  at_infinity=6080  FINITE=18 (sing=0, real=0, complex=18)
random-complex seed #2: paths=6402  at_infinity=6027  FINITE=18
random-complex seed #3: paths=6402  at_infinity=6038  FINITE=18
```
**Generic finite solution count = 18** (stable across 3 random seeds). The 6402−18 ≈ 6384
extra paths go to infinity. The degree-18 variety is what a *correct* parameter homotopy would
need to track; the mixed volume merely bounds the path count.

## Exp B — Oracle data at t=0, full breakdown

```
t=0 ORACLE: paths=6402  at_infinity=5257  FINITE=16 (sing=0, real=12, complex=4) | TRUTH + SWAP present
```
Seeding the *true* small values + true derivatives gives 16 finite solutions; both physical
branches (truth and swap) are among the 12 real. (At this special real point, 2 of the generic
18 are at infinity.)

## Exp C — Oracle scan across t (fresh polyhedral per point)

```
   t   paths  at_inf  FINITE  sing  real  complex   truth/swap
 -0.50  6402   2793     12      0     7      5       TRUTH SWAP
 -0.40  6402   3241     11      0     7      4       SWAP        (truth missing)
 -0.30  6402   3540     10      0     5      5       — none —    (BOTH missing)
 -0.20  6402   3943     15      0    11      4       TRUTH       (swap missing)
 -0.10  6402   4351     16      0    12      4       TRUTH SWAP
 +0.00  6402   4951     17      0    13      4       TRUTH SWAP
 +0.10  6402   5405     17      0    13      4       TRUTH SWAP
 +0.20  6402   5767     18      0    14      4       TRUTH SWAP
 +0.30  6402   5763     18      0    14      4       TRUTH SWAP
 +0.40  6402   5962     18      0    14      4       TRUTH SWAP
 +0.50  6402   5889     18      0    14      4       TRUTH SWAP
```
- Finite count is **t-dependent (10–18)** even with exact data; it rises to the full generic 18
  on the right (t ≥ +0.2) and dips to 10 near t=−0.3. Singular count is 0 throughout.
- **Surprise (refined by Exp F):** with *exact* data the polyhedral solve **fails to return truth
  at t=−0.3** — Exp F confirms this is **robust (5/5 HC seeds miss it)**, a genuine geometric blind
  spot where truth's path diverges to infinity even with perfect data. The t=−0.4 miss here was just
  an unlucky seed (Exp F: 4/5 seeds *do* find truth there). Truth generated the data, so it *is* a
  root — yet HC's polyhedral homotopy still sends its path to infinity at t≈−0.3. So even fresh
  polyhedral is not 100% reliable on this system in the left region.

## Exp D — Oracle parameter tracking, three seeds (collapse — even with exact data)

```
SEED t=-0.5 -> rightward  (11 start sols):  -0.4:5  -0.3:4  -0.2:2  ... +0.5:2   (collapses 11→2)
SEED t= 0.0 -> rightward  (17 start sols):  +0.1..+0.5: 6 (holds at 6)
SEED t= 0.0 -> leftward   (17 start sols):  -0.1..-0.5: 2 (collapses to 2)
GENERIC complex seed: 18 finite ->track to t=0: 9 -> rightward: 3  ;  -> leftward: 0  (total collapse)
```
- **Tracking bleeds paths at every step, even with exact data.** No chain preserves the full
  finite set. Rightward (toward +0.5) loses the least; **leftward (toward t=−0.5) collapses to 0–2.**
- Contrast with Exp C: a *fresh* polyhedral solve at the same points keeps 10–18. So the loss is
  the **tracking**, not the points.

## Exp E — AAAD contrast (interpolation's added cost)

```
AAAD polyhedral scan:
   t   FINITE  sing  real   truth/swap
 -0.50    9      0     7
 -0.40   17      0     6
 -0.30   15      0     6
 -0.20   11      0     9    TRUTH SWAP
 -0.10   18      0    14
 +0.00   16      0    12    TRUTH SWAP
 +0.10   17      0    10
 +0.20   18      0    14    TRUTH SWAP
 +0.30   18      0     6
 +0.40   16      0    13    TRUTH SWAP
 +0.50   12      1    12

AAAD tracking chain (seed t=-0.5): 12 -> 4 -> 4 -> 0 -> 0 -> ... -> 0   (collapses to 0)
```
- AAAD fresh-polyhedral finds finite counts in the same 9–18 range as oracle, but recovers
  truth/swap at **only ~4/11 t** (vs ~8/11 for oracle) — interpolation error displaces the roots
  out of tolerance (or to infinity) at the other points.
- The AAAD tracking chain collapses to 0 by t=−0.2 — the same collapse as oracle tracking, slightly
  worse (→0 vs →2). Confirms the collapse is intrinsic, with interpolation as an additional hit.

## Exp F — Multi-seed robustness at the left blind spot (oracle data)

To settle whether Exp C's "truth missing at t=−0.3/−0.4" was a stochastic artifact of HC's random
seed, the fresh polyhedral solve was repeated with **5 independent HC seeds** at each point, on
**exact (oracle)** data:

```
 t=-0.30 (oracle):  seed1 fin=11 r=6   seed2 fin=7  r=5   seed3 fin=12 r=7
                    seed4 fin=9  r=5   seed5 fin=12 r=6      -> 0/5 find truth or swap
 t=-0.40 (oracle):  seed1 fin=10 r=5 (none)   seed2 fin=13 r=8 TRUTH+SWAP   seed3 fin=11 r=7 TRUTH
                    seed4 fin=12 r=6 TRUTH     seed5 fin=11 r=8 TRUTH+SWAP    -> 4/5 find truth
```
- **t=−0.3 is a robust geometric blind spot:** all 5 seeds fail to return truth *or* swap, even with
  perfect data. Not seed luck — truth's path genuinely diverges to infinity here.
- **t=−0.4 is stochastic but usually recoverable:** 4/5 seeds find truth (2 of them also the swap).
  Exp C's single miss at −0.4 was an unlucky seed, *not* a blind spot.
- **The finite count itself is seed-stochastic:** 7–12 at t=−0.3, 10–13 at t=−0.4 across seeds — HC
  loses a different number of paths to infinity each run. So per-t counts in Exp C/E carry ±2–3.

---

## Synthesis

- **The 6402 mystery is resolved:** it's the BKK torus *path* count, not a solution count. The
  system has **18 generic finite solutions**; ~6384 of the tracked paths run to infinity. (Both
  the BKK 6402 and the total-degree 9.4e10 are loose bounds from the cubic param×param×state
  binding monomials.) Of the 18, at a given real data point ≈10–18 are finite and exactly **2 are
  physical** (truth + swap = M).

- **Receptor's failure is substantially algebraic/geometric, not interpolation:**
  - Parameter-homotopy tracking collapses **with exact data** (Exp D) — so the "path collapse"
    seen earlier with AAAD is intrinsic, not an interpolation artifact.
  - Even **fresh polyhedral with exact data** loses truth at t=−0.3/−0.4 — a geometric blind spot.
  - **Fresh polyhedral is far more robust than parameter tracking** (10–18 vs 2–6 finite).
  - Interpolation (AAAD) is a *secondary* hit: it roughly halves the truth-recovery rate on top of
    the geometric baseline.

- **Actionable implications for the pipeline:**
  1. **Don't use parameter homotopy on this system** — `solve_with_hc_parameterized` tracking
     collapses regardless of data quality. Use **fresh polyhedral (`solve_with_hc`) per shooting
     point**, which recovers truth/swap at most t. (This matches the earlier finding that the
     homotopy-OFF config found truth and the homotopy-ON config did not.)
  2. **Shooting points matter geometrically:** put points in the right/interior region (t ≥ −0.1),
     where fresh polyhedral reliably returns truth+swap with the full 18; avoid the left region
     (t ≤ −0.3) where even exact-data polyhedral drops the physical roots. `shooting_warp`
     clustering at the left boundary is doubly bad here.
  3. Better interpolation (oracle-level accuracy) roughly doubles truth recovery but does **not**
     fix the geometric tracking collapse — accuracy alone is insufficient.

## Caveats

- The multi-seed re-run (**Exp F**) settled the seed-sensitivity question: truth is **robustly absent
  at t=−0.3** (0/5 seeds), genuinely a blind spot; the t=−0.4 miss in the single Exp-C scan was an
  unlucky seed (4/5 seeds find truth). The finite *count* is seed-stochastic everywhere (e.g. 7–12 at
  t=−0.3 across seeds) — HC loses a different number of paths to infinity per run — so treat per-t
  counts as ±2–3. The qualitative pattern (left region hard, right keeps ~18, truth recoverable
  except at t≈−0.3) is robust.
- Counts are nonsingular+singular finite; singular was 0 almost everywhere (one singular at t=+0.5
  AAAD). At-infinity is HC's `nat_infinity`.

## Reproduce

```bash
julia --startup-file=no repro/receptor_solution_count_2026_05_26/run_diagnostic.jl
# ~40 min; writes the tables above to stdout. Oracle data path: build_perfect_interpolants
# + evaluate_data_vars_at_point (function-form nth_deriv). See run_diagnostic.log for the full run.
```

---

# Part II — Solver-vs-geometry forensics & the column-scaling fix (Exp G–K + PAL consult)

Part I left one thing soft: *why* does fresh polyhedral miss truth at t≈−0.3 even with exact data?
Part I guessed "geometric blind spot / truth's path diverges to infinity." Part II disproves that
and finds the real cause + two working fixes. Scripts: `exp_g_solver_forensics.jl`,
`verify_tracker.jl`, `exp_h_retrim.jl`, `exp_h2_blindspot_map.jl`, `exp_i_truth_existence.jl`,
`exp_k_fix_confirm.jl` (logs alongside). The full 40-eq / trimmed 32-eq systems are dumped to
`full_system_40.txt` / `trimmed_system_32.txt`.

## How the system is actually built (so the findings are grounded)

`get_polynomial_system_from_sian` (`src/core/si_equation_builder.jl:860`) builds `Et` by SIAN's
**rank-saturating prolongation**: add each observable's next derivative low→high order, keep it only
if it raises the Jacobian rank, pull in the ODE-prolongation (X-)equations it needs; stop an
observable when its next derivative stops adding rank; finally append remaining Y-equations that
introduce no new variable. Then `algebraic_independence` (`:565`) keeps a **greedy maximal-rank
prefix** (process eqs in order, keep if rank increases). This is a faithful SIAN method, correct for
its purpose (local/generic identifiability) — there is a real built-in low-order bias.

**Consequence for receptor (`y1 = L` observed directly):** the equations `L_k = y1_k` are *linear
data pins* that are **locally rank-redundant** (L_k is already pinned by its ODE-prolongation eq,
e.g. `[5] L_1 = f_L`), so they're appended last and dropped. The trimmed 32-eq system therefore uses
**none** of the y1-derivative data (verified: y1-derivatives orders 1–7 appear in zero of the 32
trimmed equations). Truth+swap satisfy all 40; the trimmed 32 admit 16 extra spurious roots.
*(This is a local-vs-global property of Jacobian trimming — principled, not a bug — and is a
SEPARATE issue from the blind spot.)*

## Exp G — per-path return-code forensics (the deficit isn't clean at-infinity)

Reading HC's per-path `return_code`/`condition_jacobian`/`extended_precision_used` (never inspected
in Part I): at t=−0.3 the missing ~7 solutions die as **`terminated_max_steps` (~1600 paths),
`terminated_accuracy_limit` (~355), `terminated_step_size_too_small`, `terminated_max_extended_steps`**
— solver-termination codes, *not* clean `:at_infinity`. `extended_precision_used` climbs toward the
blind spot (451 → 847 → 1300). HC already runs adaptive extended precision by default.

## verify_tracker — precision/steps cannot fix it

Same seed, t=−0.3: `max_steps=50 → finite=0` (proves `tracker_options` propagate), `max_steps=10000
→ finite=11`, `max_steps=200000 → finite=11` (`terminated_max_steps` 1614 → 1615). **20× more steps
recovers ZERO.** Not a step/precision problem.

## Exp H / H2 — reconditioning the equations doesn't fix it either

An alternative square subsystem that *keeps* the linear y1-pins collapses BKK path count 6402→**297**
(~20×) and improves max `condition_jacobian` ~**500×** (2.7e13 → 5.3e10), and still finds truth+swap
at t=0. **But the blind spot survives** (multi-seed pin-keeping system: truth found at t=−0.5 1/8,
−0.4 0/8, −0.3 0/8; recovers t=−0.2 5/8, −0.1 6/8). So it is **not** the equation conditioning,
path count, or the y1-pin omission.

## Exp I — the decisive tiebreaker: truth's exact coordinates vs t

Truth's exact 32-vector (true params + true state jet from the oracle ODE) evaluated across t:

```
   t     trim_residual(truth)   max|coord| (=Cb_8)    |Ca_8|   |Cb_8|   |L_7|
 -0.50        4.9e-10              5.26e+06            2.7e6    5.3e6    5.4e5
 -0.30        1.1e-11              3.05e+05            1.8e5    3.0e5    4.5e4
  0.00        1.9e-12              1.38e+04            9.5e3    1.4e4    3.1e3
 +0.50        6.7e-14              3.82e+02             ...
 max|coord| by order @ t=-0.3:  o0:1.6  o3:17  o5:6.1e2  o7:4.5e4  o8:3.0e5   (~10×/order)
 max|coord| by order @ t= 0.0:  o0:1.3  o3:4.5 o5:8.1e1  o7:3.1e3  o8:1.4e4   (~5×/order)
 MONODROMY @ t=-0.30 (seed=truth): 18 solutions found
```

- **Truth is an exact root at every t** (residual ≤1e−10, 1.1e−11 at the blind spot). So HC *fails to
  find* an existing root — a tracking failure, **not** geometric absence. (Part I's "diverges to
  infinity" was wrong; the PAL partners flagged it independently.)
- **It's column scaling.** Truth's coordinates span **O(0.1) … O(5×10⁶)** — dynamic range ~10⁷ — driven
  by high-order jets blowing up ~10×/order near the transient (vs ~5×/order at t=0). The *min*
  coordinate stays ~0.1 (Ca₀ at its IC), so it is **not** a toric-boundary (coords→0) issue; it's the
  high orders exploding. Exp H reconditioned rows/endpoints but left the **column** scales untouched —
  truth stayed a 10⁷-dynamic-range point in both formulations, which is why the blind spot survived.

## PAL consult (GPT-5.4 + Gemini-3.1-pro, independent) — consensus

Both: condition number is *local at the root*; the homotopy fails *globally along the path*. Left
region hard because near the IC `Ca,Cb≈0` and the deep jet's high orders explode. Distinguish
geometry vs scaling using the *known* truth coordinates (→ Exp I). #1 fix: substitute observed jet
vars away (`L_k=y1_k`, `Cb_k=y2_k−Ca_k` → ~15 unknowns) and/or **Taylor-scale** `x̂_k=hᵏx⁽ᵏ⁾/k!`;
then projective/total-degree start; then multipoint. Operationally, use t≥−0.1.

## Exp K — both fixes confirmed at t=−0.3

```
K1 (monodromy completion): plain polyhedral 11 finite (no truth) → monodromy seeded from those 11
   → 17 solutions, TRUTH + SWAP recovered.
K2 (data-driven COLUMN SCALING; scale each jet var by |order-k observable derivative|, params×1):
   6/6 seeds → finite=16, real=8, TRUTH + SWAP  (unscaled baseline 0/8).  mixed_volume stayed 6402.
```

K2 is the clean proof: scaling variables does not change the Newton polytopes (mixed_volume unchanged
at 6402) — *only* the coordinate scales change — and that alone flips 0/8 → 6/6. So the blind spot
was purely a column-scaling/coordinate-magnitude pathology.

## Corrected verdict & recommendations

- **t≈−0.3 is NOT a geometric blind spot.** Truth exists there as an exact root; unscaled polyhedral
  tracking can't reach it because truth spans ~10⁷ in coordinate magnitude (deep-jet derivative
  blowup near the transient).
- **Two fixes, both in the SOLVER layer (neither touches `si_equation_builder.jl` or the trim):**
  1. **Column scaling** of the jet variables by their observable-derivative magnitude (data-driven,
     no truth needed) — recovers truth 6/6 at t=−0.3. Matches the `CLAUDE.md` column-scaling wishlist;
     receptor is a concrete instance proving it matters. *Open:* use interpolated-jet magnitudes for
     scales (only needs order-of-magnitude accuracy); regression-test as a no-op on well-conditioned
     systems before any production change.
  2. **Monodromy completion** — after polyhedral, seed `monodromy_solve` from the found solutions to
     complete the orbit and recover truth/swap.
- **Operationally today:** prefer shooting points with t ≥ −0.1 (avoid the deep-transient left region);
  deep single-point jets near a transient are numerically antagonistic regardless of solver.
- **Separate, lower-priority:** the trim drops the linear y1-data pins (→ 16 spurious roots). Not the
  blind-spot cause; revisit only as a code-quality/efficiency item, with care (fragile core).
