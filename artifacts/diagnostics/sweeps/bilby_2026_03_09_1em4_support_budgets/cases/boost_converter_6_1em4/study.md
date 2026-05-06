# Support-Budget Sweep Case: boost_converter_6_1em4

- Model: `boost_converter`
- Bucket: `both_success / room_to_improve`
- Selected via: `extended_fallback`
- Generated: `2026-04-12T01:46:36.466`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/boost_converter_6_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.17% / 3.10%
- Benchmark ODEPE runtime: 7442.822 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 26.122 s
- Raw candidate generation: 20.830 s
- Consensus/block context build: 5.292 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.363 | 0.000 | 22068344 |
| `SI Template (SIAN analysis)` | 0.282 | 0.000 | 120021952 |
| `Equation construction + Solving` | 12.484 | 0.410 | 2833254760 |
| `Result processing` | 1.214 | 0.000 | 186592152 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=9.208s
- Single-point data eval: `aaad_gpr`=0.044s
- Single-point HC: `aaad_gpr`=6.545s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.056s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.023s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 5.75% | C_cap (11.09%) | 2.796 | 0.00% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 5.75% | C_cap (11.09%) | 78.564 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 150.15% | C_cap (397.17%) | 0.729 | -144.40% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 150.15% | C_cap (397.17%) | 0.882 | -144.40% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 150.15% | C_cap (397.17%) | 0.931 | -144.40% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 434612948730.27% | _trfn_sin_5_0(0) (1149877778908.77%) | 5.525 | -434612948724.52% | n/a | `n/a` |

## Recommendations

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_top_3_raw_by_fit`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.796
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.796 | 0.000 | 435960512 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 78.564
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.068 | 0.000 | 0 |
| `polish_raw_candidates` | 78.496 | 2.862 | 20207235952 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.06838613` |
| `polish_seconds` | `78.495660558` |
| `seed_indices` | `[1, 3, 2]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.729
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 96224 |
| `assemble_hypotheses` | 0.632 | 0.000 | 365548472 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 22080 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.882
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.388 | 0.148 | 108872784 |
| `block_decomposition` | 0.000 | 0.000 | 96224 |
| `assemble_hypotheses` | 0.480 | 0.000 | 347329872 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 22080 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.931
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.247 | 0.000 | 108598072 |
| `block_decomposition` | 0.000 | 0.000 | 96224 |
| `assemble_hypotheses` | 0.677 | 0.145 | 347567696 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 22080 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 5.525
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 96224 |
| `assemble_hypotheses` | 0.632 | 0.000 | 365548472 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 22080 |
| `build_polish_context` | 0.011 | 0.000 | 0 |
| `polish_block_v2_best` | 4.785 | 0.327 | 1741210536 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.7287114, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 9.243e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000166768, 96224, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.632468605, 365548472, 0.0), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.91e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 9.2618e-5, 22080, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 9, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.011238282` |
| `polish_seconds` | `4.784597453` |

