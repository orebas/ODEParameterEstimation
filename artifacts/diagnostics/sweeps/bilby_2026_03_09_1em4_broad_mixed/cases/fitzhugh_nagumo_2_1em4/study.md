# Bilby Sweep Case: fitzhugh_nagumo_2_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-06T13:47:11.618`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.89% | 3.14% | 690.788 | true |
| `odepe_multipoint` | 4.98% | 11.54% | 1414.871 | false |
- Benchmark classification: `a_only`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 11.244 s shared

## Shared Raw Pool

- Raw candidates: 12
- Families: 10
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 1.4977e-04 | 415.98% | 322.22% | method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 1.4977e-04 | 415.98% | 322.22% | method=algebraic, source=single_point, shoot=275, candidate=3, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | synthesized | 3.6106e-05 | 1.91% | 1.48% | method=direct_opt, source=synthesized, shoot=1, interp=aaad_gpr, polished=true |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | g (1.73% → 1.73%) | g (1.73% → 1.73%) |
| `synthesized_finalizer` | 1.1366e-04 | 414.07% | 320.74% | b (706.10% → 3.14%) | Vm(0) (0.01% → 0.00%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_barycenter` | 2 | 11, 12 | true | 14290.8147 | 2.1401e+00 | 8.5786e+01 | 0.0000 |

## Conclusion

- Primary: `synthesis_helped`

