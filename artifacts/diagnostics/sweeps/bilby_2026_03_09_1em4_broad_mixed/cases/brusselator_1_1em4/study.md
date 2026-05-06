# Bilby Sweep Case: brusselator_1_1em4

- Model: `brusselator`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-06T13:36:44.160`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_1_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.80% | 1.59% | 710.538 | true |
| `odepe_multipoint` | 2.29% | 9.17% | 2477.439 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 32.852 s shared

## Shared Raw Pool

- Raw candidates: 5
- Families: 5
- Best raw fit index: 4
- Best raw oracle index: 4
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 7.0739e-02 | 0.21% | 3.41% | method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 7.0739e-02 | 0.21% | 3.41% | method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 7.0739e-02 | 0.21% | 3.41% | method=algebraic, source=single_point, rescue=algebraic_resolve_t0, shoot=275, candidate=2, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | b (0.20% → 0.20%) | b (0.20% → 0.20%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | b (0.20% → 0.20%) | b (0.20% → 0.20%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 1, 2 | 4, 5 | false | Inf | Inf | 4.2285e+00 | 0.0024 |
| 2 | 2 | `family_medoid_blend` | 1, 5 | 4, 1 | false | Inf | Inf | 9.5221e+03 | 0.0426 |
| 3 | 3 | `family_medoid_blend` | 3, 4 | 2, 3 | false | Inf | Inf | 4.7894e+02 | 0.0024 |
| 4 | 4 | `parameter_stitch` | 3, 4 | 2, 3 | false | Inf | Inf | 4.7303e+02 | 0.0000 |

## Conclusion

- Primary: `raw_pool_too_sparse`

