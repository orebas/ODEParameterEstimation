# Support-Budget Sweep Case: dc_motor_1_1em4

- Model: `dc_motor`
- Bucket: `both_success / controls`
- Selected via: `preferred`
- Generated: `2026-04-12T01:09:38.359`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/dc_motor_1_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 0.52% / 0.77%
- Benchmark ODEPE runtime: 2428.405 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 17.102 s
- Raw candidate generation: 14.466 s
- Consensus/block context build: 2.636 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.573 | 0.000 | 72624616 |
| `SI Template (SIAN analysis)` | 0.188 | 0.000 | 77651896 |
| `Equation construction + Solving` | 7.660 | 0.187 | 1830369728 |
| `Result processing` | 1.233 | 0.149 | 188238160 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=4.714s
- Single-point data eval: `aaad_gpr`=0.043s
- Single-point HC: `aaad_gpr`=4.124s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=0.966s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.106s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 10.23% | Jm (22.11%) | 2.643 | 234163624859.11% | 88590143446.42%/s | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 234163624869.34% | _trfn_sin_5_0(0) (573581397250.39%) | 71.281 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 3.97% | i(0) (8.49%) | 0.908 | 234163624865.38% | 257952900031.49%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 3.97% | i(0) (8.49%) | 1.049 | 234163624865.38% | 223239951349.52%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 3.97% | i(0) (8.49%) | 1.015 | 234163624865.38% | 230611292209.96%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 207701450.73% | _trfn_sin_5_0(0) (508762573.11%) | 1.237 | 233955923418.62% | 189175320984.89%/s | `n/a` |

## Recommendations

- Best quality strategy: `block_v2_no_polish_4x4`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `block_v2_no_polish_4x4`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.643
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.643 | 0.041 | 460402424 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 71.281
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.033 | 0.000 | 0 |
| `polish_raw_candidates` | 71.248 | 2.302 | 19301899920 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.033072289` |
| `polish_seconds` | `71.24814713699999` |
| `seed_indices` | `[1, 2, 3]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.908
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 91296 |
| `assemble_hypotheses` | 0.856 | 0.097 | 409660400 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21264 |

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
- Incremental seconds: 1.049
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.233 | 0.000 | 130710704 |
| `block_decomposition` | 0.000 | 0.000 | 91296 |
| `assemble_hypotheses` | 0.808 | 0.082 | 398168856 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21264 |

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
- Incremental seconds: 1.015
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.230 | 0.000 | 130690440 |
| `block_decomposition` | 0.000 | 0.000 | 91296 |
| `assemble_hypotheses` | 0.779 | 0.081 | 398184744 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21264 |

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
- Incremental seconds: 1.237
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 91296 |
| `assemble_hypotheses` | 0.856 | 0.097 | 409660400 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21264 |
| `build_polish_context` | 0.008 | 0.000 | 0 |
| `polish_block_v2_best` | 0.321 | 0.038 | 195224328 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.907776671, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 6.638e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000157556, 91296, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.855842664, 409660400, 0.097484928), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 1.12e-6, 0, 0.0), TimingPhaseEntry("variable_confidence", 8.7552e-5, 21264, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 9, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.00791093` |
| `polish_seconds` | `0.321027221` |

