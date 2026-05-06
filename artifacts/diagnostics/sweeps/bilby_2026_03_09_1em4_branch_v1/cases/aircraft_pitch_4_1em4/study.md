# Branch v1 Sweep Case: aircraft_pitch_4_1em4

- Model: `aircraft_pitch`
- Bucket: `ODEPE-only / contrast`
- Selected via: `requested`
- Generated: `2026-04-06T20:10:49.077`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_4_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 4.14% | 28.97% | 738.314 | false |
| `odepe_multipoint` | 1.22% | 4.83% | 648.208 | true |
- Benchmark classification: `b_only`

## Shared Raw Pool

- Raw candidates: 3
- Baseline-family count: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 6.5565e-08 | 2.45% | 123.56% | 28.763 |
| `family_consensus` | `ok` | raw | 3.7731e-05 | 381.14% | 256.97% | 26.525 |
| `synthesized_finalizer` | `ok` | raw | 3.7731e-05 | 381.14% | 256.97% | 26.579 |
| `branch_consensus_v1` | `ok` | refined | 2.5399e-12 | 0.00% | 123.54% | 142.976 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | -3.7665e-05 | -378.69% | -133.42% | theta(0) (370.63% → 115.05%) | Z_alpha (4.91% → 762.28%) |
| `synthesized_finalizer` | -3.7665e-05 | -378.69% | -133.42% | theta(0) (370.63% → 115.05%) | Z_alpha (4.91% → 762.28%) |
| `branch_consensus_v1` | 6.5562e-08 | 2.45% | 0.01% | Z_alpha (4.91% → 0.00%) | _trfn_cos_2_0(0) (0.00% → 0.00%) |

## Branch v1 Top Hypotheses

- Best branch index: 2
- Adaptive K: 2
- Guard applied: true
- Winner lineage: method=direct_opt, source=synthesized, shoot=275, candidate=2, interp=aaad_gpr, polished=true

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 1 | 0.7937 | 1 | 1 | 1 | `medium` | false | single_point | 1 | none |
| 2 | 1 | 0.7213 | 2 | 2 | 2 | `medium` | true | single_point | 275 | none |
| 3 | 1 | 0.3450 | 3 | 3 | 3 | `fragile` | false | single_point | 1501 | none |

## Best Strategy

- Best combined-RMSE strategy on this case: `branch_consensus_v1`

