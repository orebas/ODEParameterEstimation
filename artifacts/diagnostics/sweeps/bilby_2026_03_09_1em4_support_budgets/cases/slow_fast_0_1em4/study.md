# Support-Budget Sweep Case: slow_fast_0_1em4

- Model: `slow_fast`
- Bucket: `both_success / room_to_improve`
- Selected via: `extended_fallback`
- Generated: `2026-04-12T01:43:43.603`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/slow_fast_0_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.25% / 5.66%
- Benchmark ODEPE runtime: 7555.584 s

## Shared Raw Pool

- Raw candidates: 18
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 55.490 s
- Raw candidate generation: 40.704 s
- Consensus/block context build: 14.785 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.060 | 0.000 | 11721776 |
| `SI Template (SIAN analysis)` | 0.624 | 0.000 | 208032080 |
| `Equation construction + Solving` | 27.404 | 1.058 | 7730101888 |
| `Result processing` | 1.523 | 0.000 | 300165576 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=24.287s
- Single-point data eval: `aaad_gpr`=0.111s
- Single-point HC: `aaad_gpr`=5.958s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=3.939s
- Multipoint evaluation: `aaad_gpr`=0.026s
- Multipoint solve: `aaad_gpr`=7.694s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 36.50% | xA(0) (90.06%) | 10.023 | 73.93% | 7.38%/s | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 110.43% | xA(0) (292.71%) | 41.060 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 50.22% | xA(0) (123.49%) | 3.181 | 60.21% | 18.93%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 50.22% | xA(0) (123.49%) | 8.894 | 60.21% | 6.77%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 50.22% | xA(0) (123.49%) | 9.001 | 60.21% | 6.69%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 35.12% | xA(0) (88.89%) | 3.835 | 75.30% | 19.64%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_best_block_budget`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 10.023
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 10.023 | 0.620 | 2608313024 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=4, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 41.060
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.033 | 0.000 | 0 |
| `polish_raw_candidates` | 41.026 | 2.059 | 12186950928 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.03325963` |
| `polish_seconds` | `41.026478293` |
| `seed_indices` | `[3, 4, 1]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.181
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 1648456 |
| `assemble_hypotheses` | 3.132 | 0.347 | 1144639736 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `7` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 8.894
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 5.980 | 0.605 | 2150595968 |
| `block_decomposition` | 0.001 | 0.000 | 1648456 |
| `assemble_hypotheses` | 2.892 | 0.239 | 1114984776 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `7` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 9.001
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 6.030 | 0.606 | 2150537392 |
| `block_decomposition` | 0.001 | 0.000 | 1648456 |
| `assemble_hypotheses` | 2.963 | 0.370 | 1115484696 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `7` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 3.835
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 1648456 |
| `assemble_hypotheses` | 3.132 | 0.347 | 1144639736 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |
| `build_polish_context` | 0.010 | 0.000 | 0 |
| `polish_block_v2_best` | 0.644 | 0.212 | 707219728 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 3.180722912, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 1.4103e-5, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000970064, 1648456, 0.0), TimingPhaseEntry("assemble_hypotheses", 3.131807061, 1144639736, 0.346854369), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 9.09e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 0.000125521, 23792, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 7, :hypothesis_count => 10, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.010396323` |
| `polish_seconds` | `0.643696526` |

