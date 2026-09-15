# Sneyd: the effect of fourth-rooting the clean data

Research record for the observation-only comparison. The production estimator
and dependencies are unchanged. Scripts and retained records live in
[`repro/sneyd_fourth_root_2026_09_15`](../repro/sneyd_fourth_root_2026_09_15/README.md).
The production source revision throughout is
`de79d87527551600c027e924ab48d6ba50c0fcf2`, under Julia 1.13.0.

## What changes

The original observation is

```text
y(t) = (0.9 A(t) + 0.1 O(t))⁴.
```

For the same nonnegative, clean synthetic samples, the comparison uses

```text
z(tᵢ) = √√y(tᵢ),     z(t) = 0.9 A(t) + 0.1 O(t).
```

The root is taken before fitting any interpolator. The 201 original samples,
their grid from 0 to 0.98, the condition (IP₃ = 10, Ca = 0.1), the dynamics,
bounds, and unknown initial states are otherwise retained. There is one
observed signal and six hidden states; all six initial values remain unknown.
No known-state regression or characteristic-coefficient replacement is used.

The two dynamical models are the
[nine-independent-rate experiment](2026-09-15_sneyd_free_coefficients.md) and
the original fourteen rationally composed kinetic parameters. These remain
different inference problems. The root/quartic comparison is made *within*
each one.

The native free-rate generator reproduces the retained original signal with
maximum relative discrepancy 7.50 × 10⁻¹³; its linear signal agrees with the
fourth-rooted samples within 3.51 × 10⁻¹³. The numerical checks use the
generating parameters only for validation, never as estimator starts.

## Exact algebraic comparison

| Selected HC system | Quartic observation | Linear observation after rooting |
|---|---:|---:|
| Independent-rate model: equations / unknowns | 72 / 72 | 72 / 72 |
| Independent-rate model: terms | 1,306 | 292 |
| Independent-rate model: maximum degree | 4 | 2 |
| Original kinetics: equations / unknowns | 72 / 72 | 72 / 72 |
| Original kinetics: terms | 2,362 | 1,348 |
| Original kinetics: maximum degree | 6 | 6 |
| Observation rows, either model | 11 | 11 |
| Terms in observation rows, either model | 1,047 | 33 |
| Selected highest observation derivative | 10 | 10 |

Both selected systems contain five free rate/kinetic coordinates, six anchor
states, and 61 auxiliary state derivatives. Rooting removes 1,014 terms from
the observation rows. It does not reduce the number of unknowns selected by
the existing construction.

`compare_captures.py` converts the captured systems back to physical units
and normalizes equation rows over exact rational arithmetic. For each pair,
it verifies that **all 61 dynamical rows are identical**, the unknown names
match, and the 11 observation rows are precisely the derivatives of `w⁴` or
`w`, respectively, with `w = 0.9 A + 0.1 O`. This checks the actual HC inputs,
not just the model constructors or term counts.
The exact
[free-rate comparison](../repro/sneyd_fourth_root_2026_09_15/evidence/free_equation_comparison.json),
[rational-model comparison](../repro/sneyd_fourth_root_2026_09_15/evidence/rational_equation_comparison.json)
and
[historical free-rate control check](../repro/sneyd_fourth_root_2026_09_15/evidence/historical_free_control.json)
retain the corresponding input hashes.

Automatic rescaling chooses different state and observation units after
rooting, while parameter scales remain identical within each pair. The
independent-rate model changes the units of A and I₂; the rational model
changes A, I₂, O, and S. These are coordinate changes, not added information
or parameter constraints.

The rooted rational HC system still has the previous invalid denominator
family: set `l₆ = l₋₆ = 0` and all A, R, I₁, I₂ jets to zero. Every dynamical
row vanishes. The linear observation rows determine O₀,…,O₁₀, while S jets and
O₁₁ remain free. The captured-system check verifies this exactly. These points
are outside the rational ODE domain; their existence does not by itself prove
the cause of a solver's runtime.

## Runtime comparison

The independent-rate rooted run completes mixed-volume setup and tracks all
**5,491 polyhedral paths**, returning **seven nonsingular finite complex roots**
at generic complex data. The generic-start solve takes 2,756.28 s (45.94 min).
The path count is for this polynomial start system; it is not M or the number
of valid fitted roots. The seven roots are numerical HC results, not a
certified completeness result. No monodromy is used.

The fresh free-rate quartic control reproduces the previous captured
polynomials, ordered variables, and generic complex data values exactly. It
fails again with `OverflowError("-4798045382528 * -11403264 overflowed for type
Int64")`, after 1,225.57 s inside generic-start solving and 1,455.61 s of
estimation. Its last printed partial counter is not a completed mixed volume.

At the initial 1,800 s budget, the rooted free-rate case has tracked 2,719 of
5,491 paths and found two nonsingular generic solutions. The in-place extension
to 5,400 s was requested earlier, at 1,374.21 s after the first nonsingular
root appeared. The original-budget checkpoint and extension are recorded
separately; the Julia worker was not restarted or changed. This is not
presented as a success within the original budget.

The subsequent parameter homotopy transfers those seven roots to the first
real-data anchor at t = 0, using AGPRobust's estimated derivatives. The log
reports `7 accounted; finite-kept=0`: **zero successful finite endpoints**.
The phrase "accounted" needs care. In the installed HC 2.22.4,
`solutions(...; only_nonsingular=false, only_finite=false)` also includes failed
path records; the filter in HC's `src/result.jl` does not exclude them.
Consequently this count does not distinguish failed tracking from an endpoint
classified at infinity. The individual return codes were not retained, and
the cause of the transfer failure is not established. This is not a proof
that the real-data polynomial system has no finite solutions.
The existing empty-finite-result fallback in
`solve_with_hc_parameterized` then starts a fresh 5,491-path polyhedral solve
at that anchor. Thus generic setup is completed once, but the present fallback
can still repeat the expensive polyhedral work on real data. Column scaling
is enabled, as before; this call's scale range is 1 to 3.16 × 10²⁰.

That fallback is part of the unchanged production workflow. At the extended
5,400.43 s stage cutoff its last reported progress is **730 / 5,491 paths**, with
zero finite solutions. **No fitted candidate is returned.** Other interpolators
and trajectory polishing are not reached.

Shutdown exposes a separate interruption-handling issue: HC wraps the
`InterruptException` in a failed task/composite exception, and the per-point
catch proceeds briefly to anchor two during the grace period. That transfer
also reports seven accounted paths and zero finite endpoints, then starts
fresh setup. The supervisor ends the worker with SIGTERM (return code −15);
the worker cannot write its final `finally` checkpoint, so `result.json` still
says `estimating`. The completed supervisor and extension reports determine
the outcome: timeout, with 27.45 s of shutdown time after the cutoff. Both
watchdogs and the worker have exited. The anchor-two messages are retained as
shutdown activity, not a second completed estimation trial. No production
interrupt-handling change is included here.
The existing `_rethrow_if_interrupt` helper in `logging_utils.jl` recognizes
only a direct `InterruptException`, explaining why the wrapped interrupt
reaches the ordinary per-point error path.

For the original rational kinetics, **both freshly run observation arms hit
the 1,800 s stage watchdog in mixed-volume setup**, before tracking any paths.
Worker unwind times are 1,803.56 s (quartic) and 1,802.81 s (rooted). The last
partial counters are 647,032 and 65,036, respectively. They are not completed
volumes, root counts, lower bounds, or a valid tenfold complexity comparison.

The rooted identifiable-functions request also times out. Of its 600.76 s
stage time, 559.28 s are spent in the SI request after conversion/compilation
of the probe. Interruption is in
`find_ioprojections → eliminate_var → fast_factor → uncertain_factorization →
Nemo.gcd`, still constructing input-output equations. It has not reached final
generator simplification. The previous quartic `simplify=:absent` probe used
a 600 s budget measured from the SI call itself; these two timing origins
are retained explicitly. Rooting has not made this request quick.

The rooted selection-MV run times out at the 1,200 s stage budget. The rooted
large multiplicity run times out at the 2,400 s budget, with about 2,337.94 s
inside Gröbner. Neither returns a selected HC family/count from that probe.
Selection is interrupted inside
`_noise_candidate_from_indices → _noise_mixed_volume → MixedSubdivisions`;
the multiplicity run is still in modular F4 matrix reduction.
The quartic comparisons for these two earlier requests are the retained
historical runs, not new full reruns. Their source and timing context are in
the [HC-boundary](2026-09-15_sneyd_hc_boundary.md),
[separate-M](2026-09-15_external_multiplicity.md), and
[fixed-M](2026-09-14_fixed_multiplicity.md) records.

Finally, matched native eager second-Lie-derivative probes revisit the old
denominator-clearing request. The quartic form times out after 550.79 s in
`clear_denoms` (600.91 s including probe setup). The rooted form instead raises
a `BoundsError` in `MultivariatePolynomials.termwise_content`, through the
Float64 polynomial-GCD path, after 11.61 s in `clear_denoms`. Its second Lie
derivative has 1,658 text characters versus 3,420 for the quartic form. This is
an error, not successful simplification or an estimator fit. Both exact input
expressions and full stacks are retained. These are native-model probes of
the earlier request; the original adapter probe used flattened state symbols
and a different surrounding rescaling context. No dependency fix or upstream
report was attempted.

The isolated rooted multiplicity input has 74 equations, 73 variables,
1,362 terms, and maximum degree 6. Its exact sampled point satisfies every
constraint; the nonsaturation Jacobian has rank 72. The earlier quartic input
had 2,706 terms at the same equation/variable counts and maximum degree.
This is the representative-fixed, saturated M input, distinct from the
selected HC data-fitting system above.

Final timings, watchdog outcomes, and root counts are reported in the
[campaign summary](../repro/sneyd_fourth_root_2026_09_15/evidence/summary.json).
None of the four full-estimation workers returns a fitted candidate within
its budget; all stop before trajectory polishing. Individual timings include
cold compilation where stated and come from concurrent, single-threaded
workers; they are not repeated isolated performance benchmarks.
The generic system, its complex data vector, progress log, and returned root
count are retained. This harness did not serialize the seven generic root
vectors or the interpolated real-data derivative vectors, so the saved count
does not provide independent endpoint-residual checks or a resumable solution
pool.

## Settings and limits of the comparison

The main estimates leave M unknown and disable selection mixed-volume
scoring, preserving the previous easiest configuration and the normal
polyhedral generic-start solver. The rational model retains its previous
two-point multipoint configuration (15 pairs); the independent-rate model is
explicitly single point. Both begin with the single-point system. Twenty
warped anchors, the nine configured interpolators, root polishing, bounded
trajectory polishing, and no terminal optimizer fallback are retained.

The unchanged noise heuristic filters AAAD from the rooted signal, leaving
eight effective interpolators. The quartic signal retains nine. Both begin
with AGPRobust at the first real-data solve. In this run the first interpolant
is constructed before the generic solve, but the generic solve uses random
complex data values rather than interpolated values; its pool is intended for
reuse across interpolators. The original and rescaled signal checks and
runtime logs retain the filtering behavior explicitly.

The configured list is AGPRobust, AGPRobustRQ, S3AdaptSE, S3AdaptRQ,
ChebyshevBIC, ChebyshevAICc, AAADGPR, AAAD, and S2AAAMLE. Root polishing and
trajectory polishing are enabled; the latter uses `PolishLSOBoundedLog`, a
5,000-iteration/120 s limit, and ODE tolerances 10⁻¹². The seed is 20260915.
The free-rate model's bounds are 0 to 10⁶ for every state/rate. The original
kinetics retain state bounds 0 to 10⁵ and parameter bounds 10⁻³ to 10⁵.
These settings are configured throughout, but a run must first produce
candidates to exercise polishing.

The old M = 544 is not supplied to rooted estimation. The earlier side counter
separated 136 kinetic solutions from four quartic observation branches at its
verified reference fibre; taking the positive root removes the latter
ambiguity. That fact does not make the large production Gröbner calculation
free, certify all dense-data polynomial roots, or justify transferring 544
unchanged to the rooted model.

For the independent-rate model, a new small side check fixes φ₁,…,φ₄ to one
and counts the five characteristic-coefficient equations at the explicit
remaining-rate reference `(2,3,5,7,11)`. Exact Gröbner/quotient arithmetic gives
**7**, and augmented-ideal checks show that the characteristic-map Jacobian
and the state-observability determinant are nonzero at every solution. A
nonzero 5×5 Hankel determinant at the recorded reference ICs verifies that
the scalar jets determine those characteristic coefficients. Thus the
checked full parameter/state fibre contains **7 simple points for w, or 28
for w⁴**. The exact count and checks take about 1.2 s in SymPy, after input
construction.
The equations, basis, and verification flags are saved in the
[reference-count record](../repro/sneyd_fourth_root_2026_09_15/evidence/free_reference_count.json).

This is a reference-fibre diagnostic, not a new estimator or a certificate
about every interpolated dataset. It is not used to stop HC early. It does
illustrate why the selected system's 5,491 polyhedral paths should not be
read as 5,491 physically meaningful parameter/state solutions.

Structural representatives are still fixed by the existing algorithm. In
particular, the free-rate slice fixes φ₄ = 1 and retains the previously proved
obstruction to an exact positive representative of the full generating
trajectory. Rooting does not fix that issue or the poorly sampled fastest
transient. Returned trajectories, if any, are rescored on the original y
scale as well as the rooted z scale; the two least-squares objectives are not
interchangeable away from an exact fit.

This clean-data experiment does not transform the real noisy PEtab table or
its Gaussian likelihood.

## Why linear observations can matter this much

The state dynamics here are linear in the states for fixed rates. With six
distinct eigenmodes, a linear observation is a sum of at most six
exponentials. Raising that sum to the fourth power can mix them into as many
as `binomial(9,4) = 126` distinct exponential terms. Taking the known positive
root reverses that mixing in this clean, positive compartment-model setting.

Separately, a linear observation makes every observation-jet equation linear
in the state jets. That is the exact 1,047-to-33-term change measured above.
For example, writing wₖ for its kth time derivative at the anchor,

```text
Quartic:  y₀ = w₀⁴
          y₁ = 4w₀³w₁
          y₂ = 12w₀²w₁² + 4w₀³w₂

Rooted:   zₖ = 0.9Aₖ + 0.1Oₖ,   for every k = 0,…,10.
```

The remaining rate-times-state products, rational kinetic maps, and free
hidden initial states still require inference. The current general-purpose
construction retains its 72-variable representation even after the
observation becomes linear.

This supports making a known invertible observation transformation an explicit
part of future preprocessing. Here positivity supplies the branch of the
inverse. A restriction to linear combinations of states would remove this
observation-jet expansion by construction, but would still leave the original
rational kinetic map and hidden-state problem. This experiment changes neither
the production observation API nor the supported model class.

## Validation

Both constructor copies match their preceding studies byte for byte. The
root/quartic pairs match on model equations, bounds, original samples, seed,
dependency versions, and all estimation options apart from output paths.
Their captured unknown/data ordering and generic complex data vectors also
match exactly within each pair.
The fourth-power roundtrip reproduces every retained Float64 sample exactly.
Exact captured-system comparisons and the independent reference-fibre checks
pass. The physical rescoring helper reproduces the generating trajectory for
both models (original-y SSE 2.34 × 10⁻²⁶ for free rates and zero for the native
rational generator) and rejects an incorrect reported initial-state time.

Python and Julia source parsing pass. Global and optional-environment
manifests retain their original hashes. No production source or dependency
files changed, so the production FAST/registered/recovery gates were not rerun
for this research-only comparison. Two initial harness setup faults—environment
activation order and use of symbolic equality in a Boolean assertion—are
retained separately and excluded from the mathematical outcomes.
