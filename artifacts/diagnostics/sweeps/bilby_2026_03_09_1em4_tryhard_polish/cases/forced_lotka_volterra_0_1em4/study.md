# Tryhard Finalist Benchmark Case: forced_lotka_volterra_0_1em4

- Model: `forced_lotka_volterra`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T10:52:16.523`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/forced_lotka_volterra_0_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/forced_lotka_volterra_0_1em4`

## Comparison-Table Reference

- Classification: `a_only`
- Comparison CSV ODEPE mean/max relative error: 8.53% / 19.06%
- Comparison CSV ODEPE runtime: 2140.916 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 70 | 11.00% | beta (19.16%) | 3.9653e+00 |
| `odepe_polish` | 83 | 0.00% | delta (0.00%) | 2.5707e-05 |

## Imported Raw Pool

- Raw imported candidates: 70
- Best raw fit index: 70
- Best raw oracle index: 68
- Best-fit vs best-truth combined-RMSE gap: 0.14%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.094 s
- Consensus/block context: 7.584 s
- 4x4 baseline evidence report: 0.785 s
- 4x4 block no-polish report: 3.820 s
- Polish context build: 0.005 s
- Baseline-only finalists: 159.537 s
- Additive-only finalists: 23.744 s
- Reasonable frontier finalists: 88.072 s
- Local total (excluding reference load): 283.546 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 11.00% | 11.00% | 52 | `raw` | 3.9653e+00 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 0.00% | 0.00% | 83 | `benchmark` | 2.5707e-05 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 27.49% | 27.49% | 16 | `block` | 1.7023e+03 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.00% | 0.00% | 19 | `baseline` | 2.5671e-05 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.00% | 0.00% | 14 | `block` | 2.5671e-05 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.00% | 0.00% | 22 | `baseline+block` | 2.5671e-05 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `tie`
- Improvement mode: `no_improvement`
- Baseline best finalist index / RMSE: 1 / 0.00%
- Additive best finalist index / RMSE: 1 / 0.00%
- Frontier best finalist index / RMSE: 1 / 0.00%
- Baseline preserved seeds: 52
- Additive candidate seeds: 16
- Frontier admitted seeds: 57
- Rejected additive seeds: 11
- Successful merged polished seeds: 57
- Returned merged finalists: 22

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 2.9429e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 1.2238e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 1.0264e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 3.3751e+04 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 1.1491e+04 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 3.6107e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.8500e+03 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 2.6934e+03 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | Inf | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 16 | 2.4788e+03 | method=algebraic, source=imported, candidate=16 |
| 12 | `baseline` | 17 | 2.0796e+03 | method=algebraic, source=imported, candidate=17 |
| 13 | `baseline` | 18 | 2.0827e+03 | method=algebraic, source=imported, candidate=18 |
| 14 | `baseline` | 19 | 2.0713e+03 | method=algebraic, source=imported, candidate=19 |
| 15 | `baseline` | 20 | 1.9617e+03 | method=algebraic, source=imported, candidate=20 |
| 16 | `baseline` | 21 | 1.3838e+03 | method=algebraic, source=imported, candidate=21 |
| 17 | `baseline` | 22 | 1.4161e+03 | method=algebraic, source=imported, candidate=22 |
| 18 | `baseline` | 23 | 1.6666e+03 | method=algebraic, source=imported, candidate=23 |
| 19 | `baseline` | 24 | 1.3944e+03 | method=algebraic, source=imported, candidate=24 |
| 20 | `baseline` | 25 | 1.3761e+03 | method=algebraic, source=imported, candidate=25 |
| 21 | `baseline` | 26 | 1.3538e+03 | method=algebraic, source=imported, candidate=26 |
| 22 | `baseline` | 30 | 1.3268e+03 | method=algebraic, source=imported, candidate=30 |
| 23 | `baseline` | 31 | 1.5630e+03 | method=algebraic, source=imported, candidate=31 |
| 24 | `baseline` | 32 | Inf | method=algebraic, source=imported, candidate=32 |
| 25 | `baseline` | 33 | 1.4678e+03 | method=algebraic, source=imported, candidate=33 |
| 26 | `baseline` | 34 | 1.4566e+03 | method=algebraic, source=imported, candidate=34 |
| 27 | `baseline` | 35 | 1.0034e+03 | method=algebraic, source=imported, candidate=35 |
| 28 | `baseline` | 36 | 9.8435e+02 | method=algebraic, source=imported, candidate=36 |
| 29 | `baseline` | 37 | 8.2760e+02 | method=algebraic, source=imported, candidate=37 |
| 30 | `baseline` | 38 | 6.3897e+02 | method=algebraic, source=imported, candidate=38 |
| 31 | `baseline` | 39 | 6.5370e+02 | method=algebraic, source=imported, candidate=39 |
| 32 | `baseline` | 40 | 3.8665e+02 | method=algebraic, source=imported, candidate=40 |
| 33 | `baseline` | 41 | 3.6526e+02 | method=algebraic, source=imported, candidate=41 |
| 34 | `baseline` | 42 | Inf | method=algebraic, source=imported, candidate=42 |
| 35 | `baseline` | 43 | 3.1027e+02 | method=algebraic, source=imported, candidate=43 |
| 36 | `baseline` | 44 | Inf | method=algebraic, source=imported, candidate=44 |
| 37 | `baseline` | 45 | 1.7043e+02 | method=algebraic, source=imported, candidate=45 |
| 38 | `baseline` | 46 | 1.3195e+02 | method=algebraic, source=imported, candidate=46 |
| 39 | `baseline` | 47 | 1.1673e+02 | method=algebraic, source=imported, candidate=47 |
| 40 | `baseline` | 48 | 1.1603e+02 | method=algebraic, source=imported, candidate=48 |
| 41 | `baseline` | 55 | 1.1203e+02 | method=algebraic, source=imported, candidate=55 |
| 42 | `baseline` | 58 | 9.0253e+01 | method=algebraic, source=imported, candidate=58 |
| 43 | `baseline` | 60 | 9.0033e+01 | method=algebraic, source=imported, candidate=60 |
| 44 | `baseline` | 61 | 8.8885e+01 | method=algebraic, source=imported, candidate=61 |
| 45 | `baseline` | 62 | 1.2266e+02 | method=algebraic, source=imported, candidate=62 |
| 46 | `baseline` | 63 | 4.3687e+01 | method=algebraic, source=imported, candidate=63 |
| 47 | `baseline` | 64 | 1.6706e+01 | method=algebraic, source=imported, candidate=64 |
| 48 | `baseline` | 65 | 1.5457e+01 | method=algebraic, source=imported, candidate=65 |
| 49 | `baseline` | 66 | 1.5266e+01 | method=algebraic, source=imported, candidate=66 |
| 50 | `baseline` | 68 | 9.6077e+00 | method=algebraic, source=imported, candidate=68 |
| 51 | `baseline` | 69 | 6.7005e+00 | method=algebraic, source=imported, candidate=69 |
| 52 | `baseline` | 70 | 3.9653e+00 | method=algebraic, source=imported, candidate=70 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 1.7023e+03 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0393 | 3.3827e+03 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.1969 | 5.0582e+04 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.1978 | 5.1079e+04 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.4432 | 3.8892e+06 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.4440 | 3.9248e+06 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.7055 | 3.5044e+08 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.7077 | 3.6626e+08 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.9741 | Inf | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.9788 | Inf | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.9809 | Inf | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.9837 | Inf | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.9883 | Inf | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.9904 | Inf | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 0.9952 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 1.0000 | Inf | method=direct_opt, source=assembled |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `block` | `duplicate` | 1.7023e+03 | method=direct_opt, source=assembled |
| 2 | `block` | `catastrophic_fit` | 3.5044e+08 | method=direct_opt, source=assembled |
| 3 | `block` | `catastrophic_fit` | 3.6626e+08 | method=direct_opt, source=assembled |
| 4 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 5 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 6 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 7 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 8 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 9 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 10 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 11 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 2.9429e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 1.2238e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 1.0264e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 3.3751e+04 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 1.1491e+04 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 3.6107e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.8500e+03 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 2.6934e+03 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | Inf | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#16` | 2.4788e+03 | method=algebraic, source=imported, candidate=16 |
| 12 | `baseline` | `baseline#17` | 2.0796e+03 | method=algebraic, source=imported, candidate=17 |
| 13 | `baseline` | `baseline#18` | 2.0827e+03 | method=algebraic, source=imported, candidate=18 |
| 14 | `baseline` | `baseline#19` | 2.0713e+03 | method=algebraic, source=imported, candidate=19 |
| 15 | `baseline` | `baseline#20` | 1.9617e+03 | method=algebraic, source=imported, candidate=20 |
| 16 | `baseline` | `baseline#21` | 1.3838e+03 | method=algebraic, source=imported, candidate=21 |
| 17 | `baseline` | `baseline#22` | 1.4161e+03 | method=algebraic, source=imported, candidate=22 |
| 18 | `baseline` | `baseline#23` | 1.6666e+03 | method=algebraic, source=imported, candidate=23 |
| 19 | `baseline` | `baseline#24` | 1.3944e+03 | method=algebraic, source=imported, candidate=24 |
| 20 | `baseline` | `baseline#25` | 1.3761e+03 | method=algebraic, source=imported, candidate=25 |
| 21 | `baseline` | `baseline#26` | 1.3538e+03 | method=algebraic, source=imported, candidate=26 |
| 22 | `baseline` | `baseline#30` | 1.3268e+03 | method=algebraic, source=imported, candidate=30 |
| 23 | `baseline` | `baseline#31` | 1.5630e+03 | method=algebraic, source=imported, candidate=31 |
| 24 | `baseline` | `baseline#32` | Inf | method=algebraic, source=imported, candidate=32 |
| 25 | `baseline` | `baseline#33` | 1.4678e+03 | method=algebraic, source=imported, candidate=33 |
| 26 | `baseline` | `baseline#34` | 1.4566e+03 | method=algebraic, source=imported, candidate=34 |
| 27 | `baseline` | `baseline#35` | 1.0034e+03 | method=algebraic, source=imported, candidate=35 |
| 28 | `baseline` | `baseline#36` | 9.8435e+02 | method=algebraic, source=imported, candidate=36 |
| 29 | `baseline` | `baseline#37` | 8.2760e+02 | method=algebraic, source=imported, candidate=37 |
| 30 | `baseline` | `baseline#38` | 6.3897e+02 | method=algebraic, source=imported, candidate=38 |
| 31 | `baseline` | `baseline#39` | 6.5370e+02 | method=algebraic, source=imported, candidate=39 |
| 32 | `baseline` | `baseline#40` | 3.8665e+02 | method=algebraic, source=imported, candidate=40 |
| 33 | `baseline` | `baseline#41` | 3.6526e+02 | method=algebraic, source=imported, candidate=41 |
| 34 | `baseline` | `baseline#42` | Inf | method=algebraic, source=imported, candidate=42 |
| 35 | `baseline` | `baseline#43` | 3.1027e+02 | method=algebraic, source=imported, candidate=43 |
| 36 | `baseline` | `baseline#44` | Inf | method=algebraic, source=imported, candidate=44 |
| 37 | `baseline` | `baseline#45` | 1.7043e+02 | method=algebraic, source=imported, candidate=45 |
| 38 | `baseline` | `baseline#46` | 1.3195e+02 | method=algebraic, source=imported, candidate=46 |
| 39 | `baseline` | `baseline#47` | 1.1673e+02 | method=algebraic, source=imported, candidate=47 |
| 40 | `baseline` | `baseline#48` | 1.1603e+02 | method=algebraic, source=imported, candidate=48 |
| 41 | `baseline` | `baseline#55` | 1.1203e+02 | method=algebraic, source=imported, candidate=55 |
| 42 | `baseline` | `baseline#58` | 9.0253e+01 | method=algebraic, source=imported, candidate=58 |
| 43 | `baseline` | `baseline#60` | 9.0033e+01 | method=algebraic, source=imported, candidate=60 |
| 44 | `baseline` | `baseline#61` | 8.8885e+01 | method=algebraic, source=imported, candidate=61 |
| 45 | `baseline` | `baseline#62` | 1.2266e+02 | method=algebraic, source=imported, candidate=62 |
| 46 | `baseline` | `baseline#63` | 4.3687e+01 | method=algebraic, source=imported, candidate=63 |
| 47 | `baseline` | `baseline#64` | 1.6706e+01 | method=algebraic, source=imported, candidate=64 |
| 48 | `baseline` | `baseline#65` | 1.5457e+01 | method=algebraic, source=imported, candidate=65 |
| 49 | `baseline` | `baseline#66` | 1.5266e+01 | method=algebraic, source=imported, candidate=66 |
| 50 | `baseline` | `baseline#68` | 9.6077e+00 | method=algebraic, source=imported, candidate=68 |
| 51 | `baseline` | `baseline#69` | 6.7005e+00 | method=algebraic, source=imported, candidate=69 |
| 52 | `baseline` | `baseline#70` | 3.9653e+00 | method=algebraic, source=imported, candidate=70 |
| 53 | `block` | `block#2` | 3.3827e+03 | method=direct_opt, source=assembled |
| 54 | `block` | `block#3` | 5.0582e+04 | method=direct_opt, source=assembled |
| 55 | `block` | `block#4` | 5.1079e+04 | method=direct_opt, source=assembled |
| 56 | `block` | `block#5` | 3.8892e+06 | method=direct_opt, source=assembled |
| 57 | `block` | `block#6` | 3.9248e+06 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 36 | 2.5671e-05 | 0.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=30, polished=true |
| 2 | `block` | 1 | 1.8509e+02 | 730.48% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 3 | `baseline` | 1 | 2.2803e+02 | 2802.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=39, polished=true |
| 4 | `baseline` | 1 | 2.4028e+02 | 63862.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 5 | `baseline` | 1 | 3.8665e+02 | 9986.30% | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |
| 6 | `baseline` | 1 | 9.4696e+02 | 935.98% | 0 | 0.5000 | method=algebraic, source=imported, candidate=18, polished=true |
| 7 | `baseline` | 1 | 1.0034e+03 | 10893.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 8 | `baseline` | 1 | 1.0504e+03 | 2293.35% | 0 | 0.5000 | method=algebraic, source=imported, candidate=34, polished=true |
| 9 | `baseline` | 1 | 1.1937e+03 | 5354.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 10 | `baseline` | 1 | 1.2318e+03 | 7820.28% | 0 | 0.5000 | method=algebraic, source=imported, candidate=31, polished=true |
| 11 | `baseline` | 1 | 1.4764e+03 | 9863.56% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 12 | `baseline` | 1 | 1.9617e+03 | 101676.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 13 | `baseline` | 1 | 2.4596e+03 | 2350.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 14 | `baseline` | 1 | 2.6891e+03 | 117844.68% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 15 | `baseline` | 1 | 2.9429e+06 | 38085.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 16 | `baseline` | 1 | Inf | 4926.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 17 | `baseline` | 1 | Inf | 1273837.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 18 | `baseline` | 1 | Inf | 58974.71% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 19 | `baseline` | 1 | Inf | 67645.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 20 | `baseline` | 1 | Inf | 55037.08% | 0 | 0.5000 | method=algebraic, source=imported, candidate=44, polished=true |
| 21 | `block` | 1 | Inf | 33241.17% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 22 | `block` | 1 | Inf | 33241.27% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | Inf | Inf | 4926.17% | 0.307 | `` |
| 2 | `baseline` | 2.9429e+06 | 2.9429e+06 | 38085.90% | 0.157 | `` |
| 3 | `baseline` | 1.2238e+05 | 2.5671e-05 | 0.00% | 0.442 | `` |
| 4 | `baseline` | 1.0264e+05 | 2.4596e+03 | 2350.90% | 7.685 | `` |
| 5 | `baseline` | 3.3751e+04 | 2.5671e-05 | 0.00% | 0.776 | `` |
| 6 | `baseline` | 1.1491e+04 | 2.5671e-05 | 0.00% | 1.155 | `` |
| 7 | `baseline` | 3.6107e+03 | 2.5671e-05 | 0.00% | 0.526 | `` |
| 8 | `baseline` | 2.8500e+03 | 2.5671e-05 | 0.00% | 0.326 | `` |
| 9 | `baseline` | 2.6934e+03 | 2.6891e+03 | 117844.68% | 0.708 | `` |
| 10 | `baseline` | Inf | Inf | 1273837.00% | 0.256 | `` |
| 11 | `baseline` | 2.4788e+03 | 2.5671e-05 | 0.00% | 0.341 | `` |
| 12 | `baseline` | 2.0796e+03 | 2.5671e-05 | 0.00% | 0.438 | `` |
| 13 | `baseline` | 2.0827e+03 | 9.4696e+02 | 935.98% | 4.455 | `` |
| 14 | `baseline` | 2.0713e+03 | 1.4764e+03 | 9863.56% | 7.544 | `` |
| 15 | `baseline` | 1.9617e+03 | 1.9617e+03 | 101676.64% | 0.186 | `` |
| 16 | `baseline` | 1.3838e+03 | 2.4028e+02 | 63862.48% | 12.814 | `` |
| 17 | `baseline` | 1.4161e+03 | 2.5671e-05 | 0.00% | 0.431 | `` |
| 18 | `baseline` | 1.6666e+03 | 1.1937e+03 | 5354.13% | 7.179 | `` |
| 19 | `baseline` | 1.3944e+03 | 2.5671e-05 | 0.00% | 0.537 | `` |
| 20 | `baseline` | 1.3761e+03 | 2.5671e-05 | 0.00% | 0.512 | `` |
| 21 | `baseline` | 1.3538e+03 | 2.5671e-05 | 0.00% | 0.416 | `` |
| 22 | `baseline` | 1.3268e+03 | 2.5671e-05 | 0.00% | 0.510 | `` |
| 23 | `baseline` | 1.5630e+03 | 1.2318e+03 | 7820.28% | 12.116 | `` |
| 24 | `baseline` | Inf | Inf | 58974.71% | 0.195 | `` |
| 25 | `baseline` | 1.4678e+03 | 2.5671e-05 | 0.00% | 0.725 | `` |
| 26 | `baseline` | 1.4566e+03 | 1.0504e+03 | 2293.35% | 2.155 | `` |
| 27 | `baseline` | 1.0034e+03 | 1.0034e+03 | 10893.57% | 0.202 | `` |
| 28 | `baseline` | 9.8435e+02 | 2.5671e-05 | 0.00% | 0.672 | `` |
| 29 | `baseline` | 8.2760e+02 | 2.5671e-05 | 0.00% | 0.348 | `` |
| 30 | `baseline` | 6.3897e+02 | 2.5671e-05 | 0.00% | 0.442 | `` |
| 31 | `baseline` | 6.5370e+02 | 2.2803e+02 | 2802.45% | 12.091 | `` |
| 32 | `baseline` | 3.8665e+02 | 3.8665e+02 | 9986.30% | 0.211 | `` |
| 33 | `baseline` | 3.6526e+02 | 2.5671e-05 | 0.00% | 0.362 | `` |
| 34 | `baseline` | Inf | Inf | 67645.45% | 0.181 | `` |
| 35 | `baseline` | 3.1027e+02 | 2.5671e-05 | 0.00% | 0.288 | `` |
| 36 | `baseline` | Inf | Inf | 55037.08% | 0.198 | `` |
| 37 | `baseline` | 1.7043e+02 | 2.5671e-05 | 0.00% | 0.404 | `` |
| 38 | `baseline` | 1.3195e+02 | 2.5671e-05 | 0.00% | 0.224 | `` |
| 39 | `baseline` | 1.1673e+02 | 2.5671e-05 | 0.00% | 0.271 | `` |
| 40 | `baseline` | 1.1603e+02 | 2.5671e-05 | 0.00% | 0.354 | `` |
| 41 | `baseline` | 1.1203e+02 | 2.5671e-05 | 0.00% | 0.217 | `` |
| 42 | `baseline` | 9.0253e+01 | 2.5671e-05 | 0.00% | 0.182 | `` |
| 43 | `baseline` | 9.0033e+01 | 2.5671e-05 | 0.00% | 0.179 | `` |
| 44 | `baseline` | 8.8885e+01 | 2.5671e-05 | 0.00% | 0.278 | `` |
| 45 | `baseline` | 1.2266e+02 | 2.5671e-05 | 0.00% | 0.292 | `` |
| 46 | `baseline` | 4.3687e+01 | 2.5671e-05 | 0.00% | 0.195 | `` |
| 47 | `baseline` | 1.6706e+01 | 2.5671e-05 | 0.00% | 0.294 | `` |
| 48 | `baseline` | 1.5457e+01 | 2.5671e-05 | 0.00% | 0.183 | `` |
| 49 | `baseline` | 1.5266e+01 | 2.5671e-05 | 0.00% | 0.200 | `` |
| 50 | `baseline` | 9.6077e+00 | 2.5671e-05 | 0.00% | 0.214 | `` |
| 51 | `baseline` | 6.7005e+00 | 2.5671e-05 | 0.00% | 0.284 | `` |
| 52 | `baseline` | 3.9653e+00 | 2.5671e-05 | 0.00% | 0.176 | `` |
| 53 | `block` | 3.3827e+03 | 2.5671e-05 | 0.00% | 0.495 | `` |
| 54 | `block` | 5.0582e+04 | Inf | 33241.17% | 0.107 | `` |
| 55 | `block` | 5.1079e+04 | Inf | 33241.27% | 0.115 | `` |
| 56 | `block` | 3.8892e+06 | 1.8509e+02 | 730.48% | 3.011 | `` |
| 57 | `block` | 3.9248e+06 | 2.5671e-05 | 0.00% | 2.505 | `` |

