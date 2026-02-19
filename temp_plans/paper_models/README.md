# Paper Models — 25 Scaled ODE Systems for IEEE TAC Benchmarking

## Overview

This directory contains 25 ODE models selected for the IEEE TAC paper comparing
ODEParameterEstimation.jl against other parameter estimation frameworks. Each model
is provided in two forms:

1. **Original** (`original_models.jl`): Verbatim copies with physically meaningful parameter values
2. **Scaled** (`scaled_models.jl`): Transformed so all true parameter values and ICs are 0.5

## Why Scale?

The external testing harness randomizes ALL parameters and ICs uniformly from [0.1, 1.0].
By scaling each model so that 0.5 is the true value, random draws from [0.1, 1.0] explore
a meaningful range (20% to 200% of true value) around the actual physics.

## Scaling Formula

For parameter `p` with original true value `v`:
- Scale factor: `s = 2 * v`
- Relationship: `p_original = s * p_scaled`
- True value: `p_scaled = 0.5` (since `s * 0.5 = v`)

For zero ICs: perturbed to a small physically reasonable value first.
For negative values: negative scale factor preserves sign through the equation coefficients.

## Files

| File | Description |
|------|-------------|
| `original_models.jl` | 25 original model functions (~500 lines) |
| `scaled_models.jl` | 25 scaled model functions (~900 lines) |
| `scaling_report.md` | Per-model scaling tables and notes |
| `verify_scaling.jl` | Verification script (spot-checks + random blowup tests) |

## Usage with External Harness

```julia
include("scaled_models.jl")

# Get a scaled model
pep = lotka_volterra_scaled()

# The harness will:
# 1. Draw random p, ic from Uniform[0.1, 1.0]
# 2. Simulate the scaled ODE
# 3. Discard if solution blows up
# 4. Use surviving trajectories as estimation experiments
```

## Model Categories

### Section A: Baseline (3)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 1 | harmonic | 2 | 2 | 2 | Easy |
| 2 | lotka_volterra | 2 | 3 | 1 | Easy |
| 3 | vanderpol | 2 | 2 | 2 | Easy |

### Section B: Chemical/Process (3)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 4 | brusselator | 2 | 2 | 2 | Easy |
| 5 | cstr_fixed_activation | 5 | 5 | 3 | Hard |
| 6 | biohydrogenation | 4 | 6 | 2 | Medium |

### Section C: Mechanical/Aerospace (4)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 7 | mass_spring_damper | 2 | 4 | 1 | Easy |
| 8 | dc_motor_sinusoidal | 2 | 3 | 1 | Medium |
| 9 | flexible_arm | 4 | 6 | 2 | Hard |
| 10 | aircraft_pitch_sinusoidal | 3 | 4 | 1 | Hard |

### Section D: Modern Control (3)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 11 | bicycle_model_sinusoidal | 2 | 4 | 2 | Hard |
| 12 | quadrotor_sinusoidal | 2 | 2 | 1 | Easy |
| 13 | boost_converter_sinusoidal | 2 | 3 | 2 | Hard |

### Section E: Biological (4)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 14 | seir | 4 | 3 | 2 | Medium |
| 15 | fitzhugh_nagumo | 2 | 3 | 1 | Medium |
| 16 | repressilator | 6 | 3 | 3 | Medium |
| 17 | hiv | 5 | 10 | 4 | Hard |

### Section F: Pharmacokinetics (2)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 18 | daisy_mamil4 | 4 | 7 | 3 | Easy |
| 19 | two_compartment_pk | 2 | 5 | 1 | Easy |

### Section G: Large-Scale (1)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 20 | crauste_corrected | 5 | 13 | 4 | Hard |

### Section H: Extended (5)
| # | Model | States | Params | Obs | Difficulty |
|---|-------|--------|--------|-----|-----------|
| 21 | forced_lv_sinusoidal | 2 | 4 | 2 | Easy |
| 22 | treatment | 4 | 5 | 2 | Medium |
| 23 | sirsforced | 5 | 6 | 2 | Easy |
| 24 | slowfast | 6 | 2 | 4 | Easy |
| 25 | magnetic_levitation_sinusoidal | 3 | 3 | 1 | Hard |

## Models Most Likely to Blow Up with Random Draws

1. **boost_converter_sinusoidal** — Fast PWM dynamics, small L/C
2. **magnetic_levitation_sinusoidal** — Inherently unstable
3. **hiv** — 6 orders of magnitude in parameter scales
4. **crauste_corrected** — 8 orders of magnitude in parameter scales
5. **cstr_fixed_activation** — Temperature-dependent Arrhenius, exponential sensitivity
6. **fitzhugh_nagumo** — Very fast timescale (30ms)

## Models That Should Work Well

1. **daisy_mamil4** — Already near 0.5, linear dynamics
2. **sirsforced** — Already near 0.5, moderate scales
3. **slowfast** — Already near 0.5, linear dynamics
4. **lotka_volterra** — Moderate scales, well-behaved oscillator
5. **harmonic** — Linear, bounded
6. **brusselator** — Moderate scales, limit cycle attractor

## Special Cases

| Issue | Models | Handling |
|-------|--------|---------|
| Zero ICs | 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 22, 25 | Perturbed to small nonzero |
| Negative params | 10 (aircraft_pitch) | Negative scale factors |
| Negative IC | 15 (fitzhugh_nagumo V=-1) | Negative scale factor s_V=-2 |
| Zero param | 20 (crauste mu_M=0) | Kept at 0.0, not scaled |
| Constant states | 24 (slowfast eA,eB,eC) | Scaled normally, D=0 preserved |
| Sinusoidal forcing | 8, 10, 11, 12, 13, 21, 25 | External input unchanged |
| Conservation law | 14 (SEIR), 22 (treatment) | Broken by independent scaling |
