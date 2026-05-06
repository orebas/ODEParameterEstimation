# Tryhard Finalist Benchmark Case: daisy_mamil4_6_1em4

- Model: `daisy_mamil4`
- Role: `guard`
- Selected via: `requested`
- Generated: `2026-04-15T02:59:00.542`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/daisy_mamil4_6_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/daisy_mamil4_6_1em4`

## Comparison-Table Reference

- Classification: `both_success`
- Comparison CSV ODEPE mean/max relative error: 0.70% / 2.79%
- Comparison CSV ODEPE runtime: 4366.978 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 119 | 810.29% | k13 (2671.29%) | 3.5657e-03 |
| `odepe_polish` | 351 | 0.53% | x4(0) (1.17%) | 8.0542e-06 |

## Imported Raw Pool

- Raw imported candidates: 119
- Best raw fit index: 116
- Best raw oracle index: 114
- Best-fit vs best-truth combined-RMSE gap: 762.26%

## Local Tryhard Runtime

- Reference CSV load/scoring: 3.413 s
- Consensus/block context: 37.446 s
- 4x4 baseline evidence report: 40.231 s
- 4x4 block no-polish report: 6.283 s
- Polish context build: 0.008 s
- Baseline-only finalists: 1248.141 s
- Additive-only finalists: 1385.534 s
- Reasonable frontier finalists: 1600.027 s
- Local total (excluding reference load): 4889.296 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 810.29% | 810.29% | 119 | `raw` | 3.5657e-03 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 0.53% | 0.53% | 351 | `benchmark` | 8.0542e-06 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 44.28% | 44.28% | 143 | `block` | 3.5886e+00 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.77% | 0.77% | 15 | `baseline` | 8.0251e-06 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.77% | 0.77% | 29 | `block+branch+synthesized` | 8.0251e-06 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.77% | 0.77% | 29 | `baseline+block+branch+synthesized` | 8.0251e-06 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `benchmark_polish_better`
- Improvement mode: `no_improvement`
- Baseline best finalist index / RMSE: 1 / 0.77%
- Additive best finalist index / RMSE: 1 / 0.77%
- Frontier best finalist index / RMSE: 1 / 0.77%
- Baseline preserved seeds: 119
- Additive candidate seeds: 143
- Frontier admitted seeds: 179
- Rejected additive seeds: 83
- Successful merged polished seeds: 179
- Post-polish basin metric: `trajectory_hybrid`
- Pre-polish distinctness threshold: 0.0010
- Post-polish trajectory threshold: 0.0200
- Post-polish secondary threshold: 1.0000
- Post-polish basin threshold: 0.0030
- Admitted additive by family: block=20, branch=36, synthesized=4
- Rejected additive by reason/family: soft_cap/branch=83
- Merge mode counts: trajectory_hybrid=150
- Basin histogram: singletons=24, multi=5, largest=141
- Returned merged finalists: 29

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 1.1364e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 1.1364e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 7.8295e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 7.8295e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 8.6557e+04 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 7.4720e+04 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 7.4720e+04 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.0384e+04 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 1.0335e+04 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 1.0335e+04 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 7.2225e+03 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 7.2225e+03 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 1.3658e+03 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 1.3658e+03 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 6.6678e+02 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 6.6678e+02 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 2.7709e+02 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 2.2199e+02 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 2.1928e+02 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 2.0627e+02 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 5.4059e+01 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 5.4059e+01 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 3.2935e+01 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 1.9805e+01 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 1.9805e+01 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 1.5781e+01 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 1.5781e+01 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 9.2118e+00 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 9.2118e+00 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 6.1286e+00 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 6.1286e+00 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 5.2768e+00 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 5.2768e+00 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 3.6248e+00 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 3.6248e+00 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 2.7378e+00 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 2.7378e+00 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 2.1846e+00 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 2.1846e+00 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 1.8189e+00 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 1.8189e+00 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 2.0623e+00 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 2.0623e+00 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 1.7842e+00 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 1.7842e+00 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 1.7110e+00 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 1.7110e+00 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 1.6972e+00 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 1.6972e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 1.6272e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 1.6272e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 1.3869e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | 1.3869e+00 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | 1.6208e+00 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 1.6208e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 1.5361e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 1.5361e+00 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 1.2315e+00 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 1.2315e+00 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 1.4098e+00 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 1.4098e+00 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 1.3869e+00 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 1.3869e+00 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 1.3950e+00 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 1.3950e+00 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 1.3364e+00 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 1.3364e+00 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 1.2423e+00 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 1.2897e+00 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 1.2897e+00 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 1.2177e+00 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 1.2177e+00 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 73 | 1.0164e+00 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | 74 | 1.0164e+00 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | 75 | 1.1237e+00 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | 76 | 1.1237e+00 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | 77 | 1.0084e+00 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | 78 | 1.0084e+00 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | 79 | 9.9340e-01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | 80 | 9.9340e-01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | 81 | 8.4889e-01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | 82 | 8.4889e-01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | 83 | 8.9415e-01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | 84 | 8.9415e-01 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | 85 | 8.1955e-01 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | 86 | 8.1955e-01 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | 87 | 4.8580e-01 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | 88 | 4.8580e-01 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | 89 | 3.8334e-01 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | 90 | 3.8334e-01 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | 91 | 2.9452e-01 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | 92 | 2.9452e-01 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | 93 | 3.5980e-01 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | 94 | 3.5980e-01 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | 95 | 1.8501e-01 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | 96 | 1.8501e-01 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | 97 | 1.1021e-01 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | 98 | 1.1021e-01 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | 99 | 1.0405e-01 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | 100 | 1.0405e-01 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | 101 | 9.2294e-02 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | 102 | 9.2294e-02 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | 103 | 6.4956e-02 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | 104 | 6.4956e-02 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | 105 | 3.6356e-02 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | 106 | 3.6356e-02 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | 107 | 3.5696e-02 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | 108 | 3.5696e-02 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | 109 | 2.3833e-02 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | 110 | 2.3833e-02 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | 111 | 1.4144e-02 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | 112 | 1.2209e-02 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | 113 | 1.2209e-02 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | 114 | 1.2143e-02 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | 115 | 1.2143e-02 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | 116 | 3.5657e-03 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | 117 | 3.5657e-03 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | 118 | 4.3734e-03 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | 119 | 4.3734e-03 | method=algebraic, source=imported, candidate=119 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 3.5886e+00 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0148 | 4.2436e+01 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.0158 | 5.7397e+01 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.0162 | 6.1399e+01 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.0171 | 8.1316e+01 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.0479 | 8.9735e+05 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.0479 | 9.0519e+05 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.0522 | 2.2068e+06 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.0526 | 9.5156e+05 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.7417 | 2.9929e+80 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.7486 | 1.6515e+81 | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.8405 | Inf | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.8411 | Inf | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.8416 | Inf | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 0.8422 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 0.8422 | Inf | method=direct_opt, source=assembled |
| 17 | `block` | 17 | 0.8444 | Inf | method=direct_opt, source=assembled |
| 18 | `block` | 18 | 0.8478 | Inf | method=direct_opt, source=assembled |
| 19 | `block` | 19 | 0.8480 | Inf | method=direct_opt, source=assembled |
| 20 | `block` | 20 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 1 | `branch` | 1 | 0.6217 | 1.2209e-02 | method=direct_opt, source=synthesized, candidate=112, polished=true |
| 2 | `branch` | 2 | 0.6194 | 1.2407e-04 | method=direct_opt, source=synthesized, candidate=107, polished=true |
| 3 | `branch` | 3 | 0.6182 | 5.5241e-04 | method=direct_opt, source=synthesized, candidate=100, polished=true |
| 4 | `branch` | 4 | 0.6170 | 1.2209e-02 | method=algebraic, source=imported, candidate=113 |
| 5 | `branch` | 5 | 0.6169 | 1.2143e-02 | method=algebraic, source=imported, candidate=115 |
| 6 | `branch` | 6 | 0.6167 | 1.0405e-01 | method=algebraic, source=imported, candidate=99 |
| 7 | `branch` | 7 | 0.6150 | 9.2294e-02 | method=algebraic, source=imported, candidate=101 |
| 8 | `branch` | 8 | 0.6148 | 3.5696e-02 | method=algebraic, source=imported, candidate=108 |
| 9 | `branch` | 9 | 0.6137 | 9.2294e-02 | method=algebraic, source=imported, candidate=102 |
| 10 | `branch` | 10 | 0.6130 | 1.2143e-02 | method=algebraic, source=imported, candidate=114 |
| 11 | `branch` | 11 | 0.6054 | 1.4144e-02 | method=algebraic, source=imported, candidate=111 |
| 12 | `branch` | 12 | 0.6046 | 1.1021e-01 | method=algebraic, source=imported, candidate=98 |
| 13 | `branch` | 13 | 0.6016 | 3.5980e-01 | method=algebraic, source=imported, candidate=93 |
| 14 | `branch` | 14 | 0.6007 | 1.1021e-01 | method=algebraic, source=imported, candidate=97 |
| 15 | `branch` | 15 | 0.5992 | 3.5980e-01 | method=algebraic, source=imported, candidate=94 |
| 16 | `branch` | 16 | 0.5960 | 3.5657e-03 | method=algebraic, source=imported, candidate=116 |
| 17 | `branch` | 17 | 0.5940 | 3.5657e-03 | method=algebraic, source=imported, candidate=117 |
| 18 | `branch` | 18 | 0.5780 | 8.1955e-01 | method=algebraic, source=imported, candidate=86 |
| 19 | `branch` | 19 | 0.5779 | 9.9340e-01 | method=algebraic, source=imported, candidate=80 |
| 20 | `branch` | 20 | 0.5775 | 8.4889e-01 | method=algebraic, source=imported, candidate=81 |
| 21 | `branch` | 21 | 0.5731 | 8.1955e-01 | method=algebraic, source=imported, candidate=85 |
| 22 | `branch` | 22 | 0.5726 | 8.4889e-01 | method=algebraic, source=imported, candidate=82 |
| 23 | `branch` | 23 | 0.5718 | 1.1237e+00 | method=algebraic, source=imported, candidate=76 |
| 24 | `branch` | 24 | 0.5716 | 1.0084e+00 | method=algebraic, source=imported, candidate=77 |
| 25 | `branch` | 25 | 0.5715 | 9.9340e-01 | method=algebraic, source=imported, candidate=79 |
| 26 | `branch` | 26 | 0.5704 | 1.1237e+00 | method=algebraic, source=imported, candidate=75 |
| 27 | `branch` | 27 | 0.5696 | 2.9452e-01 | method=algebraic, source=imported, candidate=92 |
| 28 | `branch` | 28 | 0.5691 | 2.9452e-01 | method=algebraic, source=imported, candidate=91 |
| 29 | `branch` | 29 | 0.5679 | 1.0084e+00 | method=algebraic, source=imported, candidate=78 |
| 30 | `branch` | 30 | 0.5667 | 1.2177e+00 | method=algebraic, source=imported, candidate=71 |
| 31 | `branch` | 31 | 0.5655 | 1.2177e+00 | method=algebraic, source=imported, candidate=72 |
| 32 | `branch` | 32 | 0.5602 | 1.0164e+00 | method=algebraic, source=imported, candidate=73 |
| 33 | `branch` | 33 | 0.5601 | 2.1846e+00 | method=algebraic, source=imported, candidate=39 |
| 34 | `branch` | 34 | 0.5592 | 1.0164e+00 | method=algebraic, source=imported, candidate=74 |
| 35 | `branch` | 35 | 0.5589 | 2.1846e+00 | method=algebraic, source=imported, candidate=38 |
| 36 | `branch` | 36 | 0.5492 | 1.9805e+01 | method=algebraic, source=imported, candidate=24 |
| 37 | `branch` | 37 | 0.5456 | 1.2897e+00 | method=algebraic, source=imported, candidate=70 |
| 38 | `branch` | 38 | 0.5446 | 1.9805e+01 | method=algebraic, source=imported, candidate=25 |
| 39 | `branch` | 39 | 0.5431 | 1.2897e+00 | method=algebraic, source=imported, candidate=69 |
| 40 | `branch` | 40 | 0.5278 | 4.8580e-01 | method=algebraic, source=imported, candidate=87 |
| 41 | `branch` | 41 | 0.5241 | 4.8580e-01 | method=algebraic, source=imported, candidate=88 |
| 42 | `branch` | 42 | 0.5218 | 1.6272e+00 | method=algebraic, source=imported, candidate=50 |
| 43 | `branch` | 43 | 0.5214 | 1.3869e+00 | method=algebraic, source=imported, candidate=53 |
| 44 | `branch` | 44 | 0.5206 | 1.6272e+00 | method=algebraic, source=imported, candidate=51 |
| 45 | `branch` | 45 | 0.5201 | 1.3869e+00 | method=algebraic, source=imported, candidate=52 |
| 46 | `branch` | 46 | 0.5191 | 1.5361e+00 | method=algebraic, source=imported, candidate=56 |
| 47 | `branch` | 47 | 0.5169 | 1.5361e+00 | method=algebraic, source=imported, candidate=57 |
| 48 | `branch` | 48 | 0.5122 | 1.6208e+00 | method=algebraic, source=imported, candidate=55 |
| 49 | `branch` | 49 | 0.5120 | 1.7842e+00 | method=algebraic, source=imported, candidate=45 |
| 50 | `branch` | 50 | 0.5118 | 1.7110e+00 | method=algebraic, source=imported, candidate=46 |
| 51 | `branch` | 51 | 0.5096 | 1.7110e+00 | method=algebraic, source=imported, candidate=47 |
| 52 | `branch` | 52 | 0.5089 | 1.6972e+00 | method=algebraic, source=imported, candidate=48 |
| 53 | `branch` | 53 | 0.5083 | 1.6208e+00 | method=algebraic, source=imported, candidate=54 |
| 54 | `branch` | 54 | 0.5081 | 1.7842e+00 | method=algebraic, source=imported, candidate=44 |
| 55 | `branch` | 55 | 0.5076 | 1.6972e+00 | method=algebraic, source=imported, candidate=49 |
| 56 | `branch` | 56 | 0.4972 | 8.9415e-01 | method=algebraic, source=imported, candidate=84 |
| 57 | `branch` | 57 | 0.4954 | 1.2315e+00 | method=algebraic, source=imported, candidate=59 |
| 58 | `branch` | 58 | 0.4933 | 8.9415e-01 | method=algebraic, source=imported, candidate=83 |
| 59 | `branch` | 59 | 0.4918 | 9.2118e+00 | method=algebraic, source=imported, candidate=29 |
| 60 | `branch` | 60 | 0.4915 | 1.2315e+00 | method=algebraic, source=imported, candidate=58 |
| 61 | `branch` | 61 | 0.4914 | 2.7378e+00 | method=algebraic, source=imported, candidate=37 |
| 62 | `branch` | 62 | 0.4904 | 5.2768e+00 | method=algebraic, source=imported, candidate=32 |
| 63 | `branch` | 63 | 0.4903 | 9.2118e+00 | method=algebraic, source=imported, candidate=28 |
| 64 | `branch` | 64 | 0.4899 | 2.7378e+00 | method=algebraic, source=imported, candidate=36 |
| 65 | `branch` | 65 | 0.4899 | 6.4956e-02 | method=algebraic, source=imported, candidate=103 |
| 66 | `branch` | 66 | 0.4879 | 5.2768e+00 | method=algebraic, source=imported, candidate=33 |
| 67 | `branch` | 67 | 0.4827 | 6.4956e-02 | method=algebraic, source=imported, candidate=104 |
| 68 | `branch` | 68 | 0.4750 | 3.6356e-02 | method=algebraic, source=imported, candidate=106 |
| 69 | `branch` | 69 | 0.4688 | 1.8189e+00 | method=algebraic, source=imported, candidate=41 |
| 70 | `branch` | 70 | 0.4677 | 6.6678e+02 | method=algebraic, source=imported, candidate=16 |
| 71 | `branch` | 71 | 0.4638 | 6.6678e+02 | method=algebraic, source=imported, candidate=15 |
| 72 | `branch` | 72 | 0.4619 | 2.3833e-02 | method=algebraic, source=imported, candidate=109 |
| 73 | `branch` | 73 | 0.4603 | 1.2423e+00 | method=algebraic, source=imported, candidate=68 |
| 74 | `branch` | 74 | 0.4586 | 3.6356e-02 | method=algebraic, source=imported, candidate=105 |
| 75 | `branch` | 75 | 0.4538 | 1.8189e+00 | method=algebraic, source=imported, candidate=40 |
| 76 | `branch` | 76 | 0.4527 | 1.3364e+00 | method=algebraic, source=imported, candidate=67 |
| 77 | `branch` | 77 | 0.4521 | 1.4098e+00 | method=algebraic, source=imported, candidate=60 |
| 78 | `branch` | 78 | 0.4515 | 1.3364e+00 | method=algebraic, source=imported, candidate=66 |
| 79 | `branch` | 79 | 0.4512 | 1.3950e+00 | method=algebraic, source=imported, candidate=64 |
| 80 | `branch` | 80 | 0.4484 | 2.3833e-02 | method=algebraic, source=imported, candidate=110 |
| 81 | `branch` | 81 | 0.4479 | 3.8334e-01 | method=algebraic, source=imported, candidate=90 |
| 82 | `branch` | 82 | 0.4475 | 3.8334e-01 | method=algebraic, source=imported, candidate=89 |
| 83 | `branch` | 83 | 0.4443 | 1.3869e+00 | method=algebraic, source=imported, candidate=62 |
| 84 | `branch` | 84 | 0.4436 | 4.3734e-03 | method=algebraic, source=imported, candidate=119 |
| 85 | `branch` | 85 | 0.4428 | 1.3950e+00 | method=algebraic, source=imported, candidate=65 |
| 86 | `branch` | 86 | 0.4410 | 1.4098e+00 | method=algebraic, source=imported, candidate=61 |
| 87 | `branch` | 87 | 0.4407 | 4.3734e-03 | method=algebraic, source=imported, candidate=118 |
| 88 | `branch` | 88 | 0.4406 | 1.3869e+00 | method=algebraic, source=imported, candidate=63 |
| 89 | `branch` | 89 | 0.4212 | 1.8501e-01 | method=algebraic, source=imported, candidate=96 |
| 90 | `branch` | 90 | 0.4173 | 1.8501e-01 | method=algebraic, source=imported, candidate=95 |
| 91 | `branch` | 91 | 0.4044 | 1.3658e+03 | method=algebraic, source=imported, candidate=13 |
| 92 | `branch` | 92 | 0.4009 | 1.3658e+03 | method=algebraic, source=imported, candidate=14 |
| 93 | `branch` | 93 | 0.3838 | 1.1364e+06 | method=algebraic, source=imported, candidate=1 |
| 94 | `branch` | 94 | 0.3803 | 1.1364e+06 | method=algebraic, source=imported, candidate=2 |
| 95 | `branch` | 95 | 0.3644 | 7.4720e+04 | method=algebraic, source=imported, candidate=6 |
| 96 | `branch` | 96 | 0.3636 | 6.1286e+00 | method=algebraic, source=imported, candidate=31 |
| 97 | `branch` | 97 | 0.3634 | 7.4720e+04 | method=algebraic, source=imported, candidate=7 |
| 98 | `branch` | 98 | 0.3566 | 2.0623e+00 | method=algebraic, source=imported, candidate=42 |
| 99 | `branch` | 99 | 0.3553 | 2.0623e+00 | method=algebraic, source=imported, candidate=43 |
| 100 | `branch` | 100 | 0.3549 | 7.8295e+05 | method=algebraic, source=imported, candidate=4 |
| 101 | `branch` | 101 | 0.3535 | 6.1286e+00 | method=algebraic, source=imported, candidate=30 |
| 102 | `branch` | 102 | 0.3535 | 7.8295e+05 | method=algebraic, source=imported, candidate=3 |
| 103 | `branch` | 103 | 0.3478 | 3.6248e+00 | method=algebraic, source=imported, candidate=34 |
| 104 | `branch` | 104 | 0.3460 | 5.4059e+01 | method=algebraic, source=imported, candidate=22 |
| 105 | `branch` | 105 | 0.3458 | 3.6248e+00 | method=algebraic, source=imported, candidate=35 |
| 106 | `branch` | 106 | 0.3421 | 5.4059e+01 | method=algebraic, source=imported, candidate=21 |
| 107 | `branch` | 107 | 0.3261 | 2.0627e+02 | method=algebraic, source=imported, candidate=20 |
| 108 | `branch` | 108 | 0.3246 | 2.1928e+02 | method=algebraic, source=imported, candidate=19 |
| 109 | `branch` | 109 | 0.3232 | 2.2199e+02 | method=algebraic, source=imported, candidate=18 |
| 110 | `branch` | 110 | 0.3230 | 3.2935e+01 | method=algebraic, source=imported, candidate=23 |
| 111 | `branch` | 111 | 0.3204 | 2.7709e+02 | method=algebraic, source=imported, candidate=17 |
| 112 | `branch` | 112 | 0.3147 | 2.0384e+04 | method=algebraic, source=imported, candidate=8 |
| 113 | `branch` | 113 | 0.3128 | 1.0335e+04 | method=algebraic, source=imported, candidate=9 |
| 114 | `branch` | 114 | 0.3091 | 1.0335e+04 | method=algebraic, source=imported, candidate=10 |
| 115 | `branch` | 115 | 0.3084 | 1.5781e+01 | method=algebraic, source=imported, candidate=27 |
| 116 | `branch` | 116 | 0.3032 | 1.5781e+01 | method=algebraic, source=imported, candidate=26 |
| 117 | `branch` | 117 | 0.2989 | 8.6557e+04 | method=algebraic, source=imported, candidate=5 |
| 118 | `branch` | 118 | 0.2783 | 7.2225e+03 | method=algebraic, source=imported, candidate=12 |
| 119 | `branch` | 119 | 0.2744 | 7.2225e+03 | method=algebraic, source=imported, candidate=11 |
| 1 | `synthesized` | 1 | 0.0001 | 1.2842e-04 | method=direct_opt, source=synthesized, polished=true |
| 2 | `synthesized` | 2 | 0.0001 | 1.2431e-04 | method=direct_opt, source=synthesized, polished=true |
| 3 | `synthesized` | 3 | 0.0002 | 1.6147e-04 | method=direct_opt, source=synthesized, polished=true |
| 4 | `synthesized` | 4 | 0.0001 | 1.4024e-04 | method=direct_opt, source=synthesized, polished=true |

## Rejected Additive Seeds

| Rank | Sources | Reason | Dist | New Families | Fit Error | Lineage |
|------|---------|--------|------|--------------|-----------|---------|
| 1 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.2897e+00 | method=algebraic, source=imported, candidate=70 |
| 2 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.9805e+01 | method=algebraic, source=imported, candidate=25 |
| 3 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.2897e+00 | method=algebraic, source=imported, candidate=69 |
| 4 | `branch` | `soft_cap` | 0.0000 | `branch` | 4.8580e-01 | method=algebraic, source=imported, candidate=87 |
| 5 | `branch` | `soft_cap` | 0.0000 | `branch` | 4.8580e-01 | method=algebraic, source=imported, candidate=88 |
| 6 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6272e+00 | method=algebraic, source=imported, candidate=50 |
| 7 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3869e+00 | method=algebraic, source=imported, candidate=53 |
| 8 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6272e+00 | method=algebraic, source=imported, candidate=51 |
| 9 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3869e+00 | method=algebraic, source=imported, candidate=52 |
| 10 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.5361e+00 | method=algebraic, source=imported, candidate=56 |
| 11 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.5361e+00 | method=algebraic, source=imported, candidate=57 |
| 12 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6208e+00 | method=algebraic, source=imported, candidate=55 |
| 13 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.7842e+00 | method=algebraic, source=imported, candidate=45 |
| 14 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.7110e+00 | method=algebraic, source=imported, candidate=46 |
| 15 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.7110e+00 | method=algebraic, source=imported, candidate=47 |
| 16 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6972e+00 | method=algebraic, source=imported, candidate=48 |
| 17 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6208e+00 | method=algebraic, source=imported, candidate=54 |
| 18 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.7842e+00 | method=algebraic, source=imported, candidate=44 |
| 19 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.6972e+00 | method=algebraic, source=imported, candidate=49 |
| 20 | `branch` | `soft_cap` | 0.0000 | `branch` | 8.9415e-01 | method=algebraic, source=imported, candidate=84 |
| 21 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.2315e+00 | method=algebraic, source=imported, candidate=59 |
| 22 | `branch` | `soft_cap` | 0.0000 | `branch` | 8.9415e-01 | method=algebraic, source=imported, candidate=83 |
| 23 | `branch` | `soft_cap` | 0.0000 | `branch` | 9.2118e+00 | method=algebraic, source=imported, candidate=29 |
| 24 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.2315e+00 | method=algebraic, source=imported, candidate=58 |
| 25 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.7378e+00 | method=algebraic, source=imported, candidate=37 |
| 26 | `branch` | `soft_cap` | 0.0000 | `branch` | 5.2768e+00 | method=algebraic, source=imported, candidate=32 |
| 27 | `branch` | `soft_cap` | 0.0000 | `branch` | 9.2118e+00 | method=algebraic, source=imported, candidate=28 |
| 28 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.7378e+00 | method=algebraic, source=imported, candidate=36 |
| 29 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.4956e-02 | method=algebraic, source=imported, candidate=103 |
| 30 | `branch` | `soft_cap` | 0.0000 | `branch` | 5.2768e+00 | method=algebraic, source=imported, candidate=33 |
| 31 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.4956e-02 | method=algebraic, source=imported, candidate=104 |
| 32 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.6356e-02 | method=algebraic, source=imported, candidate=106 |
| 33 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.8189e+00 | method=algebraic, source=imported, candidate=41 |
| 34 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.6678e+02 | method=algebraic, source=imported, candidate=16 |
| 35 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.6678e+02 | method=algebraic, source=imported, candidate=15 |
| 36 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.3833e-02 | method=algebraic, source=imported, candidate=109 |
| 37 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.2423e+00 | method=algebraic, source=imported, candidate=68 |
| 38 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.6356e-02 | method=algebraic, source=imported, candidate=105 |
| 39 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.8189e+00 | method=algebraic, source=imported, candidate=40 |
| 40 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3364e+00 | method=algebraic, source=imported, candidate=67 |
| 41 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.4098e+00 | method=algebraic, source=imported, candidate=60 |
| 42 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3364e+00 | method=algebraic, source=imported, candidate=66 |
| 43 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3950e+00 | method=algebraic, source=imported, candidate=64 |
| 44 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.3833e-02 | method=algebraic, source=imported, candidate=110 |
| 45 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.8334e-01 | method=algebraic, source=imported, candidate=90 |
| 46 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.8334e-01 | method=algebraic, source=imported, candidate=89 |
| 47 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3869e+00 | method=algebraic, source=imported, candidate=62 |
| 48 | `branch` | `soft_cap` | 0.0000 | `branch` | 4.3734e-03 | method=algebraic, source=imported, candidate=119 |
| 49 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3950e+00 | method=algebraic, source=imported, candidate=65 |
| 50 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.4098e+00 | method=algebraic, source=imported, candidate=61 |
| 51 | `branch` | `soft_cap` | 0.0000 | `branch` | 4.3734e-03 | method=algebraic, source=imported, candidate=118 |
| 52 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3869e+00 | method=algebraic, source=imported, candidate=63 |
| 53 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.8501e-01 | method=algebraic, source=imported, candidate=96 |
| 54 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.8501e-01 | method=algebraic, source=imported, candidate=95 |
| 55 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3658e+03 | method=algebraic, source=imported, candidate=13 |
| 56 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.3658e+03 | method=algebraic, source=imported, candidate=14 |
| 57 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.1364e+06 | method=algebraic, source=imported, candidate=1 |
| 58 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.1364e+06 | method=algebraic, source=imported, candidate=2 |
| 59 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.4720e+04 | method=algebraic, source=imported, candidate=6 |
| 60 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.1286e+00 | method=algebraic, source=imported, candidate=31 |
| 61 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.4720e+04 | method=algebraic, source=imported, candidate=7 |
| 62 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.0623e+00 | method=algebraic, source=imported, candidate=42 |
| 63 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.0623e+00 | method=algebraic, source=imported, candidate=43 |
| 64 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.8295e+05 | method=algebraic, source=imported, candidate=4 |
| 65 | `branch` | `soft_cap` | 0.0000 | `branch` | 6.1286e+00 | method=algebraic, source=imported, candidate=30 |
| 66 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.8295e+05 | method=algebraic, source=imported, candidate=3 |
| 67 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.6248e+00 | method=algebraic, source=imported, candidate=34 |
| 68 | `branch` | `soft_cap` | 0.0000 | `branch` | 5.4059e+01 | method=algebraic, source=imported, candidate=22 |
| 69 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.6248e+00 | method=algebraic, source=imported, candidate=35 |
| 70 | `branch` | `soft_cap` | 0.0000 | `branch` | 5.4059e+01 | method=algebraic, source=imported, candidate=21 |
| 71 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.0627e+02 | method=algebraic, source=imported, candidate=20 |
| 72 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.1928e+02 | method=algebraic, source=imported, candidate=19 |
| 73 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.2199e+02 | method=algebraic, source=imported, candidate=18 |
| 74 | `branch` | `soft_cap` | 0.0000 | `branch` | 3.2935e+01 | method=algebraic, source=imported, candidate=23 |
| 75 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.7709e+02 | method=algebraic, source=imported, candidate=17 |
| 76 | `branch` | `soft_cap` | 0.0000 | `branch` | 2.0384e+04 | method=algebraic, source=imported, candidate=8 |
| 77 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.0335e+04 | method=algebraic, source=imported, candidate=9 |
| 78 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.0335e+04 | method=algebraic, source=imported, candidate=10 |
| 79 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.5781e+01 | method=algebraic, source=imported, candidate=27 |
| 80 | `branch` | `soft_cap` | 0.0000 | `branch` | 1.5781e+01 | method=algebraic, source=imported, candidate=26 |
| 81 | `branch` | `soft_cap` | 0.0000 | `branch` | 8.6557e+04 | method=algebraic, source=imported, candidate=5 |
| 82 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.2225e+03 | method=algebraic, source=imported, candidate=12 |
| 83 | `branch` | `soft_cap` | 0.0000 | `branch` | 7.2225e+03 | method=algebraic, source=imported, candidate=11 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 1.1364e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 1.1364e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 7.8295e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 7.8295e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 8.6557e+04 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 7.4720e+04 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 7.4720e+04 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.0384e+04 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 1.0335e+04 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 1.0335e+04 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 7.2225e+03 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 7.2225e+03 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 1.3658e+03 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 1.3658e+03 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 6.6678e+02 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 6.6678e+02 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 2.7709e+02 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 2.2199e+02 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 2.1928e+02 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 2.0627e+02 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 5.4059e+01 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 5.4059e+01 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 3.2935e+01 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 1.9805e+01 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 1.9805e+01 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 1.5781e+01 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 1.5781e+01 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 9.2118e+00 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 9.2118e+00 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 6.1286e+00 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 6.1286e+00 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 5.2768e+00 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 5.2768e+00 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 3.6248e+00 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 3.6248e+00 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 2.7378e+00 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 2.7378e+00 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 2.1846e+00 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 2.1846e+00 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 1.8189e+00 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 1.8189e+00 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 2.0623e+00 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 2.0623e+00 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 1.7842e+00 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 1.7842e+00 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 1.7110e+00 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 1.7110e+00 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 1.6972e+00 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 1.6972e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 1.6272e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 1.6272e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 1.3869e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | 1.3869e+00 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | 1.6208e+00 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 1.6208e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 1.5361e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 1.5361e+00 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 1.2315e+00 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 1.2315e+00 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 1.4098e+00 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 1.4098e+00 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 1.3869e+00 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 1.3869e+00 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 1.3950e+00 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 1.3950e+00 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 1.3364e+00 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 1.3364e+00 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 1.2423e+00 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 1.2897e+00 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 1.2897e+00 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 1.2177e+00 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 1.2177e+00 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#73` | 1.0164e+00 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | `baseline#74` | 1.0164e+00 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | `baseline#75` | 1.1237e+00 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | `baseline#76` | 1.1237e+00 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | `baseline#77` | 1.0084e+00 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | `baseline#78` | 1.0084e+00 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | `baseline#79` | 9.9340e-01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | `baseline#80` | 9.9340e-01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | `baseline#81` | 8.4889e-01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | `baseline#82` | 8.4889e-01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | `baseline#83` | 8.9415e-01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | `baseline#84` | 8.9415e-01 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | `baseline#85` | 8.1955e-01 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | `baseline#86` | 8.1955e-01 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | `baseline#87` | 4.8580e-01 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | `baseline#88` | 4.8580e-01 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | `baseline#89` | 3.8334e-01 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | `baseline#90` | 3.8334e-01 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | `baseline#91` | 2.9452e-01 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | `baseline#92` | 2.9452e-01 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | `baseline#93` | 3.5980e-01 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | `baseline#94` | 3.5980e-01 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | `baseline#95` | 1.8501e-01 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | `baseline#96` | 1.8501e-01 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | `baseline#97` | 1.1021e-01 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | `baseline#98` | 1.1021e-01 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | `baseline#99` | 1.0405e-01 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | `baseline#100` | 1.0405e-01 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | `baseline#101` | 9.2294e-02 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | `baseline#102` | 9.2294e-02 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | `baseline#103` | 6.4956e-02 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | `baseline#104` | 6.4956e-02 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | `baseline#105` | 3.6356e-02 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | `baseline#106` | 3.6356e-02 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | `baseline#107` | 3.5696e-02 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | `baseline#108` | 3.5696e-02 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | `baseline#109` | 2.3833e-02 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | `baseline#110` | 2.3833e-02 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | `baseline#111` | 1.4144e-02 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | `baseline#112` | 1.2209e-02 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | `baseline#113` | 1.2209e-02 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | `baseline#114` | 1.2143e-02 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | `baseline#115` | 1.2143e-02 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | `baseline#116` | 3.5657e-03 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | `baseline#117` | 3.5657e-03 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | `baseline#118` | 4.3734e-03 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | `baseline#119` | 4.3734e-03 | method=algebraic, source=imported, candidate=119 |
| 120 | `block` | `block#9` | 9.5156e+05 | method=direct_opt, source=assembled |
| 121 | `branch` | `branch#3` | 5.5241e-04 | method=direct_opt, source=synthesized, candidate=100, polished=true |
| 122 | `synthesized` | `synthesized#2` | 1.2431e-04 | method=direct_opt, source=synthesized, polished=true |
| 123 | `block` | `block#14` | Inf | method=direct_opt, source=assembled |
| 124 | `block` | `block#16` | Inf | method=direct_opt, source=assembled |
| 125 | `block` | `block#7` | 9.0519e+05 | method=direct_opt, source=assembled |
| 126 | `block` | `block#8` | 2.2068e+06 | method=direct_opt, source=assembled |
| 127 | `block` | `block#19` | Inf | method=direct_opt, source=assembled |
| 128 | `block` | `block#18` | Inf | method=direct_opt, source=assembled |
| 129 | `block` | `block#20` | Inf | method=direct_opt, source=assembled |
| 130 | `block` | `block#17` | Inf | method=direct_opt, source=assembled |
| 131 | `block` | `block#6` | 8.9735e+05 | method=direct_opt, source=assembled |
| 132 | `block` | `block#10` | 2.9929e+80 | method=direct_opt, source=assembled |
| 133 | `block` | `block#11` | 1.6515e+81 | method=direct_opt, source=assembled |
| 134 | `block` | `block#15` | Inf | method=direct_opt, source=assembled |
| 135 | `block` | `block#13` | Inf | method=direct_opt, source=assembled |
| 136 | `block` | `block#12` | Inf | method=direct_opt, source=assembled |
| 137 | `block` | `block#2` | 4.2436e+01 | method=direct_opt, source=assembled |
| 138 | `block` | `block#4` | 6.1399e+01 | method=direct_opt, source=assembled |
| 139 | `block` | `block#5` | 8.1316e+01 | method=direct_opt, source=assembled |
| 140 | `block` | `block#3` | 5.7397e+01 | method=direct_opt, source=assembled |
| 141 | `block` | `block#1` | 3.5886e+00 | method=direct_opt, source=assembled |
| 142 | `synthesized` | `synthesized#3` | 1.6147e-04 | method=direct_opt, source=synthesized, polished=true |
| 143 | `synthesized` | `synthesized#4` | 1.4024e-04 | method=direct_opt, source=synthesized, polished=true |
| 144 | `synthesized` | `synthesized#1` | 1.2842e-04 | method=direct_opt, source=synthesized, polished=true |
| 145 | `branch` | `branch#2` | 1.2407e-04 | method=direct_opt, source=synthesized, candidate=107, polished=true |
| 146 | `branch` | `branch#1` | 1.2209e-02 | method=direct_opt, source=synthesized, candidate=112, polished=true |
| 147 | `branch` | `branch#4` | 1.2209e-02 | method=algebraic, source=imported, candidate=113 |
| 148 | `branch` | `branch#5` | 1.2143e-02 | method=algebraic, source=imported, candidate=115 |
| 149 | `branch` | `branch#6` | 1.0405e-01 | method=algebraic, source=imported, candidate=99 |
| 150 | `branch` | `branch#7` | 9.2294e-02 | method=algebraic, source=imported, candidate=101 |
| 151 | `branch` | `branch#8` | 3.5696e-02 | method=algebraic, source=imported, candidate=108 |
| 152 | `branch` | `branch#9` | 9.2294e-02 | method=algebraic, source=imported, candidate=102 |
| 153 | `branch` | `branch#10` | 1.2143e-02 | method=algebraic, source=imported, candidate=114 |
| 154 | `branch` | `branch#11` | 1.4144e-02 | method=algebraic, source=imported, candidate=111 |
| 155 | `branch` | `branch#12` | 1.1021e-01 | method=algebraic, source=imported, candidate=98 |
| 156 | `branch` | `branch#13` | 3.5980e-01 | method=algebraic, source=imported, candidate=93 |
| 157 | `branch` | `branch#14` | 1.1021e-01 | method=algebraic, source=imported, candidate=97 |
| 158 | `branch` | `branch#15` | 3.5980e-01 | method=algebraic, source=imported, candidate=94 |
| 159 | `branch` | `branch#16` | 3.5657e-03 | method=algebraic, source=imported, candidate=116 |
| 160 | `branch` | `branch#17` | 3.5657e-03 | method=algebraic, source=imported, candidate=117 |
| 161 | `branch` | `branch#18` | 8.1955e-01 | method=algebraic, source=imported, candidate=86 |
| 162 | `branch` | `branch#19` | 9.9340e-01 | method=algebraic, source=imported, candidate=80 |
| 163 | `branch` | `branch#20` | 8.4889e-01 | method=algebraic, source=imported, candidate=81 |
| 164 | `branch` | `branch#21` | 8.1955e-01 | method=algebraic, source=imported, candidate=85 |
| 165 | `branch` | `branch#22` | 8.4889e-01 | method=algebraic, source=imported, candidate=82 |
| 166 | `branch` | `branch#23` | 1.1237e+00 | method=algebraic, source=imported, candidate=76 |
| 167 | `branch` | `branch#24` | 1.0084e+00 | method=algebraic, source=imported, candidate=77 |
| 168 | `branch` | `branch#25` | 9.9340e-01 | method=algebraic, source=imported, candidate=79 |
| 169 | `branch` | `branch#26` | 1.1237e+00 | method=algebraic, source=imported, candidate=75 |
| 170 | `branch` | `branch#27` | 2.9452e-01 | method=algebraic, source=imported, candidate=92 |
| 171 | `branch` | `branch#28` | 2.9452e-01 | method=algebraic, source=imported, candidate=91 |
| 172 | `branch` | `branch#29` | 1.0084e+00 | method=algebraic, source=imported, candidate=78 |
| 173 | `branch` | `branch#30` | 1.2177e+00 | method=algebraic, source=imported, candidate=71 |
| 174 | `branch` | `branch#31` | 1.2177e+00 | method=algebraic, source=imported, candidate=72 |
| 175 | `branch` | `branch#32` | 1.0164e+00 | method=algebraic, source=imported, candidate=73 |
| 176 | `branch` | `branch#33` | 2.1846e+00 | method=algebraic, source=imported, candidate=39 |
| 177 | `branch` | `branch#34` | 1.0164e+00 | method=algebraic, source=imported, candidate=74 |
| 178 | `branch` | `branch#35` | 2.1846e+00 | method=algebraic, source=imported, candidate=38 |
| 179 | `branch` | `branch#36` | 1.9805e+01 | method=algebraic, source=imported, candidate=24 |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Traj Max | Secondary Max | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 141 | 8.0251e-06 | 0.77% | 0.0013 | 0.8815 | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 2 | `baseline` | 5 | 1.0989e+00 | 1675.38% | 0.0124 | 0.9039 | 0 | 0.5000 | method=algebraic, source=imported, candidate=58, polished=true |
| 3 | `baseline` | 5 | 1.1014e+00 | 2765.85% | 0.0140 | 0.9016 | 0 | 0.5000 | method=algebraic, source=imported, candidate=59, polished=true |
| 4 | `baseline` | 2 | 2.6368e-04 | 294.76% | 0.0003 | 0.9235 | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 5 | `baseline` | 2 | 7.1075e-02 | 98.20% | 0.0030 | 0.4006 | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 6 | `block` | 1 | 3.4152e-04 | 1313.97% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 7 | `baseline` | 1 | 3.4175e-04 | 1595.93% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 8 | `baseline` | 1 | 3.4183e-04 | 1715.41% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 9 | `block` | 1 | 3.4205e-04 | 2409.84% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 10 | `baseline` | 1 | 1.2854e+00 | 1186.79% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=56, polished=true |
| 11 | `baseline` | 1 | 1.3251e+00 | 1882.23% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=57, polished=true |
| 12 | `baseline` | 1 | 6.4453e+00 | 3367.59% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 13 | `baseline` | 1 | 1.9000e+01 | 1125.14% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 14 | `baseline` | 1 | 1.9009e+01 | 4941.07% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 15 | `baseline` | 1 | 1.9033e+01 | 1168.97% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 16 | `baseline` | 1 | 2.1775e+01 | 710.04% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 17 | `baseline` | 1 | 2.1899e+01 | 718.11% | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 18 | `block` | 1 | 4.2680e+01 | 3725.63% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 19 | `block` | 1 | 7.1460e+43 | 6304.02% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 20 | `block` | 1 | 2.3768e+48 | 6121.29% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 21 | `block` | 1 | Inf | 3088.95% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 22 | `block` | 1 | Inf | 4925.01% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 23 | `block` | 1 | Inf | 7555.44% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 24 | `block` | 1 | Inf | 18134.73% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 25 | `block` | 1 | Inf | 1515.07% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 26 | `block` | 1 | Inf | 26003.77% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 27 | `block` | 1 | Inf | 3025.34% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 28 | `block` | 1 | Inf | 976.84% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 29 | `block` | 1 | Inf | 1158.95% | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 1.1364e+06 | 7.1075e-02 | 98.20% | 10.653 | `` |
| 2 | `baseline` | 1.1364e+06 | 9.3731e-02 | 171.04% | 11.264 | `` |
| 3 | `baseline` | 7.8295e+05 | 1.9000e+01 | 1125.14% | 15.776 | `` |
| 4 | `baseline` | 7.8295e+05 | 1.9033e+01 | 1168.97% | 16.975 | `` |
| 5 | `baseline` | 8.6557e+04 | 2.6368e-04 | 294.76% | 4.911 | `` |
| 6 | `baseline` | 7.4720e+04 | 3.4175e-04 | 1595.93% | 6.190 | `` |
| 7 | `baseline` | 7.4720e+04 | 3.4183e-04 | 1715.41% | 5.906 | `` |
| 8 | `baseline` | 2.0384e+04 | 3.1674e-05 | 90.55% | 4.805 | `` |
| 9 | `baseline` | 1.0335e+04 | 6.4453e+00 | 3367.59% | 7.318 | `` |
| 10 | `baseline` | 1.0335e+04 | 1.9009e+01 | 4941.07% | 5.064 | `` |
| 11 | `baseline` | 7.2225e+03 | 3.0530e-04 | 455.74% | 19.064 | `` |
| 12 | `baseline` | 7.2225e+03 | 7.8126e-05 | 179.36% | 11.722 | `` |
| 13 | `baseline` | 1.3658e+03 | 2.1899e+01 | 718.11% | 23.310 | `` |
| 14 | `baseline` | 1.3658e+03 | 2.1775e+01 | 710.04% | 22.183 | `` |
| 15 | `baseline` | 6.6678e+02 | 1.7995e-05 | 25.67% | 6.724 | `` |
| 16 | `baseline` | 6.6678e+02 | 2.0349e-05 | 95.65% | 6.362 | `` |
| 17 | `baseline` | 2.7709e+02 | 1.4407e-05 | 40.07% | 5.009 | `` |
| 18 | `baseline` | 2.2199e+02 | 8.3072e-06 | 6.03% | 5.357 | `` |
| 19 | `baseline` | 2.1928e+02 | 8.1850e-06 | 4.85% | 5.544 | `` |
| 20 | `baseline` | 2.0627e+02 | 8.0251e-06 | 0.77% | 3.855 | `` |
| 21 | `baseline` | 5.4059e+01 | 1.9002e-05 | 26.67% | 6.203 | `` |
| 22 | `baseline` | 5.4059e+01 | 1.7711e-05 | 90.62% | 5.862 | `` |
| 23 | `baseline` | 3.2935e+01 | 8.0965e-06 | 56.33% | 5.858 | `` |
| 24 | `baseline` | 1.9805e+01 | 1.2297e-04 | 73.29% | 4.814 | `` |
| 25 | `baseline` | 1.9805e+01 | 8.5404e-05 | 99.94% | 4.343 | `` |
| 26 | `baseline` | 1.5781e+01 | 2.3447e-05 | 30.50% | 7.691 | `` |
| 27 | `baseline` | 1.5781e+01 | 2.5490e-05 | 104.56% | 7.201 | `` |
| 28 | `baseline` | 9.2118e+00 | 1.8409e-04 | 123.82% | 4.785 | `` |
| 29 | `baseline` | 9.2118e+00 | 2.4697e-04 | 122.98% | 4.067 | `` |
| 30 | `baseline` | 6.1286e+00 | 2.3668e-05 | 30.69% | 8.299 | `` |
| 31 | `baseline` | 6.1286e+00 | 2.5357e-05 | 104.35% | 7.414 | `` |
| 32 | `baseline` | 5.2768e+00 | 1.4465e-05 | 83.32% | 6.102 | `` |
| 33 | `baseline` | 5.2768e+00 | 1.5493e-05 | 22.76% | 7.039 | `` |
| 34 | `baseline` | 3.6248e+00 | 2.2338e-05 | 99.23% | 6.816 | `` |
| 35 | `baseline` | 3.6248e+00 | 2.0000e-05 | 27.61% | 7.128 | `` |
| 36 | `baseline` | 2.7378e+00 | 1.3683e-05 | 20.55% | 6.420 | `` |
| 37 | `baseline` | 2.7378e+00 | 1.3212e-05 | 80.20% | 6.236 | `` |
| 38 | `baseline` | 2.1846e+00 | 9.5815e-06 | 67.59% | 6.319 | `` |
| 39 | `baseline` | 2.1846e+00 | 9.6341e-06 | 12.44% | 6.293 | `` |
| 40 | `baseline` | 1.8189e+00 | 1.9537e-05 | 94.21% | 6.025 | `` |
| 41 | `baseline` | 1.8189e+00 | 1.7104e-05 | 24.72% | 6.575 | `` |
| 42 | `baseline` | 2.0623e+00 | 2.6717e-05 | 106.50% | 7.378 | `` |
| 43 | `baseline` | 2.0623e+00 | 2.1579e-05 | 28.90% | 8.526 | `` |
| 44 | `baseline` | 1.7842e+00 | 1.2518e-05 | 78.53% | 5.880 | `` |
| 45 | `baseline` | 1.7842e+00 | 1.1246e-05 | 16.44% | 6.593 | `` |
| 46 | `baseline` | 1.7110e+00 | 1.3135e-05 | 80.19% | 5.975 | `` |
| 47 | `baseline` | 1.7110e+00 | 1.1565e-05 | 16.73% | 7.021 | `` |
| 48 | `baseline` | 1.6972e+00 | 1.1933e-05 | 17.75% | 6.293 | `` |
| 49 | `baseline` | 1.6972e+00 | 1.1858e-05 | 76.41% | 6.055 | `` |
| 50 | `baseline` | 1.6272e+00 | 1.1901e-05 | 17.65% | 6.514 | `` |
| 51 | `baseline` | 1.6272e+00 | 1.2241e-05 | 76.40% | 6.099 | `` |
| 52 | `baseline` | 1.3869e+00 | 1.4263e-05 | 21.26% | 7.021 | `` |
| 53 | `baseline` | 1.3869e+00 | 1.3806e-05 | 81.89% | 6.177 | `` |
| 54 | `baseline` | 1.6208e+00 | 1.8026e-05 | 25.66% | 9.590 | `` |
| 55 | `baseline` | 1.6208e+00 | 1.7886e-05 | 89.06% | 8.817 | `` |
| 56 | `baseline` | 1.5361e+00 | 1.2854e+00 | 1186.79% | 39.724 | `` |
| 57 | `baseline` | 1.5361e+00 | 1.3251e+00 | 1882.23% | 34.813 | `` |
| 58 | `baseline` | 1.2315e+00 | 1.0989e+00 | 1675.38% | 39.537 | `` |
| 59 | `baseline` | 1.2315e+00 | 1.1014e+00 | 2765.85% | 40.790 | `` |
| 60 | `baseline` | 1.4098e+00 | 1.2142e+00 | 2367.80% | 39.241 | `` |
| 61 | `baseline` | 1.4098e+00 | 1.1854e+00 | 1456.19% | 40.801 | `` |
| 62 | `baseline` | 1.3869e+00 | 1.2152e+00 | 2379.31% | 38.151 | `` |
| 63 | `baseline` | 1.3869e+00 | 1.1776e+00 | 1462.46% | 42.003 | `` |
| 64 | `baseline` | 1.3950e+00 | 1.1947e+00 | 2371.55% | 39.932 | `` |
| 65 | `baseline` | 1.3950e+00 | 1.1784e+00 | 1457.99% | 40.844 | `` |
| 66 | `baseline` | 1.3364e+00 | 1.2230e+00 | 1476.68% | 40.034 | `` |
| 67 | `baseline` | 1.3364e+00 | 1.2286e+00 | 2395.39% | 40.916 | `` |
| 68 | `baseline` | 1.2423e+00 | 8.0319e-06 | 52.42% | 4.661 | `` |
| 69 | `baseline` | 1.2897e+00 | 1.8761e-04 | 101.46% | 3.993 | `` |
| 70 | `baseline` | 1.2897e+00 | 9.9132e-05 | 107.39% | 4.079 | `` |
| 71 | `baseline` | 1.2177e+00 | 9.1925e-06 | 65.49% | 7.275 | `` |
| 72 | `baseline` | 1.2177e+00 | 9.8027e-06 | 12.95% | 6.845 | `` |
| 73 | `baseline` | 1.0164e+00 | 6.2205e-05 | 101.36% | 4.070 | `` |
| 74 | `baseline` | 1.0164e+00 | 1.7961e-04 | 99.50% | 4.030 | `` |
| 75 | `baseline` | 1.1237e+00 | 1.1944e-05 | 76.72% | 7.352 | `` |
| 76 | `baseline` | 1.1237e+00 | 1.1772e-05 | 17.27% | 7.459 | `` |
| 77 | `baseline` | 1.0084e+00 | 1.1312e-05 | 74.50% | 6.191 | `` |
| 78 | `baseline` | 1.0084e+00 | 1.1170e-05 | 15.95% | 6.453 | `` |
| 79 | `baseline` | 9.9340e-01 | 1.0690e-05 | 15.13% | 6.544 | `` |
| 80 | `baseline` | 9.9340e-01 | 1.0616e-05 | 72.46% | 6.748 | `` |
| 81 | `baseline` | 8.4889e-01 | 1.1172e-05 | 74.15% | 5.980 | `` |
| 82 | `baseline` | 8.4889e-01 | 1.0032e-05 | 13.56% | 6.519 | `` |
| 83 | `baseline` | 8.9415e-01 | 1.0805e-05 | 73.17% | 6.191 | `` |
| 84 | `baseline` | 8.9415e-01 | 1.1802e-05 | 17.22% | 6.471 | `` |
| 85 | `baseline` | 8.1955e-01 | 1.1567e-05 | 17.08% | 6.944 | `` |
| 86 | `baseline` | 8.1955e-01 | 1.0066e-05 | 70.35% | 6.231 | `` |
| 87 | `baseline` | 4.8580e-01 | 1.3588e-05 | 20.36% | 6.739 | `` |
| 88 | `baseline` | 4.8580e-01 | 1.6435e-05 | 87.80% | 6.434 | `` |
| 89 | `baseline` | 3.8334e-01 | 1.9139e-05 | 25.95% | 7.635 | `` |
| 90 | `baseline` | 3.8334e-01 | 1.7966e-05 | 90.85% | 6.662 | `` |
| 91 | `baseline` | 2.9452e-01 | 1.2536e-05 | 18.80% | 6.566 | `` |
| 92 | `baseline` | 2.9452e-01 | 1.4123e-05 | 82.71% | 6.037 | `` |
| 93 | `baseline` | 3.5980e-01 | 1.1662e-05 | 76.01% | 6.129 | `` |
| 94 | `baseline` | 3.5980e-01 | 1.2986e-05 | 19.51% | 6.776 | `` |
| 95 | `baseline` | 1.8501e-01 | 2.3883e-05 | 101.84% | 7.349 | `` |
| 96 | `baseline` | 1.8501e-01 | 2.3470e-05 | 30.45% | 8.210 | `` |
| 97 | `baseline` | 1.1021e-01 | 5.0884e-05 | 44.81% | 4.252 | `` |
| 98 | `baseline` | 1.1021e-01 | 1.2344e-04 | 83.72% | 4.387 | `` |
| 99 | `baseline` | 1.0405e-01 | 1.0686e-04 | 80.54% | 4.949 | `` |
| 100 | `baseline` | 1.0405e-01 | 8.0251e-06 | 53.41% | 5.475 | `` |
| 101 | `baseline` | 9.2294e-02 | 8.6787e-06 | 8.19% | 6.064 | `` |
| 102 | `baseline` | 9.2294e-02 | 8.8500e-06 | 64.21% | 5.705 | `` |
| 103 | `baseline` | 6.4956e-02 | 1.8882e-05 | 92.34% | 6.790 | `` |
| 104 | `baseline` | 6.4956e-02 | 2.1466e-05 | 28.72% | 7.811 | `` |
| 105 | `baseline` | 3.6356e-02 | 2.1953e-05 | 98.60% | 7.141 | `` |
| 106 | `baseline` | 3.6356e-02 | 2.0033e-05 | 27.61% | 7.568 | `` |
| 107 | `baseline` | 3.5696e-02 | 9.8096e-06 | 69.24% | 6.090 | `` |
| 108 | `baseline` | 3.5696e-02 | 1.0622e-05 | 15.09% | 6.388 | `` |
| 109 | `baseline` | 2.3833e-02 | 1.6629e-05 | 88.24% | 7.063 | `` |
| 110 | `baseline` | 2.3833e-02 | 1.6243e-05 | 23.36% | 7.093 | `` |
| 111 | `baseline` | 1.4144e-02 | 1.2295e-05 | 18.29% | 6.485 | `` |
| 112 | `baseline` | 1.2209e-02 | 9.9980e-06 | 70.07% | 5.886 | `` |
| 113 | `baseline` | 1.2209e-02 | 1.1058e-05 | 16.06% | 6.263 | `` |
| 114 | `baseline` | 1.2143e-02 | 8.1679e-06 | 4.63% | 6.400 | `` |
| 115 | `baseline` | 1.2143e-02 | 8.0851e-06 | 56.31% | 5.603 | `` |
| 116 | `baseline` | 3.5657e-03 | 1.1339e-05 | 74.98% | 6.114 | `` |
| 117 | `baseline` | 3.5657e-03 | 1.2837e-05 | 19.06% | 6.525 | `` |
| 118 | `baseline` | 4.3734e-03 | 2.9101e-05 | 34.35% | 9.247 | `` |
| 119 | `baseline` | 4.3734e-03 | 3.4503e-05 | 118.02% | 9.091 | `` |
| 120 | `block` | 9.5156e+05 | 1.9063e-04 | 161.22% | 6.030 | `` |
| 121 | `branch` | 5.5241e-04 | 8.0251e-06 | 53.41% | 4.062 | `` |
| 122 | `synthesized` | 1.2431e-04 | 8.5764e-06 | 61.91% | 5.755 | `` |
| 123 | `block` | Inf | Inf | 3088.95% | 0.284 | `` |
| 124 | `block` | Inf | Inf | 4925.01% | 0.283 | `` |
| 125 | `block` | 9.0519e+05 | 3.4205e-04 | 2409.84% | 6.202 | `` |
| 126 | `block` | 2.2068e+06 | 4.2680e+01 | 3725.63% | 5.752 | `` |
| 127 | `block` | Inf | Inf | 7555.44% | 0.322 | `` |
| 128 | `block` | Inf | Inf | 18134.73% | 0.287 | `` |
| 129 | `block` | Inf | Inf | 1515.07% | 0.273 | `` |
| 130 | `block` | Inf | Inf | 26003.77% | 0.313 | `` |
| 131 | `block` | 8.9735e+05 | 3.4152e-04 | 1313.97% | 5.838 | `` |
| 132 | `block` | 2.9929e+80 | 7.1460e+43 | 6304.02% | 29.026 | `` |
| 133 | `block` | 1.6515e+81 | 2.3768e+48 | 6121.29% | 24.168 | `` |
| 134 | `block` | Inf | Inf | 3025.34% | 0.289 | `` |
| 135 | `block` | Inf | Inf | 976.84% | 0.286 | `` |
| 136 | `block` | Inf | Inf | 1158.95% | 0.311 | `` |
| 137 | `block` | 4.2436e+01 | 4.6731e-05 | 45.63% | 10.028 | `` |
| 138 | `block` | 6.1399e+01 | 5.0104e-05 | 136.68% | 9.723 | `` |
| 139 | `block` | 8.1316e+01 | 3.9359e-05 | 125.40% | 10.163 | `` |
| 140 | `block` | 5.7397e+01 | 2.8406e-05 | 34.27% | 10.721 | `` |
| 141 | `block` | 3.5886e+00 | 8.0470e-06 | 51.65% | 4.667 | `` |
| 142 | `synthesized` | 1.6147e-04 | 9.2395e-06 | 66.05% | 5.692 | `` |
| 143 | `synthesized` | 1.4024e-04 | 9.2832e-06 | 66.62% | 5.575 | `` |
| 144 | `synthesized` | 1.2842e-04 | 8.6288e-06 | 62.16% | 5.821 | `` |
| 145 | `branch` | 1.2407e-04 | 8.7305e-06 | 63.39% | 6.360 | `` |
| 146 | `branch` | 1.2209e-02 | 9.9980e-06 | 70.07% | 5.941 | `` |
| 147 | `branch` | 1.2209e-02 | 1.1058e-05 | 16.06% | 6.119 | `` |
| 148 | `branch` | 1.2143e-02 | 8.0851e-06 | 56.31% | 5.523 | `` |
| 149 | `branch` | 1.0405e-01 | 1.0686e-04 | 80.54% | 4.634 | `` |
| 150 | `branch` | 9.2294e-02 | 8.6787e-06 | 8.19% | 6.871 | `` |
| 151 | `branch` | 3.5696e-02 | 1.0622e-05 | 15.09% | 6.384 | `` |
| 152 | `branch` | 9.2294e-02 | 8.8500e-06 | 64.21% | 5.729 | `` |
| 153 | `branch` | 1.2143e-02 | 8.1679e-06 | 4.63% | 5.714 | `` |
| 154 | `branch` | 1.4144e-02 | 1.2295e-05 | 18.29% | 6.330 | `` |
| 155 | `branch` | 1.1021e-01 | 1.2344e-04 | 83.72% | 4.957 | `` |
| 156 | `branch` | 3.5980e-01 | 1.1662e-05 | 76.01% | 6.133 | `` |
| 157 | `branch` | 1.1021e-01 | 5.0884e-05 | 44.81% | 4.275 | `` |
| 158 | `branch` | 3.5980e-01 | 1.2986e-05 | 19.51% | 6.273 | `` |
| 159 | `branch` | 3.5657e-03 | 1.1339e-05 | 74.98% | 6.354 | `` |
| 160 | `branch` | 3.5657e-03 | 1.2837e-05 | 19.06% | 6.843 | `` |
| 161 | `branch` | 8.1955e-01 | 1.0066e-05 | 70.35% | 6.365 | `` |
| 162 | `branch` | 9.9340e-01 | 1.0616e-05 | 72.46% | 6.113 | `` |
| 163 | `branch` | 8.4889e-01 | 1.1172e-05 | 74.15% | 6.020 | `` |
| 164 | `branch` | 8.1955e-01 | 1.1567e-05 | 17.08% | 6.938 | `` |
| 165 | `branch` | 8.4889e-01 | 1.0032e-05 | 13.56% | 6.530 | `` |
| 166 | `branch` | 1.1237e+00 | 1.1772e-05 | 17.27% | 7.376 | `` |
| 167 | `branch` | 1.0084e+00 | 1.1312e-05 | 74.50% | 6.161 | `` |
| 168 | `branch` | 9.9340e-01 | 1.0690e-05 | 15.13% | 6.563 | `` |
| 169 | `branch` | 1.1237e+00 | 1.1944e-05 | 76.72% | 7.499 | `` |
| 170 | `branch` | 2.9452e-01 | 1.4123e-05 | 82.71% | 6.111 | `` |
| 171 | `branch` | 2.9452e-01 | 1.2536e-05 | 18.80% | 6.669 | `` |
| 172 | `branch` | 1.0084e+00 | 1.1170e-05 | 15.95% | 6.394 | `` |
| 173 | `branch` | 1.2177e+00 | 9.1925e-06 | 65.49% | 7.143 | `` |
| 174 | `branch` | 1.2177e+00 | 9.8027e-06 | 12.95% | 6.797 | `` |
| 175 | `branch` | 1.0164e+00 | 6.2205e-05 | 101.36% | 4.101 | `` |
| 176 | `branch` | 2.1846e+00 | 9.6341e-06 | 12.44% | 6.412 | `` |
| 177 | `branch` | 1.0164e+00 | 1.7961e-04 | 99.50% | 3.948 | `` |
| 178 | `branch` | 2.1846e+00 | 9.5815e-06 | 67.59% | 6.319 | `` |
| 179 | `branch` | 1.9805e+01 | 1.2297e-04 | 73.29% | 4.983 | `` |

