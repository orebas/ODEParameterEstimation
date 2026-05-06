# Branch v1 Sweep Case: daisy_mamil3_7_1em4

- Model: `daisy_mamil3`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `requested`
- Generated: `2026-04-06T20:04:29.688`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.00% | 0.01% | 489.255 | true |
| `odepe_multipoint` | 100.00% | Inf | 32.647 | false |
- Benchmark classification: `a_only`

## Shared Raw Pool

- Raw candidates: 6
- Baseline-family count: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 1.8592e-05 | 6.88% | 5.46% | 60.759 |
| `family_consensus` | `ok` | raw | 1.8592e-05 | 6.88% | 5.46% | 57.720 |
| `synthesized_finalizer` | `ok` | raw | 1.8592e-05 | 6.88% | 5.46% | 155.787 |
| `branch_consensus_v1` | `ok` | refined | 3.4696e-07 | 0.01% | 0.01% | 84.346 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | a12 (7.73% → 7.73%) | a12 (7.73% → 7.73%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | a12 (7.73% → 7.73%) | a12 (7.73% → 7.73%) |
| `branch_consensus_v1` | 1.8245e-05 | 6.88% | 5.46% | a21 (13.24% → 0.01%) | x2(0) (0.01% → 0.00%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 3
- Guard applied: false
- Winner lineage: method=direct_opt, source=synthesized, shoot=1, candidate=3, interp=aaad_gpr, polished=true

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 1 | 0.9360 | 3 | 3 | 3 | `high` | true | multipoint | 1, 275 | 3 |
| 2 | 1 | 0.7385 | 2 | 2 | 2 | `medium` | true | single_point | 275 | none |
| 3 | 1 | 0.6805 | 1 | 1 | 1 | `medium` | false | single_point | 1 | none |
| 4 | 1 | 0.5210 | 5 | 5 | 5 | `low` | false | single_point | 1 | none |
| 5 | 1 | 0.4290 | 4 | 4 | 4 | `low` | false | single_point | 1501 | none |

## Best Strategy

- Best combined-RMSE strategy on this case: `branch_consensus_v1`

