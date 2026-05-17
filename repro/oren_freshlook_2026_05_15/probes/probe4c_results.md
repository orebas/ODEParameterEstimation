# Probe 4c — full 2026-05-14 numbat benchmark walk

Cells: **1136** (all cells with valid result.csv + huge_json truth).
Deep-failure cells (best oracle > 50%): **117** / 1136 (10.3%).

## Overall rank-1 oracle (full benchmark)

| scheme | median | mean | p90 | %≤1% | %≤10% |
|---|---|---|---|---|---|
| err_only | 0.000113 | 9.54e+05 | 2.28 | 64.9% | 73.4% |
| S2 (current default) | 0.000134 | 4.29e+04 | 1.66 | 70.2% | 78.9% |

Pairwise: S2 wins 279, loses 181, ties 676 (out of 1136).

## Required_K distribution (smallest rank with oracle ≤ 10%, under S2 sort)

| K range | count | % |
|---|---|---|
| 1 | 896 | 78.9% |
| 2-5 | 41 | 3.6% |
| 6-10 | 6 | 0.5% |
| 11-20 | 6 | 0.5% |
| 21-50 | 0 | 0.0% |
| 51-100 | 0 | 0.0% |
| 101+ | 0 | 0.0% |
| never (no oracle-close row) | 187 | 16.5% |

## Per-noise breakdown (rank-1 S2 oracle)

| noise | n | median | mean | p90 | %≤1% | %≤10% |
|---|---|---|---|---|---|---|
| 0 | 228 | 2.56e-10 | 0.171 | 0.000441 | 93.0% | 93.4% |
| 1em2 | 224 | 0.0827 | 4.7e+04 | 7 | 25.9% | 50.4% |
| 1em4 | 225 | 0.00104 | 3.91e+04 | 6.54 | 64.0% | 74.7% |
| 1em6 | 230 | 9.9e-05 | 301 | 0.555 | 80.0% | 84.8% |
| 1em8 | 229 | 3.83e-06 | 1.28e+05 | 0.0764 | 87.3% | 90.4% |

## Per-system breakdown (rank-1 S2 oracle, sorted by %≤10%)

| system | n | median | p90 | %≤1% | %≤10% |
|---|---|---|---|---|---|
| cstr | 50 | 2.49 | 8.62 | 10.0% | 14.0% |
| daisy_mamil4 | 48 | 0.555 | 2.07 | 22.9% | 27.1% |
| hiv | 48 | 0.199 | 7.95e+03 | 37.5% | 47.9% |
| seir | 50 | 0.278 | 4.87 | 40.0% | 50.0% |
| crauste | 42 | 0.00855 | 1.19e+03 | 52.4% | 57.1% |
| biohydrogenation | 48 | 0.00761 | 5.45 | 52.1% | 58.3% |
| brusselator | 50 | 0.00205 | 9.88 | 52.0% | 62.0% |
| fitzhugh_nagumo | 50 | 0.000209 | 2.61 | 70.0% | 78.0% |
| flexible_arm | 50 | 0.000143 | 0.902 | 70.0% | 80.0% |
| sirt_treatment | 50 | 3.11e-05 | 0.864 | 64.0% | 80.0% |
| slow_fast | 50 | 4.78e-05 | 0.283 | 72.0% | 82.0% |
| daisy_mamil3 | 50 | 4e-06 | 0.106 | 82.0% | 90.0% |
| lotka_volterra | 50 | 2.35e-07 | 0.102 | 86.0% | 90.0% |
| repressilator | 50 | 1.14e-06 | 0.0636 | 84.0% | 94.0% |
| aircraft_pitch | 50 | 0.00058 | 0.0294 | 80.0% | 98.0% |
| forced_lotka_volterra | 50 | 0.000326 | 0.00294 | 96.0% | 98.0% |
| bicycle_model | 50 | 4.33e-05 | 0.00292 | 94.0% | 100.0% |
| boost_converter | 50 | 0.00033 | 0.0267 | 84.0% | 100.0% |
| dc_motor | 50 | 7.69e-05 | 0.0223 | 80.0% | 100.0% |
| harmonic_oscillator | 50 | 7.97e-09 | 4.31e-05 | 100.0% | 100.0% |
| mass_spring_damper | 50 | 2.59e-07 | 0.00225 | 92.0% | 100.0% |
| quadrotor | 50 | 0.000165 | 0.0179 | 88.0% | 100.0% |
| vanderpol | 50 | 2.26e-08 | 0.000124 | 100.0% | 100.0% |

## System × noise grid (%≤10% under S2)

| system | 0 | 1em8 | 1em6 | 1em4 | 1em2 |
|---|---|---|---|---|---|
| aircraft_pitch | 100% | 100% | 100% | 100% | 90% | 
| bicycle_model | 100% | 100% | 100% | 100% | 100% | 
| biohydrogenation | 100% | 100% | 80% | 11% | 0% | 
| boost_converter | 100% | 100% | 100% | 100% | 100% | 
| brusselator | 80% | 70% | 70% | 60% | 30% | 
| crauste | 100% | 80% | 70% | 0% | 0% | 
| cstr | 50% | 10% | 10% | 0% | 0% | 
| daisy_mamil3 | 100% | 100% | 100% | 100% | 50% | 
| daisy_mamil4 | 30% | 44% | 30% | 33% | 0% | 
| dc_motor | 100% | 100% | 100% | 100% | 100% | 
| fitzhugh_nagumo | 100% | 100% | 100% | 90% | 0% | 
| flexible_arm | 100% | 100% | 100% | 100% | 0% | 
| forced_lotka_volterra | 100% | 100% | 100% | 90% | 100% | 
| harmonic_oscillator | 100% | 100% | 100% | 100% | 100% | 
| hiv | 100% | 100% | 30% | 0% | 0% | 
| lotka_volterra | 100% | 100% | 100% | 100% | 50% | 
| mass_spring_damper | 100% | 100% | 100% | 100% | 100% | 
| quadrotor | 100% | 100% | 100% | 100% | 100% | 
| repressilator | 100% | 100% | 100% | 100% | 70% | 
| seir | 90% | 80% | 70% | 10% | 0% | 
| sirt_treatment | 100% | 100% | 100% | 100% | 0% | 
| slow_fast | 100% | 90% | 90% | 90% | 40% | 
| vanderpol | 100% | 100% | 100% | 100% | 100% | 
