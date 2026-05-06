# Tryhard Finalist Benchmark Case: aircraft_pitch_6_1em4

- Model: `aircraft_pitch`
- Role: `guard`
- Selected via: `family_priority`
- Generated: `2026-04-14T12:33:12.743`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/aircraft_pitch_6_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/aircraft_pitch_6_1em4`

## Comparison-Table Reference

- Classification: `b_only`
- Comparison CSV ODEPE mean/max relative error: 1.15% / 6.88%
- Comparison CSV ODEPE runtime: 806.313 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 129 | 367.60% | theta(0) (972.58%) | 7.1319e-08 |
| `odepe_polish` | 234 | 586.42% | theta(0) (1551.52%) | 4.7699e-09 |

## Imported Raw Pool

- Raw imported candidates: 129
- Best raw fit index: 129
- Best raw oracle index: 91
- Best-fit vs best-truth combined-RMSE gap: 356.93%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.867 s
- Consensus/block context: 4.887 s
- 4x4 baseline evidence report: 0.748 s
- 4x4 block no-polish report: 5.107 s
- Polish context build: 0.042 s
- Baseline-only finalists: 146.694 s
- Additive-only finalists: 11.982 s
- Reasonable frontier finalists: 64.077 s
- Local total (excluding reference load): 233.537 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 367.60% | 367.60% | 125 | `raw` | 7.1319e-08 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 586.42% | 586.42% | 234 | `benchmark` | 4.7699e-09 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 155.51% | 155.51% | 16 | `block` | 1.6553e+03 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 311.51% | 8.05% | 35 | `baseline` | 4.7699e-09 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 155.51% | 155.51% | 15 | `block` | 4.7699e-09 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 155.51% | 8.05% | 39 | `baseline+block` | 4.7699e-09 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 20 / 8.05%
- Additive best finalist index / RMSE: 1 / 155.51%
- Frontier best finalist index / RMSE: 20 / 8.05%
- Baseline preserved seeds: 125
- Additive candidate seeds: 16
- Frontier admitted seeds: 131
- Rejected additive seeds: 10
- Successful merged polished seeds: 131
- Returned merged finalists: 39

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 2.1632e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 1.0936e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 3.2276e+03 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 2.0622e+02 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 4.6910e+01 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 4.6290e+01 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 3.4934e+01 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.9769e+01 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 2.9758e+01 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 2.8470e+01 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 1.8669e+01 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 1.2819e+01 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 1.1074e+01 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 1.0389e+01 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 7.2971e+00 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 3.4372e+00 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 3.3181e+00 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 2.4087e+00 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 1.7422e+00 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 6.7379e-01 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 6.7350e-01 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 4.7802e-01 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 4.2647e-01 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 4.1354e-01 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 3.6262e-01 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 3.4477e-01 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 2.5967e-01 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 2.2851e-01 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 2.1615e-01 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 1.6835e-01 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 1.4428e-01 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 1.1669e-01 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 6.4116e-02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 3.9613e-02 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 3.9567e-02 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 2.2246e-02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 2.1029e-02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 1.2337e-02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 1.1017e-02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 1.0742e-02 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 8.6492e-03 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 7.4291e-03 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 6.4401e-03 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 4.7546e-03 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 3.7885e-03 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 3.5312e-03 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 3.0594e-03 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 2.7297e-03 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 2.6700e-03 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 2.1672e-03 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 1.8121e-03 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | 1.4847e-03 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | 1.2679e-03 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 1.1490e-03 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 1.0752e-03 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 8.1042e-04 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 7.1491e-04 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 6.2691e-04 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 6.1351e-04 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 5.8828e-04 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 5.8618e-04 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 5.5594e-04 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 4.7403e-04 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 4.6774e-04 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 3.8291e-04 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 3.8251e-04 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 3.3139e-04 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 3.1615e-04 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 2.6853e-04 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 2.5643e-04 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 2.0787e-04 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 73 | 1.8955e-04 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | 80 | 1.2833e-04 | method=algebraic, source=imported, candidate=80 |
| 75 | `baseline` | 75 | 1.5214e-04 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | 76 | 1.5072e-04 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | 77 | 1.3660e-04 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | 78 | 1.3054e-04 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | 79 | 1.2987e-04 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | 81 | 1.2456e-04 | method=algebraic, source=imported, candidate=81 |
| 81 | `baseline` | 82 | 1.1789e-04 | method=algebraic, source=imported, candidate=82 |
| 82 | `baseline` | 83 | 1.1166e-04 | method=algebraic, source=imported, candidate=83 |
| 83 | `baseline` | 84 | 1.0617e-04 | method=algebraic, source=imported, candidate=84 |
| 84 | `baseline` | 85 | 6.6141e-05 | method=algebraic, source=imported, candidate=85 |
| 85 | `baseline` | 86 | 5.1731e-05 | method=algebraic, source=imported, candidate=86 |
| 86 | `baseline` | 87 | 5.1401e-05 | method=algebraic, source=imported, candidate=87 |
| 87 | `baseline` | 88 | 4.7210e-05 | method=algebraic, source=imported, candidate=88 |
| 88 | `baseline` | 89 | 4.6338e-05 | method=algebraic, source=imported, candidate=89 |
| 89 | `baseline` | 90 | 4.3909e-05 | method=algebraic, source=imported, candidate=90 |
| 90 | `baseline` | 91 | 4.2895e-05 | method=algebraic, source=imported, candidate=91 |
| 91 | `baseline` | 92 | 3.8345e-05 | method=algebraic, source=imported, candidate=92 |
| 92 | `baseline` | 93 | 3.6238e-05 | method=algebraic, source=imported, candidate=93 |
| 93 | `baseline` | 94 | 3.4874e-05 | method=algebraic, source=imported, candidate=94 |
| 94 | `baseline` | 105 | 8.8850e-06 | method=algebraic, source=imported, candidate=105 |
| 95 | `baseline` | 96 | 3.3655e-05 | method=algebraic, source=imported, candidate=96 |
| 96 | `baseline` | 97 | 2.3893e-05 | method=algebraic, source=imported, candidate=97 |
| 97 | `baseline` | 98 | 2.1074e-05 | method=algebraic, source=imported, candidate=98 |
| 98 | `baseline` | 99 | 1.8825e-05 | method=algebraic, source=imported, candidate=99 |
| 99 | `baseline` | 100 | 1.7825e-05 | method=algebraic, source=imported, candidate=100 |
| 100 | `baseline` | 101 | 1.3384e-05 | method=algebraic, source=imported, candidate=101 |
| 101 | `baseline` | 104 | 8.9007e-06 | method=algebraic, source=imported, candidate=104 |
| 102 | `baseline` | 106 | 6.8825e-06 | method=algebraic, source=imported, candidate=106 |
| 103 | `baseline` | 107 | 6.0294e-06 | method=algebraic, source=imported, candidate=107 |
| 104 | `baseline` | 108 | 5.6938e-06 | method=algebraic, source=imported, candidate=108 |
| 105 | `baseline` | 109 | 5.6909e-06 | method=algebraic, source=imported, candidate=109 |
| 106 | `baseline` | 110 | 5.6398e-06 | method=algebraic, source=imported, candidate=110 |
| 107 | `baseline` | 111 | 5.2075e-06 | method=algebraic, source=imported, candidate=111 |
| 108 | `baseline` | 112 | 4.6009e-06 | method=algebraic, source=imported, candidate=112 |
| 109 | `baseline` | 113 | 2.8851e-06 | method=algebraic, source=imported, candidate=113 |
| 110 | `baseline` | 114 | 2.6953e-06 | method=algebraic, source=imported, candidate=114 |
| 111 | `baseline` | 115 | 2.6339e-06 | method=algebraic, source=imported, candidate=115 |
| 112 | `baseline` | 116 | 2.4620e-06 | method=algebraic, source=imported, candidate=116 |
| 113 | `baseline` | 117 | 1.8396e-06 | method=algebraic, source=imported, candidate=117 |
| 114 | `baseline` | 118 | 1.4087e-06 | method=algebraic, source=imported, candidate=118 |
| 115 | `baseline` | 119 | 8.4972e-07 | method=algebraic, source=imported, candidate=119 |
| 116 | `baseline` | 120 | 7.7749e-07 | method=algebraic, source=imported, candidate=120 |
| 117 | `baseline` | 121 | 6.2560e-07 | method=algebraic, source=imported, candidate=121 |
| 118 | `baseline` | 122 | 6.0814e-07 | method=algebraic, source=imported, candidate=122 |
| 119 | `baseline` | 123 | 5.3699e-07 | method=algebraic, source=imported, candidate=123 |
| 120 | `baseline` | 124 | 3.5858e-07 | method=algebraic, source=imported, candidate=124 |
| 121 | `baseline` | 125 | 2.6228e-07 | method=algebraic, source=imported, candidate=125 |
| 122 | `baseline` | 126 | 2.5777e-07 | method=algebraic, source=imported, candidate=126 |
| 123 | `baseline` | 127 | 1.5703e-07 | method=algebraic, source=imported, candidate=127 |
| 124 | `baseline` | 128 | 1.3674e-07 | method=algebraic, source=imported, candidate=128 |
| 125 | `baseline` | 129 | 7.1319e-08 | method=algebraic, source=imported, candidate=129 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 1.6553e+03 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0083 | 1.6553e+03 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.0244 | 1.6624e+03 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.0244 | 1.6624e+03 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.1167 | 7.0296e+04 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.1167 | 7.0296e+04 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.1741 | 7.6435e+06 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.1756 | 7.6435e+06 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.4657 | 1.1225e+13 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.4657 | 1.1225e+13 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.7297 | 3.8914e+18 | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.7297 | 3.8914e+18 | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.9881 | Inf | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.9881 | Inf | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 1.0000 | Inf | method=direct_opt, source=assembled |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `block` | `catastrophic_fit` | 7.6435e+06 | method=direct_opt, source=assembled |
| 2 | `block` | `catastrophic_fit` | 7.6435e+06 | method=direct_opt, source=assembled |
| 3 | `block` | `catastrophic_fit` | 1.1225e+13 | method=direct_opt, source=assembled |
| 4 | `block` | `catastrophic_fit` | 1.1225e+13 | method=direct_opt, source=assembled |
| 5 | `block` | `catastrophic_fit` | 3.8914e+18 | method=direct_opt, source=assembled |
| 6 | `block` | `catastrophic_fit` | 3.8914e+18 | method=direct_opt, source=assembled |
| 7 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 8 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 9 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 10 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 2.1632e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 1.0936e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 3.2276e+03 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 2.0622e+02 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 4.6910e+01 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 4.6290e+01 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 3.4934e+01 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.9769e+01 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 2.9758e+01 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 2.8470e+01 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 1.8669e+01 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 1.2819e+01 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 1.1074e+01 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 1.0389e+01 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 7.2971e+00 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 3.4372e+00 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 3.3181e+00 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 2.4087e+00 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 1.7422e+00 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 6.7379e-01 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 6.7350e-01 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 4.7802e-01 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 4.2647e-01 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 4.1354e-01 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 3.6262e-01 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 3.4477e-01 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 2.5967e-01 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 2.2851e-01 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 2.1615e-01 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 1.6835e-01 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 1.4428e-01 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 1.1669e-01 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 6.4116e-02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 3.9613e-02 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 3.9567e-02 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 2.2246e-02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 2.1029e-02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 1.2337e-02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 1.1017e-02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 1.0742e-02 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 8.6492e-03 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 7.4291e-03 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 6.4401e-03 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 4.7546e-03 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 3.7885e-03 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 3.5312e-03 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 3.0594e-03 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 2.7297e-03 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 2.6700e-03 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 2.1672e-03 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 1.8121e-03 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | 1.4847e-03 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | 1.2679e-03 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 1.1490e-03 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 1.0752e-03 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 8.1042e-04 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 7.1491e-04 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 6.2691e-04 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 6.1351e-04 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 5.8828e-04 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 5.8618e-04 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 5.5594e-04 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 4.7403e-04 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 4.6774e-04 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 3.8291e-04 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 3.8251e-04 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 3.3139e-04 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 3.1615e-04 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 2.6853e-04 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 2.5643e-04 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 2.0787e-04 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#73` | 1.8955e-04 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | `baseline#80` | 1.2833e-04 | method=algebraic, source=imported, candidate=80 |
| 75 | `baseline` | `baseline#75` | 1.5214e-04 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | `baseline#76` | 1.5072e-04 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | `baseline#77` | 1.3660e-04 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | `baseline#78` | 1.3054e-04 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | `baseline#79` | 1.2987e-04 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | `baseline#81` | 1.2456e-04 | method=algebraic, source=imported, candidate=81 |
| 81 | `baseline` | `baseline#82` | 1.1789e-04 | method=algebraic, source=imported, candidate=82 |
| 82 | `baseline` | `baseline#83` | 1.1166e-04 | method=algebraic, source=imported, candidate=83 |
| 83 | `baseline` | `baseline#84` | 1.0617e-04 | method=algebraic, source=imported, candidate=84 |
| 84 | `baseline` | `baseline#85` | 6.6141e-05 | method=algebraic, source=imported, candidate=85 |
| 85 | `baseline` | `baseline#86` | 5.1731e-05 | method=algebraic, source=imported, candidate=86 |
| 86 | `baseline` | `baseline#87` | 5.1401e-05 | method=algebraic, source=imported, candidate=87 |
| 87 | `baseline` | `baseline#88` | 4.7210e-05 | method=algebraic, source=imported, candidate=88 |
| 88 | `baseline` | `baseline#89` | 4.6338e-05 | method=algebraic, source=imported, candidate=89 |
| 89 | `baseline` | `baseline#90` | 4.3909e-05 | method=algebraic, source=imported, candidate=90 |
| 90 | `baseline` | `baseline#91` | 4.2895e-05 | method=algebraic, source=imported, candidate=91 |
| 91 | `baseline` | `baseline#92` | 3.8345e-05 | method=algebraic, source=imported, candidate=92 |
| 92 | `baseline` | `baseline#93` | 3.6238e-05 | method=algebraic, source=imported, candidate=93 |
| 93 | `baseline` | `baseline#94` | 3.4874e-05 | method=algebraic, source=imported, candidate=94 |
| 94 | `baseline` | `baseline#105` | 8.8850e-06 | method=algebraic, source=imported, candidate=105 |
| 95 | `baseline` | `baseline#96` | 3.3655e-05 | method=algebraic, source=imported, candidate=96 |
| 96 | `baseline` | `baseline#97` | 2.3893e-05 | method=algebraic, source=imported, candidate=97 |
| 97 | `baseline` | `baseline#98` | 2.1074e-05 | method=algebraic, source=imported, candidate=98 |
| 98 | `baseline` | `baseline#99` | 1.8825e-05 | method=algebraic, source=imported, candidate=99 |
| 99 | `baseline` | `baseline#100` | 1.7825e-05 | method=algebraic, source=imported, candidate=100 |
| 100 | `baseline` | `baseline#101` | 1.3384e-05 | method=algebraic, source=imported, candidate=101 |
| 101 | `baseline` | `baseline#104` | 8.9007e-06 | method=algebraic, source=imported, candidate=104 |
| 102 | `baseline` | `baseline#106` | 6.8825e-06 | method=algebraic, source=imported, candidate=106 |
| 103 | `baseline` | `baseline#107` | 6.0294e-06 | method=algebraic, source=imported, candidate=107 |
| 104 | `baseline` | `baseline#108` | 5.6938e-06 | method=algebraic, source=imported, candidate=108 |
| 105 | `baseline` | `baseline#109` | 5.6909e-06 | method=algebraic, source=imported, candidate=109 |
| 106 | `baseline` | `baseline#110` | 5.6398e-06 | method=algebraic, source=imported, candidate=110 |
| 107 | `baseline` | `baseline#111` | 5.2075e-06 | method=algebraic, source=imported, candidate=111 |
| 108 | `baseline` | `baseline#112` | 4.6009e-06 | method=algebraic, source=imported, candidate=112 |
| 109 | `baseline` | `baseline#113` | 2.8851e-06 | method=algebraic, source=imported, candidate=113 |
| 110 | `baseline` | `baseline#114` | 2.6953e-06 | method=algebraic, source=imported, candidate=114 |
| 111 | `baseline` | `baseline#115` | 2.6339e-06 | method=algebraic, source=imported, candidate=115 |
| 112 | `baseline` | `baseline#116` | 2.4620e-06 | method=algebraic, source=imported, candidate=116 |
| 113 | `baseline` | `baseline#117` | 1.8396e-06 | method=algebraic, source=imported, candidate=117 |
| 114 | `baseline` | `baseline#118` | 1.4087e-06 | method=algebraic, source=imported, candidate=118 |
| 115 | `baseline` | `baseline#119` | 8.4972e-07 | method=algebraic, source=imported, candidate=119 |
| 116 | `baseline` | `baseline#120` | 7.7749e-07 | method=algebraic, source=imported, candidate=120 |
| 117 | `baseline` | `baseline#121` | 6.2560e-07 | method=algebraic, source=imported, candidate=121 |
| 118 | `baseline` | `baseline#122` | 6.0814e-07 | method=algebraic, source=imported, candidate=122 |
| 119 | `baseline` | `baseline#123` | 5.3699e-07 | method=algebraic, source=imported, candidate=123 |
| 120 | `baseline` | `baseline#124` | 3.5858e-07 | method=algebraic, source=imported, candidate=124 |
| 121 | `baseline` | `baseline#125` | 2.6228e-07 | method=algebraic, source=imported, candidate=125 |
| 122 | `baseline` | `baseline#126` | 2.5777e-07 | method=algebraic, source=imported, candidate=126 |
| 123 | `baseline` | `baseline#127` | 1.5703e-07 | method=algebraic, source=imported, candidate=127 |
| 124 | `baseline` | `baseline#128` | 1.3674e-07 | method=algebraic, source=imported, candidate=128 |
| 125 | `baseline` | `baseline#129` | 7.1319e-08 | method=algebraic, source=imported, candidate=129 |
| 126 | `block` | `block#1` | 1.6553e+03 | method=direct_opt, source=assembled |
| 127 | `block` | `block#2` | 1.6553e+03 | method=direct_opt, source=assembled |
| 128 | `block` | `block#3` | 1.6624e+03 | method=direct_opt, source=assembled |
| 129 | `block` | `block#4` | 1.6624e+03 | method=direct_opt, source=assembled |
| 130 | `block` | `block#5` | 7.0296e+04 | method=direct_opt, source=assembled |
| 131 | `block` | `block#6` | 7.0296e+04 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 13 | 4.7699e-09 | 155.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=33, polished=true |
| 2 | `baseline` | 11 | 4.7699e-09 | 311.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=50, polished=true |
| 3 | `baseline` | 11 | 4.7699e-09 | 101.61% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 4 | `baseline` | 11 | 4.7699e-09 | 94.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 5 | `baseline` | 9 | 4.7699e-09 | 906.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=123, polished=true |
| 6 | `baseline` | 9 | 4.7699e-09 | 558.18% | 0 | 0.5000 | method=algebraic, source=imported, candidate=105, polished=true |
| 7 | `baseline` | 9 | 4.7699e-09 | 621.80% | 0 | 0.5000 | method=algebraic, source=imported, candidate=77, polished=true |
| 8 | `baseline` | 9 | 4.7699e-09 | 485.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=84, polished=true |
| 9 | `baseline` | 7 | 4.7699e-09 | 367.40% | 0 | 0.5000 | method=algebraic, source=imported, candidate=108, polished=true |
| 10 | `baseline` | 5 | 4.7699e-09 | 11.23% | 0 | 0.5000 | method=algebraic, source=imported, candidate=110, polished=true |
| 11 | `baseline` | 4 | 4.7699e-09 | 781.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=71, polished=true |
| 12 | `baseline` | 3 | 4.7699e-09 | 367.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=88, polished=true |
| 13 | `baseline` | 2 | 4.7699e-09 | 780.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=92, polished=true |
| 14 | `baseline` | 2 | 4.7699e-09 | 484.71% | 0 | 0.5000 | method=algebraic, source=imported, candidate=51, polished=true |
| 15 | `baseline` | 2 | 4.7699e-09 | 909.09% | 0 | 0.5000 | method=algebraic, source=imported, candidate=70, polished=true |
| 16 | `baseline` | 1 | 4.7699e-09 | 756.88% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 17 | `baseline` | 1 | 4.7699e-09 | 9.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=67, polished=true |
| 18 | `baseline` | 1 | 4.7699e-09 | 368.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=68, polished=true |
| 19 | `baseline` | 1 | 4.7699e-09 | 776.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=56, polished=true |
| 20 | `baseline` | 1 | 4.7699e-09 | 8.05% | 0 | 0.5000 | method=algebraic, source=imported, candidate=52, polished=true |
| 21 | `baseline` | 1 | 4.7699e-09 | 10.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=87, polished=true |
| 22 | `baseline` | 1 | 4.7699e-09 | 796.42% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 23 | `baseline` | 1 | 4.7699e-09 | 11.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=89, polished=true |
| 24 | `baseline` | 1 | 4.7699e-09 | 620.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=53, polished=true |
| 25 | `baseline` | 1 | 4.7699e-09 | 782.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=59, polished=true |
| 26 | `baseline` | 1 | 4.7699e-09 | 6738.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 27 | `baseline` | 1 | 4.7699e-09 | 767.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |
| 28 | `baseline` | 1 | 4.7699e-09 | 718.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 29 | `baseline` | 1 | 4.7699e-09 | 10.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=91, polished=true |
| 30 | `baseline` | 1 | 4.7699e-09 | 743.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 31 | `baseline` | 1 | 4.7699e-09 | 999.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 32 | `baseline` | 1 | 2.8470e+01 | 451836.27% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 33 | `baseline` | 1 | 4.6214e+04 | 624312.36% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 34 | `block` | 1 | 6.7643e+04 | 896823.07% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 35 | `baseline` | 1 | 9.2203e+04 | 895456.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 36 | `baseline` | 1 | Inf | 10776.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 37 | `block` | 1 | Inf | 9232.00% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 38 | `block` | 1 | Inf | 9916.94% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 39 | `block` | 1 | Inf | 896833.56% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 2.1632e+06 | 9.2203e+04 | 895456.91% | 1.696 | `` |
| 2 | `baseline` | 1.0936e+06 | 4.6214e+04 | 624312.36% | 1.697 | `` |
| 3 | `baseline` | 3.2276e+03 | 4.7699e-09 | 6738.19% | 2.306 | `` |
| 4 | `baseline` | 2.0622e+02 | 4.7699e-09 | 94.73% | 1.112 | `` |
| 5 | `baseline` | 4.6910e+01 | 4.7699e-09 | 94.73% | 1.218 | `` |
| 6 | `baseline` | 4.6290e+01 | 4.7699e-09 | 94.73% | 0.939 | `` |
| 7 | `baseline` | 3.4934e+01 | 4.7699e-09 | 999.46% | 1.477 | `` |
| 8 | `baseline` | 2.9769e+01 | 4.7699e-09 | 743.06% | 2.501 | `` |
| 9 | `baseline` | 2.9758e+01 | 4.7699e-09 | 718.90% | 7.179 | `` |
| 10 | `baseline` | 2.8470e+01 | 2.8470e+01 | 451836.27% | 0.690 | `` |
| 11 | `baseline` | Inf | Inf | 10776.91% | 0.067 | `` |
| 12 | `baseline` | 1.8669e+01 | 4.7699e-09 | 796.42% | 1.318 | `` |
| 13 | `baseline` | 1.2819e+01 | 4.7699e-09 | 101.62% | 1.216 | `` |
| 14 | `baseline` | 1.1074e+01 | 4.7699e-09 | 94.73% | 0.942 | `` |
| 15 | `baseline` | 1.0389e+01 | 4.7699e-09 | 101.61% | 0.822 | `` |
| 16 | `baseline` | 7.2971e+00 | 4.7699e-09 | 94.73% | 1.002 | `` |
| 17 | `baseline` | 3.4372e+00 | 4.7699e-09 | 94.73% | 1.051 | `` |
| 18 | `baseline` | 3.3181e+00 | 4.7699e-09 | 94.73% | 0.569 | `` |
| 19 | `baseline` | 2.4087e+00 | 4.7699e-09 | 94.73% | 1.024 | `` |
| 20 | `baseline` | 1.7422e+00 | 4.7699e-09 | 101.61% | 0.523 | `` |
| 21 | `baseline` | 6.7379e-01 | 4.7699e-09 | 155.51% | 0.472 | `` |
| 22 | `baseline` | 6.7350e-01 | 4.7699e-09 | 94.73% | 0.589 | `` |
| 23 | `baseline` | 4.7802e-01 | 4.7699e-09 | 101.61% | 0.397 | `` |
| 24 | `baseline` | 4.2647e-01 | 4.7699e-09 | 94.73% | 0.402 | `` |
| 25 | `baseline` | 4.1354e-01 | 4.7699e-09 | 101.61% | 0.678 | `` |
| 26 | `baseline` | 3.6262e-01 | 4.7699e-09 | 101.61% | 0.379 | `` |
| 27 | `baseline` | 3.4477e-01 | 4.7699e-09 | 101.61% | 0.540 | `` |
| 28 | `baseline` | 2.5967e-01 | 4.7699e-09 | 155.51% | 0.502 | `` |
| 29 | `baseline` | 2.2851e-01 | 4.7699e-09 | 94.73% | 0.356 | `` |
| 30 | `baseline` | 2.1615e-01 | 4.7699e-09 | 101.61% | 0.338 | `` |
| 31 | `baseline` | 1.6835e-01 | 4.7699e-09 | 155.52% | 0.406 | `` |
| 32 | `baseline` | 1.4428e-01 | 4.7699e-09 | 101.61% | 0.544 | `` |
| 33 | `baseline` | 1.1669e-01 | 4.7699e-09 | 155.51% | 0.311 | `` |
| 34 | `baseline` | 6.4116e-02 | 4.7699e-09 | 155.51% | 0.340 | `` |
| 35 | `baseline` | 3.9613e-02 | 4.7699e-09 | 756.88% | 0.335 | `` |
| 36 | `baseline` | 3.9567e-02 | 4.7699e-09 | 311.52% | 0.492 | `` |
| 37 | `baseline` | 2.2246e-02 | 4.7699e-09 | 311.49% | 0.291 | `` |
| 38 | `baseline` | 2.1029e-02 | 4.7699e-09 | 311.48% | 0.335 | `` |
| 39 | `baseline` | 1.2337e-02 | 4.7699e-09 | 155.51% | 0.337 | `` |
| 40 | `baseline` | 1.1017e-02 | 4.7699e-09 | 767.78% | 0.272 | `` |
| 41 | `baseline` | 1.0742e-02 | 4.7699e-09 | 101.61% | 0.407 | `` |
| 42 | `baseline` | 8.6492e-03 | 4.7699e-09 | 155.51% | 0.318 | `` |
| 43 | `baseline` | 7.4291e-03 | 4.7699e-09 | 101.61% | 0.270 | `` |
| 44 | `baseline` | 6.4401e-03 | 4.7699e-09 | 558.07% | 0.275 | `` |
| 45 | `baseline` | 4.7546e-03 | 4.7699e-09 | 155.52% | 0.341 | `` |
| 46 | `baseline` | 3.7885e-03 | 4.7699e-09 | 155.51% | 0.388 | `` |
| 47 | `baseline` | 3.5312e-03 | 4.7699e-09 | 155.51% | 0.266 | `` |
| 48 | `baseline` | 3.0594e-03 | 4.7699e-09 | 558.41% | 0.268 | `` |
| 49 | `baseline` | 2.7297e-03 | 4.7699e-09 | 311.49% | 0.275 | `` |
| 50 | `baseline` | 2.6700e-03 | 4.7699e-09 | 311.51% | 0.270 | `` |
| 51 | `baseline` | 2.1672e-03 | 4.7699e-09 | 484.71% | 0.407 | `` |
| 52 | `baseline` | 1.8121e-03 | 4.7699e-09 | 8.05% | 0.250 | `` |
| 53 | `baseline` | 1.4847e-03 | 4.7699e-09 | 620.84% | 0.265 | `` |
| 54 | `baseline` | 1.2679e-03 | 4.7699e-09 | 155.51% | 0.274 | `` |
| 55 | `baseline` | 1.1490e-03 | 4.7699e-09 | 622.26% | 0.272 | `` |
| 56 | `baseline` | 1.0752e-03 | 4.7699e-09 | 776.32% | 0.419 | `` |
| 57 | `baseline` | 8.1042e-04 | 4.7699e-09 | 558.21% | 0.239 | `` |
| 58 | `baseline` | 7.1491e-04 | 4.7699e-09 | 558.36% | 0.267 | `` |
| 59 | `baseline` | 6.2691e-04 | 4.7699e-09 | 782.44% | 0.266 | `` |
| 60 | `baseline` | 6.1351e-04 | 4.7699e-09 | 311.49% | 0.269 | `` |
| 61 | `baseline` | 5.8828e-04 | 4.7699e-09 | 558.16% | 0.438 | `` |
| 62 | `baseline` | 5.8618e-04 | 4.7699e-09 | 558.26% | 0.221 | `` |
| 63 | `baseline` | 5.5594e-04 | 4.7699e-09 | 485.64% | 0.264 | `` |
| 64 | `baseline` | 4.7403e-04 | 4.7699e-09 | 311.51% | 0.267 | `` |
| 65 | `baseline` | 4.6774e-04 | 4.7699e-09 | 311.52% | 0.276 | `` |
| 66 | `baseline` | 3.8291e-04 | 4.7699e-09 | 311.52% | 0.272 | `` |
| 67 | `baseline` | 3.8251e-04 | 4.7699e-09 | 9.83% | 0.387 | `` |
| 68 | `baseline` | 3.3139e-04 | 4.7699e-09 | 368.81% | 0.265 | `` |
| 69 | `baseline` | 3.1615e-04 | 4.7699e-09 | 621.36% | 0.267 | `` |
| 70 | `baseline` | 2.6853e-04 | 4.7699e-09 | 909.09% | 0.268 | `` |
| 71 | `baseline` | 2.5643e-04 | 4.7699e-09 | 781.32% | 0.273 | `` |
| 72 | `baseline` | 2.0787e-04 | 4.7699e-09 | 621.97% | 0.430 | `` |
| 73 | `baseline` | 1.8955e-04 | 4.7699e-09 | 781.44% | 0.245 | `` |
| 74 | `baseline` | 1.2833e-04 | 4.7699e-09 | 781.04% | 0.268 | `` |
| 75 | `baseline` | 1.5214e-04 | 4.7699e-09 | 781.16% | 0.270 | `` |
| 76 | `baseline` | 1.5072e-04 | 4.7699e-09 | 367.94% | 0.271 | `` |
| 77 | `baseline` | 1.3660e-04 | 4.7699e-09 | 621.80% | 0.449 | `` |
| 78 | `baseline` | 1.3054e-04 | 4.7699e-09 | 622.07% | 0.232 | `` |
| 79 | `baseline` | 1.2987e-04 | 4.7699e-09 | 311.51% | 0.268 | `` |
| 80 | `baseline` | 1.2456e-04 | 4.7699e-09 | 908.19% | 0.267 | `` |
| 81 | `baseline` | 1.1789e-04 | 4.7699e-09 | 311.51% | 0.270 | `` |
| 82 | `baseline` | 1.1166e-04 | 4.7699e-09 | 484.92% | 0.444 | `` |
| 83 | `baseline` | 1.0617e-04 | 4.7699e-09 | 485.64% | 0.214 | `` |
| 84 | `baseline` | 6.6141e-05 | 4.7699e-09 | 906.14% | 0.261 | `` |
| 85 | `baseline` | 5.1731e-05 | 4.7699e-09 | 485.49% | 0.269 | `` |
| 86 | `baseline` | 5.1401e-05 | 4.7699e-09 | 10.92% | 0.275 | `` |
| 87 | `baseline` | 4.7210e-05 | 4.7699e-09 | 367.94% | 0.277 | `` |
| 88 | `baseline` | 4.6338e-05 | 4.7699e-09 | 11.49% | 0.410 | `` |
| 89 | `baseline` | 4.3909e-05 | 4.7699e-09 | 558.17% | 0.246 | `` |
| 90 | `baseline` | 4.2895e-05 | 4.7699e-09 | 10.62% | 0.274 | `` |
| 91 | `baseline` | 3.8345e-05 | 4.7699e-09 | 780.43% | 0.271 | `` |
| 92 | `baseline` | 3.6238e-05 | 4.7699e-09 | 558.19% | 0.270 | `` |
| 93 | `baseline` | 3.4874e-05 | 4.7699e-09 | 367.85% | 0.424 | `` |
| 94 | `baseline` | 8.8850e-06 | 4.7699e-09 | 558.18% | 0.166 | `` |
| 95 | `baseline` | 3.3655e-05 | 4.7699e-09 | 367.57% | 0.267 | `` |
| 96 | `baseline` | 2.3893e-05 | 4.7699e-09 | 621.96% | 0.206 | `` |
| 97 | `baseline` | 2.1074e-05 | 4.7699e-09 | 11.15% | 0.271 | `` |
| 98 | `baseline` | 1.8825e-05 | 4.7699e-09 | 907.03% | 0.207 | `` |
| 99 | `baseline` | 1.7825e-05 | 4.7699e-09 | 907.36% | 0.374 | `` |
| 100 | `baseline` | 1.3384e-05 | 4.7699e-09 | 621.94% | 0.161 | `` |
| 101 | `baseline` | 8.9007e-06 | 4.7699e-09 | 621.94% | 0.191 | `` |
| 102 | `baseline` | 6.8825e-06 | 4.7699e-09 | 906.44% | 0.203 | `` |
| 103 | `baseline` | 6.0294e-06 | 4.7699e-09 | 621.91% | 0.203 | `` |
| 104 | `baseline` | 5.6938e-06 | 4.7699e-09 | 367.40% | 0.268 | `` |
| 105 | `baseline` | 5.6909e-06 | 4.7699e-09 | 485.80% | 0.203 | `` |
| 106 | `baseline` | 5.6398e-06 | 4.7699e-09 | 11.23% | 0.417 | `` |
| 107 | `baseline` | 5.2075e-06 | 4.7699e-09 | 11.22% | 0.239 | `` |
| 108 | `baseline` | 4.6009e-06 | 4.7699e-09 | 779.96% | 0.200 | `` |
| 109 | `baseline` | 2.8851e-06 | 4.7699e-09 | 367.58% | 0.204 | `` |
| 110 | `baseline` | 2.6953e-06 | 4.7699e-09 | 485.28% | 0.205 | `` |
| 111 | `baseline` | 2.6339e-06 | 4.7699e-09 | 367.58% | 0.205 | `` |
| 112 | `baseline` | 2.4620e-06 | 4.7699e-09 | 485.26% | 0.203 | `` |
| 113 | `baseline` | 1.8396e-06 | 4.7699e-09 | 11.14% | 0.339 | `` |
| 114 | `baseline` | 1.4087e-06 | 4.7699e-09 | 485.29% | 0.184 | `` |
| 115 | `baseline` | 8.4972e-07 | 4.7699e-09 | 11.13% | 0.203 | `` |
| 116 | `baseline` | 7.7749e-07 | 4.7699e-09 | 367.58% | 0.202 | `` |
| 117 | `baseline` | 6.2560e-07 | 4.7699e-09 | 906.83% | 0.201 | `` |
| 118 | `baseline` | 6.0814e-07 | 4.7699e-09 | 367.60% | 0.202 | `` |
| 119 | `baseline` | 5.3699e-07 | 4.7699e-09 | 906.84% | 0.201 | `` |
| 120 | `baseline` | 3.5858e-07 | 4.7699e-09 | 906.69% | 0.339 | `` |
| 121 | `baseline` | 2.6228e-07 | 4.7699e-09 | 485.49% | 0.186 | `` |
| 122 | `baseline` | 2.5777e-07 | 4.7699e-09 | 485.39% | 0.201 | `` |
| 123 | `baseline` | 1.5703e-07 | 4.7699e-09 | 906.76% | 0.200 | `` |
| 124 | `baseline` | 1.3674e-07 | 4.7699e-09 | 906.80% | 0.204 | `` |
| 125 | `baseline` | 7.1319e-08 | 4.7699e-09 | 367.60% | 0.205 | `` |
| 126 | `block` | 1.6553e+03 | 4.7699e-09 | 155.51% | 0.204 | `` |
| 127 | `block` | 1.6553e+03 | 4.7699e-09 | 155.51% | 2.226 | `` |
| 128 | `block` | 1.6624e+03 | Inf | 9232.00% | 0.068 | `` |
| 129 | `block` | 1.6624e+03 | Inf | 9916.94% | 0.065 | `` |
| 130 | `block` | 7.0296e+04 | 6.7643e+04 | 896823.07% | 0.725 | `` |
| 131 | `block` | 7.0296e+04 | Inf | 896833.56% | 0.050 | `` |

