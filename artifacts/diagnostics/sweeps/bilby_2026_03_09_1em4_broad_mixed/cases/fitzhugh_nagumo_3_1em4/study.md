# Bilby Sweep Case: fitzhugh_nagumo_3_1em4

- Model: `fitzhugh_nagumo`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-06T13:37:59.425`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_3_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.29% | 1.20% | 535.127 | true |
| `odepe_multipoint` | 1.62% | 3.25% | 971.669 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 30.756 s shared

## Shared Raw Pool

- Raw candidates: 12
- Families: 9
- Best raw fit index: 8
- Best raw oracle index: 6
- Best-fit vs best-truth RMSE gap: 3.50%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 5.3740e-06 | 13.01% | 10.59% | method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=9, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 3.1972e-05 | 9.15% | 7.09% | method=algebraic, source=multipoint, combo=1, mp_times=[1, 1501], shoot=1, candidate=7, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 3.1972e-05 | 9.15% | 7.09% | method=algebraic, source=multipoint, combo=1, mp_times=[1, 1501], shoot=1, candidate=7, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | -2.6598e-05 | 3.86% | 3.50% | R(0) (7.29% → 0.42%) | Vm(0) (0.00% → 0.00%) |
| `synthesized_finalizer` | -2.6598e-05 | 3.86% | 3.50% | R(0) (7.29% → 0.42%) | Vm(0) (0.00% → 0.00%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 2 | `family_medoid_blend` | 1, 2 | 6, 8 | true | 550.0218 | 2.9499e-03 | 1.8740e+00 | 0.0489 |
| 2 | 1 | `family_barycenter` | 4 | 10, 11 | true | 1373933.9454 | 7.3835e+00 | 2.8879e+00 | 0.0000 |

## Conclusion

- Primary: `consensus_helped`
- Secondary: `candidate_generation_bottleneck`

