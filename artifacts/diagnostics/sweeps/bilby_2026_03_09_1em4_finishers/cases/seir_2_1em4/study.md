# Finisher Sweep Case: seir_2_1em4

- Model: `seir`
- Bucket: `both_success / room_to_improve`
- Generated: `2026-04-09T23:48:18.399`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 2.66% / 6.25%
- Benchmark ODEPE runtime: 4445.644 s

## Shared Raw Pool

- Raw candidates: 22
- Best raw fit index: 10
- Best raw oracle index: 15
- Best-fit vs best-truth combined-RMSE gap: 1228.23%

## Shared Timing

- Shared total: 86.159 s
- Raw candidate generation: 75.987 s
- Consensus/block context build: 10.173 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 5.874 | 0.058 | 797714520 |
| `SI Template (SIAN analysis)` | 12.143 | 0.345 | 1883748264 |
| `Equation construction + Solving` | 42.371 | 2.021 | 10425603064 |
| `Result processing` | 9.483 | 0.234 | 2634402624 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=12.162s
- Single-point data eval: `aaad_gpr`=2.886s
- Single-point HC: `aaad_gpr`=19.034s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=4.638s
- Multipoint evaluation: `aaad_gpr`=0.213s
- Multipoint solve: `aaad_gpr`=12.631s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 1409.23% | E(0) (2760.39%) | 78.004 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 1409.23% | E(0) (2760.39%) | 42.659 | -0.00% | n/a |
| `polish_top_3_raw_by_fit` | `ok` | 202.79% | In(0) (350.10%) | 1.167 | 1206.44% | 1033.91%/s |
| `block_v2_no_polish` | `ok` | 65.47% | S(0) (100.00%) | 72.692 | 1343.76% | 18.49%/s |
| `polish_block_v2_best` | `ok` | 44.47% | nu (71.65%) | 72.982 | 1364.77% | 18.70%/s |

## Practical Recommendation

- Best quality strategy: `polish_block_v2_best`
- Best gain-per-added-second strategy: `polish_top_3_raw_by_fit`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=single_point, shoot=1501, candidate=10, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 78.004
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 78.004 | 27.827 | 51408942664 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=single_point, shoot=1501, candidate=10, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 42.659
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.262 | 0.000 | 0 |
| `polish_raw_candidates` | 42.397 | 2.081 | 10707436016 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=15, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.167
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.034 | 0.000 | 0 |
| `polish_raw_candidates` | 1.133 | 0.191 | 1168809592 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 72.692
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 72.692 | 26.812 | 52860429760 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 72.982
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 72.692 | 26.812 | 52860429760 |
| `build_polish_context` | 0.005 | 0.000 | 0 |
| `polish_block_v2_best` | 0.285 | 0.041 | 392785776 |

