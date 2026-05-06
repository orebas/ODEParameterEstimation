# Finisher Sweep Case: dc_motor_1_1em4

- Model: `dc_motor`
- Bucket: `both_success / controls`
- Generated: `2026-04-10T00:01:01.610`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/dc_motor_1_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 0.52% / 0.77%
- Benchmark ODEPE runtime: 2428.405 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 17.884 s
- Raw candidate generation: 14.965 s
- Consensus/block context build: 2.918 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.582 | 0.000 | 72634392 |
| `SI Template (SIAN analysis)` | 0.184 | 0.000 | 77307184 |
| `Equation construction + Solving` | 8.244 | 0.523 | 1830267296 |
| `Result processing` | 1.184 | 0.000 | 188199192 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=4.894s
- Single-point data eval: `aaad_gpr`=0.045s
- Single-point HC: `aaad_gpr`=4.578s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.009s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.113s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 10.23% | Jm (22.11%) | 2.190 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 234163624869.34% | _trfn_sin_5_0(0) (573581397250.39%) | 73.961 | -234163624859.11% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 207701451.25% | _trfn_sin_5_0(0) (508762574.40%) | 1.314 | -207701441.01% | n/a |
| `block_v2_no_polish` | `ok` | 3.97% | i(0) (8.49%) | 4.151 | 6.27% | 1.51%/s |
| `polish_block_v2_best` | `ok` | 207701450.73% | _trfn_sin_5_0(0) (508762573.11%) | 4.462 | -207701440.49% | n/a |

## Practical Recommendation

- Best quality strategy: `block_v2_no_polish`
- Best gain-per-added-second strategy: `block_v2_no_polish`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.190
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.190 | 0.078 | 639309992 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 73.961
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.023 | 0.000 | 0 |
| `polish_raw_candidates` | 73.938 | 2.628 | 19003833576 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.314
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.044 | 0.000 | 0 |
| `polish_raw_candidates` | 1.270 | 0.148 | 536040960 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 4.151
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 4.151 | 0.327 | 2559846424 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 4.462
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 4.151 | 0.327 | 2559846424 |
| `build_polish_context` | 0.008 | 0.000 | 0 |
| `polish_block_v2_best` | 0.303 | 0.036 | 195179304 |

