# Finisher Sweep Case: bicycle_model_7_1em4

- Model: `bicycle_model`
- Bucket: `both_success / controls`
- Generated: `2026-04-10T00:02:50.569`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/bicycle_model_7_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 0.02% / 0.05%
- Benchmark ODEPE runtime: 3196.357 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 30.216 s
- Raw candidate generation: 24.295 s
- Consensus/block context build: 5.920 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.382 | 0.000 | 34669872 |
| `SI Template (SIAN analysis)` | 0.359 | 0.000 | 127335184 |
| `Equation construction + Solving` | 14.388 | 0.690 | 3253818336 |
| `Result processing` | 1.116 | 0.000 | 195519312 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=13.850s
- Single-point data eval: `aaad_gpr`=0.043s
- Single-point HC: `aaad_gpr`=7.820s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.037s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.025s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 16.73% | Cf (41.50%) | 2.363 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 16.73% | Cf (41.50%) | 77.989 | 0.00% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 274737.06% | _trfn_sin_0_5(0) (726885.95%) | 3.415 | -274720.34% | n/a |
| `block_v2_no_polish` | `ok` | 31.69% | Cr (60.34%) | 3.050 | -14.96% | n/a |
| `polish_block_v2_best` | `ok` | 274737.03% | _trfn_sin_0_5(0) (726885.86%) | 3.915 | -274720.30% | n/a |

## Practical Recommendation

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second strategy: `best_fit_baseline`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.363
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.363 | 0.041 | 490668880 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 77.989
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.026 | 0.000 | 0 |
| `polish_raw_candidates` | 77.963 | 2.848 | 19820587152 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.415
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.046 | 0.000 | 0 |
| `polish_raw_candidates` | 3.369 | 0.500 | 2243886240 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.050
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 3.050 | 0.118 | 1220164160 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 3.915
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 3.050 | 0.118 | 1220164160 |
| `build_polish_context` | 0.012 | 0.000 | 0 |
| `polish_block_v2_best` | 0.853 | 0.120 | 545849296 |

