# Biohydrogenation Parameter Estimation Example

This example demonstrates parameter estimation for a biohydrogenation model, a biochemical reaction system with Michaelis-Menten kinetics.

## Model Description

The model consists of:
- **4 state variables**: x4, x5, x6, x7
- **6 parameters**: k5, k6, k7, k8, k9, k10  
- **2 observables**: y1 (measures x4), y2 (measures x5)

The differential equations describe the conversion rates between chemical species using Michaelis-Menten and logistic growth kinetics.

## Files

- `biohydrogenation_example.jl` - Main script for parameter estimation
- `data.csv` - Synthetic measurement data (1001 time points from t=-1 to t=1)
- `result.csv` - Output file with estimated parameters and states (generated after running)

## Running the Example

The standalone script imports `CSV`, an example-only dependency. Install it
in the environment used for examples (`using Pkg; Pkg.add("CSV")`), alongside
ODEParameterEstimation. From the repository root, run:

```sh
julia --startup-file=no src/examples/biohydrogenation/biohydrogenation_example.jl
```

## Expected Output

The script will:
1. Load the biohydrogenation model and measurement data
2. Perform parameter estimation using ODEParameterEstimation
3. Save results to `result.csv`
4. Print the number of solutions found and the best solution

## True Parameter Values

For reference, the true parameter values used to generate the synthetic data are:
- k5 = 0.539
- k6 = 0.672
- k7 = 0.582
- k8 = 0.536
- k9 = 0.439
- k10 = 0.617

Initial conditions at the start of the supplied data interval:

- x4(-1) = 0.45
- x5(-1) = 0.813
- x6(-1) = 0.871
- x7(-1) = 0.407

The synthetic CSV and model entered this repository in commit `69e3a29` by
Oren Bassik. Its first row contains the time -1 and the initial values of the
two measured states. It is an example fixture, not experimental measurements.
The model is a difficult parameter-recovery case: a small trajectory residual
alone does not establish accurate parameter estimates.
