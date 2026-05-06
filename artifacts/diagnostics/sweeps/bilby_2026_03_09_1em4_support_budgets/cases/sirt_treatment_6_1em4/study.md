# Support-Budget Sweep Case: sirt_treatment_6_1em4

- Model: `sirt_treatment`
- Bucket: `both_success / room_to_improve`
- Selected via: `extended_fallback`
- Generated: `2026-04-12T01:32:44.695`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_6_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.93% / 7.73%
- Benchmark ODEPE runtime: 4193.434 s

## Shared Raw Pool

- Raw candidates: 26
- Best raw fit index: 6
- Best raw oracle index: 7
- Best-fit vs best-truth combined-RMSE gap: 35.56%

## Shared Timing

- Shared total: 526.895 s
- Raw candidate generation: 259.310 s
- Consensus/block context build: 267.586 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 40.943 | 0.782 | 9503407928 |
| `SI Template (SIAN analysis)` | 194.228 | 4.149 | 40536778760 |
| `Equation construction + Solving` | 16.357 | 1.290 | 3075666792 |
| `Result processing` | 0.700 | 0.000 | 365013112 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=15.050s
- Single-point data eval: `aaad_gpr`=0.091s
- Single-point HC: `aaad_gpr`=1.034s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=9.780s
- Multipoint evaluation: `aaad_gpr`=0.023s
- Multipoint solve: `aaad_gpr`=0.667s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 56.06% | d (147.01%) | 20.745 | -35.32% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 20.74% | d (45.62%) | 1.926 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 26.53% | a (60.44%) | 6.735 | -5.79% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 26.53% | a (60.44%) | 20.403 | -5.79% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 26.53% | a (60.44%) | 19.611 | -5.79% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 11.70% | a (32.29%) | 7.394 | 9.04% | 1.22%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_best_block_budget`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 20.745
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 20.745 | 4.634 | 7949001760 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=23, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 1.926
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.019 | 0.000 | 0 |
| `polish_raw_candidates` | 1.906 | 0.594 | 1956924024 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.019374633` |
| `polish_seconds` | `1.906165954` |
| `seed_indices` | `[6, 7, 23]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 6.735
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 2366720 |
| `assemble_hypotheses` | 6.721 | 2.074 | 5488265936 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23840 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 20.403
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 13.702 | 4.462 | 7394003104 |
| `block_decomposition` | 0.001 | 0.000 | 2366720 |
| `assemble_hypotheses` | 6.687 | 2.254 | 5454178872 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23840 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 19.611
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 13.040 | 3.850 | 7392983648 |
| `block_decomposition` | 0.001 | 0.000 | 2366720 |
| `assemble_hypotheses` | 6.564 | 2.002 | 5453974120 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23840 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 7.394
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 2366720 |
| `assemble_hypotheses` | 6.721 | 2.074 | 5488265936 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23840 |
| `build_polish_context` | 0.012 | 0.000 | 0 |
| `polish_block_v2_best` | 0.647 | 0.000 | 587943240 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 6.735247561, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 8.073e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.001019462, 2366720, 0.0), TimingPhaseEntry("assemble_hypotheses", 6.72095182, 5488265936, 2.073540423), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.94e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 0.000184913, 23840, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 6, :hypothesis_count => 8, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.011623239` |
| `polish_seconds` | `0.647050498` |

