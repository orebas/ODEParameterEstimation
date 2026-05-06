# Bilby Sweep Case: dc_motor_1_1em4

- Model: `dc_motor`
- Bucket: `both_success / controls`
- Selected via: `preferred`
- Generated: `2026-04-06T13:42:38.465`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/dc_motor_1_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.02% | 0.03% | 618.159 | true |
| `odepe_multipoint` | 0.52% | 0.77% | 2428.405 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 18.251 s shared

## Shared Raw Pool

- Raw candidates: 3
- Families: 3
- Best raw fit index: 1
- Best raw oracle index: 1
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 4.5219e-03 | 17.37% | 10.23% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 4.5219e-03 | 17.37% | 10.23% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 4.5219e-03 | 17.37% | 10.23% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | i(0) (4.98% → 4.98%) | i(0) (4.98% → 4.98%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | i(0) (4.98% → 4.98%) | i(0) (4.98% → 4.98%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 1, 3 | 1, 3 | true | 22526.5072 | 1.0181e+02 | 5.4345e+04 | 1.0000 |

## Conclusion

- Primary: `raw_pool_too_sparse`

