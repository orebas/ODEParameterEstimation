# Support-Budget Sweep Case: daisy_mamil3_4_1em4

- Model: `daisy_mamil3`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-12T01:07:01.105`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_4_1em4`
- Support budgets: `4x4, 8x8, 12x12`

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

- Shared total: 41.049 s
- Raw candidate generation: 33.649 s
- Consensus/block context build: 7.400 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.609 | 0.000 | 72657128 |
| `SI Template (SIAN analysis)` | 0.408 | 0.000 | 113506176 |
| `Equation construction + Solving` | 24.097 | 0.987 | 6201201960 |
| `Result processing` | 1.258 | 0.000 | 214612160 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=13.602s
- Single-point data eval: `aaad_gpr`=3.619s
- Single-point HC: `aaad_gpr`=7.090s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=3.359s
- Multipoint evaluation: `aaad_gpr`=0.021s
- Multipoint solve: `aaad_gpr`=5.080s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 1.47% | x3(0) (2.62%) | 4.403 | -0.38% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 1.09% | x3(0) (2.20%) | 83.072 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 1.47% | x3(0) (2.62%) | 3.101 | -0.38% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 1.47% | x3(0) (2.62%) | 3.976 | -0.38% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 1.47% | x3(0) (2.62%) | 4.022 | -0.38% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 0.01% | x3(0) (0.01%) | 3.527 | 1.08% | 0.31%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_best_block_budget`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 4.403
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 4.403 | 0.114 | 846348912 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 83.072
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.029 | 0.000 | 0 |
| `polish_raw_candidates` | 83.042 | 3.373 | 22349768088 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.02945497` |
| `polish_seconds` | `83.042300339` |
| `seed_indices` | `[3, 2, 1]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.101
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 271376 |
| `assemble_hypotheses` | 3.062 | 0.263 | 1423868336 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.976
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.980 | 0.075 | 431844256 |
| `block_decomposition` | 0.000 | 0.000 | 271376 |
| `assemble_hypotheses` | 2.989 | 0.267 | 1406122920 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 4.022
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.000 | 0.076 | 431807144 |
| `block_decomposition` | 0.000 | 0.000 | 271376 |
| `assemble_hypotheses` | 3.016 | 0.273 | 1406092968 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 3.527
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 271376 |
| `assemble_hypotheses` | 3.062 | 0.263 | 1423868336 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |
| `build_polish_context` | 0.007 | 0.000 | 0 |
| `polish_block_v2_best` | 0.419 | 0.078 | 346691792 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 3.100756709, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.452e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000249595, 271376, 0.0), TimingPhaseEntry("assemble_hypotheses", 3.061697142, 1423868336, 0.262554981), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 9.45e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 6.9668e-5, 21424, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 20, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.007413943` |
| `polish_seconds` | `0.418634929` |

