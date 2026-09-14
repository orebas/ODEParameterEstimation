# Deferred denominator construction

The change separates numerical derivative support from polynomial construction.
It retains the fraction simplification/GCD implementation, derivative limits,
structural-identifiability machinery, basis scoring, and HC conversion.

## Core derivative tables

`populate_derivatives(...; include_cleared=false)` produces the rational tables
used by the numerical Jacobian and SI observable-support mapping. These callers
do not read the four cleared tables. The default still constructs both forms.

`ensure_cleared_derivatives!(DD, order)` constructs a missing cleared prefix and
extends it only through the requested zero-based derivative order. Existing
rows are retained. The helper clears the already substituted **base equations**
once and differentiates those polynomials, matching the former construction.
It does not clear each differentiated rational equation independently. For example:

```text
x′ = a x / (b + x)

cleared base:       (b + x)x′ = a x
first derivative:  (b + x)x″ + (x′)² = a x′
second derivative: (b + x)x‴ + 3x′x″ = a x″
```

The numerical advisory also creates its fallback derivative tables only after
the normal advisory fails. The fallback's depth and point-count formulas are
unchanged. The standard SI/SIAN pipeline obtains its polynomial template from
SIAN separately; it does not need these redundant cleared derivative tables.

## PEtab experiment frontier

The experiment loop accumulates rational observation derivatives and probes
their Jacobian using the existing rank routine. The selector calls a deferred
polynomial builder only when a derivative cap has sufficient rank. This uses
the same Jacobian for depth discovery and basis selection.

The builder clears the accumulated equations and computes their original
polynomial support scores before basis selection. It caches the cleared prefix
in case construction needs another derivative order. A rank-deficient pool can
reach its explicit limit without any polynomial construction. The new
`experiment_polynomialization` progress event identifies the expensive stage.

Selected equation/variable ordering, support scores, and candidate ranking are
checked against an eager rational fixture. Roots are still checked against the
original rational observation equations and ODE poles.

## Validation

Reproduction commands, complete rational benchmark inputs, and source hashes
are in [`repro/deferred_denominators_2026_09_11/`](../repro/deferred_denominators_2026_09_11/README.md).
The production patch and its base revision are retained in that directory's
`evidence/` folder. Tests use Julia 1.13 and the existing dependency stack.

- Focused derivative contracts: **22/22 passed**. These include independent
  product-rule identities, an analytic rational Jacobian, parameter substitution,
  incremental materialization, and SI support without cleared tables.
- PEtab contracts: **128/128 passed**, including unchanged rational basis
  selection and original-equation/pole validation.
- Full FAST gate: **1,839/1,839 passed** in 20m44.7s of test execution.
- Unit group: **412/412 passed** in 27.6s of test execution.
- Benchmark smoke: **10/10 passed** in 31m03.7s of test execution. Maximum
  relative parameter errors were 5.63 × 10⁻⁵ (noisy LV), 6.35 × 10⁻⁹ (noisy
  simple), 1.02 × 10⁻¹⁰ (clean LV), and 2.50 × 10⁻⁹ (rescaled HIV).

### Rational benchmark recovery

These use the full retained benchmark data, current default interpolator pool
and ordinary noise filtering, 20 warped anchors, two-point systems, algebraic
polish, and trajectory polish. The error below is the worst relative parameter
error in the **first-ranked returned result**, not the best raw candidate.

| Model | Data per observable | Interpolators | Parameter error | Estimation time |
|---|---:|---:|---:|---:|
| FitzHugh–Nagumo | 1,001 clean samples | 9 | 7.06 × 10⁻¹¹ | 485.2 s |
| Repressilator | 1,501 samples, noise 10⁻⁴ | 7 after noise filtering | 1.73 × 10⁻⁴ | 2,431.4 s |
| Biohydrogenation, `--optimize=0` diagnostic | 750 samples, noise 10⁻⁶ | 9 | 5.76 (576%) | 3,165.0 s |

FitzHugh–Nagumo and repressilator each returned one ranked result. Their fit errors were 1.87 × 10⁻²³ and
6.45 × 10⁻⁵ respectively. Simulating the extracted generating models before
estimation agreed with the retained data to 5.73 × 10⁻¹⁴ relative RMS for
FitzHugh–Nagumo and approximately 10⁻⁴ for each repressilator observable.

The detailed options, estimates, per-coordinate recovery errors, and phase
timing summaries are retained in `evidence/fhn.json` and
`evidence/repressilator.json`. These include hashes of the full worker records
and logs. Wall times include compilation and profiling, and these workers ran
alongside other validation jobs; they are not comparative throughput measurements.

### Biohydrogenation: comparison with the previous derivative producer

The compatibility probe loads the exact derivative producer from base revision
`fce879d65c6b36dc3b25de354017d8b776028c4d` in a separate Julia process and compares
it with deferred construction on the retained biohydrogenation model.
All **9 checks passed**. Both rational and cleared tables are symbolically
identical, and the 12 × 10 numerical observation-map Jacobian has maximum
absolute difference **0**. The producer's RNG consumption is also unchanged.
This RNG statement concerns the two producer calls, not the full advisory path,
which now skips an unused fallback computation.

The requested 6-level tables contain orders 0–5. At a request for 12 levels,
both versions hit the same existing coefficient-overflow guard and retain
9 levels (orders 0–8). This change does not relax that guard. The reproducible
probe and its result are `run_compatibility.jl` and `evidence/compatibility.toml`.

### Biohydrogenation: default runtime limitation

The full 750-sample, noise-10⁻⁶ benchmark run did **not** finish within its
3,600-second estimation-stage budget. It completed three of nine interpolators
and the fourth's single-point HC solves, then stopped while compiling the
single-point algebraic root polisher. The stack enters the single-point candidate
loop at `optimized_multishot_estimation.jl:1337`; the earlier attribution to
multipoint polish was incorrect. No final ranked estimates were returned, so
this is not a recovery pass. The hour limit applied to the whole estimation
stage, not to one compilation.

Repeated sampling stacks were in LLVM optimization while compiling ForwardDiff
through the residual in `solve_with_robust.jl:99,166`. These lines are unchanged
by this patch. SI template construction had completed in 37.9 s. This is a later
compilation bottleneck, separate from the deferred denominator construction.
The worker did not finish cleanup during the interrupt/termination grace period;
the supervisor ultimately killed it. Its last checkpoint still says `estimating`,
while the retained supervisor result explicitly says `timeout`.

`evidence/biohydrogenation_default.json` retains this distinction, the exact
options, and log hashes. A sampled stack and the saved SI template are also
retained. A separate `--optimize=0` diagnostic uses the same estimator settings;
its SI polynomial template matches the default run exactly except for timestamps,
as recorded in `evidence/biohydrogenation_template_comparison.json`.

The [September 13 compilation follow-up](../repro/biohydrogenation_compilation_2026_09_13/README.md)
finds repeated compilation across numeric shooting-point systems. It includes
a bounded kernel probe, an exact selected-system replay, and the subsequent
reusable-polisher implementation. With that later change, the same full fixture
completed under normal optimization in 25.0 minutes; raw polishing totaled
24.66 seconds. The parameter-recovery limitation below persists.

### Biohydrogenation: completed compiler diagnostic, poor parameter recovery

The `--optimize=0` run completed all nine interpolators, the 20 single-point
anchors, and the configured two-point solves. Estimation took **3,165.0 s**
(52.8 minutes). This tests recovery under a different compiler configuration.
The later reusable-polisher change resolves the default-runtime limitation
described above; its normal-compiler recovery evidence is recorded separately.

There were 1,018 candidates entering result processing. Initial processing took
54.4 s; 205 backsolves were flagged, invoking the existing algebraic recovery path.
Trajectory polish took 51.5 s, followed by 35.5 s of branch completion. SI reported
**M = 2**, and branch completion replaced the candidate pool with two candidates
before final clustering. Both returned results have `source_type=branch_completed`.
The original worker's misleading `raw_count=2` field counts that processed pool,
not the 1,018 earlier candidates; the retained JSON calls it
`preclustering_candidate_count`.

The first-ranked result's package fit error is **9.38 × 10⁻¹⁰**, but it does
**not** accurately recover all generating parameters:

| Parameter | Generating value | First-ranked estimate | Relative error |
|---|---:|---:|---:|
| k₅ | 0.471 | 0.470999587 | 8.76 × 10⁻⁷ |
| k₆ | 0.287 | 0.286998671 | 4.63 × 10⁻⁶ |
| k₇ | 0.126 | 0.125999997 | 2.57 × 10⁻⁸ |
| k₈ | 0.806 | 0.805382060 | 7.67 × 10⁻⁴ |
| k₉ | 0.893 | 0.871876596 | 2.37 × 10⁻² |
| k₁₀ | 0.741 | 5.011784680 | 5.76 |

The second branch has a worse fit (8.29 × 10⁻³) and worse maximum relative
parameter error (8.71). It also has negative k₇ and k₈ and x₆(0) ≈ 24.46;
the trajectory optimizer's box bounds are not a final output filter here.
Neither returned branch provides accurate recovery of the generating parameter
set. The unobserved x₇ is flagged structurally unidentifiable and is excluded
from the parameter-error criterion. Full coordinate values, provenance, options,
and timing summaries are in `evidence/biohydrogenation_o0.json`.

The historical result for this exact retained data also had k₁₀ ≈ 5.011870 in
its first row. Its input hash and first-row values are retained in
`evidence/biohydrogenation_historical_context.json`. This is context, not a
controlled before/after comparison: the stack and configuration were not matched,
and the old run retained 100 output rows. The exact producer/Jacobian
comparison above is the direct mathematical compatibility check for this patch.

The remaining biohydrogenation work is to investigate parameter/branch recovery.
This deferred-construction patch itself does not change root polishing or branch
completion; the later compilation fix is linked above.

### Sneyd: construction reaches order 3

The single condition `Ca_dose_response__1` retains 20 unknowns: 14 parameters and
six local states. Construction now crosses the previous order-2 denominator
clearing bottleneck and finishes the requested order-3 diagnostic in **27.7 s**,
including compilation within the construction call. Loading/importing plus
construction took 150.0 s inside the worker after package imports.

| Highest observation derivative | Equations | Numerical rank | Unknowns |
|---:|---:|---:|---:|
| 0 | 1 | 1 | 20 |
| 1 | 2 | 2 | 20 |
| 2 | 3 | 3 | 20 |
| 3 | 4 | 4 | 20 |

Polynomial construction was called **zero times**. The result was
`rank_deficient_at_limit`; no HC solve or parameter recovery was attempted.
This verifies the scheduling change, not a structural-identifiability verdict
or parameter recovery for Sneyd. Higher rational derivatives and
any polynomial construction that becomes necessary can still be expensive.
