# Control Investigations: Learning Parameter Estimation with Control Inputs

This directory contains progressive tutorial examples for understanding how to handle
control inputs in parameter estimation problems using ODEParameterEstimation.jl.

## Learning Path (Recommended Order)

| # | File | Difficulty | Key Concept |
|---|------|------------|-------------|
| 1 | `01_hello_world_constant_input.jl` | Beginner | Basic workflow with constant input |
| 2 | `02_rc_circuit_voltage_step.jl` | Beginner | Physical system, identifiability |
| 3 | `03_tank_constant_vs_driven.jl` | Intermediate | Constant vs time-varying inputs |
| 4 | `04_oscillator_input_polynomialized.jl` | Intermediate | Autonomous form technique |
| 5 | `05_comparing_approaches.jl` | Advanced | Side-by-side comparison |
| 6 | `06_your_own_model_template.jl` | Reference | Template for new models |

## Quick Start

Run any example directly:
```bash
julia --project -e 'include("src/examples/control_investigations/01_hello_world_constant_input.jl")'
```

Or interactively in Julia:
```julia
using ODEParameterEstimation
include("src/examples/control_investigations/01_hello_world_constant_input.jl")
```

## Key Concepts

### Three Approaches to Control Inputs

| Approach | When to Use | Pros | Cons |
|----------|-------------|------|------|
| **Constant Input** | Input is truly constant, or you only have steady-state data | Simple, fewer parameters | May cause identifiability issues |
| **Driven (Time-varying)** | Input signal is known (e.g., sin wave) | Breaks symmetries, better identifiability | Requires knowing input form; non-autonomous |
| **Polynomialized** | Need autonomous system; solver limitations | Fully autonomous system | More states; omega becomes fixed |

### The "INPUT" Convention

In model definitions, parameters marked with `# INPUT` are control inputs:
- They are external signals applied to the system
- Treated identically to other parameters during estimation
- In real experiments, these would typically be known measured values

### Identifiability

A key theme in these examples is **structural identifiability**:
- Can parameters be uniquely determined from the data?
- Some parameter combinations may only be identifiable as products/ratios
- Time-varying inputs often improve identifiability

## Troubleshooting

**Parameter estimates don't match true values:**
- Check if the system is structurally identifiable
- Try increasing `datasize` in options
- Consider using time-varying inputs

**Numerical errors:**
- Ensure initial conditions are physically reasonable
- Check time interval is appropriate for the dynamics
- Try different solver options

## Files Overview

- `01_hello_world_constant_input.jl` - Simplest possible example
- `02_rc_circuit_voltage_step.jl` - Classic electrical engineering example
- `03_tank_constant_vs_driven.jl` - Compare constant vs time-varying
- `04_oscillator_input_polynomialized.jl` - Convert to autonomous form
- `05_comparing_approaches.jl` - Run all three approaches
- `06_your_own_model_template.jl` - Start your own model

## Further Reading

- Main examples: `src/examples/first_example.jl`
- Control systems: `src/examples/models/control_systems.jl`
- Driven systems: `src/examples/models/control_systems_driven.jl`
