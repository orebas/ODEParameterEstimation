# Estimator-aware nonlinear campaign summary

Generated from 15 completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.

| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |
|---|---:|---:|---|---:|---|---|---|---:|---:|---:|
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | 5 | multipoint_algebraic=5 | —=5 | report:degenerate=3, report:wide_ci=2 | 0.402 | 0.626 | 10.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=4, single_point_algebraic=1 | report:degenerate=3, report:wide_ci=2 | 0.00304 | 0.0266 | 10.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=5 | 16.7 | 33.1 | 1.2 |

## Coordinate diagnostics

Coverage and z summaries include only cells with finite reported standard errors.

| model | window | noise | arm | coordinate | N estimate | median error | N UQ | median abs(z) | 95% coverage |
|---|---:|---:|---|---|---:|---:|---:|---:|---:|
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | R | 5 | 0.0253 | 5 | 2.74 | 40.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | V | 5 | 0.000615 | 5 | 3.91 | 0.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | a | 5 | 0.351 | 5 | 1.26 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | b | 5 | 0.354 | 5 | 1.62 | 80.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | g | 5 | 0.0417 | 5 | 3.12 | 40.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | R | 5 | 0.000125 | 5 | 0.224 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | V | 5 | 0.000147 | 5 | 1.49 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | a | 5 | 0.00295 | 5 | 0.177 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | b | 5 | 0.00201 | 5 | 0.332 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | g | 5 | 0.000199 | 5 | 0.209 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | R | 5 | 16.7 | 5 | 0.203 | 80.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | V | 5 | 0.592 | 5 | 1.38 | 60.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | a | 5 | 8.34 | 5 | 1.01 | 80.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | b | 5 | 1.46 | 5 | 0.839 | 100.0% |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | g | 5 | 0.968 | 5 | 14.9 | 20.0% |
