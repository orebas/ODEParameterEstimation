# PETab Generator Documentation

This tool generates PETab problems from ODE specifications written in TOML format. Here's what you need to know to use it effectively.

## Model Specification

### Basic Structure
```toml
[model]
name = "model_name"
states = [
    { name = "x1", initial_value = 1.0, estimate = true },
    { name = "x2", initial_value = 0.2, estimate = false }
]
parameters = [
    { name = "k1", value = 0.4, bounds = [1e-4, 1e2], scale = "log10", estimate = true },
    { name = "k2", value = 0.6, bounds = [1e-4, 1e2], scale = "log10", estimate = false }
]
equations = [
    "x1' = -k1 * x1",
    "x2' = k2 * x1"
]
```

### ODE Syntax
The equations use Antimony syntax:
- Use prime notation (`'`) for derivatives: `x' = ...` or `x1' = ...`
- Standard operators: `+`, `-`, `*`, `/`
- Power/exponentiation: 
  - Use `power(x,y)` for x^y (recommended, works in all versions)
  - `^` also works in recent versions
  - Python-style `**` is NOT supported
- Functions supported: `sin`, `cos`, `exp`, `ln`, `log`, `log10`, `abs`, `sqrt`, `ceiling`, `floor`, `factorial`, `piecewise`
- Parameters and state variables can be used directly by name
- Complex expressions can use parentheses: `(a + b)/(c * d)`
- Logical operators: `and`, `or`, `not`, `gt`, `lt`, `geq`, `leq`

### Parameter Specification
- Each parameter needs:
  - `name`: Identifier used in equations
  - `value`: Initial/true value
  - `bounds`: [lower, upper] bounds for estimation
  - `scale`: Parameter scale for estimation (PETab specification):
    - "log10": Log10 scale (default)
    - "lin": Linear scale
    - "log": Natural log scale
  - `estimate`: Boolean, whether to estimate (default: true)
- All numeric values are converted to float internally to avoid type issues

### Initial Conditions
- Specified in `states` section
- `estimate = true` means the initial condition will be treated as a parameter to estimate
- `estimate = false` means the initial condition is fixed

## Simulation Settings

```toml
[simulation]
timespan = [0, 10.0]  # [start_time, end_time]
n_timepoints = 30     # Number of timepoints
noise_level = 0.05    # Relative noise level (5%)
output_dir = "petab_problem"
blind = false         # Whether to hide true parameters
```

### Noise Model
The noise model adds multiplicative Gaussian noise to each measurement:
```python
noisy_data = true_data * (1 + noise_level * random.normal(0, 1))
```
This means:
- A noise_level of 0.05 corresponds to 5% relative noise
- The noise is independent for each measurement
- The standard deviation scales with the magnitude of the measurement

## Technical Details

### ODE Solver
- Uses Tellurium/Roadrunner for ODE integration
- Default settings:
  - Solver: CVODE (variable-step, variable-order)
  - Absolute tolerance: 1e-10
  - Relative tolerance: 1e-10
  - Maximum steps: unlimited
  - Integration method: BDF for stiff systems

### Number Handling
- All numeric values in the TOML file are converted to Python float
- Scientific notation (e.g., 1e-4) is supported
- Integer values are automatically converted to float
- NaN and Inf are not supported

## Common Issues & Solutions

1. **Equation Syntax Errors**
   - Check for missing multiplication symbols
   - Ensure all variables are defined
   - Use parentheses for complex expressions

2. **Parameter Bounds**
   - Must be strictly positive for log-scale parameters
   - Should span at least one order of magnitude
   - Consider computational limits (~1e-20 to 1e20)

3. **Initial Values**
   - Should be within reasonable ranges
   - Consider physical constraints (e.g., non-negative for concentrations)

4. **Numerical Integration**
   - If integration fails, try:
     - Adjusting timespan
     - Checking parameter ranges
     - Looking for stiff equations

## Example Models
[TBD]
