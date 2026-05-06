# Finisher Sweep Case: fitzhugh_nagumo_2_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Generated: `2026-04-10T00:05:53.116`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 4.98% / 11.54%
- Benchmark ODEPE runtime: 1414.871 s

## Shared Raw Pool

- Raw candidates: 12
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 11.278 s
- Raw candidate generation: 7.909 s
- Consensus/block context build: 3.369 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.032 | 0.000 | 6498464 |
| `SI Template (SIAN analysis)` | 0.108 | 0.000 | 45025208 |
| `Equation construction + Solving` | 4.683 | 0.100 | 845110000 |
| `Result processing` | 0.163 | 0.000 | 37714744 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=8.954s
- Single-point data eval: `aaad_gpr`=0.015s
- Single-point HC: `aaad_gpr`=0.185s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.252s
- Multipoint evaluation: `aaad_gpr`=0.013s
- Multipoint solve: `aaad_gpr`=0.403s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 322.22% | b (706.10%) | 3.991 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 1.48% | b (3.14%) | 0.135 | 320.74% | 2368.30%/s |
| `polish_top_3_raw_by_fit` | `ok` | 1.48% | b (3.14%) | 0.572 | 320.74% | 560.56%/s |
| `block_v2_no_polish` | `ok` | 569.71% | b (1214.07%) | 8.879 | -247.49% | n/a |
| `polish_block_v2_best` | `ok` | 1.48% | b (3.14%) | 9.081 | 320.74% | 35.32%/s |

## Practical Recommendation

- Best quality strategy: `polish_best_fit_raw`
- Best gain-per-added-second strategy: `polish_best_fit_raw`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.991
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.991 | 0.133 | 1051079056 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 0.135
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.015 | 0.000 | 0 |
| `polish_raw_candidates` | 0.120 | 0.000 | 110819496 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 0.572
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.008 | 0.000 | 0 |
| `polish_raw_candidates` | 0.565 | 0.108 | 429687408 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 8.879
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 8.879 | 0.413 | 3034205952 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 9.081
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 8.879 | 0.413 | 3034205952 |
| `build_polish_context` | 0.008 | 0.000 | 0 |
| `polish_block_v2_best` | 0.194 | 0.055 | 139824120 |

