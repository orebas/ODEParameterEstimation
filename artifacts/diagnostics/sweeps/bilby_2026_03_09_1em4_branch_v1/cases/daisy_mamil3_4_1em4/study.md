# Branch v1 Sweep Case: daisy_mamil3_4_1em4

- Model: `daisy_mamil3`
- Bucket: `both_success / room_to_improve`
- Selected via: `requested`
- Generated: `2026-04-06T20:56:00.395`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_4_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.01% | 0.01% | 338.675 | true |
| `odepe_multipoint` | 0.88% | 2.54% | 4099.973 | true |
- Benchmark classification: `both_success`

## Shared Raw Pool

- Raw candidates: 6
- Baseline-family count: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 6.5183e-06 | 1.45% | 1.47% | 87.007 |
| `family_consensus` | `ok` | raw | 6.5183e-06 | 1.45% | 1.47% | 80.595 |
| `synthesized_finalizer` | `ok` | raw | 6.5183e-06 | 1.45% | 1.47% | 187.846 |
| `branch_consensus_v1` | `ok` | refined | 4.8800e-07 | 0.01% | 0.01% | 108.774 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | a12 (0.82% → 0.82%) | a12 (0.82% → 0.82%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | a12 (0.82% → 0.82%) | a12 (0.82% → 0.82%) |
| `branch_consensus_v1` | 6.0303e-06 | 1.45% | 1.47% | x3(0) (2.62% → 0.01%) | x2(0) (0.00% → 0.00%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 2
- Guard applied: false
- Winner lineage: method=direct_opt, source=synthesized, shoot=1, candidate=3, interp=aaad_gpr, polished=true

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 2 | 0.9500 | 3 | 3 | 3 | `high` | true | multipoint, single_point | 1, 275 | 3 |
| 2 | 1 | 0.6140 | 1 | 1 | 1 | `medium` | false | single_point | 1 | none |
| 3 | 1 | 0.4860 | 5 | 5 | 5 | `low` | false | single_point | 1 | none |
| 4 | 1 | 0.3940 | 4 | 4 | 4 | `fragile` | false | single_point | 1501 | none |
| 5 | 1 | 0.2750 | 6 | 6 | 6 | `fragile` | false | single_point | 275 | none |

## Best Strategy

- Best combined-RMSE strategy on this case: `branch_consensus_v1`

