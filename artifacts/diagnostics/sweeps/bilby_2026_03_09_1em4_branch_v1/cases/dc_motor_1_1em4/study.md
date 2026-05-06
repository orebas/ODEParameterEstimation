# Branch v1 Sweep Case: dc_motor_1_1em4

- Model: `dc_motor`
- Bucket: `both_success / room_to_improve`
- Selected via: `requested`
- Generated: `2026-04-06T20:01:14.576`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/dc_motor_1_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.02% | 0.03% | 618.159 | true |
| `odepe_multipoint` | 0.52% | 0.77% | 2428.405 | true |
- Benchmark classification: `both_success`

## Shared Raw Pool

- Raw candidates: 3
- Baseline-family count: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 4.5219e-03 | 17.37% | 10.23% | 62.082 |
| `family_consensus` | `ok` | raw | 4.5219e-03 | 17.37% | 10.23% | 56.705 |
| `synthesized_finalizer` | `ok` | raw | 4.5219e-03 | 17.37% | 10.23% | 153.320 |
| `branch_consensus_v1` | `ok` | raw | 4.5219e-03 | 17.37% | 10.23% | 67.036 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | i(0) (4.98% → 4.98%) | i(0) (4.98% → 4.98%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | i(0) (4.98% → 4.98%) | i(0) (4.98% → 4.98%) |
| `branch_consensus_v1` | 0.0000e+00 | 0.00% | 0.00% | i(0) (4.98% → 4.98%) | i(0) (4.98% → 4.98%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 2
- Guard applied: false
- Winner lineage: method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 1 | 0.8950 | 1 | 1 | 1 | `high` | false | single_point | 1 | none |
| 2 | 1 | 0.6200 | 2 | 2 | 2 | `medium` | false | single_point | 275 | none |
| 3 | 1 | 0.3450 | 3 | 3 | 3 | `fragile` | false | single_point | 1501 | none |

## Best Strategy

- Best combined-RMSE strategy on this case: `best_fit_baseline`

