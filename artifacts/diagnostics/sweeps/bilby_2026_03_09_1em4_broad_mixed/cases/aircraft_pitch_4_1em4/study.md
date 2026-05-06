# Bilby Sweep Case: aircraft_pitch_4_1em4

- Model: `aircraft_pitch`
- Bucket: `ODEPE-only / contrast`
- Selected via: `preferred`
- Generated: `2026-04-06T14:01:24.886`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_4_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 4.14% | 28.97% | 738.314 | false |
| `odepe_multipoint` | 1.22% | 4.83% | 648.208 | true |
- Benchmark classification: `b_only`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 22.347 s shared

## Shared Raw Pool

- Raw candidates: 3
- Families: 3
- Best raw fit index: 2
- Best raw oracle index: 2
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 6.5565e-08 | 2.45% | 123.56% | method=algebraic, source=single_point, shoot=275, candidate=2, interp=aaad_gpr, structural_fix=1, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 3.7731e-05 | 381.14% | 256.97% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, structural_fix=1, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 3.7731e-05 | 381.14% | 256.97% | method=algebraic, source=single_point, shoot=1, candidate=1, interp=aaad_gpr, structural_fix=1, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | -3.7665e-05 | -378.69% | -133.42% | theta(0) (370.63% → 115.05%) | Z_alpha (4.91% → 762.28%) |
| `synthesized_finalizer` | -3.7665e-05 | -378.69% | -133.42% | theta(0) (370.63% → 115.05%) | Z_alpha (4.91% → 762.28%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | - | none | none | none | false | Inf | Inf | Inf | Inf |

## Conclusion

- Primary: `raw_pool_too_sparse`

