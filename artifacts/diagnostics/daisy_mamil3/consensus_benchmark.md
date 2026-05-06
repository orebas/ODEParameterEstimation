# Consensus Benchmark: daisy_mamil3

- Dataset: `benchmark_bilby_2026_03_09/daisy_mamil3_7_1em4`
- Generated: `2026-04-05T23:22:14.330`
- Shared raw candidate generation: 113.887 s
- Shared consensus context build: 9.540 s
- Shared total pre-selection time: 123.427 s
- Raw candidate count: 6
- Oracle note: Truth-based metrics in this artifact are benchmark-only evaluation metrics and were not used by the consensus selector.

## What's New

- The selector now compares one shared SP/MP raw candidate pool under three strategies: `best_fit_baseline`, `family_consensus`, and `family_consensus_refit`.
- `family_consensus` scores candidates with oracle-free evidence from fit, SP/MP kept and dropped equations, provenance support, and conditioning.
- `family_consensus_refit` can locally polish top families after consensus selection and keep the refined winner only when it rescored better.

## Run Configuration

- Interpolator: `InterpolatorAAADGPR` (resolved interpolator count: 1)
- Shooting points: 3
- Multipoint: enabled=true, points=2, max pairs=4
- Parameter homotopy: true
- Built-in polishing during raw generation: solver=false, final=false, maxiters=20, maxtime=5.0 s
- Consensus scoring support: points=4, combos=4, refine top families=1, equation refit=true

## Raw Pool Reference

| Selector | Candidate | Fit Error | Combined Oracle RMSE | Lineage |
|----------|-----------|-----------|----------------------|---------|
| Best raw fit | 3 | 1.8592e-05 | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |
| Best raw oracle | 3 | 1.8592e-05 | 5.46% | method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available |

## Strategy Comparison

| Strategy | Winner | Selection s | Effective Total s | Fit Error | Param RMSE | Combined RMSE | a31 Rel Err | Families |
|----------|--------|-------------|-------------------|-----------|------------|---------------|-------------|----------|
| `best_fit_baseline` | raw winner | 9.455 | 132.882 | 1.8592e-05 | 6.88% | 5.46% | 0.93% | 6 |
| `family_consensus` | raw winner | 1.670 | 125.097 | 1.8592e-05 | 6.88% | 5.46% | 0.93% | 6 |
| `family_consensus_refit` | refit kept raw winner | 99.264 | 222.691 | 1.8592e-05 | 6.88% | 5.46% | 0.93% | 6 |

## Impact Summary

- `best_fit_baseline` → `family_consensus`: combined oracle RMSE 5.46% → 5.46%; fit error 1.8592e-05 → 1.8592e-05.
- `family_consensus` → `family_consensus_refit`: combined oracle RMSE 5.46% → 5.46%; fit error 1.8592e-05 → 1.8592e-05.

## Strategy: `best_fit_baseline`

- Winner mode: raw winner
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Final fit error: 1.8592e-05
- Final composite score: 0.0200
- Support points: 1@0.000, 275@3.653, 1501@20.000
- Support combos: [1@0.000, 275@3.653]; [1@0.000, 1501@20.000]; [275@3.653, 1501@20.000]

### Final Winner Truth Table

| Variable | Estimate | Truth | Abs Error | Rel Error |
|----------|----------|-------|-----------|-----------|
| `a12` | 0.479801 | 0.520000 | 4.0199e-02 | 7.73% |
| `a13` | 0.693096 | 0.700000 | 6.9036e-03 | 0.99% |
| `a21` | 0.318405 | 0.367000 | 4.8595e-02 | 13.24% |
| `a31` | 0.846833 | 0.839000 | 7.8330e-03 | 0.93% |
| `a01` | 0.791674 | 0.790000 | 1.6739e-03 | 0.21% |
| `x1(0)` | 0.139022 | 0.139000 | 2.2083e-05 | 0.02% |
| `x2(0)` | 0.302972 | 0.303000 | 2.7845e-05 | 0.01% |
| `x3(0)` | 0.463325 | 0.457000 | 6.3246e-03 | 1.38% |

### Winner Evidence

| Metric | Value |
|--------|-------|
| Base fit error | 1.8592e-05 |
| SP kept residual | 6.0941e-02 |
| SP dropped residual | 2.9098e-01 |
| MP kept residual | 8.9988e-03 |
| MP dropped residual | 8.0750e-16 |
| Conditioning score | 4.0003e+05 |
| Composite score | 0.0200 |
| Score breakdown | fit=0.000, equation=0.000, support=0.000, trust=0.200 |
| Diversity tags | multipoint, aaad_gpr, shoot_1, mp_1, mp_275 |

### Top Families

| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |
|------|------|--------------|--------|-------------|---------------|---------|------------------|
| 1 | 1 | 0.0000 | 3 | 3 | aaad_gpr | multipoint | 1, 275 |
| 2 | 1 | 0.2100 | 2 | 2 | aaad_gpr | single_point | 275 |
| 3 | 1 | 0.2500 | 1 | 1 | aaad_gpr | single_point | 1 |
| 4 | 1 | 0.5600 | 5 | 5 | aaad_gpr | single_point | 1 |
| 5 | 1 | 0.7200 | 4 | 4 | aaad_gpr | single_point | 1501 |

## Strategy: `family_consensus`

- Winner mode: raw winner
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Final fit error: 1.8592e-05
- Final composite score: 0.0200
- Support points: 1@0.000, 275@3.653, 1501@20.000
- Support combos: [1@0.000, 275@3.653]; [1@0.000, 1501@20.000]; [275@3.653, 1501@20.000]

### Final Winner Truth Table

| Variable | Estimate | Truth | Abs Error | Rel Error |
|----------|----------|-------|-----------|-----------|
| `a12` | 0.479801 | 0.520000 | 4.0199e-02 | 7.73% |
| `a13` | 0.693096 | 0.700000 | 6.9036e-03 | 0.99% |
| `a21` | 0.318405 | 0.367000 | 4.8595e-02 | 13.24% |
| `a31` | 0.846833 | 0.839000 | 7.8330e-03 | 0.93% |
| `a01` | 0.791674 | 0.790000 | 1.6739e-03 | 0.21% |
| `x1(0)` | 0.139022 | 0.139000 | 2.2083e-05 | 0.02% |
| `x2(0)` | 0.302972 | 0.303000 | 2.7845e-05 | 0.01% |
| `x3(0)` | 0.463325 | 0.457000 | 6.3246e-03 | 1.38% |

### Winner Evidence

| Metric | Value |
|--------|-------|
| Base fit error | 1.8592e-05 |
| SP kept residual | 6.0941e-02 |
| SP dropped residual | 2.9098e-01 |
| MP kept residual | 8.9988e-03 |
| MP dropped residual | 8.0750e-16 |
| Conditioning score | 4.0003e+05 |
| Composite score | 0.0200 |
| Score breakdown | fit=0.000, equation=0.000, support=0.000, trust=0.200 |
| Diversity tags | multipoint, aaad_gpr, shoot_1, mp_1, mp_275 |

### Top Families

| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |
|------|------|--------------|--------|-------------|---------------|---------|------------------|
| 1 | 1 | 0.0000 | 3 | 3 | aaad_gpr | multipoint | 1, 275 |
| 2 | 1 | 0.2100 | 2 | 2 | aaad_gpr | single_point | 275 |
| 3 | 1 | 0.2500 | 1 | 1 | aaad_gpr | single_point | 1 |
| 4 | 1 | 0.5600 | 5 | 5 | aaad_gpr | single_point | 1 |
| 5 | 1 | 0.7200 | 4 | 4 | aaad_gpr | single_point | 1501 |

## Strategy: `family_consensus_refit`

- Winner mode: refit kept raw winner
- Final lineage: method=algebraic, source=multipoint, combo=3, mp_times=[1, 275], shoot=1, candidate=6, interp=aaad_gpr, template=determined, practical=advisory_available, advisory=available
- Final fit error: 1.8592e-05
- Final composite score: 0.0200
- Support points: 1@0.000, 275@3.653, 1501@20.000
- Support combos: [1@0.000, 275@3.653]; [1@0.000, 1501@20.000]; [275@3.653, 1501@20.000]

### Final Winner Truth Table

| Variable | Estimate | Truth | Abs Error | Rel Error |
|----------|----------|-------|-----------|-----------|
| `a12` | 0.479801 | 0.520000 | 4.0199e-02 | 7.73% |
| `a13` | 0.693096 | 0.700000 | 6.9036e-03 | 0.99% |
| `a21` | 0.318405 | 0.367000 | 4.8595e-02 | 13.24% |
| `a31` | 0.846833 | 0.839000 | 7.8330e-03 | 0.93% |
| `a01` | 0.791674 | 0.790000 | 1.6739e-03 | 0.21% |
| `x1(0)` | 0.139022 | 0.139000 | 2.2083e-05 | 0.02% |
| `x2(0)` | 0.302972 | 0.303000 | 2.7845e-05 | 0.01% |
| `x3(0)` | 0.463325 | 0.457000 | 6.3246e-03 | 1.38% |

### Winner Evidence

| Metric | Value |
|--------|-------|
| Base fit error | 1.8592e-05 |
| SP kept residual | 6.0941e-02 |
| SP dropped residual | 2.9098e-01 |
| MP kept residual | 8.9988e-03 |
| MP dropped residual | 8.0750e-16 |
| Conditioning score | 4.0003e+05 |
| Composite score | 0.0200 |
| Score breakdown | fit=0.000, equation=0.000, support=0.000, trust=0.200 |
| Diversity tags | multipoint, aaad_gpr, shoot_1, mp_1, mp_275 |

### Top Families

| Rank | Size | Family Score | Medoid | Best Member | Interpolators | Sources | Shooting Support |
|------|------|--------------|--------|-------------|---------------|---------|------------------|
| 1 | 1 | 0.0000 | 3 | 3 | aaad_gpr | multipoint | 1, 275 |
| 2 | 1 | 0.2100 | 2 | 2 | aaad_gpr | single_point | 275 |
| 3 | 1 | 0.2500 | 1 | 1 | aaad_gpr | single_point | 1 |
| 4 | 1 | 0.5600 | 5 | 5 | aaad_gpr | single_point | 1 |
| 5 | 1 | 0.7200 | 4 | 4 | aaad_gpr | single_point | 1501 |

