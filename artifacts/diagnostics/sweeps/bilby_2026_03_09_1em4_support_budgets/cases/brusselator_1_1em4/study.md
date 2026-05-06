# Support-Budget Sweep Case: brusselator_1_1em4

- Model: `brusselator`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-12T01:03:01.152`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_1_1em4`
- Support budgets: `4x4, 8x8, 12x12`

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

- Shared total: 30.249 s
- Raw candidate generation: 24.973 s
- Consensus/block context build: 5.276 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.554 | 0.000 | 86214320 |
| `SI Template (SIAN analysis)` | 0.432 | 0.000 | 116055520 |
| `Equation construction + Solving` | 13.737 | 0.453 | 3267329592 |
| `Result processing` | 1.228 | 0.000 | 273550672 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=10.447s
- Single-point data eval: `aaad_gpr`=0.026s
- Single-point HC: `aaad_gpr`=4.549s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=0.610s
- Multipoint evaluation: `aaad_gpr`=0.007s
- Multipoint solve: `aaad_gpr`=3.301s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 3.41% | X(0) (6.82%) | 3.735 | Inf | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | Inf | none | 69.058 | Inf | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 3.41% | X(0) (6.82%) | 1.617 | Inf | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 3.41% | X(0) (6.82%) | 2.720 | Inf | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 3.41% | X(0) (6.82%) | 3.146 | Inf | n/a | `false` |
| `polish_best_block_budget` | `0x0` | `error` | Inf | none | Inf | Inf | n/a | `n/a` |

## Recommendations

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_top_3_raw_by_fit`
- Best no-polish block budget by fit: `nothing`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.735
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.735 | 0.450 | 2076453288 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: none
- Incremental seconds: 69.058
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.023 | 0.000 | 0 |
| `polish_raw_candidates` | 69.035 | 2.536 | 20371414056 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.023067102` |
| `polish_seconds` | `69.034786687` |
| `seed_indices` | `[4, 5, 2]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.617
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 108512 |
| `assemble_hypotheses` | 1.585 | 0.500 | 2070859512 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 14128 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `2` |
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.720
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.119 | 0.210 | 1708387208 |
| `block_decomposition` | 0.000 | 0.000 | 108512 |
| `assemble_hypotheses` | 1.595 | 0.491 | 2062490320 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 14128 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `2` |
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.146
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.443 | 0.469 | 1708421960 |
| `block_decomposition` | 0.000 | 0.000 | 108512 |
| `assemble_hypotheses` | 1.698 | 0.539 | 2062425456 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 14128 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `2` |
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `0x0`
- Final lineage: none
- Incremental seconds: Inf
- Source no-polish block strategy: `nothing`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `none` | 0.000 | 0.000 | 0 B |

