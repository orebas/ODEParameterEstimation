# Finisher Sweep Case: brusselator_1_1em4

- Model: `brusselator`
- Bucket: `both_success / room_to_improve`
- Generated: `2026-04-09T23:53:52.534`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_1_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 2.29% / 9.17%
- Benchmark ODEPE runtime: 2477.439 s

## Shared Raw Pool

- Raw candidates: 5
- Best raw fit index: 4
- Best raw oracle index: 4
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 31.130 s
- Raw candidate generation: 25.691 s
- Consensus/block context build: 5.439 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.559 | 0.000 | 86242968 |
| `SI Template (SIAN analysis)` | 0.476 | 0.028 | 115594760 |
| `Equation construction + Solving` | 14.013 | 0.475 | 3266796680 |
| `Result processing` | 1.338 | 0.000 | 273961016 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=10.633s
- Single-point data eval: `aaad_gpr`=0.027s
- Single-point HC: `aaad_gpr`=4.706s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=0.629s
- Multipoint evaluation: `aaad_gpr`=0.007s
- Multipoint solve: `aaad_gpr`=3.263s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 3.41% | X(0) (6.82%) | 8.673 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | Inf | none | 71.691 | Inf | n/a |
| `polish_top_3_raw_by_fit` | `ok` | Inf | none | 0.581 | Inf | n/a |
| `block_v2_no_polish` | `ok` | 3.41% | X(0) (6.82%) | 23.832 | 0.00% | n/a |
| `polish_block_v2_best` | `ok` | 3.41% | X(0) (6.82%) | 24.031 | 0.00% | n/a |

## Practical Recommendation

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second strategy: `best_fit_baseline`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 8.673
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 8.673 | 2.292 | 8733477136 |

### `polish_best_fit_raw`

- Final lineage: none
- Incremental seconds: 71.691
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.024 | 0.000 | 0 |
| `polish_raw_candidates` | 71.667 | 2.379 | 20277145288 |

### `polish_top_3_raw_by_fit`

- Final lineage: none
- Incremental seconds: 0.581
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.037 | 0.000 | 0 |
| `polish_raw_candidates` | 0.544 | 0.112 | 206982104 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 23.832
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 23.832 | 6.798 | 28768564568 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 24.031
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 23.832 | 6.798 | 28768564568 |
| `build_polish_context` | 0.006 | 0.000 | 0 |
| `polish_block_v2_best` | 0.194 | 0.053 | 69268192 |

