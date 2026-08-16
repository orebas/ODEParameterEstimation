# Estimation and estimator-aware UQ research program

Date: 2026-08-15

Status: executable staged protocol. Stages 1--3 are complete on the frozen LV
discovery cell; see
[`2026-08-16_lv_multipoint_bias_results.md`](2026-08-16_lv_multipoint_bias_results.md).
The clean-revision hard-model repeated-noise campaign and its exact stop rules
are specified in
[`2026-08-16_audited_repeated_uq_campaign.md`](2026-08-16_audited_repeated_uq_campaign.md).
The research-only model-assisted branch and its first multi-model discovery
screen are recorded in
[`2026-08-16_model_assisted_correction_discovery.md`](2026-08-16_model_assisted_correction_discovery.md).
The numerical consistency repair is scoped to explicitly configured AGPUQ and
leaves ordinary estimator interpolators on their historical path; all
statistical estimator changes remain opt-in until the promotion gates below
are met.

Read first:

- [`2026-08-14_gp_jet_bias_decision_note.md`](2026-08-14_gp_jet_bias_decision_note.md)
- [`2026-08-14_estimator_aware_uq.md`](2026-08-14_estimator_aware_uq.md)
- [`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md)

## Objective

Improve derivative-based algebraic estimation where the improvement is either
Pareto-positive or available behind an explicit, bounded-cost option, while
continuing estimator-aware uncertainty quantification for the estimator that
actually produced returned rank one.

The program distinguishes four questions that must not be collapsed:

1. Did the software retain and route the selected estimator correctly?
2. Is the numerical linearization trustworthy for this fitted problem?
3. Are the reported intervals finite and operationally useful?
4. Do they achieve repeated-sampling coverage in this regime?

A single run can answer the first three only. Calibration is an empirical
property of a frozen model/noise/estimator protocol.

## Invariants

- The UQ target is `analysis.returned_results[1]`, never a fresh best-SSE pick
  from the raw candidate pool.
- SP, MP, trajectory polish/direct, and branch-completed estimators use their
  own retained influence route. Unsupported routes return typed
  `UQUnavailable`; they do not silently receive SP covariance.
- Truth is used for validation and coverage only. Operational scaling and
  practical-identifiability diagnostics use the selected estimate.
- Default estimator policy is unchanged by research arms. Every statistical
  alteration is named in options and recorded in the result sidecar.
- Paired comparisons reuse data and seeds. Runtime comparisons use structured
  per-run timing, not fixed arm order or warmed-process wall time.
- Frozen PEB generators, data, and historical metadata are SHA-verified before
  a scientific cell runs.

## Implemented experimental surface

### Default numerical repair

For the explicitly configured AGPUQ route, squared-exponential
marginal-likelihood optimization and final factorization use one explicit
covariance-matrix recipe. The ordinary non-UQ interpolators retain their
historical path so this repair does not perturb the default estimator pool.
Cholesky fallback jitter is relative to matrix scale. Every retained AGPUQ
interpolant records:

- fitted and used lengthscale;
- absolute Cholesky jitter and `jitter / learned_noise_variance`;
- retained-factor reconstruction residual;
- whether hyperparameter optimization converged.

Material relative jitter is visible as its own warning/telemetry axis. It does
not by itself invalidate an otherwise accurate retained linear solve; repeated
coverage decides whether that regularization is statistically consequential.
This repairs an unintended estimator mismatch; it is not claimed to remove
statistical smoother bias.

### Opt-in estimator arms

- `gp_derivative_lengthscale_factor`: defaults to `1.0`. Values below one run a
  frozen-multiplier derivative-undersmoothing arm after ordinary
  function-value marginal-likelihood fitting. Signal/noise variances are held
  at their fitted values in this causal screen.
- `multipoint_pair_strategy`: defaults to historical `:spread` behavior.
  `:boundary_order` retains physical time separation while penalizing points
  whose one-sided boundary support is short relative to fitted GP lengthscale
  and required observed-jet order.
- `multipoint_n_points` and `multipoint_max_pairs` remain the public structural
  controls for trading derivative order against polynomial-system size.

The optional arms are research mechanisms, not recommended production
settings. In particular, `0.75--0.6` is a promising region from one oracle LV
mechanism screen, not a universal tuning rule.

## Results through 2026-08-16

- The default LV multipoint estimate is excellent (0.0102% worst relative
  parameter error). Its `2.82e7` raw Jacobian condition number does not signal
  failed arithmetic: row/column equilibration gives `109`, and Float64 IFT
  agrees with a 256-bit solve to `3.4e-14` relative.
- The bounded `:boundary_order` arm failed Stage 1; it does not reliably select
  the accurate basin. The historical top-15 `:spread` set already contains
  viable pairs, so the 190-pair expansion was skipped.
- Three points lower the required observed derivative order from 3 to 2 at the
  same mixed volume of 3. The viable `[25,267,635]` local branch is centered
  but has coordinate standard errors up to about 190 times the two-point
  recipe, so it remains research-only.
- On fixed rows `[25,635]`, shortening the SE lengthscale to 0.75--0.6 removes
  most projected noiseless smoother bias while widening standard errors about
  2--4 times. In matched adaptive canaries, factor 0.6 reselected `[8,635]`,
  increased worst point error from 0.0102% to 0.0455%, reduced max one-run
  `|z|` from 2.57 to 0.772, and added 2.9% structured time.
- These are discovery results. No N=60 or default change is authorized until
  a fixed factor or oracle-free rule is predeclared and survives held-out
  audited-model checks.
- The audited DAISY/receptor hard-model campaign confirms that conclusion on
  models where unpolished estimation is excellent. At the default AGPUQ
  lengthscale both models were 5/5 usable and accurate with invariant MP pairs,
  yet both had 0/5 joint 95% coverage and coherent mean z-shifts as large as
  4.96. This rules out branch switching and failed numerical linearization as
  the primary explanation.
- With those pairs fixed, the opt-in `0.6` lengthscale factor kept all ten
  estimates below `1e-3` error while improving joint coverage from 0/5 to 4/5
  for DAISY and 5/5 for receptor; mean Mahalanobis fell from 43.36 to 16.58 and
  from 52.63 to 9.68, respectively. This is causal evidence for GP-jet smoother
  bias, but the factor was chosen with truth in view. The full execution record
  and checked-in summaries are in
  [`2026-08-16_audited_repeated_uq_campaign.md`](2026-08-16_audited_repeated_uq_campaign.md).

## Audited model panel

Use the frozen paper benchmark rather than known-flaky package registry models.
The harness currently contains:

| Cell | Historical winning seed | Reason in panel |
|---|---|---|
| `lotka_volterra_5_1em6` | MP, rows `[36,635]` in saved metadata | Main GP-jet bias/mechanism cell |
| `fitzhugh_nagumo_9_1em6` | MP | Nonlinear MP external check |
| `slow_fast_5_1em6` | SP, row `223` | Serious low-noise SP control |
| `daisy_mamil4_7_1em6` | MP, Chebyshev AICc | Excellent unpolished estimate; conditioning stress |
| `biohydrogenation_7_1em6` | MP, Chebyshev BIC | Excellent unpolished estimate; conditioning stress |
| `receptor_binding_5_1em6` | MP, AAAD-GPR | Independent nonlinear MP structure |

The original `1e-4` LV/VDP/FHN canaries remain useful route and noise-regime
checks. They are not the sole evidence base for estimator quality.

## Stage 0: software and numerical gates

Required before any Monte Carlo campaign:

1. Full package gate and seeded full-scale benchmark smoke are green.
2. Actual `UncertaintyReport` metadata serializes through JSON3; all nonfinite
   values become JSON `null`.
3. Explicit SE assembly agrees with a 256-bit reference on a deterministic
   matrix test.
4. The retained Cholesky factor reconstructs its advertised noisy+jittered
   matrix to relative residual at most `1e-10`.
5. Scaling a forced-indefinite test matrix scales first-retry jitter by the same
   factor.
6. Historical `:spread` pair ordering is unchanged, including uneven grids.
7. Each frozen PEB entry passes all three artifact hashes and constructs a data
   problem with the expected row and coordinate counts.

Failure stops the research ladder. A Monte Carlo result cannot validate broken
calculus or a changed estimand.

## Stage 1: deterministic LV mechanism map

Freeze the audited LV data, fitted hyperparameters, exact MP root, and selected
template. For every production anchor, and then every production pair, record:

- time and boundary distance in fitted lengthscales;
- maximum required observed derivative order;
- GP factorization telemetry;
- signed noiseless jet bias by order;
- sampling covariance of the retained fixed smoother;
- exact-root `S*b` and `S*Sigma_d*S'`;
- raw and row/column-equilibrated `cond2(Jx)`;
- Float64 versus 256-bit IFT disagreement;
- actual root error and first-order prediction error.

First inspect the 15 production-ranked pairs. Expand to all
`binomial(20,2)=190` only if those 15 contain no accurate low-bias interior
pair. This prevents a large homotopy sweep without a decision it can change.

Decision: a boundary/stability score advances only if it rejects the known bad
anchor without excluding every accurate branch and uses no oracle quantities at
selection time.

## Stage 2: structural point-count frontier

For `multipoint_n_points = 1:4`, build the noise-frontier structure without HC
first. Record:

- maximum observed derivative order;
- equation, solve-variable, and data-variable counts;
- mixed volume when available;
- construction time and memory.

Advance a 3- or 4-point configuration only if it reduces dependence on order-3
jets (preferably to order 2 or below) without a prohibitive mixed-volume or
construction-cost jump. Then solve one to three frozen interior combinations
and compare branch residual, estimate error, projected bias, and runtime.

## Stage 3: paired fixed-artifact estimator screen

On LV first, compare the same data/root recipe under:

| Arm | Pair policy | Lengthscale factor |
|---|---|---:|
| repaired default | `:spread` | `1.0` |
| pair only | `:boundary_order` | `1.0` |
| undersmoothing only | `:spread` | `0.9`, `0.75`, `0.6` |
| combined | `:boundary_order` | best non-oracle candidate |
| trajectory comparator | same algebraic basin, then polish | n/a |

For the causal lengthscale screen, fitted signal/noise parameters remain fixed.
The screen reports bias, variance, RMSE, standardized projected bias, branch
success, and structured runtime. A setting is not selected by the same truth
errors later used to claim coverage; convert any promising region into a
predeclared stability rule before Stage 4.

Performance policy:

- Pareto improvements may advance directly.
- A default candidate should add no more than about 10% median structured
  estimation time and no material memory regression across the audited panel.
- An explicitly enabled robust arm may spend up to 25% more median time if it
  materially reduces worst-coordinate error or unavailable-UQ rate.
- More expensive arms stay research-only and must report their actual cost.

## Stage 4: repeated-noise ladder

Use independent noise draws and paired seeds across arms.

### N = 10: plumbing and catastrophic-failure screen

This stage can reject an arm, not certify calibration. Require:

- no route/provenance mismatch;
- no serialization failure;
- at least 9/10 usable UQ outcomes;
- no repeated branch catastrophe;
- finite full covariance for every usable replicate;
- runtime and memory within the declared arm budget.

### N = 60: fixed-pair calibration decision

Freeze the pair/rule and estimator recipe before running. Report:

- unconditional usable rate and reason taxonomy;
- conditional and unconditional marginal 95% coverage;
- median `abs(z)`, mean `z`, and SD of `z`;
- empirical covariance versus mean reported covariance;
- joint Mahalanobis distribution/coverage;
- estimator bias, RMSE, and branch-success rate;
- GP jitter/noise and factorization-residual distributions;
- structured time and maximum RSS.

Indicative advance criteria, applied with uncertainty rather than as sharp
scientific laws:

- usable rate at least 90%;
- no coordinate with marginal coverage below 85%;
- worst-coordinate standardized mean bias below 0.5;
- no coherent role-specific under/over-dispersion left unexplained;
- no material point-estimate regression versus the repaired default.

### N = 200: adaptive-selection confirmation

Only promoted configurations reach this stage. Refit GP hyperparameters and
rerun point/pair selection in every replicate. This measures the variability
omitted by fixed-artifact conditional UQ. Report the same metrics as N=60 plus
selection frequencies and conditional results by selected estimator kind/pair.

## Stage 5: external validity

Repeat the promoted default and at most two opt-in arms on two or three audited
serious cells where historical unpolished estimation was excellent. The first
choices are slow-fast (SP control), receptor binding (MP), and one of
daisy_mamil4/biohydrogenation (conditioning stress). Do not promote a rule from
LV alone.

## Model-assisted correction: gated design branch

The research-only one-step correction

```text
b_hat(theta0) = W f_theta0 - L f_theta0
d_corrected    = W y - b_hat(theta0)
```

is now implemented as an explicit post-selection prototype. It changes the
estimator and its influence contains both the direct `W` term and the
pilot-through-correction term. It remains outside `EstimationOptions` and the
production candidate pool. A first one-draw screen found strong low-noise
improvement on FHN and smaller improvements on slow--fast/Van der Pol, but
a sharp breakdown by `1e-5` and uniform regression or failure at
`1e-4`/`1e-2`. Its in-sample trajectory screen catches large failures but is
not a parameter-risk certificate; see the linked discovery note.

Before it may return intervals it needs:

1. a retained typed artifact for pilot, model trajectory, correction, and
   selected branch;
2. a derived and tested child influence map, or a complete refit bootstrap;
3. perturb-and-refit finite-difference agreement on a tiny ODE;
4. fixed-pair N=60 coverage with pilot/correction refit each replicate.

Until then it must return typed UQ-unavailable rather than reuse the old MP
covariance under a new estimator name.

## Commands

Core gates:

```sh
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/test_gp_factorization_consistency.jl"); include("test/test_estimator_aware_uq.jl"); include("test/test_options_contracts.jl")'
julia --startup-file=no -e 'include("test/runtests.jl")'
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/benchmark_smoke.jl")'
```

The supervised repeated-noise commands, case-specific hard-model ladder, and
resource limits live in the dated campaign record linked above.

Audited canary examples:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl --cases=lotka_volterra_5_1em6 --arms=mp_solver_polish --interpolator-pool=uq_only
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_estimator_aware_peb_canaries.jl --cases=lotka_volterra_5_1em6 --arms=mp_solver_polish --interpolator-pool=uq_only --pair-strategy=boundary_order --lengthscale-factor=0.75
```

Never overwrite an arm: non-default pair/lengthscale settings are encoded in
the atomic result filename and in the TOML payload.

## Promotion record

Every promoted change needs a dated table containing:

- exact commit and frozen artifact hashes;
- predeclared cells, noise levels, seeds, and sample sizes;
- estimator identity and selected-point distribution;
- estimation accuracy and performance deltas;
- availability, numerical validity, interval width, and calibration as separate
  columns;
- reasons for unavailable or nonfinite outcomes in the denominator;
- the explicit production/default/opt-in decision.

No single `status=:ok` or `status=:degenerate` value substitutes for that table.
