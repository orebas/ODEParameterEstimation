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
- `summarize_estimator_aware_nonlinear.jl` — variant-aware aggregation with
  explicit outcome taxonomy, usable rate, and conditional/unconditional
  coverage denominators.
- `diagnose_audited_lv_multipoint_uq.jl` — retained-root LV conditioning and
  GP-jet bias decomposition.
- [`../../docs/2026-08-15_estimation_uq_research_program.md`](../../docs/2026-08-15_estimation_uq_research_program.md)
  — promotion gates and the N=10 → N=60 → N=200 ladder.

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

## Optional research arms

The estimator-aware runners accept:

- `--pair-strategy=spread|boundary_order`; and
- `--lengthscale-factor=<positive Float64>`.

Defaults preserve production behavior. Non-default variants are encoded in the
result filename and payload, so paired arms cannot silently overwrite one
another. A useful first causal screen is `1.0, 0.9, 0.75, 0.6`; those values are
not production recommendations.

Example frozen canary:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl \
  --cases=lotka_volterra_5_1em6 \
  --arms=mp_solver_polish \
  --interpolator-pool=uq_only \
  --pair-strategy=boundary_order \
  --lengthscale-factor=0.75
```

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
