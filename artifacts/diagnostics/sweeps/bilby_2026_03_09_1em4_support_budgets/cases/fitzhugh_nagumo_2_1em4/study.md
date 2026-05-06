# Support-Budget Sweep Case: fitzhugh_nagumo_2_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-12T01:14:13.605`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 4.98% / 11.54%
- Benchmark ODEPE runtime: 1414.871 s

## Shared Raw Pool

- Raw candidates: 12
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 10.711 s
- Raw candidate generation: 7.347 s
- Consensus/block context build: 3.364 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.029 | 0.000 | 6489120 |
| `SI Template (SIAN analysis)` | 0.136 | 0.026 | 45329488 |
| `Equation construction + Solving` | 4.419 | 0.096 | 845002672 |
| `Result processing` | 0.174 | 0.000 | 37697936 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=8.382s
- Single-point data eval: `aaad_gpr`=0.014s
- Single-point HC: `aaad_gpr`=0.175s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.237s
- Multipoint evaluation: `aaad_gpr`=0.013s
- Multipoint solve: `aaad_gpr`=0.391s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 322.22% | b (706.10%) | 3.027 | -320.74% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 1.48% | b (3.14%) | 0.566 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 569.71% | b (1214.07%) | 1.766 | -568.23% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 569.71% | b (1214.07%) | 2.669 | -568.23% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 569.71% | b (1214.07%) | 2.736 | -568.23% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 1.48% | b (3.14%) | 1.901 | -0.00% | n/a | `n/a` |

## Recommendations

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_top_3_raw_by_fit`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.027
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.027 | 0.061 | 736278592 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 0.566
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.014 | 0.000 | 0 |
| `polish_raw_candidates` | 0.552 | 0.117 | 429708312 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.014067566` |
| `polish_seconds` | `0.55213903` |
| `seed_indices` | `[3, 4, 12]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.766
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 658368 |
| `assemble_hypotheses` | 1.755 | 0.156 | 693828368 |
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
| `block_count` | `5` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.669
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.947 | 0.049 | 384977704 |
| `block_decomposition` | 0.000 | 0.000 | 658368 |
| `assemble_hypotheses` | 1.714 | 0.148 | 684632848 |
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
| `block_count` | `5` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.736
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 1.010 | 0.099 | 385084136 |
| `block_decomposition` | 0.000 | 0.000 | 658368 |
| `assemble_hypotheses` | 1.720 | 0.148 | 684448096 |
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
| `block_count` | `5` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 1.901
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 658368 |
| `assemble_hypotheses` | 1.755 | 0.156 | 693828368 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 15712 |
| `build_polish_context` | 0.007 | 0.000 | 0 |
| `polish_block_v2_best` | 0.128 | 0.000 | 139840728 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 1.766022092, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.786e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000367858, 658368, 0.0), TimingPhaseEntry("assemble_hypotheses", 1.755360381, 693828368, 0.156379528), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 1.351e-6, 0, 0.0), TimingPhaseEntry("variable_confidence", 6.9547e-5, 15712, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 5, :hypothesis_count => 20, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.007111387` |
| `polish_seconds` | `0.128356929` |

