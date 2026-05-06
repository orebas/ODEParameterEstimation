# Finisher Sweep Case: aircraft_pitch_4_1em4

- Model: `aircraft_pitch`
- Bucket: `ODEPE-only / contrast`
- Generated: `2026-04-10T00:20:26.221`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_4_1em4`

## Benchmark Reference

- Classification: `b_only`
- Benchmark ODEPE mean/max relative error: 1.22% / 4.83%
- Benchmark ODEPE runtime: 648.208 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 21.959 s
- Raw candidate generation: 18.584 s
- Consensus/block context build: 3.375 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.132 | 0.000 | 23873832 |
| `SI Template (SIAN analysis)` | 1.225 | 0.207 | 229131000 |
| `Equation construction + Solving` | 11.783 | 0.780 | 3024205424 |
| `Result processing` | 1.295 | 0.000 | 208978328 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=4.520s
- Single-point data eval: `aaad_gpr`=0.026s
- Single-point HC: `aaad_gpr`=10.726s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.399s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.023s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 123.56% | theta(0) (370.63%) | 2.667 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 11317.50% | _trfn_sin_2_0(0) (33950.46%) | 94.333 | -11193.94% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 38.35% | theta(0) (115.05%) | 1.673 | 85.20% | 50.93%/s |
| `block_v2_no_polish` | `ok` | 33.37% | theta(0) (100.00%) | 5.131 | 90.18% | 17.58%/s |
| `polish_block_v2_best` | `ok` | 33.33% | theta(0) (100.00%) | 5.379 | 90.22% | 16.77%/s |

## Practical Recommendation

- Best quality strategy: `polish_block_v2_best`
- Best gain-per-added-second strategy: `polish_top_3_raw_by_fit`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, structural_fix=1, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.667
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.667 | 0.098 | 824394008 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, polished=true, structural_fix=1, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 94.333
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.031 | 0.000 | 0 |
| `polish_raw_candidates` | 94.302 | 3.298 | 22572863400 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, structural_fix=1, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.673
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.053 | 0.000 | 0 |
| `polish_raw_candidates` | 1.621 | 0.209 | 977865816 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 5.131
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 5.131 | 0.409 | 3022472272 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 5.379
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 5.131 | 0.409 | 3022472272 |
| `build_polish_context` | 0.011 | 0.000 | 0 |
| `polish_block_v2_best` | 0.237 | 0.000 | 187787320 |

