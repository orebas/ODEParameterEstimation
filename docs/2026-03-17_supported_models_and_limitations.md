# Supported Models and Limitations

This guide reflects the package state as of 2026-03-17.

It is a short user-facing summary of the current support boundaries. For the fuller internal taxonomy, see [2026-03-17_model_taxonomy.md](/home/orebas/.julia/dev/ODEParameterEstimation/docs/2026-03-17_model_taxonomy.md).

## What the Standard Flow Is Good At

The current standard path is best understood as:

- SI-template-based estimation for supported polynomial or rational-style models
- explicit handling of structural unidentifiability through structural representative fixes
- multi-interpolator and multi-shot estimation for models that fit the supported symbolic contract

Representative maintained examples:

- `simple`
- `lotka_volterra`
- `dc_motor`
- `bicycle_model`
- `bilinear_system`
- `quadrotor_altitude`

These are good starting points for users.

## Structural-Unidentifiability Is Supported

The package does support models whose structure implies some variables are not uniquely identifiable.

Representative examples:

- `trivial_unident`
- `global_unident_test`
- `substr_test`
- `two_compartment_pk`

Current behavior:

- structural identifiability comes from `SI.jl` / `StructuralIdentifiability`
- structural representative fixes are recorded in `best.provenance.structural_fix_set`
- `best.all_unidentifiable` reports the structural-unidentifiable set

## Hard but Valid Models

Some models run through the supported flow but are harder, slower, or less reliable as demonstrations.

Representative examples:

- `magnetic_levitation`
- `fitzhugh_nagumo`
- `crauste_corrected`
- `cstr_fixed_activation`
- `cstr_reparametrized`
- `sirsforced`

Use these as stress cases or investigations, not as first examples.

## Expected Unsupported Raw Model Classes

These are not treated as active bugs in the supported flow. They should fail early and clearly.

Examples:

- raw state trigonometric dependence such as `sin(theta)` or `cos(theta)`
- raw `sqrt(...)` state dependence
- raw unsupported transcendental state dependence such as Arrhenius `exp(...)`

Representative package examples:

- `ball_beam`
- `cart_pole`
- `swing_equation`
- `tank_level`
- `two_tank`
- raw `cstr`

Current policy:

- reject these with `UnsupportedModelClassError`
- do not treat them as ordinary supported examples

## Explicit Backend Limits

One important current limit is very high observable-derivative demand from SI templates.

Representative example:

- `crauste_revised`

Current behavior:

- the numeric derivative backend is explicitly guarded at derivative order `20`
- if the SI template asks for more than that, the run fails with `UnsupportedDerivativeOrderError`

This is a known backend limitation, not just a vague solver crash.

## Practical Reading Rule

If a model behaves badly, ask in this order:

1. Is it an unsupported raw nonlinear model class?
2. Is it a known backend limitation such as derivative order?
3. Is it simply hard, slow, or weakly identified rather than broken?

That ordering is usually more accurate than assuming every failure is a core bug.
