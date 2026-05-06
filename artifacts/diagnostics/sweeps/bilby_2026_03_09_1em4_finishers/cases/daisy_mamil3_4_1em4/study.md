# Finisher Sweep Case: daisy_mamil3_4_1em4

- Model: `daisy_mamil3`
- Bucket: `both_success / room_to_improve`
- Generated: `2026-04-09T23:58:24.949`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_4_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 0.88% / 2.54%
- Benchmark ODEPE runtime: 4099.973 s

## Shared Raw Pool

- Raw candidates: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 42.638 s
- Raw candidate generation: 35.295 s
- Consensus/block context build: 7.343 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.609 | 0.000 | 72693816 |
| `SI Template (SIAN analysis)` | 0.435 | 0.000 | 113611048 |
| `Equation construction + Solving` | 24.930 | 0.792 | 6202264432 |
| `Result processing` | 1.223 | 0.000 | 214689472 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=10.675s
- Single-point data eval: `aaad_gpr`=3.763s
- Single-point HC: `aaad_gpr`=7.101s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=3.436s
- Multipoint evaluation: `aaad_gpr`=0.021s
- Multipoint solve: `aaad_gpr`=8.240s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 1.47% | x3(0) (2.62%) | 4.093 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 2.41% | x3(0) (4.76%) | 84.403 | -0.94% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 0.01% | x3(0) (0.01%) | 1.786 | 1.47% | 0.82%/s |
| `block_v2_no_polish` | `ok` | 1.47% | x3(0) (2.62%) | 11.673 | 0.00% | n/a |
| `polish_block_v2_best` | `ok` | 0.01% | x3(0) (0.01%) | 12.059 | 1.47% | 0.12%/s |

## Practical Recommendation

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second strategy: `polish_top_3_raw_by_fit`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 4.093
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 4.093 | 0.103 | 1132828216 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 84.403
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.026 | 0.000 | 0 |
| `polish_raw_candidates` | 84.377 | 3.173 | 21401516024 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.786
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.041 | 0.000 | 0 |
| `polish_raw_candidates` | 1.745 | 0.308 | 1338707008 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 11.673
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 11.673 | 0.801 | 6055241112 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 12.059
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 11.673 | 0.801 | 6055241112 |
| `build_polish_context` | 0.007 | 0.000 | 0 |
| `polish_block_v2_best` | 0.379 | 0.064 | 346678488 |

