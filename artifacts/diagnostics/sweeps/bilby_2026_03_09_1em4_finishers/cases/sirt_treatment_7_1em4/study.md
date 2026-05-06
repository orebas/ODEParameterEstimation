# Finisher Sweep Case: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Generated: `2026-04-10T00:06:21.426`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 3.01% / 12.51%
- Benchmark ODEPE runtime: 4839.546 s

## Shared Raw Pool

- Raw candidates: 20
- Best raw fit index: 17
- Best raw oracle index: 4
- Best-fit vs best-truth combined-RMSE gap: 28.87%

## Shared Timing

- Shared total: 687.275 s
- Raw candidate generation: 372.631 s
- Consensus/block context build: 314.644 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 28.896 | 0.725 | 7387729872 |
| `SI Template (SIAN analysis)` | 112.617 | 2.748 | 27494346688 |
| `Equation construction + Solving` | 128.338 | 4.125 | 27126235536 |
| `Result processing` | 4.004 | 0.887 | 2104504024 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=214.590s
- Single-point data eval: `aaad_gpr`=1.418s
- Single-point HC: `aaad_gpr`=11.785s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=6.958s
- Multipoint evaluation: `aaad_gpr`=0.025s
- Multipoint solve: `aaad_gpr`=9.996s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 35.13% | a (86.26%) | 13.997 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 35.13% | a (86.26%) | 49.071 | 0.00% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 0.20% | d (0.55%) | 2.003 | 34.93% | 17.44%/s |
| `block_v2_no_polish` | `ok` | 570.63% | d (1690.22%) | 20.075 | -535.51% | n/a |
| `polish_block_v2_best` | `ok` | 482.90% | d (1444.35%) | 20.783 | -447.77% | n/a |

## Practical Recommendation

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second strategy: `polish_top_3_raw_by_fit`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 13.997
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 13.997 | 0.516 | 3431830304 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 49.071
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.029 | 0.000 | 0 |
| `polish_raw_candidates` | 49.042 | 1.912 | 12454760584 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=4, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.003
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.042 | 0.000 | 0 |
| `polish_raw_candidates` | 1.961 | 0.500 | 2016677272 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 20.075
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 20.075 | 1.564 | 8478949592 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 20.783
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 20.075 | 1.564 | 8478949592 |
| `build_polish_context` | 0.018 | 0.000 | 0 |
| `polish_block_v2_best` | 0.690 | 0.146 | 693753976 |

