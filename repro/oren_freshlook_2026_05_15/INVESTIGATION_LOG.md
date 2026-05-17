# Investigation log — 2026-05-15 fresh-eyes deep dive

This is a running log of what we're investigating, what we've found, and
tangents we want to come back to. Most recent entries at the bottom.

---

## Goal

Understand why ODEParameterEstimation's 2026-05-14 benchmark ("14") often
ships a 100-row result.csv where the rank-1 row is far from truth, even
when an oracle-near row exists in the file. User wants moderate-sized sets
(5–20ish for hard models, 1–5 for easy, multiplied by genuine algebraic
branch count) that contain truth-near candidates without wasted budget on
"wildly wrong" rows.

## ODEPE design philosophy (per user, 2026-05-15)

This is the design ideal ODEPE distinguishes itself from AMIGO2/SHADE by:

> Under ideal (noise-free) conditions, ODEPE should return PRECISELY the
> set of points in the local-unidentifiability fiber — no more, no less.

In structural-identifiability terms:

| identifiability class (SIAN) | ideal output |
|---|---|
| globally identifiable | 1 point |
| locally identifiable, globally non-id (fiber of size d > 1) | exactly d points |
| locally non-identifiable (continuous orbit) | peg the unidentifiable directions, reduce to locally-identifiable, return d points of the reduced problem |

So the set size is *always* a small integer — the generic algebraic degree
of the (possibly pegged) polynomial system. Not "as many as polish budget
allows". With noise, the d discrete points blur into d clusters; the ideal
degrades to "return d cluster representatives".

**Consequences for this investigation:**

- The "rerank" debate is secondary. Picking the right *d* matters more
  than what order we present d rows in.
- Generic algebraic degree is the natural target size *in principle*. In
  practice, we don't compute it — see qualifications below.
- The success metric is **"are all d fiber points represented?"**, not
  "is rank-1 truth".

**Important qualifications (user, 2026-05-15 evening):**

1. *Most benchmark systems are degree 1.* So degree-aware sizing helps a
   minority of cells. The bulk of failure cases are degree-1 systems
   where we should be returning 1 row but somehow aren't doing well.
   The degree story is a small slice of the diagnosis.
2. *The "true" generic algebraic degree is hard to compute.* The system
   we feed HC.jl is **truncated**, and the truncation introduces
   spurious solutions. The correct degree would be the number of
   algebraic solutions to the *fully-extended overdetermined* system at
   a generic point — and we don't compute that. HC.jl's solution count
   is an upper bound that overcounts.
3. *biohydrogenation may have many HC-spurious solutions despite degree 1.*
   The pipeline absorbs spurious-then-discarded candidates through
   later stages but they have computational cost and can dilute
   ranking signals.
4. *"Ridges" in result.csv aren't necessarily failures.* There are
   **numerical ridges that aren't algebraic ridges**: noise + polish
   ill-conditioning blur discrete fiber points into a continuous-looking
   spread. The data residual is flat in a direction the algebraic
   system isn't. So seeing a ridge doesn't mean SIAN missed something
   or pegging didn't happen.
5. *Regularization in polish (to disambiguate ridges) was tried before*
   but the user doesn't remember outcomes. Tangent on the wishlist —
   add to TODOs.

## Open tangents to revisit (TODO list)

These are loose threads — don't lose them.

- [ ] **The 8% of cells with "no oracle-close row at all"** — these are
  separate from the ranking question. Likely the column-scaling
  investigation cluster-claude documented. Audit after the ranking thread
  is resolved.
- [ ] **Why polish-from-aggregate-seed sometimes finds lower err than
  polish-from-HC-seed.** I claimed this was "aggregates aren't constrained
  to the polynomial system" but haven't proved it. May be ODE solver
  imprecision, polish stopping criterion, IC mismatch. Test by polishing
  truth itself and reading off the err.
- [ ] **Whether the 06 baseline would have the same problem under
  err-sorting.** If we re-evaluated err on 06's rows under current polish
  code, would truth-near be at the top? (06 outputs have no err column —
  this requires re-polishing 06's parameter vectors against the same data.)
- [ ] **SI/SIAN-derived target set size.** Use generic algebraic degree
  from HC.jl's solution count + practical identifiability dimension to set
  per-cell target size adaptively.
- [ ] **`seir_5_1em4` failure** — under scheme C the rerank doesn't help.
  The 2 non-synthetic rows are both wrong. Different pathology — separate
  investigation.
- [ ] **Brusselator failure mode** (`brusselator_6_0`, noise=0, rank-1 err
  = 146). Cluster-claude's column-scaling investigation. Don't lose this
  as the long-pole of the 8%.
- [ ] **Aggregate-only cells like `slow_fast_6_1em4`** — HC produced zero
  real candidates. Without aggregates, file is empty. Argues for keeping
  aggregates. Investigate whether HC is failing for a fixable reason
  (column scaling on the polynomial system, degenerate startsystem, etc.)
  or if the cell genuinely has no real algebraic solutions.
- [ ] **Polish-stage regularization for ridge disambiguation.** User wants
  to introduce a small bias (e.g., toward bound-center, prior centroid)
  to break numerical ridges and pick a canonical representative. Tried
  before, outcome unknown. Worth revisiting.
- [ ] **Biohydrogenation spurious-solutions investigation.** Degree-1
  system reportedly producing many HC candidates due to truncation
  artifacts. Verify and quantify.
- [ ] **Compute a tractable proxy for "true" generic degree.** Options:
  use polynomial-degree analysis on the SIAN-derived equations before
  truncation; track which polished solutions ended at the same fiber
  point by clustering in identifiable-subspace; run HC once at noise=0
  to get an empirical degree count without polish noise. None gives
  the exact algebraic-geometry answer but any could be a useful proxy.

## Pipeline reference

Detailed flow map of the current default pipeline (16 stages with file:line
citations) lives in [PIPELINE_MAP.md](PIPELINE_MAP.md). Key takeaways:

- **Default output is top-100 of err-sorted, 1e-5-deduplicated cluster reps.**
  No L∞-MAD branch detection at the output stage anymore (removed in `f34d28d`).
- **Pre-polish clustering at relative-distance 0.001** (gates which candidates
  get polish budget).
- **Post-polish dedup at 1e-5** (only bit-identical merges).
- **Aggregate synthesis is ON by default**, contributes many `-1`-tagged rows.
- **Multi-point template is ON by default** (`multipoint_n_points = 2`,
  `multipoint_max_pairs = 20`).
- **Sensitivity seeds OFF** by default. UQ OFF by default.
- **Pegging happens at the SI-template stage** (`structural_fix_set`),
  catches *continuous* SIAN-detected non-identifiability. Doesn't catch
  numerical ridges.

## Established findings (high confidence)

### F1 — Truth-near rows are usually in the file, just buried (or sometimes missing entirely)

300-cell random sample from 14's `odepe_v2_polish_run`. For each cell,
compute oracle distance (max relative error over identifiable params +
states excluding `_trfn_*` and `all_unidentifiable`) for each of the 100
rows.

| rank of oracle-best in err-sorted result.csv | count | % |
|---|---|---|
| 1 | 158 | 52.7% |
| 2–5 | 35 | 11.7% |
| 6–10 | 13 | 4.3% |
| 11–50 | 37 | 12.3% |
| 51–100 | 33 | 11.0% |
| > 100 (lost) | 0 | 0.0% |
| no oracle-close anywhere (deep fail) | 24 | 8.0% |

Implication: 92% of cells with an oracle-near row at all have it inside
the 100-row file. 23% have it buried at rank 11–100 (UX problem). 8% don't
have it at all (containment problem, separate cause).

### F2 — Most "regression cells" have the same truth-near row in 14 as 06

10 named regression cells. 9 of 10 have 14 best-oracle within 1.02× of
06 best-oracle. 06 looked good only because its CSV was oracle-cheat-sorted
(no `err` column). The truth-near rows have always existed in the
candidate set.

| cell | 06 best | 14 best | 14 rank | gap |
|---|---|---|---|---|
| seir_5_1em4 | 0.01065 | 0.01065 | 66 | 1.00× |
| forced_lv_4_1em2 | 0.002283 | 0.006115 | 39 | 2.68× |
| forced_lv_6_1em2 | 0.003999 | 0.004057 | 97 | 1.02× |
| seir_5_1em6 | 0.0001621 | 0.0001621 | 2 | 1.00× |
| aircraft_pitch_5_1em8 | 0.001956 | 0.002513 | 4 | 1.29× |
| dc_motor_4_1em4 | 0.0003241 | 0.0003241 | 85 | 1.00× |
| boost_converter_9_1em4 | 0.000419 | 0.000419 | 16 | 1.00× |
| seir_0_1em6 | 8.4e-05 | 8.4e-05 | 3 | 1.00× |
| aircraft_pitch_0_1em6 | 6.6e-06 | 0.000262 | 13 | 39.7× |
| sirt_treatment_3_1em6 | 4.9e-05 | 4.9e-05 | 57 | 1.00× |

### F3 — `polish_source_hc_idx == -1` correlates with rank-1 failures (interpretation revised)

In gap cells (rank-1 oracle > 5× worse than oracle-best), rank-1 row has
`polish_source_hc_idx == -1` 77% of the time. In good cells, 37%. The
correlation is strong.

**Interpretation revised (2026-05-15 evening):** I initially read `-1` as
"synthetic-aggregate-sourced", but the template at
`julia_template_for_estimation_odepe_v2.jl:197-199` writes `-1` *whenever*
`provenance.polish_source_hc_idx === nothing`. The field is only set by
`_polish_batch_from_context` at line 2687 (via `rep_idx`). It's `nothing`
for any candidate that didn't go through that specific polish path —
which includes synthesized aggregates that bypassed polish, multipoint
candidates, terminal-fallback candidates, *or* HC candidates whose polish
result lost provenance during result aggregation.

So "`-1` rows" are a *mixture*: definitely includes aggregates, but also
other origins. The correlation with rank-1 failures is real, but the
causal story is less clean than "aggregates are wrong-basin".

Concrete evidence of the mixed bag: in `slow_fast_6_1em6`, rank-1 has
`polish_source_hc_idx = 600` (positive) — polish went through the
rep_idx path. In `slow_fast_6_1em4`, *all 100* rows have `-1`, but the
metadata says `source_type: single_point, primary_method: algebraic` for
the best — so it's a polished HC result that lost the `polish_source_hc_idx`
somewhere along the way.

Demoting `-1` rows recovers rank-1 oracle in 52% of gap cells. The fix
works empirically, but the framing "this demotes synthetic aggregates"
was wrong — it demotes "rows that lost their rep_idx provenance",
whatever the cause.



## Discoveries / discussion

### D1 — User's framing

User clarified: target set size should be small (1–20-ish, scaled by
algebraic branch count). The complaint is *not* "we don't have
truth-near", it's "wildly wrong rank-1 wastes our small-set budget".
Switching to small per-cell budgets makes ranking AND filtering
co-important.

### D2 — Slow_fast is the aggregate-paradox case (partially resolved)

For `slow_fast_6_1em4`: 100 rows, ALL with `polish_source_hc_idx = -1`,
err range tight ([1.78e-6, 9.05e-6]).

Initial framing (now revised): "the data residual is flat in a 5D
subspace of 8D parameter space; many points fit data equally well."

### D3 — Slow_fast deep dive (2026-05-15): two discrete basins, k1↔k2 mirror

The actual structure of `slow_fast_6_1em4` is much cleaner than I first
thought. There are **two discrete minima**, not a continuous ridge:

| | basin A (truth) | basin B (wild mirror) |
|---|---|---|
| k1 | 0.104 | 1.75 |
| k2 | 0.876 | 0.052 |
| xA(0) | +0.418 | −10.37 |
| xB(0) | 0.341 | 5.72 |
| eB(0) | 0.768 | 0.144 |
| α = 0.5·k1 | 0.052 | 0.875 |
| β = k2 | 0.876 | 0.052 |

So the mirror swaps `α ↔ β` — i.e., swaps the slow and fast modes — with
correspondingly rescaled (xA, xB, eB) to preserve the observable
trajectory.

**Empirical confirmation:**
- Forward-modeling both yields trajectories that differ by SSR = 1.3e-6
  over 3000 datapoints. The noise floor for noise=1e-4 is ~3e-5. So the
  two basins produce **observationally indistinguishable** trajectories at
  this noise level.
- Loss landscape between them is NOT flat. Linearly interpolating
  (1-α)·truth + α·wild gives SSR 60–260 at intermediate α (vs 1e-6 at the
  endpoints). The two basins are genuinely isolated by a barrier.
- 100 rows in result.csv split 50/50 between truth basin (|xA - 0.418| <
  0.1) and wild basin (|xA - (-10.37)| < 1.0). Zero rows elsewhere.

**Sensitivity:**
- cond(J) at truth = 113. Linearly well-conditioned.
- cond(J) at wild = 10 400. About 100× worse. The "wild" basin is wide
  (small singular values) — polish can wander more there, and fits noise
  better → produces *lower* err than the truth basin row, so rank-1 ends
  up wild.

This is **the k1↔k2 mirror** of slow_fast (generic algebraic degree = 2).
Exactly analogous to ERK's kc1↔kc2 mirror.

### D4 — Slow_fast noise sweep

| cell | err_min | err_max | n_HC | best_rank | best_oracle | rank1_oracle |
|---|---|---|---|---|---|---|
| 6_0 | 4e-24 | 2.6e-7 | 1 | 1 | 1.7e-13 | 1.7e-13 |
| 6_1em8 | 1.3e-13 | 3.2e-7 | 1 | 1 | 3.6e-9 | 3.6e-9 |
| 6_1em6 | 1.2e-9 | 2.2e-7 | 1 | 1 | 2.6e-6 | 2.6e-6 |
| 6_1em4 | **1.8e-6** | **9e-6** | 0 | 9 | **5.4e-4** | **10.8** |
| 6_1em2 | 1.7e-4 | 5e-4 | 0 | 9 | 0.031 | 0.049 |

(`n_HC` = rows with `polish_source_hc_idx > 0`.)

A clean phase transition between noise = 1e-6 and noise = 1e-4. The
crossover is where the wild basin's "best polish" err drops below the
truth basin's "best polish" err, because the wild basin is wider and can
overfit noise better. Below the crossover, rank-1 is truth; above, rank-1
is wild.

**Would more precision help?** Yes, up to a point. The two basins exist
at any noise level — the question is whether rank-1 picks the right one.
Noise σ < 1e-5 keeps truth-basin polish err below wild-basin polish err,
so rank-1 = truth. Above 1e-5, the noise realization can tilt rank-1 to
wild. To force rank-1 = truth at all noise levels, you'd need cond(J)
near-equal at the two basins, which is a model property we can't change.
The right output here is **report both basins, not pick one**.

### D5 — What this implies for output strategy

For a cell like `slow_fast_6_1em4`:

1. The pipeline should detect the algebraic degree (in this case 2) —
   either from HC's solution count at low noise, or via SIAN, or from
   *empirical clustering of polished outputs in identifiable subspace*.
2. Return one cluster representative per basin, plus a small handful
   showing intra-basin noise spread.
3. Total set size: ~5 rows for degree-2 system. ~10 rows for degree-4. Etc.
4. Mark the basins explicitly in result.csv (e.g., a `basin_id` column)
   so the user sees "here are the 2 algebraic branches".

This is exactly what you sketched: "small set size scaled by genuine
algebraic branch count".

### D5b — Exact algebraic mirror, verified to machine precision

In response to user's question "are truth and mirror algebraically exactly
equivalent?" — yes. Verified via closed-form trajectory computation (no ODE
solver): max |y_truth(t) - y_mirror(t)| = 1.1×10⁻¹⁶ across all 750 t-points
× 4 observables. Total SSR = 6.4×10⁻³⁰, which is floating-point roundoff.

**The exact mirror map** for slow_fast:

```
k1' = 2·k2,  k2' = 0.5·k1
xC0' = xC0,  eA' = eA,  eC' = eC
C := 0.249·k1·xA0/(k2 - 0.5·k1)
C' := (xB0 - C)·k2/(0.5·k1)
xA0' = C'·(k2' - 0.5·k1')/(0.249·k1')
xB0' = k2·C/(0.5·k1) + C'
eB' = [0.4422·eA·xA0 + 0.999·eB·C] / [0.999·(xB0' - C')]
```

For truth (k1=0.104, k2=0.876, xA0=0.418, ...): mirror is (k1=1.752,
k2=0.052, xA0=-10.432, xB0=5.745, eB=0.1442). This matches result.csv's
"wild" rank-1 row to ~0.5% (drift from polish on noisy data).

So slow_fast at this parameterization is **fundamentally
two-fold-ambiguous**, not "five-dimensionally non-identifiable".
SIAN's `non_identifiable: []` is correct (no *continuous* orbit) but
doesn't expose the generic degree (= 2) of the polynomial system.

### D7 — biohydrogenation_6_1em6 deep dive (different pathology than slow_fast)

`biohydrogenation_6_1em6` is **degree 1** (SIAN: identifiable, no orbit)
yet besterror=0.73 — total failure on a low-noise case.

**ODE:**
```
dx5/dt = ((-0.3·k7·x5)/(2k8 + 0.5x6 + 0.5x5) + (8·k5·x4)/(4k6 + 8x4)) / 0.5
dx7/dt = (0.2·(10·k10 - 0.5·x6)·k9·x6) / (5·k10)
dx4/dt = (-8·k5·x4)/(8·(4k6 + 8x4))
dx6/dt = ((-0.2·(10·k10 - 0.5·x6)·k9·x6)/(10·k10) + (0.3·k7·x5)/(2k8 + 0.5x6 + 0.5x5)) / 0.5
```

**Observables**: y1 = 8·x4, y2 = 0.5·x5. (x6 and x7 not observed.)

**The k10 trap:** for `k10 >> x6/20 ≈ 0.02`, the factor `(10k10 - 0.5x6)/(10k10) ≈ 1`,
so k10 effectively disappears from `dx6/dt` and `dx7/dt`. Combined with x7 being
unobserved (and not appearing in any other state's RHS), this means k10 is
*structurally* identifiable (SIAN can pick it out from the precise shape near
k10 ≈ 0.05·x6) but *numerically* ridge-like for large k10.

**Result.csv landscape (100 rows):**
- 93 of 100 rows have **k10 = 10.0 (the upper bound)** — polish saturated.
- Those 93 rows have huge spread on k8 (0.001–0.89), k9 (0.015–0.71), x6 (0.4–4.3), x7 (0.34–1.0).
- Essentially zero spread on k5, k6, k7, x4, x5 (the well-determined axes).
- 1 row has k10=0.048; 6 rows have k10 in (1,5).
- Rank-1 is multipoint-sourced, hits k10=10.0, oracle=9.18.
- **Rank-87** has the truth-near values: k10=0.048 (still wrong, k10 truth=0.818), but other params ≈ truth, oracle=0.77.
- 99/100 rows have polish_source_hc_idx > 0 (so this isn't an aggregate-flooding problem like slow_fast).
- branch_size mostly 1 (90 singletons after 1e-5 dedup) — rows are genuinely distinct points, not duplicates.

**The pathology, articulated:**
- The system has a **numerical ridge** in the high-k10 direction of parameter space.
- err is essentially constant along this ridge (all 93 bound-saturated rows have err in a tight band 1.2e-8 to 1.6e-7).
- Polish from most starting points slides along the ridge to the boundary.
- err-sorting then picks one of the bound-saturated rows.
- Truth IS NOT lost (rank-87 oracle = 0.77 has the right k5,k6,k7,x4,x5 values), it's just buried.

**This is the user's "numerical ridge that isn't an algebraic ridge" case.** SIAN
correctly reports the system as identifiable. The continuous-looking spread in
result.csv comes from the loss-landscape geometry plus polish saturation, not
from a missing-SIAN-detection or missing-pegging issue.

**What might help (untested hypotheses on this cell):**
- Polish regularization (small L2 in log-space) would bias k10 away from the
  bound. Already implemented (`polish_regularization_lambda`). User can try
  it case-by-case but no global λ works (see polish-regularization sweep doc).
- A *post-polish* sanity check: if a candidate sits on a bound and there's
  another candidate with err within, say, 10× of the bound-saturated rank-1
  but with the saturating parameter well inside the bound, prefer the interior
  one for rank-1 display.
- Tighter parameter bounds (k10_upper = 2 instead of 10) would change the
  saturation point but not eliminate the ridge — it would just relocate the
  pile of bound-saturated rows. This is a user knob, not a fix.

### D8.5 — Probe results (2026-05-15 evening) — ALL COMPLETE

Detailed report in `probes/PROBE_RESULTS.md`. Quick summary:

- **Probe 1 (cond(J) on slow_fast basins)**: PERFECTLY SEPARABLE. Truth
  basin cond ∈ [112, 113], mirror basin cond ∈ [9667, 11500]. 100%
  classification accuracy with threshold around 1000. [V]
- **Probe 2 (soft-wall regularization)**: ODEPE source changes done
  (`polish_softwall_lambda`, `polish_softwall_epsilon` as opt-in,
  default off). `test/fast_core.jl` 258/258. **Bioh sweep complete (7
  configs)**: k10 saturation 97/100 → 0/100 at any nonzero λ_sw; best
  config λ_sw=1e-2 ε=0.10 gives rank-1 oracle 9.18 → 4.19 (2.2×). λ_sw
  is essentially on/off; ε (band width) is the dominant knob. [V]
- **Probe 3 (slow_fast aggregate trace)**: Different aggregate
  strategies have STRONG basin biases. `per_sp_full_with_mp` median
  finds truth 5/5; `global_param_only` finds mirror 9/9. Aggregate
  synthesis is structured signal, not random. [V]
- **Probe 4 (saturation_count rerank)**: CONFIRMED on 275-cell sample.
  Scheme S2 = `(saturation, is_neg1, err)` raises ≤1% from 71.6%
  (scheme A) to 77.8%, ≤10% from 82.2% to 88.0%. Tail (p90 oracle)
  drops 0.598 → 0.322. Direct test on biohydrogenation_6_1em6: rank-1
  oracle 9.18 → 0.77 (12× improvement). [V]
- **Probe 5 (5 deep-failure cells)**: REFUTES the "all deep failures
  are column-scaling" assumption. 5 sampled cells have 5 distinct
  failure modes: HC failure (brusselator), low-observable-coefficient
  unidentifiability (hiv), numerical ridge (biohydrogenation),
  under-observed + high noise (cstr), multi-bound-saturation
  (flexible_arm). [V on sample]

**Bottom-line takeaway**: scheme S2 (sort-key change) and soft-wall
regularization are two different mechanisms that BOTH help on
bound-saturation failures. Scheme S2 is the cleaner small win (no
algorithmic change, +6pp on 300-cell sample, 12× on bioh). Soft-wall
is a deeper fix that prevents the saturation in the first place but
needs to be opt-in per-cell.

### D8 — Polish regularization: what's there, what's known

The infrastructure for L2 regularization in polish exists:
- `EstimationOptions.polish_regularization_lambda::Float64 = 0.0` (default off)
- Penalty (residual-mode polish): augmented residual
  `[r(log(x_internal)); √λ · log(x_internal)]`
- Penalty (scalar polish): `RSS(x) + λ · ‖log(x)‖²`
- Plumbed through `_polish_batch_from_context` → `_polish_single_residual`
  via `regularization_lambda` field on the polish context.

The 2026-04-26 regularization sweep (see
`temp_plans/2026-05-01_local_polish_default_recommendation.md` and
`artifacts/diagnostics/local_polish_regularization_1em4_hard/summary.md`)
concluded:
- Effect is real but **case-specific and not universal**.
- Helps some crauste/seir/hiv cases at noise=1e-4 (e.g., `seir_6_1em4` from
  11.5% to 0.07% rel err at λ=1e-3).
- Hurts on `daisy_mamil4_1`, `hiv_5`, `biohydrogenation_4` (λ=0 best).
- Doesn't fix pathological brusselator cases.
- 11 of 19 cases best at λ=0; 5 best at λ=1e-1; mix of other.
- **Per-case best λ varies widely — no single nonzero λ works globally.**
- Default stays λ=0.

So the infrastructure is there and validated; the question of "which λ" remains
open and would need adaptive selection or per-system tuning.

### D6 — Open questions raised by this deep dive

- **Why didn't HC find both basins at noise=1e-4?** raw_count was 938
  candidates, but `n_HC` rows (with positive polish_source_hc_idx) = 0.
  Either (a) HC found candidates but pre-polish err filter dropped them,
  or (b) HC produced no real solutions at all because the noisy
  polynomial system became singular. Worth tracing through the probes.
- **The "synthesized aggregate" path that filled in.** With HC contributing
  zero, how did the pipeline produce 100 candidates that landed correctly
  in two basins? The aggregate strategies (median across SP, etc.) seem to
  have multi-modally explored the parameter space — useful behavior! But
  they didn't tag basin membership. Worth investigating whether the
  synthesis is doing something smarter than I gave it credit for.
- **The basin-detection problem in general.** For a cell where HC succeeds
  cleanly at low noise (and gives 2 distinct candidates), we know degree=2.
  For a cell where HC fails (like slow_fast_6_1em4), we don't know
  intrinsically how many basins to look for. Could derive from the
  *low-noise* version of the same problem (run noise=0 first, count
  basins), but that's not always available.


