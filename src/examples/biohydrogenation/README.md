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

```julia
julia biohydrogenation_example.jl
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

Initial conditions:
- x4(0) = 0.45
- x5(0) = 0.813
- x6(0) = 0.871
- x7(0) = 0.407