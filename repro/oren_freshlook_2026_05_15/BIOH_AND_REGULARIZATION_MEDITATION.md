# biohydrogenation noise transition + meditation on regularization and improvements

**Status:** working notes, 2026-05-15.

This sits alongside `PIPELINE_NOTES.md` (current state) and
`INVESTIGATION_LOG.md` (running session log). Confidence markers as before:
**[V]** verified, **[L]** likely, **[S]** speculative.

---

## Part 1: What changes between low noise and 1e-6 in biohydrogenation

The cleanest answer to your question is in the per-parameter sensitivities
at the truth point. [V — numerical FD on the ODE]

**Sensitivities per 1% parameter perturbation, on biohydrogenation_6 (truth ICs/params):**

| param | rms‖ΔY‖ from 1% change | identification status |
|---|---|---|
| k5 | 1.67e-2 | strong — dominant signal |
| k6 | 5.0e-3 | strong |
| k7 | 1.1e-3 | moderate |
| k8 | 5.4e-4 | weak |
| k9 | 2.6e-5 | very weak |
| **k10** | **4.6e-7** | essentially invisible |

A 1% relative change in k10 produces an RMS observable change of 4.6×10⁻⁷
across the 750-point time series. For noise σ on the observables, the
detection threshold for a 1% change in k10 is roughly σ ~ rms‖ΔY‖. So:

| noise σ | predicted: can 1% of k10 be detected? |
|---|---|
| 1e-8 | yes, ~50× signal-to-noise — easy [V — matches empirical] |
| 1e-6 | borderline, ~0.5× — on the edge [V — matches phase transition] |
| 1e-4 | no, ~0.005× — invisible [V — matches saturation] |

This **exactly explains the empirical phase transition** we see: k10 has
small spread (rel-spread 1e-4) at noise=1e-8, blows up to spread 7.85
at noise=1e-6, and to a wide non-physical interval at higher noise [V —
direct measurement on result.csv].

> **Note on bound saturation in the saturated regime [V]:** at k10=5
> (well above truth), the 1% sensitivity drops further to 7.3e-8 — 6×
> worse than at truth. So once polish slides into the high-k10 regime,
> it has even less reason to leave. The ridge is self-reinforcing.

**Why this happens, mechanically [L from ODE structure]**:

```
dx7/dt = (0.2·(10·k10 - 0.5·x6)·k9·x6) / (5·k10)
       = 0.4·k9·x6 - 0.02·k9·x6²/k10
       = 0.4·k9·x6 · (1 - 0.05·x6/k10)
```

For `k10 ≫ 0.05·x6 ≈ 0.02`, the second factor → 1, and k10 effectively
disappears. And x7 doesn't enter any observable. So k10's only path to
visibility is through dx6/dt, which has a similar `(10·k10 - 0.5·x6)/(10·k10)`
factor that also → 1 in the same regime. The whole observable trajectory
becomes (nearly) k10-independent for k10 ≫ 0.02.

This is **structurally identifiable but practically a ridge** [V — SIAN says identifiable].
SIAN can't see the issue because it's looking at the polynomial degree
of the identification problem, not at whether the answer is recoverable
given finite-precision data.

> **Note (open question):** can a *practical* identifiability check sit
> alongside SIAN's symbolic check? Computing the Jacobian's smallest
> singular value at *some* truth-proxy would surface this kind of ridge
> at template-construction time. Maybe at the lowest-noise candidate
> from a quick pre-pass. [S]

---

## Part 2: Regularization in original parameter space — should we?

I worked through the numerics. **Yes, but not the way one might naively
do it.** Tabulating the penalty ratio `P(k10=10, bound) / P(k10=0.818, truth)`
for several variants:

| Regularizer form | Penalty ratio (bound/truth) | Property |
|---|---|---|
| log-space L2 toward `p_internal=0` (**current**) | 2.46× | mild push, scale-invariant in log |
| orig-space L2 toward midpoint of bounds | 1.43× | even weaker — truth and bound are roughly equidistant from arithmetic mid |
| orig-space L2 toward 0 (ridge regression) | 149× | strong; encourages small parameters |
| Soft wall near bounds (zero in interior) | ∞ (truth has 0 penalty) | targets bound-saturation specifically |
| Log barrier near bounds | ∞ | smooth interior-point style |

**Key takeaway [L]:**
- Original-space L2 toward the *midpoint of bounds* is **worse than log-space**
  on biohydrogenation, because the arithmetic midpoint (5.0) is far from
  truth (0.818) and from the bound (10.0), making them similarly penalized.
- Original-space L2 toward 0 (i.e., classical ridge regression) has a much
  larger penalty ratio for this specific case, but it has the *opposite*
  problem on cells where truth is at large parameter values — there it
  would pull truth toward zero. Not a universal win.
- **Soft-wall / log-barrier regularizers near bounds** are the most direct
  fix for the biohydrogenation pathology. They specifically penalize
  bound-saturation but leave interior solutions untouched.

> **Note [V from sweep summary]:** the existing log-space L2 sweep
> showed 11/16 cases best at λ=0. That doesn't mean regularization is
> useless — it means *log-space-toward-geometric-mean* doesn't reliably
> help. A different regularizer might do better on the same cases.

**Math sketch for a bound-soft-wall variant [S]:**

For each parameter `x_i` with bounds `[lb_i, ub_i]`:

```
penalty(x_i) = √λ · [
    max(0, ε - (x_i - lb_i)/(ub_i - lb_i)) +
    max(0, ε - (ub_i - x_i)/(ub_i - lb_i))
]
```

with `ε ≈ 0.05` (i.e., kick in within 5% of either bound). Zero penalty in
the central 90% of the interval. Quadratic ramp-up as the parameter
approaches a bound. Plug into the existing residual-augmentation machinery
in `polish_residual.jl:135-138` — would be ~10 lines of code [L].

> **Potential issue [S]:** soft-walls might cause polish to stall near
> the boundary (penalty growing as it approaches it, polishing toward
> the interior). This is the point — but could also slow convergence
> on cells where the true answer is genuinely near a bound (e.g.,
> kinetic constants that the user knows should be small).
> 
> **Mitigation [S]:** make it opt-in per parameter via a flag, with
> default off for parameters the user expects to live near a bound.

**Alternative: prior-aware regularization [S]:**

```
penalty(x_i) = √λ_i · (x_i - x_ref_i) / scale_i
```

with `x_ref_i` and `scale_i` user-specified. Lets the user specify "I
expect k10 to be O(1), penalize deviations on a scale of 1.0". Equivalent
to a Gaussian prior in original space. Could default to `x_ref_i = mid(lb, ub)`
and `scale_i = (ub - lb)/4` if the user doesn't specify — but the user
should be aware this is a *choice*.

> **Note [S]:** for cases where you HAVE a prior (literature value,
> expected magnitude), this is strictly better than the bound-midpoint
> default of log-space. For cases where you don't, it's no improvement.
> The infrastructure for per-parameter `x_ref` and `scale` doesn't
> currently exist [V from reading source] but would be a small addition.

---

## Part 3: Meditation on improvements — a structured list

Based on the patterns we've seen across slow_fast, biohydrogenation,
forced_lv, and the general 300-cell sample. Ordered by ratio of (likely-impact)
to (implementation-effort).

### Low-effort, low-risk

These don't change algorithms — they add information or re-rank.

1. **Bound-saturation flagging and demotion in output rank.** [S — untested]
   - After polish, compute `saturation_count` = number of parameters within
     ε of a bound (e.g., ε = 0.1% of bound range).
   - Add to result.csv as a column.
   - Use as secondary sort key: `(saturation_count, err)` — rows with fewer
     saturated parameters preferred at equal err.
   - **Expected impact**: directly addresses biohydrogenation k10 pathology
     [V — would flip rank-1 to a non-bound-hit row]. Doesn't hurt cases
     where saturation isn't happening.

2. **Cluster-size as a tie-breaker.** [S]
   - In our slow_fast deep dive, the two basins have ~50 cluster reps each
     after 1e-5 dedup, but rank-1 (whichever basin it's in) is just one
     of those 50. If we presented "rank 1 from the larger basin" as the
     primary recommendation, we'd be reporting the basin with more
     supporting evidence.
   - Easy to add — use `branch_size` as a secondary sort key.

3. **Add a `cond_J_local` diagnostic column.** [S]
   - For each result row, compute the local Jacobian's smallest singular
     value as a fraction of the largest (or just the ratio σ_max/σ_min).
   - Large ratio → the row sits on a near-singular point (numerical ridge).
   - Small ratio → tight basin.
   - Don't use for ranking (yet), just expose. Lets users filter "give me
     rows with cond < 100".

4. **Detect noise-floor underfit.** [S]
   - Estimate noise from the data: σ̂ from successive differences or a GP
     fit; expected SSR is roughly `750·σ̂²` for 4 observables.
   - If a polished row has err << expected noise SSR by 10×+: it's overfit
     (fitting noise that shouldn't be fittable).
   - Demote in rank.
   - **Expected impact [L]**: would catch the "synthetic-aggregate with
     suspiciously low err" pattern in forced_lv-style cases.

### Medium-effort

These add or change pipeline stages but don't require fundamental redesign.

5. **Bound-soft-wall regularization** (Part 2 above) [S, partly tested via existing λ knob].
   - Add as a polish method variant.
   - Empirically test on biohydrogenation, daisy_mamil4, brusselator.
   - Don't make default unless it helps broadly.

6. **Per-parameter L2 toward midpoint, scale-invariant.** [S]
   - `penalty_i = √λ · (x_i - mid_i)/halfrange_i` (linear, normalized).
   - Equivalent to a uniform prior on bounded interval.
   - Same plumbing as existing regularization, different penalty form.
   - Test against current log-space penalty on the existing sweep suite.

7. **Two-stage polish: data-fit then identifiability-aware refinement.** [S]
   - Stage 1: minimize SSR (current).
   - Stage 2: among the polished candidates that share top-quartile err,
     select the one minimizing `Σ_i (bound_distance_penalty_i + parameter_norm_penalty_i)`.
   - Equivalent to a multi-objective approach.
   - Easy to bolt onto the existing pipeline (post-polish step).

8. **Cluster output on the *identifiable* subspace only.** [S]
   - After polish, compute the local Jacobian at the err-best candidate.
   - SVD; project out the "null" directions (smallest few singular vectors).
   - For dedup at output, use the projected distance, not full distance.
   - This collapses the 50-row biohydrogenation cluster (all on the same
     ridge) into ~2 rows.
   - Also gives rank-1 a more meaningful position.

9. **Profile-likelihood credibility column.** [S — expensive]
   - For each rank-1 row, sweep each parameter across a range (say ±50% in
     log space) and re-polish the others. Record the err vs sweep value.
   - Flat profile → low credibility for that parameter.
   - Sharp profile → high credibility.
   - **Expected impact**: gives user-actionable per-parameter info ("k10
     is unidentifiable here, but the other params are tight").
   - Computational cost: ~5–10× more polish calls per cell. Could be opt-in.

### Higher-effort / more speculative

10. **Empirical algebraic degree from polished outputs.** [S]
    - After polish, project rows onto identifiable subspace, cluster at a
      noise-aware threshold (e.g., `3 × √(σ̂² · cond_J)` for the local
      basin width).
    - Count distinct clusters → empirical d.
    - Return d cluster representatives (with intra-cluster noise spread
      shown) instead of top-100.
    - Set size becomes adaptive: 1 for typical degree-1 cells; 2 for
      slow_fast-like cells; etc.
    - **Risk**: noise-aware threshold choice is fiddly; under-cluster
      and you lose meaningful structure, over-cluster and you collapse
      distinct basins.

11. **Sensitivity-driven re-parametrization.** [S — research]
    - Detect that k10 has near-zero sensitivity. Reparametrize as
      `k10' = k10 / (k10 + ref)` (sigmoid) to compress the high range.
    - Polish in reparametrized coordinates.
    - The compression makes a flat region of original-space into a
      well-conditioned region of new-space.
    - Done automatically at the polish stage based on local Jacobian.

12. **Ensemble polish across noise realizations.** [S — research]
    - For each cell, simulate K extra noise realizations (e.g., bootstrap
      on residuals), polish each.
    - Variance of the polished params across K realizations is the
      empirical UQ.
    - Robust answer = the polish landing point stable across realizations.
    - Computational cost: K× polish, but K can be small (5–10).

---

## Part 4: A few "ideas I keep coming back to"

These are the ones that feel most worth trying, on the data we've looked at:

**A. Combine ranking signal sources.** The single biggest leverage point is
moving from `sort by err` to `sort by (saturation_count, err)` or similar
multi-criterion. The slow_fast and forced_lv data both suggest rank-1 will
get much better with this change, at small cost. The catch: requires
adding the `saturation_count` (and possibly `cond_J_local`) columns first.

**B. Look at WHY aggregates worked on slow_fast.** Aggregates with no
HC-source filled 100/100 rows and split 50/50 across the algebraic basins.
That's surprisingly good behavior from a path I had thought was "noise".
Worth tracing how aggregate synthesis manages to populate both basins —
the median strategy across SP candidates may be exposing the basin
structure incidentally. If so, **aggregates may already encode basin
information** that we can read off without changing the algorithm.

**C. Bound-soft-wall regularization, opt-in per parameter.** Pure
biohydrogenation fix. Easy to implement. Low risk. The opt-in design
lets the user say "for parameters I think are O(1), penalize approach to
bounds; for parameters I expect to be small, don't".

**D. A small `IDENTIFIABILITY_TAXONOMY.md` doc.** The "three distinct
problems" framing in `PIPELINE_NOTES.md` Section 8 isn't documented
elsewhere. Capturing it gives a vocabulary for talking about which
mechanism a cell is failing via. Worth a short, clear write-up that
both users and benchmarks can consult.

---

## Part 5: Specific things I want to verify next, before committing to a direction

These are validation steps that would derisk the ideas above [all S in current state]:

1. **Compute `cond(J_local)` for the 50 truth-basin rows of slow_fast** vs
   the 50 mirror-basin rows. Are they distinguishable by cond alone?
   Would let us validate idea #3 as a basin-flagging tool.

2. **Test bound-soft-wall on biohydrogenation_6_1em6.** Run polish with
   the soft-wall on k10 at a few ε and λ values. Does it move rank-1
   off the bound? Does it find the truth-near row?

3. **Trace aggregate synthesis on slow_fast_6_1em4** — read the
   synthesis_log.csv if it exists. Confirm whether aggregates explicitly
   discover both basins or just stumble into them.

4. **Re-rank by `(saturation_count, err)` on the 300-cell sample.**
   Quantify the rank-1-oracle improvement. Compare to the
   `(polish_source_hc_idx == -1, err)` rerank from earlier.

5. **The 8% deep-failure cells.** Are they uniformly column-scaling
   problems, or different pathologies? Sample 5 and inspect.

Each of these is bounded (a few hours of work, no production code change).
None of them are big enough to be a "project" yet — they're scouting.
