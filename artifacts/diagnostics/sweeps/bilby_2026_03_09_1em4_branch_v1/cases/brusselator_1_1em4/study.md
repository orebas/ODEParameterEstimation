# Branch v1 Sweep Case: brusselator_1_1em4

- Model: `brusselator`
- Bucket: `both_success / room_to_improve`
- Selected via: `requested`
- Generated: `2026-04-06T20:52:19.524`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_1_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.80% | 1.59% | 710.538 | true |
| `odepe_multipoint` | 2.29% | 9.17% | 2477.439 | true |
- Benchmark classification: `both_success`

## Shared Raw Pool

- Raw candidates: 5
- Baseline-family count: 5
- Best raw fit index: 4
- Best raw oracle index: 4
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 7.0739e-02 | 0.21% | 3.41% | 75.868 |
| `family_consensus` | `ok` | raw | 7.0739e-02 | 0.21% | 3.41% | 70.939 |
| `synthesized_finalizer` | `ok` | raw | 7.0739e-02 | 0.21% | 3.41% | 92.441 |
| `branch_consensus_v1` | `ok` | raw | 7.0739e-02 | 0.21% | 3.41% | 110.174 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | b (0.20% → 0.20%) | b (0.20% → 0.20%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | b (0.20% → 0.20%) | b (0.20% → 0.20%) |
| `branch_consensus_v1` | 0.0000e+00 | 0.00% | 0.00% | b (0.20% → 0.20%) | b (0.20% → 0.20%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 2
- Guard applied: false
- Winner lineage: method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 3 | 0.8113 | 4 | 4 | 4 | `high` | false | single_point | 1, 275, 1501 | none |
| 2 | 2 | 0.6113 | 2 | 2 | 2 | `medium` | false | multipoint | 1, 275, 1501 | 1, 3 |

## Best Strategy

- Best combined-RMSE strategy on this case: `best_fit_baseline`

