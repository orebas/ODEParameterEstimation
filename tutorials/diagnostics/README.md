# Diagnostic Framework Tutorial

The `diagnose(pep)` function answers: **"How hard is this parameter estimation problem, and where does it break?"**

It runs three automated stages — derivative accuracy, polynomial feasibility, and sensitivity analysis — using oracle (machine-precision) Taylor coefficients as ground truth. The result is a `DiagnosticReport` with a difficulty classification (`:easy`, `:moderate`, `:hard`, `:infeasible`) and a human-readable bottleneck description.

Use diagnostics when a model fails estimation and you need to understand *why*, or when bringing up a new model and you want to predict difficulty before running the full pipeline.

## Quick Start

```julia
using ODEParameterEstimation

# Built-in example: well-conditioned 2-state model
pep = simple()
pep_data = sample_problem_data(pep, EstimationOptions(datasize = 101, time_interval = [-0.5, 0.5]))

report = diagnose(pep_data)
# → DiagnosticReport with difficulty = :easy
```

`diagnose()` prints a formatted summary table and saves reports (text, CSV, and HTML with collapsible sections) to `artifacts/diagnostics/<model_name>/`. The returned `DiagnosticReport` struct gives programmatic access to every number.

## Multi-Interpolator / Multi-Point Mode

For harder models, the choice of interpolator and shooting point dramatically affects results. Pass `interpolators` and/or `t_eval_points` to sweep across combinations and automatically select the best:

```julia
# Sweep 3 interpolators across 3 shooting points
report = diagnose(pep_data;
    interpolators = [InterpolatorAAADGPR, InterpolatorAAAD, InterpolatorAGPRobust],
    t_eval_points = [0.01, 5.0, 10.0],
)
# → ComprehensiveDiagnosticReport with derivative accuracy grid

# Access the best combination
report.best_interpolator   # e.g. "aaad"
report.best_eval_point     # e.g. 0.01
report.best.difficulty     # e.g. :hard
report.derivative_grid     # all DerivativeAccuracyReports

# HTML report with expandable detail sections
# → artifacts/diagnostics/<model>/report.html
```

The comprehensive mode runs SIAN once (structural analysis is interpolator-independent), then creates interpolants for each method and evaluates derivative accuracy at every (interpolator, point) combination. The full 3-stage pipeline (polynomial feasibility + sensitivity) runs only for the best combination.

Default interpolator set when `interpolators` is empty: `InterpolatorAAADGPR` (production default), `InterpolatorAAAD` (pure rational), `InterpolatorAGPRobust` (GP), `InterpolatorFHD` (finite differences).

## The Three Diagnostic Stages

### Stage 1: Derivative Accuracy

**What it does:** Computes Taylor coefficients of each observable at the shooting point using symbolic recursion on the ODE's expression tree (Cauchy products for `*`, long division for `/`, repeated squaring for `^`). Then compares these oracle values against the production GP/AAAD interpolant derivatives.

**Key fields in `DerivativeAccuracyReport`:**

| Field | Type | Meaning |
|-------|------|---------|
| `entries` | `Vector{NamedTuple}` | Per-(observable, order) comparison |
| `worst_obs` | `String` | Observable with the largest error |
| `worst_order` | `Int` | Derivative order of worst error |
| `worst_rel_error` | `Float64` | Magnitude of worst relative error |

**How to interpret:** Each entry shows `true_val` (oracle), `interp_val` (production), and `rel_error`. Errors below 1% are fine. Errors above 10% at any required derivative order will degrade HC.jl solutions or cause 0-solution results.

The oracle Taylor recursion works because ODE right-hand sides are polynomial in states (possibly with transcendental functions of time, handled separately). The k-th Taylor coefficient of a state is:

```
x_{k+1} = f_k / (k + 1)
```

where `f_k` is the k-th Taylor coefficient of the RHS `f(x, t)`, computed by walking the symbolic expression tree.

### Stage 2: Polynomial Feasibility

**What it does:** Builds the SIAN polynomial system (the SI template) with two different data sources:
1. **Perfect interpolants** — `PerfectInterpolant` objects that evaluate as Taylor polynomials via Horner's method, giving machine-precision derivatives.
2. **Production interpolants** — whatever GP/AAAD the pipeline would normally use.

Solves both systems with HC.jl and compares solution counts, residuals at the true parameter values, and distance from the closest HC solution to the truth.

**Key fields in `PolynomialFeasibilityReport`:**

| Field | Type | Meaning |
|-------|------|---------|
| `n_equations`, `n_variables` | `Int` | System dimensions |
| `is_square` | `Bool` | Must be true for HC.jl |
| `n_solutions_perfect` | `Int` | Solutions with oracle data |
| `n_solutions_production` | `Int` | Solutions with production data |
| `true_residual_perfect` | `Float64` | ||F(x_true)|| with oracle data |
| `true_residual_production` | `Float64` | ||F(x_true)|| with production data |
| `closest_distance_perfect` | `Float64` | ||x_closest - x_true|| with oracle |
| `closest_distance_production` | `Float64` | ||x_closest - x_true|| with production |

**How to interpret:** If `n_solutions_perfect > 0` but `n_solutions_production == 0`, the polynomial system is solvable in principle but production interpolation errors push it beyond HC.jl's tracking tolerance. If `n_solutions_perfect == 0`, the system itself may be degenerate at this evaluation point.

### Stage 3: Sensitivity Analysis

**What it does:** Computes the Jacobian of the polynomial system at the true solution via ForwardDiff, then performs SVD to get the condition number and effective rank.

**Key fields in `SensitivityReport`:**

| Field | Type | Meaning |
|-------|------|---------|
| `jacobian_cond` | `Float64` | Condition number (sigma_max / sigma_min) |
| `effective_rank` | `Int` | Number of singular values > 1e-10 * sigma_max |
| `singular_values` | `Vector{Float64}` | Full singular value spectrum |
| `root_sensitivity` | `Float64` | Root displacement per unit data perturbation |

**How to interpret:** A condition number below 10^6 is excellent. Between 10^6 and 10^12 is moderate — small interpolation errors will amplify but may still yield usable solutions. Above 10^12 means even sub-percent data errors can displace solutions by orders of magnitude. `effective_rank < n_variables` indicates a structurally degenerate system (e.g., practical non-identifiability).

## Difficulty Classification

| Difficulty | Derivative Error | Jacobian Cond | Meaning |
|------------|-----------------|---------------|---------|
| `:easy` | < 1% | < 10^6 | Standard pipeline will succeed |
| `:moderate` | < 10% | < 10^12 | May need tuning (more data points, better interpolator) |
| `:hard` | >= 10% | >= 10^12 | Fundamental conditioning problem; polish/fallback needed |
| `:infeasible` | any | any | 0 solutions with production data |

The thresholds are defined in `_classify_difficulty()` in `src/core/diagnostics.jl`.

## Lower-Level API

You can call each diagnostic stage independently:

```julia
# Stage 1 only
deriv_report = diagnose_derivative_accuracy(pep_data)

# Stage 2 only
poly_report = diagnose_polynomial_system(pep_data)

# Stage 3 only (can optionally use poly_report for root sensitivity)
sens_report = diagnose_sensitivity(pep_data; poly_report = poly_report)
```

### Oracle Taylor Coefficients

The building blocks are also exported for standalone use:

```julia
# Compute state Taylor coefficients at t=5.0, up to order 4
state_coeffs = compute_oracle_taylor_coefficients(pep_data, 5.0, 4)
# state_coeffs[x1] = [x1(5), x1'(5)/1!, x1''(5)/2!, x1'''(5)/3!, x1''''(5)/4!]

# Compute observable Taylor coefficients from state coefficients
obs_coeffs = compute_observable_taylor_coefficients(pep_data, state_coeffs, 5.0, 4)

# Build PerfectInterpolant objects (drop-in replacements for production interpolants)
perfect = build_perfect_interpolants(pep_data, 5.0, 4)
# perfect[obs_key](t) evaluates via Horner's method
```

`PerfectInterpolant` stores coefficients `c[k+1] = f^(k)(t0) / k!` and evaluates as:

```
p(t) = c[1] + c[2]*(t-t0) + c[3]*(t-t0)^2 + ... (Horner form)
```

TaylorDiff on a `PerfectInterpolant` recovers machine-precision derivatives up to the stored order — this is what makes oracle-vs-production comparison meaningful.

## Report Types Reference

```julia
struct DiagnosticReport
    model_name::String
    derivative_accuracy::DerivativeAccuracyReport
    polynomial_feasibility::PolynomialFeasibilityReport
    sensitivity::SensitivityReport
    difficulty::Symbol          # :easy, :moderate, :hard, :infeasible
    bottleneck::String          # human-readable summary
    timestamp::Dates.DateTime
end

struct DerivativeAccuracyReport
    model_name::String
    t_eval::Float64
    max_required_order::Int
    entries::Vector{NamedTuple{(:obs, :order, :true_val, :interp_val, :rel_error), ...}}
    worst_obs::String
    worst_order::Int
    worst_rel_error::Float64
end

struct PolynomialFeasibilityReport
    model_name::String
    n_equations::Int
    n_variables::Int
    is_square::Bool
    n_solutions_perfect::Int
    n_solutions_production::Int
    true_residual_perfect::Float64
    true_residual_production::Float64
    closest_distance_perfect::Float64
    closest_distance_production::Float64
    variable_names::Vector{String}
end

struct SensitivityReport
    model_name::String
    jacobian_cond::Float64
    effective_rank::Int
    singular_values::Vector{Float64}
    root_sensitivity::Float64
end
```

## Disk Output

When `save_to_disk = true` (the default), `diagnose()` writes to `artifacts/diagnostics/<model_name>/`:

| File | Content |
|------|---------|
| `summary.txt` | Human-readable report with all three stages |
| `derivative_accuracy.csv` | Per-observable, per-order: `true_val`, `interp_val`, `rel_error` |
| `sensitivity.csv` | Singular value spectrum (index, value) |

Pass `save_to_disk = false` to suppress file output:

```julia
report = diagnose(pep_data; save_to_disk = false)
```

## Worked Example: Why the Bilby CSTR Fails

The CSTR (Continuous Stirred-Tank Reactor) is the hardest model in the bilby benchmark — it fails 7 out of 8 instances even with zero noise. This walkthrough shows exactly why.

### Defining the CSTR

This is the exact nondimensionalized CSTR from the bilby benchmark analysis. It has 3 states, 4 parameters, 1 observable, and a `sin(0.5*t)` forcing term:

```julia
using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

@parameters tau Tin dH_rhoCP UA_VrhoCP
@variables C(t) Temp(t) r_eff(t) y1(t)

# Nondimensionalization constants
alpha1 = 1.999863916554819     # rate scaling
alpha2 = 0.0285694845222117    # heat generation
alpha3 = 6 / 7                 # coolant base term
alpha4 = 2 / 35                # coolant oscillation
E_R_nondim = 12.5              # activation energy (nondim)

eqs = [
    D(C) ~ (1.0 - C) / (2.0 * tau) - alpha1 * r_eff * C,
    D(Temp) ~ (Tin - Temp) / (2.0 * tau) + alpha2 * dH_rhoCP * r_eff * C -
              2.0 * UA_VrhoCP * Temp + alpha3 * UA_VrhoCP +
              alpha4 * UA_VrhoCP * sin(0.5 * t),
    D(r_eff) ~ E_R_nondim * r_eff / (Temp^2) * (
        (Tin - Temp) / (2.0 * tau) + alpha2 * dH_rhoCP * r_eff * C -
        2.0 * UA_VrhoCP * Temp + alpha3 * UA_VrhoCP +
        alpha4 * UA_VrhoCP * sin(0.5 * t)
    ),
]
measured_quantities = [y1 ~ 700.0 * Temp]
```

The `r_eff / Temp^2` term is polynomial in states (division handled by Taylor long-division). The `sin(0.5*t)` is transcendental in time only — handled by the `_trfn_` transform.

### Instance cstr_0_0

```julia
p_true = OrderedDict([tau, Tin, dH_rhoCP, UA_VrhoCP] .=> [0.15, 0.439, 0.307, 0.779])
ic = OrderedDict([C, Temp, r_eff] .=> [0.127, 0.867, 0.384])
```

### Transcendental Transform (Critical Step)

The `sin(0.5*t)` cannot go through SIAN directly. You must transform the PEP first:

```julia
model, mq = create_ordered_ode_system("cstr_nondim", [C, Temp, r_eff], [tau, Tin, dH_rhoCP, UA_VrhoCP], eqs, measured_quantities)
pep = ParameterEstimationProblem("cstr_nondim", model, mq, nothing, [0.0, 20.0], nothing, p_true, ic, 0)

# Sample data
opts = EstimationOptions(datasize = 1501, time_interval = [0.0, 20.0])
pep_data = sample_problem_data(pep, opts)

# Transform: sin(0.5*t) → _trfn_sin_5_0(t) with its own ODE
pep_transformed, tr_info = transform_pep_for_estimation(pep_data, t)

# NOW run diagnostics on the transformed PEP
report = diagnose(pep_transformed)
```

Without the transform, `diagnose()` will fail when SIAN encounters the `sin` term.

### What the Diagnostic Reveals

The CSTR diagnostic output shows three compounding problems:

**1. r_eff catastrophic decay:** The reaction effectiveness `r_eff` decays from 0.384 to approximately 0 by `t ≈ 0.76` (Jacobian eigenvalues ≈ -400). This means higher-order Taylor coefficients of `r_eff` span enormous dynamic range, stressing any interpolation scheme.

**2. Derivative accuracy degrades at higher orders:** Order-0 and order-1 derivatives of `y1` (which is `700*Temp`) may be within 1-5% accuracy, but by order 3-4, the production GP/AAAD errors grow to 10-100%+ — because the underlying `r_eff*C` products require accurate high-order information from a rapidly decaying signal.

**3. Jacobian condition number ~ 10^18:** Even with perfect derivatives, the polynomial system's Jacobian has condition number on the order of 10^18. This means a 0.26% interpolation error (typical GP accuracy) can displace solutions by 8+ orders of magnitude — far beyond any tolerance threshold.

The diagnosis correctly classifies this as `:hard` (or `:infeasible` if 0 production solutions are found).

### The Fundamental Limit

The CSTR illustrates the gap between *structural* and *practical* identifiability: SIAN proves the system is structurally identifiable (a finite number of parameter solutions exist), but the Jacobian conditioning makes it practically unidentifiable from finite-precision data. The diagnostic framework quantifies exactly where in the pipeline the problem becomes intractable.

## Running the Tutorial

```bash
julia tutorials/diagnostics/run_diagnostics.jl
```

This runs `diagnose()` on three models of increasing difficulty (simple, Lotka-Volterra, CSTR) and demonstrates the lower-level API. Output artifacts are saved to `artifacts/diagnostics/`.

## Files

- `run_diagnostics.jl` — Runnable example script with easy + moderate + hard models
- `README.md` — This documentation
