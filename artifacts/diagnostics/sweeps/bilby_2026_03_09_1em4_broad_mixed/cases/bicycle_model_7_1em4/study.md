# Bilby Sweep Case: bicycle_model_7_1em4

- Model: `bicycle_model`
- Bucket: `both_success / controls`
- Selected via: `preferred`
- Generated: `2026-04-06T13:44:24.091`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/bicycle_model_7_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.00% | 0.00% | 629.694 | true |
| `odepe_multipoint` | 0.02% | 0.05% | 3196.357 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 31.311 s shared

## Shared Raw Pool

- Raw candidates: 3
- Families: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 2.7171e-04 | 25.55% | 16.73% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 2.7171e-04 | 25.55% | 16.73% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 2.7171e-04 | 25.55% | 16.73% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | vy(0) (0.00% → 0.00%) | vy(0) (0.00% → 0.00%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | vy(0) (0.00% → 0.00%) | vy(0) (0.00% → 0.00%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 2, 3 | 3, 2 | true | 5670869.4669 | 1.5408e+03 | 5.0889e+00 | 0.1777 |
| 2 | 2 | `parameter_stitch` | 2, 3 | 3, 2 | true | 5670905.3011 | 1.5408e+03 | 3.5332e+00 | 0.0000 |

## Conclusion

- Primary: `raw_pool_too_sparse`

