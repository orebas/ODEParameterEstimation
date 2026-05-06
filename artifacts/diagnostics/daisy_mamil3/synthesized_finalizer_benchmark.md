# Synthesized Finalizer Benchmark: daisy_mamil3

- Dataset: `benchmark_bilby_2026_03_09/daisy_mamil3_7_1em4`
- Generated: `2026-04-06T10:01:34.005`
- Total runtime: 242.537 s
- Raw candidate count: 6
- Family count: 6
- Synthesized seeds: 1 (1 accepted for refinement)
- Refined synthesized results: 1
- Winning origin: `raw`
- Oracle note: Truth-based metrics in this artifact are benchmark-only evaluation metrics and were not used by the synthesized selector.

## What's New

- The finalizer now generates new seeds from the raw SP/MP candidate pool instead of only selecting an existing candidate.
- Seed generation includes within-family barycenters and guarded cross-family synthesis, including grouped parameter stitching.
- Every synthesized seed is screened with oracle-free fit and equation checks before optional full-trajectory refinement.
- The final choice still stays oracle-free; truth metrics here are benchmark-only evaluation.

## Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved interpolator count: 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Raw-generation polishing: solver=false, final=false, maxiters=20, maxtime=5.0 s
- Base consensus: strategy=`family_consensus`, support points=4, support combos=4, refine top families=1, equation refit=false
- Synthesizer: family seeds=4, cross-family seeds=4, cross-family enabled=true, stitching=true, distance limit=0.500, max refined seeds=4, objective=`trajectory_only`

## Outcome Comparison

| Candidate | Fit Error | Param RMSE | Combined RMSE | Lineage |
|-----------|-----------|------------|---------------|---------|
| raw consensus winner | 1.8592e-05 | 6.88% | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| best synthesized refined result | 7.7038e-02 | 6.78% | 38.60% | method=direct_opt, source=synthesized, interp=aaad_gpr, polished=true |
| final selected winner | 1.8592e-05 | 6.88% | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Impact Summary

- Combined oracle RMSE: 5.46% → 5.46%
- Final winner came from: `raw`

## Parameter and IC Table

| Variable | Raw Rel Error | Final Rel Error | Delta |
|----------|---------------|-----------------|-------|
| `a01` | 0.21% | 0.21% | +0.00% |
| `a12` | 7.73% | 7.73% | +0.00% |
| `a13` | 0.99% | 0.99% | +0.00% |
| `a21` | 13.24% | 13.24% | +0.00% |
| `a31` | 0.93% | 0.93% | +0.00% |
| `x1(0)` | 0.02% | 0.02% | +0.00% |
| `x2(0)` | 0.01% | 0.01% | +0.00% |
| `x3(0)` | 1.38% | 1.38% | +0.00% |

## Synthesized Seeds

| Rank | Seed | Kind | Families | Source Candidates | Accepted | Pre-Score | Fit Loss | Equation Penalty | Nearest Raw Dist |
|------|------|------|----------|-------------------|----------|-----------|----------|------------------|------------------|
| 1 | 1 | `family_medoid_blend` | 1, 2 | 3, 2 | true | 4148.2092 | 7.7038e-02 | 2.2909e-01 | 0.1501 |

## Refined Synthesized Results

| Rank | Fit Error | Param RMSE | Combined RMSE | Lineage |
|------|-----------|------------|---------------|---------|
| 1 | 7.7038e-02 | 6.78% | 38.60% | method=direct_opt, source=synthesized, interp=aaad_gpr, polished=true |

## Raw Families

| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |
|------|------|--------------|--------|-------------|---------------|---------|------------------|
| 1 | 1 | 0.0000 | 3 | 3 | aaad_gpr | multipoint | 1, 275 |
| 2 | 1 | 0.2100 | 2 | 2 | aaad_gpr | single_point | 275 |
| 3 | 1 | 0.2500 | 1 | 1 | aaad_gpr | single_point | 1 |
| 4 | 1 | 0.5600 | 5 | 5 | aaad_gpr | single_point | 1 |
| 5 | 1 | 0.7200 | 4 | 4 | aaad_gpr | single_point | 1501 |

