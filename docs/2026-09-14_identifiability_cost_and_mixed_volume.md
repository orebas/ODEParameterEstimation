# Asking SI for less, and giving Fujita mixed volume more time

The local identifiability calculation is sufficient for the classification
ODEPE currently consumes, and it is fast on both retained dense models. However,
ODEPE also uses identifiable functions to choose representative fixes. Skipping
that separate calculation without replacing its consumer would change behavior.
This investigation identifies a conservative optimization and a further,
explicitly different representative-selection option.

This report supersedes the solver recommendation at the end of the
[earlier September 14 follow-up](2026-09-14_dense_single_followup.md).
The repository owner's repeated experience is that monodromy has been unreliable
both in runtime and root coverage. The earlier small exact-jet experiment is
retained as a diagnostic; it is insufficient grounds to recommend monodromy as
the production path. No further monodromy runs or estimator integration were
made for this investigation.

Core source is `62baa5d`; Julia is 1.13.0, StructuralIdentifiability is 0.5.31,
and HomotopyContinuation is 2.22.4. Production source, option defaults, and
dependencies remain unchanged. The
[baseline algorithm audit](2026-09-14_baseline_algorithm_changes.md) documents
the preceding changes separately.

## What ODEPE currently requests

The relevant path is
[`prepare_si_template_with_structural_fix`](../src/core/parameter_estimation.jl)
→ [`get_si_equation_system`](../src/core/si_equation_builder.jl):

```text
Original model + observations
  ├─ SIAN polynomial construction and rank selection
  ├─ SI.assess_identifiability(parameters ∪ states)
  │    ├─ local identifiability
  │    └─ global identifiability / input-output elimination
  │         ODEPE keeps only status == :nonidentifiable
  └─ SI.find_identifiable_functions(model)
       └─ Jacobian of combinations → representative variables to fix

Then build the final template:
  repeat analysis of the same original model;
  apply the chosen fixed values to the symbolic polynomial equations.
```

The initial detection pass disables algebraic multiplicity. The final pass
allows its computation. This multiplicity calculation is a distinct cost from
SI's classification and function generation; omitting global SI does not
automatically eliminate it. Fujita's earlier 738.8-second preflight included
about 549.2 seconds in the multiplicity quotient calculation.

`pre_fixed_params` is applied after the SI calls. It is not substituted into
the ODE supplied to SI in those two passes. Thus classification and identifiable
functions can be reused between them without changing which model is analyzed.
Any later analysis of an actually modified model needs its own cache key.

The global call, nonidentifiable filter, and function-generation request already
appear in commit `503fe45c` from September 9, 2025. They were not introduced by
the denominator or polynomial-polisher work this month.

## The classification can ask only for local identifiability

Installed SI 0.5.31 implements `assess_identifiability` by running its local
algorithm first. For each requested quantity it returns:

```text
local false                 → :nonidentifiable
local true, global false    → :locally
local true, global true     → :globally
```

ODEPE uses only the first category. It does not use the distinction between
`:locally` and `:globally` in this builder. Consequently the public
`assess_local_identifiability` API already answers that consumed question.
The API supports checking parameters and states for one experiment with
`type=:SE`; `:ME` answers a different question and does not accept states.
See the [official API documentation](https://docs.sciml.ai/StructuralIdentifiability/stable/identifiability/identifiability/).

To preserve the existing local-stage probability when the overall SI probability
is p, use

```text
p_local = 1 − 0.1(1 − p).
```

For the current p = 0.99 this is 0.999. The probes use that probability, all
model parameters and states, and three fixed seeds. They reimport and verify
the exact physical model from the retained run and apply the ordinary power-of-2
rescaling before conversion to SI. These are free-initial-state, single-condition
models, matching the dense studies; the published full PEtab problem has a
different initial-condition/multi-condition contract.

| Model | Parameters + states checked | Locally identifiable quantities | Independent continuous freedoms | First call, including compilation | Two further calls |
|---|---:|---:|---:|---:|---:|
| Sneyd | 14 + 6 = 20 | 0 | 9 | 7.576 s (7.352 s compilation) | 0.620 s, 0.139 s |
| Fujita | 16 + 9 = 25 | 7 | 2 | 8.188 s (7.500 s compilation) | 1.330 s, 0.486 s |

All three seeds agree on each model's complete classification and coordinate
basis. The seven locally identifiable Fujita quantities are `reaction_2_k2`,
`reaction_3_k1`, `reaction_4_k1`, `reaction_5_k2`, `reaction_6_k1`,
`reaction_7_k1`, and `reaction_8_k1`. The other eight rate/observation parameters,
`EGFR_turnover`, and all nine states are classified nonidentifiable.

Sneyd's 20 individually nonidentifiable quantities do **not** imply 20 independent
freedoms. Their dependencies leave a nine-dimensional family of indistinguishable
parameter/state assignments, consistent with the earlier rank-72 system with
81 unknowns. The local SI result adds direct model-level evidence to the prior
signal-dimension argument.

The isolated timings exclude roughly three minutes of package loading, model
import, rescaling, and conversion. They do not replace the end-to-end estimator
time. Workers use one Julia/BLAS thread and periodic sampling profiles; cold
compilation and concurrent probes mean these are diagnostic timings.

An isolated Fujita `assess_identifiability` call finishes in **59.286 seconds**
(55.893 seconds attributed to compilation). Its nonidentifiable set matches
the local result exactly; the seven local-true quantities are classified globally
identifiable. That verifies the consumed-set equivalence on the actual model,
in addition to the source-level argument. It does not measure the separate
identifiable-function call or SIAN multiplicity cost.

There is also a narrow upstream optimization opportunity: Sneyd's local result
leaves **no quantities to check globally**, but installed SI still enters
input-output elimination with an empty `locally_identifiable` list. An early
return at that internal stage could avoid the wasted work while retaining the
full public classification interface. ODEPE can obtain its needed classification
through the existing local API without waiting for such a dependency patch.
This would still leave ODEPE's separate function-generation request below.

## Identifiable functions are a separate request, with a real consumer

`find_identifiable_functions` computes generators describing everything
identifiable in the model. ODEPE's structural-fix code converts them to Symbolics,
differentiates them with respect to candidate variables, evaluates that Jacobian,
and uses pivoted QR to choose nonpivot coordinates to fix to 1.0. For candidate
vector c and combinations g(c), the intended number is

```text
number to fix = length(c) − rank(∂g/∂c).
```

The current policy prefers parameters, considering states only if no parameter
candidates remain. If given no usable identifiable functions, it selects the
first candidate instead. Returning an empty function list would therefore not
preserve this policy or correctly communicate that the expensive analysis was
skipped. Its generator role is described in SI's
[identifiable-functions tutorial](https://docs.sciml.ai/StructuralIdentifiability/stable/tutorials/identifiable_functions/).

### Settings that help, and settings that do not remove this bottleneck

| Request or setting | Assessment |
|---|---|
| Replace full classification with local classification | Sufficient for the nonidentifiable set consumed here; directly measured above. |
| Reuse classification/functions between detection and final template | Same original SI model is analyzed twice; a conservative optimization opportunity. |
| Skip functions when there are no variables requiring representative fixes | The fix-selection consumer has no work in that case. Preserve an explicit metadata contract for callers that request functions. |
| `find_identifiable_functions(...; simplify=:weak)` or `:absent` | Avoids some/all final generator simplification, but not construction of the initial input-output equations. |
| `with_states=false` | Already the default used by ODEPE. Asking for states would request more. |
| Lower probability | Changes probabilistic work bounds; it does not remove the elimination algorithm. No need to weaken probability to obtain the local timings above. |
| Check only parameters | Would omit the state observability information ODEPE currently needs. |
| Switch to `type=:ME`, or declare additional ICs known | Changes the mathematical question; not a performance-only setting. |

In installed SI, even `simplify=:absent` first calls
`initial_identifiable_functions`. Only after that returns does it skip
`simplified_generating_set`. The previous Sneyd timeout was inside
`find_ioequations → find_ioprojections → eliminate_var → det_minor_expansion`,
before this final simplification stage. This is SI polynomial elimination,
distinct from ODEPE's `clear_denoms` GCD.

The isolated Sneyd `simplify=:absent, with_states=false` run exceeds its
**600-second SI-operation budget**. The worker records interruption after
601.066 seconds, still in that same input-output elimination chain inside Nemo
polynomial multiplication. It never reaches final generator simplification.
The supervisor records `timeout`; the worker records `interrupted`, with the
full stack retained. Disabling final simplification therefore does not remove
the observed stall. This is a bounded result, not a claim that the computation
can never finish with more time.

After writing its interruption record and printing `FINISHED interrupted`, this
worker segfaulted during process-exit FLINT polynomial finalization (return code
−11). The full log records both events. The five completed local/global/slice
workers exited normally. The shutdown failure is a separate observed limitation
of this interrupted run; it is not counted as a completed SI calculation, and
its cause has not been isolated here.

### A possible replacement for representative selection

The local API accepts `trbasis`, an output array populated with nonpivot
coordinate variables from its finite-field observation-jet Jacobian. These
coordinates parameterize the remaining generic continuous freedom relative
to the observations. Installed SI itself passes this basis into its subsequent
global calculation. For the three local probes, the arrays are:

```text
Sneyd:  l2, k_4, k_3, k_2, k_1, k4, k3, k2, k1     (9 parameters)
Fujita: reaction_1_k1, EGFR_turnover                  (2 parameters)
```

This provides a much cheaper candidate mechanism for taking a coordinate slice
through the solution family, without constructing explicit identifiable
combinations. It is a different choice rule from ODEPE's floating-point QR on
globally identifiable functions. It must be introduced as such, rather than
silently labeled an equivalent simplification setting.

The `local_fixed` probe actually substitutes these parameters into SI's ODE,
using `set_parameter_values`, then repeats local analysis. It tests an all-ones
slice and a distinct-rational slice (1.1, 1.2, … in basis order), each with three
seeds. All six checks per model leave an empty transcendence basis and classify
**every remaining quantity as locally identifiable**:

| Model | Fixed parameters | Remaining quantities | Local recheck time |
|---|---:|---:|---:|
| Sneyd | 9 | 5 parameters + 6 states = 11 | 0.018–0.109 s |
| Fujita | 2 | 14 parameters + 9 states = 23 | 0.302–0.719 s |

These are diagnostic slices in the rescaled SI coordinates. They establish that
this proposed choice removes continuous freedom in these tested models. They
do not show parameter recovery from observations or equality to the old
representative values.

Local rank is not a global root count, a positivity certificate, or proof that a
chosen fixed value intersects every admissible real solution branch. A future
implementation should retain all finite branches within the chosen slice,
report the convention, recheck rank after fixing, and handle bases containing
states as well as parameters. In particular, fixing all coordinates to 1 is
not a theorem about physical feasibility under PEtab bounds.

## Fujita mixed volume: give the calculation a longer budget

The previous three-minute limits were scouting budgets, not evidence that
completion was impractical. The new measurement gives the original retained
85 × 85 system **1,800 seconds for mixed-volume computation**, separately from
loading. It keeps the original equation order and does not eliminate variables
or change the polynomial support.

The input is the retained **SIAN-selected basis**, not the uncaptured frontier
candidate interrupted in the original full estimator. It has 14 model/observation
parameters, nine anchor states, 62 auxiliary state derivatives, 23 data
coefficients, and 466 monomial occurrences. The largest unknown degree is 3.
The full 88-equation pool has 26 data coefficients.

The **1,800-second requested stage limit is exceeded without a mixed-volume
value or a completed mixed cell**. The interrupted traversal is at regeneration
stage **49/85**, in `next_cell! → exchange_column! → compute_dot_bound!`.
The worker saves its result and exits with code 1; the supervisor records
`timeout`. This is a substantially longer trial than the initial scouting runs,
but it does not rule out completion with a longer offline budget.

The worker's Unix-clock operation duration is 1,801.278 seconds. The supervisor
reports 1,655.609 seconds for the entire process using its monotonic clock.
Those clocks disagree, so this should be described as a roughly half-hour
bounded trial, not a controlled 30-minute timing measurement. Both original
measurements are retained. The earlier support-reordered 85-equation run reached
stage 59 under its shorter budget; traversal stage is not a linear completion
percentage and equation order matters to intermediate work.

These are torus mixed-volume measurements, matching the current basis scorer;
they do not count affine roots or finish an HC solve. The worker records
tropical-regeneration progress and completed cells. Its counter implementation
was checked previously against a system of known mixed volume 2.

### How often is the expensive work done?

The user's recollection is correct about amortizing generic starting roots.
Within a normal run, generic-frontier selections and generic root sets are
cached and reused across anchors and interpolators for the same structure.
Single-point and multipoint systems have distinct structures and caches.

There is an additional cost before that reuse:
[`_noise_select_pool`](../src/core/noise_frontier_construction.jl) constructs
candidate row bases at the first feasible derivative cap, deduplicates row sets,
and keeps up to `construction_candidate_limit = 64`. Each square full-rank
candidate can call `_noise_mixed_volume`; `construction_compute_mixed_volume`
defaults to true. This is up to 64 distinct mixed-volume computations per
frontier construction, not one calculation for the entire estimation run.

The selected mixed-volume integer is a score. It is not a retained polyhedral
start system supplied to the subsequent generic HC solve, so scoring does not
automatically reuse its mixed-cell enumeration there. Tracking-recovery paths
can also require fresh solves. The normal caches are scoped to one run; these
are not persistent cross-session artifacts.

The conservative next steps are to log the candidate index/support and separate
scoring time from generic-root initialization, retain results per structure,
and allow a realistic explicit budget for expensive cases. Restricting the
number of scored bases or changing the basis criterion is an algorithm decision;
it should be recorded and compared, not silently coupled to a timeout increase.

## What the earlier dense studies actually establish

| Study | Established | Still unresolved |
|---|---|---|
| Bruno, one condition, 201 clean samples per output | Ordinary dense pipeline recovers four rates and three free ICs; maximum relative error 3.27 × 10⁻¹². | Public noisy/multi-condition benchmark comparison. |
| Sneyd | Imported linear state dynamics and synthetic data independently verified by matrix exponential; rank construction finishes; local SI is fast and reports nine freedoms. | Baseline representative selection, interpolation of the fast initial transient, and end-to-end estimation. |
| Fujita | Exact auxiliary elimination/lifting verified; individual paths can be tracked; a supplied-root diagnostic can recover exact generated targets. | Reliable starting-root enumeration and recovery from interpolated data. |
| Biohydrogenation | Deferred equations match the prior producer; reusable kernels resolve repeated raw-polisher compilation in the retained full run. | Existing k₁₀ recovery error. |

Eliminating 59 Fujita auxiliary derivatives shrank 85 unknowns to 26 in about
1.1 seconds, but increased support from 466 to 8,702 monomial occurrences and
maximum degree from 3 to 15. Fewer variables did not guarantee cheaper
mixed-volume work. The earlier monodromy run returned 180 roots before its
timeout and happened to cover two exact generated targets. It did not certify
all roots, use interpolated observations, or establish production robustness.

Sneyd's fastest generated mode has a time constant near 79 μs, whereas the
uniform grid spacing was 4.9 ms. A grid resolving the early transient is a
separate future experiment; it cannot fix a symbolic SI stall that occurs
before interpolation. The complete evidence and qualifications are retained in
[the preceding report](2026-09-14_dense_single_followup.md).

## Implementation order supported by this investigation

1. Change only the classification request to local SI, preserving its probability
   and the reported nonidentifiable set. Reuse that result across the two template
   passes. This is the smallest well-supported core change.
2. Avoid redundant function generation, including the no-fix case, with a clear
   template metadata contract. Keeping the existing fix policy still leaves
   Sneyd's expensive first function-generation call.
3. If removing that remaining cost, introduce and validate local-basis
   representative selection explicitly. Check small identifiable/partially
   identifiable models and rational recovery models, including biohydrogenation;
   run the full gate and recovery benchmark before adopting it as the baseline.
4. Continue Fujita with logged, longer-budget mixed-volume and generic-start
   preparation. Keep root completeness and the omitted-equation checks visible.

These are proposed production changes, not changes already made by this report.
The only executable changes here are the bounded SI research probe and its
supervisor mode. Existing production gates remain the recorded 1,934/1,934 full
and 10/10 benchmark results from the reusable-polisher change.

## Reproduction and retained evidence

The [dense-study README](../repro/petab/dense_single/README.md) gives commands.
New evidence is under
[`si_cost_20260914/`](../repro/petab/dense_single/evidence/si_cost_20260914/),
including exact worker snapshots, input hashes, SI equations, classifications,
timings, timeout records, and a file-hash manifest. The earlier dense model
definitions and data are reused by hash rather than regenerated from fitting
results. No published parameter values are used as candidate starts.
