# Probe 4d — 06 vs 14 candidate-set ceiling

Apples-to-apples: for each of 1130 cells, what's the closest-to-truth
row across *all* rows of result.csv? (06 returns ~2000 rows per cell;
14 returns ≤100 after clustering and `branch_top_k` cap.)

Rows per cell: median 06=378, 14=100; max 06=2849, 14=100.

## Set-ceiling stats

| Threshold | 06 ceiling | 14 ceiling | Δ (pp) |
|---|---|---|---|
| ≤1% | 77.1% | 74.4% | -2.65 |
| ≤10% | 85.1% | 83.9% | -1.24 |
| ≤50% | 92.5% | 90.1% | -2.39 |

## Pairwise

- 06 had a closer row than 14 (clustering lost ceiling): **706** (62.5%)
- 14 had a closer row than 06 (pipeline improved): **337** (29.8%)
- Same: 87 (7.7%)

## Crossing rate

- At ≤1%: 06 succeeded but 14 lost: **34** cells; 14 succeeded but 06 lost: **4**
- At ≤10%: 06 succeeded but 14 lost: **18** cells; 14 succeeded but 06 lost: **4**

## Per-system breakdown (sorted by Δ ascending — biggest 14-losses first)

| system | n | 06 %≤10% | 14 %≤10% | Δ (pp) |
|---|---|---|---|---|
| seir | 50 | 84.0% | 70.0% | -14.0 |
| lotka_volterra | 50 | 100.0% | 92.0% | -8.0 |
| brusselator | 45 | 77.8% | 73.3% | -4.4 |
| sirt_treatment | 50 | 88.0% | 84.0% | -4.0 |
| biohydrogenation | 47 | 59.6% | 57.4% | -2.1 |
| cstr | 50 | 18.0% | 16.0% | -2.0 |
| aircraft_pitch | 50 | 98.0% | 98.0% | +0.0 |
| bicycle_model | 50 | 100.0% | 100.0% | +0.0 |
| boost_converter | 50 | 100.0% | 100.0% | +0.0 |
| daisy_mamil3 | 50 | 90.0% | 90.0% | +0.0 |
| daisy_mamil4 | 48 | 77.1% | 77.1% | +0.0 |
| dc_motor | 50 | 100.0% | 100.0% | +0.0 |
| fitzhugh_nagumo | 50 | 80.0% | 80.0% | +0.0 |
| flexible_arm | 50 | 80.0% | 80.0% | +0.0 |
| forced_lotka_volterra | 50 | 100.0% | 100.0% | +0.0 |
| harmonic_oscillator | 50 | 100.0% | 100.0% | +0.0 |
| hiv | 48 | 47.9% | 47.9% | +0.0 |
| mass_spring_damper | 50 | 100.0% | 100.0% | +0.0 |
| quadrotor | 50 | 100.0% | 100.0% | +0.0 |
| repressilator | 50 | 100.0% | 100.0% | +0.0 |
| slow_fast | 50 | 98.0% | 98.0% | +0.0 |
| vanderpol | 50 | 100.0% | 100.0% | +0.0 |
| crauste | 42 | 50.0% | 57.1% | +7.1 |

## Caveats

- This compares **set ceilings only**. K-recall under ranking schemes (S2, err_only) requires `err` column which the 06 result.csv doesn't have. To get ranked-K-recall on 06, we'd need to re-run the 06 cells through the current pipeline.
- The 14 candidate set already had `branch_top_k = 100` applied. So '14 ceiling' = best of top-100 reps, not best of all generated raw HC candidates. If clustering threw out a truth-near rep that wasn't in the top-100, this would show as a 14-loss.
