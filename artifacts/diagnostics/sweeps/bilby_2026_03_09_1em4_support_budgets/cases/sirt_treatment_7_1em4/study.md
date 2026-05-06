# Support-Budget Sweep Case: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-12T01:14:38.445`
- Status: `ok`
- Datasize: 1501
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`
- Support budgets: `4x4, 8x8, 12x12`

## Benchmark Reference

- Classification: `a_only`
- Benchmark ODEPE mean/max relative error: 3.01% / 12.51%
- Benchmark ODEPE runtime: 4839.546 s

## Shared Raw Pool

- Raw candidates: 20
- Best raw fit index: 17
- Best raw oracle index: 4
- Best-fit vs best-truth combined-RMSE gap: 28.87%

## Shared Timing

- Shared total: 665.511 s
- Raw candidate generation: 358.189 s
- Consensus/block context build: 307.322 s

### Raw Estimation Phases

| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `Setup (identifiability)` | 27.505 | 0.704 | 7513841040 |
| `SI Template (SIAN analysis)` | 109.176 | 2.630 | 27476600016 |
| `Equation construction + Solving` | 119.831 | 3.550 | 27125537616 |
| `Result processing` | 4.049 | 0.976 | 2104397232 |

### Raw Estimation Subphase Totals

- Interpolant creation: `aaad_gpr`=208.187s
- Single-point data eval: `aaad_gpr`=1.236s
- Single-point HC: `aaad_gpr`=14.413s
- Single-point system solve: none
- Multipoint template: `aaad_gpr`=7.450s
- Multipoint evaluation: `aaad_gpr`=0.023s
- Multipoint solve: `aaad_gpr`=7.467s

## Strategy Comparison

| Strategy | Budget | Status | Combined RMSE | Worst Error | Added s | Delta vs Top-3 Polish | Gain / s | Reused Baseline Evidence |
|----------|--------|--------|---------------|-------------|---------|------------------------|----------|--------------------------|
| `best_fit_baseline` | `3x3` | `ok` | 35.13% | a (86.26%) | 12.545 | -34.93% | n/a | `n/a` |
| `polish_top_3_raw_by_fit` | `0x0` | `ok` | 0.20% | d (0.55%) | 48.463 | 0.00% | n/a | `n/a` |
| `block_v2_no_polish_4x4` | `4x4` | `ok` | 570.63% | d (1690.22%) | 4.774 | -570.44% | n/a | `true` |
| `block_v2_no_polish_8x8` | `8x8` | `ok` | 570.63% | d (1690.22%) | 8.739 | -570.44% | n/a | `false` |
| `block_v2_no_polish_12x12` | `12x12` | `ok` | 570.63% | d (1690.22%) | 8.477 | -570.44% | n/a | `false` |
| `polish_best_block_budget` | `3x3` | `ok` | 482.90% | d (1444.35%) | 5.505 | -482.70% | n/a | `n/a` |

## Recommendations

- Best quality strategy: `polish_top_3_raw_by_fit`
- Best gain-per-added-second vs `polish_top_3_raw_by_fit`: `polish_top_3_raw_by_fit`
- Best no-polish block budget by fit: `block_v2_no_polish_4x4`

## Per-Strategy Timing Detail

### `best_fit_baseline`

- Budget: `3x3`
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 12.545
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `best_fit_baseline` | 12.545 | 0.639 | 2399387816 |

### `polish_top_3_raw_by_fit`

- Budget: `0x0`
- Final lineage: method=algebraic, source=single_point, shoot=275, candidate=4, interp=aaad_gpr, polished=true, template=determined, practical=advisory_available, advisory=available
- Incremental seconds: 48.463
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `build_polish_context` | 0.029 | 0.000 | 0 |
| `polish_raw_candidates` | 48.434 | 2.731 | 13777995088 |

| Detail | Value |
|--------|-------|
| `build_polish_context_seconds` | `0.02855718` |
| `polish_seconds` | `48.434054095` |
| `seed_indices` | `[17, 4, 12]` |
| `polished_candidate_count` | `3` |

### `block_v2_no_polish_4x4`

- Budget: `4x4`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 4.774
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 1866840 |
| `assemble_hypotheses` | 4.730 | 0.503 | 2005812464 |
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
| `block_count` | `7` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `true` |

### `block_v2_no_polish_8x8`

- Budget: `8x8`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 8.739
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 4.158 | 0.500 | 1729073576 |
| `block_decomposition` | 0.001 | 0.000 | 1866840 |
| `assemble_hypotheses` | 4.564 | 0.521 | 1971549016 |
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
| `block_count` | `7` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `block_v2_no_polish_12x12`

- Budget: `12x12`
- Final lineage: method=direct_opt, source=assembled
- Incremental seconds: 8.477
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 3.993 | 0.411 | 1728886968 |
| `block_decomposition` | 0.001 | 0.000 | 1866840 |
| `assemble_hypotheses` | 4.477 | 0.510 | 1971471336 |
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
| `block_count` | `7` |
| `hypothesis_count` | `20` |
| `reused_baseline_report` | `false` |

### `polish_best_block_budget`

- Budget: `3x3`
- Final lineage: method=direct_opt, source=assembled, polished=true
- Incremental seconds: 5.505
- Source no-polish block strategy: `block_v2_no_polish_4x4`
| Phase | Seconds | GC s | Bytes |
|-------|---------|------|-------|
| `reuse_or_build_evidence` | 0.000 | 0.000 | 1104 |
| `block_decomposition` | 0.001 | 0.000 | 1866840 |
| `assemble_hypotheses` | 4.730 | 0.503 | 2005812464 |
| `hypothesis_rescore` | 0.000 | 0.000 | 0 |
| `polish_hypotheses` | 0.000 | 0.000 | 0 |
| `variable_confidence` | 0.000 | 0.000 | 23840 |
| `build_polish_context` | 0.010 | 0.000 | 0 |
| `polish_block_v2_best` | 0.721 | 0.211 | 693804672 |

| Detail | Value |
|--------|-------|
| `block_summary_timing` | `TimingBreakdown(:block_v2_no_polish_4x4, 4.773655762, TimingPhaseEntry[TimingPhaseEntry("reuse_or_build_evidence", 7.805e-6, 1104, 0.0), TimingPhaseEntry("block_decomposition", 0.000890422, 1866840, 0.0), TimingPhaseEntry("assemble_hypotheses", 4.730243406, 2005812464, 0.503204224), TimingPhaseEntry("hypothesis_rescore", 0.0, 0, 0.0), TimingPhaseEntry("polish_hypotheses", 8.54e-7, 0, 0.0), TimingPhaseEntry("variable_confidence", 9.8926e-5, 23840, 0.0)], OrderedDict{Symbol, Any}(:reused_support_points => true, :reused_support_combos => true, :reused_candidate_evidence => true, :support_point_count => 3, :support_combo_count => 3, :block_count => 7, :hypothesis_count => 20, :reused_baseline_report => true))` |
| `build_polish_context_seconds` | `0.010081011` |
| `polish_seconds` | `0.720979057` |

