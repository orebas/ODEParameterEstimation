# Transform-aware bounds bug

Date: 2026-06-19

Status: documented for follow-up. This is not yet fixed.

## Summary

When a parameter-estimation problem is transformed before polishing, user-supplied vector bounds can silently stop applying. The known failing case is a model with automatic transcendental handling enabled, where support states such as `_trfn_sin_*` and `_trfn_cos_*` are inserted into the state vector after the caller has already supplied `opt_lb` and `opt_ub` for the original unknowns.

The current code only uses `opts.opt_lb` and `opts.opt_ub` if their lengths exactly match the transformed unknown vector length. If the lengths do not match, the polish context falls back to broad default bounds without an error. This can allow polished estimates outside the benchmark box that the caller intended to enforce.

This should be treated as a package bug, not just a benchmark-documentation issue.

## Concrete evidence

The archived final-v2 benchmark CSTR cell

```text
/home/orebas/ParameterEstimationBenchmark-local/results/final_v2_2026_06_12/results/odepe_v2_polish_run/cstr_2_1em2
```

supplies bounds for the original CSTR unknown vector:

```julia
opt_lb = 1e-05 * ones(length(ic) + length(p_true))
opt_ub = 10.0 * ones(length(ic) + length(p_true))
polish_method = PolishLSOBoundedLog
```

For that model, `length(ic) + length(p_true) == 7`.

However, the metadata for the same run shows that the transformed model used during estimation has five states and four parameters:

```text
states: C(t), Temp(t), _trfn_cos_0_5(t), _trfn_sin_0_5(t), r_eff(t)
params: tau, Tin, dH_rhoCP, UA_VrhoCP
```

so the transformed polish vector length is 9, not 7.

The selected polished estimate in `result.csv` contains values outside the intended positive box:

```text
r_eff(t)       = -0.2674389427489551
C(t)           = 799.7973009681007
dH_rhoCP       = -3.3501211616551642e-6
```

The corresponding `pool.csv` row has `polish_source_hc_idx=58`, `primary_method=algebraic`, and `source_type=single_point`, so this is a selected polished candidate, not only an unpolished algebraic candidate or a hand-edited reporting artifact.

The source raw candidate for this polished result was already outside the intended positive box: it had `UA_VrhoCP` slightly below zero and `r_eff(t)` negative before polishing. Thus this was not a case where strict candidate filtering enforced the requested box but polishing escaped it. In this transformed case, the intended box was not acting as a hard filter on the raw candidate pool either.

## Root cause path

The relevant code path is:

1. `src/core/analysis_utils.jl`
   - `analyze_parameter_estimation_problem` applies `transform_pep_for_estimation` before rescaling and estimation.
   - Automatic transcendental handling can insert support states into the problem.

2. `src/core/problem_rescaling.jl`
   - `rescale_option_bounds(opts, scale_info, PEP)` rescales option bounds after transformation.
   - Its helper returns the original vector unchanged when the vector length does not match the transformed scale vector.
   - There is no warning or error on this mismatch.

3. `src/core/parameter_estimation.jl`
   - `_build_polish_context` uses user-supplied bounds only when `length(opts.opt_lb) == p_size` and `length(opts.opt_ub) == p_size`.
   - If the lengths do not match, it silently calls `compute_default_bounds`.
   - These default bounds are broad and symmetric, so negative or very large values can be accepted even when the caller intended a positive box.

4. `src/core/parameter_estimation_helpers.jl`
   - `_clamp_params_for_backsolve` also no-ops when bound lengths do not match, which can hide the same issue in backsolve-related paths.

## Affected scope

This affects any workflow where bounds are supplied positionally for the original state/parameter vector and the estimation problem is later transformed by adding, removing, or reordering variables.

The clearest current trigger is `auto_handle_transcendentals=true`, especially for models with time-dependent inputs represented by `sin`, `cos`, or related support variables.

In the final-v2 benchmark configuration, systems with sinusoidal inputs include:

```text
aircraft_pitch
bicycle_model
boost_converter
cstr
dc_motor
forced_lotka_volterra
quadrotor
```

A quick scan of selected polished results outside the intended `[1e-5, 10]` box found visible out-of-box selected estimates for:

```text
aircraft_pitch
cstr
```

The absence of out-of-box selected estimates in the other transformed systems does not prove they were unaffected. It only means the selected first-row outputs did not visibly violate that box.

The `odepe_shade` baseline should not be treated as affected by this specific transformation bug. Although SHADE uses `_build_polish_context`, it calls that context directly on the original ODE problem and does not run the algebraic `transform_pep_for_estimation` path that introduces `_trfn_*` support states. For example, the archived `odepe_shade` CSTR metadata reports only the original states `C(t)`, `Temp(t)`, and `r_eff(t)`, whereas the proposed-method CSTR metadata includes `_trfn_cos_0_5(t)` and `_trfn_sin_0_5(t)`. Therefore, in SHADE, the original-length `[1e-5, 10]` bound vector matches the optimization vector for this issue.

This also matters for any future transformation pass, not just transcendental support states.

## Why padding the bounds is not enough

The inserted `_trfn_*` states are not ordinary positive unknowns. For example, a support state for `sin(t)` can have initial value zero, which would violate a positive lower bound such as `1e-5`.

Therefore, simply padding the original `[1e-5, 10]` vector to match the transformed state length would be incorrect. The bounds need to be mapped by variable identity and by semantic role.

## Recommended fixes

1. Stop silently falling back to default bounds.

   If a user supplies `opt_lb` or `opt_ub` and the length does not match the active unknown vector, the package should throw an error by default. A warning is probably too weak for benchmark or publication workflows.

2. Introduce transform-aware bounds.

   Internally, bounds should be represented by variable identity rather than only by vector position. A `BoundSpec` or equivalent structure should be resolved after all model transformations and rescaling have completed.

3. Map original bounds by symbol.

   Bounds for original states and parameters should be attached to their corresponding transformed variables by name or canonical variable identity. Inserted support states should not inherit ordinary state bounds by position.

4. Treat deterministic support states specially.

   Support states introduced for known inputs should be fixed or separately constrained according to their analytic definition and known initial value. They should not be estimated as ordinary free positive initial conditions unless that is explicitly requested.

5. Add a final bound invariant.

   After polishing and unrescaling, every original user-bounded estimated quantity should be checked against the requested bound interval. Out-of-bounds candidates should be rejected or marked failed, not reported as valid bounded-polish estimates.

6. Make benchmark configuration explicit.

   The benchmark layer should record both the user-requested original bounds and the actual active polish bounds after transformations. This metadata should be written with each run.

## Suggested tests

1. A transformed toy problem with `sin(t)` input and original-vector bounds should fail loudly until transform-aware bounds are implemented.

2. Symbol-keyed bounds should survive transformation and rescaling.

3. Inserted `_trfn_*` support states should not receive the original positive state bounds by position.

4. `_build_polish_context` should error if explicit bounds are present but have the wrong length.

5. `_clamp_params_for_backsolve` should error or otherwise report mismatch when explicit bounds are present but have the wrong length.

6. Regression test: a CSTR-like transformed problem with requested `[1e-5, 10]` bounds should not return selected original estimates outside that interval.

## Benchmark and paper implications

The archived benchmark remains reproducible because the scripts and outputs record what was actually run. However, any manuscript language saying that the proposed polished method was uniformly constrained by the same `[1e-5, 10]` box as the optimizer baselines is too strong unless these transformed-bound cases are rerun with a fixed package.

For paper purposes, either:

1. remove or soften the uniform-bound claim for the proposed method, or
2. fix the package and rerun the affected transformed systems before keeping that claim.

The CSTR example should not display out-of-box polished parameter estimates while the surrounding benchmark protocol says those estimates were constrained to `[1e-5, 10]`.
