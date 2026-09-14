# Dense single-experiment follow-up: Sneyd and Fujita

This resumes the PEtab investigation after the reusable-polisher fix. The
estimator is unchanged at `2fd4850c809c0ebca8682751459fe0dea9f379f6`.
Julia is 1.13.0, with the existing optional PEtab environment and frozen public
model checkout. No dependency versions or production solver defaults changed.

Bruno already has successful dense-data recovery in the
[original record](2026-09-11_dense_single_experiments.md). This follow-up runs
Sneyd through the same normal estimator and investigates the retained Fujita
polynomial system separately. Neither model has a completed dense-data
parameter-recovery result yet.

Scripts, commands, and compact evidence are in
[`repro/petab/dense_single/`](../repro/petab/dense_single/README.md), particularly
[`evidence/followup_20260914/`](../repro/petab/dense_single/evidence/followup_20260914/).
Timing includes compilation and sampling overhead. These are bounded diagnostics,
not comparative throughput measurements.

## Sneyd: rank construction finishes; global elimination remains expensive

The ordinary dense harness uses condition `Ca_dose_response__1`, with Ca = 0.1
and IP₃ = 10, 201 clean samples on [0, 0.98] seconds, 14 kinetic parameters,
and six freely estimated initial states. It retains the nine default
interpolators, 20 anchors, and two-point multipoint configuration. This attempt
never reaches interpolation, HC, or candidate processing.

The 900-second estimation-stage limit interrupts StructuralIdentifiability's
global analysis. Its stack is
`assess_global_identifiability → initial_identifiable_functions → find_ioequations
→ find_ioprojections → eliminate_var → det_minor_expansion`, inside polynomial
multiplication. The earlier SIAN rank calculation also spent substantial time
in ODEPE's exact-rational LU, but **that calculation finished**:

| Quantity | Value |
|---|---:|
| Constructed equations | 73 |
| Non-data indeterminates, including state derivatives | 81 |
| Exact Jacobian rank | 72 |
| Selected independent equations | 72 |
| Jacobian nullity | 9 |

This is later than the old denominator-clearing stall. The previous deferred
construction check had only demonstrated rank construction through order 3;
it had not exercised this global identifiability step.

The supervisor records `timeout`, while the worker's interrupted cleanup records
`interrupted`. Its whole-worker elapsed time is 1,056.3 seconds; the worker and
supervisor use different clocks for their stage measurements. Both original
measurements are retained. An empty completed-phase timing dictionary does not
mean no work occurred: the flushed construction messages and sampling stacks
identify the unfinished phases.

### What one fixed condition can identify

An independent SymPy calculation proves that the imported six-state model has
the form x′ = A(p)x, with 1ᵀA = 0. Its ten directed transitions use only **nine
distinct effective rates**. The 9 × 14 Jacobian mapping kinetic parameters to
those rates has rank 9 at three exact-rational probes. Thus the single fixed
condition leaves at least five continuous freedoms among the 14 original
parameters, even if all six states were observed perfectly. This is a rate-map
calculation, not a completed global output-identifiability certificate.

There is a stronger dimension bound for this run's scalar observation and free
initial states. Write w = 0.9 IPR_A + 0.1 IPR_O, so y = w⁴. Conservation forces
one zero eigenvalue of the state matrix. Cayley–Hamilton therefore gives

```text
w⁽⁶⁾ + c₅w⁽⁵⁾ + c₄w⁽⁴⁾ + c₃w‴ + c₂w″ + c₁w′ = 0.
```

The signal is determined by at most five characteristic coefficients and six
initial derivative values: 11 continuous coordinates, versus the run's 20
kinetic/initial-state unknowns. Taking the fourth power cannot increase that
dimension. This upper-bound argument predicts at least nine continuous freedoms,
consistent with SIAN's observed nullity. It does not establish which named
parameters are globally identifiable. Different experimental input conditions
are valuable because they change the effective-rate map.

### Independent simulation check and a grid limitation

SciPy's matrix exponential reproduces the 201 retained Julia observations to
**6.41 × 10⁻¹³**, measured as maximum signal error divided by maximum signal
magnitude. This independently checks the imported model and synthetic data.

At the generating parameters, the nonzero eigenvalues are approximately
−12,685.8, −49.23, −5.538, −1.324, and −1.272 s⁻¹. The fastest time constant is
7.88 × 10⁻⁵ seconds; the uniform sample spacing is 0.0049 seconds, about 62 of
those time constants. The next interpolation experiment should therefore
resolve the early transient with a nonuniform grid. This sampling limitation
does **not** explain the present stall, which occurs before interpolation.

## Fujita: auxiliary-variable elimination and mixed volume

All comparisons below use the retained **SIAN-selected 85-equation basis** from
the 88-equation pool, not the unrecorded noise-frontier basis interrupted in the
original estimator run. The basis has 85 unknowns: 14 remaining model/observation
parameters, nine anchor states, and 62 higher state derivatives. There are 23
data coefficients. The full pool uses 26 data coefficients. The previous SI
representative choices are retained; no additional physical parameters are fixed.

`reduce_fujita_jets.py` eliminates only auxiliary derivatives whose defining
equation has a nonzero constant coefficient. It never divides by an unknown.
Every step retains an explicit reconstruction formula, so this preserves affine
solutions. The greedy choice bounds predicted polynomial support growth; this
is one elimination policy, not an exhaustive search over elimination orders.

| Equations = unknowns | Monomial occurrences | Largest equation | Maximum unknown degree |
|---:|---:|---:|---:|
| 85 | 466 | 13 | 3 |
| 75 | 388 | 12 | 3 |
| 65 | 389 | 12 | 6 |
| 55 | 588 | 24 | 9 |
| 45 | 769 | 55 | 12 |
| 35 | 2,043 | 418 | 13 |
| 26 | 8,702 | 3,558 | 15 |

Fifty-nine auxiliary derivatives are removed in about 1.1 seconds, before
independent verification. Three remain: `pAkt_2`, `pEGFR_1`, and `pEGFR_2`.
Reducing the variable count eventually produces much denser, higher-degree
equations. The final status is `support_budget_or_no_constant_pivot`, under
limits of 5,000 predicted terms per equation and 50,000 overall.

The input polynomials are checked coefficient-for-coefficient against the
independently retained support report. Three exact-rational assignment/lift
checks also verify the reconstructed equations. Julia's `//` rational syntax is
explicitly converted before SymPy parsing; an initial incorrect floor-division
parsing attempt was discarded and is not used in these results.

### Bounded mixed-volume measurements

The original, 75-variable, and 55-variable systems each exceed a separate
180-second mixed-volume stage limit. No mixed-volume value is obtained.
Reordering the 85- and 75-variable equations by support size also exceeds the
same limit. Instrumenting the underlying tropical-regeneration traversal shows
it stopped at stages **59/85** and **56/75**, respectively, before returning the
first completed mixed cell. This identifies intermediate combinatorial work;
it does not establish a large numerical path count.

These calls measure torus mixed volume, matching the current basis scorer's
`HC.mixed_volume` call. They are not an affine HC solve or a completed root
enumeration. Eliminating variables can change this mixed-volume bound even
when it preserves affine solutions. Equation permutation preserves the bound.
A two-equation canary, x² − d = 0 and y − x = 0, returns the expected volume 2.

## Fujita: tracking a supplied root is tractable

The next diagnostic draws independent positive rational values for the 23
remaining physical coordinates and forward-generates all state/observation
derivatives. Three fixtures—start, nearby perturbation, and independent distant
point—satisfy all 88 equations **exactly over ℚ**. These use no published
parameters or fitted observations. Supplying one such root bypasses starting-root
enumeration and tests HC's path tracker in isolation. Column scaling is disabled
in this diagnostic; production defaults are unchanged.

| Target and homotopy | Result | Elapsed / compilation |
|---|---|---:|
| Nearby, straight parameter path | Expected real root, 9 steps | 29.23 / 29.13 s |
| Nearby, γ-straight system path | Expected real root, 12 steps | 6.87 / 6.59 s |
| Distant, straight parameter path | Step size too small, 764 steps | 0.79 / 0 s |
| Distant, γ-straight system path | Complex root of selected subsystem, 630 steps | 0.57 / 0 s |

Both nearby solutions recover the 23 physical coordinates to maximum relative
error **2.51 × 10⁻¹²**. Their maximum residual across **all 88 equations** is
1.07 × 10⁻¹². The distant γ result has selected-system residual 8.04 × 10⁻¹⁴,
but full-pool residual 4.82 and a large imaginary component. It is not a recovery
of the independently known distant root.

Thus the 85-variable representation is tractable for individual paths, but one
supplied root does not provide adequate branch coverage. A subsystem root must
also be checked against the omitted equations. This diagnostic does not turn a
single supplied seed into a complete generic start set.

### Historical monodromy diagnostic: coverage of two exact targets

A bounded follow-up uses HC's existing `monodromy_solve` to discover more roots
from the same starting root by loops through complex data-coefficient space.
Its internal 120-second budget returns **180 roots**, with return code `timeout`.
The call takes 175.5 seconds including 60.3 seconds attributed to compilation;
its internal timeout does not cover all setup/compilation. The outer worker has
a separate 240-second stage limit; the worker records 231.7 seconds for that stage.

Tracking all 180 roots with γ-straight homotopies succeeds for every path at
both targets. At each target exactly one endpoint has full-pool residual below
10⁻⁷, and that endpoint recovers the independently generated physical values:

| Target | Tracking time | Maximum physical relative error | Full 88-equation residual, independent Python evaluator |
|---|---:|---:|---:|
| Nearby | 11.76 s, including 9.40 s compilation | 2.51 × 10⁻¹² | 1.07 × 10⁻¹² |
| Distant | 31.95 s, no reported compilation | 2.10 × 10⁻¹² | 2.27 × 10⁻¹³ |

`verify_fujita_tracking.py` independently parses the original full polynomial
pool and evaluates every endpoint with SymPy/NumPy. It also verifies numerical
separation of all 180 endpoints at each target. The minimum pairwise relative
coordinate distance is 0.84 for the nearby set and 0.60 for the distant set;
the count is not explained by near-duplicate roots.

This result is **not** a completeness certificate: the monodromy run times out,
uses heuristic deduplication, and has no applicable trace-test certificate for
this parameter family. Nor does it demonstrate recovery from interpolated
observations. The repository owner reports a long history of unreliable
monodromy runtime and root coverage. This narrow result does not overturn that
experience, and the earlier recommendation to pursue it as the estimator path
is withdrawn. The 10⁻⁷ check above is only a clean synthetic diagnostic, not a
proposed cutoff for noisy data. No monodromy production default was added.

## Validation and scope

Only research scripts, retained evidence, and documentation change in this
follow-up. The normal estimator and optional integration source remain unchanged.
The meaningful checks here are exact input equality, exact elimination/lifting,
independent Sneyd simulation, a known mixed-volume canary, and independent
Fujita target-root/residual and numerical-distinctness comparisons. Package gates
were not repeated for these research-only changes. The passing production baseline remains the
[reusable-polisher validation](2026-09-13_reusable_polynomial_polishing.md).

The [SI cost and longer mixed-volume investigation](2026-09-14_identifiability_cost_and_mixed_volume.md)
supersedes the next-step recommendation: give Fujita's original retained basis
a longer mixed-volume budget, and ask SI only for information the estimator
needs, with explicit validation of any replacement representative-selection
policy. The [baseline audit](2026-09-14_baseline_algorithm_changes.md) distinguishes
actual estimator changes from these research diagnostics. Public multi-experiment
benchmark scores remain a later step.
