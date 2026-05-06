# Bilby Sweep Case: daisy_mamil3_4_1em4

- Model: `daisy_mamil3`
- Bucket: `both_success / room_to_improve`
- Selected via: `preferred`
- Generated: `2026-04-06T13:40:07.885`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_4_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.01% | 0.01% | 338.675 | true |
| `odepe_multipoint` | 0.88% | 2.54% | 4099.973 | true |
- Benchmark classification: `both_success`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 44.173 s shared

## Shared Raw Pool

- Raw candidates: 6
- Families: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 6.5183e-06 | 1.45% | 1.47% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 6.5183e-06 | 1.45% | 1.47% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 6.5183e-06 | 1.45% | 1.47% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | a12 (0.82% → 0.82%) | a12 (0.82% → 0.82%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | a12 (0.82% → 0.82%) | a12 (0.82% → 0.82%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 1, 2 | 3, 2 | true | 599.9386 | 3.8880e-03 | 6.3813e-03 | 0.0728 |

## Conclusion

- Primary: `raw_pool_too_sparse`

