# Estimator-aware nonlinear campaign summary

Generated from 15 completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.

| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |
|---|---:|---:|---|---:|---|---|---|---:|---:|---:|
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=5 | —=5 | report:degenerate=2, report:ok=3 | 0.0673 | 0.104 | 9.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=3, single_point_algebraic=2 | report:degenerate=3, report:wide_ci=2 | 0.000304 | 0.00266 | 10.8 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | 5 | none=1, single_point_algebraic=4 | —=5 | no_estimate:=1, report:degenerate=4 | 18.5 | 40.3 | 0.7 |

## Coordinate diagnostics

Coverage and z summaries include only cells with finite reported standard errors.

| model | window | noise | arm | coordinate | N estimate | median error | N UQ | median abs(z) | 95% coverage |
|---|---:|---:|---|---|---:|---:|---:|---:|---:|
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | R | 5 | 0.00342 | 5 | 2.12 | 40.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | V | 5 | 1.12e-05 | 5 | 0.33 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | a | 5 | 0.0673 | 5 | 1.49 | 60.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | b | 5 | 0.0199 | 5 | 0.918 | 80.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | g | 5 | 0.00497 | 5 | 2.23 | 40.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | R | 5 | 1.25e-05 | 5 | 0.232 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | V | 5 | 1.47e-05 | 5 | 1.55 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | a | 5 | 0.000295 | 5 | 0.184 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | b | 5 | 0.000201 | 5 | 0.346 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | g | 5 | 1.99e-05 | 5 | 0.22 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | R | 4 | 8.15 | 4 | 0.249 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | V | 4 | 0.6 | 4 | 13.4 | 25.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | a | 4 | 11.1 | 4 | 3.13 | 25.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | b | 4 | 1.87 | 4 | 1.14 | 75.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | g | 4 | 0.979 | 4 | 35.4 | 0.0% |
