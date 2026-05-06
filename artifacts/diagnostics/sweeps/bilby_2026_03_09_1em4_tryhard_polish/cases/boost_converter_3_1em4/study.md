# Tryhard Finalist Benchmark Case: boost_converter_3_1em4

- Model: `boost_converter`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T10:57:12.109`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/boost_converter_3_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/boost_converter_3_1em4`

## Comparison-Table Reference

- Classification: `a_only`
- Comparison CSV ODEPE mean/max relative error: 100.00% / Inf
- Comparison CSV ODEPE runtime: 57.317 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 54 | 385.00% | iL(0) (840.06%) | 1.6302e+03 |
| `odepe_polish` | 73 | 385.00% | iL(0) (840.06%) | 1.6302e+03 |

## Imported Raw Pool

- Raw imported candidates: 54
- Best raw fit index: 32
- Best raw oracle index: 52
- Best-fit vs best-truth combined-RMSE gap: 384.78%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.200 s
- Consensus/block context: 6.725 s
- 4x4 baseline evidence report: 0.650 s
- 4x4 block no-polish report: 3.905 s
- Polish context build: 0.033 s
- Baseline-only finalists: 112.620 s
- Additive-only finalists: 19.091 s
- Reasonable frontier finalists: 60.749 s
- Local total (excluding reference load): 203.773 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 385.00% | 385.00% | 53 | `raw` | 1.6302e+03 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 385.00% | 385.00% | 73 | `benchmark` | 1.6302e+03 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 12531894177.75% | 12531894177.75% | 20 | `block` | 2.6226e+04 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 2814960.53% | 0.22% | 52 | `baseline` | 2.3736e+04 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 329.01% | 329.01% | 20 | `block` | 6.7162e+03 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 2814960.53% | 0.22% | 67 | `baseline` | 2.3736e+04 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 51 / 0.22%
- Additive best finalist index / RMSE: 1 / 329.01%
- Frontier best finalist index / RMSE: 66 / 0.22%
- Baseline preserved seeds: 53
- Additive candidate seeds: 20
- Frontier admitted seeds: 68
- Rejected additive seeds: 5
- Successful merged polished seeds: 68
- Returned merged finalists: 67

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 5.4222e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 1.5569e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 1.1973e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 9.9378e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 8.1155e+05 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 4.0491e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 2.5733e+05 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.2757e+05 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 1.2858e+05 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 1.1482e+05 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 6.1490e+04 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 4.6743e+04 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 5.4319e+04 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 4.0084e+04 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 3.8482e+04 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 3.0807e+04 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 2.9984e+04 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 3.2395e+04 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 2.7166e+04 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 2.4326e+04 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 2.4227e+04 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 2.4116e+04 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 2.3885e+04 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 2.3806e+04 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 2.3781e+04 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 2.3789e+04 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 2.3773e+04 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | Inf | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 1.9494e+04 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 1.9002e+04 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | Inf | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 1.6302e+03 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | Inf | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | Inf | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | Inf | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | Inf | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | Inf | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | Inf | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | Inf | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | Inf | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | Inf | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | Inf | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | Inf | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | Inf | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | Inf | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | Inf | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | Inf | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | Inf | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | Inf | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | Inf | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | Inf | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | Inf | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | Inf | method=algebraic, source=imported, candidate=53 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 2.6226e+04 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.0002 | 2.6360e+04 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.0349 | 2.8773e+04 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.0540 | 6.4354e+04 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.1363 | 7.4713e+04 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.1517 | 4.2000e+04 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.2222 | 3.0390e+06 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.2322 | 5.6365e+04 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.2330 | 7.5552e+04 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.3423 | 2.8185e+07 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.4245 | 2.5228e+07 | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.4608 | 4.6754e+08 | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.4722 | 4.4651e+08 | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.4788 | 6.4088e+08 | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 0.4916 | 6.1613e+08 | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 0.9167 | Inf | method=direct_opt, source=assembled |
| 17 | `block` | 17 | 0.9238 | 5.7700e+11 | method=direct_opt, source=assembled |
| 18 | `block` | 18 | 0.9469 | 5.7455e+11 | method=direct_opt, source=assembled |
| 19 | `block` | 19 | 0.9635 | Inf | method=direct_opt, source=assembled |
| 20 | `block` | 20 | 1.0000 | Inf | method=direct_opt, source=assembled |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 2 | `block` | `catastrophic_fit` | 5.7700e+11 | method=direct_opt, source=assembled |
| 3 | `block` | `catastrophic_fit` | 5.7455e+11 | method=direct_opt, source=assembled |
| 4 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 5 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 5.4222e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 1.5569e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 1.1973e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 9.9378e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 8.1155e+05 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 4.0491e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 2.5733e+05 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.2757e+05 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 1.2858e+05 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 1.1482e+05 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 6.1490e+04 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 4.6743e+04 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 5.4319e+04 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 4.0084e+04 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 3.8482e+04 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 3.0807e+04 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 2.9984e+04 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 3.2395e+04 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 2.7166e+04 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 2.4326e+04 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 2.4227e+04 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 2.4116e+04 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 2.3885e+04 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 2.3806e+04 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 2.3781e+04 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 2.3789e+04 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 2.3773e+04 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | Inf | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 1.9494e+04 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 1.9002e+04 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | Inf | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 1.6302e+03 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | Inf | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | Inf | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | Inf | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | Inf | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | Inf | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | Inf | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | Inf | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | Inf | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | Inf | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | Inf | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | Inf | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | Inf | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | Inf | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | Inf | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | Inf | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | Inf | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | Inf | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | Inf | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | Inf | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | Inf | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | Inf | method=algebraic, source=imported, candidate=53 |
| 54 | `block` | `block#1` | 2.6226e+04 | method=direct_opt, source=assembled |
| 55 | `block` | `block#2` | 2.6360e+04 | method=direct_opt, source=assembled |
| 56 | `block` | `block#3` | 2.8773e+04 | method=direct_opt, source=assembled |
| 57 | `block` | `block#4` | 6.4354e+04 | method=direct_opt, source=assembled |
| 58 | `block` | `block#5` | 7.4713e+04 | method=direct_opt, source=assembled |
| 59 | `block` | `block#6` | 4.2000e+04 | method=direct_opt, source=assembled |
| 60 | `block` | `block#7` | 3.0390e+06 | method=direct_opt, source=assembled |
| 61 | `block` | `block#8` | 5.6365e+04 | method=direct_opt, source=assembled |
| 62 | `block` | `block#9` | 7.5552e+04 | method=direct_opt, source=assembled |
| 63 | `block` | `block#10` | 2.8185e+07 | method=direct_opt, source=assembled |
| 64 | `block` | `block#11` | 2.5228e+07 | method=direct_opt, source=assembled |
| 65 | `block` | `block#12` | 4.6754e+08 | method=direct_opt, source=assembled |
| 66 | `block` | `block#13` | 4.4651e+08 | method=direct_opt, source=assembled |
| 67 | `block` | `block#14` | 6.4088e+08 | method=direct_opt, source=assembled |
| 68 | `block` | `block#15` | 6.1613e+08 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `baseline` | 2 | 2.3736e+04 | 2814960.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 2 | `baseline` | 1 | 1.6302e+03 | 385.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 3 | `block` | 1 | 6.7162e+03 | 329.01% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 4 | `baseline` | 1 | 1.9002e+04 | 511.68% | 0 | 0.5000 | method=algebraic, source=imported, candidate=30, polished=true |
| 5 | `baseline` | 1 | 1.9494e+04 | 527.10% | 0 | 0.5000 | method=algebraic, source=imported, candidate=29, polished=true |
| 6 | `block` | 1 | 2.1104e+04 | 1969.88% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 7 | `baseline` | 1 | 2.3345e+04 | 5224.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 8 | `baseline` | 1 | 2.3412e+04 | 5797.07% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 9 | `baseline` | 1 | 2.3516e+04 | 13347.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 10 | `baseline` | 1 | 2.3712e+04 | 1607259.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 11 | `baseline` | 1 | 2.3712e+04 | 1430118.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 12 | `baseline` | 1 | 2.3712e+04 | 1408873.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 13 | `baseline` | 1 | 2.3712e+04 | 1261773.67% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 14 | `baseline` | 1 | 2.3713e+04 | 1177637.28% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 15 | `baseline` | 1 | 2.3713e+04 | 1174555.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 16 | `block` | 1 | 2.3735e+04 | 559231.68% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 17 | `baseline` | 1 | 2.3736e+04 | 3158233.09% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 18 | `baseline` | 1 | 2.3736e+04 | 2798587.54% | 0 | 0.5000 | method=algebraic, source=imported, candidate=22, polished=true |
| 19 | `baseline` | 1 | 2.3736e+04 | 2777484.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 20 | `baseline` | 1 | 2.3736e+04 | 2721586.35% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 21 | `baseline` | 1 | 2.3736e+04 | 2622216.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 22 | `baseline` | 1 | 2.3736e+04 | 2564543.99% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 23 | `block` | 1 | 2.3738e+04 | 12531893883.22% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 24 | `block` | 1 | 2.3738e+04 | 12531893883.25% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 25 | `block` | 1 | 2.3738e+04 | 12531893883.28% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 26 | `baseline` | 1 | 2.3738e+04 | 1188149.65% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 27 | `baseline` | 1 | 2.3738e+04 | 1068135.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 28 | `baseline` | 1 | 2.3738e+04 | 1159007.99% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 29 | `baseline` | 1 | 2.3740e+04 | 2626682.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=26, polished=true |
| 30 | `block` | 1 | 2.3740e+04 | 19400684041.42% | 0 | 0.4979 | method=direct_opt, source=assembled, polished=true |
| 31 | `baseline` | 1 | 2.3740e+04 | 2442210.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 32 | `baseline` | 1 | 2.3740e+04 | 2234678.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=25, polished=true |
| 33 | `baseline` | 1 | 2.3740e+04 | 3280609.66% | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 34 | `block` | 1 | 2.3766e+04 | 383480.32% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 35 | `block` | 1 | 2.3813e+04 | 752982.23% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 36 | `block` | 1 | 2.3849e+04 | 1691879.58% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 37 | `block` | 1 | 2.8348e+04 | 12531893881.70% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 38 | `block` | 1 | 3.4602e+04 | 333.20% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 39 | `baseline` | 1 | 3.9697e+04 | 12531894023.82% | 0 | 0.4987 | method=algebraic, source=imported, candidate=5, polished=true |
| 40 | `block` | 1 | 4.0093e+04 | 12531893881.70% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 41 | `block` | 1 | 5.4991e+04 | 1970.58% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 42 | `baseline` | 1 | 7.2959e+04 | 850302.75% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 43 | `baseline` | 1 | 1.5569e+06 | 2901.22% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 44 | `block` | 1 | 2.4160e+06 | 12531893881.70% | 0 | 0.4987 | method=direct_opt, source=assembled, polished=true |
| 45 | `baseline` | 1 | Inf | 174.50% | 0 | 0.5000 | method=algebraic, source=imported, candidate=28, polished=true |
| 46 | `baseline` | 1 | Inf | 1043.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=31, polished=true |
| 47 | `baseline` | 1 | Inf | 405.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=33, polished=true |
| 48 | `baseline` | 1 | Inf | 629.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=34, polished=true |
| 49 | `baseline` | 1 | Inf | 359.34% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 50 | `baseline` | 1 | Inf | 36.29% | 0 | 0.5000 | method=algebraic, source=imported, candidate=36, polished=true |
| 51 | `baseline` | 1 | Inf | 35.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 52 | `baseline` | 1 | Inf | 32.24% | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |
| 53 | `baseline` | 1 | Inf | 27.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=39, polished=true |
| 54 | `baseline` | 1 | Inf | 23.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |
| 55 | `baseline` | 1 | Inf | 8.07% | 0 | 0.5000 | method=algebraic, source=imported, candidate=41, polished=true |
| 56 | `baseline` | 1 | Inf | 15.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 57 | `baseline` | 1 | Inf | 13.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=43, polished=true |
| 58 | `baseline` | 1 | Inf | 53.26% | 0 | 0.5000 | method=algebraic, source=imported, candidate=44, polished=true |
| 59 | `baseline` | 1 | Inf | 14.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 60 | `baseline` | 1 | Inf | 14.11% | 0 | 0.5000 | method=algebraic, source=imported, candidate=46, polished=true |
| 61 | `baseline` | 1 | Inf | 5.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=47, polished=true |
| 62 | `baseline` | 1 | Inf | 82.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=48, polished=true |
| 63 | `baseline` | 1 | Inf | 30.26% | 0 | 0.5000 | method=algebraic, source=imported, candidate=49, polished=true |
| 64 | `baseline` | 1 | Inf | 0.66% | 0 | 0.5000 | method=algebraic, source=imported, candidate=50, polished=true |
| 65 | `baseline` | 1 | Inf | 13.86% | 0 | 0.5000 | method=algebraic, source=imported, candidate=51, polished=true |
| 66 | `baseline` | 1 | Inf | 0.22% | 0 | 0.5000 | method=algebraic, source=imported, candidate=52, polished=true |
| 67 | `baseline` | 1 | Inf | 0.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=53, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 5.4222e+06 | 7.2959e+04 | 850302.75% | 3.281 | `` |
| 2 | `baseline` | 1.5569e+06 | 1.5569e+06 | 2901.22% | 0.166 | `` |
| 3 | `baseline` | 1.1973e+06 | 2.3412e+04 | 5797.07% | 2.114 | `` |
| 4 | `baseline` | 9.9378e+05 | 2.3713e+04 | 1177637.28% | 1.788 | `` |
| 5 | `baseline` | 8.1155e+05 | 3.9697e+04 | 12531894023.82% | 0.259 | `` |
| 6 | `baseline` | 4.0491e+05 | 2.3740e+04 | 3280609.66% | 2.013 | `` |
| 7 | `baseline` | 2.5733e+05 | 2.3738e+04 | 1068135.72% | 1.602 | `` |
| 8 | `baseline` | 2.2757e+05 | 2.3738e+04 | 1188149.65% | 1.475 | `` |
| 9 | `baseline` | 1.2858e+05 | 2.3736e+04 | 2564543.99% | 1.584 | `` |
| 10 | `baseline` | 1.1482e+05 | 2.3713e+04 | 1174555.84% | 1.691 | `` |
| 11 | `baseline` | 6.1490e+04 | 2.3345e+04 | 5224.43% | 2.456 | `` |
| 12 | `baseline` | 4.6743e+04 | 2.3738e+04 | 1159007.99% | 1.375 | `` |
| 13 | `baseline` | 5.4319e+04 | 2.3712e+04 | 1430118.19% | 1.432 | `` |
| 14 | `baseline` | 4.0084e+04 | 2.3736e+04 | 2622216.72% | 1.487 | `` |
| 15 | `baseline` | 3.8482e+04 | 2.3736e+04 | 2721586.35% | 1.497 | `` |
| 16 | `baseline` | 3.0807e+04 | 2.3736e+04 | 2814960.53% | 1.331 | `` |
| 17 | `baseline` | 2.9984e+04 | 2.3736e+04 | 2777484.85% | 1.489 | `` |
| 18 | `baseline` | 3.2395e+04 | 2.3736e+04 | 2812161.78% | 1.546 | `` |
| 19 | `baseline` | 2.7166e+04 | 2.3712e+04 | 1408873.49% | 1.475 | `` |
| 20 | `baseline` | 2.4326e+04 | 2.3712e+04 | 1261773.67% | 1.265 | `` |
| 21 | `baseline` | 2.4227e+04 | 2.3712e+04 | 1607259.48% | 1.440 | `` |
| 22 | `baseline` | 2.4116e+04 | 2.3736e+04 | 2798587.54% | 1.520 | `` |
| 23 | `baseline` | 2.3885e+04 | 2.3516e+04 | 13347.02% | 1.706 | `` |
| 24 | `baseline` | 2.3806e+04 | 2.3740e+04 | 2442210.97% | 1.418 | `` |
| 25 | `baseline` | 2.3781e+04 | 2.3740e+04 | 2234678.43% | 1.365 | `` |
| 26 | `baseline` | 2.3789e+04 | 2.3740e+04 | 2626682.15% | 1.418 | `` |
| 27 | `baseline` | 2.3773e+04 | 2.3736e+04 | 3158233.09% | 1.507 | `` |
| 28 | `baseline` | Inf | Inf | 174.50% | 0.156 | `` |
| 29 | `baseline` | 1.9494e+04 | 1.9494e+04 | 527.10% | 0.169 | `` |
| 30 | `baseline` | 1.9002e+04 | 1.9002e+04 | 511.68% | 0.173 | `` |
| 31 | `baseline` | Inf | Inf | 1043.19% | 0.158 | `` |
| 32 | `baseline` | 1.6302e+03 | 1.6302e+03 | 385.00% | 0.166 | `` |
| 33 | `baseline` | Inf | Inf | 405.51% | 0.165 | `` |
| 34 | `baseline` | Inf | Inf | 629.01% | 0.158 | `` |
| 35 | `baseline` | Inf | Inf | 359.34% | 0.314 | `` |
| 36 | `baseline` | Inf | Inf | 36.29% | 0.143 | `` |
| 37 | `baseline` | Inf | Inf | 35.78% | 0.143 | `` |
| 38 | `baseline` | Inf | Inf | 32.24% | 0.159 | `` |
| 39 | `baseline` | Inf | Inf | 27.70% | 0.167 | `` |
| 40 | `baseline` | Inf | Inf | 23.00% | 0.169 | `` |
| 41 | `baseline` | Inf | Inf | 8.07% | 0.161 | `` |
| 42 | `baseline` | Inf | Inf | 15.06% | 0.158 | `` |
| 43 | `baseline` | Inf | Inf | 13.13% | 0.160 | `` |
| 44 | `baseline` | Inf | Inf | 53.26% | 0.167 | `` |
| 45 | `baseline` | Inf | Inf | 14.89% | 0.155 | `` |
| 46 | `baseline` | Inf | Inf | 14.11% | 0.161 | `` |
| 47 | `baseline` | Inf | Inf | 5.70% | 0.159 | `` |
| 48 | `baseline` | Inf | Inf | 82.02% | 0.163 | `` |
| 49 | `baseline` | Inf | Inf | 30.26% | 0.309 | `` |
| 50 | `baseline` | Inf | Inf | 0.66% | 0.136 | `` |
| 51 | `baseline` | Inf | Inf | 13.86% | 0.134 | `` |
| 52 | `baseline` | Inf | Inf | 0.22% | 0.143 | `` |
| 53 | `baseline` | Inf | Inf | 0.63% | 0.155 | `` |
| 54 | `block` | 2.6226e+04 | 2.3738e+04 | 12531893883.28% | 1.248 | `` |
| 55 | `block` | 2.6360e+04 | 2.3738e+04 | 12531893883.22% | 1.297 | `` |
| 56 | `block` | 2.8773e+04 | 6.7162e+03 | 329.01% | 0.139 | `` |
| 57 | `block` | 6.4354e+04 | 2.3740e+04 | 19400684041.42% | 1.256 | `` |
| 58 | `block` | 7.4713e+04 | 2.8348e+04 | 12531893881.70% | 0.307 | `` |
| 59 | `block` | 4.2000e+04 | 2.1104e+04 | 1969.88% | 0.152 | `` |
| 60 | `block` | 3.0390e+06 | 2.3738e+04 | 12531893883.25% | 1.196 | `` |
| 61 | `block` | 5.6365e+04 | 3.4602e+04 | 333.20% | 0.149 | `` |
| 62 | `block` | 7.5552e+04 | 5.4991e+04 | 1970.58% | 0.170 | `` |
| 63 | `block` | 2.8185e+07 | 4.0093e+04 | 12531893881.70% | 0.462 | `` |
| 64 | `block` | 2.5228e+07 | 2.4160e+06 | 12531893881.70% | 0.581 | `` |
| 65 | `block` | 4.6754e+08 | 2.3813e+04 | 752982.23% | 1.772 | `` |
| 66 | `block` | 4.4651e+08 | 2.3766e+04 | 383480.32% | 1.863 | `` |
| 67 | `block` | 6.4088e+08 | 2.3849e+04 | 1691879.58% | 2.161 | `` |
| 68 | `block` | 6.1613e+08 | 2.3735e+04 | 559231.68% | 1.895 | `` |

