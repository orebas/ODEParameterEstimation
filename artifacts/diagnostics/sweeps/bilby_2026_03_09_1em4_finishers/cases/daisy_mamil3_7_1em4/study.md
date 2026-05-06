# Finisher Sweep Case: daisy_mamil3_7_1em4

- Model: `daisy_mamil3`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Generated: `2026-04-10T00:05:00.383`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 100.00% / Inf
- Benchmark ODEPE runtime: 32.647 s

## Shared Raw Pool

- Raw candidates: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 28.968 s
- Raw candidate generation: 19.682 s
- Consensus/block context build: 9.286 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.028 | 0.000 | 7880800 |
| `SI Template (SIAN analysis)` | 0.231 | 0.000 | 96770832 |
| `Equation construction + Solving` | 13.070 | 0.397 | 2315324056 |
| `Result processing` | 0.142 | 0.000 | 45607408 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=12.241s
- Single-point data eval: `aaad_gpr`=0.048s
- Single-point HC: `aaad_gpr`=1.359s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=3.760s
- Multipoint evaluation: `aaad_gpr`=0.023s
- Multipoint solve: `aaad_gpr`=1.720s

## Strategy Comparison

| Strategy | Status | Combined RMSE | Worst Error | Added s | Gain vs Baseline | Gain / s |
|----------|--------|---------------|-------------|---------|------------------|----------|
| `best_fit_baseline` | `ok` | 5.46% | a21 (13.24%) | 4.421 | 0.00% | n/a |
| `polish_best_fit_raw` | `ok` | 0.01% | a31 (0.01%) | 0.419 | 5.46% | 13.04%/s |
| `polish_top_3_raw_by_fit` | `ok` | 0.01% | a31 (0.01%) | 1.820 | 5.46% | 3.00%/s |
| `block_v2_no_polish` | `ok` | 5.14% | a21 (12.39%) | 13.831 | 0.33% | 0.02%/s |
| `polish_block_v2_best` | `ok` | 0.01% | a31 (0.01%) | 14.120 | 5.46% | 0.39%/s |

## Practical Recommendation

- Best quality strategy: `polish_block_v2_best`
- Best gain-per-added-second strategy: `polish_best_fit_raw`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 4.421
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 4.421 | 0.162 | 1330411224 |

### `polish_best_fit_raw`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 0.419
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.029 | 0.000 | 0 |
| `polish_raw_candidates` | 0.390 | 0.103 | 287548072 |

### `polish_top_3_raw_by_fit`

- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.820
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.009 | 0.000 | 0 |
| `polish_raw_candidates` | 1.811 | 0.274 | 1255814528 |

### `block_v2_no_polish`

- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 13.831
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 13.831 | 1.094 | 8547971648 |

### `polish_block_v2_best`

- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 14.120
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `block_consensus_v2_no_polish` | 13.831 | 1.094 | 8547971648 |
| `build_polish_context` | 0.009 | 0.000 | 0 |
| `polish_block_v2_best` | 0.281 | 0.048 | 249234848 |

