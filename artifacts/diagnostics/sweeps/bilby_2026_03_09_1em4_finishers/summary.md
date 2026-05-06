# Bilby Sweep Summary: cheap finishers

- Generated: `2026-04-10T00:22:44.329`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Noise slice: `1e-4`
- Total cases: 10
- Oracle note: truth metrics here are benchmark-only evaluation and were not used by any finisher.

## Best-Quality Counts

- `best_fit_baseline`: 2
- `polish_best_fit_raw`: 1
- `polish_top_3_raw_by_fit`: 3
- `block_v2_no_polish`: 1
- `polish_block_v2_best`: 3
- Baseline remained best: 2

## Average Added Time and Gain

| Strategy | Mean Combined-RMSE Gain | Median Added s | Mean Gain / s |
|----------|-------------------------|----------------|---------------|
| `polish_best_fit_raw` | -26018181747.60% | 71.185 | 1190.67%/s |
| `polish_top_3_raw_by_fit` | -23108277.45% | 1.493 | 239.37%/s |
| `block_v2_no_polish` | 64.61% | 10.276 | 7.62%/s |
| `polish_block_v2_best` | -20797481.59% | 10.570 | 12.12%/s |

## Per-Case Outcomes

| Case | Bucket | Baseline | Polish Best Fit | Polish Top 3 | Block No Polish | Polish Block Best | Practical Winner |
|------|--------|----------|-----------------|--------------|-----------------|-------------------|------------------|
| `seir_2_1em4` | both_success / room_to_improve | 1409.23% | 1409.23% | 202.79% | 65.47% | 44.47% | `polish_top_3_raw_by_fit` |
| `brusselator_1_1em4` | both_success / room_to_improve | 3.41% | Inf | Inf | 3.41% | 3.41% | `best_fit_baseline` |
| `fitzhugh_nagumo_3_1em4` | both_success / room_to_improve | 10.59% | 11.25% | 0.54% | 7.09% | 0.54% | `polish_top_3_raw_by_fit` |
| `daisy_mamil3_4_1em4` | both_success / room_to_improve | 1.47% | 2.41% | 0.01% | 1.47% | 0.01% | `polish_top_3_raw_by_fit` |
| `dc_motor_1_1em4` | both_success / controls | 10.23% | 234163624869.34% | 207701451.25% | 3.97% | 207701450.73% | `block_v2_no_polish` |
| `bicycle_model_7_1em4` | both_success / controls | 16.73% | 16.73% | 274737.06% | 31.69% | 274737.03% | `best_fit_baseline` |
| `daisy_mamil3_7_1em4` | AMIGO2-only / ODEPE near-miss | 5.46% | 0.01% | 0.01% | 5.14% | 0.01% | `polish_best_fit_raw` |
| `fitzhugh_nagumo_2_1em4` | AMIGO2-only / ODEPE near-miss | 322.22% | 1.48% | 1.48% | 569.71% | 1.48% | `polish_best_fit_raw` |
| `sirt_treatment_7_1em4` | AMIGO2-only / ODEPE near-miss | 35.13% | 35.13% | 0.20% | 570.63% | 482.90% | `polish_top_3_raw_by_fit` |
| `aircraft_pitch_4_1em4` | ODEPE-only / contrast | 123.56% | 11317.50% | 38.35% | 33.37% | 33.33% | `polish_top_3_raw_by_fit` |

