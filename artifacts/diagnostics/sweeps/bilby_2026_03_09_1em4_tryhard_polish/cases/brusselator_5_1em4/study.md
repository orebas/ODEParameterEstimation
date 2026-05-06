# Tryhard Finalist Benchmark Case: brusselator_5_1em4

- Model: `brusselator`
- Role: `guard`
- Selected via: `requested`
- Generated: `2026-04-15T12:18:32.969`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/brusselator_5_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/brusselator_5_1em4`

## Comparison-Table Reference

- Classification: `both_success`
- Comparison CSV ODEPE mean/max relative error: 0.18% / 0.73%
- Comparison CSV ODEPE runtime: 5985.795 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 123 | 6.23% | b (9.38%) | Inf |
| `odepe_polish` | 123 | 6.23% | b (9.38%) | Inf |

## Imported Raw Pool

- Raw imported candidates: 123
- Best raw fit index: 1
- Best raw oracle index: 81
- Best-fit vs best-truth combined-RMSE gap: 6.17%

## Local Tryhard Runtime

- Reference CSV load/scoring: 8.865 s
- Consensus/block context: 20.256 s
- 4x4 baseline evidence report: 33.570 s
- 4x4 block no-polish report: 1.033 s
- Polish context build: 0.005 s
- Baseline-only finalists: 93.006 s
- Additive-only finalists: 6.565 s
- Reasonable frontier finalists: 9.757 s
- Local total (excluding reference load): 448.284 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 6.23% | 6.23% | 42 | `raw` | Inf | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 6.23% | 6.23% | 123 | `benchmark` | Inf | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 99.22% | 99.22% | 42 | `block` | Inf | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.09% | 0.09% | 25 | `baseline` | Inf | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.08% | 0.08% | 30 | `block+branch` | Inf | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.08% | 0.08% | 29 | `baseline+block+branch` | Inf | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 1 / 0.09%
- Additive best finalist index / RMSE: 1 / 0.08%
- Frontier best finalist index / RMSE: 1 / 0.08%
- Baseline preserved seeds: 42
- Additive candidate seeds: 42
- Frontier admitted seeds: 63
- Rejected additive seeds: 21
- Successful merged polished seeds: 63
- Post-polish basin metric: `trajectory_hybrid`
- Pre-polish distinctness threshold: 0.0010
- Post-polish trajectory threshold: 0.0200
- Post-polish secondary threshold: 1.0000
- Post-polish basin threshold: 0.0030
- Admitted additive by family: block=4, branch=19
- Rejected additive by reason/family: soft_cap/branch=21
- Merge mode counts: geometry_fallback=34
- Representative update counts: observable_loss=19
- Basin histogram: singletons=16, multi=13, largest=14
- Returned merged finalists: 29

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | Inf | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | Inf | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | Inf | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | Inf | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | Inf | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | Inf | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | Inf | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | Inf | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | Inf | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | Inf | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | Inf | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | Inf | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | Inf | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | Inf | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | Inf | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | Inf | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | Inf | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 21 | Inf | method=algebraic, source=imported, candidate=21 |
| 21 | `baseline` | 23 | Inf | method=algebraic, source=imported, candidate=23 |
| 22 | `baseline` | 24 | Inf | method=algebraic, source=imported, candidate=24 |
| 23 | `baseline` | 25 | Inf | method=algebraic, source=imported, candidate=25 |
| 24 | `baseline` | 26 | Inf | method=algebraic, source=imported, candidate=26 |
| 25 | `baseline` | 27 | Inf | method=algebraic, source=imported, candidate=27 |
| 26 | `baseline` | 29 | Inf | method=algebraic, source=imported, candidate=29 |
| 27 | `baseline` | 30 | Inf | method=algebraic, source=imported, candidate=30 |
| 28 | `baseline` | 31 | Inf | method=algebraic, source=imported, candidate=31 |
| 29 | `baseline` | 36 | Inf | method=algebraic, source=imported, candidate=36 |
| 30 | `baseline` | 37 | Inf | method=algebraic, source=imported, candidate=37 |
| 31 | `baseline` | 38 | Inf | method=algebraic, source=imported, candidate=38 |
| 32 | `baseline` | 40 | Inf | method=algebraic, source=imported, candidate=40 |
| 33 | `baseline` | 42 | Inf | method=algebraic, source=imported, candidate=42 |
| 34 | `baseline` | 43 | Inf | method=algebraic, source=imported, candidate=43 |
| 35 | `baseline` | 44 | Inf | method=algebraic, source=imported, candidate=44 |
| 36 | `baseline` | 45 | Inf | method=algebraic, source=imported, candidate=45 |
| 37 | `baseline` | 48 | Inf | method=algebraic, source=imported, candidate=48 |
| 38 | `baseline` | 49 | Inf | method=algebraic, source=imported, candidate=49 |
| 39 | `baseline` | 50 | Inf | method=algebraic, source=imported, candidate=50 |
| 40 | `baseline` | 55 | Inf | method=algebraic, source=imported, candidate=55 |
| 41 | `baseline` | 66 | Inf | method=algebraic, source=imported, candidate=66 |
| 42 | `baseline` | 78 | Inf | method=algebraic, source=imported, candidate=78 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block+branch` | 1 | 0.7000 | Inf | method=direct_opt, source=assembled |
| 1 | `block+branch` | 2 | 0.7018 | Inf | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.9974 | Inf | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 42 | `branch` | 42 | 0.4158 | Inf | method=algebraic, source=imported, candidate=40 |
| 46 | `branch` | 46 | 0.4136 | Inf | method=algebraic, source=imported, candidate=43 |
| 47 | `branch` | 47 | 0.4131 | Inf | method=algebraic, source=imported, candidate=45 |
| 48 | `branch` | 48 | 0.4130 | Inf | method=algebraic, source=imported, candidate=50 |
| 49 | `branch` | 49 | 0.4106 | Inf | method=algebraic, source=imported, candidate=37 |
| 51 | `branch` | 51 | 0.4096 | Inf | method=algebraic, source=imported, candidate=31 |
| 52 | `branch` | 52 | 0.4089 | Inf | method=algebraic, source=imported, candidate=34 |
| 54 | `branch` | 54 | 0.4084 | Inf | method=algebraic, source=imported, candidate=27 |
| 55 | `branch` | 55 | 0.4052 | Inf | method=algebraic, source=imported, candidate=17 |
| 60 | `branch` | 60 | 0.4039 | Inf | method=algebraic, source=imported, candidate=21 |
| 62 | `branch` | 62 | 0.4022 | Inf | method=algebraic, source=imported, candidate=14 |
| 63 | `branch` | 63 | 0.4020 | Inf | method=algebraic, source=imported, candidate=15 |
| 64 | `branch` | 64 | 0.4017 | Inf | method=algebraic, source=imported, candidate=25 |
| 65 | `branch` | 65 | 0.4010 | Inf | method=algebraic, source=imported, candidate=23 |
| 66 | `branch` | 66 | 0.4010 | Inf | method=algebraic, source=imported, candidate=10 |
| 68 | `branch` | 68 | 0.4000 | Inf | method=algebraic, source=imported, candidate=9 |
| 69 | `branch` | 69 | 0.3997 | Inf | method=algebraic, source=imported, candidate=36 |
| 70 | `branch` | 70 | 0.3997 | Inf | method=algebraic, source=imported, candidate=6 |
| 71 | `branch` | 71 | 0.3992 | Inf | method=algebraic, source=imported, candidate=38 |
| 72 | `branch` | 72 | 0.3978 | Inf | method=algebraic, source=imported, candidate=4 |
| 73 | `branch` | 73 | 0.3969 | Inf | method=algebraic, source=imported, candidate=48 |
| 75 | `branch` | 75 | 0.3955 | Inf | method=algebraic, source=imported, candidate=42 |
| 92 | `branch` | 92 | 0.3430 | Inf | method=algebraic, source=imported, candidate=66 |
| 102 | `branch` | 102 | 0.3152 | Inf | method=algebraic, source=imported, candidate=46 |
| 109 | `branch` | 109 | 0.2902 | Inf | method=algebraic, source=imported, candidate=28 |
| 111 | `branch` | 111 | 0.2855 | Inf | method=algebraic, source=imported, candidate=24 |
| 112 | `branch` | 112 | 0.2784 | Inf | method=algebraic, source=imported, candidate=19 |
| 113 | `branch` | 113 | 0.2763 | Inf | method=algebraic, source=imported, candidate=18 |
| 114 | `branch` | 114 | 0.2745 | Inf | method=algebraic, source=imported, candidate=16 |
| 115 | `branch` | 115 | 0.2706 | Inf | method=algebraic, source=imported, candidate=13 |
| 116 | `branch` | 116 | 0.2685 | Inf | method=algebraic, source=imported, candidate=12 |
| 117 | `branch` | 117 | 0.2651 | Inf | method=algebraic, source=imported, candidate=11 |
| 118 | `branch` | 118 | 0.2624 | Inf | method=algebraic, source=imported, candidate=8 |
| 119 | `branch` | 119 | 0.2584 | Inf | method=algebraic, source=imported, candidate=5 |
| 120 | `branch` | 120 | 0.2578 | Inf | method=algebraic, source=imported, candidate=7 |
| 121 | `branch` | 121 | 0.2542 | Inf | method=algebraic, source=imported, candidate=3 |
| 122 | `branch` | 122 | 0.2521 | Inf | method=algebraic, source=imported, candidate=2 |
| 123 | `branch` | 123 | 0.2500 | Inf | method=algebraic, source=imported, candidate=1 |

## Rejected Additive Seeds

| Rank | Sources | Reason | Dist | New Families | Fit Error | Lineage |
|------|---------|--------|------|--------------|-----------|---------|
| 1 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=9 |
| 2 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=36 |
| 3 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=6 |
| 4 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=38 |
| 5 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=4 |
| 6 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=48 |
| 7 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=42 |
| 8 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=66 |
| 9 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=24 |
| 10 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=19 |
| 11 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=18 |
| 12 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=16 |
| 13 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=13 |
| 14 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=12 |
| 15 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=11 |
| 16 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=8 |
| 17 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=5 |
| 18 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=7 |
| 19 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=3 |
| 20 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=2 |
| 21 | `branch` | `soft_cap` | 0.0000 | `branch` | Inf | method=algebraic, source=imported, candidate=1 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | Inf | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | Inf | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | Inf | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | Inf | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | Inf | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | Inf | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | Inf | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | Inf | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | Inf | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | Inf | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | Inf | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | Inf | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | Inf | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | Inf | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | Inf | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | Inf | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | Inf | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | Inf | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#21` | Inf | method=algebraic, source=imported, candidate=21 |
| 21 | `baseline` | `baseline#23` | Inf | method=algebraic, source=imported, candidate=23 |
| 22 | `baseline` | `baseline#24` | Inf | method=algebraic, source=imported, candidate=24 |
| 23 | `baseline` | `baseline#25` | Inf | method=algebraic, source=imported, candidate=25 |
| 24 | `baseline` | `baseline#26` | Inf | method=algebraic, source=imported, candidate=26 |
| 25 | `baseline` | `baseline#27` | Inf | method=algebraic, source=imported, candidate=27 |
| 26 | `baseline` | `baseline#29` | Inf | method=algebraic, source=imported, candidate=29 |
| 27 | `baseline` | `baseline#30` | Inf | method=algebraic, source=imported, candidate=30 |
| 28 | `baseline` | `baseline#31` | Inf | method=algebraic, source=imported, candidate=31 |
| 29 | `baseline` | `baseline#36` | Inf | method=algebraic, source=imported, candidate=36 |
| 30 | `baseline` | `baseline#37` | Inf | method=algebraic, source=imported, candidate=37 |
| 31 | `baseline` | `baseline#38` | Inf | method=algebraic, source=imported, candidate=38 |
| 32 | `baseline` | `baseline#40` | Inf | method=algebraic, source=imported, candidate=40 |
| 33 | `baseline` | `baseline#42` | Inf | method=algebraic, source=imported, candidate=42 |
| 34 | `baseline` | `baseline#43` | Inf | method=algebraic, source=imported, candidate=43 |
| 35 | `baseline` | `baseline#44` | Inf | method=algebraic, source=imported, candidate=44 |
| 36 | `baseline` | `baseline#45` | Inf | method=algebraic, source=imported, candidate=45 |
| 37 | `baseline` | `baseline#48` | Inf | method=algebraic, source=imported, candidate=48 |
| 38 | `baseline` | `baseline#49` | Inf | method=algebraic, source=imported, candidate=49 |
| 39 | `baseline` | `baseline#50` | Inf | method=algebraic, source=imported, candidate=50 |
| 40 | `baseline` | `baseline#55` | Inf | method=algebraic, source=imported, candidate=55 |
| 41 | `baseline` | `baseline#66` | Inf | method=algebraic, source=imported, candidate=66 |
| 42 | `baseline` | `baseline#78` | Inf | method=algebraic, source=imported, candidate=78 |
| 43 | `block+branch` | `block#1, branch#74` | Inf | method=direct_opt, source=assembled |
| 44 | `block` | `block#4` | Inf | method=direct_opt, source=assembled |
| 45 | `block` | `block#3` | Inf | method=direct_opt, source=assembled |
| 46 | `branch` | `branch#102, branch#103, branch#104, branch#105, branch#106, branch#107, branch#108` | Inf | method=algebraic, source=imported, candidate=46 |
| 47 | `block+branch` | `block#2, branch#1, branch#2, branch#3, branch#4, branch#5, branch#6, branch#7, branch#8, branch#9, branch#10, branch#11, branch#12, branch#13, branch#14, branch#15, branch#16, branch#17, branch#18, branch#19, branch#20, branch#21, branch#22, branch#23, branch#24, branch#25, branch#26, branch#27, branch#29, branch#30, branch#31, branch#32, branch#33, branch#34, branch#36, branch#37, branch#38, branch#39, branch#40, branch#41, branch#43, branch#44, branch#79, branch#28, branch#35, branch#45, branch#53, branch#56, branch#57, branch#67, branch#76, branch#77, branch#78, branch#80, branch#81, branch#82, branch#83, branch#84, branch#85, branch#86, branch#87, branch#88, branch#89, branch#90, branch#91, branch#93, branch#94, branch#95, branch#96, branch#97, branch#98, branch#99, branch#100, branch#101` | Inf | method=direct_opt, source=assembled |
| 48 | `branch` | `branch#52, branch#59` | Inf | method=algebraic, source=imported, candidate=34 |
| 49 | `branch` | `branch#109, branch#110` | Inf | method=algebraic, source=imported, candidate=28 |
| 50 | `branch` | `branch#42` | Inf | method=algebraic, source=imported, candidate=40 |
| 51 | `branch` | `branch#46` | Inf | method=algebraic, source=imported, candidate=43 |
| 52 | `branch` | `branch#47` | Inf | method=algebraic, source=imported, candidate=45 |
| 53 | `branch` | `branch#48, branch#50` | Inf | method=algebraic, source=imported, candidate=50 |
| 54 | `branch` | `branch#49` | Inf | method=algebraic, source=imported, candidate=37 |
| 55 | `branch` | `branch#51` | Inf | method=algebraic, source=imported, candidate=31 |
| 56 | `branch` | `branch#54` | Inf | method=algebraic, source=imported, candidate=27 |
| 57 | `branch` | `branch#55, branch#58` | Inf | method=algebraic, source=imported, candidate=17 |
| 58 | `branch` | `branch#60, branch#61` | Inf | method=algebraic, source=imported, candidate=21 |
| 59 | `branch` | `branch#62` | Inf | method=algebraic, source=imported, candidate=14 |
| 60 | `branch` | `branch#63` | Inf | method=algebraic, source=imported, candidate=15 |
| 61 | `branch` | `branch#64` | Inf | method=algebraic, source=imported, candidate=25 |
| 62 | `branch` | `branch#65` | Inf | method=algebraic, source=imported, candidate=23 |
| 63 | `branch` | `branch#66` | Inf | method=algebraic, source=imported, candidate=10 |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Obs Loss | Traj Max | Secondary Max | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|----------|----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 14 | Inf | 0.08% | 9.7118e-01 | 0.0250 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 2 | `mixed` | 6 | Inf | 1.21% | 5.5234e+03 | 0.0419 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=31, polished=true |
| 3 | `mixed` | 5 | Inf | 1.41% | 1.1508e+03 | 0.0028 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 4 | `mixed` | 3 | Inf | 99.22% | 3.3670e+02 | 0.0064 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 5 | `mixed` | 3 | Inf | 0.28% | 2.2204e+03 | 0.0126 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |
| 6 | `mixed` | 2 | Inf | 3.18% | 3.4641e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 7 | `mixed` | 2 | Inf | 1.38% | 8.8479e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 8 | `mixed` | 2 | Inf | 7.17% | 4.4329e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 9 | `mixed` | 2 | Inf | 6.49% | 3.3960e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 10 | `mixed` | 2 | Inf | 25.18% | 1.5540e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 11 | `mixed` | 2 | Inf | 3.98% | 1.2992e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=25, polished=true |
| 12 | `baseline` | 2 | Inf | 3.39% | 6.3784e+05 | 0.0089 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 13 | `baseline` | 2 | Inf | 100.40% | 1.4618e+03 | 0.0037 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |
| 14 | `baseline` | 1 | Inf | 6.23% | 3.8961e+06 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 15 | `baseline` | 1 | Inf | 6.32% | 3.4560e+06 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 16 | `baseline` | 1 | Inf | 4.17% | 1.8522e+06 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 17 | `baseline` | 1 | Inf | 13.58% | 1.5233e+06 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 18 | `baseline` | 1 | Inf | 3.13% | 8.3316e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 19 | `baseline` | 1 | Inf | 23.09% | 8.1006e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 20 | `baseline` | 1 | Inf | 4.83% | 6.1823e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 21 | `baseline` | 1 | Inf | 2.34% | 3.0662e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 22 | `baseline` | 1 | Inf | 1.60% | 1.1112e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 23 | `baseline` | 1 | Inf | 1.14% | 5.2132e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 24 | `baseline` | 1 | Inf | 0.80% | 4.1171e+04 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 25 | `baseline` | 1 | Inf | 94.81% | 5.4615e+02 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=48, polished=true |
| 26 | `block` | 1 | Inf | 99.50% | 8.1356e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 27 | `block` | 1 | Inf | 7.39% | 8.2289e+05 | 0.0000 | 0.0000 | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 28 | `branch` | 1 | Inf | 0.58% | 9.7527e+03 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=28, polished=true |
| 29 | `branch` | 1 | Inf | 1.86% | 2.5315e+03 | 0.0000 | 0.0000 | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | Inf | Inf | 6.23% | 0.145 | `` |
| 2 | `baseline` | Inf | Inf | 6.32% | 0.176 | `` |
| 3 | `baseline` | Inf | Inf | 4.17% | 0.139 | `` |
| 4 | `baseline` | Inf | Inf | 13.58% | 0.134 | `` |
| 5 | `baseline` | Inf | Inf | 3.13% | 0.166 | `` |
| 6 | `baseline` | Inf | Inf | 23.09% | 0.130 | `` |
| 7 | `baseline` | Inf | Inf | 3.53% | 0.181 | `` |
| 8 | `baseline` | Inf | Inf | 3.39% | 0.149 | `` |
| 9 | `baseline` | Inf | Inf | 4.83% | 0.141 | `` |
| 10 | `baseline` | Inf | Inf | 3.18% | 0.156 | `` |
| 11 | `baseline` | Inf | Inf | 2.34% | 0.149 | `` |
| 12 | `baseline` | Inf | Inf | 1.60% | 0.176 | `` |
| 13 | `baseline` | Inf | Inf | 1.24% | 0.141 | `` |
| 14 | `baseline` | Inf | Inf | 1.38% | 0.171 | `` |
| 15 | `baseline` | Inf | Inf | 1.43% | 0.139 | `` |
| 16 | `baseline` | Inf | Inf | 1.14% | 0.156 | `` |
| 17 | `baseline` | Inf | Inf | 7.17% | 0.173 | `` |
| 18 | `baseline` | Inf | Inf | 1.03% | 0.144 | `` |
| 19 | `baseline` | Inf | Inf | 0.80% | 0.181 | `` |
| 20 | `baseline` | Inf | Inf | 6.49% | 0.141 | `` |
| 21 | `baseline` | Inf | Inf | 25.18% | 0.142 | `` |
| 22 | `baseline` | Inf | Inf | 0.65% | 0.179 | `` |
| 23 | `baseline` | Inf | Inf | 3.98% | 0.137 | `` |
| 24 | `baseline` | Inf | Inf | 0.61% | 0.183 | `` |
| 25 | `baseline` | Inf | Inf | 1.00% | 0.138 | `` |
| 26 | `baseline` | Inf | Inf | 0.55% | 0.147 | `` |
| 27 | `baseline` | Inf | Inf | 0.41% | 0.177 | `` |
| 28 | `baseline` | Inf | Inf | 1.21% | 0.142 | `` |
| 29 | `baseline` | Inf | Inf | 100.78% | 0.183 | `` |
| 30 | `baseline` | Inf | Inf | 1.86% | 0.145 | `` |
| 31 | `baseline` | Inf | Inf | 100.40% | 0.144 | `` |
| 32 | `baseline` | Inf | Inf | 0.28% | 0.165 | `` |
| 33 | `baseline` | Inf | Inf | 99.05% | 0.141 | `` |
| 34 | `baseline` | Inf | Inf | 1.66% | 0.175 | `` |
| 35 | `baseline` | Inf | Inf | 99.22% | 0.144 | `` |
| 36 | `baseline` | Inf | Inf | 1.41% | 0.148 | `` |
| 37 | `baseline` | Inf | Inf | 94.81% | 0.172 | `` |
| 38 | `baseline` | Inf | Inf | 0.18% | 0.142 | `` |
| 39 | `baseline` | Inf | Inf | 0.13% | 0.174 | `` |
| 40 | `baseline` | Inf | Inf | 0.15% | 0.143 | `` |
| 41 | `baseline` | Inf | Inf | 0.31% | 0.146 | `` |
| 42 | `baseline` | Inf | Inf | 0.09% | 0.172 | `` |
| 43 | `block+branch` | Inf | Inf | 99.22% | 0.140 | `` |
| 44 | `block` | Inf | Inf | 99.50% | 0.148 | `` |
| 45 | `block` | Inf | Inf | 7.39% | 0.158 | `` |
| 46 | `branch` | Inf | Inf | 0.31% | 0.137 | `` |
| 47 | `block+branch` | Inf | Inf | 0.08% | 0.171 | `` |
| 48 | `branch` | Inf | Inf | 0.52% | 0.133 | `` |
| 49 | `branch` | Inf | Inf | 0.58% | 0.157 | `` |
| 50 | `branch` | Inf | Inf | 0.28% | 0.168 | `` |
| 51 | `branch` | Inf | Inf | 1.66% | 0.145 | `` |
| 52 | `branch` | Inf | Inf | 1.41% | 0.175 | `` |
| 53 | `branch` | Inf | Inf | 0.13% | 0.135 | `` |
| 54 | `branch` | Inf | Inf | 1.86% | 0.140 | `` |
| 55 | `branch` | Inf | Inf | 1.21% | 0.178 | `` |
| 56 | `branch` | Inf | Inf | 1.00% | 0.135 | `` |
| 57 | `branch` | Inf | Inf | 7.17% | 0.151 | `` |
| 58 | `branch` | Inf | Inf | 6.49% | 0.153 | `` |
| 59 | `branch` | Inf | Inf | 1.38% | 0.138 | `` |
| 60 | `branch` | Inf | Inf | 1.43% | 0.172 | `` |
| 61 | `branch` | Inf | Inf | 3.98% | 0.137 | `` |
| 62 | `branch` | Inf | Inf | 25.18% | 0.150 | `` |
| 63 | `branch` | Inf | Inf | 3.18% | 0.156 | `` |

