# Estimator-aware nonlinear campaign summary

Generated from 90 completed checkpoint cells. Small-N results are routing and accuracy pilots, not calibration claims.

| model | window | noise | arm | N | selected estimator | seed lineage | UQ outcome | median worst error | max worst error | median seconds |
|---|---:|---:|---|---:|---|---|---|---:|---:|---:|
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=5 | —=5 | report:degenerate=2, report:ok=3 | 0.0673 | 0.104 | 9.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=3, single_point_algebraic=2 | report:degenerate=3, report:wide_ci=2 | 0.000304 | 0.00266 | 10.8 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-05 | sp | 5 | none=1, single_point_algebraic=4 | —=5 | no_estimate:=1, report:degenerate=4 | 18.5 | 40.3 | 0.7 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp | 5 | multipoint_algebraic=5 | —=5 | report:degenerate=3, report:wide_ci=2 | 0.402 | 0.626 | 10.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=4, single_point_algebraic=1 | report:degenerate=3, report:wide_ci=2 | 0.00304 | 0.0266 | 10.0 |
| fitzhugh_nagumo | 0.0–3.0 | 1.0e-04 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=5 | 16.7 | 33.1 | 1.2 |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=5 | —=5 | report:ok=5 | 0.00797 | 0.013 | 10.3 |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=4, single_point_algebraic=1 | report:ok=5 | 1.03e-05 | 1.13e-05 | 16.7 |
| lotka_volterra | 0.0–20.0 | 1.0e-05 | sp | 5 | none=4, single_point_algebraic=1 | —=5 | no_estimate:=4, report:degenerate=1 | 0.323 | 0.323 | 0.9 |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp | 5 | multipoint_algebraic=5 | —=5 | report:ok=5 | 0.0551 | 0.0751 | 9.9 |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:ok=5 | 0.000103 | 0.000113 | 16.5 |
| lotka_volterra | 0.0–20.0 | 1.0e-04 | sp | 5 | none=5 | —=5 | no_estimate:=5 | NaN | NaN | 0.9 |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp | 5 | multipoint_algebraic=2, single_point_algebraic=3 | —=5 | report:degenerate=3, report:wide_ci=2 | 0.000614 | 0.00134 | 6.6 |
| vanderpol | 0.0–10.0 | 1.0e-05 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:degenerate=2, report:wide_ci=3 | 5.54e-06 | 9.37e-06 | 3.7 |
| vanderpol | 0.0–10.0 | 1.0e-05 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=2, report:wide_ci=3 | 0.236 | 0.445 | 0.6 |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=2, report:ok=1, report:wide_ci=2 | 0.019 | 0.0439 | 4.9 |
| vanderpol | 0.0–10.0 | 1.0e-04 | mp_polish | 5 | trajectory_polish=5 | multipoint_algebraic=2, single_point_algebraic=3 | report:degenerate=2, report:wide_ci=3 | 5.54e-05 | 9.37e-05 | 3.7 |
| vanderpol | 0.0–10.0 | 1.0e-04 | sp | 5 | single_point_algebraic=5 | —=5 | report:degenerate=4, report:ok=1 | 2.3 | 9.34 | 1.0 |

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
