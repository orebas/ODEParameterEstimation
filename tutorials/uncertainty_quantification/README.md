# Uncertainty Quantification Tutorial

This tutorial demonstrates the Uncertainty Quantification (UQ) feature of ODEParameterEstimation.jl. UQ provides confidence intervals for estimated parameters by propagating measurement uncertainty through the estimation pipeline.

## Overview

When estimating parameters from noisy data, we don't just want point estimates—we want to know **how confident** we can be in those estimates. The UQ feature answers questions like:

- "Given my measurement noise, how precisely can I determine this parameter?"
- "Are some parameters more identifiable than others?"
- "How do correlations between parameters affect my estimates?"

## Quick Start

```julia
using ODEParameterEstimation

# Define your model
pep = simple()  # Built-in example model

# Enable UQ in options
opts = EstimationOptions(
    datasize = 51,
    noise_level = 0.05,           # 5% noise
    compute_uncertainty = true,    # Enable UQ
    flow = FlowDirectOpt,
)

# Run estimation
pep_sampled = sample_problem_data(pep, opts)
results_tuple, analysis_results, uq_result = analyze_parameter_estimation_problem(pep_sampled, opts)

# Access uncertainties
if uq_result.success
    for (param, info) in uq_result.parameter_uncertainties
        println("$param: $(info.estimate) ± $(1.96 * info.std_dev) (95% CI)")
    end
end
```

## How It Works

The UQ pipeline consists of three stages:

### Stage 1: Gaussian Process Interpolation

Instead of using raw noisy data, we fit a Gaussian Process (GP) to each observable. The GP provides:
- A smooth estimate of the signal (posterior mean)
- Uncertainty quantification at each point (posterior variance)
- Analytically computable derivatives with their uncertainties

**Key insight**: Derivatives are harder to estimate than values. The GP framework naturally captures this—derivative uncertainties are typically larger than value uncertainties.

```
Observation: y(t) ± σ_y(t)
Derivative:  dy/dt ± σ_{dy/dt}(t)   [typically larger uncertainty]
```

### Stage 2: Observation Vector Construction

We construct a vector `z` containing all the information needed for parameter estimation:
- Observable values at measurement times
- Observable derivatives at measurement times

The GP provides a covariance matrix `Σ_z` that captures:
- Uncertainty in each component
- Correlations between values and derivatives
- Cross-time correlations

### Stage 3: Implicit Function Theorem (IFT) & Delta Method

The parameter estimation problem can be written as solving `F(θ, z) = 0` for parameters `θ` given observations `z`. The IFT tells us:

```
∂θ/∂z = -[∂F/∂θ]⁻¹ · [∂F/∂z]
```

We call this sensitivity matrix `S`. Then the **delta method** gives us:

```
Cov(θ) ≈ S · Σ_z · Sᵀ
```

This propagates the observation uncertainty `Σ_z` into parameter uncertainty `Cov(θ)`.

## Step-by-Step Example

### 1. Define the Problem

```julia
using ODEParameterEstimation
using CairoMakie

# The "simple" model: dx/dt = p1*x, y = x (single state, single parameter)
pep = simple()
println("Model: ", pep.name)
println("Parameters: ", pep.parameters)
println("States: ", pep.states)
```

### 2. Generate Synthetic Data

```julia
opts = EstimationOptions(
    datasize = 51,
    noise_level = 0.05,  # 5% multiplicative noise
    time_interval = [-0.5, 0.5],
    compute_uncertainty = true,
    flow = FlowDirectOpt,
)

pep_sampled = sample_problem_data(pep, opts)
```

### 3. Run Parameter Estimation with UQ

```julia
results_tuple, analysis_results, uq_result = analyze_parameter_estimation_problem(pep_sampled, opts)
```

### 4. Interpret Results

```julia
if uq_result.success
    println("\n=== Parameter Estimates with 95% Confidence Intervals ===")

    for (param, info) in uq_result.parameter_uncertainties
        ci_half = 1.96 * info.std_dev
        lower = info.estimate - ci_half
        upper = info.estimate + ci_half

        println("$param:")
        println("  Point estimate: $(info.estimate)")
        println("  95% CI: [$lower, $upper]")
        println("  Relative uncertainty: $(100 * info.std_dev / abs(info.estimate))%")
    end

    println("\nCorrelation Matrix:")
    display(uq_result.correlation_matrix)
end
```

## Interpreting Results

### Parameter Standard Deviations (`param_std`)

The standard deviation tells you the typical size of estimation error:
- **Small σ** → Parameter is well-determined by the data
- **Large σ** → Parameter is poorly constrained (low identifiability)

Rule of thumb: `relative_uncertainty = σ / |estimate|`
- < 5%: Excellent precision
- 5-20%: Good precision
- 20-50%: Moderate precision
- > 50%: Poor precision (consider if parameter is identifiable)

### Covariance Matrix

The covariance matrix `Cov(θ)` captures relationships between parameter uncertainties:
- **Diagonal elements** `Cov(θᵢ, θᵢ) = Var(θᵢ) = σᵢ²`
- **Off-diagonal elements** `Cov(θᵢ, θⱼ)` indicate parameter correlations

### Correlation Matrix

The correlation matrix is the normalized covariance:

```
Corr(θᵢ, θⱼ) = Cov(θᵢ, θⱼ) / (σᵢ · σⱼ)
```

Values range from -1 to +1:
- **|ρ| ≈ 0**: Parameters are independently estimated
- **|ρ| ≈ 1**: Parameters are highly correlated (potential identifiability issue)
- **ρ > 0**: Overestimating one tends to overestimate the other
- **ρ < 0**: Overestimating one tends to underestimate the other

### Confidence Ellipses

For two parameters, the joint 95% confidence region is an ellipse. The ellipse shape tells you:
- **Circular**: Parameters are independent
- **Elongated along diagonal**: Parameters are correlated
- **Elongated along axis**: One parameter is less identifiable

## Noise Sensitivity

The UQ feature correctly tracks how uncertainty scales with noise:

| Noise Level | Typical Behavior |
|-------------|------------------|
| 0.1% | Very tight CIs, near-perfect identifiability |
| 1% | Good CIs, reliable estimates |
| 5% | Moderate CIs, typical experimental precision |
| 10% | Wide CIs, may see identifiability issues |

**Expected relationship**: For well-posed problems, `σ(θ) ∝ σ(noise)` approximately.

Run the tutorial with different noise levels to observe this:

```julia
for noise in [0.001, 0.01, 0.05, 0.1]
    opts = EstimationOptions(
        noise_level = noise,
        compute_uncertainty = true,
        ...
    )
    # Run and collect CI widths
end
```

## Advanced: Intermediate Results

### Accessing GP Interpolators

The UQ computation creates GP interpolators for each observable:

```julia
# During UQ computation (internal)
interp_uq = agp_gpr_uq(ts, ys_noisy, 0, 2)  # AGPInterpolatorUQ object

# Query value and variance at a point
μ, σ² = interp_uq(t_query)

# Query derivative and variance
μ_deriv, σ²_deriv = derivative_estimate(interp_uq, t_query)
```

### Joint Derivative Covariance

For a single time point, get the full covariance between value and derivative:

```julia
μ, Σ = joint_derivative_covariance(interp_uq, t)
# μ = [y(t), dy/dt(t)]
# Σ = 2×2 covariance matrix
```

### Full Observation Covariance

Build the complete observation vector with covariance:

```julia
μ_z, Σ_z, labels = build_observation_covariance(interps_uq, ts)
# μ_z: mean observation vector
# Σ_z: full covariance matrix (block diagonal by observable)
# labels: parameter name labels
```

### Jacobian Inspection

The sensitivity matrix `S` comes from solving a linear system involving the Jacobian of the estimation equations:

```julia
# Internal computation
J_theta = jacobian_wrt_parameters(F, θ)
J_z = jacobian_wrt_observations(F, z)
S = -inv(J_theta) * J_z
```

## Caveats and Limitations

### Linear Approximation

The delta method uses a **first-order Taylor expansion**. This is accurate when:
- Uncertainties are small relative to parameter values
- The estimation problem is approximately linear near the solution

For highly nonlinear problems or large uncertainties, the true confidence region may be asymmetric or non-elliptical.

### Model Specification Assumed Correct

The UQ analysis assumes your ODE model is the correct model. It does **not** account for:
- Model misspecification
- Missing dynamics
- Systematic measurement bias

If the model is wrong, the confidence intervals may be overconfident.

### Block-Diagonal Assumption

The current implementation treats each observable's GP as independent, yielding a block-diagonal covariance matrix. This is appropriate when:
- Observables are measured independently
- Cross-observable correlations are negligible

### Numerical Conditioning

For problems with many parameters or near-singular Jacobians:
- The covariance matrix inversion may be ill-conditioned
- Standard deviations may be numerically inflated
- Consider regularization or model reformulation

## Running the Tutorial

```bash
cd tutorials/uncertainty_quantification
julia --project -e "using Pkg; Pkg.instantiate()"
julia --project uq_tutorial.jl
```

Output figures will be saved to the `figures/` directory:
- `01_gp_fit_with_bands.pdf` - GP interpolation with uncertainty bands
- `02_derivative_uncertainty.pdf` - Value and derivative uncertainty comparison
- `03_parameter_confidence.pdf` - Parameter estimates with confidence intervals
- `04_covariance_ellipse.pdf` - Joint parameter confidence ellipse
- `05_noise_sensitivity.pdf` - How noise affects uncertainty

## Files

- `Project.toml` - Dependencies for this tutorial
- `uq_tutorial.jl` - Main runnable script with all examples and visualizations
- `figures/` - Output directory for generated figures
- `README.md` - This documentation

## Dependencies

- `ODEParameterEstimation` - The main package
- `CairoMakie` - Publication-quality vector graphics
- `Colors`, `ColorSchemes` - Colorblind-safe palettes
- `LinearAlgebra` - Matrix operations
- `Statistics` - Statistical computations
- `Distributions` - For chi-squared quantiles (confidence ellipses)
- `Printf` - Formatted output
- `Random` - Reproducible noise generation
