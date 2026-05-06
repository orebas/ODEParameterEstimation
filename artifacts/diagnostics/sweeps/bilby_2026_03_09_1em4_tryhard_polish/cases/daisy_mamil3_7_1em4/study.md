# Tryhard Finalist Benchmark Case: daisy_mamil3_7_1em4

- Model: `daisy_mamil3`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T09:50:30.693`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil3_7_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/daisy_mamil3_7_1em4`

## Comparison-Table Reference

- Classification: `a_only`
- Comparison CSV ODEPE mean/max relative error: 100.00% / Inf
- Comparison CSV ODEPE runtime: 32.647 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 89 | 5.73% | a31 (11.11%) | 7.6048e-04 |
| `odepe_polish` | 224 | 0.52% | a31 (1.22%) | 6.4622e-07 |

## Imported Raw Pool

- Raw imported candidates: 89
- Best raw fit index: 89
- Best raw oracle index: 89
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.402 s
- Consensus/block context: 14.619 s
- 4x4 baseline evidence report: 17.556 s
- 4x4 block no-polish report: 12.173 s
- Polish context build: 0.006 s
- Baseline-only finalists: 361.957 s
- Additive-only finalists: 420.031 s
- Reasonable frontier finalists: 413.569 s
- Local total (excluding reference load): 1486.921 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 5.73% | 5.73% | 89 | `raw` | 7.6048e-04 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 0.52% | 0.52% | 224 | `benchmark` | 6.4622e-07 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 8.25% | 8.25% | 108 | `block` | 1.5060e-02 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.01% | 0.01% | 34 | `baseline` | 3.4696e-07 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.01% | 0.01% | 51 | `block+branch+synthesized` | 3.4696e-07 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.01% | 0.01% | 43 | `baseline+block+branch+synthesized` | 3.4696e-07 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 1 / 0.01%
- Additive best finalist index / RMSE: 1 / 0.01%
- Frontier best finalist index / RMSE: 1 / 0.01%
- Baseline preserved seeds: 89
- Additive candidate seeds: 108
- Frontier admitted seeds: 103
- Rejected additive seeds: 94
- Successful merged polished seeds: 103
- Returned merged finalists: 43

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 1.8710e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 6.9253e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 1.2694e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 2.6518e+04 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 5.0446e+03 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 3.9861e+03 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 1.0081e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.0471e+02 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 1.7014e+02 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 7.9928e+01 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 2.5469e+01 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 1.6799e+01 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 1.2394e+01 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 1.0881e+01 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 1.1097e+01 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 1.0759e+01 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 1.0473e+01 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 1.0397e+01 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 1.0383e+01 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 9.6866e+00 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 9.6416e+00 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 8.6466e+00 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 9.6463e+00 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 9.1197e+00 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 6.4062e+00 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 5.2551e+00 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 7.3257e+00 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 9.1235e+00 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 5.1143e+00 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 4.3795e+00 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 4.6364e+00 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 3.1449e+00 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | Inf | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 1.8715e+00 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 1.8684e+00 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 1.8072e+00 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 1.8014e+00 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 1.8024e+00 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 2.0773e+00 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 1.7475e+00 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 1.6948e+00 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 1.6514e+00 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 1.5756e+00 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 1.4632e+00 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 1.4633e+00 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 1.3945e+00 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 1.3522e+00 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 1.3483e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 1.9179e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 1.3207e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 1.3540e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | 1.1337e+00 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | 1.1571e+00 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 1.0142e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 1.0320e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 6.2583e-01 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 4.8283e-01 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 4.7173e-01 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 4.7327e-01 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 4.6751e-01 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 3.8332e-01 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 3.7838e-01 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 2.8807e-01 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 2.5645e-01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 4.0265e-01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 8.7737e-02 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 7.9049e-02 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 7.6512e-02 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 6.1306e-02 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 7.1494e-02 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 5.4497e-02 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 73 | 6.8021e-02 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | 74 | 4.4796e-02 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | 75 | 4.9380e-02 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | 76 | 1.8715e-02 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | 77 | 1.5455e-02 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | 78 | 1.5311e-02 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | 79 | 1.1229e-02 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | 80 | 6.6804e-03 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | 81 | 4.8417e-03 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | 82 | 2.8330e-03 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | 83 | 2.7086e-03 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | 84 | 2.7160e-03 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | 85 | 2.0579e-03 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | 86 | 1.6748e-03 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | 87 | 1.2806e-03 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | 88 | 9.9091e-04 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | 89 | 7.6048e-04 | method=algebraic, source=imported, candidate=89 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 1.5060e-02 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0785 | 3.9106e+00 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.1361 | 6.5835e+00 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.1564 | 1.0012e+01 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.5417 | 2.1648e+04 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.6153 | 1.0893e+05 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.7456 | 6.8574e+05 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.7671 | 1.2376e+06 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.7770 | 1.4814e+06 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.7869 | 1.3852e+06 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.8214 | 6.0899e+05 | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.8682 | 1.6055e+06 | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.9238 | Inf | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.9238 | Inf | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 0.9241 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 0.9241 | Inf | method=direct_opt, source=assembled |
| 17 | `block` | 17 | 0.9909 | Inf | method=direct_opt, source=assembled |
| 18 | `block` | 18 | 0.9909 | Inf | method=direct_opt, source=assembled |
| 19 | `block` | 19 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 20 | `block` | 20 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 1 | `branch` | 1 | 0.6738 | 2.3559e-03 | method=direct_opt, source=synthesized, candidate=81, polished=true |
| 1 | `branch+synthesized` | 1 | 0.0000 | 3.4696e-07 | method=direct_opt, source=synthesized, polished=true |
| 4 | `branch` | 4 | 0.6640 | 2.0579e-03 | method=algebraic, source=imported, candidate=85 |
| 5 | `branch` | 5 | 0.6633 | 2.7160e-03 | method=algebraic, source=imported, candidate=84 |
| 6 | `branch` | 6 | 0.6632 | 7.6048e-04 | method=algebraic, source=imported, candidate=89 |
| 7 | `branch` | 7 | 0.6557 | 1.2806e-03 | method=algebraic, source=imported, candidate=87 |
| 8 | `branch` | 8 | 0.6519 | 1.6748e-03 | method=algebraic, source=imported, candidate=86 |
| 9 | `branch` | 9 | 0.6496 | 2.8330e-03 | method=algebraic, source=imported, candidate=82 |
| 10 | `branch` | 10 | 0.6480 | 6.1306e-02 | method=algebraic, source=imported, candidate=70 |
| 11 | `branch` | 11 | 0.6478 | 7.1494e-02 | method=algebraic, source=imported, candidate=71 |
| 12 | `branch` | 12 | 0.6433 | 2.7086e-03 | method=algebraic, source=imported, candidate=83 |
| 13 | `branch` | 13 | 0.6368 | 1.8715e-02 | method=algebraic, source=imported, candidate=76 |
| 14 | `branch` | 14 | 0.6261 | 7.6512e-02 | method=algebraic, source=imported, candidate=69 |
| 15 | `branch` | 15 | 0.6183 | 8.7737e-02 | method=algebraic, source=imported, candidate=67 |
| 16 | `branch` | 16 | 0.6177 | 2.5645e-01 | method=algebraic, source=imported, candidate=65 |
| 17 | `branch` | 17 | 0.6120 | 1.1229e-02 | method=algebraic, source=imported, candidate=79 |
| 18 | `branch` | 18 | 0.6023 | 5.4497e-02 | method=algebraic, source=imported, candidate=72 |
| 19 | `branch` | 19 | 0.5997 | 4.9380e-02 | method=algebraic, source=imported, candidate=75 |
| 20 | `branch` | 20 | 0.5957 | 4.8283e-01 | method=algebraic, source=imported, candidate=58 |
| 21 | `branch` | 21 | 0.5914 | 4.0265e-01 | method=algebraic, source=imported, candidate=66 |
| 22 | `branch` | 22 | 0.5904 | 1.0142e+00 | method=algebraic, source=imported, candidate=55 |
| 23 | `branch` | 23 | 0.5871 | 6.2583e-01 | method=algebraic, source=imported, candidate=57 |
| 24 | `branch` | 24 | 0.5862 | 3.8332e-01 | method=algebraic, source=imported, candidate=62 |
| 25 | `branch` | 25 | 0.5805 | 1.1571e+00 | method=algebraic, source=imported, candidate=54 |
| 26 | `branch` | 26 | 0.5754 | 2.8807e-01 | method=algebraic, source=imported, candidate=64 |
| 27 | `branch` | 27 | 0.5686 | 7.9049e-02 | method=algebraic, source=imported, candidate=68 |
| 28 | `branch` | 28 | 0.5669 | 1.5455e-02 | method=algebraic, source=imported, candidate=77 |
| 29 | `branch` | 29 | 0.5653 | 1.3540e+00 | method=algebraic, source=imported, candidate=52 |
| 30 | `branch` | 30 | 0.5653 | 1.5311e-02 | method=algebraic, source=imported, candidate=78 |
| 31 | `branch` | 31 | 0.5587 | 3.7838e-01 | method=algebraic, source=imported, candidate=63 |
| 32 | `branch` | 32 | 0.5304 | 4.4796e-02 | method=algebraic, source=imported, candidate=74 |
| 33 | `branch` | 33 | 0.5215 | 2.0773e+00 | method=algebraic, source=imported, candidate=40 |
| 34 | `branch` | 34 | 0.5180 | 4.6751e-01 | method=algebraic, source=imported, candidate=61 |
| 35 | `branch` | 35 | 0.5173 | 4.7327e-01 | method=algebraic, source=imported, candidate=60 |
| 36 | `branch` | 36 | 0.5127 | 6.8021e-02 | method=algebraic, source=imported, candidate=73 |
| 37 | `branch` | 37 | 0.5059 | 3.1449e+00 | method=algebraic, source=imported, candidate=33 |
| 38 | `branch` | 38 | 0.4995 | 4.7173e-01 | method=algebraic, source=imported, candidate=59 |
| 39 | `branch` | 39 | 0.4977 | 1.9179e+00 | method=algebraic, source=imported, candidate=50 |
| 40 | `branch` | 40 | 0.4918 | 1.0320e+00 | method=algebraic, source=imported, candidate=56 |
| 41 | `branch` | 41 | 0.4782 | 9.6416e+00 | method=algebraic, source=imported, candidate=22 |
| 42 | `branch` | 42 | 0.4721 | 8.6466e+00 | method=algebraic, source=imported, candidate=23 |
| 43 | `branch` | 43 | 0.4611 | 9.6866e+00 | method=algebraic, source=imported, candidate=21 |
| 44 | `branch` | 44 | 0.4587 | 1.2394e+01 | method=algebraic, source=imported, candidate=14 |
| 45 | `branch` | 45 | 0.4476 | 2.0471e+02 | method=algebraic, source=imported, candidate=8 |
| 46 | `branch` | 46 | 0.4443 | 1.0383e+01 | method=algebraic, source=imported, candidate=20 |
| 47 | `branch` | 47 | 0.4422 | 7.3257e+00 | method=algebraic, source=imported, candidate=28 |
| 48 | `branch` | 48 | 0.4418 | 6.4062e+00 | method=algebraic, source=imported, candidate=26 |
| 49 | `branch` | 49 | 0.4372 | 1.0397e+01 | method=algebraic, source=imported, candidate=19 |
| 50 | `branch` | 50 | 0.4333 | 7.9928e+01 | method=algebraic, source=imported, candidate=10 |
| 51 | `branch` | 51 | 0.4319 | 1.0473e+01 | method=algebraic, source=imported, candidate=18 |
| 52 | `branch` | 52 | 0.4199 | 5.2551e+00 | method=algebraic, source=imported, candidate=27 |
| 53 | `branch` | 53 | 0.4185 | 1.3207e+00 | method=algebraic, source=imported, candidate=51 |
| 54 | `branch` | 54 | 0.4184 | 1.0759e+01 | method=algebraic, source=imported, candidate=17 |
| 55 | `branch` | 55 | 0.4141 | 1.1337e+00 | method=algebraic, source=imported, candidate=53 |
| 56 | `branch` | 56 | 0.4137 | 1.3483e+00 | method=algebraic, source=imported, candidate=49 |
| 57 | `branch` | 57 | 0.4128 | 1.1097e+01 | method=algebraic, source=imported, candidate=16 |
| 58 | `branch` | 58 | 0.4098 | 2.5469e+01 | method=algebraic, source=imported, candidate=12 |
| 59 | `branch` | 59 | 0.4080 | 1.5756e+00 | method=algebraic, source=imported, candidate=44 |
| 60 | `branch` | 60 | 0.4068 | 1.3522e+00 | method=algebraic, source=imported, candidate=48 |
| 61 | `branch` | 61 | 0.4007 | 1.3945e+00 | method=algebraic, source=imported, candidate=47 |
| 62 | `branch` | 62 | 0.3978 | 1.4632e+00 | method=algebraic, source=imported, candidate=45 |
| 63 | `branch` | 63 | 0.3929 | 1.8024e+00 | method=algebraic, source=imported, candidate=39 |
| 64 | `branch` | 64 | 0.3907 | 1.8014e+00 | method=algebraic, source=imported, candidate=38 |
| 65 | `branch` | 65 | 0.3897 | 1.4633e+00 | method=algebraic, source=imported, candidate=46 |
| 66 | `branch` | 66 | 0.3893 | 1.6514e+00 | method=algebraic, source=imported, candidate=43 |
| 67 | `branch` | 67 | 0.3833 | 9.1235e+00 | method=algebraic, source=imported, candidate=29 |
| 68 | `branch` | 68 | 0.3807 | 1.0881e+01 | method=algebraic, source=imported, candidate=15 |
| 69 | `branch` | 69 | 0.3807 | 1.6948e+00 | method=algebraic, source=imported, candidate=42 |
| 70 | `branch` | 70 | 0.3797 | 1.8072e+00 | method=algebraic, source=imported, candidate=37 |
| 71 | `branch` | 71 | 0.3792 | 1.0081e+03 | method=algebraic, source=imported, candidate=7 |
| 72 | `branch` | 72 | 0.3722 | 1.8684e+00 | method=algebraic, source=imported, candidate=36 |
| 73 | `branch` | 73 | 0.3652 | 4.3795e+00 | method=algebraic, source=imported, candidate=31 |
| 74 | `branch` | 74 | 0.3620 | 1.8715e+00 | method=algebraic, source=imported, candidate=35 |
| 75 | `branch` | 75 | 0.3581 | 1.7475e+00 | method=algebraic, source=imported, candidate=41 |
| 76 | `branch` | 76 | 0.3559 | 5.0446e+03 | method=algebraic, source=imported, candidate=5 |
| 77 | `branch` | 77 | 0.3522 | 4.6364e+00 | method=algebraic, source=imported, candidate=32 |
| 78 | `branch` | 78 | 0.3415 | 9.1197e+00 | method=algebraic, source=imported, candidate=25 |
| 79 | `branch` | 79 | 0.3374 | 1.2694e+05 | method=algebraic, source=imported, candidate=3 |
| 80 | `branch` | 80 | 0.3372 | 1.6799e+01 | method=algebraic, source=imported, candidate=13 |
| 81 | `branch` | 81 | 0.3276 | 3.9861e+03 | method=algebraic, source=imported, candidate=6 |
| 82 | `branch` | 82 | 0.3252 | 1.7014e+02 | method=algebraic, source=imported, candidate=9 |
| 83 | `branch` | 83 | 0.3113 | 5.1143e+00 | method=algebraic, source=imported, candidate=30 |
| 84 | `branch` | 84 | 0.3068 | 2.6518e+04 | method=algebraic, source=imported, candidate=4 |
| 85 | `branch` | 85 | 0.3034 | 1.8710e+06 | method=algebraic, source=imported, candidate=1 |
| 86 | `branch` | 86 | 0.2996 | 6.9253e+05 | method=algebraic, source=imported, candidate=2 |
| 87 | `branch` | 87 | 0.2923 | 9.6463e+00 | method=algebraic, source=imported, candidate=24 |
| 88 | `branch` | 88 | 0.2624 | Inf | method=algebraic, source=imported, candidate=11 |
| 89 | `branch` | 89 | 0.2403 | Inf | method=algebraic, source=imported, candidate=34 |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `branch` | `duplicate` | 2.0579e-03 | method=algebraic, source=imported, candidate=85 |
| 2 | `branch` | `duplicate` | 2.7160e-03 | method=algebraic, source=imported, candidate=84 |
| 3 | `branch` | `duplicate` | 7.6048e-04 | method=algebraic, source=imported, candidate=89 |
| 4 | `branch` | `duplicate` | 1.2806e-03 | method=algebraic, source=imported, candidate=87 |
| 5 | `branch` | `duplicate` | 1.6748e-03 | method=algebraic, source=imported, candidate=86 |
| 6 | `branch` | `duplicate` | 2.8330e-03 | method=algebraic, source=imported, candidate=82 |
| 7 | `branch` | `duplicate` | 6.1306e-02 | method=algebraic, source=imported, candidate=70 |
| 8 | `branch` | `duplicate` | 7.1494e-02 | method=algebraic, source=imported, candidate=71 |
| 9 | `branch` | `duplicate` | 2.7086e-03 | method=algebraic, source=imported, candidate=83 |
| 10 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 11 | `branch` | `duplicate` | 1.8715e-02 | method=algebraic, source=imported, candidate=76 |
| 12 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 13 | `branch` | `duplicate` | 7.6512e-02 | method=algebraic, source=imported, candidate=69 |
| 14 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 15 | `branch` | `duplicate` | 8.7737e-02 | method=algebraic, source=imported, candidate=67 |
| 16 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 17 | `branch` | `duplicate` | 2.5645e-01 | method=algebraic, source=imported, candidate=65 |
| 18 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 19 | `branch` | `duplicate` | 1.1229e-02 | method=algebraic, source=imported, candidate=79 |
| 20 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 21 | `branch` | `duplicate` | 5.4497e-02 | method=algebraic, source=imported, candidate=72 |
| 22 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 23 | `branch` | `duplicate` | 4.9380e-02 | method=algebraic, source=imported, candidate=75 |
| 24 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 25 | `branch` | `duplicate` | 4.8283e-01 | method=algebraic, source=imported, candidate=58 |
| 26 | `branch` | `duplicate` | 4.0265e-01 | method=algebraic, source=imported, candidate=66 |
| 27 | `branch` | `duplicate` | 1.0142e+00 | method=algebraic, source=imported, candidate=55 |
| 28 | `branch` | `duplicate` | 6.2583e-01 | method=algebraic, source=imported, candidate=57 |
| 29 | `branch` | `duplicate` | 3.8332e-01 | method=algebraic, source=imported, candidate=62 |
| 30 | `branch` | `duplicate` | 1.1571e+00 | method=algebraic, source=imported, candidate=54 |
| 31 | `branch` | `duplicate` | 2.8807e-01 | method=algebraic, source=imported, candidate=64 |
| 32 | `branch` | `duplicate` | 7.9049e-02 | method=algebraic, source=imported, candidate=68 |
| 33 | `branch` | `duplicate` | 1.5455e-02 | method=algebraic, source=imported, candidate=77 |
| 34 | `branch` | `duplicate` | 1.3540e+00 | method=algebraic, source=imported, candidate=52 |
| 35 | `branch` | `duplicate` | 1.5311e-02 | method=algebraic, source=imported, candidate=78 |
| 36 | `branch` | `duplicate` | 3.7838e-01 | method=algebraic, source=imported, candidate=63 |
| 37 | `branch` | `duplicate` | 4.4796e-02 | method=algebraic, source=imported, candidate=74 |
| 38 | `branch` | `duplicate` | 2.0773e+00 | method=algebraic, source=imported, candidate=40 |
| 39 | `branch` | `duplicate` | 4.6751e-01 | method=algebraic, source=imported, candidate=61 |
| 40 | `branch` | `duplicate` | 4.7327e-01 | method=algebraic, source=imported, candidate=60 |
| 41 | `branch` | `duplicate` | 6.8021e-02 | method=algebraic, source=imported, candidate=73 |
| 42 | `branch` | `duplicate` | 3.1449e+00 | method=algebraic, source=imported, candidate=33 |
| 43 | `branch` | `duplicate` | 4.7173e-01 | method=algebraic, source=imported, candidate=59 |
| 44 | `branch` | `duplicate` | 1.9179e+00 | method=algebraic, source=imported, candidate=50 |
| 45 | `branch` | `duplicate` | 1.0320e+00 | method=algebraic, source=imported, candidate=56 |
| 46 | `branch` | `duplicate` | 9.6416e+00 | method=algebraic, source=imported, candidate=22 |
| 47 | `branch` | `duplicate` | 8.6466e+00 | method=algebraic, source=imported, candidate=23 |
| 48 | `branch` | `duplicate` | 9.6866e+00 | method=algebraic, source=imported, candidate=21 |
| 49 | `branch` | `duplicate` | 1.2394e+01 | method=algebraic, source=imported, candidate=14 |
| 50 | `branch` | `duplicate` | 2.0471e+02 | method=algebraic, source=imported, candidate=8 |
| 51 | `branch` | `duplicate` | 1.0383e+01 | method=algebraic, source=imported, candidate=20 |
| 52 | `branch` | `duplicate` | 7.3257e+00 | method=algebraic, source=imported, candidate=28 |
| 53 | `branch` | `duplicate` | 6.4062e+00 | method=algebraic, source=imported, candidate=26 |
| 54 | `branch` | `duplicate` | 1.0397e+01 | method=algebraic, source=imported, candidate=19 |
| 55 | `branch` | `duplicate` | 7.9928e+01 | method=algebraic, source=imported, candidate=10 |
| 56 | `branch` | `duplicate` | 1.0473e+01 | method=algebraic, source=imported, candidate=18 |
| 57 | `branch` | `duplicate` | 5.2551e+00 | method=algebraic, source=imported, candidate=27 |
| 58 | `branch` | `duplicate` | 1.3207e+00 | method=algebraic, source=imported, candidate=51 |
| 59 | `branch` | `duplicate` | 1.0759e+01 | method=algebraic, source=imported, candidate=17 |
| 60 | `branch` | `duplicate` | 1.1337e+00 | method=algebraic, source=imported, candidate=53 |
| 61 | `branch` | `duplicate` | 1.3483e+00 | method=algebraic, source=imported, candidate=49 |
| 62 | `branch` | `duplicate` | 1.1097e+01 | method=algebraic, source=imported, candidate=16 |
| 63 | `branch` | `duplicate` | 2.5469e+01 | method=algebraic, source=imported, candidate=12 |
| 64 | `branch` | `duplicate` | 1.5756e+00 | method=algebraic, source=imported, candidate=44 |
| 65 | `branch` | `duplicate` | 1.3522e+00 | method=algebraic, source=imported, candidate=48 |
| 66 | `branch` | `duplicate` | 1.3945e+00 | method=algebraic, source=imported, candidate=47 |
| 67 | `branch` | `duplicate` | 1.4632e+00 | method=algebraic, source=imported, candidate=45 |
| 68 | `branch` | `duplicate` | 1.8024e+00 | method=algebraic, source=imported, candidate=39 |
| 69 | `branch` | `duplicate` | 1.8014e+00 | method=algebraic, source=imported, candidate=38 |
| 70 | `branch` | `duplicate` | 1.4633e+00 | method=algebraic, source=imported, candidate=46 |
| 71 | `branch` | `duplicate` | 1.6514e+00 | method=algebraic, source=imported, candidate=43 |
| 72 | `branch` | `duplicate` | 9.1235e+00 | method=algebraic, source=imported, candidate=29 |
| 73 | `branch` | `duplicate` | 1.0881e+01 | method=algebraic, source=imported, candidate=15 |
| 74 | `branch` | `duplicate` | 1.6948e+00 | method=algebraic, source=imported, candidate=42 |
| 75 | `branch` | `duplicate` | 1.8072e+00 | method=algebraic, source=imported, candidate=37 |
| 76 | `branch` | `duplicate` | 1.0081e+03 | method=algebraic, source=imported, candidate=7 |
| 77 | `branch` | `duplicate` | 1.8684e+00 | method=algebraic, source=imported, candidate=36 |
| 78 | `branch` | `duplicate` | 4.3795e+00 | method=algebraic, source=imported, candidate=31 |
| 79 | `branch` | `duplicate` | 1.8715e+00 | method=algebraic, source=imported, candidate=35 |
| 80 | `branch` | `duplicate` | 1.7475e+00 | method=algebraic, source=imported, candidate=41 |
| 81 | `branch` | `duplicate` | 5.0446e+03 | method=algebraic, source=imported, candidate=5 |
| 82 | `branch` | `duplicate` | 4.6364e+00 | method=algebraic, source=imported, candidate=32 |
| 83 | `branch` | `duplicate` | 9.1197e+00 | method=algebraic, source=imported, candidate=25 |
| 84 | `branch` | `duplicate` | 1.2694e+05 | method=algebraic, source=imported, candidate=3 |
| 85 | `branch` | `duplicate` | 1.6799e+01 | method=algebraic, source=imported, candidate=13 |
| 86 | `branch` | `duplicate` | 3.9861e+03 | method=algebraic, source=imported, candidate=6 |
| 87 | `branch` | `duplicate` | 1.7014e+02 | method=algebraic, source=imported, candidate=9 |
| 88 | `branch` | `duplicate` | 5.1143e+00 | method=algebraic, source=imported, candidate=30 |
| 89 | `branch` | `duplicate` | 2.6518e+04 | method=algebraic, source=imported, candidate=4 |
| 90 | `branch` | `duplicate` | 1.8710e+06 | method=algebraic, source=imported, candidate=1 |
| 91 | `branch` | `duplicate` | 6.9253e+05 | method=algebraic, source=imported, candidate=2 |
| 92 | `branch` | `duplicate` | 9.6463e+00 | method=algebraic, source=imported, candidate=24 |
| 93 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=11 |
| 94 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=34 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 1.8710e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 6.9253e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 1.2694e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 2.6518e+04 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 5.0446e+03 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 3.9861e+03 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 1.0081e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.0471e+02 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 1.7014e+02 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 7.9928e+01 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 2.5469e+01 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 1.6799e+01 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 1.2394e+01 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 1.0881e+01 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 1.1097e+01 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 1.0759e+01 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 1.0473e+01 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 1.0397e+01 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 1.0383e+01 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 9.6866e+00 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 9.6416e+00 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 8.6466e+00 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 9.6463e+00 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 9.1197e+00 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 6.4062e+00 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 5.2551e+00 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 7.3257e+00 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 9.1235e+00 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 5.1143e+00 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 4.3795e+00 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 4.6364e+00 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 3.1449e+00 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | Inf | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 1.8715e+00 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 1.8684e+00 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 1.8072e+00 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 1.8014e+00 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 1.8024e+00 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 2.0773e+00 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 1.7475e+00 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 1.6948e+00 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 1.6514e+00 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 1.5756e+00 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 1.4632e+00 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 1.4633e+00 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 1.3945e+00 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 1.3522e+00 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 1.3483e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 1.9179e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 1.3207e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 1.3540e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | 1.1337e+00 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | 1.1571e+00 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 1.0142e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 1.0320e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 6.2583e-01 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 4.8283e-01 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 4.7173e-01 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 4.7327e-01 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 4.6751e-01 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 3.8332e-01 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 3.7838e-01 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 2.8807e-01 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 2.5645e-01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 4.0265e-01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 8.7737e-02 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 7.9049e-02 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 7.6512e-02 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 6.1306e-02 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 7.1494e-02 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 5.4497e-02 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#73` | 6.8021e-02 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | `baseline#74` | 4.4796e-02 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | `baseline#75` | 4.9380e-02 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | `baseline#76` | 1.8715e-02 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | `baseline#77` | 1.5455e-02 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | `baseline#78` | 1.5311e-02 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | `baseline#79` | 1.1229e-02 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | `baseline#80` | 6.6804e-03 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | `baseline#81` | 4.8417e-03 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | `baseline#82` | 2.8330e-03 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | `baseline#83` | 2.7086e-03 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | `baseline#84` | 2.7160e-03 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | `baseline#85` | 2.0579e-03 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | `baseline#86` | 1.6748e-03 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | `baseline#87` | 1.2806e-03 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | `baseline#88` | 9.9091e-04 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | `baseline#89` | 7.6048e-04 | method=algebraic, source=imported, candidate=89 |
| 90 | `branch+synthesized` | `branch#2, branch#3, synthesized#1, synthesized#2, synthesized#3, synthesized#4` | 3.4696e-07 | method=direct_opt, source=synthesized, polished=true |
| 91 | `block` | `block#1` | 1.5060e-02 | method=direct_opt, source=assembled |
| 92 | `branch` | `branch#1` | 2.3559e-03 | method=direct_opt, source=synthesized, candidate=81, polished=true |
| 93 | `block` | `block#2` | 3.9106e+00 | method=direct_opt, source=assembled |
| 94 | `block` | `block#3` | 6.5835e+00 | method=direct_opt, source=assembled |
| 95 | `block` | `block#4` | 1.0012e+01 | method=direct_opt, source=assembled |
| 96 | `block` | `block#5` | 2.1648e+04 | method=direct_opt, source=assembled |
| 97 | `block` | `block#6` | 1.0893e+05 | method=direct_opt, source=assembled |
| 98 | `block` | `block#7` | 6.8574e+05 | method=direct_opt, source=assembled |
| 99 | `block` | `block#8` | 1.2376e+06 | method=direct_opt, source=assembled |
| 100 | `block` | `block#9` | 1.4814e+06 | method=direct_opt, source=assembled |
| 101 | `block` | `block#10` | 1.3852e+06 | method=direct_opt, source=assembled |
| 102 | `block` | `block#11` | 6.0899e+05 | method=direct_opt, source=assembled |
| 103 | `block` | `block#12` | 1.6055e+06 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 60 | 3.4696e-07 | 0.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=72, polished=true |
| 2 | `baseline` | 2 | 9.2360e-03 | 983.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 3 | `block` | 1 | 5.4327e-04 | 18.57% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 4 | `baseline` | 1 | 3.3412e-03 | 83.27% | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |
| 5 | `block` | 1 | 7.7725e-03 | 4629.05% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 6 | `block` | 1 | 7.7910e-03 | 5064.84% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 7 | `block` | 1 | 7.8010e-03 | 5351.57% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 8 | `baseline` | 1 | 8.6607e-03 | 1681.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=22, polished=true |
| 9 | `baseline` | 1 | 8.8028e-03 | 1432.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 10 | `baseline` | 1 | 2.1600e-02 | 1143.14% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 11 | `baseline` | 1 | 2.3712e-02 | 1845.68% | 0 | 0.5000 | method=algebraic, source=imported, candidate=18, polished=true |
| 12 | `baseline` | 1 | 2.5972e-02 | 4725.79% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 13 | `baseline` | 1 | 2.5976e-02 | 4766.50% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 14 | `baseline` | 1 | 2.5988e-02 | 5431.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 15 | `baseline` | 1 | 2.6039e-02 | 5233.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=25, polished=true |
| 16 | `baseline` | 1 | 2.6407e-02 | 9163.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 17 | `baseline` | 1 | 2.6417e-02 | 7638.96% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 18 | `baseline` | 1 | 2.6439e-02 | 10306.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=31, polished=true |
| 19 | `baseline` | 1 | 2.6460e-02 | 25699.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 20 | `baseline` | 1 | 2.6463e-02 | 19828.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=36, polished=true |
| 21 | `baseline` | 1 | 2.6712e-02 | 30512.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 22 | `baseline` | 1 | 2.7091e-02 | 38063.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 23 | `baseline` | 1 | 2.7101e-02 | 36013.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 24 | `baseline` | 1 | 2.7183e-02 | 34572.74% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 25 | `baseline` | 1 | 2.7557e-02 | 39506.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=41, polished=true |
| 26 | `baseline` | 1 | 4.3350e-02 | 111.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=56, polished=true |
| 27 | `baseline` | 1 | 4.4634e-02 | 130.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=73, polished=true |
| 28 | `block` | 1 | 1.1247e-01 | 197.61% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 29 | `block` | 1 | 1.6283e-01 | 423.35% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 30 | `baseline` | 1 | 1.6360e-01 | 511.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 31 | `baseline` | 1 | 1.9005e-01 | 1703.04% | 0 | 0.5000 | method=algebraic, source=imported, candidate=29, polished=true |
| 32 | `baseline` | 1 | 2.9027e-01 | 263.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 33 | `block` | 1 | 3.5327e+00 | 4520.07% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 34 | `baseline` | 1 | 5.1143e+00 | 55473.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=30, polished=true |
| 35 | `block` | 1 | 9.6155e+00 | 4108.14% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 36 | `baseline` | 1 | 9.6463e+00 | 1318252.10% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 37 | `baseline` | 1 | 1.0081e+03 | 621.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 38 | `baseline` | 1 | 1.8962e+03 | 22099.21% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 39 | `block` | 1 | 2.9647e+03 | 27617.35% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 40 | `baseline` | 1 | 4.8393e+03 | 31491.96% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 41 | `baseline` | 1 | 1.8710e+06 | 100883.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 42 | `baseline` | 1 | Inf | 2023923.74% | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 43 | `baseline` | 1 | Inf | 2394360.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=34, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 1.8710e+06 | 1.8710e+06 | 100883.25% | 5.138 | `` |
| 2 | `baseline` | 6.9253e+05 | 1.8962e+03 | 22099.21% | 3.781 | `` |
| 3 | `baseline` | 1.2694e+05 | 4.8393e+03 | 31491.96% | 4.450 | `` |
| 4 | `baseline` | 2.6518e+04 | 3.4696e-07 | 0.01% | 2.370 | `` |
| 5 | `baseline` | 5.0446e+03 | 9.2360e-03 | 983.44% | 2.953 | `` |
| 6 | `baseline` | 3.9861e+03 | 3.4696e-07 | 0.01% | 1.494 | `` |
| 7 | `baseline` | 1.0081e+03 | 1.0081e+03 | 621.85% | 0.226 | `` |
| 8 | `baseline` | 2.0471e+02 | 1.6360e-01 | 511.81% | 3.517 | `` |
| 9 | `baseline` | 1.7014e+02 | 3.4696e-07 | 0.01% | 1.643 | `` |
| 10 | `baseline` | 7.9928e+01 | 2.9027e-01 | 263.32% | 3.602 | `` |
| 11 | `baseline` | Inf | Inf | 2023923.74% | 1.062 | `` |
| 12 | `baseline` | 2.5469e+01 | 3.4696e-07 | 0.01% | 1.650 | `` |
| 13 | `baseline` | 1.6799e+01 | 2.5988e-02 | 5431.43% | 11.124 | `` |
| 14 | `baseline` | 1.2394e+01 | 8.8028e-03 | 1432.62% | 2.977 | `` |
| 15 | `baseline` | 1.0881e+01 | 2.7101e-02 | 36013.06% | 26.571 | `` |
| 16 | `baseline` | 1.1097e+01 | 2.6712e-02 | 30512.25% | 22.443 | `` |
| 17 | `baseline` | 1.0759e+01 | 2.6417e-02 | 7638.96% | 10.882 | `` |
| 18 | `baseline` | 1.0473e+01 | 2.3712e-02 | 1845.68% | 4.855 | `` |
| 19 | `baseline` | 1.0397e+01 | 2.5976e-02 | 4766.50% | 9.193 | `` |
| 20 | `baseline` | 1.0383e+01 | 2.5972e-02 | 4725.79% | 9.072 | `` |
| 21 | `baseline` | 9.6866e+00 | 3.4696e-07 | 0.01% | 2.208 | `` |
| 22 | `baseline` | 9.6416e+00 | 8.6607e-03 | 1681.94% | 3.076 | `` |
| 23 | `baseline` | 8.6466e+00 | 3.4696e-07 | 0.01% | 2.803 | `` |
| 24 | `baseline` | 9.6463e+00 | 9.6463e+00 | 1318252.10% | 0.734 | `` |
| 25 | `baseline` | 9.1197e+00 | 2.6039e-02 | 5233.92% | 11.895 | `` |
| 26 | `baseline` | 6.4062e+00 | 9.2394e-03 | 982.67% | 2.835 | `` |
| 27 | `baseline` | 5.2551e+00 | 2.7183e-02 | 34572.74% | 28.074 | `` |
| 28 | `baseline` | 7.3257e+00 | 3.4696e-07 | 0.01% | 1.567 | `` |
| 29 | `baseline` | 9.1235e+00 | 1.9005e-01 | 1703.04% | 4.466 | `` |
| 30 | `baseline` | 5.1143e+00 | 5.1143e+00 | 55473.73% | 0.787 | `` |
| 31 | `baseline` | 4.3795e+00 | 2.6439e-02 | 10306.62% | 15.764 | `` |
| 32 | `baseline` | 4.6364e+00 | 2.6407e-02 | 9163.81% | 14.238 | `` |
| 33 | `baseline` | 3.1449e+00 | 3.4696e-07 | 0.01% | 0.952 | `` |
| 34 | `baseline` | Inf | Inf | 2394360.52% | 0.930 | `` |
| 35 | `baseline` | 1.8715e+00 | 2.6460e-02 | 25699.91% | 26.894 | `` |
| 36 | `baseline` | 1.8684e+00 | 2.6463e-02 | 19828.01% | 21.715 | `` |
| 37 | `baseline` | 1.8072e+00 | 2.1600e-02 | 1143.14% | 5.276 | `` |
| 38 | `baseline` | 1.8014e+00 | 3.3412e-03 | 83.27% | 2.904 | `` |
| 39 | `baseline` | 1.8024e+00 | 3.4696e-07 | 0.01% | 1.951 | `` |
| 40 | `baseline` | 2.0773e+00 | 3.4696e-07 | 0.01% | 0.702 | `` |
| 41 | `baseline` | 1.7475e+00 | 2.7557e-02 | 39506.57% | 21.396 | `` |
| 42 | `baseline` | 1.6948e+00 | 2.7091e-02 | 38063.45% | 20.570 | `` |
| 43 | `baseline` | 1.6514e+00 | 3.4696e-07 | 0.01% | 1.669 | `` |
| 44 | `baseline` | 1.5756e+00 | 3.4696e-07 | 0.01% | 1.376 | `` |
| 45 | `baseline` | 1.4632e+00 | 3.4696e-07 | 0.01% | 0.949 | `` |
| 46 | `baseline` | 1.4633e+00 | 3.4696e-07 | 0.01% | 1.412 | `` |
| 47 | `baseline` | 1.3945e+00 | 3.4696e-07 | 0.01% | 1.228 | `` |
| 48 | `baseline` | 1.3522e+00 | 3.4696e-07 | 0.01% | 1.169 | `` |
| 49 | `baseline` | 1.3483e+00 | 3.4696e-07 | 0.01% | 1.129 | `` |
| 50 | `baseline` | 1.9179e+00 | 3.4696e-07 | 0.01% | 1.558 | `` |
| 51 | `baseline` | 1.3207e+00 | 3.4696e-07 | 0.01% | 0.986 | `` |
| 52 | `baseline` | 1.3540e+00 | 3.4696e-07 | 0.01% | 0.655 | `` |
| 53 | `baseline` | 1.1337e+00 | 3.4696e-07 | 0.01% | 0.907 | `` |
| 54 | `baseline` | 1.1571e+00 | 3.4696e-07 | 0.01% | 0.640 | `` |
| 55 | `baseline` | 1.0142e+00 | 3.4696e-07 | 0.01% | 0.595 | `` |
| 56 | `baseline` | 1.0320e+00 | 4.3350e-02 | 111.00% | 3.992 | `` |
| 57 | `baseline` | 6.2583e-01 | 3.4696e-07 | 0.01% | 0.678 | `` |
| 58 | `baseline` | 4.8283e-01 | 3.4696e-07 | 0.01% | 0.570 | `` |
| 59 | `baseline` | 4.7173e-01 | 3.4696e-07 | 0.01% | 0.579 | `` |
| 60 | `baseline` | 4.7327e-01 | 3.4696e-07 | 0.01% | 0.525 | `` |
| 61 | `baseline` | 4.6751e-01 | 3.4696e-07 | 0.01% | 0.476 | `` |
| 62 | `baseline` | 3.8332e-01 | 3.4696e-07 | 0.01% | 0.579 | `` |
| 63 | `baseline` | 3.7838e-01 | 3.4696e-07 | 0.01% | 0.498 | `` |
| 64 | `baseline` | 2.8807e-01 | 3.4696e-07 | 0.01% | 1.220 | `` |
| 65 | `baseline` | 2.5645e-01 | 3.4696e-07 | 0.01% | 0.470 | `` |
| 66 | `baseline` | 4.0265e-01 | 3.4696e-07 | 0.01% | 0.505 | `` |
| 67 | `baseline` | 8.7737e-02 | 3.4696e-07 | 0.01% | 0.432 | `` |
| 68 | `baseline` | 7.9049e-02 | 3.4696e-07 | 0.01% | 0.944 | `` |
| 69 | `baseline` | 7.6512e-02 | 3.4696e-07 | 0.01% | 0.777 | `` |
| 70 | `baseline` | 6.1306e-02 | 3.4696e-07 | 0.01% | 0.459 | `` |
| 71 | `baseline` | 7.1494e-02 | 3.4696e-07 | 0.01% | 0.419 | `` |
| 72 | `baseline` | 5.4497e-02 | 3.4696e-07 | 0.01% | 0.789 | `` |
| 73 | `baseline` | 6.8021e-02 | 4.4634e-02 | 130.84% | 5.983 | `` |
| 74 | `baseline` | 4.4796e-02 | 3.4696e-07 | 0.01% | 0.282 | `` |
| 75 | `baseline` | 4.9380e-02 | 3.4696e-07 | 0.01% | 0.717 | `` |
| 76 | `baseline` | 1.8715e-02 | 3.4696e-07 | 0.01% | 0.293 | `` |
| 77 | `baseline` | 1.5455e-02 | 3.4696e-07 | 0.01% | 0.402 | `` |
| 78 | `baseline` | 1.5311e-02 | 3.4696e-07 | 0.01% | 0.483 | `` |
| 79 | `baseline` | 1.1229e-02 | 3.4696e-07 | 0.01% | 0.336 | `` |
| 80 | `baseline` | 6.6804e-03 | 3.4696e-07 | 0.01% | 0.354 | `` |
| 81 | `baseline` | 4.8417e-03 | 3.4696e-07 | 0.01% | 0.448 | `` |
| 82 | `baseline` | 2.8330e-03 | 3.4696e-07 | 0.01% | 0.311 | `` |
| 83 | `baseline` | 2.7086e-03 | 3.4696e-07 | 0.01% | 0.305 | `` |
| 84 | `baseline` | 2.7160e-03 | 3.4696e-07 | 0.01% | 0.312 | `` |
| 85 | `baseline` | 2.0579e-03 | 3.4696e-07 | 0.01% | 0.304 | `` |
| 86 | `baseline` | 1.6748e-03 | 3.4696e-07 | 0.01% | 0.310 | `` |
| 87 | `baseline` | 1.2806e-03 | 3.4696e-07 | 0.01% | 0.315 | `` |
| 88 | `baseline` | 9.9091e-04 | 3.4696e-07 | 0.01% | 0.294 | `` |
| 89 | `baseline` | 7.6048e-04 | 3.4696e-07 | 0.01% | 0.208 | `` |
| 90 | `branch+synthesized` | 3.4696e-07 | 3.4696e-07 | 0.01% | 0.032 | `` |
| 91 | `block` | 1.5060e-02 | 3.4696e-07 | 0.01% | 0.342 | `` |
| 92 | `branch` | 2.3559e-03 | 3.4696e-07 | 0.01% | 0.457 | `` |
| 93 | `block` | 3.9106e+00 | 3.4696e-07 | 0.01% | 0.678 | `` |
| 94 | `block` | 6.5835e+00 | 5.4327e-04 | 18.57% | 4.143 | `` |
| 95 | `block` | 1.0012e+01 | 3.4696e-07 | 0.01% | 3.374 | `` |
| 96 | `block` | 2.1648e+04 | 7.7725e-03 | 4629.05% | 4.130 | `` |
| 97 | `block` | 1.0893e+05 | 7.7910e-03 | 5064.84% | 4.393 | `` |
| 98 | `block` | 6.8574e+05 | 7.8010e-03 | 5351.57% | 5.170 | `` |
| 99 | `block` | 1.2376e+06 | 3.5327e+00 | 4520.07% | 7.532 | `` |
| 100 | `block` | 1.4814e+06 | 2.9647e+03 | 27617.35% | 3.909 | `` |
| 101 | `block` | 1.3852e+06 | 9.6155e+00 | 4108.14% | 6.644 | `` |
| 102 | `block` | 6.0899e+05 | 1.1247e-01 | 197.61% | 6.211 | `` |
| 103 | `block` | 1.6055e+06 | 1.6283e-01 | 423.35% | 5.975 | `` |

