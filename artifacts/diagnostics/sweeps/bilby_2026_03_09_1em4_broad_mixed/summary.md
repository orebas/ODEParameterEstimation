# Bilby Sweep Summary: benchmark_bilby_2026_03_09

- Generated: `2026-04-06T14:01:53.414`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Noise slice: `1e-4`
- Total cases: 10
- Oracle note: Truth-based metrics in these sweep artifacts are benchmark-only evaluation metrics and were not used by the selector/finalizer.

## Selected Cases

| Case | Bucket | Classification | Selected Via | ODEPE Mean Rel Err | ODEPE Max Rel Err |
|------|--------|----------------|--------------|--------------------|-------------------|
| `seir_2_1em4` | both_success / room_to_improve | `both_success` | `preferred` | 2.66% | 6.25% |
| `brusselator_1_1em4` | both_success / room_to_improve | `both_success` | `preferred` | 2.29% | 9.17% |
| `fitzhugh_nagumo_3_1em4` | both_success / room_to_improve | `both_success` | `preferred` | 1.62% | 3.25% |
| `daisy_mamil3_4_1em4` | both_success / room_to_improve | `both_success` | `preferred` | 0.88% | 2.54% |
| `dc_motor_1_1em4` | both_success / controls | `both_success` | `preferred` | 0.52% | 0.77% |
| `bicycle_model_7_1em4` | both_success / controls | `both_success` | `preferred` | 0.02% | 0.05% |
| `daisy_mamil3_7_1em4` | AMIGO2-only / ODEPE near-miss | `a_only` | `preferred` | 100.00% | Inf |
| `fitzhugh_nagumo_2_1em4` | AMIGO2-only / ODEPE near-miss | `a_only` | `preferred` | 4.98% | 11.54% |
| `sirt_treatment_7_1em4` | AMIGO2-only / ODEPE near-miss | `a_only` | `preferred` | 3.01% | 12.51% |
| `aircraft_pitch_4_1em4` | ODEPE-only / contrast | `b_only` | `preferred` | 1.22% | 4.83% |

## Aggregate Counts

- Consensus beat baseline: 2
- Synthesis beat baseline: 4
- Synthesis beat consensus: 2
- Raw baseline remained best: 6

## Aggregate Deltas

| Metric | Mean | Median |
|--------|------|--------|
| Consensus minus baseline combined RMSE improvement | 109.83% | 0.00% |
| Synthesis minus baseline combined RMSE improvement | 142.45% | 0.00% |
| Consensus minus baseline parameter RMSE improvement | -25.83% | 0.00% |
| Synthesis minus baseline parameter RMSE improvement | 16.27% | 0.00% |
| Consensus minus baseline fit improvement | -7.1979e-02 | 0.0000e+00 |
| Synthesis minus baseline fit improvement | -7.1966e-02 | 0.0000e+00 |

## Conclusion Labels by Bucket

| Bucket | Conclusion | Count |
|--------|------------|-------|
| both_success / room_to_improve | `consensus_helped` | 2 |
| both_success / room_to_improve | `raw_pool_too_sparse` | 2 |
| both_success / controls | `raw_pool_too_sparse` | 2 |
| AMIGO2-only / ODEPE near-miss | `raw_pool_too_sparse` | 1 |
| AMIGO2-only / ODEPE near-miss | `synthesis_helped` | 2 |
| ODEPE-only / contrast | `raw_pool_too_sparse` | 1 |

## Follow-up Shortlist

- biggest positive synthesis delta: `seir_2_1em4` (both_success / room_to_improve) score=1228.23%
- biggest negative synthesis delta: `aircraft_pitch_4_1em4` (ODEPE-only / contrast) score=-133.42%
- biggest best-fit vs best-truth divergence: `seir_2_1em4` (both_success / room_to_improve) score=1228.23%

## Per-Case Outcomes

| Case | Primary Conclusion | Baseline Combined RMSE | Consensus Combined RMSE | Synth Combined RMSE | Best-Fit vs Best-Truth Gap |
|------|--------------------|------------------------|-------------------------|--------------------|----------------------------|
| `seir_2_1em4` | `consensus_helped` | 1409.23% | 181.00% | 181.00% | 1228.23% |
| `brusselator_1_1em4` | `raw_pool_too_sparse` | 3.41% | 3.41% | 3.41% | 0.00% |
| `fitzhugh_nagumo_3_1em4` | `consensus_helped` | 10.59% | 7.09% | 7.09% | 3.50% |
| `daisy_mamil3_4_1em4` | `raw_pool_too_sparse` | 1.47% | 1.47% | 1.47% | 0.00% |
| `dc_motor_1_1em4` | `raw_pool_too_sparse` | 10.23% | 10.23% | 10.23% | 0.00% |
| `bicycle_model_7_1em4` | `raw_pool_too_sparse` | 16.73% | 16.73% | 16.73% | 0.00% |
| `daisy_mamil3_7_1em4` | `synthesis_helped` | 5.46% | 5.46% | 0.01% | 0.00% |
| `fitzhugh_nagumo_2_1em4` | `synthesis_helped` | 322.22% | 322.22% | 1.48% | 0.00% |
| `sirt_treatment_7_1em4` | `raw_pool_too_sparse` | 35.13% | 35.13% | 35.13% | 28.87% |
| `aircraft_pitch_4_1em4` | `raw_pool_too_sparse` | 123.56% | 256.97% | 256.97% | 0.00% |

