# Support-Budget Sweep Case: daisy_mamil3_7_1em4

- Model: `daisy_mamil3`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-12T01:13:26.386`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 100.00% / Inf
- Benchmark ODEPE runtime: 32.647 s

## Shared Raw Pool

- Raw candidates: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Shared Timing

- Shared total: 27.189 s
- Raw candidate generation: 18.867 s
- Consensus/block context build: 8.322 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 0.029 | 0.000 | 7871056 |
| `SI Template (SIAN analysis)` | 0.299 | 0.039 | 95824536 |
| `Equation construction + Solving` | 12.413 | 0.351 | 2315061048 |
| `Result processing` | 0.135 | 0.000 | 45603312 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=11.684s
- Single-point data eval: `aaad_gpr`=0.046s
- Single-point HC: `aaad_gpr`=4.959s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=3.467s
- Multipoint evaluation: `aaad_gpr`=0.020s
- Multipoint solve: `aaad_gpr`=1.650s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 5.46% | a21 (13.24%) | 3.424 | -5.46% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 0.01% | a31 (0.01%) | 2.159 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 5.14% | a21 (12.39%) | 2.988 | -5.13% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 5.14% | a21 (12.39%) | 3.791 | -5.13% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 5.14% | a21 (12.39%) | 3.815 | -5.13% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 0.01% | a31 (0.01%) | 3.265 | 0.00% | 0.00%/s | `n/a` |

## Recommendations

- Best quality strategy: `polish_best_block_budget`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_best_block_budget`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 3.424
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 3.424 | 0.122 | 779593784 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 2.159
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.014 | 0.000 | 0 |
| `polish_raw_candidates` | 2.145 | 0.681 | 1255810680 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.014498635` |
| `polish_seconds` | `2.1447832690000004` |
| `seed_indices` | `[3, 2, 1]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 2.988
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 260528 |
| `assemble_hypotheses` | 2.977 | 0.250 | 1577072256 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `true` |
| `reused_support_combos` | `true` |
| `reused_candidate_evidence` | `true` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.791
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.955 | 0.091 | 444641600 |
| `block_decomposition` | 0.000 | 0.000 | 260528 |
| `assemble_hypotheses` | 2.827 | 0.237 | 1559376456 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 3.815
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.957 | 0.092 | 444746456 |
| `block_decomposition` | 0.000 | 0.000 | 260528 |
| `assemble_hypotheses` | 2.852 | 0.235 | 1559262104 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |

| Detail | Value |
|--------|-------|
| `reused_support_points` | `false` |
| `reused_support_combos` | `false` |
| `reused_candidate_evidence` | `false` |
| `support_point_count` | `3` |
| `support_combo_count` | `3` |
| `block_count` | `4` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 3.265
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.000 | 0.000 | 260528 |
| `assemble_hypotheses` | 2.977 | 0.250 | 1577072256 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 21424 |
| `build_polish_context` | 0.009 | 0.000 | 0 |
| `polish_block_v2_best` | 0.269 | 0.047 | 249231728 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 2.988128749, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 6.905e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000218168, 260528, 0.0), TimingPhaseEntry("assemble_hypotheses", 2.977197924, 1577072256, 0.250057523), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 9.76e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 7.8757e-5, 21424, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 4, :hypothesis_count => 20, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.00854653` |
| `polish_seconds` | `0.268624498` |

