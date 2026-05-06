# Bilby Sweep Case: seir_2_1em4

- Model: `seir`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-06T13:28:48.663`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_2_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.48% | 1.25% | 545.805 | true |
| `odepe_multipoint` | 2.66% | 6.25% | 4445.644 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 88.945 s shared

## Shared Raw Pool

- Raw candidates: 22
- Families: 16
- Best raw fit index: 10
- Best raw oracle index: 15
- Best-fit vs best-truth RMSE gap: 1228.23%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 1.4615e+00 | 241.08% | 1409.23% | method=algebraic, source=single_point, shoot=1501, candidate=10, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 2.1812e+00 | 124.53% | 181.00% | method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=15, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 2.1812e+00 | 124.53% | 181.00% | method=algebraic, source=multipoint, combo=2, mp_times=[275, 1501], shoot=275, candidate=15, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | -7.1973e-01 | 116.55% | 1228.23% | E(0) (2760.39% → 199.63%) | Npop(0) (0.00% → 0.00%) |
| `synthesized_finalizer` | -7.1973e-01 | 116.55% | 1228.23% | E(0) (2760.39% → 199.63%) | Npop(0) (0.00% → 0.00%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 2 | `family_barycenter` | 2 | 10, 12 | true | 29612134.5408 | 4.3278e+07 | 5.5041e+01 | 0.0000 |
| 2 | 1 | `family_barycenter` | 1 | 15, 17 | true | 65975817.3067 | 9.6423e+07 | 8.4414e+01 | 0.0000 |
| 3 | 3 | `family_barycenter` | 3 | 16, 18 | true | 68211612.3981 | 9.9690e+07 | 1.0463e+02 | 0.0000 |

## Conclusion

- Primary: `consensus_helped`
- Secondary: `candidate_generation_bottleneck`

