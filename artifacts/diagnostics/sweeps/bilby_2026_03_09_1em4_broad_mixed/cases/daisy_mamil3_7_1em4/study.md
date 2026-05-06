# Bilby Sweep Case: daisy_mamil3_7_1em4

- Model: `daisy_mamil3`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-06T13:46:29.758`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.00% | 0.01% | 489.255 | true |
| `odepe_multipoint` | 100.00% | Inf | 32.647 | false |
- Benchmark classification: `a_only`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 29.522 s shared

## Shared Raw Pool

- Raw candidates: 6
- Families: 6
- Best raw fit index: 3
- Best raw oracle index: 3
- Best-fit vs best-truth RMSE gap: 0.00%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 1.8592e-05 | 6.88% | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 1.8592e-05 | 6.88% | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | synthesized | 3.4696e-07 | 0.01% | 0.01% | method=direct_opt, source=synthesized, interp=aaad_gpr, polished=true |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | a12 (7.73% → 7.73%) | a12 (7.73% → 7.73%) |
| `synthesized_finalizer` | 1.8245e-05 | 6.88% | 5.46% | a21 (13.24% → 0.01%) | x2(0) (0.01% → 0.00%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 1, 2 | 3, 2 | true | 4148.2092 | 7.7038e-02 | 2.2909e-01 | 0.1501 |

## Conclusion

- Primary: `synthesis_helped`
- Secondary: `raw_pool_too_sparse`

