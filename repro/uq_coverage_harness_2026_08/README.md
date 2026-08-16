# UQ coverage/calibration harness (2026-08-13, Stream B item 2)

Empirical CI-coverage measurement for the UQ chain: N independent noise
replicates of (draw → estimate → GP jets → Σ_d → sensitivity S → Σ_x →
physicalized report), then per-coordinate z-scores and coverage of the
`UQ_CI_Z` (1.96 → nominal 95%) interval.

## Files

- `coverage_driver.jl` — self-contained driver. Entry points:
  - `run_coverage(pep_ctor; N, noise_level, value_source, estimator, …) → CoverageResult`
  - `print_coverage(result)` — per-coordinate coverage / mean z / sd z table.
  - `two_exp_pep()` — the TAC-theory anchor model (ẋᵢ = −kᵢxᵢ, y = x1 + x2;
    k2 ≫ k1 makes (x2, k2) the weakly-identified block).
  - `two_state_observed_pep()` — well-conditioned companion (`simple()`).
- `run_estimator_aware_nonlinear.jl` — selected-estimator SP/MP/polish campaign
  runner with atomic TOML records, structured timings, full covariance, and
  reliability-axis fields.
- `run_estimator_aware_peb_canaries.jl` — SHA-pinned loaders for audited frozen
  PEB paper cells. This is the scientific nonlinear panel; package registry
  constructors are routing stress only.
- `run_audited_repeated_uq.jl` — clean-revision, schema-v2 repeated-noise
  runner over the audited 750-row PEB models, with paired data hashes and
  optional research-only fixed SP/MP recipes.
- `supervise_audited_repeated_uq.jl` — per-cell Linux process-group wall/RSS
  supervisor with bounded whole-tree TERM/KILL and explicit failure records.
- `summarize_audited_repeated_uq.jl` — revision-safe aggregation of estimator
  accuracy, unconditional availability/coverage, full covariance, Mahalanobis,
  selection frequencies, timing, and memory.
- `audited_campaign_manifest_v1.toml` — predeclared H1/H2/H3/U10 cells,
  budgets, seeds, and advancement gates.
- `run_model_assisted_panel.jl` — paired unpolished/corrected/polished
  estimation study using the exact selected SP/MP artifact.
- `run_model_assisted_replicates.jl` — stable-seed, resumable repeated-noise
  wrapper for the same model-assisted cells.
- `summarize_model_assisted_replicates.jl` — truth-for-evaluation-only RMSE,
  pairwise improvement, and false-accept/false-reject aggregation.
- `summarize_model_assisted_polish.jl` — warm-up-aware paired polish accuracy
  and alternating-order steady-state timing aggregation.
- `campaign_io.jl` — atomic TOML sidecars with explicit optional-value
  encoding, shared by resumable campaign runners.
- `summarize_estimator_aware_nonlinear.jl` — variant-aware aggregation with
  explicit outcome taxonomy, usable rate, and conditional/unconditional
  coverage denominators.
- `diagnose_audited_lv_multipoint_uq.jl` — retained-root LV conditioning,
  bounded pair maps, point-count frontiers, fixed k=3 combinations, and the
  fixed-recipe lengthscale screen.
- [`../../docs/2026-08-15_estimation_uq_research_program.md`](../../docs/2026-08-15_estimation_uq_research_program.md)
  — promotion gates and the N=10 → N=60 → N=200 ladder.
- [`../../docs/2026-08-16_lv_multipoint_bias_results.md`](../../docs/2026-08-16_lv_multipoint_bias_results.md)
  — exact Stage 1--3 decisions for the frozen LV discovery cell.
- [`../../docs/2026-08-16_audited_repeated_uq_campaign.md`](../../docs/2026-08-16_audited_repeated_uq_campaign.md)
  — executable hard-model campaign, estimand, stop rules, and results ledger.

## Outcome accounting

Coverage summaries report both:

- **conditional coverage**, among finite usable intervals; and
- **unconditional coverage**, with unavailable/nonfinite outcomes retained in
  the denominator.

They also retain full covariance matrices, joint Mahalanobis statistics, usable
rate, and a reason taxonomy. Dropping failed rows from the denominator can make
an unreliable pipeline look calibrated and is not permitted for promotion.

An individual UQ sidecar records availability, numerical-linearization status,
interval-width status, selection scope, and calibration status separately.
Calibration is always `not_assessed_by_single_run`; `status=:ok` is not a
coverage certificate.

TOML has no null value. Campaign atomic writers preserve optional `nothing`
fields with the explicit string sentinel `__missing__`; downstream summaries
must treat that sentinel as unavailable, not as a scientific value.

## Optional research arms

The estimator-aware runners accept:

- `--pair-strategy=spread|boundary_order`; and
- `--lengthscale-factor=<positive Float64>`.

Defaults preserve production behavior. Non-default variants are encoded in the
result filename and payload, so paired arms cannot silently overwrite one
another. A useful first causal screen is `1.0, 0.9, 0.75, 0.6`; those values are
not production recommendations.

### Audited repeated-noise campaign

Use the audited runner—not the package-constructor pilot—for scientific
DAISY/receptor/biohydrogenation cells. It refuses a dirty ODEPE worktree by
default and fingerprints the complete estimator protocol. `historical_plus_uq`
checks selection/routing; because the historical winner may be Chebyshev or
AAAD-GPR, covariance claims use the explicitly narrowed `uq_only` AGPUQ pool.

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_audited_repeated_uq.jl \
  --cases=daisy_mamil4_7_1em6,receptor_binding_5_1em6,biohydrogenation_7_1em6 \
  --data-source=synthetic --seeds=8164101 --validate-only=true

julia --startup-file=no repro/uq_coverage_harness_2026_08/supervise_audited_repeated_uq.jl \
  --cases=daisy_mamil4_7_1em6,receptor_binding_5_1em6 \
  --arms=mp_solver_polish --interpolator-pools=uq_only \
  --data-source=synthetic --seeds=8164101,8164102,8164103 \
  --cell-wall-limit-seconds=1800 --cell-rss-limit-bytes=17179869184 \
  --machine-hour-budget=24 --out=audited_h2_primary_20260816
```

The fixed-artifact CLI is `--fixed-sp-row=<row>` or
`--fixed-mp-rows=<row,row>`, optionally with
`--fixed-interpolator=agp_uq`. Fixed and adaptive cells are distinct protocol
groups. Small-N results are qualification/reconnaissance only; the manifest's
N=60 recipes are prepared but not authorized.

Example frozen canary:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl \
  --cases=lotka_volterra_5_1em6 \
  --arms=mp_solver_polish \
  --interpolator-pool=uq_only \
  --pair-strategy=boundary_order \
  --lengthscale-factor=0.75
```

### Model-assisted correction

The model-assisted runner compares the selected unpolished pilot, literal IFT
one-step update, same-branch local polynomial re-solve, and fixed-seed
trajectory polish from both the original and corrected candidates. It uses
audited benchmark constructors with paired synthetic additive-noise draws.
Corrected UQ remains deliberately unavailable until the
pilot-through-correction influence is derived and tested.

The runner retains both raw corrected candidates. Its conservative
`model_assisted_screened` arm is present only when the lower-SSE corrected
candidate also improves on the reconstructed pilot's observed-data trajectory
SSE. This is a truth-free catastrophe screen, not a guarantee of lower
parameter error or faster downstream polishing.

```sh
julia --startup-file=no \
  repro/uq_coverage_harness_2026_08/run_model_assisted_panel.jl \
  --cases=lotka_volterra_5_1em6,fitzhugh_nagumo_9_1em6,slow_fast_5_1em6,receptor_binding_5_1em6 \
  --noises=1e-6,1e-4,1e-2 --polish=true
```

Cells are written atomically and skipped on resume. Polish order alternates by
cell so compilation and warm-cache effects do not systematically favor the
corrected seed. When cases are launched in separate processes, use
`--cell-index-offset=1` on every other process to preserve that alternation.

The repeated-noise wrapper makes the seed list independent of case order, so
models can be partitioned across processes without changing their draws:

```sh
julia --startup-file=no \
  repro/uq_coverage_harness_2026_08/run_model_assisted_replicates.jl \
  --cases=fitzhugh_nagumo_9_1em6 --noises=1e-6 \
  --seed-start=8163100 --replicates=10 --polish=false \
  --out=model_assisted_n10_20260816

julia --startup-file=no \
  repro/uq_coverage_harness_2026_08/summarize_model_assisted_replicates.jl \
  --dirs=repro/uq_coverage_harness_2026_08/results/model_assisted_n10_20260816 \
  --out=repro/uq_coverage_harness_2026_08/results/model_assisted_n10_20260816_summary.toml
```

Schema-v2 cells also record `model_assisted_screened_policy`: the accepted
correction when the trajectory-SSE screen passes, otherwise the original
pilot. This is the actual deployable fallback policy; the raw corrected and
accepted-only records remain available separately.

The conditional repeated-polish follow-up has a separate aggregator. It
excludes the declared warm-up seed, reports paired availability and final
estimate agreement, and keeps the alternating-order steady-state timings:

```sh
julia --startup-file=no \
  repro/uq_coverage_harness_2026_08/summarize_model_assisted_polish.jl \
  --dirs=repro/uq_coverage_harness_2026_08/results/model_assisted_polish_vdp_n5_20260816 \
  --warmup-seeds=8163200
```

## Audited LV staged diagnostics

The bounded mechanism maps inspect only 15 ranked pairs:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl \
  --pair-map --scope=spread15
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl \
  --pair-map --scope=boundary15
```

Build the k=1:4 structural frontier first, then compute mixed volume only for
the advancing k=2/3 comparison:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl \
  --frontier --points=1,2,3,4 --mixed-volume=false
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl \
  --frontier --points=2,3 --mixed-volume=true
```

The controlled k=3 and fixed-k=2 lengthscale screens are:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl --k3-screen
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl --k3-augment
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_audited_lv_multipoint_uq.jl \
  --lengthscale-screen --indices=25,635 --factors=1.0,0.9,0.75,0.6
```

Matched adaptive default/0.6 canaries use `run_estimator_aware_peb_canaries.jl`
with the same case, arm, pool, and output directory, changing only
`--lengthscale-factor`. Exact checked-in records are under `results/`:

- `lv_stage1_spread15_20260815.toml`
- `lv_stage1_boundary15_20260815.toml`
- `lv_stage2_frontier_nomv_20260816.toml`
- `lv_stage2_frontier_k2_3_mv_20260816.toml`
- `lv_stage2_k3_fixed_combos_20260816.toml`
- `lv_stage2_k3_selected_pair_augmentation_20260816.toml`
- `lv_stage3_k2_lengthscale_screen_20260816.toml`
- `lv_stage3_adaptive_canary_20260816/`

## Modes

- `value_source = :estimate` (default) — the production conditioning shipped
  2026-08-13 (`10c7380`): S evaluated at (θ̂, x̂ jets, GP data jets).
- `value_source = :oracle` — truth-conditioned; this is the mode behind the
  TAC-theory PHASE3_CALIBRATION anchor numbers (95% well-conditioned block,
  82% weak block at 1% noise, N=100). Comparing the two modes on the same
  seeds quantifies the estimate-conditioning effect — paper-relevant.
- `estimator = :nls_polish` (default) — forward-solve least squares started
  at truth; cheap enough for N=100. The estimator is a stand-in: the UQ chain
  under test is exactly the production one.
- `estimator = :full_pipeline` — full `analyze_parameter_estimation_problem`
  with `compute_uncertainty = true` per replicate (slow; paper-grade).

## Gate smoke

`test/test_uq_coverage_smoke.jl` includes this driver and runs the N=20
two_exp sweep inside the full FAST gate with loose coverage bands, so
calibration breakage (crashes, zero coverage, non-finite σ) turns the gate
red. They are breakage tripwires, not calibration assertions; the paper-grade
numbers come from N≥100 runs of this driver.

Baseline that set the bands (2026-08-13, estimate-conditioned, :nls_polish,
N=20, noise 1%, datasize 61, t ∈ [0,1], seeds 7000+1..20, wall ≈ 61 s):

| coord | coverage | mean z | sd z |
|-------|----------|--------|------|
| k1    | 100%     | −0.025 | 0.43 |
| k2    | 100%     | −0.097 | 0.49 |
| x1    | 100%     | −0.035 | 0.46 |
| x2    | 100%     | +0.031 | 0.47 |

20/20 replicates reported (2 `:wide_ci`). Note sd(z) ≈ 0.46 ≪ 1: at this
mild config σ̂ over-estimates the NLS-polish estimator spread ~2× —
conservative CIs, the OPPOSITE direction from the TAC anchor's weak-block
underestimate (its config has late shooting times where the fast mode is
dead). Coverage-band tripwires in the smoke: reports ≥ 18/20, per-coordinate
coverage ≥ 0.7, |mean z| ≤ 1.0, sd z ∈ [0.05, 2.5].

## Known limitations (documented, expected)

- Weak-block undercoverage (~82% at anchor settings) is the honest residual:
  estimator bias (mean z ≈ −0.74 for k2) + covariance underestimate
  (sd z ≈ 1.25) from first-order delta method + plug-in GP hyperparameters.
  Remedies (bias correction, second-order term, η̂ uncertainty) are future
  work — see the TAC-theory PHASE3_CALIBRATION.md.
- `nls_polish_estimate` assumes observable RHS are time-invariant expressions
  of (states, params).
