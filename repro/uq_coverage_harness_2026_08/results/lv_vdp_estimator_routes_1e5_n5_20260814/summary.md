# Estimator-aware nonlinear campaign summary

Generated from 30 completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.

| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |
|---|---:|---:|---|---:|---|---|---|---:|---:|---:|
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=5 | —=5 | report:ok=5 | 0.00797 | 0.013 | 10.3 |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=4, single_point_algebraic=1 | report:ok=5 | 1.03e-05 | 1.13e-05 | 16.7 |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | 5 | none=4, single_point_algebraic=1 | —=5 | no_estimate:=4, report:degenerate=1 | 0.323 | 0.323 | 0.9 |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=2, single_point_algebraic=3 | —=5 | report:degenerate=3, report:wide_ci=2 | 0.000614 | 0.00134 | 6.6 |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:degenerate=2, report:wide_ci=3 | 5.54e-06 | 9.37e-06 | 3.7 |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=2, report:wide_ci=3 | 0.236 | 0.445 | 0.6 |

## Coordinate diagnostics

Coverage and z summaries include only cells with finite reported standard errors.

| model | window | noise | arm | coordinate | N estimate | median error | N UQ | median abs(z) | 95% coverage |
|---|---:|---:|---|---|---:|---:|---:|---:|---:|
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | k1 | 5 | 0.00304 | 5 | 3.62 | 20.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | k2 | 5 | 0.00304 | 5 | 1.32 | 80.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | k3 | 5 | 0.00406 | 5 | 0.469 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | r | 5 | 0.000203 | 5 | 3.59 | 0.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | w | 5 | 0.00797 | 5 | 2.52 | 40.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | k1 | 5 | 3.47e-06 | 5 | 0.417 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | k2 | 5 | 4.18e-06 | 5 | 0.544 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | k3 | 5 | 2.68e-06 | 5 | 0.292 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | r | 5 | 1.31e-06 | 5 | 1.02 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | w | 5 | 1.03e-05 | 5 | 0.487 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | k1 | 1 | 0.0663 | 1 | 0.0684 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | k2 | 1 | 0.0765 | 1 | 0.034 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | k3 | 1 | 0.139 | 1 | 0.0625 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | r | 1 | 0.0351 | 1 | 0.0172 | 100.0% |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | w | 1 | 0.323 | 1 | 0.0895 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | a | 5 | 5.27e-05 | 5 | 0.327 | 80.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | b | 5 | 7.25e-05 | 5 | 0.419 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | x1 | 5 | 0.000107 | 5 | 0.488 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | x2 | 5 | 0.000614 | 5 | 0.445 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | a | 5 | 4.62e-07 | 5 | 0.961 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | b | 5 | 1.66e-06 | 5 | 0.612 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | x1 | 5 | 1.76e-06 | 5 | 1.16 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | x2 | 5 | 5.54e-06 | 5 | 0.84 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | a | 5 | 7.06e-05 | 5 | 1.08 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | b | 5 | 0.000648 | 5 | 0.746 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | x1 | 5 | 0.0406 | 5 | 0.745 | 100.0% |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | x2 | 5 | 0.236 | 5 | 0.703 | 100.0% |
