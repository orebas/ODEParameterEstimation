# Crauste Saved-Pool Comparison

- Case: `crauste_3_1em8`
- Generated: `2026-04-16T21:06:39.555`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Shared raw pool: saved bilby `odepe_nopolish/result.csv` candidates
- Local comparison basis: stock polish vs frontier modes on the same imported pool

## Saved Benchmark References

| Method | Selected RMSE | Selected Max Rel Err | Success |
| --- | ---: | ---: | ---: |
| `amigo2_run` | 0.00% | 0.01% | true |
| `odepe_nopolish` | 29.23% | 410.64% | false |
| `odepe_polish` | 197.84% | 1438.70% | false |

## Imported Raw Pool

- Imported candidate count: 13
- Import runtime: 50.138 s
- Shared context build runtime: 437.580 s
- Best-fit imported candidate RMSE: 285819.02%
- Best imported candidate in set RMSE: 285819.02%
- Saved `odepe_polish` best imported RMSE: 291.90%

## Same-Pool Local Comparison

| Arm | Selected RMSE | Best In Set RMSE | Merged Seeds | Polished Seeds | Finalists | Runtime |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `stock_polish` | 285819.07% | 285819.02% | 20 | 20 | 20 | 243.224 s |
| `frontier_raw_only` | 285819.07% | 285819.07% | 13 | 13 | 13 | 409.649 s |
| `frontier_raw_plus_block` | 285819.07% | 285819.07% | 26 | 26 | 26 | 667.351 s |
| `frontier_raw_plus_block_branch` | 285819.07% | 285819.07% | 26 | 26 | 25 | 818.550 s |
| `frontier_full` | 285819.07% | 285819.07% | 26 | 26 | 25 | 848.010 s |

## Frontier Timing Breakdown

| Mode | Block | Branch | Synth | Seed Prep | Total Generator | Total Selection | Polish Errors | Maxiters Errors |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `frontier_raw_only` | 0.0000e+00 s | 0.0000e+00 s | 0.0000e+00 s | 0.026 s | 0.026 s | 409.649 s | 0 | 0 |
| `frontier_raw_plus_block` | 36.635 s | 0.0000e+00 s | 0.0000e+00 s | 0.352 s | 36.986 s | 667.351 s | 0 | 0 |
| `frontier_raw_plus_block_branch` | 17.218 s | 154.040 s | 0.0000e+00 s | 0.029 s | 171.287 s | 818.550 s | 0 | 0 |
| `frontier_full` | 17.972 s | 142.432 s | 8.354 s | 0.025 s | 168.783 s | 848.010 s | 0 | 0 |

## Conclusions

- `frontier_raw_only` vs stock best-in-set: `worse`; vs saved `odepe_polish` best-in-set: `worse`.
- `frontier_raw_plus_block` vs stock best-in-set: `worse`; vs saved `odepe_polish` best-in-set: `worse`.
- `frontier_raw_plus_block_branch` vs stock best-in-set: `worse`; vs saved `odepe_polish` best-in-set: `worse`.
- `frontier_full` vs stock best-in-set: `worse`; vs saved `odepe_polish` best-in-set: `worse`.
