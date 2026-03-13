# SI Placeholder Inventory

## Purpose

Inventory which SI placeholder categories are actually exercised by the current package flow before turning any of them into unconditional hard failures.

## Baseline Used

The main inventory run covered all models in:

- `GREEN_MODELS`
- `STRUCTURAL_UNIDENTIFIABILITY_MODELS`
- `HARD_MODELS`

using a more realistic baseline than the old smoke profile:

- `datasize = 101`
- `noise_level = 0.0`
- `shooting_points = 2`
- `use_parameter_homotopy = true`
- `polish_solver_solutions = true`
- `polish_solutions = false`
- `interpolators = [InterpolatorAAAD, InterpolatorAGPRobust]`

## Coverage

- Models covered: `56`
- Successful runs: `56`
- Errors in this main run: `0`

A smaller follow-up spot-check on limitation models was started separately. It was not needed for the main conclusion.

## Main Result

Note: this inventory was gathered before the SI mapping vocabulary was redesigned. The underlying behavior is still the same, but the runtime category names have since been clarified:

- `:dd_derivative_unmapped` -> `:observable_derivative_overflow`
- `:nonobservable_derivative` -> `:state_or_input_jet`
- `:unknown_variable` split into:
  - `:sian_auxiliary` for `z_aux`
  - `:true_unknown_variable` for anything genuinely unmapped

Across all 56 realistic runs, every model exercised all of these placeholder categories:

- `:dd_derivative_unmapped`
- `:nonobservable_derivative`
- `:unknown_variable`

None of the 56 runs exercised:

- `:dd_observable_index_oob`
- `:no_dd_derivative`
- `:late_map_miss`

## Aggregate Counts

Across the 56-model main run:

- `:dd_derivative_unmapped`: `326`
- `:nonobservable_derivative`: `450`
- `:unknown_variable`: `90`

Model coverage:

- `:dd_derivative_unmapped`: `56 / 56`
- `:nonobservable_derivative`: `56 / 56`
- `:unknown_variable`: `56 / 56`

## What The Categories Look Like

Representative samples from the inventory:

- `:dd_derivative_unmapped`
  - `y1_7`, `y2_10`, `y4_12`
  - transformed-observable derivatives such as `_obs_trfn_cos_2_0_cos_9`

- `:nonobservable_derivative`
  - state/IC-style symbols such as `x1_0`, `x2_1`, `theta_0`, `omega_0`
  - transformed-input symbols such as `_trfn_sin_2_0_0`, `u_cos_0`

- `:unknown_variable`
  - overwhelmingly `z_aux`

This means the three common categories are not rare mismatch paths in the current implementation. They are part of the normal SI-to-ODEPE plumbing.

## Practical Interpretation

### `:dd_derivative_unmapped`

This is currently expected behavior, not an obvious bug category.

It mostly reflects high-order observable derivatives that are requested by SIAN but not present in the finite `DD.obs_lhs` derivative stack we built.

### `:nonobservable_derivative`

This is also currently expected.

It captures derivative-like or `_0`-suffixed symbols that are not measured-observable derivatives at all, so they cannot map through `DD.obs_lhs`.

### `:unknown_variable`

In practice this is mostly `z_aux`.

That strongly suggests there is one recurring auxiliary-symbol pathway in the SI conversion flow, not a broad family of random unmapped symbols.

## Post-Refactor Interpretation

After the SI mapping refactor, these now surface as:

- `:observable_derivative_overflow`
- `:state_or_input_jet`
- `:sian_auxiliary` / `:true_unknown_variable`

A representative post-refactor probe on `simple` now reports:

- `:observable_derivative_overflow = 4`
- `:state_or_input_jet = 5`
- `:sian_auxiliary = 1` with sample `z_aux`

That confirms `z_aux` is no longer being bucketed as a generic unknown.

## Implications For Cleanup

### Safe conclusion

Do **not** make these categories unconditional hard failures in the current design:

- `:dd_derivative_unmapped`
- `:nonobservable_derivative`
- `:unknown_variable`

Doing so would break essentially every supported model.

### Still promising as strict guardrails

The categories that did **not** appear in the 56-model main run are still the best candidates for tightening:

- `:dd_observable_index_oob`
- `:no_dd_derivative`
- `:late_map_miss`

Of these, `:dd_observable_index_oob` already has a gated hard-fail path and was A/B tested on representative models without changing outcomes.

## Recommended Next Steps

1. Keep category-gated hard-fail support, but only use it on rare categories for now.
2. Investigate the origin and meaning of `z_aux`.
3. Redesign the readable SI mapping flow around the real semantics observed here:
   - observable-derivative overflow
   - non-observable derivative-like symbols
   - explicit auxiliary symbols
4. Only after that redesign, reconsider whether some of the currently-common categories can disappear entirely.
