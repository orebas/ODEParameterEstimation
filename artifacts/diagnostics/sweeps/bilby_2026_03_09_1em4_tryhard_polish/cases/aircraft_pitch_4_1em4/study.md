# Tryhard Polishing Benchmark Case: aircraft_pitch_4_1em4

- Model: `aircraft_pitch`
- Role: `guard`
- Selected via: `requested`
- Generated: `2026-04-12T14:58:18.916`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_4_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/aircraft_pitch_4_1em4`

## Comparison-Table Reference

- Classification: `b_only`
- Comparison CSV ODEPE mean/max relative error: 1.22% / 4.83%
- Comparison CSV ODEPE runtime: 648.208 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 117 | 12.82% | theta(0) (33.90%) | 4.5996e-09 |
| `odepe_polish` | 242 | 106.92% | theta(0) (282.88%) | 2.5399e-12 |

## Imported Raw Pool

- Raw imported candidates: 117
- Best raw fit index: 117
- Best raw oracle index: 88
- Best-fit vs best-truth combined-RMSE gap: 0.16%

## Local Tryhard Runtime

- Reference CSV load/scoring: 9.006 s
- Consensus/block context: 26.521 s
- 4x4 baseline evidence report: 3.997 s
- 4x4 block no-polish report: 9.295 s
- Polish context build: 0.007 s
- Polishing merged pool: 88.410 s
- Local total (excluding reference load): 128.230 s

## Local Comparison

| Strategy | Status | Combined RMSE | Worst Error | Fit Error | Notes |
|----------|--------|---------------|-------------|-----------|-------|
| `best imported raw` | `ok` | 12.82% | theta(0) (33.90%) | 4.5996e-09 | benchmark nopolish best-fit reference |
| `block_v2_no_polish_4x4` | `ok` | 104.53% | theta(0) (253.37%) | 1.5188e+03 | best block seed before polish |
| `tryhard_pooled_polish` | `ok` | 109.97% | theta(0) (290.95%) | 2.5399e-12 | 5 raw + 5 block distinct seeds, merged and polished |

## Outcome

- Benchmark `odepe_polish` vs tryhard: `benchmark_polish_better`
- Improvement mode: `no_improvement`
- Tryhard winner sources: `raw`
- Raw selected seeds: 5
- Block selected seeds: 5
- Merged distinct seeds: 10
- Successful polished seeds: 10

## Raw Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `raw` | 117 | 4.5996e-09 | method=algebraic, source=imported, candidate=117 |
| 2 | `raw` | 116 | 5.7051e-09 | method=algebraic, source=imported, candidate=116 |
| 3 | `raw` | 115 | 2.0044e-08 | method=algebraic, source=imported, candidate=115 |
| 4 | `raw` | 114 | 2.0669e-08 | method=algebraic, source=imported, candidate=114 |
| 5 | `raw` | 113 | 2.0857e-08 | method=algebraic, source=imported, candidate=113 |

## Block Seed Pool

| Rank | Source | Hypothesis Index | Block Score | Fit Error | Lineage |
|------|--------|------------------|-------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 1.5188e+03 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0000 | 1.5188e+03 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.0000 | 1.5188e+03 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.0000 | 1.5186e+03 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.0000 | 1.5186e+03 | method=direct_opt, source=assembled |

## Merged Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `raw` | `raw#117` | 4.5996e-09 | method=algebraic, source=imported, candidate=117 |
| 2 | `raw` | `raw#116` | 5.7051e-09 | method=algebraic, source=imported, candidate=116 |
| 3 | `raw` | `raw#115` | 2.0044e-08 | method=algebraic, source=imported, candidate=115 |
| 4 | `raw` | `raw#114` | 2.0669e-08 | method=algebraic, source=imported, candidate=114 |
| 5 | `raw` | `raw#113` | 2.0857e-08 | method=algebraic, source=imported, candidate=113 |
| 6 | `block` | `block#1` | 1.5188e+03 | method=direct_opt, source=assembled |
| 7 | `block` | `block#2` | 1.5188e+03 | method=direct_opt, source=assembled |
| 8 | `block` | `block#3` | 1.5188e+03 | method=direct_opt, source=assembled |
| 9 | `block` | `block#4` | 1.5186e+03 | method=direct_opt, source=assembled |
| 10 | `block` | `block#5` | 1.5186e+03 | method=direct_opt, source=assembled |

## Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `raw` | 4.5996e-09 | 2.5399e-12 | 12.81% | 86.435 | `` |
| 2 | `raw` | 5.7051e-09 | 2.5399e-12 | 109.96% | 0.294 | `` |
| 3 | `raw` | 2.0044e-08 | 2.5399e-12 | 124.32% | 0.097 | `` |
| 4 | `raw` | 2.0669e-08 | 2.5399e-12 | 109.97% | 0.142 | `` |
| 5 | `raw` | 2.0857e-08 | 2.5399e-12 | 74.27% | 0.090 | `` |
| 6 | `block` | 1.5188e+03 | 2.5399e-12 | 95.77% | 0.657 | `` |
| 7 | `block` | 1.5188e+03 | 2.5399e-12 | 124.33% | 0.273 | `` |
| 8 | `block` | 1.5188e+03 | 2.5399e-12 | 12.40% | 0.243 | `` |
| 9 | `block` | 1.5186e+03 | 2.5399e-12 | 12.40% | 0.089 | `` |
| 10 | `block` | 1.5186e+03 | 2.5399e-12 | 95.77% | 0.091 | `` |

