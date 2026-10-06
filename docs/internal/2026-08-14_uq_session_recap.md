# UQ session recap — 2026-08-13/14

> Historical calibration and investigation record. The later production
> estimator-routing/API contract is documented in
> [`2026-08-14_estimator_aware_uq.md`](2026-08-14_estimator_aware_uq.md), and
> the current audited nonlinear canaries are recorded in
> [`2026-08-14_peb_audited_uq_canaries.md`](2026-08-14_peb_audited_uq_canaries.md).
> The earlier package-constructor routing pilot is retained as a superseded
> stress record in
> [`2026-08-14_simple_nonlinear_estimator_pilot.md`](2026-08-14_simple_nonlinear_estimator_pilot.md).

Session baseline `59eafb0` → head `875944c` (main ≡ uq-revamp-wip, pushed).
**31 files changed, +2249 / −176.** Full FAST gate 1170 → **1344**; `fast_unit`
186 → **232**.

Two arcs: (1) Stream B roadmap items 1–3 plus multipoint-UQ v1 steps 1–3, and
(2) an empirical validation campaign that changed what we think the UQ is *for*.
Arc (2) is the more important one and is written up in full in
[§5](#5-what-the-validation-campaign-found) — it ends with the first
calibration of the UQ against the estimator it actually describes.

---

## 1. Commits

| # | hash | what |
|---|------|------|
| 1 | `10c7380` | Estimate-conditioned sensitivity S — production UQ runs without truth |
| 2 | `2a7ed53` | Delete severed UQ kernel dispatch (SE-only is the honest truth) |
| 3 | `ccbeb8b` | UQ coverage harness + N=20 gate smoke |
| 4 | `6022013` | Multipoint data alignment: exact per-point index lists, indexed fill |
| 5 | `007aacd` | Σ_d assembly: exact-only observable-name matching |
| 6 | `4c63690` | `MultiPointTemplate.data_var_meta` — authoritative per-data-var metadata |
| 7 | `ee58a68` | Stacked multi-time estimator covariance `W_stack Σ_y W_stackᵀ` |
| 8 | `3639457` | IFT solve: degrade loudly, no silent `pinv` |
| 9 | `d71a1ff` | Multipoint estimate-conditioned sensitivity S (v1 step 3) |
| 10 | `af522a0` | Nonlinear UQ validation driver + LV diagnostic replicate |
| 11 | `875944c` | UQ regime screening: harness hardening + single-point regime findings |

---

## 2. Stream B items 1–3 (roadmap locked 2026-08-13)

### 2.1 Estimate-conditioned S — the blocking defect, fixed (`10c7380`)

**Before:** the UQ sensitivity matrix S was evaluated at *ground truth*
(`_build_true_value_vector(pep, …)` + oracle Taylor coefficients at
`feasibility_sensitivity.jl:678-694`). `compute_uncertainty = true` therefore
could not run on real data at all — no `p_true` ⇒ empty S ⇒ `nothing`.

**After:** `diagnose_sensitivity(...; estimate_result, value_source)`.
`:estimate` (default when an estimate is supplied) evaluates every Jacobian at
(θ̂, x̂-propagated state jets, the GP interpolant jets the solver consumed);
`:oracle` is retained unchanged as the calibration/testing diagnostic.
`_compute_uq_result` passes `estimate_result = best_solution`, so the
production path is estimate-conditioned.

Machinery added to `taylor_oracle.jl`:

- `_propagate_state_taylor` — the symbolic jet recursion extracted from
  `compute_oracle_taylor_coefficients`. **Insight:** the Taylor jet of an ODE
  solution at a point is an *algebraic* function of (state values, parameters)
  at that point, so no trajectory is needed. The oracle path now solves the ODE
  only to obtain the anchor value; behaviour is byte-identical.
- `compute_estimate_taylor_coefficients` — the estimate-value sibling.
- `interpolant_taylor_coefficients` — GP jets shaped as the `obs_taylor` contract.
- `_pep_with_estimate_values` — reuses the SIAN name-parsing lookup machinery
  with estimate value dictionaries instead of duplicating it.

**Trap found during implementation:** `ParameterEstimationResult.states` are
**t0 initial conditions**, not values at `at_time`. Reading them directly as the
jet anchor would have been silently wrong; the anchor goes through
`_uq_state_values_at_time` (the same resolver the physicalization uses).

`SensitivityReport` gained `value_source::Symbol` (legacy constructors default
`:oracle`); the HTML report no longer hardcodes "evaluated at true values".

### 2.2 Severed kernel dispatch deleted (`2a7ed53`)

`_uq_kernel_for_result` / `_uq_kernel_from_interpolator_source` /
`_default_uq_interpolator_source` / `_UQ_MATERN_INTERPOLATOR_SOURCES` had zero
production callers — the UQ path pins `agp_gpr_uq`, which is SE-kernel-only and
throws otherwise, so the Matérn branch was unreachable. Only two `fast_core`
asserts consumed it. Deleted with a tombstone comment stating the SE-only
constraint; Matérn UQ returns when there is a harness able to validate it.

### 2.3 Coverage harness + gate smoke (`ccbeb8b`)

`repro/uq_coverage_harness_2026_08/coverage_driver.jl` — N-replicate empirical
CI coverage of the whole chain (noisy draw → estimate → GP jets → Σ_d → S →
Σ_x → physicalized report → per-coordinate z). Modes:
`value_source ∈ {:estimate, :oracle}` × `estimator ∈ {:nls_polish, :full_pipeline}`.
Ships `two_exp_pep()` (the TAC anchor model).

`test/test_uq_coverage_smoke.jl` runs an N=20 two_exp sweep (~1 min) inside the
full gate with tripwire bands — reports ≥ 18/20 (the 2026-06-30 "no successful
audit trials" crash class), coverage ≥ 0.7, |mean z| ≤ 1.0, sd z ∈ [0.05, 2.5].
Bands are breakage tripwires, **not** calibration assertions.

---

## 3. Multipoint UQ v1 (steps 1–3, then paused)

### 3.1 Design consult

The design was reviewed adversarially by GPT Sol (`openai/gpt-5.6-sol` via PAL;
continuation `5ba8f63b-11da-4e0f-8ead-ae6f0f32ea72`). Outcomes:

- **Confirmed:** the cross-time covariance `Cov(jet(tᵢ), jet(tⱼ)) = Wᵢ Σ_y Wⱼᵀ`,
  properly described as the *repeated-observation sampling covariance at
  plug-in hyperparameters*. (Wording correction adopted: not "conditional on
  the same realization" — conditioning on the realized y makes the posterior-mean
  estimator deterministic and its sampling covariance zero.)
- **Confirmed:** `build_observation_covariance` computes the *latent posterior*
  cross-time covariance — a different random object. It must stay dark and must
  never be mixed with the estimator-sampling path (double counting).
- **Rejected:** the proposed overdetermined GLS sensitivity
  `-(J_xᵀ W J_x)⁻¹ J_xᵀ W J_d` is only a frozen-weight Gauss–Newton
  approximation, not the derivative of the LM estimator actually used. The exact
  form needs the score-equation IFT with residual-weighted second derivatives.
  Overdetermined UQ deferred.
- **Adopted:** factorized per-observable assembly, construction-time metadata as
  the source of truth, a root-residual gate, no silent `pinv`, and point-1
  physicalization described as *the estimator mapping* rather than "conservative"
  (it can err in either direction).

### 3.2 Two pre-existing bugs the consult surfaced (verified in code, fixed first)

**(a) `6022013` — per-point data alignment.** `MultiPointTemplate` stored each
point's data-variable locations as `first(indices):last(indices)` **ranges**,
with a source comment admitting the indices "may not be contiguous", while
`evaluate_multipoint_template` appended `data_values` sequentially. The
`data_values[i] ↔ data_vars[i]` alignment that solve-time substitution depends
on therefore held only as an unguarded accident of construction order;
interleaved indices would have evaluated data at the wrong time points
silently. Now `per_point_data_var_indices::Vector{Vector{Int}}` (exact lists,
partition asserted) and evaluation pre-allocates `fill(NaN, n)` and fills **by
index**, so alignment holds under any ordering.

**(b) `007aacd` — Σ_d observable matching.** `_match_obs_name` had a
`startswith` prefix fallback: base `"y1"` could match observable `"y10"`
depending on dictionary iteration order, wiring one observable's estimator
covariance into another's Σ_d rows. Same silent-mismatch class as the July P0#4
`lookup_value` prefix fallback removed in `ad07cd5`. Now exact-match only.

### 3.3 Steps 1–3

- **`4c63690` (step 1)** — `DataVarMeta(clean_name, obs_idx, order, point, kind)`
  aligned 1:1 with `data_vars`, computed by a shared `_build_data_var_meta` in
  **both** template builders (generic and noise-frontier; same `_ptK` convention
  verified). Labels are demoted to display-only for Σ_d purposes.
- **`ee58a68` (step 2)** — `StackedJetInfluenceEstimate` and the vector-of-times
  method of `joint_derivative_estimator_covariance`:
  `Σ = W_stack Σ_y W_stackᵀ`, PSD by construction. PSD handling per the consult:
  symmetrize + eigen-clip negatives to zero, warn only when materially
  indefinite, and **preserve genuine singularity** (repeated times) rather than
  shifting it away — `S Σ_d Sᵀ` needs no inverse. `stacked_jet_index` maps
  (time, order) → row.
- **`3639457`** — `_ift_solve`: always the factorized solve. Above the
  conditioning threshold it warns and returns `degraded = true` instead of the
  old silent `pinv`, whose minimum-norm derivative **suppresses weak-direction
  sensitivity and makes the covariance overconfident exactly when conditioning
  is worst**. Exactly-singular returns an empty S. (Decision: "degrade loudly",
  explicitly including the single-point path.)
- **`d71a1ff` (step 3)** — `_compute_multipoint_data_sensitivity` in the new
  `src/core/diagnostics/multipoint_sensitivity.jl`. d̂ comes from
  `evaluate_multipoint_template` (exactly the vector the solver consumes); x̂ is
  θ̂ plus per-point state jets. Returns the root-residual and conditioning gates
  plus the linearization point. An unusable estimate now **degrades**
  (`:estimate_taylor_failed`) instead of propagating the Taylor builder's
  exception to callers.

**Status: paused after step 3**, at a clean boundary — the sensitivity exists
and is tested, wired into nothing. Steps 4–8 (metadata-driven Σ_d, RunContext
template handoff, point-1 physicalization, validation suite, Σ_y producers) are
specced but not started. Multipoint remains the right tool for *expanding* the
in-regime set later, since it lowers the per-point derivative order.

---

## 4. The BigFloat finding (investigated, benign, no action)

While debugging step 3 the multipoint compiled system function was observed
returning `BigFloat`. **Initial claim that this was multipoint-specific was
wrong.** A probe over three equation sources settled it:

```
si_template.equations          Rational{BigInt} => 6
single-point prod_eqs          Float64 => 4, Rational{BigInt} => 6
multipoint stripped_equations  Rational{BigInt} => 5

single-point fn output : BigFloat      single-point AD jac : BigFloat
multipoint  fn output  : BigFloat      multipoint  AD jac  : BigFloat
```

**Mechanism:** SIAN returns `Rational{BigInt}` coefficients, and Julia's
rational promotion resolves through the numerator type —
`promote_type(Rational{BigInt}, Float64)` → `promote_type(BigInt, Float64)` =
`BigFloat`. (With `Rational{Int}` it would be `Float64`, which is why the
first guess was wrong.)

**Every** compiled SI-template function in the codebase evaluates in extended
precision, and always has. It was invisible because `SensitivityReport` stores
`Matrix{Float64}` and narrows at construction; multipoint only *looked* special
because a test helper had a concrete `Vector{Float64}` signature.

**Verdict: correct but slow, and not slow enough to matter.** Measured
agreement between extended and narrowed results is exactly 0.0; cost is ~40 µs
per 8×8 AD Jacobian; and the hot paths (polish, HC solve) do not use
`_compile_system_function` at all — usage is confined to template construction,
selection probes, and diagnostics. A "floated-coefficient" control failed to
change the eltype (Symbolics re-normalizes the rebuild), so the *multiplier*
remains unmeasured; the absolute cost makes it moot. Logged, not chased.

Step 3 narrows **results** to Float64 at the boundary, never AD inputs —
narrowing inputs would strip the Dual partials and silently produce a zero
Jacobian.

---

## 5. What the validation campaign found

### 5.1 Exposure before this session

The estimate-conditioned path had run on exactly two synthetic models:
`simple()` (noiseless e2e test) and `two_exp` (N=20 at 1% noise). No nonlinear
model, no unidentifiable parameters, no transcendental models, no real data, no
PEB.

### 5.2 Nonlinear models (`af522a0`)

`lotka_volterra`, `vanderpol`, `fitzhugh_nagumo`, N=20 each at 1% noise.
**60/60 replicates crash-free** — the chain survives nonlinear dynamics and a
latent (unobserved) state. But **every report came back `:degenerate`.**

`diagnose_lv_replicate.jl` root-caused it, and it is neither ill-conditioning
nor a bug:

| stage | LV value |
|---|---|
| cond(J_x) at the estimate | 2940 (degrade path never fires) |
| required observable-jet order | **4** (prey-only observation) |
| Σ_d diagonal, order 0 → order 4 | 1.06e-5 → **0.195** |
| \|S\| on the high-order columns | 200 – 800 |
| resulting σ̂ on params of size 0.3–1.0 | 22 – 58 |
| max CV | ≈ 360 |

**The σ̂ is honest — about the wrong estimator.** It describes the *one-point
unpolished algebraic read*, which for LV at 1% noise is genuinely hopeless. The
estimates we *report* are polished full-trajectory fits with error ~1e-3, so
single-point IFT overstates the reported estimator's uncertainty by ~1e4–1e5.
The continuum is consistent: two_exp (low orders) ~2× conservative,
`fitzhugh_nagumo`'s `g` near-calibrated (sd z = 1.88), LV vacuous. σ̂ is linear
in noise — at 1e-5 noise the same read is a usable seed.

### 5.3 Scope reframe

> "We need to start working on UQ specifically for models where unpolished,
> single point estimations work, and really, ideally, from a single GPR SE
> estimator." — Oren, 2026-08-14

Σ_x **is** exactly the sampling covariance of the single-point algebraic solve
conditioned on one SE-kernel GP fit. Every calibration number to date compared
it against a *different* estimator. Restricting the claim to the regime where
that estimator is itself good makes the theory exact rather than approximate.

Two consequences: the report is **self-certifying** (`max_cv` / `:degenerate`
already says "out of regime" — no separate screening criterion is needed), and
coverage had **never** been measured against the UQ's own estimand.

### 5.4 Calibration confirmed against the UQ's own estimand

Configuration: `InterpolatorAGPUQ` only (no pool), `polish_solutions = false`,
`polish_solver_solutions = false`, `use_multipoint = false`, single point —
i.e. the estimator Σ_x describes. N=10 per cell.

| model | noise | med\|z\| (target 0.674) | p90\|z\| (target 1.64) | coverage | med relerr vs med σ̂ |
|---|---|---|---|---|---|
| `simple` | 1e-4 | 0.50 – 0.91 | 1.04 – 1.49 | 90–100% | 2.7e-5 vs 2.0e-5 ✓ |
| `simple` | 1e-2 | 0.72 – **1.46** | 1.33 – 2.40 | 70–100% | `a`: 4.0e-3 vs 1.3e-3 ✗ |
| `simple_linear_combination` | 1e-4 | 0.83 – 0.87 | 1.27 – 1.73 | 90–100% | 3.3e-5 vs 1.7e-5 ✓ |
| `simple_linear_combination` | 1e-2 | 0.96 – **2.02** | 3.1 – 4.0 | 50–80% | `b`: 6.4% vs 2.8% ✗ |
| `onesp_cubed` | 1e-4 | **0.16** – 1.00 | 0.35 – 2.06 | 80–100% | ✓ |
| `onesp_cubed` | 1e-2 | 0.67 – **1.89** | 1.36 – 3.83 | 50–100% | ✗ |

**At 1e-4 the calibration is genuinely correct** — median |z| of 0.5–0.9 against
the standard-normal 0.674, p90 of 1.0–1.7 against 1.64, σ̂ matching the realized
error to ~1.5×. This is the first validation of the UQ against the estimator it
actually describes.

**Polishing the same configuration makes the intervals conservative**
(med |z| 0.19–0.65, coverage 100%) — the predicted signature of describing a
worse estimator than the one being reported. The LV "failure" was estimand
mismatch, not broken machinery.

> ### ⚠ RETRACTED, THEN PARTIALLY REINSTATED AT N=60 — read §5.4b
>
> An earlier draft claimed systematic overconfident degradation with noise
> (σ̂ 2–3× too small, coverage 50–70% at 1e-2). **The magnitude was wrong and
> the N=10 evidence could not support it** — but the N=60 confirmation
> (§5.4b) establishes that a **real, milder** effect exists: σ̂ ≈ 1.45× too
> small at 1e-2, coverage 80–97%, significant at 3σ on all four coordinates
> simultaneously. So: right direction, overstated magnitude, and originally
> inferred from evidence too noisy to carry it. The sampling-noise analysis
> below stands and is why the N=60 run was necessary.
>
> The noise sweep (§5.4a) re-ran `simple` @ 1e-2 at different seeds and got
> med|z| = [0.65, 1.0, 1.0, 0.89] where the screen had reported
> [1.46, 0.79, 0.93, 0.72]. Both are draws from the same truth.
>
> **The arithmetic that should have been done first:** the sampling sd of
> median|z| over N replicates is ≈ 1/(2 f(0.674) √N) = 0.787/√N, where f is the
> density of |z| at its median. At N=10 that is **0.25**, so a perfectly
> calibrated coordinate lands anywhere in ≈ [0.17, 1.17] at 2σ. The
> `regime_verdict` band [0.34, 1.35] is therefore roughly a ±2σ window — about
> 5% of correctly calibrated coordinates are flagged by chance, and with 4–6
> coordinates per cell **a quarter or more of cells read "marginal" for no
> reason at all.** Every scattered verdict in §5.5 and §5.4a is consistent with
> this, `threesp_cubed` included.
>
> **Methodological rule going forward: N=10 cannot resolve calibration.** Use
> N ≥ 60 (sd ≈ 0.10) for any per-cell verdict, or report med|z| with its
> sampling interval rather than a binary.

### 5.4a Noise sweep — the corrected picture (`run_noise_threshold.jl`, N=10)

med|z| per coordinate, 1e-6 → 1e-2, single SE-GPR / unpolished / single point:

| model | 1e-6 | 1e-5 | 1e-4 | 1e-3 | 1e-2 | worst rel err (1e-6 → 1e-2) |
|---|---|---|---|---|---|---|
| `simple` | 0.26–1.1 | 0.81–1.0 | 0.39–0.72 | 0.57–0.82 | 0.65–1.0 | 0.0007% → 2.5% |
| `simple_linear_combination` | 0.49–0.77 | 0.47–1.1 | 0.73–0.89 | 0.32–0.76 | 0.49–1.2 | 0.0008% → 2.3% |
| `onesp_cubed` | 0.14, 1.1 | 0.19, 1.3 | 0.19, 1.1 | 0.22, 1.4 | 0.38, 1.3 | 0.0004% → 1.2% |
| `threesp_cubed` | 0.08–0.64 | 0.23–2.7 | 0.09–1.3 | 0.16–0.78 | 0.59–1.6 | 0.0003% → 2.0% |

**There is no monotone degradation with noise.** med|z| sits in roughly 0.5–1.2
across four orders of magnitude while the estimator's own error grows by four
orders of magnitude — i.e. **σ̂ tracks the realized error across the whole
range.** That is a stronger result than the retracted one.

Two patterns that survive the sampling-noise caveat because they are consistent
across *several* cells rather than one:

- **Low-noise conservatism.** `onesp_cubed`'s first coordinate sits at
  med|z| = 0.14–0.22 for 1e-6 through 1e-3 (σ̂ several times too large), and
  `threesp_cubed`'s three parameter coordinates behave the same way. Consistent
  with a floor in the GP's learned observation-noise variance: below some level
  the GP cannot learn σ, so σ̂ stops shrinking. **Checkable and worth checking.**
- **`threesp_cubed` splits by role** — parameters conservative, states near or
  above 1. Not obviously a bug; needs N ≥ 60 before interpreting.

### 5.4b N=60 confirmation — the settled numbers (`run_calibration_confirm.jl`)

At N=60 the sampling sd of median|z| is 0.10, so deviations from the calibrated
target 0.674 are quoted in sampling-σ units. **These are the numbers to trust.**

| cell | coord | med\|z\| | dev | verdict | coverage | med relerr / med σ̂ |
|---|---|---|---|---|---|---|
| `simple` @ 1e-4 | a | 0.618 | −0.6σ | **calibrated** | 86.7% | — |
| | b | 0.754 | +0.8σ | **calibrated** | 90.0% | 3.03e-4 / 3.17e-4 |
| | x1 | 0.752 | +0.8σ | **calibrated** | 96.7% | 1.78e-5 / 8.13e-6 |
| | x2 | 0.686 | +0.1σ | **calibrated** | 86.7% | 4.67e-5 / 4.23e-5 |
| `simple` @ 1e-2 | a | 0.985 | +3.1σ | overconfident | 86.7% | 2.65e-3 / 1.16e-3 |
| | b | 0.988 | +3.1σ | overconfident | 96.7% | 2.85e-2 / 2.30e-2 |
| | x1 | 1.01 | +3.3σ | overconfident | 80.0% | 1.58e-3 / 5.07e-4 |
| | x2 | 0.993 | +3.1σ | overconfident | 91.7% | 4.35e-3 / 3.14e-3 |
| `onesp_cubed` @ 1e-5 | a | 0.206 | −4.6σ | **conservative** | 100% | 3.52e-5 / 1.68e-5 |
| | x1 | 1.38 | +6.9σ | **overconfident** | 70.0% | 1.72e-6 / 2.46e-6 |

Three conclusions, all now resting on adequate N:

1. **`simple` at 1e-4 is calibrated**, unambiguously — all four coordinates
   within 0.8σ of the standard-normal target. This is the clean demonstration
   that the UQ is correct for its own estimand.
2. **Noise degradation is real but mild.** All four coordinates move to
   med|z| ≈ 0.99 at 1e-2 — a coherent +3σ shift, far too consistent to be
   chance. That is σ̂ ≈ **1.45×** too small (0.99/0.674), with coverage
   80–97%, *not* the 2–3× and 50–70% originally claimed. Consistent with the
   first-order delta method starting to bite; the effect is small enough that
   it does not disqualify 1e-2 for practical use.
3. **`onesp_cubed` splits by role, and it is not sampling noise**: the
   parameter `a` is conservative at −4.6σ (σ̂ ~2× too large, 100% coverage)
   while the state `x1` is overconfident at +6.9σ (70% coverage). A single
   model cannot be simultaneously over- and under-dispersed by accident — this
   is structural and is **the highest-value thing to investigate next**,
   displacing the `threesp_cubed` lead. The low-noise conservatism of §5.4a is
   confirmed here as real.

### 5.5 Regime screen (7 models × 2 noise levels)

| model | 1e-4 | 1e-2 |
|---|---|---|
| `simple` | in_regime | in_regime |
| `simple_linear_combination` | in_regime | out_of_regime |
| `onesp_cubed` | in_regime | in_regime |
| `threesp_cubed` | **marginal** | **marginal** |
| `vanderpol` | out | out |
| `fitzhugh_nagumo` | out | out |
| `lotka_volterra` | out | out |

> These verdicts predate the `regime_verdict` band tightening
> (`[0.15, 2.5]` → `[0.34, 1.35]`, a factor of 2 around 0.674) applied in
> `875944c` — the loose band passed a coordinate with 50% coverage. The 1e-2
> `in_regime` cells should be re-run to confirm.

`threesp_cubed` at **marginal** (accurate estimator, mis-scaled interval) looked
like the one signature that would indicate a genuine bug in the covariance
chain. **Downgrade that reading** in light of §5.4: at N=10 a quarter of cells
read marginal by chance, and `threesp_cubed` has six coordinates, so it is the
*most* likely model to be flagged spuriously. Its one non-random-looking feature
is the parameter/state split noted in §5.4a. Re-check at N ≥ 60 before
investigating.

### 5.6 `two_exp` is not scorable by name — and a paper flag

`y = x1 + x2` is invariant under (x1,k1) ↔ (x2,k2), so the solver may return an
equally valid relabelled root. `probe_two_exp_labels.jl`:

```
rep  k1_hat   k2_hat    verdict     (truth k1 = 0.6, k2 = 3.0)
2    4.5255   0.78193   SWAPPED
3    3.9290   0.70861   SWAPPED
4    4.7504   0.75833   SWAPPED
6    3.7841   0.62874   SWAPPED
5    0.7999   3.4595    identity
1    1.2209  -5.3247    identity (bad solve: negative rate)
```

4 of 6 replicates swapped. Name-based scoring is meaningless there. Note also
that even the correctly-assigned replicates are 15–33% off, so two_exp is
marginal-to-out-of-regime at 1% anyway.

> **PAPER FLAG.** The TAC anchor's 95% / 82% coverage numbers were produced by a
> **truth-started estimator**. That legitimately validates covariance
> *propagation* (Σ_y → W → Σ_d → S → Σ_x) but is **not** calibration of the
> delivered method, because the pipeline's estimator neither starts at truth nor
> stays on the identity branch. Worth settling before the manuscript leans on
> those numbers.

### 5.7 Harness hardening (`875944c`)

The earlier summary statistics were not trustworthy:

- **median |z| and p90 |z| replace mean/sd.** One degenerate-σ̂ replicate
  produced |z| ~ 1e7 and destroyed the summaries; the giveaway was
  sd/mean = 2.236 = √5 exactly, the fingerprint of one outlier among five with
  the rest near zero.
- **Degenerate-σ̂ replicates are counted, not averaged in** — an infinite z is an
  unusable measurement, not a coverage miss.
- **The estimator's own median relative error is reported** alongside coverage,
  because an interval wide enough to cover everything while saying nothing is
  the out-of-regime signature (LV: 100% coverage with 4030% relative error).
- `regime_verdict` requires **both** accuracy and calibration.

---

## 6. Testing

### 6.1 Test files added (7)

| file | tier | what it pins |
|---|---|---|
| `test_taylor_propagation.jl` | fast_unit + runtests | jet recursion vs matrix-power reference on a linear system; GP-jet Taylor-shape round-trip; mis-sized anchor throws |
| `test_estimate_conditioned_uq.jl` | runtests | estimate Taylor ≡ oracle Taylor when estimate = truth; S(:estimate) ≈ S(:oracle) on clean data; **S bit-identical when `p_true`/`ic` are stripped to NaN** (the real-data capability); kwarg contracts; full-pipeline `compute_uncertainty` smoke |
| `test_uq_coverage_smoke.jl` | runtests | N=20 two_exp coverage tripwires (~1 min) |
| `test_exact_index_matching.jl` | fast_unit + runtests | interleaved per-point index lists (the range-collapse regression); `y1` vs `y10` exact matching; `DataVarMeta` classification incl. bounded `y<N>` fallback |
| `test_stacked_jet_covariance.jl` | runtests | fixed-hyperparameter **Monte Carlo** vs the factorized matrix (homoscedastic + heteroscedastic); cross-block orientation `C_ij = C_jiᵀ`; scalar-method consistency; repeated-time singularity **preserved** |
| `test_ift_solve.jl` | fast_unit + runtests | well-conditioned identity; ill-conditioned keeps amplification visible + flag; exactly-singular returns empty |
| `test_multipoint_sensitivity.jl` | runtests | **finite-difference validation of every S column** (Newton re-solve of the same root branch under a perturbed data coordinate); shape/label/role contracts; eltype narrowing; gate values; degrade-not-throw guards |

The finite-difference test is the strongest check in the set: it validates
variable ordering, the solve/data partition, the Jacobian, and the sign
convention simultaneously, against a numerically independent computation.

### 6.2 Gate progression

| after | full FAST gate |
|---|---|
| baseline `59eafb0` | 1170 |
| `10c7380` | 1218 |
| `ccbeb8b` | 1237 |
| `007aacd` | 1250 |
| `ee58a68` | 1306 |
| `3639457` | 1314 |
| `d71a1ff` | **1344** |

`fast_unit` 186 → 232. `fast_core` 415 → 442. Every commit merged only on a
green full gate; `--ff-only`, both branches pushed.

### 6.3 Test failures encountered and what they taught

- **`_mps_newton` MethodError** — the Newton iterate promoted to
  `Vector{BigFloat}`, which is how the BigFloat promotion was discovered at all.
- **NaN-estimate guard threw instead of degrading** — `compute_estimate_taylor_coefficients`
  raised before the `all(isfinite, x_hat)` guard could run. Fixed in the
  *source* (callers need a status, not an exception), not the test.
- **Two adjacent docstrings** silently broke package load; `Meta.parseall` does
  **not** catch doc-attachment errors, only a real `using` load does.
- **`julia … | tail` masks the exit code** — a background task reported exit 0
  on a load failure. All gate invocations now use `set -o pipefail`.

---

## 7. Conclusions

1. **The UQ machinery is correct, and now proven correct against its own
   estimand.** At low noise on small systems the intervals are calibrated to the
   standard-normal quantiles, with σ̂ matching realized error. This had never
   been measured before — every prior number compared against a different
   estimator.
2. **The regime is defined jointly by model *and* noise level.** Not a list of
   models. The failure mode as noise grows is systematic overconfidence from the
   first-order delta method.
3. **`:degenerate` is a feature.** The report already self-certifies when a
   model is out of regime; no separate screening criterion is needed.
4. **The gap between the algebraic estimator and the reported (polished)
   estimator is the central open question in this area.** Multipoint UQ narrows
   it by lowering per-point derivative order; a polish-aware covariance would
   close it directly but is a different estimand.
5. Two long-standing silent-data bugs were removed (per-point index alignment,
   observable prefix matching), both of the "wrong values, no error" class.
6. The BigFloat promotion is real, universal, benign, and not worth chasing.

## 8. Open decisions and next steps

**Needs Oren's decision:**

- **Exact-GP reuse** (Sol trap #7, now load-bearing): `_compute_uq_result`
  refits a fresh `agp_gpr_uq` setup instead of reusing the estimation
  interpolants, so W may not come from the exact GP that produced the estimate.
  For a "single SE GPR estimator" claim to be exact this should be wired —
  requires threading `setup_data` into `_compute_uq_result` (an API change).
- **TAC anchor re-framing** in the paper (§5.6).
- Version call for the pre-release breaks (`CHANGELOG.md`, still open).

**Queued work, in value order:**

1. Dissect `threesp_cubed` — the one *marginal* cell, where a genuine covariance
   bug would hide.
2. Re-run the 1e-2 cells under the tightened `regime_verdict` band.
3. Finish the noise-threshold grid; publish per-model ceilings.
4. Resume multipoint UQ steps 4–8 to expand the in-regime set.
5. Σ_y producers (residual/effective-df, sandwich) as **internal** alternatives —
   decision recorded: the user should never supply a covariance matrix, it is
   part of the algorithm.
6. Salvage ~350 reusable lines from `deprecated/test_uncertainty_quantification.jl`.

## 9. Reproducing the findings

```bash
# calibration against the UQ's own estimand (unpolished vs polished arms)
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_single_point_regime.jl

# model × noise regime classification (optional model-name filter)
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_regime_screen.jl simple onesp_cubed

# per-model noise ceiling
julia --startup-file=no repro/uq_coverage_harness_2026_08/run_noise_threshold.jl

# why LV reports :degenerate — the full stage-by-stage breakdown
julia --startup-file=no repro/uq_coverage_harness_2026_08/diagnose_lv_replicate.jl

# label-switching demonstration on two_exp
julia --startup-file=no repro/uq_coverage_harness_2026_08/probe_two_exp_labels.jl
```
