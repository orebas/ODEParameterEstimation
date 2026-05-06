# Tryhard Finalist Benchmark Case: dc_motor_1_1em4

- Model: `dc_motor`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T11:00:44.661`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/dc_motor_1_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/dc_motor_1_1em4`

## Comparison-Table Reference

- Classification: `both_success`
- Comparison CSV ODEPE mean/max relative error: 0.52% / 0.77%
- Comparison CSV ODEPE runtime: 2428.405 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 102 | 0.78% | omega_m(0) (1.22%) | 9.4787e-03 |
| `odepe_polish` | 156 | 0.02% | Jm (0.03%) | 6.9255e-04 |

## Imported Raw Pool

- Raw imported candidates: 102
- Best raw fit index: 102
- Best raw oracle index: 101
- Best-fit vs best-truth combined-RMSE gap: 0.43%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.458 s
- Consensus/block context: 4.360 s
- 4x4 baseline evidence report: 0.688 s
- 4x4 block no-polish report: 3.673 s
- Polish context build: 0.035 s
- Baseline-only finalists: 136.935 s
- Additive-only finalists: 8.571 s
- Reasonable frontier finalists: 72.688 s
- Local total (excluding reference load): 226.949 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 0.78% | 0.78% | 76 | `raw` | 9.4787e-03 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 0.02% | 0.02% | 156 | `benchmark` | 6.9255e-04 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 77.71% | 77.71% | 8 | `block` | 2.0700e+03 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.02% | 0.02% | 29 | `baseline` | 6.9255e-04 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.02% | 0.02% | 5 | `block` | 6.9255e-04 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.02% | 0.02% | 33 | `baseline+block` | 6.9255e-04 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `tie`
- Improvement mode: `no_improvement`
- Baseline best finalist index / RMSE: 1 / 0.02%
- Additive best finalist index / RMSE: 1 / 0.02%
- Frontier best finalist index / RMSE: 1 / 0.02%
- Baseline preserved seeds: 76
- Additive candidate seeds: 8
- Frontier admitted seeds: 84
- Rejected additive seeds: 0
- Successful merged polished seeds: 84
- Returned merged finalists: 33

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 6.7133e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 6.5414e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 6.5112e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 2.8141e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 1.4555e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 7.7763e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 1.1309e+05 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | Inf | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 2.5884e+03 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 2.4309e+03 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 12 | 2.3604e+03 | method=algebraic, source=imported, candidate=12 |
| 12 | `baseline` | 13 | 1.6157e+03 | method=algebraic, source=imported, candidate=13 |
| 13 | `baseline` | 14 | 1.4160e+03 | method=algebraic, source=imported, candidate=14 |
| 14 | `baseline` | 15 | 9.2944e+02 | method=algebraic, source=imported, candidate=15 |
| 15 | `baseline` | 16 | 4.8647e+02 | method=algebraic, source=imported, candidate=16 |
| 16 | `baseline` | 17 | 4.6607e+02 | method=algebraic, source=imported, candidate=17 |
| 17 | `baseline` | 18 | 4.0619e+02 | method=algebraic, source=imported, candidate=18 |
| 18 | `baseline` | 19 | 3.4499e+02 | method=algebraic, source=imported, candidate=19 |
| 19 | `baseline` | 20 | 3.1944e+02 | method=algebraic, source=imported, candidate=20 |
| 20 | `baseline` | 21 | 3.1694e+02 | method=algebraic, source=imported, candidate=21 |
| 21 | `baseline` | 22 | 2.9655e+02 | method=algebraic, source=imported, candidate=22 |
| 22 | `baseline` | 23 | 2.9460e+02 | method=algebraic, source=imported, candidate=23 |
| 23 | `baseline` | 24 | 2.7852e+02 | method=algebraic, source=imported, candidate=24 |
| 24 | `baseline` | 26 | 2.6665e+02 | method=algebraic, source=imported, candidate=26 |
| 25 | `baseline` | 27 | 2.3989e+02 | method=algebraic, source=imported, candidate=27 |
| 26 | `baseline` | 28 | 2.0109e+02 | method=algebraic, source=imported, candidate=28 |
| 27 | `baseline` | 29 | 1.9906e+02 | method=algebraic, source=imported, candidate=29 |
| 28 | `baseline` | 30 | 1.4051e+02 | method=algebraic, source=imported, candidate=30 |
| 29 | `baseline` | 31 | 9.4568e+01 | method=algebraic, source=imported, candidate=31 |
| 30 | `baseline` | 32 | Inf | method=algebraic, source=imported, candidate=32 |
| 31 | `baseline` | 33 | 7.7812e+01 | method=algebraic, source=imported, candidate=33 |
| 32 | `baseline` | 34 | 6.0928e+01 | method=algebraic, source=imported, candidate=34 |
| 33 | `baseline` | 35 | 4.2980e+01 | method=algebraic, source=imported, candidate=35 |
| 34 | `baseline` | 36 | Inf | method=algebraic, source=imported, candidate=36 |
| 35 | `baseline` | 37 | Inf | method=algebraic, source=imported, candidate=37 |
| 36 | `baseline` | 38 | Inf | method=algebraic, source=imported, candidate=38 |
| 37 | `baseline` | 39 | 2.7056e+01 | method=algebraic, source=imported, candidate=39 |
| 38 | `baseline` | 40 | 2.4190e+01 | method=algebraic, source=imported, candidate=40 |
| 39 | `baseline` | 41 | 1.5140e+01 | method=algebraic, source=imported, candidate=41 |
| 40 | `baseline` | 42 | 1.0645e+01 | method=algebraic, source=imported, candidate=42 |
| 41 | `baseline` | 43 | 9.2210e+00 | method=algebraic, source=imported, candidate=43 |
| 42 | `baseline` | 44 | 8.7736e+00 | method=algebraic, source=imported, candidate=44 |
| 43 | `baseline` | 46 | 6.5844e+00 | method=algebraic, source=imported, candidate=46 |
| 44 | `baseline` | 47 | 2.6452e+00 | method=algebraic, source=imported, candidate=47 |
| 45 | `baseline` | 48 | 2.5422e+00 | method=algebraic, source=imported, candidate=48 |
| 46 | `baseline` | 49 | 2.3512e+00 | method=algebraic, source=imported, candidate=49 |
| 47 | `baseline` | 50 | 2.1466e+00 | method=algebraic, source=imported, candidate=50 |
| 48 | `baseline` | 51 | 1.8676e+00 | method=algebraic, source=imported, candidate=51 |
| 49 | `baseline` | 53 | 1.8614e+00 | method=algebraic, source=imported, candidate=53 |
| 50 | `baseline` | 54 | 1.7737e+00 | method=algebraic, source=imported, candidate=54 |
| 51 | `baseline` | 55 | 1.5754e+00 | method=algebraic, source=imported, candidate=55 |
| 52 | `baseline` | 56 | 1.5148e+00 | method=algebraic, source=imported, candidate=56 |
| 53 | `baseline` | 57 | 1.5106e+00 | method=algebraic, source=imported, candidate=57 |
| 54 | `baseline` | 58 | 1.4778e+00 | method=algebraic, source=imported, candidate=58 |
| 55 | `baseline` | 62 | 1.3423e+00 | method=algebraic, source=imported, candidate=62 |
| 56 | `baseline` | 64 | 1.1901e+00 | method=algebraic, source=imported, candidate=64 |
| 57 | `baseline` | 66 | 1.0364e+00 | method=algebraic, source=imported, candidate=66 |
| 58 | `baseline` | 68 | 8.5756e-01 | method=algebraic, source=imported, candidate=68 |
| 59 | `baseline` | 72 | 6.1833e-01 | method=algebraic, source=imported, candidate=72 |
| 60 | `baseline` | 71 | 6.4816e-01 | method=algebraic, source=imported, candidate=71 |
| 61 | `baseline` | 74 | 5.2077e-01 | method=algebraic, source=imported, candidate=74 |
| 62 | `baseline` | 75 | 4.5369e-01 | method=algebraic, source=imported, candidate=75 |
| 63 | `baseline` | 79 | 3.4339e-01 | method=algebraic, source=imported, candidate=79 |
| 64 | `baseline` | 80 | 2.8130e-01 | method=algebraic, source=imported, candidate=80 |
| 65 | `baseline` | 81 | 2.6265e-01 | method=algebraic, source=imported, candidate=81 |
| 66 | `baseline` | 90 | 1.7581e-01 | method=algebraic, source=imported, candidate=90 |
| 67 | `baseline` | 91 | 1.4402e-01 | method=algebraic, source=imported, candidate=91 |
| 68 | `baseline` | 92 | 1.3824e-01 | method=algebraic, source=imported, candidate=92 |
| 69 | `baseline` | 95 | 1.2307e-01 | method=algebraic, source=imported, candidate=95 |
| 70 | `baseline` | 96 | 1.0879e-01 | method=algebraic, source=imported, candidate=96 |
| 71 | `baseline` | 97 | 9.8581e-02 | method=algebraic, source=imported, candidate=97 |
| 72 | `baseline` | 98 | 9.6649e-02 | method=algebraic, source=imported, candidate=98 |
| 73 | `baseline` | 99 | 8.7242e-02 | method=algebraic, source=imported, candidate=99 |
| 74 | `baseline` | 100 | 6.7731e-02 | method=algebraic, source=imported, candidate=100 |
| 75 | `baseline` | 101 | 5.3754e-02 | method=algebraic, source=imported, candidate=101 |
| 76 | `baseline` | 102 | 9.4787e-03 | method=algebraic, source=imported, candidate=102 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0052 | 2.0700e+03 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0277 | 1.9619e+03 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.4685 | 7.8410e+05 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.4709 | 7.7582e+05 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.8788 | 1.4118e+07 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.8909 | 1.5137e+07 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.9233 | 5.9086e+06 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.9346 | 6.5610e+06 | method=direct_opt, source=assembled |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `none` | `none` | Inf | none |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 6.7133e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 6.5414e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 6.5112e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 2.8141e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 1.4555e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 7.7763e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 1.1309e+05 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | Inf | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 2.5884e+03 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 2.4309e+03 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#12` | 2.3604e+03 | method=algebraic, source=imported, candidate=12 |
| 12 | `baseline` | `baseline#13` | 1.6157e+03 | method=algebraic, source=imported, candidate=13 |
| 13 | `baseline` | `baseline#14` | 1.4160e+03 | method=algebraic, source=imported, candidate=14 |
| 14 | `baseline` | `baseline#15` | 9.2944e+02 | method=algebraic, source=imported, candidate=15 |
| 15 | `baseline` | `baseline#16` | 4.8647e+02 | method=algebraic, source=imported, candidate=16 |
| 16 | `baseline` | `baseline#17` | 4.6607e+02 | method=algebraic, source=imported, candidate=17 |
| 17 | `baseline` | `baseline#18` | 4.0619e+02 | method=algebraic, source=imported, candidate=18 |
| 18 | `baseline` | `baseline#19` | 3.4499e+02 | method=algebraic, source=imported, candidate=19 |
| 19 | `baseline` | `baseline#20` | 3.1944e+02 | method=algebraic, source=imported, candidate=20 |
| 20 | `baseline` | `baseline#21` | 3.1694e+02 | method=algebraic, source=imported, candidate=21 |
| 21 | `baseline` | `baseline#22` | 2.9655e+02 | method=algebraic, source=imported, candidate=22 |
| 22 | `baseline` | `baseline#23` | 2.9460e+02 | method=algebraic, source=imported, candidate=23 |
| 23 | `baseline` | `baseline#24` | 2.7852e+02 | method=algebraic, source=imported, candidate=24 |
| 24 | `baseline` | `baseline#26` | 2.6665e+02 | method=algebraic, source=imported, candidate=26 |
| 25 | `baseline` | `baseline#27` | 2.3989e+02 | method=algebraic, source=imported, candidate=27 |
| 26 | `baseline` | `baseline#28` | 2.0109e+02 | method=algebraic, source=imported, candidate=28 |
| 27 | `baseline` | `baseline#29` | 1.9906e+02 | method=algebraic, source=imported, candidate=29 |
| 28 | `baseline` | `baseline#30` | 1.4051e+02 | method=algebraic, source=imported, candidate=30 |
| 29 | `baseline` | `baseline#31` | 9.4568e+01 | method=algebraic, source=imported, candidate=31 |
| 30 | `baseline` | `baseline#32` | Inf | method=algebraic, source=imported, candidate=32 |
| 31 | `baseline` | `baseline#33` | 7.7812e+01 | method=algebraic, source=imported, candidate=33 |
| 32 | `baseline` | `baseline#34` | 6.0928e+01 | method=algebraic, source=imported, candidate=34 |
| 33 | `baseline` | `baseline#35` | 4.2980e+01 | method=algebraic, source=imported, candidate=35 |
| 34 | `baseline` | `baseline#36` | Inf | method=algebraic, source=imported, candidate=36 |
| 35 | `baseline` | `baseline#37` | Inf | method=algebraic, source=imported, candidate=37 |
| 36 | `baseline` | `baseline#38` | Inf | method=algebraic, source=imported, candidate=38 |
| 37 | `baseline` | `baseline#39` | 2.7056e+01 | method=algebraic, source=imported, candidate=39 |
| 38 | `baseline` | `baseline#40` | 2.4190e+01 | method=algebraic, source=imported, candidate=40 |
| 39 | `baseline` | `baseline#41` | 1.5140e+01 | method=algebraic, source=imported, candidate=41 |
| 40 | `baseline` | `baseline#42` | 1.0645e+01 | method=algebraic, source=imported, candidate=42 |
| 41 | `baseline` | `baseline#43` | 9.2210e+00 | method=algebraic, source=imported, candidate=43 |
| 42 | `baseline` | `baseline#44` | 8.7736e+00 | method=algebraic, source=imported, candidate=44 |
| 43 | `baseline` | `baseline#46` | 6.5844e+00 | method=algebraic, source=imported, candidate=46 |
| 44 | `baseline` | `baseline#47` | 2.6452e+00 | method=algebraic, source=imported, candidate=47 |
| 45 | `baseline` | `baseline#48` | 2.5422e+00 | method=algebraic, source=imported, candidate=48 |
| 46 | `baseline` | `baseline#49` | 2.3512e+00 | method=algebraic, source=imported, candidate=49 |
| 47 | `baseline` | `baseline#50` | 2.1466e+00 | method=algebraic, source=imported, candidate=50 |
| 48 | `baseline` | `baseline#51` | 1.8676e+00 | method=algebraic, source=imported, candidate=51 |
| 49 | `baseline` | `baseline#53` | 1.8614e+00 | method=algebraic, source=imported, candidate=53 |
| 50 | `baseline` | `baseline#54` | 1.7737e+00 | method=algebraic, source=imported, candidate=54 |
| 51 | `baseline` | `baseline#55` | 1.5754e+00 | method=algebraic, source=imported, candidate=55 |
| 52 | `baseline` | `baseline#56` | 1.5148e+00 | method=algebraic, source=imported, candidate=56 |
| 53 | `baseline` | `baseline#57` | 1.5106e+00 | method=algebraic, source=imported, candidate=57 |
| 54 | `baseline` | `baseline#58` | 1.4778e+00 | method=algebraic, source=imported, candidate=58 |
| 55 | `baseline` | `baseline#62` | 1.3423e+00 | method=algebraic, source=imported, candidate=62 |
| 56 | `baseline` | `baseline#64` | 1.1901e+00 | method=algebraic, source=imported, candidate=64 |
| 57 | `baseline` | `baseline#66` | 1.0364e+00 | method=algebraic, source=imported, candidate=66 |
| 58 | `baseline` | `baseline#68` | 8.5756e-01 | method=algebraic, source=imported, candidate=68 |
| 59 | `baseline` | `baseline#72` | 6.1833e-01 | method=algebraic, source=imported, candidate=72 |
| 60 | `baseline` | `baseline#71` | 6.4816e-01 | method=algebraic, source=imported, candidate=71 |
| 61 | `baseline` | `baseline#74` | 5.2077e-01 | method=algebraic, source=imported, candidate=74 |
| 62 | `baseline` | `baseline#75` | 4.5369e-01 | method=algebraic, source=imported, candidate=75 |
| 63 | `baseline` | `baseline#79` | 3.4339e-01 | method=algebraic, source=imported, candidate=79 |
| 64 | `baseline` | `baseline#80` | 2.8130e-01 | method=algebraic, source=imported, candidate=80 |
| 65 | `baseline` | `baseline#81` | 2.6265e-01 | method=algebraic, source=imported, candidate=81 |
| 66 | `baseline` | `baseline#90` | 1.7581e-01 | method=algebraic, source=imported, candidate=90 |
| 67 | `baseline` | `baseline#91` | 1.4402e-01 | method=algebraic, source=imported, candidate=91 |
| 68 | `baseline` | `baseline#92` | 1.3824e-01 | method=algebraic, source=imported, candidate=92 |
| 69 | `baseline` | `baseline#95` | 1.2307e-01 | method=algebraic, source=imported, candidate=95 |
| 70 | `baseline` | `baseline#96` | 1.0879e-01 | method=algebraic, source=imported, candidate=96 |
| 71 | `baseline` | `baseline#97` | 9.8581e-02 | method=algebraic, source=imported, candidate=97 |
| 72 | `baseline` | `baseline#98` | 9.6649e-02 | method=algebraic, source=imported, candidate=98 |
| 73 | `baseline` | `baseline#99` | 8.7242e-02 | method=algebraic, source=imported, candidate=99 |
| 74 | `baseline` | `baseline#100` | 6.7731e-02 | method=algebraic, source=imported, candidate=100 |
| 75 | `baseline` | `baseline#101` | 5.3754e-02 | method=algebraic, source=imported, candidate=101 |
| 76 | `baseline` | `baseline#102` | 9.4787e-03 | method=algebraic, source=imported, candidate=102 |
| 77 | `block` | `block#1` | 2.0700e+03 | method=direct_opt, source=assembled |
| 78 | `block` | `block#2` | 1.9619e+03 | method=direct_opt, source=assembled |
| 79 | `block` | `block#3` | 7.8410e+05 | method=direct_opt, source=assembled |
| 80 | `block` | `block#4` | 7.7582e+05 | method=direct_opt, source=assembled |
| 81 | `block` | `block#5` | 1.4118e+07 | method=direct_opt, source=assembled |
| 82 | `block` | `block#6` | 1.5137e+07 | method=direct_opt, source=assembled |
| 83 | `block` | `block#7` | 5.9086e+06 | method=direct_opt, source=assembled |
| 84 | `block` | `block#8` | 6.5610e+06 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 52 | 6.9255e-04 | 0.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=55, polished=true |
| 2 | `baseline` | 1 | 1.1837e+01 | 58.61% | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 3 | `baseline` | 1 | 2.0846e+01 | 210.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |
| 4 | `baseline` | 1 | 3.9706e+01 | 286.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=34, polished=true |
| 5 | `baseline` | 1 | 4.2980e+01 | 40.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 6 | `baseline` | 1 | 7.7812e+01 | 42.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=33, polished=true |
| 7 | `baseline` | 1 | 1.0744e+02 | 581.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 8 | `baseline` | 1 | 1.1470e+02 | 655.10% | 0 | 0.5000 | method=algebraic, source=imported, candidate=28, polished=true |
| 9 | `baseline` | 1 | 1.2389e+02 | 678.54% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 10 | `baseline` | 1 | 1.3541e+02 | 705.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 11 | `baseline` | 1 | 1.3567e+02 | 703.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 12 | `baseline` | 1 | 1.4956e+02 | 754.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 13 | `baseline` | 1 | 1.9998e+02 | 834.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 14 | `baseline` | 1 | 2.2670e+02 | 798.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=22, polished=true |
| 15 | `baseline` | 1 | 2.2680e+02 | 796.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 16 | `baseline` | 1 | 2.3045e+02 | 756.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=26, polished=true |
| 17 | `baseline` | 1 | 4.8901e+02 | 1415.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 18 | `baseline` | 1 | 5.3040e+02 | 1566.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 19 | `baseline` | 1 | 1.1309e+05 | 21075.27% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 20 | `baseline` | 1 | 5.0842e+05 | 46076.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 21 | `baseline` | 1 | 6.9345e+05 | 60923.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 22 | `baseline` | 1 | 1.6423e+06 | 92240.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 23 | `baseline` | 1 | 1.6488e+06 | 92467.16% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 24 | `block` | 1 | 2.0990e+06 | 92240.97% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 25 | `block` | 1 | 2.1378e+06 | 92240.96% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 26 | `baseline` | 1 | 2.3551e+06 | 98798.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 27 | `block` | 1 | 2.8009e+06 | 92241.08% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 28 | `block` | 1 | 2.8353e+06 | 92241.08% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 29 | `baseline` | 1 | Inf | 123.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 30 | `baseline` | 1 | Inf | 48.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 31 | `baseline` | 1 | Inf | 49.93% | 0 | 0.5000 | method=algebraic, source=imported, candidate=36, polished=true |
| 32 | `baseline` | 1 | Inf | 48.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 33 | `baseline` | 1 | Inf | 48.56% | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 6.7133e+06 | 2.3551e+06 | 98798.90% | 0.439 | `` |
| 2 | `baseline` | 6.5414e+06 | 1.6488e+06 | 92467.16% | 0.584 | `` |
| 3 | `baseline` | 6.5112e+06 | 1.6423e+06 | 92240.97% | 0.595 | `` |
| 4 | `baseline` | 2.8141e+06 | 6.9345e+05 | 60923.51% | 0.739 | `` |
| 5 | `baseline` | 1.4555e+06 | 5.0842e+05 | 46076.70% | 0.465 | `` |
| 6 | `baseline` | 7.7763e+05 | 1.1837e+01 | 58.61% | 0.317 | `` |
| 7 | `baseline` | 1.1309e+05 | 1.1309e+05 | 21075.27% | 0.124 | `` |
| 8 | `baseline` | Inf | Inf | 123.70% | 0.070 | `` |
| 9 | `baseline` | 2.5884e+03 | 6.9255e-04 | 0.02% | 0.602 | `` |
| 10 | `baseline` | 2.4309e+03 | 6.9255e-04 | 0.02% | 0.588 | `` |
| 11 | `baseline` | 2.3604e+03 | 6.9255e-04 | 0.02% | 0.555 | `` |
| 12 | `baseline` | 1.6157e+03 | 5.3040e+02 | 1566.70% | 0.474 | `` |
| 13 | `baseline` | 1.4160e+03 | 4.8901e+02 | 1415.64% | 0.792 | `` |
| 14 | `baseline` | 9.2944e+02 | 6.9255e-04 | 0.02% | 0.417 | `` |
| 15 | `baseline` | 4.8647e+02 | 1.9998e+02 | 834.31% | 0.496 | `` |
| 16 | `baseline` | 4.6607e+02 | 6.9255e-04 | 0.02% | 0.492 | `` |
| 17 | `baseline` | 4.0619e+02 | 6.9255e-04 | 0.02% | 1.059 | `` |
| 18 | `baseline` | 3.4499e+02 | 1.4956e+02 | 754.70% | 0.361 | `` |
| 19 | `baseline` | 3.1944e+02 | 1.3541e+02 | 705.78% | 0.374 | `` |
| 20 | `baseline` | 3.1694e+02 | 1.3567e+02 | 703.01% | 0.373 | `` |
| 21 | `baseline` | 2.9655e+02 | 2.2670e+02 | 798.81% | 0.260 | `` |
| 22 | `baseline` | 2.9460e+02 | 2.2680e+02 | 796.15% | 0.265 | `` |
| 23 | `baseline` | 2.7852e+02 | 1.2389e+02 | 678.54% | 0.515 | `` |
| 24 | `baseline` | 2.6665e+02 | 2.3045e+02 | 756.85% | 0.224 | `` |
| 25 | `baseline` | 2.3989e+02 | 1.0744e+02 | 581.19% | 0.588 | `` |
| 26 | `baseline` | 2.0109e+02 | 1.1470e+02 | 655.10% | 0.878 | `` |
| 27 | `baseline` | 1.9906e+02 | 6.9255e-04 | 0.02% | 0.662 | `` |
| 28 | `baseline` | 1.4051e+02 | 6.9255e-04 | 0.02% | 0.515 | `` |
| 29 | `baseline` | 9.4568e+01 | 6.9255e-04 | 0.02% | 0.497 | `` |
| 30 | `baseline` | Inf | Inf | 48.84% | 0.041 | `` |
| 31 | `baseline` | 7.7812e+01 | 7.7812e+01 | 42.46% | 0.102 | `` |
| 32 | `baseline` | 6.0928e+01 | 3.9706e+01 | 286.00% | 11.891 | `` |
| 33 | `baseline` | 4.2980e+01 | 4.2980e+01 | 40.19% | 0.123 | `` |
| 34 | `baseline` | Inf | Inf | 49.93% | 0.184 | `` |
| 35 | `baseline` | Inf | Inf | 48.49% | 0.034 | `` |
| 36 | `baseline` | Inf | Inf | 48.56% | 0.033 | `` |
| 37 | `baseline` | 2.7056e+01 | 6.9255e-04 | 0.02% | 0.349 | `` |
| 38 | `baseline` | 2.4190e+01 | 2.0846e+01 | 210.31% | 11.904 | `` |
| 39 | `baseline` | 1.5140e+01 | 6.9255e-04 | 0.02% | 0.496 | `` |
| 40 | `baseline` | 1.0645e+01 | 6.9255e-04 | 0.02% | 0.552 | `` |
| 41 | `baseline` | 9.2210e+00 | 6.9255e-04 | 0.02% | 0.458 | `` |
| 42 | `baseline` | 8.7736e+00 | 6.9255e-04 | 0.02% | 5.906 | `` |
| 43 | `baseline` | 6.5844e+00 | 6.9255e-04 | 0.02% | 0.659 | `` |
| 44 | `baseline` | 2.6452e+00 | 6.9255e-04 | 0.02% | 0.445 | `` |
| 45 | `baseline` | 2.5422e+00 | 6.9255e-04 | 0.02% | 0.506 | `` |
| 46 | `baseline` | 2.3512e+00 | 6.9255e-04 | 0.02% | 2.551 | `` |
| 47 | `baseline` | 2.1466e+00 | 6.9255e-04 | 0.02% | 0.484 | `` |
| 48 | `baseline` | 1.8676e+00 | 6.9255e-04 | 0.02% | 0.556 | `` |
| 49 | `baseline` | 1.8614e+00 | 6.9255e-04 | 0.02% | 0.362 | `` |
| 50 | `baseline` | 1.7737e+00 | 6.9255e-04 | 0.02% | 0.395 | `` |
| 51 | `baseline` | 1.5754e+00 | 6.9255e-04 | 0.02% | 0.416 | `` |
| 52 | `baseline` | 1.5148e+00 | 6.9255e-04 | 0.02% | 0.532 | `` |
| 53 | `baseline` | 1.5106e+00 | 6.9255e-04 | 0.02% | 0.641 | `` |
| 54 | `baseline` | 1.4778e+00 | 6.9255e-04 | 0.02% | 0.356 | `` |
| 55 | `baseline` | 1.3423e+00 | 6.9255e-04 | 0.02% | 0.520 | `` |
| 56 | `baseline` | 1.1901e+00 | 6.9255e-04 | 0.02% | 0.527 | `` |
| 57 | `baseline` | 1.0364e+00 | 6.9255e-04 | 0.02% | 0.570 | `` |
| 58 | `baseline` | 8.5756e-01 | 6.9255e-04 | 0.02% | 0.369 | `` |
| 59 | `baseline` | 6.1833e-01 | 6.9255e-04 | 0.02% | 0.389 | `` |
| 60 | `baseline` | 6.4816e-01 | 6.9255e-04 | 0.02% | 0.492 | `` |
| 61 | `baseline` | 5.2077e-01 | 6.9255e-04 | 0.02% | 0.413 | `` |
| 62 | `baseline` | 4.5369e-01 | 6.9255e-04 | 0.02% | 0.543 | `` |
| 63 | `baseline` | 3.4339e-01 | 6.9255e-04 | 0.02% | 0.364 | `` |
| 64 | `baseline` | 2.8130e-01 | 6.9255e-04 | 0.02% | 0.378 | `` |
| 65 | `baseline` | 2.6265e-01 | 6.9255e-04 | 0.02% | 0.501 | `` |
| 66 | `baseline` | 1.7581e-01 | 6.9255e-04 | 0.02% | 0.408 | `` |
| 67 | `baseline` | 1.4402e-01 | 6.9255e-04 | 0.02% | 0.578 | `` |
| 68 | `baseline` | 1.3824e-01 | 6.9255e-04 | 0.02% | 0.360 | `` |
| 69 | `baseline` | 1.2307e-01 | 6.9255e-04 | 0.02% | 0.392 | `` |
| 70 | `baseline` | 1.0879e-01 | 6.9255e-04 | 0.02% | 0.400 | `` |
| 71 | `baseline` | 9.8581e-02 | 6.9255e-04 | 0.02% | 0.416 | `` |
| 72 | `baseline` | 9.6649e-02 | 6.9255e-04 | 0.02% | 0.564 | `` |
| 73 | `baseline` | 8.7242e-02 | 6.9255e-04 | 0.02% | 0.352 | `` |
| 74 | `baseline` | 6.7731e-02 | 6.9255e-04 | 0.02% | 0.386 | `` |
| 75 | `baseline` | 5.3754e-02 | 6.9255e-04 | 0.02% | 0.302 | `` |
| 76 | `baseline` | 9.4787e-03 | 6.9255e-04 | 0.02% | 0.408 | `` |
| 77 | `block` | 2.0700e+03 | 6.9255e-04 | 0.02% | 0.461 | `` |
| 78 | `block` | 1.9619e+03 | 6.9255e-04 | 0.02% | 0.520 | `` |
| 79 | `block` | 7.8410e+05 | 6.9255e-04 | 0.02% | 1.067 | `` |
| 80 | `block` | 7.7582e+05 | 6.9255e-04 | 0.02% | 4.767 | `` |
| 81 | `block` | 1.4118e+07 | 2.1378e+06 | 92240.96% | 0.442 | `` |
| 82 | `block` | 1.5137e+07 | 2.8353e+06 | 92241.08% | 0.517 | `` |
| 83 | `block` | 5.9086e+06 | 2.0990e+06 | 92240.97% | 0.486 | `` |
| 84 | `block` | 6.5610e+06 | 2.8009e+06 | 92241.08% | 0.499 | `` |

