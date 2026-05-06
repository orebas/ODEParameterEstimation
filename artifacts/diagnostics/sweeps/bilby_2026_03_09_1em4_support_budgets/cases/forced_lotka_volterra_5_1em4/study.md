# Support-Budget Sweep Case: forced_lotka_volterra_5_1em4

- Model: `forced_lotka_volterra`
- Bucket: `both_success / room_to_improve`
- Selected via: `extended_fallback`
- Generated: `2026-04-12T01:46:06.163`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_5_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.18% / 3.63%
- Benchmark ODEPE runtime: 2187.538 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 19.179 s
- Raw candidate generation: 12.114 s
- Consensus/block context build: 7.065 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.039 | 0.000 | 15138488 |
| `SI Template (SIAN analysis)` | 0.372 | 0.000 | 153852488 |
| `Equation construction + Solving` | 6.288 | 0.138 | 1312158856 |
| `Result processing` | 0.105 | 0.000 | 15701528 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=10.460s
- Single-point data eval: `aaad_gpr`=0.047s
- Single-point HC: `aaad_gpr`=0.034s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.030s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.016s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 1.90% | delta (4.48%) | 2.303 | 16913685.59% | 7344927.46%/s | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 16913687.48% | _trfn_sin_2_0(0) (47839132.46%) | 2.965 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 3.62% | delta (9.42%) | 0.343 | 16913683.86% | 49286252.89%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 3.62% | delta (9.42%) | 0.599 | 16913683.86% | 28221385.56%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 3.62% | delta (9.42%) | 0.703 | 16913683.86% | 24044032.21%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 16913687.55% | _trfn_sin_2_0(0) (47839132.65%) | 0.932 | -0.07% | n/a | `n/a` |

## Recommendations

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `block_v2_no_polish_4x4`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.303
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.303 | 0.073 | 401211744 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.965
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.020 | 0.000 | 0 |
| `polish_raw_candidates` | 2.945 | 0.555 | 1972173040 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.019981124` |
| `polish_seconds` | `2.9451397420000003` |
| `seed_indices` | `[2, 1, 3]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.343
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 104832 |
| `assemble_hypotheses` | 0.329 | 0.000 | 128469808 |
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
| `block_count` | `4` |
| `hypothesis_count` | `3` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.599
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.323 | 0.000 | 119079344 |
| `block_decomposition` | 0.000 | 0.000 | 104832 |
| `assemble_hypotheses` | 0.264 | 0.000 | 109743616 |
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
| `block_count` | `4` |
| `hypothesis_count` | `3` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.703
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.480 | 0.128 | 119077504 |
| `block_decomposition` | 0.000 | 0.000 | 104832 |
| `assemble_hypotheses` | 0.217 | 0.000 | 110192816 |
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
| `block_count` | `4` |
| `hypothesis_count` | `3` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 0.932
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 104832 |
| `assemble_hypotheses` | 0.329 | 0.000 | 128469808 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |
| `build_polish_context` | 0.011 | 0.000 | 0 |
| `polish_block_v2_best` | 0.578 | 0.120 | 497459072 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.343172444, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 8.297e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000159866, 104832, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.328786958, 128469808, 0.0), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 1.044e-6, 0, 0.0), TimingPhaseEntry("variable_confidence", 0.000103967, 23792, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 3, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.010679091` |
| `polish_seconds` | `0.57847742` |

