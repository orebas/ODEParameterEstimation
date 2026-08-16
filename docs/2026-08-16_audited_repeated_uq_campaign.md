# Audited repeated-noise estimator-aware UQ campaign

Date: 2026-08-16

Status: infrastructure implemented. H0 is green: the full package gate passed
1,621/1,621 and the seeded full-scale benchmark smoke passed 10/10. Staged
scientific cells must run from the final clean commit before results can be
interpreted.

This is the execution record for Stages H0--H3 and U10 of the broader
[`2026-08-15_estimation_uq_research_program.md`](2026-08-15_estimation_uq_research_program.md).
The machine-readable protocol is
[`../repro/uq_coverage_harness_2026_08/audited_campaign_manifest_v1.toml`](../repro/uq_coverage_harness_2026_08/audited_campaign_manifest_v1.toml).

## Question and estimand

The hard-model panel asks whether selected-estimator UQ remains available and
numerically coherent on audited models for which unpolished algebraic
estimation historically worked well. It does not substitute the package's
known-flaky registry examples for benchmark evidence.

The scientific UQ estimand in this campaign is the returned rank-one estimator
from the explicitly UQ-capable AGPUQ pool, including whether that estimator is
SP or MP and its exact selected rows. The `historical_plus_uq` arm is a separate
selection/routing contract check. A historical Chebyshev or AAAD-GPR winner may
correctly return `UQUnavailable`; that is not evidence about the AGPUQ
estimator's covariance and must not be silently relabelled as such.

Fixed-row recipes are research-only `RunContext` contracts. They never change
ordinary `EstimationOptions` defaults. Adaptive cells refit the GP and rerun
point/pair selection in each replicate.

## Panel

| Cell | Role | Audited historical evidence | Campaign caveat |
|---|---|---|---|
| `daisy_mamil4_7_1em6` | first-wave MP conditioning test | 10/10 final-v2 cells below `1e-3`; selected two-point MP seed near `9.14e-6` max coordinate error | historical winner is Chebyshev AICc, so exact UQ uses a changed AGPUQ pool |
| `receptor_binding_5_1em6` | independent nonlinear MP test | all ten full-pool cells MP and below `2.29e-4` | this is the separately observed M=1 control, not the expensive aggregate M=2 branch model |
| `biohydrogenation_7_1em6` | conditional stress cell | historical selected seed near `1.24e-4` max coordinate error | `x7` is structurally unidentifiable and excluded from accuracy/coverage gates; use the declared `1e-8` fallback only after the named `1e-6` pilot |

`repressilator_7_1em8` is a possible later N=1 reconnaissance cell after it is
added to the pinned catalog and its current wall/RSS are measured. Crauste is
excluded from repeated-noise UQ: the audited estimation evidence is already
catastrophic, so it would test failure taxonomy rather than interval validity.

All cells use the exact 750-row PEB grids. Downsampling is prohibited for this
campaign because it can change the selected basin. Synthetic noise reproduces
the frozen PEB generator's additive, signed-per-observable-mean convention.
Every master seed is mapped through SHA-256 to a case-specific RNG seed, and
the generated data hash must match across all paired arms.

## Implemented controls

`run_audited_repeated_uq.jl` provides:

- SHA-verified frozen benchmark equations, clean trajectories, noisy data,
  generators, and metadata;
- case-order-independent paired synthetic draws;
- exact configuration fingerprints containing the ODEPE commit and worktree
  state, frozen PEB SHA, estimator arm, point policy, noise source, seed, and
  optional fixed selection recipe;
- strict resume (an existing path with a different fingerprint is an error),
  atomic schema-v2 records, and a pre-estimation `running` record;
- full covariance, selected identity/lineage, exact artifact-match checks,
  coordinate errors, reliability axes, GP telemetry, structured timing, and
  process memory;
- fail-fast contract errors for selected-result, fixed-recipe, or artifact
  mismatches.

`supervise_audited_repeated_uq.jl` launches each cell in its own Linux process
group. It samples aggregate descendant RSS, enforces a 30-minute/16-GiB default
limit, performs bounded TERM then KILL of the whole tree, verifies death, and
turns the worker's `running` record into an explicit timeout/resource outcome.
An infrastructure failure before that record exists is kept in a separate
ledger and stops the campaign.

`summarize_audited_repeated_uq.jl` refuses duplicate seeds or changing UQ
coordinate order within a protocol group. Groups include the code/frozen-data
revisions and all selection controls, so different estimators cannot be pooled
silently. It reports:

- estimate and UQ availability rates plus reason taxonomy;
- accuracy-at-`1e-3`, estimator bias/RMSE, and relative-error summaries;
- conditional and unconditional marginal coverage, mean/SD z, and median
  absolute z;
- empirical versus mean reported covariance;
- conditional and unconditional joint Mahalanobis coverage;
- selected-estimator/pair frequencies, linearization acceptance, GP
  jitter/noise, structured wall time, and peak process-tree RSS.

## Numerical interpretation

Raw condition number is retained but is not by itself a failure certificate.
Each retained IFT/Hessian solve now records raw condition, one-pass row/column
equilibrated condition, and normwise backward error. A large raw condition with
acceptable equilibrated condition and backward error is labelled
`scale_sensitive_conditioning`; intrinsic equilibrated ill-conditioning,
large backward error, nonfinite arithmetic, or a concerning
condition-times-error bound degrades numerical reliability.

GP Cholesky jitter relative to learned observation noise is also a separate
warning axis. Material jitter is evidence about the smoother/factorization and
must be inspected in coverage results, but it does not alone prove that the
retained algebraic or optimizer linear solve failed.

## Stages and stop rules

### H0: software and data preflight

Required before any scientific cell:

1. focused SP, exact MP, actual trajectory-polish, actual direct-optimizer, and
   branch-composition UQ tests pass;
2. campaign seed/fingerprint/resume, JSON/TOML serialization, summary
   denominators, and process-tree death tests pass;
3. all three frozen cases validate at 750 rows and emit deterministic data
   hashes;
4. the full package gate and seeded benchmark smoke pass on the exact commit;
5. the ODEPE worktree is clean. `--allow-dirty=true` is smoke-only and cannot
   produce scientific evidence.

### H1: one frozen qualification cell per case

Run both `historical_plus_uq` and `uq_only` at each case's catalog noise. Stop
globally on a hash, identity, artifact, serialization, or process-tree-death
mismatch. A case advances only if the UQ-only arm returns an estimate with all
identifiable-coordinate relative errors at most `1e-3`, exact selected
artifact identity, finite covariance, and no catastrophic boundary saturation.
A typed numerical warning may advance for diagnosis, not as calibration proof.

### H2: N=3 synthetic reconnaissance

Run DAISY and receptor at `1e-6`. Run one named biohydrogenation pilot at
`1e-6`; if the route is valid but accuracy does not qualify, use the
predeclared N=3 fallback at `1e-8`. Stop a case if at least two of three cells
have no estimate/nonfinite UQ, exceed `1e-3` max identifiable-coordinate error,
hit resource limits, or undergo a branch catastrophe. Advancement requires
3/3 completed finite covariances and at least 2/3 accurate estimates. These
three draws are reconnaissance, never a coverage claim.

### H3: N=5 confirmation

Only advancing DAISY/receptor cases run. Require at least 4/5 usable exact UQ
reports and accurate estimates, stable resources, and no obvious coherent
large-z bias. N=5 still does not certify calibration.

### U10 and later work

The manifest prepares an N=10 catastrophic-failure screen on established
audited SP/MP/polish cells. It requires at least 9/10 usable UQ outcomes.
N=60 fixed-recipe cells are recorded but explicitly not authorized by this
stage. No N=60 or N=200 run begins merely because smaller-N coverage happens to
look favorable.

## Commands

Validate frozen inputs and deterministic synthetic draws without estimation:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_audited_repeated_uq.jl \
  --cases=daisy_mamil4_7_1em6,receptor_binding_5_1em6,biohydrogenation_7_1em6 \
  --data-source=synthetic --seeds=8164101 --validate-only=true
```

Run H1 under process-tree supervision from a clean commit:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/supervise_audited_repeated_uq.jl \
  --cases=daisy_mamil4_7_1em6,receptor_binding_5_1em6,biohydrogenation_7_1em6 \
  --arms=mp_solver_polish --interpolator-pools=historical_plus_uq,uq_only \
  --data-source=frozen_noisy --seeds=8164101 --detailed=true \
  --cell-wall-limit-seconds=1800 --cell-rss-limit-bytes=17179869184 \
  --machine-hour-budget=24 --out=audited_h1_20260816
```

Run the primary H2 cells only after H1 is reviewed:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/supervise_audited_repeated_uq.jl \
  --cases=daisy_mamil4_7_1em6,receptor_binding_5_1em6 \
  --arms=mp_solver_polish --interpolator-pools=uq_only \
  --data-source=synthetic --seeds=8164101,8164102,8164103 \
  --cell-wall-limit-seconds=1800 --cell-rss-limit-bytes=17179869184 \
  --machine-hour-budget=24 --out=audited_h2_primary_20260816
```

Summarize one or more compatible result directories:

```sh
julia --startup-file=no repro/uq_coverage_harness_2026_08/summarize_audited_repeated_uq.jl \
  --dirs=repro/uq_coverage_harness_2026_08/results/audited_h2_primary_20260816
```

## Results ledger

Populate this section only from clean-revision supervised records.

| Stage | Commit | Result directory | Decision |
|---|---|---|---|
| H0 | pending final commit hash | n/a | pass: full gate 1,621/1,621; benchmark smoke 10/10 |
| H1 | pending | pending | not started |
| H2 | pending | pending | not started |
| H3 | pending | pending | not started |
