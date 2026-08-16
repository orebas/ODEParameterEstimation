# Estimator-aware nonlinear campaign summary

Generated from 30 completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.

| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |
|---|---:|---:|---|---:|---|---|---|---:|---:|---:|
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | 5 | multipoint_algebraic=5 | —=5 | report:ok=5 | 0.0551 | 0.0751 | 9.9 |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:ok=5 | 0.000103 | 0.000113 | 16.5 |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | sp | 5 | none=5 | —=5 | no_estimate:=5 | NaN | NaN | 0.9 |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=2, report:ok=1, report:wide_ci=2 | 0.019 | 0.0439 | 4.9 |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:degenerate=2, report:wide_ci=3 | 5.54e-05 | 9.37e-05 | 3.7 |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=4, report:ok=1 | 2.3 | 9.34 | 1.0 |

## Coordinate diagnostics

Coverage and z summaries include only cells with finite reported standard errors.

| model | window | noise | arm | coordinate | N estimate | median error | N UQ | median abs(z) | 95% coverage |
|---|---:|---:|---|---|---:|---:|---:|---:|---:|
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | k1 | 5 | 0.0186 | 5 | 3.46 | 20.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | k2 | 5 | 0.0245 | 5 | 1.53 | 80.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | k3 | 5 | 0.0165 | 5 | 0.271 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | r | 5 | 0.00103 | 5 | 2.98 | 40.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | w | 5 | 0.0551 | 5 | 2.71 | 40.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | k1 | 5 | 3.47e-05 | 5 | 0.497 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | k2 | 5 | 4.18e-05 | 5 | 0.624 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | k3 | 5 | 2.68e-05 | 5 | 0.341 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | r | 5 | 1.31e-05 | 5 | 1.06 | 80.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | w | 5 | 0.000103 | 5 | 0.559 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | a | 5 | 0.000131 | 5 | 0.419 | 80.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | b | 5 | 0.000243 | 5 | 0.39 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | x1 | 5 | 0.00374 | 5 | 0.584 | 80.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | x2 | 5 | 0.019 | 5 | 0.571 | 80.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | a | 5 | 4.62e-06 | 5 | 1.01 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | b | 5 | 1.66e-05 | 5 | 0.699 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | x1 | 5 | 1.76e-05 | 5 | 1.25 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | x2 | 5 | 5.54e-05 | 5 | 0.911 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | a | 5 | 0.000209 | 5 | 0.432 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | b | 5 | 0.00356 | 5 | 0.755 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | x1 | 5 | 0.286 | 5 | 0.383 | 80.0% |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | x2 | 5 | 2.3 | 5 | 0.281 | 80.0% |
