# Tryhard Finalist Benchmark Case: sirt_treatment_7_1em4

- Model: `sirt_treatment`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T10:29:23.678`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/sirt_treatment_7_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/sirt_treatment_7_1em4`

## Comparison-Table Reference

- Classification: `a_only`
- Comparison CSV ODEPE mean/max relative error: 3.01% / 12.51%
- Comparison CSV ODEPE runtime: 4839.546 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 77 | 23.14% | d (65.35%) | 1.7769e+02 |
| `odepe_polish` | 339 | 2.96% | d (8.44%) | 2.9925e+01 |

## Imported Raw Pool

- Raw imported candidates: 77
- Best raw fit index: 77
- Best raw oracle index: 71
- Best-fit vs best-truth combined-RMSE gap: 15.66%

## Local Tryhard Runtime

- Reference CSV load/scoring: 3.046 s
- Consensus/block context: 242.101 s
- 4x4 baseline evidence report: 31.370 s
- 4x4 block no-polish report: 5.156 s
- Polish context build: 0.008 s
- Baseline-only finalists: 238.157 s
- Additive-only finalists: 271.071 s
- Reasonable frontier finalists: 263.720 s
- Local total (excluding reference load): 1326.832 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 23.14% | 23.14% | 75 | `raw` | 1.7769e+02 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 2.96% | 2.96% | 339 | `benchmark` | 2.9925e+01 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 12.73% | 12.73% | 85 | `block` | 3.8129e+02 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 0.02% | 0.02% | 18 | `baseline` | 2.9822e+01 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 0.02% | 0.02% | 22 | `block+branch+synthesized` | 2.9822e+01 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 0.02% | 0.02% | 18 | `baseline+block+branch+synthesized` | 2.9822e+01 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 1 / 0.02%
- Additive best finalist index / RMSE: 1 / 0.02%
- Frontier best finalist index / RMSE: 1 / 0.02%
- Baseline preserved seeds: 75
- Additive candidate seeds: 85
- Frontier admitted seeds: 83
- Rejected additive seeds: 77
- Successful merged polished seeds: 83
- Returned merged finalists: 18

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 6.4691e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 5.3672e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 3.7314e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 3.6301e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 3.3945e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 3.4877e+06 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 2.5465e+06 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 2.6846e+06 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 2.3804e+06 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 2.5061e+06 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 1.8859e+06 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 1.8132e+06 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 1.5786e+06 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 1.4900e+06 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 1.2235e+06 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 1.2667e+06 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 1.2642e+06 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 1.4439e+06 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 1.0202e+06 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 1.0665e+06 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 6.0255e+05 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 4.9046e+05 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 4.4287e+05 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 4.6287e+05 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 4.3222e+05 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 3.7862e+05 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 2.3954e+05 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 2.6019e+05 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 1.5410e+05 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 1.1484e+05 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 1.2101e+05 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 1.0123e+05 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 7.7070e+04 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 5.0860e+04 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 4.9100e+04 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 5.1296e+04 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 4.7485e+04 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 3.1387e+04 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 2.2835e+04 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 2.6576e+04 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 2.0493e+04 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 1.9909e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 44 | 1.6101e+04 | method=algebraic, source=imported, candidate=44 |
| 44 | `baseline` | 45 | 1.4732e+04 | method=algebraic, source=imported, candidate=45 |
| 45 | `baseline` | 46 | 1.4272e+04 | method=algebraic, source=imported, candidate=46 |
| 46 | `baseline` | 47 | 1.3968e+04 | method=algebraic, source=imported, candidate=47 |
| 47 | `baseline` | 48 | 1.1555e+04 | method=algebraic, source=imported, candidate=48 |
| 48 | `baseline` | 49 | 1.2565e+04 | method=algebraic, source=imported, candidate=49 |
| 49 | `baseline` | 50 | 7.2792e+03 | method=algebraic, source=imported, candidate=50 |
| 50 | `baseline` | 51 | 7.0743e+03 | method=algebraic, source=imported, candidate=51 |
| 51 | `baseline` | 52 | 7.9266e+03 | method=algebraic, source=imported, candidate=52 |
| 52 | `baseline` | 53 | 8.3728e+03 | method=algebraic, source=imported, candidate=53 |
| 53 | `baseline` | 54 | 8.4833e+03 | method=algebraic, source=imported, candidate=54 |
| 54 | `baseline` | 55 | 6.3499e+03 | method=algebraic, source=imported, candidate=55 |
| 55 | `baseline` | 56 | 6.1827e+03 | method=algebraic, source=imported, candidate=56 |
| 56 | `baseline` | 57 | 3.7982e+03 | method=algebraic, source=imported, candidate=57 |
| 57 | `baseline` | 58 | 3.8537e+03 | method=algebraic, source=imported, candidate=58 |
| 58 | `baseline` | 59 | 3.5113e+03 | method=algebraic, source=imported, candidate=59 |
| 59 | `baseline` | 60 | 4.5664e+03 | method=algebraic, source=imported, candidate=60 |
| 60 | `baseline` | 61 | 2.6968e+03 | method=algebraic, source=imported, candidate=61 |
| 61 | `baseline` | 62 | 2.3658e+03 | method=algebraic, source=imported, candidate=62 |
| 62 | `baseline` | 63 | 1.3533e+03 | method=algebraic, source=imported, candidate=63 |
| 63 | `baseline` | 64 | 1.5158e+03 | method=algebraic, source=imported, candidate=64 |
| 64 | `baseline` | 65 | 1.0258e+03 | method=algebraic, source=imported, candidate=65 |
| 65 | `baseline` | 66 | 9.5376e+02 | method=algebraic, source=imported, candidate=66 |
| 66 | `baseline` | 67 | 5.4050e+02 | method=algebraic, source=imported, candidate=67 |
| 67 | `baseline` | 68 | 4.0650e+02 | method=algebraic, source=imported, candidate=68 |
| 68 | `baseline` | 69 | 3.1666e+02 | method=algebraic, source=imported, candidate=69 |
| 69 | `baseline` | 70 | 2.5577e+02 | method=algebraic, source=imported, candidate=70 |
| 70 | `baseline` | 71 | 2.5051e+02 | method=algebraic, source=imported, candidate=71 |
| 71 | `baseline` | 72 | 2.1797e+02 | method=algebraic, source=imported, candidate=72 |
| 72 | `baseline` | 74 | 2.1739e+02 | method=algebraic, source=imported, candidate=74 |
| 73 | `baseline` | 75 | 1.9569e+02 | method=algebraic, source=imported, candidate=75 |
| 74 | `baseline` | 76 | 1.7784e+02 | method=algebraic, source=imported, candidate=76 |
| 75 | `baseline` | 77 | 1.7769e+02 | method=algebraic, source=imported, candidate=77 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block+branch` | 1 | 0.0000 | 3.8129e+02 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.2362 | 5.4808e+05 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.3794 | 2.2971e+07 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.3864 | 2.8065e+07 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.7402 | 1.8940e+10 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.7789 | 4.4632e+10 | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.9892 | 4.7731e+12 | method=direct_opt, source=assembled |
| 15 | `block` | 15 | 1.0000 | 6.0464e+12 | method=direct_opt, source=assembled |
| 1 | `branch` | 1 | 0.6524 | 3.8242e+01 | method=direct_opt, source=synthesized, candidate=75, polished=true |
| 2 | `branch` | 2 | 0.6439 | 3.1301e+01 | method=direct_opt, source=synthesized, candidate=72, polished=true |
| 3 | `branch` | 3 | 0.6381 | 3.1482e+01 | method=direct_opt, source=synthesized, candidate=74, polished=true |
| 4 | `branch` | 4 | 0.6370 | 2.1798e+02 | method=algebraic, source=imported, candidate=73 |
| 5 | `branch` | 5 | 0.6351 | 1.7769e+02 | method=algebraic, source=imported, candidate=77 |
| 6 | `branch` | 6 | 0.6329 | 1.7784e+02 | method=algebraic, source=imported, candidate=76 |
| 7 | `branch` | 7 | 0.5943 | 5.4050e+02 | method=algebraic, source=imported, candidate=67 |
| 8 | `branch` | 8 | 0.5941 | 1.5158e+03 | method=algebraic, source=imported, candidate=64 |
| 9 | `branch` | 9 | 0.5925 | 2.5051e+02 | method=algebraic, source=imported, candidate=71 |
| 10 | `branch` | 10 | 0.5902 | 2.5577e+02 | method=algebraic, source=imported, candidate=70 |
| 11 | `branch` | 11 | 0.5795 | 3.1666e+02 | method=algebraic, source=imported, candidate=69 |
| 13 | `branch` | 13 | 0.5744 | 1.0258e+03 | method=algebraic, source=imported, candidate=65 |
| 14 | `branch` | 14 | 0.5575 | 1.3533e+03 | method=algebraic, source=imported, candidate=63 |
| 15 | `branch` | 15 | 0.5488 | 4.5664e+03 | method=algebraic, source=imported, candidate=60 |
| 16 | `branch` | 16 | 0.5444 | 1.3968e+04 | method=algebraic, source=imported, candidate=47 |
| 17 | `branch` | 17 | 0.5430 | 7.9266e+03 | method=algebraic, source=imported, candidate=52 |
| 18 | `branch` | 18 | 0.5422 | 1.4272e+04 | method=algebraic, source=imported, candidate=46 |
| 19 | `branch` | 19 | 0.5398 | 1.2565e+04 | method=algebraic, source=imported, candidate=49 |
| 20 | `branch` | 20 | 0.5342 | 1.4732e+04 | method=algebraic, source=imported, candidate=45 |
| 21 | `branch` | 21 | 0.5333 | 4.0650e+02 | method=algebraic, source=imported, candidate=68 |
| 22 | `branch` | 22 | 0.5287 | 2.3658e+03 | method=algebraic, source=imported, candidate=62 |
| 23 | `branch` | 23 | 0.5244 | 1.6101e+04 | method=algebraic, source=imported, candidate=44 |
| 24 | `branch` | 24 | 0.5218 | 3.5113e+03 | method=algebraic, source=imported, candidate=59 |
| 25 | `branch` | 25 | 0.5198 | 7.7070e+04 | method=algebraic, source=imported, candidate=33 |
| 26 | `branch` | 26 | 0.5181 | 3.7982e+03 | method=algebraic, source=imported, candidate=57 |
| 28 | `branch` | 28 | 0.5147 | 1.1555e+04 | method=algebraic, source=imported, candidate=48 |
| 29 | `branch` | 29 | 0.5108 | 7.2792e+03 | method=algebraic, source=imported, candidate=50 |
| 30 | `branch` | 30 | 0.5094 | 7.0743e+03 | method=algebraic, source=imported, candidate=51 |
| 31 | `branch` | 31 | 0.5083 | 6.1827e+03 | method=algebraic, source=imported, candidate=56 |
| 32 | `branch` | 32 | 0.5060 | 2.6968e+03 | method=algebraic, source=imported, candidate=61 |
| 33 | `branch` | 33 | 0.5054 | 4.7485e+04 | method=algebraic, source=imported, candidate=37 |
| 34 | `branch` | 34 | 0.5023 | 6.3499e+03 | method=algebraic, source=imported, candidate=55 |
| 35 | `branch` | 35 | 0.4919 | 5.1296e+04 | method=algebraic, source=imported, candidate=36 |
| 36 | `branch` | 36 | 0.4778 | 8.4833e+03 | method=algebraic, source=imported, candidate=54 |
| 37 | `branch` | 37 | 0.4716 | 3.8537e+03 | method=algebraic, source=imported, candidate=58 |
| 38 | `branch` | 38 | 0.4670 | 1.5410e+05 | method=algebraic, source=imported, candidate=29 |
| 39 | `branch` | 39 | 0.4667 | 1.2101e+05 | method=algebraic, source=imported, candidate=31 |
| 40 | `branch` | 40 | 0.4628 | 2.2835e+04 | method=algebraic, source=imported, candidate=39 |
| 41 | `branch` | 41 | 0.4621 | 2.6019e+05 | method=algebraic, source=imported, candidate=28 |
| 42 | `branch` | 42 | 0.4495 | 1.9909e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `branch` | 43 | 0.4488 | 4.9046e+05 | method=algebraic, source=imported, candidate=22 |
| 44 | `branch` | 44 | 0.4479 | 4.3222e+05 | method=algebraic, source=imported, candidate=25 |
| 45 | `branch` | 45 | 0.4439 | 3.1387e+04 | method=algebraic, source=imported, candidate=38 |
| 46 | `branch` | 46 | 0.4436 | 8.3728e+03 | method=algebraic, source=imported, candidate=53 |
| 47 | `branch` | 47 | 0.4435 | 2.0493e+04 | method=algebraic, source=imported, candidate=41 |
| 48 | `branch` | 48 | 0.4357 | 1.2642e+06 | method=algebraic, source=imported, candidate=17 |
| 49 | `branch` | 49 | 0.4347 | 1.0202e+06 | method=algebraic, source=imported, candidate=19 |
| 50 | `branch` | 50 | 0.4341 | 1.0123e+05 | method=algebraic, source=imported, candidate=32 |
| 51 | `branch` | 51 | 0.4338 | 4.6287e+05 | method=algebraic, source=imported, candidate=24 |
| 52 | `branch` | 52 | 0.4328 | 1.1484e+05 | method=algebraic, source=imported, candidate=30 |
| 53 | `branch` | 53 | 0.4314 | 1.2667e+06 | method=algebraic, source=imported, candidate=16 |
| 54 | `branch` | 54 | 0.4313 | 4.9100e+04 | method=algebraic, source=imported, candidate=35 |
| 55 | `branch` | 55 | 0.4274 | 1.2235e+06 | method=algebraic, source=imported, candidate=15 |
| 56 | `branch` | 56 | 0.4270 | 5.0860e+04 | method=algebraic, source=imported, candidate=34 |
| 57 | `branch` | 57 | 0.4247 | 2.6576e+04 | method=algebraic, source=imported, candidate=40 |
| 58 | `branch` | 58 | 0.4220 | 2.3954e+05 | method=algebraic, source=imported, candidate=27 |
| 59 | `branch` | 59 | 0.4188 | 1.8132e+06 | method=algebraic, source=imported, candidate=12 |
| 60 | `branch` | 60 | 0.4118 | 2.5061e+06 | method=algebraic, source=imported, candidate=10 |
| 61 | `branch` | 61 | 0.4084 | 3.3945e+06 | method=algebraic, source=imported, candidate=5 |
| 62 | `branch` | 62 | 0.4075 | 2.6846e+06 | method=algebraic, source=imported, candidate=8 |
| 63 | `branch` | 63 | 0.4046 | 6.0255e+05 | method=algebraic, source=imported, candidate=21 |
| 64 | `branch` | 64 | 0.4035 | 3.6301e+06 | method=algebraic, source=imported, candidate=4 |
| 65 | `branch` | 65 | 0.4012 | 3.7314e+06 | method=algebraic, source=imported, candidate=3 |
| 66 | `branch` | 66 | 0.3974 | 1.0665e+06 | method=algebraic, source=imported, candidate=20 |
| 67 | `branch` | 67 | 0.3936 | 2.3804e+06 | method=algebraic, source=imported, candidate=9 |
| 68 | `branch` | 68 | 0.3915 | 1.4900e+06 | method=algebraic, source=imported, candidate=14 |
| 69 | `branch` | 69 | 0.3872 | 1.5786e+06 | method=algebraic, source=imported, candidate=13 |
| 70 | `branch` | 70 | 0.3804 | 1.8859e+06 | method=algebraic, source=imported, candidate=11 |
| 71 | `branch` | 71 | 0.3783 | 1.4439e+06 | method=algebraic, source=imported, candidate=18 |
| 72 | `branch` | 72 | 0.3778 | 6.4691e+06 | method=algebraic, source=imported, candidate=1 |
| 73 | `branch` | 73 | 0.3742 | 2.5465e+06 | method=algebraic, source=imported, candidate=7 |
| 74 | `branch` | 74 | 0.3526 | 5.3672e+06 | method=algebraic, source=imported, candidate=2 |
| 75 | `branch` | 75 | 0.3491 | 3.7862e+05 | method=algebraic, source=imported, candidate=26 |
| 76 | `branch` | 76 | 0.3413 | 4.4287e+05 | method=algebraic, source=imported, candidate=23 |
| 77 | `branch` | 77 | 0.2980 | 3.4877e+06 | method=algebraic, source=imported, candidate=6 |
| 1 | `synthesized` | 1 | 32.3716 | 3.2372e+01 | method=direct_opt, source=synthesized, polished=true |
| 2 | `synthesized` | 2 | 32.1777 | 3.2178e+01 | method=direct_opt, source=synthesized, polished=true |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `block+branch` | `duplicate` | 3.8129e+02 | method=direct_opt, source=assembled |
| 2 | `branch` | `duplicate` | 2.1798e+02 | method=algebraic, source=imported, candidate=73 |
| 3 | `branch` | `duplicate` | 1.7769e+02 | method=algebraic, source=imported, candidate=77 |
| 4 | `branch` | `duplicate` | 1.7784e+02 | method=algebraic, source=imported, candidate=76 |
| 5 | `branch` | `duplicate` | 5.4050e+02 | method=algebraic, source=imported, candidate=67 |
| 6 | `branch` | `duplicate` | 1.5158e+03 | method=algebraic, source=imported, candidate=64 |
| 7 | `block` | `catastrophic_fit` | 1.8940e+10 | method=direct_opt, source=assembled |
| 8 | `branch` | `duplicate` | 2.5051e+02 | method=algebraic, source=imported, candidate=71 |
| 9 | `branch` | `duplicate` | 2.5577e+02 | method=algebraic, source=imported, candidate=70 |
| 10 | `block` | `catastrophic_fit` | 4.4632e+10 | method=direct_opt, source=assembled |
| 11 | `branch` | `duplicate` | 3.1666e+02 | method=algebraic, source=imported, candidate=69 |
| 12 | `block` | `catastrophic_fit` | 4.7731e+12 | method=direct_opt, source=assembled |
| 13 | `branch` | `duplicate` | 1.0258e+03 | method=algebraic, source=imported, candidate=65 |
| 14 | `branch` | `duplicate` | 1.3533e+03 | method=algebraic, source=imported, candidate=63 |
| 15 | `block` | `catastrophic_fit` | 6.0464e+12 | method=direct_opt, source=assembled |
| 16 | `branch` | `duplicate` | 4.5664e+03 | method=algebraic, source=imported, candidate=60 |
| 17 | `branch` | `duplicate` | 1.3968e+04 | method=algebraic, source=imported, candidate=47 |
| 18 | `branch` | `duplicate` | 7.9266e+03 | method=algebraic, source=imported, candidate=52 |
| 19 | `branch` | `duplicate` | 1.4272e+04 | method=algebraic, source=imported, candidate=46 |
| 20 | `branch` | `duplicate` | 1.2565e+04 | method=algebraic, source=imported, candidate=49 |
| 21 | `branch` | `duplicate` | 1.4732e+04 | method=algebraic, source=imported, candidate=45 |
| 22 | `branch` | `duplicate` | 4.0650e+02 | method=algebraic, source=imported, candidate=68 |
| 23 | `branch` | `duplicate` | 2.3658e+03 | method=algebraic, source=imported, candidate=62 |
| 24 | `branch` | `duplicate` | 1.6101e+04 | method=algebraic, source=imported, candidate=44 |
| 25 | `branch` | `duplicate` | 3.5113e+03 | method=algebraic, source=imported, candidate=59 |
| 26 | `branch` | `duplicate` | 7.7070e+04 | method=algebraic, source=imported, candidate=33 |
| 27 | `branch` | `duplicate` | 3.7982e+03 | method=algebraic, source=imported, candidate=57 |
| 28 | `branch` | `duplicate` | 1.1555e+04 | method=algebraic, source=imported, candidate=48 |
| 29 | `branch` | `duplicate` | 7.2792e+03 | method=algebraic, source=imported, candidate=50 |
| 30 | `branch` | `duplicate` | 7.0743e+03 | method=algebraic, source=imported, candidate=51 |
| 31 | `branch` | `duplicate` | 6.1827e+03 | method=algebraic, source=imported, candidate=56 |
| 32 | `branch` | `duplicate` | 2.6968e+03 | method=algebraic, source=imported, candidate=61 |
| 33 | `branch` | `duplicate` | 4.7485e+04 | method=algebraic, source=imported, candidate=37 |
| 34 | `branch` | `duplicate` | 6.3499e+03 | method=algebraic, source=imported, candidate=55 |
| 35 | `branch` | `duplicate` | 5.1296e+04 | method=algebraic, source=imported, candidate=36 |
| 36 | `branch` | `duplicate` | 8.4833e+03 | method=algebraic, source=imported, candidate=54 |
| 37 | `branch` | `duplicate` | 3.8537e+03 | method=algebraic, source=imported, candidate=58 |
| 38 | `branch` | `duplicate` | 1.5410e+05 | method=algebraic, source=imported, candidate=29 |
| 39 | `branch` | `duplicate` | 1.2101e+05 | method=algebraic, source=imported, candidate=31 |
| 40 | `branch` | `duplicate` | 2.2835e+04 | method=algebraic, source=imported, candidate=39 |
| 41 | `branch` | `duplicate` | 2.6019e+05 | method=algebraic, source=imported, candidate=28 |
| 42 | `branch` | `duplicate` | 1.9909e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `branch` | `duplicate` | 4.9046e+05 | method=algebraic, source=imported, candidate=22 |
| 44 | `branch` | `duplicate` | 4.3222e+05 | method=algebraic, source=imported, candidate=25 |
| 45 | `branch` | `duplicate` | 3.1387e+04 | method=algebraic, source=imported, candidate=38 |
| 46 | `branch` | `duplicate` | 8.3728e+03 | method=algebraic, source=imported, candidate=53 |
| 47 | `branch` | `duplicate` | 2.0493e+04 | method=algebraic, source=imported, candidate=41 |
| 48 | `branch` | `duplicate` | 1.2642e+06 | method=algebraic, source=imported, candidate=17 |
| 49 | `branch` | `duplicate` | 1.0202e+06 | method=algebraic, source=imported, candidate=19 |
| 50 | `branch` | `duplicate` | 1.0123e+05 | method=algebraic, source=imported, candidate=32 |
| 51 | `branch` | `duplicate` | 4.6287e+05 | method=algebraic, source=imported, candidate=24 |
| 52 | `branch` | `duplicate` | 1.1484e+05 | method=algebraic, source=imported, candidate=30 |
| 53 | `branch` | `duplicate` | 1.2667e+06 | method=algebraic, source=imported, candidate=16 |
| 54 | `branch` | `duplicate` | 4.9100e+04 | method=algebraic, source=imported, candidate=35 |
| 55 | `branch` | `duplicate` | 1.2235e+06 | method=algebraic, source=imported, candidate=15 |
| 56 | `branch` | `duplicate` | 5.0860e+04 | method=algebraic, source=imported, candidate=34 |
| 57 | `branch` | `duplicate` | 2.6576e+04 | method=algebraic, source=imported, candidate=40 |
| 58 | `branch` | `duplicate` | 2.3954e+05 | method=algebraic, source=imported, candidate=27 |
| 59 | `branch` | `duplicate` | 1.8132e+06 | method=algebraic, source=imported, candidate=12 |
| 60 | `branch` | `duplicate` | 2.5061e+06 | method=algebraic, source=imported, candidate=10 |
| 61 | `branch` | `duplicate` | 3.3945e+06 | method=algebraic, source=imported, candidate=5 |
| 62 | `branch` | `duplicate` | 2.6846e+06 | method=algebraic, source=imported, candidate=8 |
| 63 | `branch` | `duplicate` | 6.0255e+05 | method=algebraic, source=imported, candidate=21 |
| 64 | `branch` | `duplicate` | 3.6301e+06 | method=algebraic, source=imported, candidate=4 |
| 65 | `branch` | `duplicate` | 3.7314e+06 | method=algebraic, source=imported, candidate=3 |
| 66 | `branch` | `duplicate` | 1.0665e+06 | method=algebraic, source=imported, candidate=20 |
| 67 | `branch` | `duplicate` | 2.3804e+06 | method=algebraic, source=imported, candidate=9 |
| 68 | `branch` | `duplicate` | 1.4900e+06 | method=algebraic, source=imported, candidate=14 |
| 69 | `branch` | `duplicate` | 1.5786e+06 | method=algebraic, source=imported, candidate=13 |
| 70 | `branch` | `duplicate` | 1.8859e+06 | method=algebraic, source=imported, candidate=11 |
| 71 | `branch` | `duplicate` | 1.4439e+06 | method=algebraic, source=imported, candidate=18 |
| 72 | `branch` | `duplicate` | 6.4691e+06 | method=algebraic, source=imported, candidate=1 |
| 73 | `branch` | `duplicate` | 2.5465e+06 | method=algebraic, source=imported, candidate=7 |
| 74 | `branch` | `duplicate` | 5.3672e+06 | method=algebraic, source=imported, candidate=2 |
| 75 | `branch` | `duplicate` | 3.7862e+05 | method=algebraic, source=imported, candidate=26 |
| 76 | `branch` | `duplicate` | 4.4287e+05 | method=algebraic, source=imported, candidate=23 |
| 77 | `branch` | `duplicate` | 3.4877e+06 | method=algebraic, source=imported, candidate=6 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 6.4691e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 5.3672e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 3.7314e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 3.6301e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 3.3945e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 3.4877e+06 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 2.5465e+06 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 2.6846e+06 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 2.3804e+06 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 2.5061e+06 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 1.8859e+06 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 1.8132e+06 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 1.5786e+06 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 1.4900e+06 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 1.2235e+06 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 1.2667e+06 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 1.2642e+06 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 1.4439e+06 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 1.0202e+06 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 1.0665e+06 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 6.0255e+05 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 4.9046e+05 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 4.4287e+05 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 4.6287e+05 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 4.3222e+05 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 3.7862e+05 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 2.3954e+05 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 2.6019e+05 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 1.5410e+05 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 1.1484e+05 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 1.2101e+05 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 1.0123e+05 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 7.7070e+04 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 5.0860e+04 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 4.9100e+04 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 5.1296e+04 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 4.7485e+04 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 3.1387e+04 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 2.2835e+04 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 2.6576e+04 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 2.0493e+04 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 1.9909e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#44` | 1.6101e+04 | method=algebraic, source=imported, candidate=44 |
| 44 | `baseline` | `baseline#45` | 1.4732e+04 | method=algebraic, source=imported, candidate=45 |
| 45 | `baseline` | `baseline#46` | 1.4272e+04 | method=algebraic, source=imported, candidate=46 |
| 46 | `baseline` | `baseline#47` | 1.3968e+04 | method=algebraic, source=imported, candidate=47 |
| 47 | `baseline` | `baseline#48` | 1.1555e+04 | method=algebraic, source=imported, candidate=48 |
| 48 | `baseline` | `baseline#49` | 1.2565e+04 | method=algebraic, source=imported, candidate=49 |
| 49 | `baseline` | `baseline#50` | 7.2792e+03 | method=algebraic, source=imported, candidate=50 |
| 50 | `baseline` | `baseline#51` | 7.0743e+03 | method=algebraic, source=imported, candidate=51 |
| 51 | `baseline` | `baseline#52` | 7.9266e+03 | method=algebraic, source=imported, candidate=52 |
| 52 | `baseline` | `baseline#53` | 8.3728e+03 | method=algebraic, source=imported, candidate=53 |
| 53 | `baseline` | `baseline#54` | 8.4833e+03 | method=algebraic, source=imported, candidate=54 |
| 54 | `baseline` | `baseline#55` | 6.3499e+03 | method=algebraic, source=imported, candidate=55 |
| 55 | `baseline` | `baseline#56` | 6.1827e+03 | method=algebraic, source=imported, candidate=56 |
| 56 | `baseline` | `baseline#57` | 3.7982e+03 | method=algebraic, source=imported, candidate=57 |
| 57 | `baseline` | `baseline#58` | 3.8537e+03 | method=algebraic, source=imported, candidate=58 |
| 58 | `baseline` | `baseline#59` | 3.5113e+03 | method=algebraic, source=imported, candidate=59 |
| 59 | `baseline` | `baseline#60` | 4.5664e+03 | method=algebraic, source=imported, candidate=60 |
| 60 | `baseline` | `baseline#61` | 2.6968e+03 | method=algebraic, source=imported, candidate=61 |
| 61 | `baseline` | `baseline#62` | 2.3658e+03 | method=algebraic, source=imported, candidate=62 |
| 62 | `baseline` | `baseline#63` | 1.3533e+03 | method=algebraic, source=imported, candidate=63 |
| 63 | `baseline` | `baseline#64` | 1.5158e+03 | method=algebraic, source=imported, candidate=64 |
| 64 | `baseline` | `baseline#65` | 1.0258e+03 | method=algebraic, source=imported, candidate=65 |
| 65 | `baseline` | `baseline#66` | 9.5376e+02 | method=algebraic, source=imported, candidate=66 |
| 66 | `baseline` | `baseline#67` | 5.4050e+02 | method=algebraic, source=imported, candidate=67 |
| 67 | `baseline` | `baseline#68` | 4.0650e+02 | method=algebraic, source=imported, candidate=68 |
| 68 | `baseline` | `baseline#69` | 3.1666e+02 | method=algebraic, source=imported, candidate=69 |
| 69 | `baseline` | `baseline#70` | 2.5577e+02 | method=algebraic, source=imported, candidate=70 |
| 70 | `baseline` | `baseline#71` | 2.5051e+02 | method=algebraic, source=imported, candidate=71 |
| 71 | `baseline` | `baseline#72` | 2.1797e+02 | method=algebraic, source=imported, candidate=72 |
| 72 | `baseline` | `baseline#74` | 2.1739e+02 | method=algebraic, source=imported, candidate=74 |
| 73 | `baseline` | `baseline#75` | 1.9569e+02 | method=algebraic, source=imported, candidate=75 |
| 74 | `baseline` | `baseline#76` | 1.7784e+02 | method=algebraic, source=imported, candidate=76 |
| 75 | `baseline` | `baseline#77` | 1.7769e+02 | method=algebraic, source=imported, candidate=77 |
| 76 | `branch` | `branch#1` | 3.8242e+01 | method=direct_opt, source=synthesized, candidate=75, polished=true |
| 77 | `synthesized` | `synthesized#1` | 3.2372e+01 | method=direct_opt, source=synthesized, polished=true |
| 78 | `branch` | `branch#2` | 3.1301e+01 | method=direct_opt, source=synthesized, candidate=72, polished=true |
| 79 | `synthesized` | `synthesized#2` | 3.2178e+01 | method=direct_opt, source=synthesized, polished=true |
| 80 | `block` | `block#3, block#4` | 5.4808e+05 | method=direct_opt, source=assembled |
| 81 | `branch` | `branch#3` | 3.1482e+01 | method=direct_opt, source=synthesized, candidate=74, polished=true |
| 82 | `block` | `block#5, block#6` | 2.2971e+07 | method=direct_opt, source=assembled |
| 83 | `block` | `block#7, block#8` | 2.8065e+07 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 64 | 2.9822e+01 | 0.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=18, polished=true |
| 2 | `baseline` | 2 | 2.9823e+01 | 0.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=44, polished=true |
| 3 | `baseline` | 2 | 2.9841e+01 | 1.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 4 | `baseline` | 1 | 2.9823e+01 | 0.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 5 | `baseline` | 1 | 2.9826e+01 | 0.58% | 0 | 0.5000 | method=algebraic, source=imported, candidate=33, polished=true |
| 6 | `baseline` | 1 | 2.9921e+01 | 2.93% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 7 | `baseline` | 1 | 2.9983e+01 | 3.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 8 | `baseline` | 1 | 3.1179e+01 | 13.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 9 | `baseline` | 1 | 3.2294e+01 | 18.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 10 | `baseline` | 1 | 8.8868e+03 | 273.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 11 | `baseline` | 1 | 5.1940e+05 | 447.05% | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 12 | `baseline` | 1 | 5.2051e+05 | 450.22% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 13 | `baseline` | 1 | 6.0557e+05 | 447.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 14 | `baseline` | 1 | 8.7913e+05 | 529.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 15 | `baseline` | 1 | 1.0205e+06 | 553.29% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 16 | `baseline` | 1 | 1.0748e+06 | 585.55% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 17 | `baseline` | 1 | 1.1242e+06 | 671.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 18 | `baseline` | 1 | 1.1554e+06 | 693.21% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 6.4691e+06 | 8.8868e+03 | 273.53% | 2.995 | `` |
| 2 | `baseline` | 5.3672e+06 | 2.9822e+01 | 0.02% | 3.509 | `` |
| 3 | `baseline` | 3.7314e+06 | 6.0557e+05 | 447.03% | 3.029 | `` |
| 4 | `baseline` | 3.6301e+06 | 5.2051e+05 | 450.22% | 3.005 | `` |
| 5 | `baseline` | 3.3945e+06 | 5.1940e+05 | 447.05% | 2.900 | `` |
| 6 | `baseline` | 3.4877e+06 | 2.9841e+01 | 1.38% | 3.211 | `` |
| 7 | `baseline` | 2.5465e+06 | 2.9822e+01 | 0.02% | 3.399 | `` |
| 8 | `baseline` | 2.6846e+06 | 8.7913e+05 | 529.15% | 3.311 | `` |
| 9 | `baseline` | 2.3804e+06 | 3.2294e+01 | 18.89% | 3.197 | `` |
| 10 | `baseline` | 2.5061e+06 | 1.0205e+06 | 553.29% | 3.375 | `` |
| 11 | `baseline` | 1.8859e+06 | 2.9822e+01 | 0.02% | 2.135 | `` |
| 12 | `baseline` | 1.8132e+06 | 1.0748e+06 | 585.55% | 3.517 | `` |
| 13 | `baseline` | 1.5786e+06 | 2.9822e+01 | 0.02% | 3.513 | `` |
| 14 | `baseline` | 1.4900e+06 | 2.9822e+01 | 0.02% | 1.903 | `` |
| 15 | `baseline` | 1.2235e+06 | 2.9983e+01 | 3.64% | 3.251 | `` |
| 16 | `baseline` | 1.2667e+06 | 1.1242e+06 | 671.73% | 3.719 | `` |
| 17 | `baseline` | 1.2642e+06 | 1.1554e+06 | 693.21% | 3.799 | `` |
| 18 | `baseline` | 1.4439e+06 | 2.9822e+01 | 0.02% | 3.510 | `` |
| 19 | `baseline` | 1.0202e+06 | 2.9823e+01 | 0.19% | 3.245 | `` |
| 20 | `baseline` | 1.0665e+06 | 2.9822e+01 | 0.02% | 3.249 | `` |
| 21 | `baseline` | 6.0255e+05 | 2.9822e+01 | 0.02% | 3.338 | `` |
| 22 | `baseline` | 4.9046e+05 | 2.9822e+01 | 0.02% | 3.396 | `` |
| 23 | `baseline` | 4.4287e+05 | 2.9822e+01 | 0.02% | 3.319 | `` |
| 24 | `baseline` | 4.6287e+05 | 3.1179e+01 | 13.97% | 3.134 | `` |
| 25 | `baseline` | 4.3222e+05 | 2.9822e+01 | 0.02% | 3.695 | `` |
| 26 | `baseline` | 3.7862e+05 | 2.9822e+01 | 0.02% | 3.107 | `` |
| 27 | `baseline` | 2.3954e+05 | 2.9822e+01 | 0.02% | 1.461 | `` |
| 28 | `baseline` | 2.6019e+05 | 2.9822e+01 | 0.02% | 3.419 | `` |
| 29 | `baseline` | 1.5410e+05 | 2.9822e+01 | 0.02% | 3.341 | `` |
| 30 | `baseline` | 1.1484e+05 | 2.9822e+01 | 0.02% | 3.426 | `` |
| 31 | `baseline` | 1.2101e+05 | 2.9822e+01 | 0.02% | 3.418 | `` |
| 32 | `baseline` | 1.0123e+05 | 2.9822e+01 | 0.02% | 3.340 | `` |
| 33 | `baseline` | 7.7070e+04 | 2.9826e+01 | 0.58% | 3.233 | `` |
| 34 | `baseline` | 5.0860e+04 | 2.9822e+01 | 0.02% | 3.332 | `` |
| 35 | `baseline` | 4.9100e+04 | 2.9822e+01 | 0.02% | 3.256 | `` |
| 36 | `baseline` | 5.1296e+04 | 2.9822e+01 | 0.02% | 3.541 | `` |
| 37 | `baseline` | 4.7485e+04 | 2.9921e+01 | 2.93% | 3.121 | `` |
| 38 | `baseline` | 3.1387e+04 | 2.9822e+01 | 0.02% | 3.505 | `` |
| 39 | `baseline` | 2.2835e+04 | 2.9822e+01 | 0.02% | 2.939 | `` |
| 40 | `baseline` | 2.6576e+04 | 2.9822e+01 | 0.02% | 3.663 | `` |
| 41 | `baseline` | 2.0493e+04 | 2.9822e+01 | 0.02% | 1.498 | `` |
| 42 | `baseline` | 1.9909e+04 | 2.9822e+01 | 0.02% | 3.547 | `` |
| 43 | `baseline` | 1.6101e+04 | 2.9823e+01 | 0.31% | 3.222 | `` |
| 44 | `baseline` | 1.4732e+04 | 2.9841e+01 | 1.39% | 3.062 | `` |
| 45 | `baseline` | 1.4272e+04 | 2.9824e+01 | 0.39% | 3.186 | `` |
| 46 | `baseline` | 1.3968e+04 | 2.9822e+01 | 0.02% | 3.336 | `` |
| 47 | `baseline` | 1.1555e+04 | 2.9822e+01 | 0.02% | 2.391 | `` |
| 48 | `baseline` | 1.2565e+04 | 2.9822e+01 | 0.02% | 3.279 | `` |
| 49 | `baseline` | 7.2792e+03 | 2.9822e+01 | 0.02% | 3.408 | `` |
| 50 | `baseline` | 7.0743e+03 | 2.9822e+01 | 0.02% | 3.692 | `` |
| 51 | `baseline` | 7.9266e+03 | 2.9822e+01 | 0.02% | 3.490 | `` |
| 52 | `baseline` | 8.3728e+03 | 2.9822e+01 | 0.02% | 3.562 | `` |
| 53 | `baseline` | 8.4833e+03 | 2.9822e+01 | 0.02% | 1.471 | `` |
| 54 | `baseline` | 6.3499e+03 | 2.9822e+01 | 0.02% | 3.603 | `` |
| 55 | `baseline` | 6.1827e+03 | 2.9822e+01 | 0.02% | 3.601 | `` |
| 56 | `baseline` | 3.7982e+03 | 2.9822e+01 | 0.02% | 3.537 | `` |
| 57 | `baseline` | 3.8537e+03 | 2.9822e+01 | 0.02% | 3.569 | `` |
| 58 | `baseline` | 3.5113e+03 | 2.9822e+01 | 0.02% | 1.815 | `` |
| 59 | `baseline` | 4.5664e+03 | 2.9822e+01 | 0.02% | 2.562 | `` |
| 60 | `baseline` | 2.6968e+03 | 2.9822e+01 | 0.02% | 3.491 | `` |
| 61 | `baseline` | 2.3658e+03 | 2.9822e+01 | 0.02% | 3.545 | `` |
| 62 | `baseline` | 1.3533e+03 | 2.9822e+01 | 0.02% | 3.499 | `` |
| 63 | `baseline` | 1.5158e+03 | 2.9822e+01 | 0.02% | 4.055 | `` |
| 64 | `baseline` | 1.0258e+03 | 2.9822e+01 | 0.02% | 3.773 | `` |
| 65 | `baseline` | 9.5376e+02 | 2.9822e+01 | 0.02% | 3.530 | `` |
| 66 | `baseline` | 5.4050e+02 | 2.9822e+01 | 0.02% | 3.387 | `` |
| 67 | `baseline` | 4.0650e+02 | 2.9822e+01 | 0.02% | 3.581 | `` |
| 68 | `baseline` | 3.1666e+02 | 2.9822e+01 | 0.02% | 3.555 | `` |
| 69 | `baseline` | 2.5577e+02 | 2.9822e+01 | 0.02% | 3.554 | `` |
| 70 | `baseline` | 2.5051e+02 | 2.9822e+01 | 0.02% | 0.991 | `` |
| 71 | `baseline` | 2.1797e+02 | 2.9822e+01 | 0.02% | 2.175 | `` |
| 72 | `baseline` | 2.1739e+02 | 2.9822e+01 | 0.02% | 3.371 | `` |
| 73 | `baseline` | 1.9569e+02 | 2.9822e+01 | 0.02% | 3.368 | `` |
| 74 | `baseline` | 1.7784e+02 | 2.9822e+01 | 0.02% | 3.398 | `` |
| 75 | `baseline` | 1.7769e+02 | 2.9822e+01 | 0.02% | 3.435 | `` |
| 76 | `branch` | 3.8242e+01 | 2.9822e+01 | 0.02% | 3.275 | `` |
| 77 | `synthesized` | 3.2372e+01 | 2.9822e+01 | 0.02% | 1.935 | `` |
| 78 | `branch` | 3.1301e+01 | 2.9822e+01 | 0.02% | 3.534 | `` |
| 79 | `synthesized` | 3.2178e+01 | 2.9822e+01 | 0.02% | 3.522 | `` |
| 80 | `block` | 5.4808e+05 | 2.9822e+01 | 0.02% | 1.951 | `` |
| 81 | `branch` | 3.1482e+01 | 2.9822e+01 | 0.02% | 3.523 | `` |
| 82 | `block` | 2.2971e+07 | 2.9822e+01 | 0.02% | 3.267 | `` |
| 83 | `block` | 2.8065e+07 | 2.9822e+01 | 0.02% | 3.415 | `` |

