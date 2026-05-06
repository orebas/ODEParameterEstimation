# Support-Budget Sweep Case: aircraft_pitch_4_1em4

- Model: `aircraft_pitch`
- Bucket: `ODEPE-only / contrast`
- Selected via: `preferred`
- Generated: `2026-04-12T01:28:28.683`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_4_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `b_only`
- Benchmark ODEPE mean/max relative error: 1.22% / 4.83%
- Benchmark ODEPE runtime: 648.208 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 20.315 s
- Raw candidate generation: 17.234 s
- Consensus/block context build: 3.080 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.130 | 0.000 | 23860024 |
| `SI Template (SIAN analysis)` | 0.975 | 0.000 | 228619608 |
| `Equation construction + Solving` | 10.842 | 0.380 | 3024200744 |
| `Result processing` | 1.231 | 0.000 | 208956704 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=3.966s
- Single-point data eval: `aaad_gpr`=0.025s
- Single-point HC: `aaad_gpr`=7.487s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.291s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.023s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 123.56% | theta(0) (370.63%) | 2.987 | -85.20% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 38.35% | theta(0) (115.05%) | 93.147 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 33.37% | theta(0) (100.00%) | 0.815 | 4.98% | 6.11%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 33.37% | theta(0) (100.00%) | 1.139 | 4.98% | 4.37%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 33.37% | theta(0) (100.00%) | 1.089 | 4.98% | 4.57%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 33.33% | theta(0) (100.00%) | 1.063 | 5.02% | 4.72%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `block_v2_no_polish_4x4`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, structural_fix=1, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.987
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 2.987 | 0.000 | 511973176 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, polished=true, structural_fix=1, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 93.147
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.030 | 0.000 | 0 |
| `polish_raw_candidates` | 93.117 | 3.535 | 23319729088 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.030052136` |
| `polish_seconds` | `93.116602715` |
| `seed_indices` | `[2, 1, 3]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.815
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 111808 |
| `assemble_hypotheses` | 0.763 | 0.000 | 433101632 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 26912 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.139
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.376 | 0.092 | 171227904 |
| `block_decomposition` | 0.000 | 0.000 | 111808 |
| `assemble_hypotheses` | 0.752 | 0.098 | 417418504 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 26912 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.089
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.245 | 0.000 | 170933584 |
| `block_decomposition` | 0.000 | 0.000 | 111808 |
| `assemble_hypotheses` | 0.837 | 0.089 | 417632312 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 26912 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `8` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 1.063
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 111808 |
| `assemble_hypotheses` | 0.763 | 0.000 | 433101632 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 26912 |
| `build_polish_context` | 0.011 | 0.000 | 0 |
| `polish_block_v2_best` | 0.237 | 0.000 | 187833392 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.814660829, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 6.732e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000180655, 111808, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.763053394, 433101632, 0.0), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.01e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 0.00011537, 26912, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 8, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.011483386` |
| `polish_seconds` | `0.237241528` |

