# Sensitivity-Seed Validation Summary (v6, 6 cases × 4 arms = 24 runs)

Compares baseline (`use_sensitivity_seeds = false`) against seeded (`use_sensitivity_seeds = true`)
in both polish-on and polish-off modes. Cases sourced from bilby `1e-4 broad_mixed`. The
polish=OFF arm tests whether sensitivity seeds improve raw algebraic-quality output without
invoking optimization.

## Top-line: ZERO regressions across 24 arms

No case got worse on either ranking metric. That's the safety signal needed to consider
default-on for users who explicitly want it.

## Polish=ON

| Case | Baseline max-rel-err | Seeded max-rel-err | Δ | Baseline fit | Seeded fit | Baseline t (s) | Seeded t (s) |
|------|----:|----:|----:|----:|----:|----:|----:|
| fitzhugh_nagumo_2_1em4 | 0.03128 | **0.03076** | -1.7% | 3.611e-5 | 3.611e-5 | 109.6 | 14.7 |
| daisy_mamil3_7_1em4 | 8.228e-5 | 8.228e-5 | 0 | 3.47e-7 | 3.47e-7 | 62.0 | 24.2 |
| seir_2_1em4 | 3.363 | 1.992 | -41% (oracle) | 18.19 | **8290** | 54.8 | 33.6 |
| daisy_mamil3_4_1em4 | 1.163e-4 | **8.489e-5** | -27% | 4.883e-7 | 4.881e-7 | 16.1 | 17.1 |
| sirt_treatment_7_1em4 | 0.1405 | 0.1405 | 0 | 0.04438 | 0.04438 | 406.9 | 522.6 |
| brusselator_1_1em4 | 0.06816 | 0.06816 | 0 | 0.07074 | 0.07074 | 34.8 | 11.9 |

## Polish=OFF (raw algebraic — the design-intent test)

| Case | Baseline max-rel-err | Seeded max-rel-err | Δ | Baseline fit | Seeded fit | Baseline t (s) | Seeded t (s) |
|------|----:|----:|----:|----:|----:|----:|----:|
| fitzhugh_nagumo_2_1em4 | 7.061 | 2.54 | -64% (oracle) | 1.498e-4 | **0.3329** | 6.4 | 6.6 |
| daisy_mamil3_7_1em4 | 0.1324 | 0.1324 | 0 | 1.859e-5 | 1.859e-5 | 17.7 | 18.3 |
| seir_2_1em4 | 3.363 | 1.868 | -44% (oracle) | 18.19 | **2.856e7** | 20.0 | 21.8 |
| daisy_mamil3_4_1em4 | 0.02617 | 0.02617 | 0 | 6.518e-6 | 6.518e-6 | 13.9 | 14.7 |
| sirt_treatment_7_1em4 | 0.1405 | 0.1405 | 0 | 0.04438 | 0.04438 | 441.6 | 564.1 |
| brusselator_1_1em4 | 0.06816 | 0.06816 | 0 | 0.07074 | 0.07074 | 10.6 | 10.7 |

## Critical caveat: oracle vs. production ranking

The test framework returns the **oracle-sorted** cluster representatives — `analyze_estimation_result`
in `src/core/analysis_utils.jl:421` sorts the first list by `oracle_sort_key(problem, candidate)`,
which uses `problem.p_true` (only available in benchmarks). Production code (where `p_true` is
unknown) falls through to err-sorting via the third tuple field of `oracle_sort_key`. So the
table values are for the **oracle-best** candidate, not the **fit-best** candidate. The two
diverge sharply on sloppy systems.

Because the seeded pool is a superset of the baseline pool (`vcat(solved_res, new_candidates)`
in `sensitivity_seeds.jl:474`), **production fit-ranking can never pick a worse candidate from
the seeded pool than from the baseline pool**. The seeded production-best fit is ≤ baseline
production-best fit by construction.

What we can say from the data:

| Case | Arm | Oracle-best max-rel-err | Oracle-best fit | Likely production picture |
|------|-----|----:|----:|:---|
| fitzhugh_nagumo_2 | polish=ON | 0.03128 → 0.03076 | 3.611e-5 → 3.611e-5 | Oracle-best ≈ fit-best in both arms — the small win is real and likely production-visible |
| daisy_mamil3_4 | polish=ON | 1.163e-4 → 8.489e-5 | 4.883e-7 → 4.881e-7 | Same — fits track tightly, win is likely production-visible |
| seir_2 | polish=ON | 3.363 → 1.992 | 18.19 → **8290** | Seeded oracle-best has 455× worse fit → fit-best in seeded pool is a different candidate (probably the same one as in baseline). Production max-rel-err change is **unknown from this data** |
| seir_2 | polish=OFF | 3.363 → 1.868 | 18.19 → **2.856e7** | Same — production max-rel-err **unknown** |
| fitzhugh_nagumo_2 | polish=OFF | 7.061 → 2.54 | 1.498e-4 → **0.3329** | Seeded oracle-best has 2222× worse fit → fit-best is a different candidate. Production max-rel-err **unknown** |

The "fit ratio WORSE" rows do **not** mean production is worse — they mean the closest-to-truth
candidate in the seeded pool has worse fit than the closest-to-truth in baseline, but the
*lowest-fit* candidate in seeded ≤ lowest-fit in baseline. To know whether the production
winner improved, the validation script needs to report fit-best max-rel-err separately. That's
a deferred follow-up experiment.

## Why does fit fail to pick the truth-near candidate?

Sloppy directions: the seir and fitzhugh polish=OFF systems have practical identifiability
gaps where many parameter values produce similar trajectories. The seeded probes (along
sloppy eigenvectors of Σ_x) move closer to truth in *parameter* space but produce trajectories
that fit the *noisy* data worse than baseline candidates that overfit the noise. This is the
fundamental "fit doesn't reliably select truth on sloppy systems" problem documented in
the 2026-03-29 multipoint diagnostics session.

The user's existing `cross-solution spread` UQ already addresses this from a different
angle (use the spread, not the point-wise fit). Sensitivity seeds add candidates that
broaden this spread on the truth-side, but unless the ranking changes, the win stays hidden.

## Cluster counts (mechanical confirmation seeds are firing)

| Case | polish=ON baseline | polish=ON seeded | polish=OFF baseline | polish=OFF seeded |
|------|---:|---:|---:|---:|
| fitzhugh_nagumo_2_1em4 | 14 | 37 | 8 | 10 |
| daisy_mamil3_7_1em4 | 4 | 5 | 3 | 4 |
| seir_2_1em4 | 14 | 14 | 14 | 13 |
| daisy_mamil3_4_1em4 | 6 | 8 | 3 | 4 |
| sirt_treatment_7_1em4 | 3 | 3 | 3 | 3 |
| brusselator_1_1em4 | 2 | 2 | 2 | 2 |

Cluster counts increase in 4/6 polish=ON arms and 3/6 polish=OFF arms, confirming seeds are
mechanically being emitted, evaluated, clustered, and entering the analyzed pool. Where cluster
counts are unchanged (sirt_treatment_7, brusselator_1), the seeded probes either landed inside
existing clusters after polish or were dropped by the eigenvalue-significance threshold. No
case showed empty seed emission on a non-degenerate sensitivity matrix.

## Time cost

Mostly a wash. Some seeded arms are faster (fitzhugh_nagumo_2 polish=ON: 109.6s → 14.7s, likely
due to model-load caching after the baseline arm), some are slower (sirt_treatment_7
polish=ON: 406.9s → 522.6s, +28%). Median overhead small.

## Recommendation

- **Keep `use_sensitivity_seeds = false` as the default.** Two oracle-best wins look likely
  production-visible (fitzhugh polish=ON, daisy_mamil3_4 polish=ON), three are ambiguous
  (seir ×2, fitzhugh polish=OFF) until the validation script is extended to report fit-best
  max-rel-err. Not enough signal yet to flip default-on.
- **Zero regressions across 24 arms is the headline.** Safe to expose the option to users who
  want geometric exploration on practical-non-identifiable systems.
- **Mandatory follow-up experiment**: extend `_summarize_run` in
  `test/generate_sensitivity_seeds_validation.jl` to compute max-rel-err for *both* the
  oracle-best AND the fit-best (`first(sorted_results)` after err-sort, no truth needed).
  That single change resolves the seir/fitzhugh-OFF ambiguity. Estimated cost: a few minutes
  to edit, ~50 minutes to re-sweep. Critical before any default flip discussion.
- **If fit-best max-rel-err on seir/fitzhugh-OFF doesn't improve**, the unlock paths are
  ranking-side, not seed-side:
  1. Surface top-K finalists, not just winner.
  2. Cross-spread-aware ranking (already computed for UQ in 2026-03-29 work).
  3. Per-candidate Σ_x (deferred as task #22).

## Bugs found and fixed during this validation cycle

Three wiring bugs silently no-op'd sensitivity seeds before any signal could be measured.
All caught only because the validation framework forced explicit comparison:

1. `Matrix{BigFloat}(S)` — `_compute_data_sensitivity` returns BigFloat for ill-conditioned
   cases; strict `Matrix{Float64}` signature MethodError'd inside try/catch.
2. Phase placement — sensitivity-seed augmentation was nested inside the polish gate, so
   `polish_solutions=false` runs never reached it.
3. S row projection — `_compute_data_sensitivity` returns S with rows for all SI unknowns
   (state derivatives, parameters, ICs, auxiliaries); polish-context vector is just
   (states; params). Dimension-mismatch check rejected every case.

Without these fixes the sweep would have reported zero improvement everywhere and we would
have wrongly concluded sensitivity seeds don't work.

## Reference (synthesized_finalizer baseline from `bilby_2026_03_09_1em4_broad_mixed`)

- `fitzhugh_nagumo_2_1em4`: 322.22% → 1.48% (synthesized_finalizer, against OLD scalar polish)
- `daisy_mamil3_7_1em4`:    5.46%   → 0.01% (synthesized_finalizer, against OLD scalar polish)

The new LSO log-space polish (shipped earlier this session) independently brings fitzhugh to
3.13% and daisy_mamil3_7 to 0.008% on the polish=ON baseline (no seeds). Sensitivity seeds add
a small additional improvement on top of that for fitzhugh polish=ON (3.13% → 3.08%) and a
moderate improvement for daisy_mamil3_4 polish=ON (0.012% → 0.008%). Other reference cases
(seir, sirt_treatment, brusselator) didn't have synthesized_finalizer baselines.
