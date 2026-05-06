# Tryhard Finalist Benchmark Case: fitzhugh_nagumo_2_1em4

- Model: `fitzhugh_nagumo`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T10:16:01.696`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/fitzhugh_nagumo_2_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/fitzhugh_nagumo_2_1em4`

## Comparison-Table Reference

- Classification: `a_only`
- Comparison CSV ODEPE mean/max relative error: 4.98% / 11.54%
- Comparison CSV ODEPE runtime: 1414.871 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 186 | 7.83% | b (17.43%) | 4.4029e-05 |
| `odepe_polish` | 385 | 3.62% | b (8.00%) | 3.6504e-05 |

## Imported Raw Pool

- Raw imported candidates: 186
- Best raw fit index: 186
- Best raw oracle index: 184
- Best-fit vs best-truth combined-RMSE gap: 0.75%

## Local Tryhard Runtime

- Reference CSV load/scoring: 2.671 s
- Consensus/block context: 9.832 s
- 4x4 baseline evidence report: 20.074 s
- 4x4 block no-polish report: 0.607 s
- Polish context build: 0.006 s
- Baseline-only finalists: 162.777 s
- Additive-only finalists: 183.716 s
- Reasonable frontier finalists: 182.641 s
- Local total (excluding reference load): 774.040 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 7.83% | 7.83% | 184 | `raw` | 4.4029e-05 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 3.62% | 3.62% | 385 | `benchmark` | 3.6504e-05 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 11.82% | 11.82% | 191 | `block` | 2.6599e-02 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 1.48% | 1.48% | 60 | `baseline` | 3.6106e-05 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 1.48% | 1.48% | 65 | `block+branch+synthesized` | 3.6106e-05 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 1.48% | 1.48% | 65 | `baseline+block+branch+synthesized` | 3.6106e-05 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 1 / 1.48%
- Additive best finalist index / RMSE: 1 / 1.48%
- Frontier best finalist index / RMSE: 1 / 1.48%
- Baseline preserved seeds: 184
- Additive candidate seeds: 191
- Frontier admitted seeds: 193
- Rejected additive seeds: 182
- Successful merged polished seeds: 193
- Returned merged finalists: 65

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 2.9684e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 3.3669e+04 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 2.0880e+04 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 9.3335e+03 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 6.6588e+03 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 2.6119e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 8.4790e+02 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 8.0645e+02 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 6.7904e+02 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 5.8025e+02 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 5.7344e+02 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 4.4660e+02 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 4.2019e+02 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 4.1323e+02 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 3.9976e+02 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 3.9865e+02 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 3.7285e+02 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 2.4789e+02 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 2.4359e+02 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 2.3370e+02 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 2.2112e+02 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 2.1452e+02 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 1.9249e+02 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 1.7425e+02 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 1.7358e+02 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 1.7914e+02 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 1.4046e+02 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 1.3589e+02 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 1.3233e+02 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 1.3071e+02 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 1.2856e+02 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 1.2002e+02 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 1.1917e+02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 1.1915e+02 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 1.1757e+02 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 1.1695e+02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 1.1653e+02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 1.1518e+02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 1.1496e+02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 1.1467e+02 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 1.1453e+02 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 1.1451e+02 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 1.1292e+02 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 1.1290e+02 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 1.1122e+02 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 1.1071e+02 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 1.0990e+02 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 1.0974e+02 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 1.0768e+02 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 1.0709e+02 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 1.0257e+02 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | 1.0245e+02 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | 1.0235e+02 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 9.2736e+01 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 6.8812e+01 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 5.7878e+01 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 5.5315e+01 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 5.5058e+01 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 5.4450e+01 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 5.2905e+01 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 5.2262e+01 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 5.2234e+01 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 5.1512e+01 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 5.1303e+01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 5.0974e+01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 4.8025e+01 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 4.6709e+01 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 4.6493e+01 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 4.6266e+01 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 4.5549e+01 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 4.3455e+01 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 73 | 4.1519e+01 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | 74 | 4.0844e+01 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | 75 | 3.9841e+01 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | 76 | 3.7439e+01 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | 77 | 3.7250e+01 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | 78 | 3.1838e+01 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | 79 | 2.9507e+01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | 80 | 2.5924e+01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | 81 | 2.5160e+01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | 82 | 2.0440e+01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | 83 | 1.2000e+01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | 84 | 9.6944e+00 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | 85 | 9.6004e+00 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | 86 | 7.8918e+00 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | 87 | 7.1029e+00 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | 88 | 7.0814e+00 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | 89 | 6.4402e+00 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | 90 | 5.7279e+00 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | 91 | 5.7003e+00 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | 92 | 5.2288e+00 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | 93 | 4.9001e+00 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | 94 | 3.7507e+00 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | 95 | 3.3344e+00 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | 96 | 3.2515e+00 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | 97 | 3.2244e+00 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | 98 | 3.2132e+00 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | 99 | 3.1753e+00 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | 100 | 3.0414e+00 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | 101 | 2.8704e+00 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | 102 | 2.7460e+00 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | 103 | 2.6694e+00 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | 104 | 2.5786e+00 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | 105 | 2.3909e+00 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | 106 | 2.2824e+00 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | 107 | 2.1782e+00 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | 108 | 2.1258e+00 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | 109 | 2.0448e+00 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | 110 | 2.0401e+00 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | 111 | 2.0400e+00 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | 112 | 2.0187e+00 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | 113 | 1.9891e+00 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | 114 | 1.9805e+00 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | 115 | 1.9431e+00 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | 116 | 1.8041e+00 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | 117 | 1.7873e+00 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | 118 | 1.7471e+00 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | 119 | 1.7432e+00 | method=algebraic, source=imported, candidate=119 |
| 120 | `baseline` | 120 | 1.7119e+00 | method=algebraic, source=imported, candidate=120 |
| 121 | `baseline` | 121 | 1.7102e+00 | method=algebraic, source=imported, candidate=121 |
| 122 | `baseline` | 122 | 1.7023e+00 | method=algebraic, source=imported, candidate=122 |
| 123 | `baseline` | 123 | 1.6895e+00 | method=algebraic, source=imported, candidate=123 |
| 124 | `baseline` | 125 | 1.6788e+00 | method=algebraic, source=imported, candidate=125 |
| 125 | `baseline` | 126 | 1.5279e+00 | method=algebraic, source=imported, candidate=126 |
| 126 | `baseline` | 127 | 1.5259e+00 | method=algebraic, source=imported, candidate=127 |
| 127 | `baseline` | 128 | 1.5068e+00 | method=algebraic, source=imported, candidate=128 |
| 128 | `baseline` | 129 | 1.4938e+00 | method=algebraic, source=imported, candidate=129 |
| 129 | `baseline` | 130 | 1.3913e+00 | method=algebraic, source=imported, candidate=130 |
| 130 | `baseline` | 131 | 1.1848e+00 | method=algebraic, source=imported, candidate=131 |
| 131 | `baseline` | 132 | 1.0353e+00 | method=algebraic, source=imported, candidate=132 |
| 132 | `baseline` | 133 | 9.7687e-01 | method=algebraic, source=imported, candidate=133 |
| 133 | `baseline` | 134 | 8.0597e-01 | method=algebraic, source=imported, candidate=134 |
| 134 | `baseline` | 135 | 6.4938e-01 | method=algebraic, source=imported, candidate=135 |
| 135 | `baseline` | 137 | 6.4282e-01 | method=algebraic, source=imported, candidate=137 |
| 136 | `baseline` | 138 | 5.3849e-01 | method=algebraic, source=imported, candidate=138 |
| 137 | `baseline` | 139 | 5.3414e-01 | method=algebraic, source=imported, candidate=139 |
| 138 | `baseline` | 140 | 3.4454e-01 | method=algebraic, source=imported, candidate=140 |
| 139 | `baseline` | 141 | 3.3245e-01 | method=algebraic, source=imported, candidate=141 |
| 140 | `baseline` | 142 | 3.2513e-01 | method=algebraic, source=imported, candidate=142 |
| 141 | `baseline` | 143 | 1.4294e-01 | method=algebraic, source=imported, candidate=143 |
| 142 | `baseline` | 144 | 1.4237e-01 | method=algebraic, source=imported, candidate=144 |
| 143 | `baseline` | 145 | 1.1565e-01 | method=algebraic, source=imported, candidate=145 |
| 144 | `baseline` | 146 | 8.0713e-02 | method=algebraic, source=imported, candidate=146 |
| 145 | `baseline` | 147 | 4.5066e-02 | method=algebraic, source=imported, candidate=147 |
| 146 | `baseline` | 148 | 4.1284e-02 | method=algebraic, source=imported, candidate=148 |
| 147 | `baseline` | 149 | 3.7017e-02 | method=algebraic, source=imported, candidate=149 |
| 148 | `baseline` | 150 | 3.6898e-02 | method=algebraic, source=imported, candidate=150 |
| 149 | `baseline` | 151 | 3.3091e-02 | method=algebraic, source=imported, candidate=151 |
| 150 | `baseline` | 152 | 2.2854e-02 | method=algebraic, source=imported, candidate=152 |
| 151 | `baseline` | 153 | 2.1149e-02 | method=algebraic, source=imported, candidate=153 |
| 152 | `baseline` | 154 | 1.7789e-02 | method=algebraic, source=imported, candidate=154 |
| 153 | `baseline` | 155 | 1.3595e-02 | method=algebraic, source=imported, candidate=155 |
| 154 | `baseline` | 156 | 1.1448e-02 | method=algebraic, source=imported, candidate=156 |
| 155 | `baseline` | 157 | 9.6995e-03 | method=algebraic, source=imported, candidate=157 |
| 156 | `baseline` | 158 | 9.6079e-03 | method=algebraic, source=imported, candidate=158 |
| 157 | `baseline` | 159 | 8.5007e-03 | method=algebraic, source=imported, candidate=159 |
| 158 | `baseline` | 160 | 8.1282e-03 | method=algebraic, source=imported, candidate=160 |
| 159 | `baseline` | 161 | 7.4222e-03 | method=algebraic, source=imported, candidate=161 |
| 160 | `baseline` | 162 | 4.2340e-03 | method=algebraic, source=imported, candidate=162 |
| 161 | `baseline` | 163 | 3.5186e-03 | method=algebraic, source=imported, candidate=163 |
| 162 | `baseline` | 164 | 3.0835e-03 | method=algebraic, source=imported, candidate=164 |
| 163 | `baseline` | 165 | 3.0628e-03 | method=algebraic, source=imported, candidate=165 |
| 164 | `baseline` | 166 | 2.9490e-03 | method=algebraic, source=imported, candidate=166 |
| 165 | `baseline` | 167 | 2.5847e-03 | method=algebraic, source=imported, candidate=167 |
| 166 | `baseline` | 168 | 2.5147e-03 | method=algebraic, source=imported, candidate=168 |
| 167 | `baseline` | 169 | 2.2050e-03 | method=algebraic, source=imported, candidate=169 |
| 168 | `baseline` | 170 | 1.4272e-03 | method=algebraic, source=imported, candidate=170 |
| 169 | `baseline` | 171 | 1.3868e-03 | method=algebraic, source=imported, candidate=171 |
| 170 | `baseline` | 172 | 1.3401e-03 | method=algebraic, source=imported, candidate=172 |
| 171 | `baseline` | 173 | 1.2847e-03 | method=algebraic, source=imported, candidate=173 |
| 172 | `baseline` | 174 | 1.2382e-03 | method=algebraic, source=imported, candidate=174 |
| 173 | `baseline` | 175 | 9.6320e-04 | method=algebraic, source=imported, candidate=175 |
| 174 | `baseline` | 176 | 7.0823e-04 | method=algebraic, source=imported, candidate=176 |
| 175 | `baseline` | 177 | 6.5683e-04 | method=algebraic, source=imported, candidate=177 |
| 176 | `baseline` | 178 | 5.6186e-04 | method=algebraic, source=imported, candidate=178 |
| 177 | `baseline` | 179 | 4.7811e-04 | method=algebraic, source=imported, candidate=179 |
| 178 | `baseline` | 180 | 2.8381e-04 | method=algebraic, source=imported, candidate=180 |
| 179 | `baseline` | 181 | 2.8114e-04 | method=algebraic, source=imported, candidate=181 |
| 180 | `baseline` | 182 | 1.3686e-04 | method=algebraic, source=imported, candidate=182 |
| 181 | `baseline` | 183 | 1.0275e-04 | method=algebraic, source=imported, candidate=183 |
| 182 | `baseline` | 184 | 9.6532e-05 | method=algebraic, source=imported, candidate=184 |
| 183 | `baseline` | 185 | 8.8036e-05 | method=algebraic, source=imported, candidate=185 |
| 184 | `baseline` | 186 | 4.4029e-05 | method=algebraic, source=imported, candidate=186 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 2.6599e-02 | method=direct_opt, source=assembled |
| 2 | `block` | 2 | 0.2917 | 8.0904e+01 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.2952 | 1.0546e+02 | method=direct_opt, source=assembled |
| 4 | `block` | 4 | 0.3123 | 1.1139e+02 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.7602 | 1.9535e+04 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.7644 | 4.1110e+03 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.8718 | 2.7560e+05 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.9990 | 2.7089e+05 | method=direct_opt, source=assembled |
| 1 | `branch` | 1 | 0.6454 | 2.9490e-03 | method=direct_opt, source=synthesized, candidate=166, polished=true |
| 1 | `branch+synthesized` | 4 | 0.0000 | 3.6106e-05 | method=direct_opt, source=synthesized, polished=true |
| 4 | `branch` | 4 | 0.6419 | 1.3686e-04 | method=algebraic, source=imported, candidate=182 |
| 5 | `branch` | 5 | 0.6401 | 3.5186e-03 | method=algebraic, source=imported, candidate=163 |
| 6 | `branch` | 6 | 0.6391 | 3.4454e-01 | method=algebraic, source=imported, candidate=140 |
| 7 | `branch` | 7 | 0.6379 | 2.1149e-02 | method=algebraic, source=imported, candidate=153 |
| 8 | `branch` | 8 | 0.6376 | 9.7687e-01 | method=algebraic, source=imported, candidate=133 |
| 9 | `branch` | 9 | 0.6369 | 4.4029e-05 | method=algebraic, source=imported, candidate=186 |
| 10 | `branch` | 10 | 0.6348 | 3.3091e-02 | method=algebraic, source=imported, candidate=151 |
| 11 | `branch` | 11 | 0.6346 | 1.0275e-04 | method=algebraic, source=imported, candidate=183 |
| 12 | `branch` | 12 | 0.6336 | 3.6898e-02 | method=algebraic, source=imported, candidate=150 |
| 13 | `branch` | 13 | 0.6335 | 2.2050e-03 | method=algebraic, source=imported, candidate=169 |
| 14 | `branch` | 14 | 0.6331 | 4.7811e-04 | method=algebraic, source=imported, candidate=179 |
| 15 | `branch` | 15 | 0.6330 | 2.8381e-04 | method=algebraic, source=imported, candidate=180 |
| 16 | `branch` | 16 | 0.6324 | 3.2513e-01 | method=algebraic, source=imported, candidate=142 |
| 17 | `branch` | 17 | 0.6294 | 2.5847e-03 | method=algebraic, source=imported, candidate=167 |
| 18 | `branch` | 18 | 0.6286 | 2.5147e-03 | method=algebraic, source=imported, candidate=168 |
| 19 | `branch` | 19 | 0.6283 | 3.0835e-03 | method=algebraic, source=imported, candidate=164 |
| 20 | `branch` | 20 | 0.6279 | 1.7789e-02 | method=algebraic, source=imported, candidate=154 |
| 21 | `branch` | 21 | 0.6271 | 5.6186e-04 | method=algebraic, source=imported, candidate=178 |
| 22 | `branch` | 22 | 0.6260 | 1.2847e-03 | method=algebraic, source=imported, candidate=173 |
| 23 | `branch` | 23 | 0.6260 | 3.0628e-03 | method=algebraic, source=imported, candidate=165 |
| 24 | `branch` | 24 | 0.6234 | 9.6320e-04 | method=algebraic, source=imported, candidate=175 |
| 25 | `branch` | 25 | 0.6201 | 1.4272e-03 | method=algebraic, source=imported, candidate=170 |
| 26 | `branch` | 26 | 0.6197 | 8.1282e-03 | method=algebraic, source=imported, candidate=160 |
| 27 | `branch` | 27 | 0.6162 | 2.8114e-04 | method=algebraic, source=imported, candidate=181 |
| 28 | `branch` | 28 | 0.6142 | 1.3595e-02 | method=algebraic, source=imported, candidate=155 |
| 29 | `branch` | 29 | 0.6134 | 8.0713e-02 | method=algebraic, source=imported, candidate=146 |
| 30 | `branch` | 30 | 0.6084 | 9.6995e-03 | method=algebraic, source=imported, candidate=157 |
| 31 | `branch` | 31 | 0.6077 | 1.2382e-03 | method=algebraic, source=imported, candidate=174 |
| 32 | `branch` | 32 | 0.6061 | 1.3868e-03 | method=algebraic, source=imported, candidate=171 |
| 33 | `branch` | 33 | 0.6061 | 1.4237e-01 | method=algebraic, source=imported, candidate=144 |
| 34 | `branch` | 34 | 0.6059 | 4.2340e-03 | method=algebraic, source=imported, candidate=162 |
| 35 | `branch` | 35 | 0.6025 | 5.3414e-01 | method=algebraic, source=imported, candidate=139 |
| 36 | `branch` | 36 | 0.6018 | 7.0823e-04 | method=algebraic, source=imported, candidate=176 |
| 37 | `branch` | 37 | 0.6006 | 9.6079e-03 | method=algebraic, source=imported, candidate=158 |
| 38 | `branch` | 38 | 0.6001 | 2.8704e+00 | method=algebraic, source=imported, candidate=101 |
| 39 | `branch` | 39 | 0.6000 | 8.5007e-03 | method=algebraic, source=imported, candidate=159 |
| 40 | `branch` | 40 | 0.5970 | 1.4294e-01 | method=algebraic, source=imported, candidate=143 |
| 41 | `branch` | 41 | 0.5963 | 6.4282e-01 | method=algebraic, source=imported, candidate=137 |
| 43 | `branch` | 43 | 0.5920 | 3.7017e-02 | method=algebraic, source=imported, candidate=149 |
| 44 | `branch` | 44 | 0.5917 | 8.0597e-01 | method=algebraic, source=imported, candidate=134 |
| 45 | `branch` | 45 | 0.5907 | 3.3245e-01 | method=algebraic, source=imported, candidate=141 |
| 46 | `branch` | 46 | 0.5899 | 2.2854e-02 | method=algebraic, source=imported, candidate=152 |
| 47 | `branch` | 47 | 0.5887 | 4.1284e-02 | method=algebraic, source=imported, candidate=148 |
| 48 | `branch` | 48 | 0.5882 | 6.4938e-01 | method=algebraic, source=imported, candidate=135 |
| 49 | `branch` | 49 | 0.5880 | 6.5683e-04 | method=algebraic, source=imported, candidate=177 |
| 50 | `branch` | 50 | 0.5877 | 1.1448e-02 | method=algebraic, source=imported, candidate=156 |
| 51 | `branch` | 51 | 0.5861 | 1.0353e+00 | method=algebraic, source=imported, candidate=132 |
| 52 | `branch` | 52 | 0.5837 | 1.3401e-03 | method=algebraic, source=imported, candidate=172 |
| 53 | `branch` | 53 | 0.5778 | 1.1565e-01 | method=algebraic, source=imported, candidate=145 |
| 54 | `branch` | 54 | 0.5732 | 7.4222e-03 | method=algebraic, source=imported, candidate=161 |
| 55 | `branch` | 55 | 0.5724 | 4.5066e-02 | method=algebraic, source=imported, candidate=147 |
| 56 | `branch` | 56 | 0.5688 | 2.3909e+00 | method=algebraic, source=imported, candidate=105 |
| 57 | `branch` | 57 | 0.5404 | 1.4938e+00 | method=algebraic, source=imported, candidate=129 |
| 58 | `branch` | 58 | 0.5382 | 7.0814e+00 | method=algebraic, source=imported, candidate=88 |
| 59 | `branch` | 59 | 0.5376 | 2.1782e+00 | method=algebraic, source=imported, candidate=107 |
| 60 | `branch` | 60 | 0.5370 | 1.5259e+00 | method=algebraic, source=imported, candidate=127 |
| 61 | `branch` | 61 | 0.5334 | 1.9805e+00 | method=algebraic, source=imported, candidate=114 |
| 62 | `branch` | 62 | 0.5323 | 2.7460e+00 | method=algebraic, source=imported, candidate=102 |
| 63 | `branch` | 63 | 0.5281 | 2.6694e+00 | method=algebraic, source=imported, candidate=103 |
| 64 | `branch` | 64 | 0.5275 | 1.9891e+00 | method=algebraic, source=imported, candidate=113 |
| 65 | `branch` | 65 | 0.5252 | 3.0414e+00 | method=algebraic, source=imported, candidate=100 |
| 66 | `branch` | 66 | 0.5224 | 1.5279e+00 | method=algebraic, source=imported, candidate=126 |
| 67 | `branch` | 67 | 0.5206 | 1.5068e+00 | method=algebraic, source=imported, candidate=128 |
| 68 | `branch` | 68 | 0.5177 | 1.8041e+00 | method=algebraic, source=imported, candidate=116 |
| 69 | `branch` | 69 | 0.5107 | 2.0187e+00 | method=algebraic, source=imported, candidate=112 |
| 70 | `branch` | 70 | 0.5097 | 3.1753e+00 | method=algebraic, source=imported, candidate=99 |
| 71 | `branch` | 71 | 0.5084 | 1.0974e+02 | method=algebraic, source=imported, candidate=49 |
| 72 | `branch` | 72 | 0.5072 | 3.2132e+00 | method=algebraic, source=imported, candidate=98 |
| 73 | `branch` | 73 | 0.5018 | 1.1071e+02 | method=algebraic, source=imported, candidate=47 |
| 74 | `branch` | 74 | 0.5006 | 1.1695e+02 | method=algebraic, source=imported, candidate=37 |
| 75 | `branch` | 75 | 0.4997 | 1.1467e+02 | method=algebraic, source=imported, candidate=41 |
| 76 | `branch` | 76 | 0.4994 | 3.2515e+00 | method=algebraic, source=imported, candidate=96 |
| 77 | `branch` | 77 | 0.4981 | 4.9001e+00 | method=algebraic, source=imported, candidate=93 |
| 78 | `branch` | 78 | 0.4979 | 2.5924e+01 | method=algebraic, source=imported, candidate=80 |
| 79 | `branch` | 79 | 0.4979 | 6.4402e+00 | method=algebraic, source=imported, candidate=89 |
| 80 | `branch` | 80 | 0.4924 | 5.7003e+00 | method=algebraic, source=imported, candidate=91 |
| 81 | `branch` | 81 | 0.4920 | 5.2288e+00 | method=algebraic, source=imported, candidate=92 |
| 82 | `branch` | 82 | 0.4918 | 1.1915e+02 | method=algebraic, source=imported, candidate=35 |
| 83 | `branch` | 83 | 0.4916 | 1.1653e+02 | method=algebraic, source=imported, candidate=38 |
| 84 | `branch` | 84 | 0.4913 | 2.2824e+00 | method=algebraic, source=imported, candidate=106 |
| 85 | `branch` | 85 | 0.4905 | 1.1848e+00 | method=algebraic, source=imported, candidate=131 |
| 86 | `branch` | 86 | 0.4899 | 1.0245e+02 | method=algebraic, source=imported, candidate=53 |
| 87 | `branch` | 87 | 0.4890 | 1.0768e+02 | method=algebraic, source=imported, candidate=50 |
| 88 | `branch` | 88 | 0.4878 | 5.7279e+00 | method=algebraic, source=imported, candidate=90 |
| 89 | `branch` | 89 | 0.4874 | 1.0257e+02 | method=algebraic, source=imported, candidate=52 |
| 90 | `branch` | 90 | 0.4861 | 6.8812e+01 | method=algebraic, source=imported, candidate=56 |
| 91 | `branch` | 91 | 0.4858 | 7.1029e+00 | method=algebraic, source=imported, candidate=87 |
| 92 | `branch` | 92 | 0.4855 | 1.1292e+02 | method=algebraic, source=imported, candidate=44 |
| 93 | `branch` | 93 | 0.4851 | 2.0400e+00 | method=algebraic, source=imported, candidate=111 |
| 94 | `branch` | 94 | 0.4847 | 1.1290e+02 | method=algebraic, source=imported, candidate=45 |
| 95 | `branch` | 95 | 0.4844 | 2.5160e+01 | method=algebraic, source=imported, candidate=81 |
| 96 | `branch` | 96 | 0.4842 | 2.0401e+00 | method=algebraic, source=imported, candidate=110 |
| 97 | `branch` | 97 | 0.4835 | 1.1757e+02 | method=algebraic, source=imported, candidate=36 |
| 98 | `branch` | 98 | 0.4794 | 1.1518e+02 | method=algebraic, source=imported, candidate=39 |
| 99 | `branch` | 99 | 0.4786 | 1.1496e+02 | method=algebraic, source=imported, candidate=40 |
| 100 | `branch` | 100 | 0.4780 | 1.1453e+02 | method=algebraic, source=imported, candidate=42 |
| 101 | `branch` | 101 | 0.4764 | 1.1451e+02 | method=algebraic, source=imported, candidate=43 |
| 102 | `branch` | 102 | 0.4718 | 3.7250e+01 | method=algebraic, source=imported, candidate=77 |
| 103 | `branch` | 103 | 0.4717 | 1.7432e+00 | method=algebraic, source=imported, candidate=119 |
| 104 | `branch` | 104 | 0.4707 | 1.9431e+00 | method=algebraic, source=imported, candidate=115 |
| 105 | `branch` | 105 | 0.4659 | 1.7471e+00 | method=algebraic, source=imported, candidate=118 |
| 106 | `branch` | 106 | 0.4657 | 3.1838e+01 | method=algebraic, source=imported, candidate=78 |
| 107 | `branch` | 107 | 0.4641 | 1.3589e+02 | method=algebraic, source=imported, candidate=29 |
| 108 | `branch` | 108 | 0.4589 | 4.2019e+02 | method=algebraic, source=imported, candidate=14 |
| 109 | `branch` | 109 | 0.4582 | 2.1258e+00 | method=algebraic, source=imported, candidate=108 |
| 110 | `branch` | 110 | 0.4579 | 1.1917e+02 | method=algebraic, source=imported, candidate=34 |
| 111 | `branch` | 111 | 0.4562 | 1.2002e+02 | method=algebraic, source=imported, candidate=33 |
| 112 | `branch` | 112 | 0.4541 | 3.7285e+02 | method=algebraic, source=imported, candidate=18 |
| 113 | `branch` | 113 | 0.4533 | 5.7878e+01 | method=algebraic, source=imported, candidate=57 |
| 114 | `branch` | 114 | 0.4514 | 6.7904e+02 | method=algebraic, source=imported, candidate=10 |
| 115 | `branch` | 115 | 0.4499 | 9.6004e+00 | method=algebraic, source=imported, candidate=85 |
| 116 | `branch` | 116 | 0.4494 | 2.5786e+00 | method=algebraic, source=imported, candidate=104 |
| 117 | `branch` | 117 | 0.4493 | 1.3071e+02 | method=algebraic, source=imported, candidate=31 |
| 118 | `branch` | 118 | 0.4474 | 9.6944e+00 | method=algebraic, source=imported, candidate=84 |
| 119 | `branch` | 119 | 0.4467 | 1.2856e+02 | method=algebraic, source=imported, candidate=32 |
| 120 | `branch` | 120 | 0.4454 | 4.0844e+01 | method=algebraic, source=imported, candidate=74 |
| 121 | `branch` | 121 | 0.4447 | 1.2000e+01 | method=algebraic, source=imported, candidate=83 |
| 122 | `branch` | 122 | 0.4429 | 4.1519e+01 | method=algebraic, source=imported, candidate=73 |
| 123 | `branch` | 123 | 0.4417 | 3.9841e+01 | method=algebraic, source=imported, candidate=75 |
| 124 | `branch` | 124 | 0.4383 | 5.3849e-01 | method=algebraic, source=imported, candidate=138 |
| 125 | `branch` | 125 | 0.4311 | 2.0448e+00 | method=algebraic, source=imported, candidate=109 |
| 126 | `branch` | 126 | 0.4296 | 1.0235e+02 | method=algebraic, source=imported, candidate=54 |
| 127 | `branch` | 127 | 0.4272 | 3.9976e+02 | method=algebraic, source=imported, candidate=16 |
| 128 | `branch` | 128 | 0.4242 | 1.1122e+02 | method=algebraic, source=imported, candidate=46 |
| 129 | `branch` | 129 | 0.4201 | 1.7358e+02 | method=algebraic, source=imported, candidate=26 |
| 130 | `branch` | 130 | 0.4196 | 1.6895e+00 | method=algebraic, source=imported, candidate=123 |
| 131 | `branch` | 131 | 0.4193 | 4.1323e+02 | method=algebraic, source=imported, candidate=15 |
| 132 | `branch` | 132 | 0.4182 | 2.9507e+01 | method=algebraic, source=imported, candidate=79 |
| 133 | `branch` | 134 | 0.4139 | 1.6788e+00 | method=algebraic, source=imported, candidate=125 |
| 135 | `branch` | 135 | 0.4120 | 1.7023e+00 | method=algebraic, source=imported, candidate=122 |
| 136 | `branch` | 136 | 0.4071 | 1.7102e+00 | method=algebraic, source=imported, candidate=121 |
| 137 | `branch` | 137 | 0.4046 | 1.7119e+00 | method=algebraic, source=imported, candidate=120 |
| 138 | `branch` | 138 | 0.3979 | 1.7873e+00 | method=algebraic, source=imported, candidate=117 |
| 139 | `branch` | 139 | 0.3967 | 1.3913e+00 | method=algebraic, source=imported, candidate=130 |
| 140 | `branch` | 140 | 0.3951 | 1.4046e+02 | method=algebraic, source=imported, candidate=28 |
| 141 | `branch` | 141 | 0.3884 | 7.8918e+00 | method=algebraic, source=imported, candidate=86 |
| 142 | `branch` | 142 | 0.3862 | 3.7439e+01 | method=algebraic, source=imported, candidate=76 |
| 143 | `branch` | 143 | 0.3854 | 3.2244e+00 | method=algebraic, source=imported, candidate=97 |
| 144 | `branch` | 144 | 0.3813 | 3.3344e+00 | method=algebraic, source=imported, candidate=95 |
| 145 | `branch` | 145 | 0.3803 | 3.7507e+00 | method=algebraic, source=imported, candidate=94 |
| 146 | `branch` | 146 | 0.3663 | 4.3455e+01 | method=algebraic, source=imported, candidate=72 |
| 147 | `branch` | 147 | 0.3655 | 1.0709e+02 | method=algebraic, source=imported, candidate=51 |
| 148 | `branch` | 148 | 0.3650 | 1.3233e+02 | method=algebraic, source=imported, candidate=30 |
| 149 | `branch` | 149 | 0.3645 | 2.6119e+03 | method=algebraic, source=imported, candidate=7 |
| 150 | `branch` | 150 | 0.3590 | 4.5549e+01 | method=algebraic, source=imported, candidate=71 |
| 151 | `branch` | 151 | 0.3570 | 4.6709e+01 | method=algebraic, source=imported, candidate=68 |
| 152 | `branch` | 152 | 0.3557 | 4.6266e+01 | method=algebraic, source=imported, candidate=70 |
| 153 | `branch` | 153 | 0.3547 | 4.6493e+01 | method=algebraic, source=imported, candidate=69 |
| 154 | `branch` | 154 | 0.3535 | 5.0974e+01 | method=algebraic, source=imported, candidate=66 |
| 155 | `branch` | 155 | 0.3511 | 5.2234e+01 | method=algebraic, source=imported, candidate=63 |
| 156 | `branch` | 156 | 0.3506 | 5.1303e+01 | method=algebraic, source=imported, candidate=65 |
| 157 | `branch` | 157 | 0.3505 | 5.1512e+01 | method=algebraic, source=imported, candidate=64 |
| 158 | `branch` | 158 | 0.3502 | 5.2262e+01 | method=algebraic, source=imported, candidate=62 |
| 159 | `branch` | 159 | 0.3498 | 4.8025e+01 | method=algebraic, source=imported, candidate=67 |
| 160 | `branch` | 160 | 0.3493 | 5.2905e+01 | method=algebraic, source=imported, candidate=61 |
| 161 | `branch` | 161 | 0.3458 | 5.5315e+01 | method=algebraic, source=imported, candidate=58 |
| 162 | `branch` | 162 | 0.3454 | 5.4450e+01 | method=algebraic, source=imported, candidate=60 |
| 163 | `branch` | 163 | 0.3448 | 1.7425e+02 | method=algebraic, source=imported, candidate=25 |
| 164 | `branch` | 164 | 0.3440 | 5.5058e+01 | method=algebraic, source=imported, candidate=59 |
| 165 | `branch` | 165 | 0.3428 | 2.3370e+02 | method=algebraic, source=imported, candidate=21 |
| 166 | `branch` | 166 | 0.3428 | 2.0440e+01 | method=algebraic, source=imported, candidate=82 |
| 167 | `branch` | 167 | 0.3412 | 2.2112e+02 | method=algebraic, source=imported, candidate=22 |
| 168 | `branch` | 168 | 0.3337 | 1.0990e+02 | method=algebraic, source=imported, candidate=48 |
| 169 | `branch` | 169 | 0.3301 | 9.3335e+03 | method=algebraic, source=imported, candidate=5 |
| 170 | `branch` | 170 | 0.3236 | 9.2736e+01 | method=algebraic, source=imported, candidate=55 |
| 171 | `branch` | 171 | 0.3052 | 2.0880e+04 | method=algebraic, source=imported, candidate=4 |
| 172 | `branch` | 172 | 0.2999 | 8.0645e+02 | method=algebraic, source=imported, candidate=9 |
| 173 | `branch` | 173 | 0.2987 | 3.3669e+04 | method=algebraic, source=imported, candidate=3 |
| 174 | `branch` | 174 | 0.2923 | 2.9684e+05 | method=algebraic, source=imported, candidate=2 |
| 175 | `branch` | 175 | 0.2882 | 2.1452e+02 | method=algebraic, source=imported, candidate=23 |
| 176 | `branch` | 176 | 0.2876 | Inf | method=algebraic, source=imported, candidate=1 |
| 177 | `branch` | 177 | 0.2873 | 1.7914e+02 | method=algebraic, source=imported, candidate=27 |
| 178 | `branch` | 178 | 0.2864 | 2.4359e+02 | method=algebraic, source=imported, candidate=20 |
| 179 | `branch` | 179 | 0.2842 | 4.4660e+02 | method=algebraic, source=imported, candidate=13 |
| 180 | `branch` | 180 | 0.2839 | 2.4789e+02 | method=algebraic, source=imported, candidate=19 |
| 181 | `branch` | 181 | 0.2837 | 1.9249e+02 | method=algebraic, source=imported, candidate=24 |
| 182 | `branch` | 182 | 0.2739 | 3.9865e+02 | method=algebraic, source=imported, candidate=17 |
| 183 | `branch` | 183 | 0.2721 | 5.8025e+02 | method=algebraic, source=imported, candidate=11 |
| 184 | `branch` | 184 | 0.2706 | 5.7344e+02 | method=algebraic, source=imported, candidate=12 |
| 185 | `branch` | 185 | 0.2686 | 8.4790e+02 | method=algebraic, source=imported, candidate=8 |
| 186 | `branch` | 186 | 0.2580 | 6.6588e+03 | method=algebraic, source=imported, candidate=6 |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `branch` | `duplicate` | 2.9490e-03 | method=direct_opt, source=synthesized, candidate=166, polished=true |
| 2 | `branch` | `duplicate` | 1.3686e-04 | method=algebraic, source=imported, candidate=182 |
| 3 | `branch` | `duplicate` | 3.5186e-03 | method=algebraic, source=imported, candidate=163 |
| 4 | `branch` | `duplicate` | 3.4454e-01 | method=algebraic, source=imported, candidate=140 |
| 5 | `branch` | `duplicate` | 2.1149e-02 | method=algebraic, source=imported, candidate=153 |
| 6 | `branch` | `duplicate` | 9.7687e-01 | method=algebraic, source=imported, candidate=133 |
| 7 | `branch` | `duplicate` | 4.4029e-05 | method=algebraic, source=imported, candidate=186 |
| 8 | `branch` | `duplicate` | 3.3091e-02 | method=algebraic, source=imported, candidate=151 |
| 9 | `branch` | `duplicate` | 1.0275e-04 | method=algebraic, source=imported, candidate=183 |
| 10 | `branch` | `duplicate` | 3.6898e-02 | method=algebraic, source=imported, candidate=150 |
| 11 | `branch` | `duplicate` | 2.2050e-03 | method=algebraic, source=imported, candidate=169 |
| 12 | `branch` | `duplicate` | 4.7811e-04 | method=algebraic, source=imported, candidate=179 |
| 13 | `branch` | `duplicate` | 2.8381e-04 | method=algebraic, source=imported, candidate=180 |
| 14 | `branch` | `duplicate` | 3.2513e-01 | method=algebraic, source=imported, candidate=142 |
| 15 | `branch` | `duplicate` | 2.5847e-03 | method=algebraic, source=imported, candidate=167 |
| 16 | `branch` | `duplicate` | 2.5147e-03 | method=algebraic, source=imported, candidate=168 |
| 17 | `branch` | `duplicate` | 3.0835e-03 | method=algebraic, source=imported, candidate=164 |
| 18 | `branch` | `duplicate` | 1.7789e-02 | method=algebraic, source=imported, candidate=154 |
| 19 | `branch` | `duplicate` | 5.6186e-04 | method=algebraic, source=imported, candidate=178 |
| 20 | `branch` | `duplicate` | 1.2847e-03 | method=algebraic, source=imported, candidate=173 |
| 21 | `branch` | `duplicate` | 3.0628e-03 | method=algebraic, source=imported, candidate=165 |
| 22 | `branch` | `duplicate` | 9.6320e-04 | method=algebraic, source=imported, candidate=175 |
| 23 | `branch` | `duplicate` | 1.4272e-03 | method=algebraic, source=imported, candidate=170 |
| 24 | `branch` | `duplicate` | 8.1282e-03 | method=algebraic, source=imported, candidate=160 |
| 25 | `branch` | `duplicate` | 2.8114e-04 | method=algebraic, source=imported, candidate=181 |
| 26 | `branch` | `duplicate` | 1.3595e-02 | method=algebraic, source=imported, candidate=155 |
| 27 | `branch` | `duplicate` | 8.0713e-02 | method=algebraic, source=imported, candidate=146 |
| 28 | `branch` | `duplicate` | 9.6995e-03 | method=algebraic, source=imported, candidate=157 |
| 29 | `branch` | `duplicate` | 1.2382e-03 | method=algebraic, source=imported, candidate=174 |
| 30 | `branch` | `duplicate` | 1.3868e-03 | method=algebraic, source=imported, candidate=171 |
| 31 | `branch` | `duplicate` | 1.4237e-01 | method=algebraic, source=imported, candidate=144 |
| 32 | `branch` | `duplicate` | 4.2340e-03 | method=algebraic, source=imported, candidate=162 |
| 33 | `branch` | `duplicate` | 5.3414e-01 | method=algebraic, source=imported, candidate=139 |
| 34 | `branch` | `duplicate` | 7.0823e-04 | method=algebraic, source=imported, candidate=176 |
| 35 | `branch` | `duplicate` | 9.6079e-03 | method=algebraic, source=imported, candidate=158 |
| 36 | `branch` | `duplicate` | 2.8704e+00 | method=algebraic, source=imported, candidate=101 |
| 37 | `branch` | `duplicate` | 8.5007e-03 | method=algebraic, source=imported, candidate=159 |
| 38 | `branch` | `duplicate` | 1.4294e-01 | method=algebraic, source=imported, candidate=143 |
| 39 | `branch` | `duplicate` | 6.4282e-01 | method=algebraic, source=imported, candidate=137 |
| 40 | `branch` | `duplicate` | 3.7017e-02 | method=algebraic, source=imported, candidate=149 |
| 41 | `branch` | `duplicate` | 8.0597e-01 | method=algebraic, source=imported, candidate=134 |
| 42 | `branch` | `duplicate` | 3.3245e-01 | method=algebraic, source=imported, candidate=141 |
| 43 | `branch` | `duplicate` | 2.2854e-02 | method=algebraic, source=imported, candidate=152 |
| 44 | `branch` | `duplicate` | 4.1284e-02 | method=algebraic, source=imported, candidate=148 |
| 45 | `branch` | `duplicate` | 6.4938e-01 | method=algebraic, source=imported, candidate=135 |
| 46 | `branch` | `duplicate` | 6.5683e-04 | method=algebraic, source=imported, candidate=177 |
| 47 | `branch` | `duplicate` | 1.1448e-02 | method=algebraic, source=imported, candidate=156 |
| 48 | `branch` | `duplicate` | 1.0353e+00 | method=algebraic, source=imported, candidate=132 |
| 49 | `branch` | `duplicate` | 1.3401e-03 | method=algebraic, source=imported, candidate=172 |
| 50 | `branch` | `duplicate` | 1.1565e-01 | method=algebraic, source=imported, candidate=145 |
| 51 | `branch` | `duplicate` | 7.4222e-03 | method=algebraic, source=imported, candidate=161 |
| 52 | `branch` | `duplicate` | 4.5066e-02 | method=algebraic, source=imported, candidate=147 |
| 53 | `branch` | `duplicate` | 2.3909e+00 | method=algebraic, source=imported, candidate=105 |
| 54 | `branch` | `duplicate` | 1.4938e+00 | method=algebraic, source=imported, candidate=129 |
| 55 | `branch` | `duplicate` | 7.0814e+00 | method=algebraic, source=imported, candidate=88 |
| 56 | `branch` | `duplicate` | 2.1782e+00 | method=algebraic, source=imported, candidate=107 |
| 57 | `branch` | `duplicate` | 1.5259e+00 | method=algebraic, source=imported, candidate=127 |
| 58 | `branch` | `duplicate` | 1.9805e+00 | method=algebraic, source=imported, candidate=114 |
| 59 | `branch` | `duplicate` | 2.7460e+00 | method=algebraic, source=imported, candidate=102 |
| 60 | `branch` | `duplicate` | 2.6694e+00 | method=algebraic, source=imported, candidate=103 |
| 61 | `branch` | `duplicate` | 1.9891e+00 | method=algebraic, source=imported, candidate=113 |
| 62 | `branch` | `duplicate` | 3.0414e+00 | method=algebraic, source=imported, candidate=100 |
| 63 | `branch` | `duplicate` | 1.5279e+00 | method=algebraic, source=imported, candidate=126 |
| 64 | `branch` | `duplicate` | 1.5068e+00 | method=algebraic, source=imported, candidate=128 |
| 65 | `branch` | `duplicate` | 1.8041e+00 | method=algebraic, source=imported, candidate=116 |
| 66 | `branch` | `duplicate` | 2.0187e+00 | method=algebraic, source=imported, candidate=112 |
| 67 | `branch` | `duplicate` | 3.1753e+00 | method=algebraic, source=imported, candidate=99 |
| 68 | `branch` | `duplicate` | 1.0974e+02 | method=algebraic, source=imported, candidate=49 |
| 69 | `branch` | `duplicate` | 3.2132e+00 | method=algebraic, source=imported, candidate=98 |
| 70 | `branch` | `duplicate` | 1.1071e+02 | method=algebraic, source=imported, candidate=47 |
| 71 | `branch` | `duplicate` | 1.1695e+02 | method=algebraic, source=imported, candidate=37 |
| 72 | `branch` | `duplicate` | 1.1467e+02 | method=algebraic, source=imported, candidate=41 |
| 73 | `branch` | `duplicate` | 3.2515e+00 | method=algebraic, source=imported, candidate=96 |
| 74 | `branch` | `duplicate` | 4.9001e+00 | method=algebraic, source=imported, candidate=93 |
| 75 | `branch` | `duplicate` | 2.5924e+01 | method=algebraic, source=imported, candidate=80 |
| 76 | `branch` | `duplicate` | 6.4402e+00 | method=algebraic, source=imported, candidate=89 |
| 77 | `branch` | `duplicate` | 5.7003e+00 | method=algebraic, source=imported, candidate=91 |
| 78 | `branch` | `duplicate` | 5.2288e+00 | method=algebraic, source=imported, candidate=92 |
| 79 | `branch` | `duplicate` | 1.1915e+02 | method=algebraic, source=imported, candidate=35 |
| 80 | `branch` | `duplicate` | 1.1653e+02 | method=algebraic, source=imported, candidate=38 |
| 81 | `branch` | `duplicate` | 2.2824e+00 | method=algebraic, source=imported, candidate=106 |
| 82 | `branch` | `duplicate` | 1.1848e+00 | method=algebraic, source=imported, candidate=131 |
| 83 | `branch` | `duplicate` | 1.0245e+02 | method=algebraic, source=imported, candidate=53 |
| 84 | `branch` | `duplicate` | 1.0768e+02 | method=algebraic, source=imported, candidate=50 |
| 85 | `branch` | `duplicate` | 5.7279e+00 | method=algebraic, source=imported, candidate=90 |
| 86 | `branch` | `duplicate` | 1.0257e+02 | method=algebraic, source=imported, candidate=52 |
| 87 | `branch` | `duplicate` | 6.8812e+01 | method=algebraic, source=imported, candidate=56 |
| 88 | `branch` | `duplicate` | 7.1029e+00 | method=algebraic, source=imported, candidate=87 |
| 89 | `branch` | `duplicate` | 1.1292e+02 | method=algebraic, source=imported, candidate=44 |
| 90 | `branch` | `duplicate` | 2.0400e+00 | method=algebraic, source=imported, candidate=111 |
| 91 | `branch` | `duplicate` | 1.1290e+02 | method=algebraic, source=imported, candidate=45 |
| 92 | `branch` | `duplicate` | 2.5160e+01 | method=algebraic, source=imported, candidate=81 |
| 93 | `branch` | `duplicate` | 2.0401e+00 | method=algebraic, source=imported, candidate=110 |
| 94 | `branch` | `duplicate` | 1.1757e+02 | method=algebraic, source=imported, candidate=36 |
| 95 | `branch` | `duplicate` | 1.1518e+02 | method=algebraic, source=imported, candidate=39 |
| 96 | `branch` | `duplicate` | 1.1496e+02 | method=algebraic, source=imported, candidate=40 |
| 97 | `branch` | `duplicate` | 1.1453e+02 | method=algebraic, source=imported, candidate=42 |
| 98 | `branch` | `duplicate` | 1.1451e+02 | method=algebraic, source=imported, candidate=43 |
| 99 | `branch` | `duplicate` | 3.7250e+01 | method=algebraic, source=imported, candidate=77 |
| 100 | `branch` | `duplicate` | 1.7432e+00 | method=algebraic, source=imported, candidate=119 |
| 101 | `branch` | `duplicate` | 1.9431e+00 | method=algebraic, source=imported, candidate=115 |
| 102 | `branch` | `duplicate` | 1.7471e+00 | method=algebraic, source=imported, candidate=118 |
| 103 | `branch` | `duplicate` | 3.1838e+01 | method=algebraic, source=imported, candidate=78 |
| 104 | `branch` | `duplicate` | 1.3589e+02 | method=algebraic, source=imported, candidate=29 |
| 105 | `branch` | `duplicate` | 4.2019e+02 | method=algebraic, source=imported, candidate=14 |
| 106 | `branch` | `duplicate` | 2.1258e+00 | method=algebraic, source=imported, candidate=108 |
| 107 | `branch` | `duplicate` | 1.1917e+02 | method=algebraic, source=imported, candidate=34 |
| 108 | `branch` | `duplicate` | 1.2002e+02 | method=algebraic, source=imported, candidate=33 |
| 109 | `branch` | `duplicate` | 3.7285e+02 | method=algebraic, source=imported, candidate=18 |
| 110 | `branch` | `duplicate` | 5.7878e+01 | method=algebraic, source=imported, candidate=57 |
| 111 | `branch` | `duplicate` | 6.7904e+02 | method=algebraic, source=imported, candidate=10 |
| 112 | `branch` | `duplicate` | 9.6004e+00 | method=algebraic, source=imported, candidate=85 |
| 113 | `branch` | `duplicate` | 2.5786e+00 | method=algebraic, source=imported, candidate=104 |
| 114 | `branch` | `duplicate` | 1.3071e+02 | method=algebraic, source=imported, candidate=31 |
| 115 | `branch` | `duplicate` | 9.6944e+00 | method=algebraic, source=imported, candidate=84 |
| 116 | `branch` | `duplicate` | 1.2856e+02 | method=algebraic, source=imported, candidate=32 |
| 117 | `branch` | `duplicate` | 4.0844e+01 | method=algebraic, source=imported, candidate=74 |
| 118 | `branch` | `duplicate` | 1.2000e+01 | method=algebraic, source=imported, candidate=83 |
| 119 | `branch` | `duplicate` | 4.1519e+01 | method=algebraic, source=imported, candidate=73 |
| 120 | `branch` | `duplicate` | 3.9841e+01 | method=algebraic, source=imported, candidate=75 |
| 121 | `branch` | `duplicate` | 5.3849e-01 | method=algebraic, source=imported, candidate=138 |
| 122 | `branch` | `duplicate` | 2.0448e+00 | method=algebraic, source=imported, candidate=109 |
| 123 | `branch` | `duplicate` | 1.0235e+02 | method=algebraic, source=imported, candidate=54 |
| 124 | `branch` | `duplicate` | 3.9976e+02 | method=algebraic, source=imported, candidate=16 |
| 125 | `branch` | `duplicate` | 1.1122e+02 | method=algebraic, source=imported, candidate=46 |
| 126 | `branch` | `duplicate` | 1.7358e+02 | method=algebraic, source=imported, candidate=26 |
| 127 | `branch` | `duplicate` | 1.6895e+00 | method=algebraic, source=imported, candidate=123 |
| 128 | `branch` | `duplicate` | 4.1323e+02 | method=algebraic, source=imported, candidate=15 |
| 129 | `branch` | `duplicate` | 2.9507e+01 | method=algebraic, source=imported, candidate=79 |
| 130 | `branch` | `duplicate` | 1.6788e+00 | method=algebraic, source=imported, candidate=125 |
| 131 | `branch` | `duplicate` | 1.7023e+00 | method=algebraic, source=imported, candidate=122 |
| 132 | `branch` | `duplicate` | 1.7102e+00 | method=algebraic, source=imported, candidate=121 |
| 133 | `branch` | `duplicate` | 1.7119e+00 | method=algebraic, source=imported, candidate=120 |
| 134 | `branch` | `duplicate` | 1.7873e+00 | method=algebraic, source=imported, candidate=117 |
| 135 | `branch` | `duplicate` | 1.3913e+00 | method=algebraic, source=imported, candidate=130 |
| 136 | `branch` | `duplicate` | 1.4046e+02 | method=algebraic, source=imported, candidate=28 |
| 137 | `branch` | `duplicate` | 7.8918e+00 | method=algebraic, source=imported, candidate=86 |
| 138 | `branch` | `duplicate` | 3.7439e+01 | method=algebraic, source=imported, candidate=76 |
| 139 | `branch` | `duplicate` | 3.2244e+00 | method=algebraic, source=imported, candidate=97 |
| 140 | `branch` | `duplicate` | 3.3344e+00 | method=algebraic, source=imported, candidate=95 |
| 141 | `branch` | `duplicate` | 3.7507e+00 | method=algebraic, source=imported, candidate=94 |
| 142 | `branch` | `duplicate` | 4.3455e+01 | method=algebraic, source=imported, candidate=72 |
| 143 | `branch` | `duplicate` | 1.0709e+02 | method=algebraic, source=imported, candidate=51 |
| 144 | `branch` | `duplicate` | 1.3233e+02 | method=algebraic, source=imported, candidate=30 |
| 145 | `branch` | `duplicate` | 2.6119e+03 | method=algebraic, source=imported, candidate=7 |
| 146 | `branch` | `duplicate` | 4.5549e+01 | method=algebraic, source=imported, candidate=71 |
| 147 | `branch` | `duplicate` | 4.6709e+01 | method=algebraic, source=imported, candidate=68 |
| 148 | `branch` | `duplicate` | 4.6266e+01 | method=algebraic, source=imported, candidate=70 |
| 149 | `branch` | `duplicate` | 4.6493e+01 | method=algebraic, source=imported, candidate=69 |
| 150 | `branch` | `duplicate` | 5.0974e+01 | method=algebraic, source=imported, candidate=66 |
| 151 | `branch` | `duplicate` | 5.2234e+01 | method=algebraic, source=imported, candidate=63 |
| 152 | `branch` | `duplicate` | 5.1303e+01 | method=algebraic, source=imported, candidate=65 |
| 153 | `branch` | `duplicate` | 5.1512e+01 | method=algebraic, source=imported, candidate=64 |
| 154 | `branch` | `duplicate` | 5.2262e+01 | method=algebraic, source=imported, candidate=62 |
| 155 | `branch` | `duplicate` | 4.8025e+01 | method=algebraic, source=imported, candidate=67 |
| 156 | `branch` | `duplicate` | 5.2905e+01 | method=algebraic, source=imported, candidate=61 |
| 157 | `branch` | `duplicate` | 5.5315e+01 | method=algebraic, source=imported, candidate=58 |
| 158 | `branch` | `duplicate` | 5.4450e+01 | method=algebraic, source=imported, candidate=60 |
| 159 | `branch` | `duplicate` | 1.7425e+02 | method=algebraic, source=imported, candidate=25 |
| 160 | `branch` | `duplicate` | 5.5058e+01 | method=algebraic, source=imported, candidate=59 |
| 161 | `branch` | `duplicate` | 2.3370e+02 | method=algebraic, source=imported, candidate=21 |
| 162 | `branch` | `duplicate` | 2.0440e+01 | method=algebraic, source=imported, candidate=82 |
| 163 | `branch` | `duplicate` | 2.2112e+02 | method=algebraic, source=imported, candidate=22 |
| 164 | `branch` | `duplicate` | 1.0990e+02 | method=algebraic, source=imported, candidate=48 |
| 165 | `branch` | `duplicate` | 9.3335e+03 | method=algebraic, source=imported, candidate=5 |
| 166 | `branch` | `duplicate` | 9.2736e+01 | method=algebraic, source=imported, candidate=55 |
| 167 | `branch` | `duplicate` | 2.0880e+04 | method=algebraic, source=imported, candidate=4 |
| 168 | `branch` | `duplicate` | 8.0645e+02 | method=algebraic, source=imported, candidate=9 |
| 169 | `branch` | `duplicate` | 3.3669e+04 | method=algebraic, source=imported, candidate=3 |
| 170 | `branch` | `duplicate` | 2.9684e+05 | method=algebraic, source=imported, candidate=2 |
| 171 | `branch` | `duplicate` | 2.1452e+02 | method=algebraic, source=imported, candidate=23 |
| 172 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=1 |
| 173 | `branch` | `duplicate` | 1.7914e+02 | method=algebraic, source=imported, candidate=27 |
| 174 | `branch` | `duplicate` | 2.4359e+02 | method=algebraic, source=imported, candidate=20 |
| 175 | `branch` | `duplicate` | 4.4660e+02 | method=algebraic, source=imported, candidate=13 |
| 176 | `branch` | `duplicate` | 2.4789e+02 | method=algebraic, source=imported, candidate=19 |
| 177 | `branch` | `duplicate` | 1.9249e+02 | method=algebraic, source=imported, candidate=24 |
| 178 | `branch` | `duplicate` | 3.9865e+02 | method=algebraic, source=imported, candidate=17 |
| 179 | `branch` | `duplicate` | 5.8025e+02 | method=algebraic, source=imported, candidate=11 |
| 180 | `branch` | `duplicate` | 5.7344e+02 | method=algebraic, source=imported, candidate=12 |
| 181 | `branch` | `duplicate` | 8.4790e+02 | method=algebraic, source=imported, candidate=8 |
| 182 | `branch` | `duplicate` | 6.6588e+03 | method=algebraic, source=imported, candidate=6 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | Inf | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 2.9684e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 3.3669e+04 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 2.0880e+04 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 9.3335e+03 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 6.6588e+03 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 2.6119e+03 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 8.4790e+02 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 8.0645e+02 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 6.7904e+02 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 5.8025e+02 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 5.7344e+02 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 4.4660e+02 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 4.2019e+02 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 4.1323e+02 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 3.9976e+02 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 3.9865e+02 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 3.7285e+02 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 2.4789e+02 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 2.4359e+02 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 2.3370e+02 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 2.2112e+02 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 2.1452e+02 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 1.9249e+02 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 1.7425e+02 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 1.7358e+02 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 1.7914e+02 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 1.4046e+02 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 1.3589e+02 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 1.3233e+02 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 1.3071e+02 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 1.2856e+02 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 1.2002e+02 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 1.1917e+02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 1.1915e+02 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 1.1757e+02 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 1.1695e+02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 1.1653e+02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 1.1518e+02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 1.1496e+02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 1.1467e+02 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 1.1453e+02 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 1.1451e+02 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 1.1292e+02 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 1.1290e+02 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 1.1122e+02 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 1.1071e+02 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 1.0990e+02 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 1.0974e+02 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 1.0768e+02 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 1.0709e+02 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 1.0257e+02 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | 1.0245e+02 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | 1.0235e+02 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 9.2736e+01 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 6.8812e+01 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 5.7878e+01 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 5.5315e+01 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 5.5058e+01 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 5.4450e+01 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 5.2905e+01 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 5.2262e+01 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 5.2234e+01 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 5.1512e+01 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 5.1303e+01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 5.0974e+01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 4.8025e+01 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 4.6709e+01 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 4.6493e+01 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 4.6266e+01 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 4.5549e+01 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 4.3455e+01 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#73` | 4.1519e+01 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | `baseline#74` | 4.0844e+01 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | `baseline#75` | 3.9841e+01 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | `baseline#76` | 3.7439e+01 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | `baseline#77` | 3.7250e+01 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | `baseline#78` | 3.1838e+01 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | `baseline#79` | 2.9507e+01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | `baseline#80` | 2.5924e+01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | `baseline#81` | 2.5160e+01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | `baseline#82` | 2.0440e+01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | `baseline#83` | 1.2000e+01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | `baseline#84` | 9.6944e+00 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | `baseline#85` | 9.6004e+00 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | `baseline#86` | 7.8918e+00 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | `baseline#87` | 7.1029e+00 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | `baseline#88` | 7.0814e+00 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | `baseline#89` | 6.4402e+00 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | `baseline#90` | 5.7279e+00 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | `baseline#91` | 5.7003e+00 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | `baseline#92` | 5.2288e+00 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | `baseline#93` | 4.9001e+00 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | `baseline#94` | 3.7507e+00 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | `baseline#95` | 3.3344e+00 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | `baseline#96` | 3.2515e+00 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | `baseline#97` | 3.2244e+00 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | `baseline#98` | 3.2132e+00 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | `baseline#99` | 3.1753e+00 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | `baseline#100` | 3.0414e+00 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | `baseline#101` | 2.8704e+00 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | `baseline#102` | 2.7460e+00 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | `baseline#103` | 2.6694e+00 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | `baseline#104` | 2.5786e+00 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | `baseline#105` | 2.3909e+00 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | `baseline#106` | 2.2824e+00 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | `baseline#107` | 2.1782e+00 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | `baseline#108` | 2.1258e+00 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | `baseline#109` | 2.0448e+00 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | `baseline#110` | 2.0401e+00 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | `baseline#111` | 2.0400e+00 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | `baseline#112` | 2.0187e+00 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | `baseline#113` | 1.9891e+00 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | `baseline#114` | 1.9805e+00 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | `baseline#115` | 1.9431e+00 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | `baseline#116` | 1.8041e+00 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | `baseline#117` | 1.7873e+00 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | `baseline#118` | 1.7471e+00 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | `baseline#119` | 1.7432e+00 | method=algebraic, source=imported, candidate=119 |
| 120 | `baseline` | `baseline#120` | 1.7119e+00 | method=algebraic, source=imported, candidate=120 |
| 121 | `baseline` | `baseline#121` | 1.7102e+00 | method=algebraic, source=imported, candidate=121 |
| 122 | `baseline` | `baseline#122` | 1.7023e+00 | method=algebraic, source=imported, candidate=122 |
| 123 | `baseline` | `baseline#123` | 1.6895e+00 | method=algebraic, source=imported, candidate=123 |
| 124 | `baseline` | `baseline#125` | 1.6788e+00 | method=algebraic, source=imported, candidate=125 |
| 125 | `baseline` | `baseline#126` | 1.5279e+00 | method=algebraic, source=imported, candidate=126 |
| 126 | `baseline` | `baseline#127` | 1.5259e+00 | method=algebraic, source=imported, candidate=127 |
| 127 | `baseline` | `baseline#128` | 1.5068e+00 | method=algebraic, source=imported, candidate=128 |
| 128 | `baseline` | `baseline#129` | 1.4938e+00 | method=algebraic, source=imported, candidate=129 |
| 129 | `baseline` | `baseline#130` | 1.3913e+00 | method=algebraic, source=imported, candidate=130 |
| 130 | `baseline` | `baseline#131` | 1.1848e+00 | method=algebraic, source=imported, candidate=131 |
| 131 | `baseline` | `baseline#132` | 1.0353e+00 | method=algebraic, source=imported, candidate=132 |
| 132 | `baseline` | `baseline#133` | 9.7687e-01 | method=algebraic, source=imported, candidate=133 |
| 133 | `baseline` | `baseline#134` | 8.0597e-01 | method=algebraic, source=imported, candidate=134 |
| 134 | `baseline` | `baseline#135` | 6.4938e-01 | method=algebraic, source=imported, candidate=135 |
| 135 | `baseline` | `baseline#137` | 6.4282e-01 | method=algebraic, source=imported, candidate=137 |
| 136 | `baseline` | `baseline#138` | 5.3849e-01 | method=algebraic, source=imported, candidate=138 |
| 137 | `baseline` | `baseline#139` | 5.3414e-01 | method=algebraic, source=imported, candidate=139 |
| 138 | `baseline` | `baseline#140` | 3.4454e-01 | method=algebraic, source=imported, candidate=140 |
| 139 | `baseline` | `baseline#141` | 3.3245e-01 | method=algebraic, source=imported, candidate=141 |
| 140 | `baseline` | `baseline#142` | 3.2513e-01 | method=algebraic, source=imported, candidate=142 |
| 141 | `baseline` | `baseline#143` | 1.4294e-01 | method=algebraic, source=imported, candidate=143 |
| 142 | `baseline` | `baseline#144` | 1.4237e-01 | method=algebraic, source=imported, candidate=144 |
| 143 | `baseline` | `baseline#145` | 1.1565e-01 | method=algebraic, source=imported, candidate=145 |
| 144 | `baseline` | `baseline#146` | 8.0713e-02 | method=algebraic, source=imported, candidate=146 |
| 145 | `baseline` | `baseline#147` | 4.5066e-02 | method=algebraic, source=imported, candidate=147 |
| 146 | `baseline` | `baseline#148` | 4.1284e-02 | method=algebraic, source=imported, candidate=148 |
| 147 | `baseline` | `baseline#149` | 3.7017e-02 | method=algebraic, source=imported, candidate=149 |
| 148 | `baseline` | `baseline#150` | 3.6898e-02 | method=algebraic, source=imported, candidate=150 |
| 149 | `baseline` | `baseline#151` | 3.3091e-02 | method=algebraic, source=imported, candidate=151 |
| 150 | `baseline` | `baseline#152` | 2.2854e-02 | method=algebraic, source=imported, candidate=152 |
| 151 | `baseline` | `baseline#153` | 2.1149e-02 | method=algebraic, source=imported, candidate=153 |
| 152 | `baseline` | `baseline#154` | 1.7789e-02 | method=algebraic, source=imported, candidate=154 |
| 153 | `baseline` | `baseline#155` | 1.3595e-02 | method=algebraic, source=imported, candidate=155 |
| 154 | `baseline` | `baseline#156` | 1.1448e-02 | method=algebraic, source=imported, candidate=156 |
| 155 | `baseline` | `baseline#157` | 9.6995e-03 | method=algebraic, source=imported, candidate=157 |
| 156 | `baseline` | `baseline#158` | 9.6079e-03 | method=algebraic, source=imported, candidate=158 |
| 157 | `baseline` | `baseline#159` | 8.5007e-03 | method=algebraic, source=imported, candidate=159 |
| 158 | `baseline` | `baseline#160` | 8.1282e-03 | method=algebraic, source=imported, candidate=160 |
| 159 | `baseline` | `baseline#161` | 7.4222e-03 | method=algebraic, source=imported, candidate=161 |
| 160 | `baseline` | `baseline#162` | 4.2340e-03 | method=algebraic, source=imported, candidate=162 |
| 161 | `baseline` | `baseline#163` | 3.5186e-03 | method=algebraic, source=imported, candidate=163 |
| 162 | `baseline` | `baseline#164` | 3.0835e-03 | method=algebraic, source=imported, candidate=164 |
| 163 | `baseline` | `baseline#165` | 3.0628e-03 | method=algebraic, source=imported, candidate=165 |
| 164 | `baseline` | `baseline#166` | 2.9490e-03 | method=algebraic, source=imported, candidate=166 |
| 165 | `baseline` | `baseline#167` | 2.5847e-03 | method=algebraic, source=imported, candidate=167 |
| 166 | `baseline` | `baseline#168` | 2.5147e-03 | method=algebraic, source=imported, candidate=168 |
| 167 | `baseline` | `baseline#169` | 2.2050e-03 | method=algebraic, source=imported, candidate=169 |
| 168 | `baseline` | `baseline#170` | 1.4272e-03 | method=algebraic, source=imported, candidate=170 |
| 169 | `baseline` | `baseline#171` | 1.3868e-03 | method=algebraic, source=imported, candidate=171 |
| 170 | `baseline` | `baseline#172` | 1.3401e-03 | method=algebraic, source=imported, candidate=172 |
| 171 | `baseline` | `baseline#173` | 1.2847e-03 | method=algebraic, source=imported, candidate=173 |
| 172 | `baseline` | `baseline#174` | 1.2382e-03 | method=algebraic, source=imported, candidate=174 |
| 173 | `baseline` | `baseline#175` | 9.6320e-04 | method=algebraic, source=imported, candidate=175 |
| 174 | `baseline` | `baseline#176` | 7.0823e-04 | method=algebraic, source=imported, candidate=176 |
| 175 | `baseline` | `baseline#177` | 6.5683e-04 | method=algebraic, source=imported, candidate=177 |
| 176 | `baseline` | `baseline#178` | 5.6186e-04 | method=algebraic, source=imported, candidate=178 |
| 177 | `baseline` | `baseline#179` | 4.7811e-04 | method=algebraic, source=imported, candidate=179 |
| 178 | `baseline` | `baseline#180` | 2.8381e-04 | method=algebraic, source=imported, candidate=180 |
| 179 | `baseline` | `baseline#181` | 2.8114e-04 | method=algebraic, source=imported, candidate=181 |
| 180 | `baseline` | `baseline#182` | 1.3686e-04 | method=algebraic, source=imported, candidate=182 |
| 181 | `baseline` | `baseline#183` | 1.0275e-04 | method=algebraic, source=imported, candidate=183 |
| 182 | `baseline` | `baseline#184` | 9.6532e-05 | method=algebraic, source=imported, candidate=184 |
| 183 | `baseline` | `baseline#185` | 8.8036e-05 | method=algebraic, source=imported, candidate=185 |
| 184 | `baseline` | `baseline#186` | 4.4029e-05 | method=algebraic, source=imported, candidate=186 |
| 185 | `branch+synthesized` | `branch#2, branch#3, synthesized#1, synthesized#2, synthesized#3, synthesized#4` | 3.6106e-05 | method=direct_opt, source=synthesized, polished=true |
| 186 | `block` | `block#1` | 2.6599e-02 | method=direct_opt, source=assembled |
| 187 | `block` | `block#2` | 8.0904e+01 | method=direct_opt, source=assembled |
| 188 | `block` | `block#3` | 1.0546e+02 | method=direct_opt, source=assembled |
| 189 | `block` | `block#4` | 1.1139e+02 | method=direct_opt, source=assembled |
| 190 | `block` | `block#5` | 1.9535e+04 | method=direct_opt, source=assembled |
| 191 | `block` | `block#6` | 4.1110e+03 | method=direct_opt, source=assembled |
| 192 | `block` | `block#7` | 2.7560e+05 | method=direct_opt, source=assembled |
| 193 | `block` | `block#8` | 2.7089e+05 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `mixed` | 89 | 3.6106e-05 | 1.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=46, polished=true |
| 2 | `baseline` | 40 | 1.0109e-01 | 1349.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=50, polished=true |
| 3 | `mixed` | 2 | 2.1255e-01 | 201274.98% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 4 | `baseline` | 1 | 3.2828e-04 | 97.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=81, polished=true |
| 5 | `baseline` | 1 | 1.0740e-03 | 332.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=80, polished=true |
| 6 | `baseline` | 1 | 5.2006e-03 | 1281.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=77, polished=true |
| 7 | `baseline` | 1 | 1.8399e-02 | 2721.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=54, polished=true |
| 8 | `baseline` | 1 | 2.5084e-02 | 3215.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=85, polished=true |
| 9 | `baseline` | 1 | 2.5144e-02 | 3220.26% | 0 | 0.5000 | method=algebraic, source=imported, candidate=84, polished=true |
| 10 | `baseline` | 1 | 2.7664e-02 | 3397.41% | 0 | 0.5000 | method=algebraic, source=imported, candidate=83, polished=true |
| 11 | `baseline` | 1 | 3.0924e-02 | 3622.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 12 | `baseline` | 1 | 4.9143e-02 | 3946.65% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 13 | `baseline` | 1 | 6.5545e-02 | 4142.36% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 14 | `baseline` | 1 | 1.0190e-01 | 1509.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=72, polished=true |
| 15 | `baseline` | 1 | 1.0206e-01 | 1589.08% | 0 | 0.5000 | method=algebraic, source=imported, candidate=69, polished=true |
| 16 | `baseline` | 1 | 1.0227e-01 | 1618.23% | 0 | 0.5000 | method=algebraic, source=imported, candidate=68, polished=true |
| 17 | `baseline` | 1 | 1.0392e-01 | 1794.47% | 0 | 0.5000 | method=algebraic, source=imported, candidate=70, polished=true |
| 18 | `baseline` | 1 | 1.0831e-01 | 2149.98% | 0 | 0.5000 | method=algebraic, source=imported, candidate=71, polished=true |
| 19 | `baseline` | 1 | 2.0551e-01 | 7158.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=55, polished=true |
| 20 | `baseline` | 1 | 2.0979e-01 | 17664.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 21 | `baseline` | 1 | 2.0990e-01 | 18222.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 22 | `baseline` | 1 | 2.1053e-01 | 23371.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 23 | `baseline` | 1 | 2.1056e-01 | 23796.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 24 | `baseline` | 1 | 2.1074e-01 | 25811.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 25 | `baseline` | 1 | 2.1136e-01 | 36745.40% | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 26 | `baseline` | 1 | 2.1236e-01 | 117971.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 27 | `baseline` | 1 | 2.1531e-01 | 21952.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=86, polished=true |
| 28 | `baseline` | 1 | 2.1643e-01 | 15408.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 29 | `baseline` | 1 | 2.2108e-01 | 6844.34% | 0 | 0.5000 | method=algebraic, source=imported, candidate=61, polished=true |
| 30 | `baseline` | 1 | 2.2305e-01 | 5593.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=58, polished=true |
| 31 | `baseline` | 1 | 2.2368e-01 | 5216.37% | 0 | 0.5000 | method=algebraic, source=imported, candidate=59, polished=true |
| 32 | `baseline` | 1 | 2.2712e-01 | 4019.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=65, polished=true |
| 33 | `baseline` | 1 | 2.3421e-01 | 2774.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=64, polished=true |
| 34 | `baseline` | 1 | 2.3657e-01 | 2526.50% | 0 | 0.5000 | method=algebraic, source=imported, candidate=60, polished=true |
| 35 | `baseline` | 1 | 2.4911e-01 | 1755.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=63, polished=true |
| 36 | `baseline` | 1 | 2.4922e-01 | 1748.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=66, polished=true |
| 37 | `baseline` | 1 | 2.5135e-01 | 1681.55% | 0 | 0.5000 | method=algebraic, source=imported, candidate=62, polished=true |
| 38 | `baseline` | 1 | 3.0901e-01 | 944.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 39 | `baseline` | 1 | 3.2754e-01 | 903.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=49, polished=true |
| 40 | `baseline` | 1 | 5.8157e-01 | 874.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=41, polished=true |
| 41 | `baseline` | 1 | 1.2431e+00 | 939.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 42 | `baseline` | 1 | 1.8568e+00 | 6338.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 43 | `baseline` | 1 | 2.2444e+00 | 457781.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 44 | `baseline` | 1 | 2.4653e+00 | 1035.37% | 0 | 0.5000 | method=algebraic, source=imported, candidate=44, polished=true |
| 45 | `baseline` | 1 | 2.7641e+00 | 1044.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 46 | `baseline` | 1 | 3.9894e+00 | 8065.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 47 | `baseline` | 1 | 4.3916e+00 | 1852312.77% | 0 | 0.5000 | method=algebraic, source=imported, candidate=67, polished=true |
| 48 | `block` | 1 | 4.3977e+00 | 1852314.61% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 49 | `baseline` | 1 | 5.8210e+00 | 9305.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 50 | `baseline` | 1 | 7.2471e+00 | 10043.87% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 51 | `block` | 1 | 7.7152e+00 | 1857004.99% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 52 | `block` | 1 | 7.9135e+00 | 1857072.25% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 53 | `baseline` | 1 | 9.8530e+00 | 2356.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=48, polished=true |
| 54 | `block` | 1 | 1.8105e+01 | 1856624.11% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 55 | `baseline` | 1 | 9.9171e+01 | 1010.56% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 56 | `baseline` | 1 | 1.0047e+02 | 902.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=47, polished=true |
| 57 | `baseline` | 1 | 1.0109e+02 | 988.93% | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |
| 58 | `baseline` | 1 | 1.0897e+02 | 1032.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 59 | `baseline` | 1 | 1.0914e+02 | 1033.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=43, polished=true |
| 60 | `baseline` | 1 | 1.2370e+02 | 1524.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 61 | `baseline` | 1 | 1.3182e+02 | 1889.30% | 0 | 0.5000 | method=algebraic, source=imported, candidate=30, polished=true |
| 62 | `baseline` | 1 | 1.7914e+02 | 25420.76% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 63 | `block` | 1 | 2.7089e+05 | 243858.43% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 64 | `baseline` | 1 | 2.9684e+05 | 12022.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 65 | `baseline` | 1 | Inf | 13962.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | Inf | Inf | 13962.39% | 0.174 | `` |
| 2 | `baseline` | 2.9684e+05 | 2.9684e+05 | 12022.06% | 0.174 | `` |
| 3 | `baseline` | 3.3669e+04 | 7.2471e+00 | 10043.87% | 3.678 | `` |
| 4 | `baseline` | 2.0880e+04 | 5.8210e+00 | 9305.49% | 3.268 | `` |
| 5 | `baseline` | 9.3335e+03 | 3.9894e+00 | 8065.17% | 3.122 | `` |
| 6 | `baseline` | 6.6588e+03 | 2.1255e-01 | 201462.30% | 2.124 | `` |
| 7 | `baseline` | 2.6119e+03 | 1.8568e+00 | 6338.45% | 2.742 | `` |
| 8 | `baseline` | 8.4790e+02 | 2.1074e-01 | 25811.15% | 1.766 | `` |
| 9 | `baseline` | 8.0645e+02 | 3.0901e-01 | 944.52% | 1.341 | `` |
| 10 | `baseline` | 6.7904e+02 | 4.9143e-02 | 3946.65% | 2.421 | `` |
| 11 | `baseline` | 5.8025e+02 | 2.1136e-01 | 36745.40% | 1.785 | `` |
| 12 | `baseline` | 5.7344e+02 | 2.1053e-01 | 23371.84% | 1.777 | `` |
| 13 | `baseline` | 4.4660e+02 | 2.1643e-01 | 15408.64% | 1.527 | `` |
| 14 | `baseline` | 4.2019e+02 | 3.0924e-02 | 3622.62% | 2.330 | `` |
| 15 | `baseline` | 4.1323e+02 | 6.5545e-02 | 4142.36% | 2.474 | `` |
| 16 | `baseline` | 3.9976e+02 | 1.0109e-01 | 1349.95% | 1.014 | `` |
| 17 | `baseline` | 3.9865e+02 | 2.2444e+00 | 457781.44% | 2.501 | `` |
| 18 | `baseline` | 3.7285e+02 | 3.6106e-05 | 1.48% | 1.438 | `` |
| 19 | `baseline` | 2.4789e+02 | 2.0979e-01 | 17664.06% | 1.619 | `` |
| 20 | `baseline` | 2.4359e+02 | 2.0990e-01 | 18222.45% | 1.719 | `` |
| 21 | `baseline` | 2.3370e+02 | 1.0109e-01 | 1349.95% | 1.052 | `` |
| 22 | `baseline` | 2.2112e+02 | 1.0109e-01 | 1349.95% | 1.065 | `` |
| 23 | `baseline` | 2.1452e+02 | 2.1056e-01 | 23796.17% | 1.637 | `` |
| 24 | `baseline` | 1.9249e+02 | 2.1236e-01 | 117971.73% | 2.130 | `` |
| 25 | `baseline` | 1.7425e+02 | 1.0109e-01 | 1349.95% | 1.160 | `` |
| 26 | `baseline` | 1.7358e+02 | 1.0109e-01 | 1349.95% | 0.399 | `` |
| 27 | `baseline` | 1.7914e+02 | 1.7914e+02 | 25420.76% | 0.223 | `` |
| 28 | `baseline` | 1.4046e+02 | 1.0109e-01 | 1349.95% | 0.428 | `` |
| 29 | `baseline` | 1.3589e+02 | 1.0109e-01 | 1349.95% | 0.307 | `` |
| 30 | `baseline` | 1.3233e+02 | 1.3182e+02 | 1889.30% | 4.734 | `` |
| 31 | `baseline` | 1.3071e+02 | 1.0109e-01 | 1349.95% | 0.229 | `` |
| 32 | `baseline` | 1.2856e+02 | 1.2370e+02 | 1524.45% | 3.900 | `` |
| 33 | `baseline` | 1.2002e+02 | 3.6106e-05 | 1.48% | 0.485 | `` |
| 34 | `baseline` | 1.1917e+02 | 3.6106e-05 | 1.48% | 0.381 | `` |
| 35 | `baseline` | 1.1915e+02 | 9.9171e+01 | 1010.56% | 3.206 | `` |
| 36 | `baseline` | 1.1757e+02 | 1.0109e-01 | 1349.95% | 0.418 | `` |
| 37 | `baseline` | 1.1695e+02 | 1.2431e+00 | 939.45% | 1.406 | `` |
| 38 | `baseline` | 1.1653e+02 | 1.0109e+02 | 988.93% | 3.477 | `` |
| 39 | `baseline` | 1.1518e+02 | 1.0109e-01 | 1349.95% | 0.378 | `` |
| 40 | `baseline` | 1.1496e+02 | 1.0109e-01 | 1349.95% | 0.368 | `` |
| 41 | `baseline` | 1.1467e+02 | 5.8157e-01 | 874.48% | 1.380 | `` |
| 42 | `baseline` | 1.1453e+02 | 1.0897e+02 | 1032.31% | 3.664 | `` |
| 43 | `baseline` | 1.1451e+02 | 1.0914e+02 | 1033.57% | 3.636 | `` |
| 44 | `baseline` | 1.1292e+02 | 2.4653e+00 | 1035.37% | 2.267 | `` |
| 45 | `baseline` | 1.1290e+02 | 2.7641e+00 | 1044.95% | 2.304 | `` |
| 46 | `baseline` | 1.1122e+02 | 3.6106e-05 | 1.48% | 0.496 | `` |
| 47 | `baseline` | 1.1071e+02 | 1.0047e+02 | 902.94% | 3.312 | `` |
| 48 | `baseline` | 1.0990e+02 | 9.8530e+00 | 2356.92% | 1.858 | `` |
| 49 | `baseline` | 1.0974e+02 | 3.2754e-01 | 903.53% | 1.294 | `` |
| 50 | `baseline` | 1.0768e+02 | 1.0109e-01 | 1349.95% | 0.427 | `` |
| 51 | `baseline` | 1.0709e+02 | 1.0109e-01 | 1349.95% | 0.774 | `` |
| 52 | `baseline` | 1.0257e+02 | 1.0109e-01 | 1349.95% | 0.410 | `` |
| 53 | `baseline` | 1.0245e+02 | 1.0109e-01 | 1349.95% | 0.482 | `` |
| 54 | `baseline` | 1.0235e+02 | 1.8399e-02 | 2721.32% | 2.195 | `` |
| 55 | `baseline` | 9.2736e+01 | 2.0551e-01 | 7158.95% | 1.546 | `` |
| 56 | `baseline` | 6.8812e+01 | 3.6106e-05 | 1.48% | 0.250 | `` |
| 57 | `baseline` | 5.7878e+01 | 3.6106e-05 | 1.48% | 0.227 | `` |
| 58 | `baseline` | 5.5315e+01 | 2.2305e-01 | 5593.25% | 1.472 | `` |
| 59 | `baseline` | 5.5058e+01 | 2.2368e-01 | 5216.37% | 1.408 | `` |
| 60 | `baseline` | 5.4450e+01 | 2.3657e-01 | 2526.50% | 1.148 | `` |
| 61 | `baseline` | 5.2905e+01 | 2.2108e-01 | 6844.34% | 1.453 | `` |
| 62 | `baseline` | 5.2262e+01 | 2.5135e-01 | 1681.55% | 1.184 | `` |
| 63 | `baseline` | 5.2234e+01 | 2.4911e-01 | 1755.13% | 1.096 | `` |
| 64 | `baseline` | 5.1512e+01 | 2.3421e-01 | 2774.91% | 1.182 | `` |
| 65 | `baseline` | 5.1303e+01 | 2.2712e-01 | 4019.57% | 1.317 | `` |
| 66 | `baseline` | 5.0974e+01 | 2.4922e-01 | 1748.17% | 1.110 | `` |
| 67 | `baseline` | 4.8025e+01 | 4.3916e+00 | 1852312.77% | 4.908 | `` |
| 68 | `baseline` | 4.6709e+01 | 1.0227e-01 | 1618.23% | 2.189 | `` |
| 69 | `baseline` | 4.6493e+01 | 1.0206e-01 | 1589.08% | 2.059 | `` |
| 70 | `baseline` | 4.6266e+01 | 1.0392e-01 | 1794.47% | 2.461 | `` |
| 71 | `baseline` | 4.5549e+01 | 1.0831e-01 | 2149.98% | 2.246 | `` |
| 72 | `baseline` | 4.3455e+01 | 1.0190e-01 | 1509.15% | 2.077 | `` |
| 73 | `baseline` | 4.1519e+01 | 3.6106e-05 | 1.48% | 0.217 | `` |
| 74 | `baseline` | 4.0844e+01 | 3.6106e-05 | 1.48% | 0.328 | `` |
| 75 | `baseline` | 3.9841e+01 | 3.6106e-05 | 1.48% | 0.289 | `` |
| 76 | `baseline` | 3.7439e+01 | 1.0109e-01 | 1349.95% | 1.322 | `` |
| 77 | `baseline` | 3.7250e+01 | 5.2006e-03 | 1281.46% | 1.822 | `` |
| 78 | `baseline` | 3.1838e+01 | 3.6106e-05 | 1.48% | 0.297 | `` |
| 79 | `baseline` | 2.9507e+01 | 3.6106e-05 | 1.48% | 0.150 | `` |
| 80 | `baseline` | 2.5924e+01 | 1.0740e-03 | 332.13% | 1.711 | `` |
| 81 | `baseline` | 2.5160e+01 | 3.2828e-04 | 97.64% | 1.572 | `` |
| 82 | `baseline` | 2.0440e+01 | 3.6106e-05 | 1.48% | 1.163 | `` |
| 83 | `baseline` | 1.2000e+01 | 2.7664e-02 | 3397.41% | 2.227 | `` |
| 84 | `baseline` | 9.6944e+00 | 2.5144e-02 | 3220.26% | 2.284 | `` |
| 85 | `baseline` | 9.6004e+00 | 2.5084e-02 | 3215.90% | 2.295 | `` |
| 86 | `baseline` | 7.8918e+00 | 2.1531e-01 | 21952.83% | 1.799 | `` |
| 87 | `baseline` | 7.1029e+00 | 3.6106e-05 | 1.48% | 0.577 | `` |
| 88 | `baseline` | 7.0814e+00 | 3.6106e-05 | 1.48% | 0.226 | `` |
| 89 | `baseline` | 6.4402e+00 | 3.6106e-05 | 1.48% | 0.277 | `` |
| 90 | `baseline` | 5.7279e+00 | 3.6106e-05 | 1.48% | 0.562 | `` |
| 91 | `baseline` | 5.7003e+00 | 3.6106e-05 | 1.48% | 0.341 | `` |
| 92 | `baseline` | 5.2288e+00 | 3.6106e-05 | 1.48% | 0.777 | `` |
| 93 | `baseline` | 4.9001e+00 | 3.6106e-05 | 1.48% | 0.358 | `` |
| 94 | `baseline` | 3.7507e+00 | 3.6106e-05 | 1.48% | 0.378 | `` |
| 95 | `baseline` | 3.3344e+00 | 3.6106e-05 | 1.48% | 0.429 | `` |
| 96 | `baseline` | 3.2515e+00 | 3.6106e-05 | 1.48% | 0.850 | `` |
| 97 | `baseline` | 3.2244e+00 | 3.6106e-05 | 1.48% | 0.385 | `` |
| 98 | `baseline` | 3.2132e+00 | 3.6106e-05 | 1.48% | 0.205 | `` |
| 99 | `baseline` | 3.1753e+00 | 3.6106e-05 | 1.48% | 0.442 | `` |
| 100 | `baseline` | 3.0414e+00 | 1.0109e-01 | 1349.95% | 0.345 | `` |
| 101 | `baseline` | 2.8704e+00 | 3.6106e-05 | 1.48% | 0.248 | `` |
| 102 | `baseline` | 2.7460e+00 | 1.0109e-01 | 1349.95% | 0.273 | `` |
| 103 | `baseline` | 2.6694e+00 | 3.6106e-05 | 1.48% | 0.215 | `` |
| 104 | `baseline` | 2.5786e+00 | 3.6106e-05 | 1.48% | 0.147 | `` |
| 105 | `baseline` | 2.3909e+00 | 3.6106e-05 | 1.48% | 0.307 | `` |
| 106 | `baseline` | 2.2824e+00 | 1.0109e-01 | 1349.95% | 0.366 | `` |
| 107 | `baseline` | 2.1782e+00 | 3.6106e-05 | 1.48% | 0.216 | `` |
| 108 | `baseline` | 2.1258e+00 | 1.0109e-01 | 1349.95% | 0.418 | `` |
| 109 | `baseline` | 2.0448e+00 | 1.0109e-01 | 1349.95% | 0.387 | `` |
| 110 | `baseline` | 2.0401e+00 | 1.0109e-01 | 1349.95% | 0.406 | `` |
| 111 | `baseline` | 2.0400e+00 | 1.0109e-01 | 1349.95% | 0.265 | `` |
| 112 | `baseline` | 2.0187e+00 | 1.0109e-01 | 1349.95% | 0.372 | `` |
| 113 | `baseline` | 1.9891e+00 | 1.0109e-01 | 1349.95% | 0.351 | `` |
| 114 | `baseline` | 1.9805e+00 | 1.0109e-01 | 1349.95% | 0.324 | `` |
| 115 | `baseline` | 1.9431e+00 | 1.0109e-01 | 1349.95% | 0.253 | `` |
| 116 | `baseline` | 1.8041e+00 | 1.0109e-01 | 1349.95% | 0.325 | `` |
| 117 | `baseline` | 1.7873e+00 | 1.0109e-01 | 1349.95% | 0.334 | `` |
| 118 | `baseline` | 1.7471e+00 | 1.0109e-01 | 1349.95% | 0.296 | `` |
| 119 | `baseline` | 1.7432e+00 | 1.0109e-01 | 1349.95% | 0.392 | `` |
| 120 | `baseline` | 1.7119e+00 | 1.0109e-01 | 1349.95% | 0.520 | `` |
| 121 | `baseline` | 1.7102e+00 | 1.0109e-01 | 1349.95% | 0.488 | `` |
| 122 | `baseline` | 1.7023e+00 | 1.0109e-01 | 1349.95% | 0.376 | `` |
| 123 | `baseline` | 1.6895e+00 | 1.0109e-01 | 1349.95% | 0.396 | `` |
| 124 | `baseline` | 1.6788e+00 | 1.0109e-01 | 1349.95% | 0.481 | `` |
| 125 | `baseline` | 1.5279e+00 | 3.6106e-05 | 1.48% | 0.110 | `` |
| 126 | `baseline` | 1.5259e+00 | 3.6106e-05 | 1.48% | 0.214 | `` |
| 127 | `baseline` | 1.5068e+00 | 3.6106e-05 | 1.48% | 0.114 | `` |
| 128 | `baseline` | 1.4938e+00 | 3.6106e-05 | 1.48% | 0.188 | `` |
| 129 | `baseline` | 1.3913e+00 | 1.0109e-01 | 1349.95% | 0.558 | `` |
| 130 | `baseline` | 1.1848e+00 | 3.6106e-05 | 1.48% | 0.195 | `` |
| 131 | `baseline` | 1.0353e+00 | 3.6106e-05 | 1.48% | 0.161 | `` |
| 132 | `baseline` | 9.7687e-01 | 3.6106e-05 | 1.48% | 0.401 | `` |
| 133 | `baseline` | 8.0597e-01 | 3.6106e-05 | 1.48% | 0.116 | `` |
| 134 | `baseline` | 6.4938e-01 | 3.6106e-05 | 1.48% | 0.323 | `` |
| 135 | `baseline` | 6.4282e-01 | 3.6106e-05 | 1.48% | 0.079 | `` |
| 136 | `baseline` | 5.3849e-01 | 1.0109e-01 | 1349.95% | 0.501 | `` |
| 137 | `baseline` | 5.3414e-01 | 3.6106e-05 | 1.48% | 0.075 | `` |
| 138 | `baseline` | 3.4454e-01 | 1.0109e-01 | 1349.95% | 0.223 | `` |
| 139 | `baseline` | 3.3245e-01 | 3.6106e-05 | 1.48% | 0.227 | `` |
| 140 | `baseline` | 3.2513e-01 | 1.0109e-01 | 1349.95% | 0.178 | `` |
| 141 | `baseline` | 1.4294e-01 | 3.6106e-05 | 1.48% | 0.132 | `` |
| 142 | `baseline` | 1.4237e-01 | 3.6106e-05 | 1.48% | 0.235 | `` |
| 143 | `baseline` | 1.1565e-01 | 3.6106e-05 | 1.48% | 0.104 | `` |
| 144 | `baseline` | 8.0713e-02 | 3.6106e-05 | 1.48% | 0.146 | `` |
| 145 | `baseline` | 4.5066e-02 | 3.6106e-05 | 1.48% | 0.106 | `` |
| 146 | `baseline` | 4.1284e-02 | 3.6106e-05 | 1.48% | 0.683 | `` |
| 147 | `baseline` | 3.7017e-02 | 3.6106e-05 | 1.48% | 0.296 | `` |
| 148 | `baseline` | 3.6898e-02 | 3.6106e-05 | 1.48% | 0.283 | `` |
| 149 | `baseline` | 3.3091e-02 | 3.6106e-05 | 1.48% | 0.085 | `` |
| 150 | `baseline` | 2.2854e-02 | 3.6106e-05 | 1.48% | 0.152 | `` |
| 151 | `baseline` | 2.1149e-02 | 3.6106e-05 | 1.48% | 0.255 | `` |
| 152 | `baseline` | 1.7789e-02 | 3.6106e-05 | 1.48% | 0.082 | `` |
| 153 | `baseline` | 1.3595e-02 | 3.6106e-05 | 1.48% | 0.096 | `` |
| 154 | `baseline` | 1.1448e-02 | 3.6106e-05 | 1.48% | 0.105 | `` |
| 155 | `baseline` | 9.6995e-03 | 3.6106e-05 | 1.48% | 0.109 | `` |
| 156 | `baseline` | 9.6079e-03 | 3.6106e-05 | 1.48% | 0.159 | `` |
| 157 | `baseline` | 8.5007e-03 | 3.6106e-05 | 1.48% | 0.083 | `` |
| 158 | `baseline` | 8.1282e-03 | 3.6106e-05 | 1.48% | 0.133 | `` |
| 159 | `baseline` | 7.4222e-03 | 3.6106e-05 | 1.48% | 0.119 | `` |
| 160 | `baseline` | 4.2340e-03 | 3.6106e-05 | 1.48% | 0.176 | `` |
| 161 | `baseline` | 3.5186e-03 | 3.6106e-05 | 1.48% | 0.069 | `` |
| 162 | `baseline` | 3.0835e-03 | 3.6106e-05 | 1.48% | 0.099 | `` |
| 163 | `baseline` | 3.0628e-03 | 3.6106e-05 | 1.48% | 0.119 | `` |
| 164 | `baseline` | 2.9490e-03 | 3.6106e-05 | 1.48% | 0.095 | `` |
| 165 | `baseline` | 2.5847e-03 | 3.6106e-05 | 1.48% | 0.165 | `` |
| 166 | `baseline` | 2.5147e-03 | 3.6106e-05 | 1.48% | 0.065 | `` |
| 167 | `baseline` | 2.2050e-03 | 3.6106e-05 | 1.48% | 0.083 | `` |
| 168 | `baseline` | 1.4272e-03 | 3.6106e-05 | 1.48% | 0.108 | `` |
| 169 | `baseline` | 1.3868e-03 | 3.6106e-05 | 1.48% | 0.096 | `` |
| 170 | `baseline` | 1.3401e-03 | 3.6106e-05 | 1.48% | 0.169 | `` |
| 171 | `baseline` | 1.2847e-03 | 3.6106e-05 | 1.48% | 0.070 | `` |
| 172 | `baseline` | 1.2382e-03 | 3.6106e-05 | 1.48% | 0.071 | `` |
| 173 | `baseline` | 9.6320e-04 | 3.6106e-05 | 1.48% | 0.078 | `` |
| 174 | `baseline` | 7.0823e-04 | 3.6106e-05 | 1.48% | 0.080 | `` |
| 175 | `baseline` | 6.5683e-04 | 3.6106e-05 | 1.48% | 0.105 | `` |
| 176 | `baseline` | 5.6186e-04 | 3.6106e-05 | 1.48% | 0.149 | `` |
| 177 | `baseline` | 4.7811e-04 | 3.6106e-05 | 1.48% | 0.073 | `` |
| 178 | `baseline` | 2.8381e-04 | 3.6106e-05 | 1.48% | 0.085 | `` |
| 179 | `baseline` | 2.8114e-04 | 3.6106e-05 | 1.48% | 0.079 | `` |
| 180 | `baseline` | 1.3686e-04 | 3.6106e-05 | 1.48% | 0.067 | `` |
| 181 | `baseline` | 1.0275e-04 | 3.6106e-05 | 1.48% | 0.067 | `` |
| 182 | `baseline` | 9.6532e-05 | 3.6106e-05 | 1.48% | 0.067 | `` |
| 183 | `baseline` | 8.8036e-05 | 3.6106e-05 | 1.48% | 0.124 | `` |
| 184 | `baseline` | 4.4029e-05 | 3.6106e-05 | 1.48% | 0.038 | `` |
| 185 | `branch+synthesized` | 3.6106e-05 | 3.6106e-05 | 1.48% | 0.011 | `` |
| 186 | `block` | 2.6599e-02 | 3.6106e-05 | 1.48% | 0.069 | `` |
| 187 | `block` | 8.0904e+01 | 4.3977e+00 | 1852314.61% | 4.935 | `` |
| 188 | `block` | 1.0546e+02 | 1.8105e+01 | 1856624.11% | 2.928 | `` |
| 189 | `block` | 1.1139e+02 | 3.6106e-05 | 1.48% | 1.236 | `` |
| 190 | `block` | 1.9535e+04 | 7.7152e+00 | 1857004.99% | 5.048 | `` |
| 191 | `block` | 4.1110e+03 | 7.9135e+00 | 1857072.25% | 4.922 | `` |
| 192 | `block` | 2.7560e+05 | 2.1255e-01 | 201274.98% | 2.050 | `` |
| 193 | `block` | 2.7089e+05 | 2.7089e+05 | 243858.43% | 0.025 | `` |

