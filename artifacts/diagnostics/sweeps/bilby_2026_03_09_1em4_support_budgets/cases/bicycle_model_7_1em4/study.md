# Support-Budget Sweep Case: bicycle_model_7_1em4

- Model: `bicycle_model`
- Bucket: `both_success / controls`
- Selected via: `preferred`
- Generated: `2026-04-12T01:11:23.190`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/bicycle_model_7_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 0.02% / 0.05%
- Benchmark ODEPE runtime: 3196.357 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 29.018 s
- Raw candidate generation: 23.096 s
- Consensus/block context build: 5.922 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.375 | 0.000 | 34650848 |
| `SI Template (SIAN analysis)` | 0.356 | 0.000 | 126989144 |
| `Equation construction + Solving` | 13.588 | 0.591 | 3253923208 |
| `Result processing` | 1.052 | 0.000 | 195506072 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=10.643s
- Single-point data eval: `aaad_gpr`=0.066s
- Single-point HC: `aaad_gpr`=7.098s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=0.976s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.027s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 16.73% | Cf (41.50%) | 2.960 | 274720.34% | 92811.05%/s | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 274737.06% | _trfn_sin_0_5(0) (726885.95%) | 77.958 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 31.69% | Cr (60.34%) | 0.678 | 274705.38% | 405143.39%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 31.69% | Cr (60.34%) | 0.690 | 274705.38% | 398297.94%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 31.69% | Cr (60.34%) | 0.677 | 274705.38% | 405595.50%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 274737.03% | _trfn_sin_0_5(0) (726885.86%) | 1.443 | 0.03% | 0.02%/s | `n/a` |

## Recommendations

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `block_v2_no_polish_12x12`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.960
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.960 | 0.060 | 448944648 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 77.958
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.023 | 0.000 | 0 |
| `polish_raw_candidates` | 77.934 | 3.086 | 21610246544 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.023483124` |
| `polish_seconds` | `77.93420860799999` |
| `seed_indices` | `[1, 2, 3]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.678
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 98592 |
| `assemble_hypotheses` | 0.624 | 0.054 | 241121032 |
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
| `block_count` | `5` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.690
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.188 | 0.000 | 72052360 |
| `block_decomposition` | 0.000 | 0.000 | 98592 |
| `assemble_hypotheses` | 0.491 | 0.053 | 221787008 |
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
| `block_count` | `5` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.677
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.180 | 0.000 | 71695512 |
| `block_decomposition` | 0.000 | 0.000 | 98592 |
| `assemble_hypotheses` | 0.491 | 0.044 | 221780656 |
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
| `block_count` | `5` |
| `hypothesis_count` | `9` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 1.443
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 98592 |
| `assemble_hypotheses` | 0.624 | 0.054 | 241121032 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 22080 |
| `build_polish_context` | 0.009 | 0.000 | 0 |
| `polish_block_v2_best` | 0.757 | 0.077 | 545891304 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.678044822, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.218e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000164465, 98592, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.624441882, 241121032, 0.053539839), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.1e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 9.6065e-5, 22080, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 5, :hypothesis_count => 9, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.008622459` |
| `polish_seconds` | `0.756790585` |

