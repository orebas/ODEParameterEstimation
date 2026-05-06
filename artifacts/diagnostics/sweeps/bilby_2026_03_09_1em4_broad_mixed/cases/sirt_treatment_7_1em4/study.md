# Bilby Sweep Case: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Bucket: `AMIGO2-only / ODEPE near-miss`
- Selected via: `preferred`
- Generated: `2026-04-06T13:47:35.346`
- Status: `ok`
- Case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`

## Benchmark Reference

| Comparison | Mean Rel Err | Max Rel Err | Runtime s | Success |
|------------|--------------|-------------|-----------|---------|
| `amigo2_run` | 0.01% | 0.04% | 557.016 | true |
| `odepe_multipoint` | 3.01% | 12.51% | 4839.546 | false |
- Benchmark classification: `a_only`

## Sweep Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved count 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw candidate generation: 691.291 s shared

## Shared Raw Pool

- Raw candidates: 20
- Families: 20
- Best raw fit index: 17
- Best raw oracle index: 4
- Best-fit vs best-truth RMSE gap: 28.87%

## Strategy Comparison

| Strategy | Status | Winner | Fit Error | Param RMSE | Combined RMSE | Lineage |
|----------|--------|--------|-----------|------------|---------------|---------|
| `best_fit_baseline` | `ok` | raw winner | 3.8860e-02 | 46.10% | 35.13% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `family_consensus` | `ok` | raw winner | 3.8860e-02 | 46.10% | 35.13% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| `synthesized_finalizer` | `ok` | raw | 3.8860e-02 | 46.10% | 35.13% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=18, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Baseline Deltas

| Strategy | Fit Delta | Param RMSE Delta | Combined RMSE Delta | Biggest Gain | Biggest Regression |
|----------|-----------|------------------|---------------------|--------------|--------------------|
| `family_consensus` | 0.0000e+00 | 0.00% | 0.00% | In(0) (0.02% → 0.02%) | In(0) (0.02% → 0.02%) |
| `synthesized_finalizer` | 0.0000e+00 | 0.00% | 0.00% | In(0) (0.02% → 0.02%) | In(0) (0.02% → 0.02%) |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 4 | `parameter_stitch` | 1, 3 | 17, 4 | true | 629820.1172 | 2.4475e+04 | 1.3885e+01 | 0.0019 |
| 2 | 3 | `family_medoid_blend` | 1, 3 | 17, 4 | true | 1578834.1512 | 6.1353e+04 | 1.4601e+01 | 0.1345 |
| 3 | 2 | `parameter_stitch` | 1, 2 | 17, 12 | true | 1681602.6987 | 6.5347e+04 | 1.4391e+01 | 0.0172 |
| 4 | 1 | `family_medoid_blend` | 1, 2 | 17, 12 | true | 1766931.3319 | 6.8663e+04 | 1.5057e+01 | 0.1181 |

## Conclusion

- Primary: `raw_pool_too_sparse`
- Secondary: `candidate_generation_bottleneck`

