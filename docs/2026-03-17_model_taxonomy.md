This document records the current working taxonomy after the structural-fix cleanup, unsupported-model gate, rescue-path hardening, and focused model investigations.

## Core Flow Conclusions

- Structural identifiability in the standard SI flow now comes from `SI.jl` / `StructuralIdentifiability`.
- The old multipoint Jacobian/nullspace layer is now advisory-only. It may influence heuristic derivative depth and point-count choices, but it no longer defines `all_unidentifiable`.
- Structural representative fixing is now explicit. The old iterative square-repair loop is no longer part of the supported default flow.
- If the SI template remains non-square after structural fixing, the default path throws early instead of trying to repair it heuristically.

## Current Model Buckets

### Green

Straightforward maintained examples that currently run well enough to present as supported examples.

Representative cases:
- `simple`
- `lotka_volterra`
- `sum_test`
- `dc_motor`
- `quadrotor_altitude`
- `bicycle_model`
- `bilinear_system`
- `maglev_linear`
- `two_tank_poly`

### Structural Unidentifiability

Models kept specifically as structural-identifiability demonstrations.

Representative cases:
- `trivial_unident`
- `global_unident_test`
- `substr_test`
- `aircraft_pitch`
- `dc_motor_identifiable`
- `mass_spring_damper`
- `two_compartment_pk`
- `treatment`

### Hard

Models that run through the supported flow, but are slower, less accurate, more weakly identified, or otherwise not suitable as straightforward examples.

Representative cases:
- `fitzhugh_nagumo`
- `biohydrogenation`
- `crauste_corrected`
- `boost_converter_identifiable`
- `boost_converter_sinusoidal`
- `magnetic_levitation`
- `cstr_fixed_activation`
- `cstr_reparametrized`
- `sirsforced`

Notes:
- `magnetic_levitation` was previously failing because sampling silently accepted an unstable truncated trajectory. It now fails early and clearly if sampling is invalid, and the raw model has been recalibrated to a sane operating point. It still remains a hard, heavily unidentifiable model.
- `sirsforced` now runs. Its remaining issue is non-core: algebraic state-resolve rescue can trigger an upstream Groebner/StructuralIdentifiability failure on some bad candidates, but that rescue path is now candidate-local and non-blocking.
- `cstr_fixed_activation` is slow but workable.
- `cstr_reparametrized` runs, but is very slow and currently recovers poorly even under patient settings.

### Limitations

Models retained in-package for known unsupported classes, explicit backend limits, or unresolved failure modes that are no longer treated as active mysteries.

Representative cases:
- `cart_pole`
- `ball_beam`
- `swing_equation`
- `tank_level`
- `two_tank`
- `cstr`
- `crauste_revised`
- `seir`
- `boost_converter`
- `crauste`

## Failure Taxonomy

### Expected Unsupported Raw Nonlinear Classes

These are not active bugs in the supported SI/local-identifiability flow. They should fail early and clearly.

- Raw state trigonometric dependence such as `sin(theta)` or `cos(theta)`
  - examples: `ball_beam`, `cart_pole`, `swing_equation`
- Raw `sqrt(...)` state dependence
  - examples: `tank_level`, `two_tank`
- Raw unsupported transcendental state dependence such as Arrhenius `exp(...)`
  - example: `cstr`

Current policy:
- reject these before the old multipoint Jacobian path with `UnsupportedModelClassError`
- do not keep surfacing them as “symbolic substitution bugs”

### High-Order SI Derivative Limit

This is a real contract mismatch between SI template demands and the current numeric derivative backend.

- example: `crauste_revised`
- the advisory/setup layer only asks for modest derivative orders
- the SI template can still request much higher observable derivatives
- `crauste_revised` asked for derivatives up to order `22`
- the current TaylorDiff-backed numeric derivative backend is explicitly guarded at order `20`

Current policy:
- fail early with `UnsupportedDerivativeOrderError`
- treat this as a known backend limitation, not as a vague SI or Symbolics bug

See also:
- [2026-03-17_high_order_si_derivative_limit.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_high_order_si_derivative_limit.md)

### Non-Core Rescue Warnings

These are failures in opportunistic rescue logic, not in the main estimation algorithm.

- example: `sirsforced`
- main SI/HC solve succeeds
- some bad candidates later trigger algebraic-resolve rescue
- that rescue can fail upstream in Groebner / StructuralIdentifiability

Current policy:
- algebraic-resolve rescue is candidate-local and best-effort
- rescue failures add provenance notes and do not fail the model run

### Degenerate Late-Stage Reconstruction

These are edgy cases where the main solve works but a late reconstruction or rescue step is degenerate at a particular timepoint.

- example: `seir`
- the `t=0` algebraic re-solve is partially singular because one observed quantity is zero there

Current policy:
- treat this as a late-stage edge case, not as a core construction issue
- do not let it drive major architectural changes unless more models show the same pattern

## CSTR Family

The CSTR family now separates cleanly into:

- `cstr`
  - expected unsupported raw transcendental model because of raw `exp((-E_R) / T(t))`
- `cstr_fixed_activation`
  - supported transformed variant
  - large but workable square system
  - with `datasize=1000`, completed in about `1212s`
  - best max relative error on identifiable quantities about `0.165`
- `cstr_reparametrized`
  - supported transformed variant
  - larger and slower square system
  - with `datasize=1000`, completed in about `4344s`
  - best max relative error on identifiable quantities about `1.29`

So the current interpretation is:
- raw `cstr` belongs in limitations
- `cstr_fixed_activation` belongs in hard but workable
- `cstr_reparametrized` belongs in hard and currently poor

## Iterative Fixing Retrospective

The iterative-fixing audit was useful, but the current interpretation has changed.

What we learned:
- the old loop was mostly, and possibly entirely in the sampled catalog, doing structural representative fixing rather than residual template repair
- after splitting structural fixing from residual repair, the residual repair branch appeared effectively unused in normal practice

Current policy:
- supported flow uses structural fixing only
- residual square-repair is not part of the supported default path

The original audit is still useful as a historical artifact:
- [2026-03-15_iterfix_audit.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-15_iterfix_audit.md)

## Practical Reading Guide

When triaging a model now, ask in this order:

1. Is this an unsupported raw nonlinear model class?
2. Is this an SI-template / backend contract limit such as unsupported derivative order?
3. Is the main run succeeding and only a non-core rescue path failing?
4. Is the model simply hard, slow, or weakly identified rather than broken?

That ordering matches the current code contract better than the older “everything is a bug until proven otherwise” interpretation.
