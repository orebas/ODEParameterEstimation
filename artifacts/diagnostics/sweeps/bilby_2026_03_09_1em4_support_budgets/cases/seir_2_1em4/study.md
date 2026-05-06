# Support-Budget Sweep Case: seir_2_1em4

- Model: `seir`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-12T00:59:03.063`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 2.66% / 6.25%
- Benchmark ODEPE runtime: 4445.644 s

## Shared Raw Pool

- Raw candidates: 22
- Best raw fit index: 10
- Best raw oracle index: 15
- Best-fit vs best-truth combined-RMSE gap: 1228.23%

## Shared Timing

- Shared total: 82.325 s
- Raw candidate generation: 72.276 s
- Consensus/block context build: 10.049 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 5.792 | 0.062 | 797746192 |
| `SI Template (SIAN analysis)` | 11.335 | 0.312 | 1882818376 |
| `Equation construction + Solving` | 39.582 | 1.730 | 10428385840 |
| `Result processing` | 9.636 | 0.426 | 2634452720 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=11.604s
- Single-point data eval: `aaad_gpr`=6.269s
- Single-point HC: `aaad_gpr`=15.269s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=4.137s
- Multipoint evaluation: `aaad_gpr`=0.228s
- Multipoint solve: `aaad_gpr`=14.881s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 1409.23% | E(0) (2760.39%) | 29.485 | -1206.44% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 202.79% | In(0) (350.10%) | 39.127 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 65.47% | S(0) (100.00%) | 5.041 | 137.32% | 27.24%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 65.47% | S(0) (100.00%) | 18.552 | 137.32% | 7.40%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 65.47% | S(0) (100.00%) | 17.798 | 137.32% | 7.72%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 44.47% | nu (71.65%) | 5.379 | 158.33% | 29.43%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_best_block_budget`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=1501, candidate=10, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 29.485
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 29.485 | 5.302 | 12602763672 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=15, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 39.127
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.288 | 0.000 | 0 |
| `polish_raw_candidates` | 38.839 | 2.380 | 11217594072 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.288290159` |
| `polish_seconds` | `38.838858142` |
| `seed_indices` | `[10, 12, 15]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 5.041
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.064 | 0.000 | 4561104 |
| `assemble_hypotheses` | 2.173 | 0.155 | 882674352 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 20544 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 18.552
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 15.468 | 5.054 | 11286948992 |
| `block_decomposition` | 0.002 | 0.000 | 2105504 |
| `assemble_hypotheses` | 2.665 | 0.926 | 844893312 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 20544 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 17.798
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 15.216 | 4.861 | 11284800064 |
| `block_decomposition` | 0.001 | 0.000 | 2105504 |
| `assemble_hypotheses` | 2.575 | 0.753 | 844455040 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 20544 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `6` |
| `hypothesis_count` | `10` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 5.379
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.064 | 0.000 | 4561104 |
| `assemble_hypotheses` | 2.173 | 0.155 | 882674352 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 20544 |
| `build_polish_context` | 0.006 | 0.000 | 0 |
| `polish_block_v2_best` | 0.333 | 0.045 | 392818800 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 5.04057925, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 9.095e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.064334028, 4561104, 0.0), TimingPhaseEntry("assemble_hypotheses", 2.172630872, 882674352, 0.154984906), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.11e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 0.000104289, 20544, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 6, :hypothesis_count => 10, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.006078924` |
| `polish_seconds` | `0.332555028` |

