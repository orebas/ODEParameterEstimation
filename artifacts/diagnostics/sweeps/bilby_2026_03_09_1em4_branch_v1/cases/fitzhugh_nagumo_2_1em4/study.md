# Branch v1 Sweep Case: fitzhugh_nagumo_2_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `requested`
- Generated: `2026-04-06T20:07:40.389`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.89% | 3.14% | 690.788 | true |
| `odepe_multipoint` | 4.98% | 11.54% | 1414.871 | false |
- Benchmark classification: `a_only`

## Shared Raw Pool

- Raw candidates: 12
- Baseline-family count: 10
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 1.4977e-04 | 415.98% | 322.22% | 37.859 |
| `family_consensus` | `ok` | raw | 1.4977e-04 | 415.98% | 322.22% | 35.500 |
| `synthesized_finalizer` | `ok` | raw | 1.4977e-04 | 415.98% | 322.22% | 117.887 |
| `branch_consensus_v1` | `ok` | refined | 3.6106e-05 | 1.91% | 1.48% | 53.201 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | g (1.73% → 1.73%) | g (1.73% → 1.73%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | g (1.73% → 1.73%) | g (1.73% → 1.73%) |
| `branch_consensus_v1` | 1.1366e-04 | 414.07% | 320.74% | b (706.10% → 3.14%) | Vm(0) (0.01% → 0.00%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 5
- Guard applied: false
- Winner lineage: method=direct_opt, source=synthesized, shoot=1, candidate=12, interp=aaad_gpr, polished=true

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 1 | 0.8407 | 12 | 12 | 12 | `high` | true | multipoint | 1, 275 | 3 |
| 2 | 1 | 0.7989 | 11 | 11 | 11 | `medium` | true | multipoint | 1, 275 | 3 |
| 3 | 1 | 0.7482 | 3 | 3 | 3 | `medium` | true | single_point | 275 | none |
| 4 | 1 | 0.7032 | 10 | 10 | 10 | `medium` | false | multipoint | 275, 1501 | 2 |
| 5 | 1 | 0.6564 | 4 | 4 | 4 | `medium` | false | single_point | 275 | none |

## Best Strategy

- Best combined-RMSE strategy on this case: `branch_consensus_v1`

