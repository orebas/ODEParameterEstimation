# Finisher Sweep Case: fitzhugh_nagumo_3_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `both_success / room_to_improve`
- Generated: `2026-04-09T23:56:21.354`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_3_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.62% / 3.25%
- Benchmark ODEPE runtime: 971.669 s

## Shared Raw Pool

- Raw candidates: 12
- Best raw fit index: 8
- Best raw oracle index: 6
- Best-fit vs best-truth combined-RMSE gap: 3.50%

## Shared Timing

- Shared total: 29.607 s
- Raw candidate generation: 26.052 s
- Consensus/block context build: 3.555 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 4.747 | 0.000 | 412601776 |
| `SI Template (SIAN analysis)` | 0.272 | 0.000 | 60451400 |
| `Equation construction + Solving` | 14.591 | 0.382 | 3991071376 |
| `Result processing` | 1.204 | 0.000 | 213020448 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=5.342s
- Single-point data eval: `aaad_gpr`=0.024s
- Single-point HC: `aaad_gpr`=8.277s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.328s
- Multipoint evaluation: `aaad_gpr`=0.013s
- Multipoint solve: `aaad_gpr`=5.233s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 10.59% | b (19.09%) | 4.075 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 11.25% | b (21.75%) | 70.680 | -0.66% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 0.54% | b (1.20%) | 1.123 | 10.05% | 8.95%/s |
| `block_v2_no_polish` | `ok` | 7.09% | b (12.81%) | 6.855 | 3.50% | 0.51%/s |
| `polish_block_v2_best` | `ok` | 0.54% | b (1.20%) | 7.055 | 10.05% | 1.42%/s |

## Practical Recommendation

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second strategy: `polish_top_3_raw_by_fit`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=9, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 4.075
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 4.075 | 0.164 | 1075792448 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=9, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 70.680
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.024 | 0.000 | 0 |
| `polish_raw_candidates` | 70.655 | 2.323 | 18024189400 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=multipoint, combo=1, mp_times=[1, 1501], shoot=1, candidate=7, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.123
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.037 | 0.000 | 0 |
| `polish_raw_candidates` | 1.086 | 0.132 | 498835712 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 6.855
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 6.855 | 0.330 | 2554599952 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 7.055
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 6.855 | 0.330 | 2554599952 |
| `build_polish_context` | 0.006 | 0.000 | 0 |
| `polish_block_v2_best` | 0.193 | 0.027 | 176342096 |

