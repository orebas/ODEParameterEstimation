# F1 — Recon of prior research on AMIGO2-only failure cases

Generated: 2026-05-04 during autonomous research run.

## Bottom line

**Most of the seed-strategy R&D in this conversation thread has been retreading
investigations the team already did in March-April 2026.** The prior research is more
mature than I gave it credit for. Three documents, taken together, already lay out:

1. The AMIGO2-only failure cases are a heterogeneous set requiring different fixes.
2. The "fit-rank picks wrong winner" failure mode is well-documented and partially fixed
   via finalist-set output.
3. There's a smoking-gun bug at `analysis_utils.jl:253` that drops truth-better candidates.

I should be building on this work, not duplicating it.

## Documents I should have read first

Pinned for future-me:

- **`temp_plans/2026-04-16_post_polish_research_memo.md`** — comprehensive arc of the
  post-polish work. Summary: shifted from "improve winner" to "improve set coverage";
  block consensus, tryhard-K, finalists, reasonable-frontier are the implemented stages.
- **`artifacts/diagnostics/cstr_crauste_deep_dive/summary.md`** — already classified
  CSTR (structural / observability / bounds — NOT seed-quality) and Crauste
  (basin-search / catastrophic derivatives — partly seed-coverage).
- **`artifacts/diagnostics/cstr_crauste_coord_failure_audit.md`** — for the failing
  `crauste_3_1em8` and `cstr_1_1em8` cases, identifies WHICH coordinates are the
  failures (mu_PE 850%, mu_LE 635%, etc.) — sloppy directions are now per-coord-named.
- **`artifacts/diagnostics/flexible_arm_brusselator_followup_2026-04-23.md`** — the
  smoking gun re: `analysis_utils.jl:253` MAX_ERROR_THRESHOLD discarding good
  candidates.
- **`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_*/`** — saved-pool sweep
  artifacts with substantive results across most relevant cases.

## The smoking gun: `analysis_utils.jl:253`

```julia
scored_results = _scored_results(result)
sorted_results = if isempty(scored_results)
    Any[]
else
    valid_results = filter(x -> x.err < MAX_ERROR_THRESHOLD, scored_results)
    if isempty(valid_results)
        sort(scored_results, by = _result_err_key)[1:min(MAX_SOLUTIONS, length(scored_results))]
    else
        sort(valid_results, by = _result_err_key)
    end
end
```

`MAX_ERROR_THRESHOLD = 0.5` (from `core_types.jl:63`). Behavior:

- If ANY candidate has `err < 0.5` → discard everything with `err >= 0.5`
- Else → keep top `MAX_SOLUTIONS` by err

On `flexible_arm_0_1em4`:
- Imported pool has candidates at 6.62% and 7.50% rel-err (both truth-better than the
  benchmark-selected winner)
- Both have fit `err > 0.5` (data noise + slow-mode mismatch)
- Two OTHER candidates have fit `err < 0.5` (lucky overfits)
- The gate keeps only those 2; the truth-better candidates are silently dropped before
  clustering / polish.

This is the mechanism the April followup memo identified as "the primary culprit."

## Per-case prior diagnoses (from cstr_crauste_deep_dive + sweeps)

### CSTR family (22 AMIGO2-only wins, 0 ODEPE wins)

- **Diagnosis**: structurally different. 1 observable, 3 states. Bottleneck is
  derivative-order failure even after direct-trig fallback (`cstr_derivative_only_after_direct_trig_failure`).
- **Pool quality**: All 100+ pool rows are box-violating (params outside [1e-5, 10]).
  Best-truth row exists but is at rank 66 of 101 (better-than-first count: 65).
- **NOT a seed-strategy problem**: the issue is observability + bounds enforcement.
  Polish doesn't help. Per the memo: "next issues are observability / latent-state
  treatment / bounds enforcement."

### Crauste (10 AMIGO2-only wins, 1 ODEPE-only)

- **Diagnosis**: catastrophic derivative errors at high orders (151% at order 4, even
  at noise=1e-8). Jacobian cond 1.9e15. Pool only has 13 rows at noise=1e-8, all
  box-violating.
- **At higher noise (1e-4, 1e-2)**: derivative err can reach 13597% at order 5, ODEPE
  errors reach 21746%.
- **Pool composition**: pool has 13-30 rows; truth-near rows DO appear after polish
  (best truth RMSE 2.92 at row 33 in odepe_polish), but the winner is wrong
  (171 polished rows total, only 33 are truth-better than first).
- **Mostly a basin-search problem**: more polish breadth helps; finalists-set output
  partly already works.

### Flexible_arm (9 AMIGO2-only wins)

- **Diagnosis**: pool DOES contain near-truth candidates (6.62-7.50% rel-err); they're
  just being discarded by `MAX_ERROR_THRESHOLD` gate.
- **Class C — ranking miss**. Fix: change the gate.

### HIV (8 AMIGO2-only wins)

- **Diagnosis**: large parameter space (10+ params), local optima. Per the memo:
  "ODEPE hits local optima". Not investigated as deeply as cstr/crauste.
- **Likely a basin-search problem** — multiple distinct algebraic branches; pool may
  not span them all.

### Forced_lotka_volterra (12 AMIGO2-only wins)

- **At noise=1e-2**: AMIGO2 wins 8/8. ODEPE errors 0.04-3.36 vs AMIGO2 <0.3%.
- **Not yet investigated in detail** in the prior artifacts I've seen.
- This is the **highest-signal case to investigate** — total ODEPE failure in a system
  ODEPE handles fine at lower noise. Almost certainly noise-amplification + derivative
  failure at order 3-5.

### daisy_mamil3 (9 AMIGO2-only wins)

- **At noise=1e-4 (3 wins)**: documented in the broad_mixed sweep. `daisy_mamil3_7_1em4`
  was specifically tagged "ODEPE near-miss" with rel ≈ 100%.
- **Mostly a basin-search / parameter-permutation problem** (similar to daisy_mamil4 but
  at higher noise).

### daisy_mamil4 (4 AMIGO2-only, **10 ODEPE-only** at noise=0)

- This is an ODEPE-WIN system. AMIGO2 permutes the k13/k14/k31/k41 parameters.
- **ODEPE's algebraic constraints are the strength here** — they prevent permutation.
- Not a seed-strategy target.

## The team's existing direction (from the April 16 memo)

The memo's "high-level arc":

1. ✅ Add new seed generators (block consensus, additive families)
2. ✅ Add ways to polish broader seed sets without collapsing to one winner
3. ✅ Shift evaluation from "did fit choose right winner?" to "is good basin in
   returned set?"
4. ✅ Replace fixed-rank truncation with baseline-preserving frontier admission
5. ✅ Separate `crauste`-style (basin) from `cstr`-style (structural) problems

Implementations exist:

- `_assemble_block_consensus_report` (`src/core/block_consensus_v2.jl:746`)
- `research_tryhard_finalists` (`src/core/benchmark_sweeps.jl:1788`)
- `_build_reasonable_tryhard_frontier` (`src/core/benchmark_sweeps.jl:1252`)
- `_cluster_tryhard_finalists` (`src/core/benchmark_sweeps.jl:1422`)

So **the seed-strategy machinery the user has been hoping I'd build is mostly already
there.** It's wrapped in research/sweep code, not in production-pipeline code, but the
algorithms exist and have been tested.

## What's actually missing or open

After all the prior work, what's still genuinely valuable:

### A. Fix `analysis_utils.jl:253` — almost-free lift

The `MAX_ERROR_THRESHOLD = 0.5` gate is a clear bug for high-noise cases. Fix options:

1. **Relative threshold**: `valid_results = filter(x -> x.err < k * min_err, scored_results)` — keep candidates within k× the best fit error.
2. **Quantile threshold**: keep top-N by err, period.
3. **Disable gate, rely on clustering**: if clustering already produces representatives,
   the gate may not be needed.

The April followup explicitly identified this. Whether it's been fixed since I'm not
sure — would need to check git log. Could be a 1-line fix.

### B. Promote research seed strategies to production gate path

The block consensus, frontier, finalists machinery is in `benchmark_sweeps.jl` (research
code, not production). If they're proven on cases like `daisy_mamil4_6_1em4`, they
should be in the production pipeline behind a flag.

### C. Investigate forced_lv at high noise

The 8/8 AMIGO2 dominance on forced_lotka_volterra at noise=1e-2 is the largest unexplained
signal. Not investigated in detail in prior artifacts. Worth a proper deep-dive.

### D. Higher-order algorithmic ideas (OUT-of-scope here)

The team's work has been about handling the existing pool well. Ideas like changing the
SI template, using different observable parameterizations, or non-stationary GP for
boundary derivatives are bigger lifts that may matter for some cases (cstr, crauste) but
aren't the immediate next step.

## Where I should focus my remaining time

Given I have ~3.5h left and the user wants real progress:

1. **Verify the threshold-gate hypothesis on a saved case** (~30 min): pick one case
   from the AMIGO2-only set where the gate likely bites (flexible_arm or daisy_mamil3_7
   at 1e-4), run my harness, check whether truth-near candidates exist with err > 0.5
   in the raw pool.
2. **Implement and test a relative-threshold fix on saved pools** (~60 min): if the
   gate bites, write a small one-line variant of `analyze_estimation_result` that uses
   `err < k × min_err` and re-evaluate. If this produces a better best-rel on multiple
   cases, the fix is essentially free.
3. **Investigate forced_lv at 1e-2** (~60 min): the unexplained high-noise dominance.
   Run my deep-dive harness on `forced_lotka_volterra_0_1em2`.
4. **Synthesize and write up** (~30 min): consolidated findings + recommendations.

This is more focused than my original F2/F3 plan and uses the existing artifacts as
foundation.
