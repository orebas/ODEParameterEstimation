# Branch v1 Sweep Case: fitzhugh_nagumo_3_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `both_success / room_to_improve`
- Selected via: `requested`
- Generated: `2026-04-06T20:10:04.556`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_3_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.29% | 1.20% | 535.127 | true |
| `odepe_multipoint` | 1.62% | 3.25% | 971.669 | true |
- Benchmark classification: `both_success`

## Shared Raw Pool

- Raw candidates: 12
- Baseline-family count: 9
- Best raw fit index: 8
- Best raw oracle index: 6
- Best-fit vs best-truth RMSE gap: 3.50%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 5.3740e-06 | 13.01% | 10.59% | 19.051 |
| `family_consensus` | `ok` | raw | 3.1972e-05 | 9.15% | 7.09% | 16.691 |
| `synthesized_finalizer` | `ok` | raw | 3.1972e-05 | 9.15% | 7.09% | 20.563 |
| `branch_consensus_v1` | `ok` | raw | 3.1972e-05 | 9.15% | 7.09% | 31.755 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | -2.6598e-05 | 3.86% | 3.50% | R(0) (7.29% → 0.42%) | Vm(0) (0.00% → 0.00%) |
| `synthesized_finalizer` | -2.6598e-05 | 3.86% | 3.50% | R(0) (7.29% → 0.42%) | Vm(0) (0.00% → 0.00%) |
| `branch_consensus_v1` | -2.6598e-05 | 3.86% | 3.50% | R(0) (7.29% → 0.42%) | Vm(0) (0.00% → 0.00%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 5
- Guard applied: false
- Winner lineage: method=algebraic, source=multipoint, combo=1, mp_times=[1, 1501], shoot=1, candidate=7, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 2 | 0.8834 | 6 | 8 | 6 | `high` | false | multipoint | 1, 275, 1501 | 1, 2 |
| 2 | 1 | 0.6714 | 10 | 10 | 10 | `medium` | true | multipoint | 1, 275 | 3 |
| 3 | 1 | 0.6214 | 11 | 11 | 11 | `medium` | true | multipoint | 1, 275 | 3 |
| 4 | 1 | 0.6078 | 7 | 7 | 7 | `medium` | false | multipoint | 1, 1501 | 1 |
| 5 | 1 | 0.5619 | 9 | 9 | 9 | `low` | false | multipoint | 275, 1501 | 2 |

## Best Strategy

- Best combined-RMSE strategy on this case: `family_consensus`

