# Support-Budget Sweep Case: fitzhugh_nagumo_3_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-12T01:05:02.924`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_3_1em4`
- Support budgets: `4x4, 8x8, 12x12`

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

- Shared total: 28.594 s
- Raw candidate generation: 25.459 s
- Consensus/block context build: 3.136 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 4.579 | 0.000 | 411985080 |
| `SI Template (SIAN analysis)` | 0.288 | 0.018 | 60100448 |
| `Equation construction + Solving` | 14.561 | 0.602 | 3990898648 |
| `Result processing` | 1.147 | 0.000 | 213024904 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=5.171s
- Single-point data eval: `aaad_gpr`=0.022s
- Single-point HC: `aaad_gpr`=9.110s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.293s
- Multipoint evaluation: `aaad_gpr`=0.012s
- Multipoint solve: `aaad_gpr`=5.078s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 10.59% | b (19.09%) | 3.972 | -10.05% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 0.54% | b (1.20%) | 68.144 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 7.09% | b (12.81%) | 1.356 | -6.55% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 7.09% | b (12.81%) | 2.733 | -6.55% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 7.09% | b (12.81%) | 2.357 | -6.55% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 0.54% | b (1.20%) | 1.546 | 0.00% | n/a | `n/a` |

## Recommendations

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_top_3_raw_by_fit`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=9, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.972
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.972 | 0.112 | 855021840 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=multipoint, combo=1, mp_times=[1, 1501], shoot=1, candidate=7, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 68.144
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.025 | 0.000 | 0 |
| `polish_raw_candidates` | 68.119 | 2.340 | 18348224920 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.025426931` |
| `polish_seconds` | `68.11888812800001` |
| `seed_indices` | `[8, 6, 9]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.356
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 524864 |
| `assemble_hypotheses` | 1.320 | 0.106 | 547921712 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 15712 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `16` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.733
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.409 | 0.400 | 428260296 |
| `block_decomposition` | 0.000 | 0.000 | 524864 |
| `assemble_hypotheses` | 1.318 | 0.085 | 538350184 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 15712 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `16` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.357
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.094 | 0.100 | 428171760 |
| `block_decomposition` | 0.000 | 0.000 | 524864 |
| `assemble_hypotheses` | 1.258 | 0.094 | 538683000 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 15712 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `16` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 1.546
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 524864 |
| `assemble_hypotheses` | 1.320 | 0.106 | 547921712 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 15712 |
| `build_polish_context` | 0.006 | 0.000 | 0 |
| `polish_block_v2_best` | 0.184 | 0.024 | 176359912 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 1.355842698, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.929e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000344985, 524864, 0.0), TimingPhaseEntry("assemble_hypotheses", 1.319848534, 547921712, 0.106177208), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.46e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 5.4585e-5, 15712, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 16, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.006375201` |
| `polish_seconds` | `0.184173715` |

