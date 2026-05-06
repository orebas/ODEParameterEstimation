# Bilby Sweep Summary: support budgets

- Generated: `2026-04-12T01:48:42.496`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Noise slice: `1e-4`
- Total cases: 15
- Support budgets: `4x4, 8x8, 12x12`
- Oracle note: truth metrics here are benchmark-only evaluation and were not used by any finisher.

## Best-Quality Counts

- `best_fit_baseline`: 5
- `polish_top_3_raw_by_fit`: 3
- `block_v2_no_polish_4x4`: 1
- `block_v2_no_polish_8x8`: 0
- `block_v2_no_polish_12x12`: 0
- `polish_best_block_budget`: 6

## Delta vs `polish_top_3_raw_by_fit`

| Strategy | Mean Combined-RMSE Delta | Median Combined-RMSE Delta | Median Added s | Mean Gain / s |
|----------|---------------------------|-----------------------------|----------------|---------------|
| `best_fit_baseline` | 16728601939.93% | -2.92% | 3.593 | 17720608125.62%/s |
| `block_v2_no_polish_4x4` | 16728601976.70% | 2.30% | 1.617 | 36860921086.07%/s |
| `block_v2_no_polish_8x8` | 16728601976.70% | 2.30% | 2.720 | 31898233691.15%/s |
| `block_v2_no_polish_12x12` | 16728601976.70% | 2.30% | 2.736 | 32950782723.17%/s |
| `polish_best_block_budget` | -14332644681.42% | 0.04% | 2.583 | 21019480115.59%/s |

## Winner Changes Across Budgets

- `8x8` vs `4x4`: winner changed on 0 case(s)
- `12x12` vs `8x8`: winner changed on 0 case(s)

## Budget Follow-Ups

- Biggest `8x8` gain over `4x4`: `seir_2_1em4` (0.00%)
- Biggest `12x12` gain over `8x8`: `seir_2_1em4` (0.00%)
- Biggest regression from larger budgets: `seir_2_1em4` (0.00%)

## Per-Case Outcomes

| Case | Bucket | Top-3 Polish | 4x4 | 8x8 | 12x12 | Polish Best Block | Practical Winner |
|------|--------|--------------|--------------|--------------|--------------|--------------|--------------|
| `seir_2_1em4` | both_success / room_to_improve | 202.79% | 65.47% | 65.47% | 65.47% | 44.47% | `polish_best_block_budget` |
| `brusselator_1_1em4` | both_success / room_to_improve | Inf | 3.41% | 3.41% | 3.41% | Inf | `polish_top_3_raw_by_fit` |
| `fitzhugh_nagumo_3_1em4` | both_success / room_to_improve | 0.54% | 7.09% | 7.09% | 7.09% | 0.54% | `polish_top_3_raw_by_fit` |
| `daisy_mamil3_4_1em4` | both_success / room_to_improve | 1.09% | 1.47% | 1.47% | 1.47% | 0.01% | `polish_best_block_budget` |
| `dc_motor_1_1em4` | both_success / controls | 234163624869.34% | 3.97% | 3.97% | 3.97% | 207701450.73% | `block_v2_no_polish_4x4` |
| `bicycle_model_7_1em4` | both_success / controls | 274737.06% | 31.69% | 31.69% | 31.69% | 274737.03% | `block_v2_no_polish_12x12` |
| `daisy_mamil3_7_1em4` | AMIGO2-only / ODEPE near-miss | 0.01% | 5.14% | 5.14% | 5.14% | 0.01% | `polish_best_block_budget` |
| `fitzhugh_nagumo_2_1em4` | AMIGO2-only / ODEPE near-miss | 1.48% | 569.71% | 569.71% | 569.71% | 1.48% | `polish_top_3_raw_by_fit` |
| `sirt_treatment_7_1em4` | AMIGO2-only / ODEPE near-miss | 0.20% | 570.63% | 570.63% | 570.63% | 482.90% | `polish_top_3_raw_by_fit` |
| `aircraft_pitch_4_1em4` | ODEPE-only / contrast | 38.35% | 33.37% | 33.37% | 33.37% | 33.33% | `block_v2_no_polish_4x4` |
| `forced_lotka_volterra_2_1em4` | both_success / room_to_improve | 19615518.77% | 1.17% | 1.17% | 1.17% | 19615518.72% | `block_v2_no_polish_4x4` |
| `sirt_treatment_6_1em4` | both_success / room_to_improve | 20.74% | 26.53% | 26.53% | 26.53% | 11.70% | `polish_best_block_budget` |
| `slow_fast_0_1em4` | both_success / room_to_improve | 110.43% | 50.22% | 50.22% | 50.22% | 35.12% | `polish_best_block_budget` |
| `forced_lotka_volterra_5_1em4` | both_success / room_to_improve | 16913687.48% | 3.62% | 3.62% | 3.62% | 16913687.55% | `block_v2_no_polish_4x4` |
| `boost_converter_6_1em4` | both_success / room_to_improve | 5.75% | 150.15% | 150.15% | 150.15% | 434612948730.27% | `polish_top_3_raw_by_fit` |

