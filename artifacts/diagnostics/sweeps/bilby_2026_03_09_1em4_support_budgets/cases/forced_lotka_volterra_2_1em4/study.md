# Support-Budget Sweep Case: forced_lotka_volterra_2_1em4

- Model: `forced_lotka_volterra`
- Bucket: `both_success / room_to_improve`
- Selected via: `extended_fallback`
- Generated: `2026-04-12T01:30:41.708`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_2_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `both_success`
- Benchmark ODEPE mean/max relative error: 1.99% / 4.66%
- Benchmark ODEPE runtime: 2148.828 s

## Shared Raw Pool

- Raw candidates: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 27.682 s
- Raw candidate generation: 20.209 s
- Consensus/block context build: 7.473 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.050 | 0.000 | 14573232 |
| `SI Template (SIAN analysis)` | 0.375 | 0.000 | 151453720 |
| `Equation construction + Solving` | 12.134 | 0.329 | 2799016568 |
| `Result processing` | 1.202 | 0.000 | 188175776 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=16.085s
- Single-point data eval: `aaad_gpr`=0.045s
- Single-point HC: `aaad_gpr`=4.448s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=1.060s
- Multipoint evaluation: `aaad_gpr`=0.000s
- Multipoint solve: `aaad_gpr`=0.021s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 0.23% | _trfn_sin_2_0(0) (0.65%) | 3.593 | 19615518.54% | 5459435.80%/s | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 19615518.77% | _trfn_sin_2_0(0) (55481065.36%) | 75.116 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 1.17% | delta (3.04%) | 0.822 | 19615517.60% | 23856122.42%/s | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 1.17% | delta (3.04%) | 1.029 | 19615517.60% | 19064786.49%/s | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 1.17% | delta (3.04%) | 0.994 | 19615517.60% | 19737205.54%/s | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 19615518.72% | _trfn_sin_2_0(0) (55481065.22%) | 1.002 | 0.05% | 0.05%/s | `n/a` |

## Recommendations

- Best quality strategy: `best_fit_baseline`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `block_v2_no_polish_4x4`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.593
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.593 | 0.454 | 468655624 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=1501, candidate=3, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 75.116
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.053 | 0.000 | 0 |
| `polish_raw_candidates` | 75.063 | 2.515 | 20055452080 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.053073303` |
| `polish_seconds` | `75.06339502899999` |
| `seed_indices` | `[2, 3, 1]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.822
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 105104 |
| `assemble_hypotheses` | 0.743 | 0.090 | 271127504 |
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
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 1.029
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.328 | 0.000 | 125042880 |
| `block_decomposition` | 0.000 | 0.000 | 105104 |
| `assemble_hypotheses` | 0.691 | 0.101 | 251585344 |
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
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 0.994
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.329 | 0.000 | 125088680 |
| `block_decomposition` | 0.000 | 0.000 | 105104 |
| `assemble_hypotheses` | 0.659 | 0.087 | 251588288 |
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
| `hypothesis_count` | `6` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 1.002
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 105104 |
| `assemble_hypotheses` | 0.743 | 0.090 | 271127504 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23792 |
| `build_polish_context` | 0.010 | 0.000 | 0 |
| `polish_block_v2_best` | 0.170 | 0.000 | 223381936 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 0.822242494, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.839e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000167929, 105104, 0.0), TimingPhaseEntry("assemble_hypotheses", 0.742820857, 271127504, 0.090318632), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.1e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 9.1106e-5, 23792, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 6, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.009706778` |
| `polish_seconds` | `0.170313271` |

