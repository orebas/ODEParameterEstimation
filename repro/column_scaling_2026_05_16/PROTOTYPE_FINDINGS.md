# Column-scaling diagnostic prototype findings (2026-05-16)

**Status:** Read-only investigation. No source-code changes made.
**Goal:** Confirm the cond(J) numbers in
[`docs/2026-05-01_variable_scaling_investigation.md`](../../docs/2026-05-01_variable_scaling_investigation.md)
hold under current code, and ask whether column rescaling would close the gap.
**Method:** For each of {biohydrogenation, daisy_mamil4, crauste}, call
`diagnose_sensitivity(pep)` (which computes the SI-template Jacobian at
truth via ForwardDiff), then compute cond(J · D) for two diagonal scalings:
- **Column-norm scaling:** `D_ii = 1/‖J[:, i]‖_2` (Bauer-Skeel optimal
  diagonal scaling).
- **Truth-magnitude scaling:** `D_ii = max(|truth_i|, 1.0)` (proxy for the
  "bound-based" choice in the doc).
**Script:** `diagnose_column_scaling.jl` in this directory.

## Headline numbers

| System | n_eqs × n_vars | eff_rank | cond(J) raw | cond(J·D) col-norm | improvement | cond(J·D) truth | improvement |
|---|---|---|---|---|---|---|---|
| biohydrogenation | 25 × 25 | 25 / 25 | **1.44 × 10⁹** | **6.81 × 10⁵** | **2114×** | 2.88 × 10⁸ | 5× |
| daisy_mamil4 | 32 × 32 | 32 / 32 | **1.65 × 10⁶** | 1.13 × 10⁶ | 1.5× | 1.65 × 10⁶ | 1.0× |
| crauste | 43 × 43 | **38 / 43** | 3.67 × 10⁸¹ | 3.11 × 10¹⁷ | (singular) | 1.21 × 10²¹ | (singular) |

Col-norm range (orders of magnitude across J's columns at the raw scale):
- biohydrogenation: **4.1 orders** (9.4e-4 to 11.6)
- daisy_mamil4: 0.66 orders (1.0 to 4.5)
- crauste: ill-defined (5 zero-norm columns)

## Per-system interpretation

### biohydrogenation — column scaling is a clear win

Bauer-Skeel column scaling drops cond(J) from 1.44 × 10⁹ to 6.81 × 10⁵ —
a **2114× improvement.** The improvement comes from balancing the column
norms: in raw J, the column for `k6_0` has norm 9.4 × 10⁻⁴ while `x5_2`
(state derivative) has norm 11.6 — a 4.1-orders-of-magnitude imbalance.
Column scaling drives all columns to unit norm and the cond drops directly.

The smallest singular value is σ₂₅ = 1.12 × 10⁻⁸, which is what makes the
raw cond large. After column scaling, the spectrum redistributes such that
σ₂₅/σ₁ ≈ 1.5 × 10⁻⁶ — orders of magnitude better.

**Truth-magnitude scaling only helps 5×.** This is because the truth
magnitudes (e.g. k5=0.5, k6=2, k10=5) don't reflect the column-norm
imbalance — they're all O(1), but the J-columns differ wildly because of
the polynomial structure (a small coefficient on k6 in some equation lets
J change slowly there). So a bound-based scaling (option 1 in the doc) is
substantially weaker than column-norm-based (option 2 in the doc) for this
system.

**Discrepancy with the doc:** The doc cited cond(J) = 4.5 × 10¹⁰; we measure
1.44 × 10⁹ under current code. ~30× lower. Possibly due to: SI-template
changes since 2026-05-01, different `max_deriv_level`, or
interpolator-evaluation point differences. Order-of-magnitude qualitative
finding (very ill-conditioned, dominated by column-norm imbalance) is
unchanged.

### daisy_mamil4 — column scaling barely helps

Column-norm scaling drops cond from 1.65 × 10⁶ to 1.13 × 10⁶ — only **1.5×**.
This is consistent with the **0.66-order col-norm range** (all columns are
within ~4× of each other in norm). The conditioning issue here is *not*
column scale; it's a genuine near-null direction (σ₃₂ = 5.6 × 10⁻⁶ — a
practical non-identifiability axis in the polynomial system itself).

**This refutes the column-scaling hypothesis for daisy_mamil4.** The
doc-quoted cond(J) ≈ 2 × 10⁶ matches our 1.65 × 10⁶ closely, but the
mechanism isn't column imbalance — it's a structural near-null direction
that diagonal scaling can't fix.

### crauste — rank-deficient, different problem

Raw cond(J) = 3.67 × 10⁸¹ — essentially singular. The SVD shows σ₃₈ =
1.7 × 10⁻⁵ but σ₃₉ … σ₄₃ all at 10⁻⁷⁷ (machine epsilon). Effective rank
is **38/43**; five columns of J are zero or near-zero. The "improvements"
reported in the table are meaningless because zero columns get assigned
arbitrary scaling.

This isn't a column-scaling problem. The SI template construction is
producing 5 dead variables. Fixing this needs **Level C** from the doc
(reformulate the algebraic problem — alternative derivative orders or
elimination ordering) or a pre-pass that drops zero-norm columns.

## Verdict

| Failure mode | System | Scaling helps? |
|---|---|---|
| Column-norm imbalance | biohydrogenation | **YES — 2000× cond reduction** |
| Near-null direction (practical non-id) | daisy_mamil4 | No — different problem |
| Structural rank deficiency | crauste | No — different problem |

**Column scaling is *not* a silver bullet** but it is a real, large win for
*one* of the three challenging systems (biohydrogenation), and possibly
others with similar polynomial structure. The doc's Level A
(variable-substitution wrapper) is likely worth implementing for that
class of problem.

## Recommendation for next steps

1. **Implement Level A bound-based scaling as opt-in first** (per the doc's
   "What to NOT do" — don't silently flip defaults). The bound-based
   choice from the doc is suboptimal vs column-norm-based (truth-magnitude
   gave only 5× vs column-norm's 2114× on bioh) but it's the cheapest to
   wire up because it needs no Jacobian evaluation. Worth testing as a
   baseline.

2. **Compute column-norm scaling lazily** during HC.jl preprocessing. The
   J at any feasible polynomial-system point gives a useful scale. This
   would buy most of the 2114× improvement.

3. **For crauste-class rank-deficient systems**, a separate diagnostic is
   needed before HC.jl runs: detect zero-norm columns and either drop them
   (effectively removing structurally-unidentifiable variables before HC.jl
   sees them) or warn the user.

4. **For daisy_mamil4-class near-null systems**, column scaling is not
   useful. These need the practical-identifiability framework (already in
   `diagnose()`'s cross-solution spread; see
   `_write_html_spread_section`) to flag them and either peg the
   non-identifiable parameter or report a CV-based credibility interval.

## Files in this directory

- `diagnose_column_scaling.jl` — the prototype script (read-only)
- `column_scaling_results.csv` — summary CSV: one row per (system, noise)
- `biohydrogenation_noise_*.txt` — per-column norms, truth proxies, full
  SVD spectrum (raw and after scaling)
- `daisy_mamil4_noise_*.txt` — same
- `crauste_noise_*.txt` — same
- `run.log` — Julia stdout for the diagnostic run
- This file: `PROTOTYPE_FINDINGS.md`

## Reproducibility

```
cd repro/column_scaling_2026_05_16/
julia --startup-file=no diagnose_column_scaling.jl
```

Takes ~3–5 minutes wall-clock on a multi-core machine. The noise=1e-8 and
noise=0 rows give identical cond numbers because `diagnose_sensitivity`
evaluates J at the *truth* point, not at the noisy data — noise affects
the data residual, not the J at truth.
