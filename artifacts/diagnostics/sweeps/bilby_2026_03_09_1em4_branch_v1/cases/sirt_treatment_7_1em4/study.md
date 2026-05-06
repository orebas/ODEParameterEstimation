# Branch v1 Sweep Case: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `requested`
- Generated: `2026-04-07T00:52:56.370`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.01% | 0.04% | 557.016 | true |
| `odepe_multipoint` | 3.01% | 12.51% | 4839.546 | false |
- Benchmark classification: `a_only`

## Shared Raw Pool

- Raw candidates: 20
- Baseline-family count: 20
- Best raw fit index: 17
- Best raw oracle index: 4
- Best-fit vs best-truth RMSE gap: 28.87%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Effective Total s |
|----------|--------|--------|-----------|------------|---------------|-------------------|
| `best_fit_baseline` | `ok` | raw | 3.8860e-02 | 46.10% | 35.13% | 708.277 |
| `family_consensus` | `ok` | raw | 3.8860e-02 | 46.10% | 35.13% | 697.345 |
| `synthesized_finalizer` | `ok` | raw | 3.8860e-02 | 46.10% | 35.13% | 771.716 |
| `branch_consensus_v1` | `ok` | raw | 9.7203e-02 | 47.64% | 35.76% | 785.005 |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | In(0) (0.02% → 0.02%) | In(0) (0.02% → 0.02%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | In(0) (0.02% → 0.02%) | In(0) (0.02% → 0.02%) |
| `branch_consensus_v1` | -5.8343e-02 | -1.54% | -0.63% | a (86.26% → 7.56%) | d (38.38% → 106.24%) |

## Branch v1 Top Hypotheses

- Best branch index: 1
- Adaptive K: 5
- Guard applied: false
- Winner lineage: method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=13, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available

| Rank | Size | Branch Score | Representative | Best Fit | Best Eq | Confidence | Refined | Sources | Shooting Support | Combo Support |
|------|------|--------------|----------------|----------|---------|------------|---------|---------|------------------|---------------|
| 1 | 2 | 0.8874 | 12 | 4 | 4 | `high` | false | multipoint, single_point | 275, 1501 | 2 |
| 2 | 1 | 0.8553 | 17 | 17 | 17 | `high` | false | multipoint | 1, 275 | 3 |
| 3 | 1 | 0.8012 | 8 | 8 | 8 | `high` | false | multipoint | 1, 1501 | 1 |
| 4 | 1 | 0.6620 | 13 | 13 | 13 | `medium` | false | multipoint | 275, 1501 | 2 |
| 5 | 1 | 0.6508 | 16 | 16 | 16 | `medium` | false | multipoint | 1, 275 | 3 |

## Best Strategy

- Best combined-RMSE strategy on this case: `best_fit_baseline`

