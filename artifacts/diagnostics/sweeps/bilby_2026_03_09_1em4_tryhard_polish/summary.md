# Tryhard Finalist Benchmark Summary

- Generated: `2026-04-15T12:27:01.638`
- Benchmark root: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09`
- Noise slice: `1e-4`
- Policy: `preserve baseline standard-polish seeds, add all current generator families under conservative filtering, apply a soft 1.5x frontier cap, cluster polished basins, return finalists`
- Block support budget: `4x4`
- Total cases: 1
- Oracle note: truth metrics here are benchmark-only evaluation and were not used to rank local tryhard seeds, polished basins, or finalists.

## Headline

- Reasonable frontier finalist set beats benchmark `odepe_polish`: 1
- Ties within tolerance: 0
- Benchmark `odepe_polish` remains better: 0

## Aggregate Delta vs Benchmark `odepe_polish`

- Mean best-in-set combined-RMSE improvement: 6.15%
- Median best-in-set combined-RMSE improvement: 6.15%
- Mean local total runtime: 448.284 s
- Median local total runtime: 448.284 s
- Mean local polish-only runtime: 109.328 s
- Median local polish-only runtime: 109.328 s
- Mean merged finalist count: 29.00
- Median merged finalist count: 29.00

## Coverage Modes

- `baseline_seed_family_win`: 0
- `additive_seed_family_win`: 0
- `both_seed_families_win`: 1
- `merged_only_win`: 0
- `no_improvement`: 0

## Family Coverage vs Benchmark `odepe_polish`

- Baseline-only finalist set better: 1
- Additive-only finalist set better: 1
- Reasonable frontier finalist set better: 1

## Wins by Family

- `brusselator`: merged finalist set better 1, ties 0, benchmark polish better 0

## Per-Case Outcomes

| Case | Role | Benchmark Polish | Baseline Best-In-Set | Additive Best-In-Set | Frontier Best-In-Set | Frontier Ranked Best | Finalists | Outcome |
|------|------|------------------|-----------------|-------------------|--------------------|--------------------|-----------|---------|
| `brusselator_5_1em4` | `guard` | 6.23% | 0.09% | 0.08% | 0.08% | 0.08% | 29 | `finalist_set_better` |

