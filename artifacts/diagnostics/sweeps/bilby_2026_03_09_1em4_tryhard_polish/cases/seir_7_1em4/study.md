# Tryhard Finalist Benchmark Case: seir_7_1em4

- Model: `seir`
- Role: `hard target`
- Selected via: `family_priority`
- Generated: `2026-04-14T09:17:11.627`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/seir_7_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/seir_7_1em4`

## Comparison-Table Reference

- Classification: `both_fail`
- Comparison CSV ODEPE mean/max relative error: 172.20% / 531.21%
- Comparison CSV ODEPE runtime: 4210.162 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 298 | 91870.57% | b (243066.38%) | 4.6701e+01 |
| `odepe_polish` | 542 | 647.61% | E(0) (1704.90%) | 4.2416e+01 |

## Imported Raw Pool

- Raw imported candidates: 298
- Best raw fit index: 297
- Best raw oracle index: 115
- Best-fit vs best-truth combined-RMSE gap: 91501.61%

## Local Tryhard Runtime

- Reference CSV load/scoring: 10.013 s
- Consensus/block context: 34.427 s
- 4x4 baseline evidence report: 65.915 s
- 4x4 block no-polish report: 4.480 s
- Polish context build: 0.007 s
- Baseline-only finalists: 410.515 s
- Additive-only finalists: 409.398 s
- Reasonable frontier finalists: 405.336 s
- Local total (excluding reference load): 1917.893 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 91870.57% | 91870.57% | 295 | `raw` | 4.6701e+01 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 647.61% | 647.61% | 542 | `benchmark` | 4.2416e+01 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 14540.38% | 14540.38% | 311 | `block` | 5.2075e+04 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 28351.97% | 238.72% | 229 | `baseline` | 4.3682e+01 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 28351.97% | 238.72% | 245 | `branch` | 4.3682e+01 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 28351.97% | 238.72% | 244 | `baseline` | 4.3682e+01 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 99 / 238.72%
- Additive best finalist index / RMSE: 105 / 238.72%
- Frontier best finalist index / RMSE: 107 / 238.72%
- Baseline preserved seeds: 295
- Additive candidate seeds: 311
- Frontier admitted seeds: 310
- Rejected additive seeds: 296
- Successful merged polished seeds: 310
- Returned merged finalists: 244

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 6.9689e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 2.0853e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 1.8277e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 1.8277e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 1.5368e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 1.5368e+06 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 1.4401e+06 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 1.4401e+06 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 1.0039e+06 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 1.0039e+06 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 2.2358e+05 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 1.7505e+05 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 1.7505e+05 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 1.1407e+05 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 1.1407e+05 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 9.8485e+04 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 9.8485e+04 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 6.3183e+04 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 5.8657e+04 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 5.8657e+04 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 5.6873e+04 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 5.6873e+04 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 5.6225e+04 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 5.6225e+04 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 5.2785e+04 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 5.2785e+04 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 4.4985e+04 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 4.4985e+04 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 4.4604e+04 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 4.4604e+04 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 4.1451e+04 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 4.1451e+04 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 4.1397e+04 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 4.1397e+04 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | 4.1049e+04 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | 4.1049e+04 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 4.0317e+04 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | Inf | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 4.0308e+04 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | Inf | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 4.0228e+04 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 4.0228e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 4.0217e+04 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 4.0217e+04 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 4.0204e+04 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 4.0204e+04 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 3.9856e+04 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 3.9856e+04 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 3.9137e+04 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 3.9137e+04 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 3.8538e+04 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 3.8538e+04 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | 3.8433e+04 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | 3.8433e+04 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 3.7791e+04 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 3.7791e+04 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 3.7701e+04 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 3.7701e+04 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 3.6740e+04 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 3.6719e+04 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 3.6492e+04 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 3.6492e+04 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 3.6128e+04 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 3.6128e+04 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 3.6075e+04 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 3.6075e+04 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 3.6015e+04 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 3.6015e+04 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 3.5979e+04 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 3.5691e+04 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 3.5691e+04 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 3.5821e+04 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 74 | 3.5490e+04 | method=algebraic, source=imported, candidate=74 |
| 74 | `baseline` | 76 | 3.5288e+04 | method=algebraic, source=imported, candidate=76 |
| 75 | `baseline` | 77 | 3.5212e+04 | method=algebraic, source=imported, candidate=77 |
| 76 | `baseline` | 78 | 3.5088e+04 | method=algebraic, source=imported, candidate=78 |
| 77 | `baseline` | 79 | 3.5088e+04 | method=algebraic, source=imported, candidate=79 |
| 78 | `baseline` | 80 | 3.5032e+04 | method=algebraic, source=imported, candidate=80 |
| 79 | `baseline` | 81 | 3.4984e+04 | method=algebraic, source=imported, candidate=81 |
| 80 | `baseline` | 82 | 3.4984e+04 | method=algebraic, source=imported, candidate=82 |
| 81 | `baseline` | 83 | 3.4930e+04 | method=algebraic, source=imported, candidate=83 |
| 82 | `baseline` | 84 | 3.4930e+04 | method=algebraic, source=imported, candidate=84 |
| 83 | `baseline` | 85 | 3.3257e+04 | method=algebraic, source=imported, candidate=85 |
| 84 | `baseline` | 86 | 3.3257e+04 | method=algebraic, source=imported, candidate=86 |
| 85 | `baseline` | 87 | 3.3015e+04 | method=algebraic, source=imported, candidate=87 |
| 86 | `baseline` | 88 | 3.2624e+04 | method=algebraic, source=imported, candidate=88 |
| 87 | `baseline` | 89 | 3.0151e+04 | method=algebraic, source=imported, candidate=89 |
| 88 | `baseline` | 90 | 3.0151e+04 | method=algebraic, source=imported, candidate=90 |
| 89 | `baseline` | 91 | 2.9870e+04 | method=algebraic, source=imported, candidate=91 |
| 90 | `baseline` | 92 | 2.9870e+04 | method=algebraic, source=imported, candidate=92 |
| 91 | `baseline` | 93 | 2.7965e+04 | method=algebraic, source=imported, candidate=93 |
| 92 | `baseline` | 94 | 2.7965e+04 | method=algebraic, source=imported, candidate=94 |
| 93 | `baseline` | 95 | 2.7570e+04 | method=algebraic, source=imported, candidate=95 |
| 94 | `baseline` | 96 | 2.6996e+04 | method=algebraic, source=imported, candidate=96 |
| 95 | `baseline` | 97 | 2.6996e+04 | method=algebraic, source=imported, candidate=97 |
| 96 | `baseline` | 98 | 2.5955e+04 | method=algebraic, source=imported, candidate=98 |
| 97 | `baseline` | 99 | 2.5258e+04 | method=algebraic, source=imported, candidate=99 |
| 98 | `baseline` | 100 | 2.5174e+04 | method=algebraic, source=imported, candidate=100 |
| 99 | `baseline` | 101 | 2.5174e+04 | method=algebraic, source=imported, candidate=101 |
| 100 | `baseline` | 102 | 2.4777e+04 | method=algebraic, source=imported, candidate=102 |
| 101 | `baseline` | 103 | 2.4777e+04 | method=algebraic, source=imported, candidate=103 |
| 102 | `baseline` | 104 | 2.3604e+04 | method=algebraic, source=imported, candidate=104 |
| 103 | `baseline` | 105 | 2.3604e+04 | method=algebraic, source=imported, candidate=105 |
| 104 | `baseline` | 106 | 2.3539e+04 | method=algebraic, source=imported, candidate=106 |
| 105 | `baseline` | 107 | 2.3539e+04 | method=algebraic, source=imported, candidate=107 |
| 106 | `baseline` | 108 | 2.1929e+04 | method=algebraic, source=imported, candidate=108 |
| 107 | `baseline` | 109 | 2.1929e+04 | method=algebraic, source=imported, candidate=109 |
| 108 | `baseline` | 110 | 2.1166e+04 | method=algebraic, source=imported, candidate=110 |
| 109 | `baseline` | 111 | 1.7627e+04 | method=algebraic, source=imported, candidate=111 |
| 110 | `baseline` | 112 | 1.7627e+04 | method=algebraic, source=imported, candidate=112 |
| 111 | `baseline` | 113 | 1.7574e+04 | method=algebraic, source=imported, candidate=113 |
| 112 | `baseline` | 114 | 1.7022e+04 | method=algebraic, source=imported, candidate=114 |
| 113 | `baseline` | 115 | 1.6313e+04 | method=algebraic, source=imported, candidate=115 |
| 114 | `baseline` | 116 | 1.6313e+04 | method=algebraic, source=imported, candidate=116 |
| 115 | `baseline` | 117 | 1.5781e+04 | method=algebraic, source=imported, candidate=117 |
| 116 | `baseline` | 118 | 1.5781e+04 | method=algebraic, source=imported, candidate=118 |
| 117 | `baseline` | 119 | 1.3817e+04 | method=algebraic, source=imported, candidate=119 |
| 118 | `baseline` | 120 | 1.3469e+04 | method=algebraic, source=imported, candidate=120 |
| 119 | `baseline` | 121 | 1.3469e+04 | method=algebraic, source=imported, candidate=121 |
| 120 | `baseline` | 122 | 1.2754e+04 | method=algebraic, source=imported, candidate=122 |
| 121 | `baseline` | 123 | 1.2754e+04 | method=algebraic, source=imported, candidate=123 |
| 122 | `baseline` | 124 | 1.2546e+04 | method=algebraic, source=imported, candidate=124 |
| 123 | `baseline` | 125 | 1.2517e+04 | method=algebraic, source=imported, candidate=125 |
| 124 | `baseline` | 126 | 3.5533e+03 | method=algebraic, source=imported, candidate=126 |
| 125 | `baseline` | 127 | 9.1848e+03 | method=algebraic, source=imported, candidate=127 |
| 126 | `baseline` | 128 | 9.1848e+03 | method=algebraic, source=imported, candidate=128 |
| 127 | `baseline` | 129 | 8.6819e+03 | method=algebraic, source=imported, candidate=129 |
| 128 | `baseline` | 130 | 8.6819e+03 | method=algebraic, source=imported, candidate=130 |
| 129 | `baseline` | 131 | 1.1704e+03 | method=algebraic, source=imported, candidate=131 |
| 130 | `baseline` | 132 | 5.5309e+03 | method=algebraic, source=imported, candidate=132 |
| 131 | `baseline` | 133 | 5.5309e+03 | method=algebraic, source=imported, candidate=133 |
| 132 | `baseline` | 134 | 5.1958e+03 | method=algebraic, source=imported, candidate=134 |
| 133 | `baseline` | 135 | 5.1958e+03 | method=algebraic, source=imported, candidate=135 |
| 134 | `baseline` | 136 | 4.8991e+03 | method=algebraic, source=imported, candidate=136 |
| 135 | `baseline` | 137 | 4.6880e+03 | method=algebraic, source=imported, candidate=137 |
| 136 | `baseline` | 138 | 4.6880e+03 | method=algebraic, source=imported, candidate=138 |
| 137 | `baseline` | 139 | 4.7362e+03 | method=algebraic, source=imported, candidate=139 |
| 138 | `baseline` | 140 | 4.7362e+03 | method=algebraic, source=imported, candidate=140 |
| 139 | `baseline` | 141 | 4.6605e+03 | method=algebraic, source=imported, candidate=141 |
| 140 | `baseline` | 142 | 4.5900e+03 | method=algebraic, source=imported, candidate=142 |
| 141 | `baseline` | 143 | 4.5900e+03 | method=algebraic, source=imported, candidate=143 |
| 142 | `baseline` | 144 | 4.4946e+03 | method=algebraic, source=imported, candidate=144 |
| 143 | `baseline` | 145 | 4.4946e+03 | method=algebraic, source=imported, candidate=145 |
| 144 | `baseline` | 146 | 4.3390e+03 | method=algebraic, source=imported, candidate=146 |
| 145 | `baseline` | 147 | 3.8887e+03 | method=algebraic, source=imported, candidate=147 |
| 146 | `baseline` | 148 | 3.8887e+03 | method=algebraic, source=imported, candidate=148 |
| 147 | `baseline` | 149 | 3.4009e+03 | method=algebraic, source=imported, candidate=149 |
| 148 | `baseline` | 150 | 3.4009e+03 | method=algebraic, source=imported, candidate=150 |
| 149 | `baseline` | 151 | 3.0077e+03 | method=algebraic, source=imported, candidate=151 |
| 150 | `baseline` | 152 | 3.0077e+03 | method=algebraic, source=imported, candidate=152 |
| 151 | `baseline` | 153 | 2.8944e+03 | method=algebraic, source=imported, candidate=153 |
| 152 | `baseline` | 154 | 2.8944e+03 | method=algebraic, source=imported, candidate=154 |
| 153 | `baseline` | 155 | 2.8417e+03 | method=algebraic, source=imported, candidate=155 |
| 154 | `baseline` | 156 | 2.8417e+03 | method=algebraic, source=imported, candidate=156 |
| 155 | `baseline` | 157 | 2.1196e+03 | method=algebraic, source=imported, candidate=157 |
| 156 | `baseline` | 158 | 2.1196e+03 | method=algebraic, source=imported, candidate=158 |
| 157 | `baseline` | 159 | 1.9891e+03 | method=algebraic, source=imported, candidate=159 |
| 158 | `baseline` | 160 | 1.9891e+03 | method=algebraic, source=imported, candidate=160 |
| 159 | `baseline` | 161 | 1.9177e+03 | method=algebraic, source=imported, candidate=161 |
| 160 | `baseline` | 162 | 1.9177e+03 | method=algebraic, source=imported, candidate=162 |
| 161 | `baseline` | 163 | 1.7926e+03 | method=algebraic, source=imported, candidate=163 |
| 162 | `baseline` | 164 | 1.7926e+03 | method=algebraic, source=imported, candidate=164 |
| 163 | `baseline` | 165 | 1.7923e+03 | method=algebraic, source=imported, candidate=165 |
| 164 | `baseline` | 166 | 1.7923e+03 | method=algebraic, source=imported, candidate=166 |
| 165 | `baseline` | 167 | 1.5226e+03 | method=algebraic, source=imported, candidate=167 |
| 166 | `baseline` | 168 | 1.5123e+03 | method=algebraic, source=imported, candidate=168 |
| 167 | `baseline` | 169 | 1.5123e+03 | method=algebraic, source=imported, candidate=169 |
| 168 | `baseline` | 170 | 1.3970e+03 | method=algebraic, source=imported, candidate=170 |
| 169 | `baseline` | 171 | 1.3970e+03 | method=algebraic, source=imported, candidate=171 |
| 170 | `baseline` | 175 | 1.3841e+03 | method=algebraic, source=imported, candidate=175 |
| 171 | `baseline` | 173 | 1.3967e+03 | method=algebraic, source=imported, candidate=173 |
| 172 | `baseline` | 174 | 1.3841e+03 | method=algebraic, source=imported, candidate=174 |
| 173 | `baseline` | 176 | 1.2161e+03 | method=algebraic, source=imported, candidate=176 |
| 174 | `baseline` | 177 | 1.0612e+03 | method=algebraic, source=imported, candidate=177 |
| 175 | `baseline` | 178 | 1.0010e+03 | method=algebraic, source=imported, candidate=178 |
| 176 | `baseline` | 179 | 1.0010e+03 | method=algebraic, source=imported, candidate=179 |
| 177 | `baseline` | 180 | 9.8873e+02 | method=algebraic, source=imported, candidate=180 |
| 178 | `baseline` | 181 | 9.3026e+02 | method=algebraic, source=imported, candidate=181 |
| 179 | `baseline` | 182 | 9.3026e+02 | method=algebraic, source=imported, candidate=182 |
| 180 | `baseline` | 183 | 8.9082e+02 | method=algebraic, source=imported, candidate=183 |
| 181 | `baseline` | 184 | 7.9976e+02 | method=algebraic, source=imported, candidate=184 |
| 182 | `baseline` | 185 | 7.9976e+02 | method=algebraic, source=imported, candidate=185 |
| 183 | `baseline` | 186 | 7.0820e+02 | method=algebraic, source=imported, candidate=186 |
| 184 | `baseline` | 187 | 7.0820e+02 | method=algebraic, source=imported, candidate=187 |
| 185 | `baseline` | 188 | 6.1046e+02 | method=algebraic, source=imported, candidate=188 |
| 186 | `baseline` | 189 | 5.8884e+02 | method=algebraic, source=imported, candidate=189 |
| 187 | `baseline` | 190 | 5.4610e+02 | method=algebraic, source=imported, candidate=190 |
| 188 | `baseline` | 191 | 5.3934e+02 | method=algebraic, source=imported, candidate=191 |
| 189 | `baseline` | 192 | 5.3858e+02 | method=algebraic, source=imported, candidate=192 |
| 190 | `baseline` | 193 | 5.3472e+02 | method=algebraic, source=imported, candidate=193 |
| 191 | `baseline` | 194 | 5.3219e+02 | method=algebraic, source=imported, candidate=194 |
| 192 | `baseline` | 195 | 5.2513e+02 | method=algebraic, source=imported, candidate=195 |
| 193 | `baseline` | 196 | 5.1306e+02 | method=algebraic, source=imported, candidate=196 |
| 194 | `baseline` | 197 | 5.0654e+02 | method=algebraic, source=imported, candidate=197 |
| 195 | `baseline` | 198 | 5.0579e+02 | method=algebraic, source=imported, candidate=198 |
| 196 | `baseline` | 199 | 4.9943e+02 | method=algebraic, source=imported, candidate=199 |
| 197 | `baseline` | 200 | 4.9943e+02 | method=algebraic, source=imported, candidate=200 |
| 198 | `baseline` | 201 | 4.9185e+02 | method=algebraic, source=imported, candidate=201 |
| 199 | `baseline` | 202 | 4.9185e+02 | method=algebraic, source=imported, candidate=202 |
| 200 | `baseline` | 203 | 4.9052e+02 | method=algebraic, source=imported, candidate=203 |
| 201 | `baseline` | 204 | 4.9052e+02 | method=algebraic, source=imported, candidate=204 |
| 202 | `baseline` | 205 | 4.8547e+02 | method=algebraic, source=imported, candidate=205 |
| 203 | `baseline` | 206 | 4.8426e+02 | method=algebraic, source=imported, candidate=206 |
| 204 | `baseline` | 207 | 4.8426e+02 | method=algebraic, source=imported, candidate=207 |
| 205 | `baseline` | 208 | 4.7309e+02 | method=algebraic, source=imported, candidate=208 |
| 206 | `baseline` | 209 | 4.6783e+02 | method=algebraic, source=imported, candidate=209 |
| 207 | `baseline` | 210 | 4.5945e+02 | method=algebraic, source=imported, candidate=210 |
| 208 | `baseline` | 211 | 4.5573e+02 | method=algebraic, source=imported, candidate=211 |
| 209 | `baseline` | 212 | 4.4630e+02 | method=algebraic, source=imported, candidate=212 |
| 210 | `baseline` | 213 | 4.2477e+02 | method=algebraic, source=imported, candidate=213 |
| 211 | `baseline` | 214 | 4.2477e+02 | method=algebraic, source=imported, candidate=214 |
| 212 | `baseline` | 215 | 4.1918e+02 | method=algebraic, source=imported, candidate=215 |
| 213 | `baseline` | 216 | 4.1787e+02 | method=algebraic, source=imported, candidate=216 |
| 214 | `baseline` | 217 | 4.1786e+02 | method=algebraic, source=imported, candidate=217 |
| 215 | `baseline` | 218 | 4.1715e+02 | method=algebraic, source=imported, candidate=218 |
| 216 | `baseline` | 219 | 4.0415e+02 | method=algebraic, source=imported, candidate=219 |
| 217 | `baseline` | 220 | 3.7639e+02 | method=algebraic, source=imported, candidate=220 |
| 218 | `baseline` | 221 | 3.7639e+02 | method=algebraic, source=imported, candidate=221 |
| 219 | `baseline` | 222 | 3.6898e+02 | method=algebraic, source=imported, candidate=222 |
| 220 | `baseline` | 223 | 3.6898e+02 | method=algebraic, source=imported, candidate=223 |
| 221 | `baseline` | 224 | 3.5785e+02 | method=algebraic, source=imported, candidate=224 |
| 222 | `baseline` | 225 | 3.5785e+02 | method=algebraic, source=imported, candidate=225 |
| 223 | `baseline` | 226 | 3.5580e+02 | method=algebraic, source=imported, candidate=226 |
| 224 | `baseline` | 227 | 2.8808e+02 | method=algebraic, source=imported, candidate=227 |
| 225 | `baseline` | 228 | 2.8808e+02 | method=algebraic, source=imported, candidate=228 |
| 226 | `baseline` | 229 | 3.4391e+02 | method=algebraic, source=imported, candidate=229 |
| 227 | `baseline` | 230 | 3.4043e+02 | method=algebraic, source=imported, candidate=230 |
| 228 | `baseline` | 231 | 3.0706e+02 | method=algebraic, source=imported, candidate=231 |
| 229 | `baseline` | 232 | 3.0706e+02 | method=algebraic, source=imported, candidate=232 |
| 230 | `baseline` | 233 | 2.9161e+02 | method=algebraic, source=imported, candidate=233 |
| 231 | `baseline` | 234 | 2.7749e+02 | method=algebraic, source=imported, candidate=234 |
| 232 | `baseline` | 235 | 2.7749e+02 | method=algebraic, source=imported, candidate=235 |
| 233 | `baseline` | 236 | 2.5253e+02 | method=algebraic, source=imported, candidate=236 |
| 234 | `baseline` | 237 | 2.4383e+02 | method=algebraic, source=imported, candidate=237 |
| 235 | `baseline` | 238 | 2.2958e+02 | method=algebraic, source=imported, candidate=238 |
| 236 | `baseline` | 239 | 2.0690e+02 | method=algebraic, source=imported, candidate=239 |
| 237 | `baseline` | 240 | 2.0281e+02 | method=algebraic, source=imported, candidate=240 |
| 238 | `baseline` | 241 | 1.9815e+02 | method=algebraic, source=imported, candidate=241 |
| 239 | `baseline` | 242 | 1.9272e+02 | method=algebraic, source=imported, candidate=242 |
| 240 | `baseline` | 243 | 1.7934e+02 | method=algebraic, source=imported, candidate=243 |
| 241 | `baseline` | 244 | 1.7934e+02 | method=algebraic, source=imported, candidate=244 |
| 242 | `baseline` | 245 | 1.5390e+02 | method=algebraic, source=imported, candidate=245 |
| 243 | `baseline` | 246 | 1.5368e+02 | method=algebraic, source=imported, candidate=246 |
| 244 | `baseline` | 247 | 1.4420e+02 | method=algebraic, source=imported, candidate=247 |
| 245 | `baseline` | 248 | 1.4420e+02 | method=algebraic, source=imported, candidate=248 |
| 246 | `baseline` | 249 | 1.3880e+02 | method=algebraic, source=imported, candidate=249 |
| 247 | `baseline` | 250 | 1.3880e+02 | method=algebraic, source=imported, candidate=250 |
| 248 | `baseline` | 251 | 1.2647e+02 | method=algebraic, source=imported, candidate=251 |
| 249 | `baseline` | 252 | 1.2038e+02 | method=algebraic, source=imported, candidate=252 |
| 250 | `baseline` | 253 | 1.2038e+02 | method=algebraic, source=imported, candidate=253 |
| 251 | `baseline` | 254 | 1.1651e+02 | method=algebraic, source=imported, candidate=254 |
| 252 | `baseline` | 255 | 1.1651e+02 | method=algebraic, source=imported, candidate=255 |
| 253 | `baseline` | 256 | 1.1747e+02 | method=algebraic, source=imported, candidate=256 |
| 254 | `baseline` | 257 | 1.1432e+02 | method=algebraic, source=imported, candidate=257 |
| 255 | `baseline` | 258 | 1.1432e+02 | method=algebraic, source=imported, candidate=258 |
| 256 | `baseline` | 259 | 1.1492e+02 | method=algebraic, source=imported, candidate=259 |
| 257 | `baseline` | 260 | 1.1108e+02 | method=algebraic, source=imported, candidate=260 |
| 258 | `baseline` | 261 | 1.1108e+02 | method=algebraic, source=imported, candidate=261 |
| 259 | `baseline` | 262 | 1.1085e+02 | method=algebraic, source=imported, candidate=262 |
| 260 | `baseline` | 263 | 1.1085e+02 | method=algebraic, source=imported, candidate=263 |
| 261 | `baseline` | 264 | 1.0863e+02 | method=algebraic, source=imported, candidate=264 |
| 262 | `baseline` | 265 | 1.0863e+02 | method=algebraic, source=imported, candidate=265 |
| 263 | `baseline` | 266 | 1.1004e+02 | method=algebraic, source=imported, candidate=266 |
| 264 | `baseline` | 267 | 1.1004e+02 | method=algebraic, source=imported, candidate=267 |
| 265 | `baseline` | 268 | 1.0355e+02 | method=algebraic, source=imported, candidate=268 |
| 266 | `baseline` | 269 | 1.0355e+02 | method=algebraic, source=imported, candidate=269 |
| 267 | `baseline` | 270 | 9.1517e+01 | method=algebraic, source=imported, candidate=270 |
| 268 | `baseline` | 271 | 9.0363e+01 | method=algebraic, source=imported, candidate=271 |
| 269 | `baseline` | 272 | 7.7243e+01 | method=algebraic, source=imported, candidate=272 |
| 270 | `baseline` | 273 | 7.7243e+01 | method=algebraic, source=imported, candidate=273 |
| 271 | `baseline` | 274 | 7.6830e+01 | method=algebraic, source=imported, candidate=274 |
| 272 | `baseline` | 275 | 7.5479e+01 | method=algebraic, source=imported, candidate=275 |
| 273 | `baseline` | 276 | 7.2040e+01 | method=algebraic, source=imported, candidate=276 |
| 274 | `baseline` | 277 | 7.2040e+01 | method=algebraic, source=imported, candidate=277 |
| 275 | `baseline` | 278 | 6.9564e+01 | method=algebraic, source=imported, candidate=278 |
| 276 | `baseline` | 279 | 6.9564e+01 | method=algebraic, source=imported, candidate=279 |
| 277 | `baseline` | 280 | 6.7603e+01 | method=algebraic, source=imported, candidate=280 |
| 278 | `baseline` | 281 | 6.7603e+01 | method=algebraic, source=imported, candidate=281 |
| 279 | `baseline` | 282 | 6.9854e+01 | method=algebraic, source=imported, candidate=282 |
| 280 | `baseline` | 283 | 6.9854e+01 | method=algebraic, source=imported, candidate=283 |
| 281 | `baseline` | 284 | 6.5668e+01 | method=algebraic, source=imported, candidate=284 |
| 282 | `baseline` | 285 | 6.5668e+01 | method=algebraic, source=imported, candidate=285 |
| 283 | `baseline` | 286 | 6.2167e+01 | method=algebraic, source=imported, candidate=286 |
| 284 | `baseline` | 287 | 6.2146e+01 | method=algebraic, source=imported, candidate=287 |
| 285 | `baseline` | 288 | 6.2753e+01 | method=algebraic, source=imported, candidate=288 |
| 286 | `baseline` | 289 | 6.2753e+01 | method=algebraic, source=imported, candidate=289 |
| 287 | `baseline` | 290 | 5.8289e+01 | method=algebraic, source=imported, candidate=290 |
| 288 | `baseline` | 291 | 5.6793e+01 | method=algebraic, source=imported, candidate=291 |
| 289 | `baseline` | 292 | 5.6793e+01 | method=algebraic, source=imported, candidate=292 |
| 290 | `baseline` | 293 | 5.3233e+01 | method=algebraic, source=imported, candidate=293 |
| 291 | `baseline` | 294 | 5.3220e+01 | method=algebraic, source=imported, candidate=294 |
| 292 | `baseline` | 295 | 5.2339e+01 | method=algebraic, source=imported, candidate=295 |
| 293 | `baseline` | 296 | 5.2339e+01 | method=algebraic, source=imported, candidate=296 |
| 294 | `baseline` | 297 | 4.6701e+01 | method=algebraic, source=imported, candidate=297 |
| 295 | `baseline` | 298 | 4.6701e+01 | method=algebraic, source=imported, candidate=298 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.1133 | 5.2075e+04 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.2337 | 8.4887e+03 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.3185 | 4.0246e+04 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.3255 | 4.0158e+04 | method=direct_opt, source=assembled |
| 7 | `block` | 7 | 0.3257 | 4.0302e+04 | method=direct_opt, source=assembled |
| 9 | `block` | 9 | 0.3461 | 4.0321e+04 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.3508 | 4.0308e+04 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.4128 | 6.7229e+04 | method=direct_opt, source=assembled |
| 12 | `block` | 12 | 0.5716 | 7.4130e+07 | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.7000 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 0.7242 | 6.8808e+07 | method=direct_opt, source=assembled |
| 17 | `block` | 17 | 0.8106 | 3.2181e+09 | method=direct_opt, source=assembled |
| 19 | `block` | 19 | 0.8843 | Inf | method=direct_opt, source=assembled |
| 1 | `branch` | 1 | 0.6871 | 6.2753e+01 | method=direct_opt, source=synthesized, candidate=289, polished=true |
| 2 | `branch` | 2 | 0.6782 | 4.2398e+01 | method=direct_opt, source=synthesized, candidate=288, polished=true |
| 3 | `branch` | 3 | 0.6754 | 4.2530e+01 | method=direct_opt, source=synthesized, candidate=278, polished=true |
| 4 | `branch` | 4 | 0.6737 | 5.2339e+01 | method=algebraic, source=imported, candidate=296 |
| 5 | `branch` | 5 | 0.6723 | 1.1432e+02 | method=algebraic, source=imported, candidate=257 |
| 6 | `branch` | 6 | 0.6712 | 6.5668e+01 | method=algebraic, source=imported, candidate=285 |
| 7 | `branch` | 7 | 0.6632 | 6.9854e+01 | method=algebraic, source=imported, candidate=282 |
| 8 | `branch` | 8 | 0.6534 | 1.1432e+02 | method=algebraic, source=imported, candidate=258 |
| 9 | `branch` | 9 | 0.6521 | 5.2339e+01 | method=algebraic, source=imported, candidate=295 |
| 10 | `branch` | 10 | 0.6495 | 6.9564e+01 | method=algebraic, source=imported, candidate=279 |
| 11 | `branch` | 11 | 0.6468 | 6.5668e+01 | method=algebraic, source=imported, candidate=284 |
| 12 | `branch` | 12 | 0.6452 | 6.9854e+01 | method=algebraic, source=imported, candidate=283 |
| 13 | `branch` | 13 | 0.6424 | 7.6830e+01 | method=algebraic, source=imported, candidate=274 |
| 14 | `branch` | 14 | 0.6393 | 6.2146e+01 | method=algebraic, source=imported, candidate=287 |
| 15 | `branch` | 15 | 0.6371 | 9.0363e+01 | method=algebraic, source=imported, candidate=271 |
| 16 | `branch` | 16 | 0.6355 | 9.1517e+01 | method=algebraic, source=imported, candidate=270 |
| 17 | `branch` | 17 | 0.6345 | 1.1492e+02 | method=algebraic, source=imported, candidate=259 |
| 18 | `branch` | 18 | 0.6340 | 1.4420e+02 | method=algebraic, source=imported, candidate=248 |
| 19 | `branch` | 19 | 0.6331 | 6.7603e+01 | method=algebraic, source=imported, candidate=280 |
| 20 | `branch` | 20 | 0.6327 | 1.9272e+02 | method=algebraic, source=imported, candidate=242 |
| 21 | `branch` | 21 | 0.6316 | 6.7603e+01 | method=algebraic, source=imported, candidate=281 |
| 22 | `branch` | 22 | 0.6306 | 1.9815e+02 | method=algebraic, source=imported, candidate=241 |
| 23 | `branch` | 23 | 0.6244 | 1.2647e+02 | method=algebraic, source=imported, candidate=251 |
| 24 | `branch` | 24 | 0.6222 | 1.2038e+02 | method=algebraic, source=imported, candidate=253 |
| 25 | `branch` | 25 | 0.6206 | 5.8289e+01 | method=algebraic, source=imported, candidate=290 |
| 26 | `branch` | 26 | 0.6194 | 4.8426e+02 | method=algebraic, source=imported, candidate=206 |
| 27 | `branch` | 27 | 0.6192 | 7.5479e+01 | method=algebraic, source=imported, candidate=275 |
| 28 | `branch` | 28 | 0.6179 | 5.3233e+01 | method=algebraic, source=imported, candidate=293 |
| 29 | `branch` | 29 | 0.6178 | 1.4420e+02 | method=algebraic, source=imported, candidate=247 |
| 30 | `branch` | 30 | 0.6170 | 2.8808e+02 | method=algebraic, source=imported, candidate=228 |
| 31 | `branch` | 31 | 0.6161 | 5.3220e+01 | method=algebraic, source=imported, candidate=294 |
| 32 | `branch` | 32 | 0.6153 | 6.2167e+01 | method=algebraic, source=imported, candidate=286 |
| 33 | `branch` | 33 | 0.6116 | 4.4630e+02 | method=algebraic, source=imported, candidate=212 |
| 34 | `branch` | 34 | 0.6056 | 4.6701e+01 | method=algebraic, source=imported, candidate=298 |
| 35 | `branch` | 35 | 0.6044 | 1.1747e+02 | method=algebraic, source=imported, candidate=256 |
| 36 | `branch` | 36 | 0.6041 | 1.5368e+02 | method=algebraic, source=imported, candidate=246 |
| 37 | `branch` | 37 | 0.6018 | 7.0820e+02 | method=algebraic, source=imported, candidate=187 |
| 38 | `branch` | 38 | 0.6001 | 3.5785e+02 | method=algebraic, source=imported, candidate=224 |
| 39 | `branch` | 39 | 0.6001 | 4.6701e+01 | method=algebraic, source=imported, candidate=297 |
| 40 | `branch` | 40 | 0.5979 | 3.6898e+02 | method=algebraic, source=imported, candidate=222 |
| 41 | `branch` | 41 | 0.5963 | 3.4043e+02 | method=algebraic, source=imported, candidate=230 |
| 42 | `branch` | 42 | 0.5956 | 4.8426e+02 | method=algebraic, source=imported, candidate=207 |
| 43 | `branch` | 43 | 0.5938 | 5.6793e+01 | method=algebraic, source=imported, candidate=292 |
| 44 | `branch` | 44 | 0.5922 | 1.5390e+02 | method=algebraic, source=imported, candidate=245 |
| 45 | `branch` | 45 | 0.5911 | 2.9161e+02 | method=algebraic, source=imported, candidate=233 |
| 46 | `branch` | 46 | 0.5910 | 1.2038e+02 | method=algebraic, source=imported, candidate=252 |
| 47 | `branch` | 47 | 0.5874 | 7.2040e+01 | method=algebraic, source=imported, candidate=276 |
| 48 | `branch` | 48 | 0.5854 | 5.6793e+01 | method=algebraic, source=imported, candidate=291 |
| 49 | `branch` | 49 | 0.5847 | 2.2958e+02 | method=algebraic, source=imported, candidate=238 |
| 50 | `branch` | 50 | 0.5821 | 7.2040e+01 | method=algebraic, source=imported, candidate=277 |
| 51 | `branch` | 51 | 0.5819 | 2.8808e+02 | method=algebraic, source=imported, candidate=227 |
| 52 | `branch` | 52 | 0.5807 | 1.0010e+03 | method=algebraic, source=imported, candidate=179 |
| 53 | `branch` | 53 | 0.5783 | 7.0820e+02 | method=algebraic, source=imported, candidate=186 |
| 54 | `branch` | 54 | 0.5782 | 3.4391e+02 | method=algebraic, source=imported, candidate=229 |
| 55 | `branch` | 55 | 0.5770 | 3.5580e+02 | method=algebraic, source=imported, candidate=226 |
| 56 | `branch` | 56 | 0.5757 | 3.5785e+02 | method=algebraic, source=imported, candidate=225 |
| 57 | `branch` | 57 | 0.5756 | 1.3841e+03 | method=algebraic, source=imported, candidate=174 |
| 58 | `branch` | 58 | 0.5741 | 1.3967e+03 | method=algebraic, source=imported, candidate=173 |
| 59 | `branch` | 59 | 0.5736 | 3.6898e+02 | method=algebraic, source=imported, candidate=223 |
| 60 | `branch` | 60 | 0.5734 | 2.1196e+03 | method=algebraic, source=imported, candidate=158 |
| 61 | `branch` | 61 | 0.5658 | 4.9052e+02 | method=algebraic, source=imported, candidate=204 |
| 62 | `branch` | 62 | 0.5648 | 4.8547e+02 | method=algebraic, source=imported, candidate=205 |
| 63 | `branch` | 63 | 0.5636 | 4.9185e+02 | method=algebraic, source=imported, candidate=201 |
| 64 | `branch` | 64 | 0.5626 | 1.0863e+02 | method=algebraic, source=imported, candidate=264 |
| 65 | `branch` | 65 | 0.5610 | 7.7243e+01 | method=algebraic, source=imported, candidate=273 |
| 66 | `branch` | 66 | 0.5588 | 1.7923e+03 | method=algebraic, source=imported, candidate=166 |
| 67 | `branch` | 67 | 0.5582 | 1.3970e+03 | method=algebraic, source=imported, candidate=171 |
| 68 | `branch` | 68 | 0.5582 | 1.1108e+02 | method=algebraic, source=imported, candidate=260 |
| 69 | `branch` | 69 | 0.5574 | 1.1651e+02 | method=algebraic, source=imported, candidate=254 |
| 70 | `branch` | 70 | 0.5561 | 1.0355e+02 | method=algebraic, source=imported, candidate=269 |
| 71 | `branch` | 71 | 0.5557 | 1.0010e+03 | method=algebraic, source=imported, candidate=178 |
| 72 | `branch` | 72 | 0.5557 | 2.4383e+02 | method=algebraic, source=imported, candidate=237 |
| 73 | `branch` | 73 | 0.5551 | 2.5253e+02 | method=algebraic, source=imported, candidate=236 |
| 74 | `branch` | 74 | 0.5551 | 1.0355e+02 | method=algebraic, source=imported, candidate=268 |
| 75 | `branch` | 75 | 0.5544 | 1.0863e+02 | method=algebraic, source=imported, candidate=265 |
| 76 | `branch` | 76 | 0.5543 | 1.1108e+02 | method=algebraic, source=imported, candidate=261 |
| 77 | `branch` | 77 | 0.5526 | 2.0281e+02 | method=algebraic, source=imported, candidate=240 |
| 78 | `branch` | 78 | 0.5524 | 4.2477e+02 | method=algebraic, source=imported, candidate=214 |
| 79 | `branch` | 79 | 0.5522 | 1.1651e+02 | method=algebraic, source=imported, candidate=255 |
| 80 | `branch` | 80 | 0.5515 | 4.5900e+03 | method=algebraic, source=imported, candidate=142 |
| 81 | `branch` | 81 | 0.5504 | 2.0690e+02 | method=algebraic, source=imported, candidate=239 |
| 82 | `branch` | 82 | 0.5503 | 1.3841e+03 | method=algebraic, source=imported, candidate=175 |
| 83 | `branch` | 83 | 0.5502 | 7.7243e+01 | method=algebraic, source=imported, candidate=272 |
| 84 | `branch` | 84 | 0.5492 | 3.8887e+03 | method=algebraic, source=imported, candidate=147 |
| 85 | `branch` | 85 | 0.5484 | 3.0706e+02 | method=algebraic, source=imported, candidate=232 |
| 86 | `branch` | 86 | 0.5478 | 4.9943e+02 | method=algebraic, source=imported, candidate=199 |
| 87 | `branch` | 87 | 0.5469 | 7.9976e+02 | method=algebraic, source=imported, candidate=184 |
| 89 | `branch` | 89 | 0.5456 | 2.1196e+03 | method=algebraic, source=imported, candidate=157 |
| 90 | `branch` | 90 | 0.5455 | 4.2477e+02 | method=algebraic, source=imported, candidate=213 |
| 91 | `branch` | 91 | 0.5452 | 4.9052e+02 | method=algebraic, source=imported, candidate=203 |
| 92 | `branch` | 92 | 0.5450 | 1.3970e+03 | method=algebraic, source=imported, candidate=170 |
| 93 | `branch` | 93 | 0.5449 | 1.2161e+03 | method=algebraic, source=imported, candidate=176 |
| 94 | `branch` | 94 | 0.5436 | 4.9185e+02 | method=algebraic, source=imported, candidate=202 |
| 95 | `branch` | 95 | 0.5429 | 1.7934e+02 | method=algebraic, source=imported, candidate=244 |
| 96 | `branch` | 96 | 0.5429 | 5.3472e+02 | method=algebraic, source=imported, candidate=193 |
| 97 | `branch` | 97 | 0.5425 | 1.9177e+03 | method=algebraic, source=imported, candidate=162 |
| 98 | `branch` | 98 | 0.5421 | 2.7749e+02 | method=algebraic, source=imported, candidate=235 |
| 99 | `branch` | 99 | 0.5419 | 3.0706e+02 | method=algebraic, source=imported, candidate=231 |
| 100 | `branch` | 100 | 0.5418 | 3.7639e+02 | method=algebraic, source=imported, candidate=221 |
| 101 | `branch` | 101 | 0.5399 | 1.7934e+02 | method=algebraic, source=imported, candidate=243 |
| 102 | `branch` | 102 | 0.5388 | 3.0077e+03 | method=algebraic, source=imported, candidate=152 |
| 103 | `branch` | 103 | 0.5381 | 7.9976e+02 | method=algebraic, source=imported, candidate=185 |
| 104 | `branch` | 104 | 0.5361 | 4.4946e+03 | method=algebraic, source=imported, candidate=145 |
| 105 | `branch` | 105 | 0.5361 | 3.8887e+03 | method=algebraic, source=imported, candidate=148 |
| 106 | `branch` | 106 | 0.5342 | 9.1848e+03 | method=algebraic, source=imported, candidate=127 |
| 107 | `branch` | 107 | 0.5334 | 1.3880e+02 | method=algebraic, source=imported, candidate=249 |
| 108 | `branch` | 108 | 0.5330 | 4.0415e+02 | method=algebraic, source=imported, candidate=219 |
| 109 | `branch` | 109 | 0.5328 | 2.7749e+02 | method=algebraic, source=imported, candidate=234 |
| 110 | `branch` | 110 | 0.5327 | 5.4610e+02 | method=algebraic, source=imported, candidate=190 |
| 111 | `branch` | 111 | 0.5314 | 4.5573e+02 | method=algebraic, source=imported, candidate=211 |
| 112 | `branch` | 112 | 0.5310 | 3.7639e+02 | method=algebraic, source=imported, candidate=220 |
| 113 | `branch` | 113 | 0.5306 | 1.3880e+02 | method=algebraic, source=imported, candidate=250 |
| 114 | `branch` | 114 | 0.5291 | 4.5900e+03 | method=algebraic, source=imported, candidate=143 |
| 115 | `branch` | 115 | 0.5286 | 5.3858e+02 | method=algebraic, source=imported, candidate=192 |
| 116 | `branch` | 116 | 0.5284 | 6.1046e+02 | method=algebraic, source=imported, candidate=188 |
| 117 | `branch` | 117 | 0.5280 | 1.7923e+03 | method=algebraic, source=imported, candidate=165 |
| 118 | `branch` | 118 | 0.5267 | 5.3934e+02 | method=algebraic, source=imported, candidate=191 |
| 119 | `branch` | 119 | 0.5255 | 1.5226e+03 | method=algebraic, source=imported, candidate=167 |
| 120 | `branch` | 120 | 0.5249 | 1.5123e+03 | method=algebraic, source=imported, candidate=168 |
| 121 | `branch` | 121 | 0.5246 | 4.6605e+03 | method=algebraic, source=imported, candidate=141 |
| 122 | `branch` | 122 | 0.5236 | 4.5945e+02 | method=algebraic, source=imported, candidate=210 |
| 123 | `branch` | 123 | 0.5226 | 9.8873e+02 | method=algebraic, source=imported, candidate=180 |
| 124 | `branch` | 124 | 0.5225 | 4.9943e+02 | method=algebraic, source=imported, candidate=200 |
| 125 | `branch` | 125 | 0.5205 | 2.6996e+04 | method=algebraic, source=imported, candidate=96 |
| 126 | `branch` | 126 | 0.5198 | 5.1306e+02 | method=algebraic, source=imported, candidate=196 |
| 127 | `branch` | 127 | 0.5195 | 5.8884e+02 | method=algebraic, source=imported, candidate=189 |
| 128 | `branch` | 128 | 0.5195 | 1.9177e+03 | method=algebraic, source=imported, candidate=161 |
| 129 | `branch` | 129 | 0.5168 | 9.1848e+03 | method=algebraic, source=imported, candidate=128 |
| 130 | `branch` | 130 | 0.5145 | 4.7309e+02 | method=algebraic, source=imported, candidate=208 |
| 131 | `branch` | 131 | 0.5143 | 2.8417e+03 | method=algebraic, source=imported, candidate=156 |
| 132 | `branch` | 132 | 0.5142 | 1.5123e+03 | method=algebraic, source=imported, candidate=169 |
| 133 | `branch` | 133 | 0.5114 | 1.6313e+04 | method=algebraic, source=imported, candidate=115 |
| 134 | `branch` | 134 | 0.5093 | 2.6996e+04 | method=algebraic, source=imported, candidate=97 |
| 135 | `branch` | 135 | 0.5092 | 5.3219e+02 | method=algebraic, source=imported, candidate=194 |
| 136 | `branch` | 136 | 0.5089 | 2.8417e+03 | method=algebraic, source=imported, candidate=155 |
| 137 | `branch` | 137 | 0.5068 | 1.0612e+03 | method=algebraic, source=imported, candidate=177 |
| 138 | `branch` | 138 | 0.5067 | 4.4946e+03 | method=algebraic, source=imported, candidate=144 |
| 139 | `branch` | 139 | 0.5057 | 1.6313e+04 | method=algebraic, source=imported, candidate=116 |
| 140 | `branch` | 140 | 0.5052 | 5.0579e+02 | method=algebraic, source=imported, candidate=198 |
| 141 | `branch` | 141 | 0.5049 | 3.5088e+04 | method=algebraic, source=imported, candidate=79 |
| 142 | `branch` | 142 | 0.5034 | 4.3390e+03 | method=algebraic, source=imported, candidate=146 |
| 143 | `branch` | 143 | 0.5025 | 3.5088e+04 | method=algebraic, source=imported, candidate=78 |
| 144 | `branch` | 144 | 0.5007 | 5.0654e+02 | method=algebraic, source=imported, candidate=197 |
| 145 | `branch` | 145 | 0.5005 | 4.6783e+02 | method=algebraic, source=imported, candidate=209 |
| 146 | `branch` | 146 | 0.4997 | 5.2513e+02 | method=algebraic, source=imported, candidate=195 |
| 147 | `branch` | 147 | 0.4981 | 3.6015e+04 | method=algebraic, source=imported, candidate=67 |
| 148 | `branch` | 148 | 0.4977 | 3.0077e+03 | method=algebraic, source=imported, candidate=151 |
| 149 | `branch` | 149 | 0.4973 | 3.6015e+04 | method=algebraic, source=imported, candidate=68 |
| 150 | `branch` | 150 | 0.4884 | 4.1715e+02 | method=algebraic, source=imported, candidate=218 |
| 151 | `branch` | 151 | 0.4881 | 8.9082e+02 | method=algebraic, source=imported, candidate=183 |
| 152 | `branch` | 152 | 0.4880 | 3.4009e+03 | method=algebraic, source=imported, candidate=150 |
| 153 | `branch` | 153 | 0.4860 | 3.4009e+03 | method=algebraic, source=imported, candidate=149 |
| 154 | `branch` | 154 | 0.4856 | 4.1918e+02 | method=algebraic, source=imported, candidate=215 |
| 155 | `branch` | 155 | 0.4832 | 5.5309e+03 | method=algebraic, source=imported, candidate=133 |
| 156 | `branch` | 156 | 0.4826 | 4.8991e+03 | method=algebraic, source=imported, candidate=136 |
| 157 | `branch` | 157 | 0.4809 | 5.1958e+03 | method=algebraic, source=imported, candidate=135 |
| 158 | `branch` | 158 | 0.4789 | 5.1958e+03 | method=algebraic, source=imported, candidate=134 |
| 159 | `branch` | 159 | 0.4781 | 4.1787e+02 | method=algebraic, source=imported, candidate=216 |
| 160 | `branch` | 160 | 0.4776 | 4.1786e+02 | method=algebraic, source=imported, candidate=217 |
| 161 | `branch` | 161 | 0.4772 | 5.5309e+03 | method=algebraic, source=imported, candidate=132 |
| 162 | `branch` | 162 | 0.4761 | 1.7926e+03 | method=algebraic, source=imported, candidate=163 |
| 163 | `branch` | 163 | 0.4757 | 1.7574e+04 | method=algebraic, source=imported, candidate=113 |
| 164 | `branch` | 164 | 0.4750 | 3.4930e+04 | method=algebraic, source=imported, candidate=83 |
| 165 | `branch` | 165 | 0.4722 | 1.9891e+03 | method=algebraic, source=imported, candidate=159 |
| 166 | `branch` | 166 | 0.4720 | 2.1166e+04 | method=algebraic, source=imported, candidate=110 |
| 167 | `branch` | 167 | 0.4718 | 9.3026e+02 | method=algebraic, source=imported, candidate=181 |
| 168 | `branch` | 168 | 0.4713 | 1.7926e+03 | method=algebraic, source=imported, candidate=164 |
| 169 | `branch` | 169 | 0.4671 | 9.3026e+02 | method=algebraic, source=imported, candidate=182 |
| 170 | `branch` | 170 | 0.4669 | 1.3469e+04 | method=algebraic, source=imported, candidate=121 |
| 171 | `branch` | 171 | 0.4664 | 1.3817e+04 | method=algebraic, source=imported, candidate=119 |
| 172 | `branch` | 172 | 0.4660 | 2.3539e+04 | method=algebraic, source=imported, candidate=107 |
| 173 | `branch` | 173 | 0.4622 | 2.5174e+04 | method=algebraic, source=imported, candidate=101 |
| 174 | `branch` | 174 | 0.4621 | 4.1049e+04 | method=algebraic, source=imported, candidate=36 |
| 175 | `branch` | 175 | 0.4478 | 3.4930e+04 | method=algebraic, source=imported, candidate=84 |
| 176 | `branch` | 176 | 0.4454 | 3.5691e+04 | method=algebraic, source=imported, candidate=70 |
| 177 | `branch` | 177 | 0.4453 | 2.4777e+04 | method=algebraic, source=imported, candidate=103 |
| 178 | `branch` | 178 | 0.4419 | 1.3469e+04 | method=algebraic, source=imported, candidate=120 |
| 179 | `branch` | 179 | 0.4415 | 1.5781e+04 | method=algebraic, source=imported, candidate=117 |
| 180 | `branch` | 180 | 0.4410 | 3.5032e+04 | method=algebraic, source=imported, candidate=80 |
| 181 | `branch` | 181 | 0.4399 | 3.5490e+04 | method=algebraic, source=imported, candidate=74 |
| 183 | `branch` | 183 | 0.4383 | 3.5212e+04 | method=algebraic, source=imported, candidate=77 |
| 184 | `branch` | 184 | 0.4381 | 3.5691e+04 | method=algebraic, source=imported, candidate=71 |
| 185 | `branch` | 185 | 0.4381 | 3.3015e+04 | method=algebraic, source=imported, candidate=87 |
| 186 | `branch` | 186 | 0.4375 | 2.4777e+04 | method=algebraic, source=imported, candidate=102 |
| 187 | `branch` | 187 | 0.4367 | 1.9891e+03 | method=algebraic, source=imported, candidate=160 |
| 188 | `branch` | 188 | 0.4363 | 9.8485e+04 | method=algebraic, source=imported, candidate=17 |
| 189 | `branch` | 189 | 0.4343 | 2.3539e+04 | method=algebraic, source=imported, candidate=106 |
| 190 | `branch` | 190 | 0.4340 | 1.2754e+04 | method=algebraic, source=imported, candidate=122 |
| 191 | `branch` | 191 | 0.4337 | 4.1049e+04 | method=algebraic, source=imported, candidate=35 |
| 192 | `branch` | 192 | 0.4335 | 1.1004e+02 | method=algebraic, source=imported, candidate=267 |
| 193 | `branch` | 193 | 0.4333 | 3.2624e+04 | method=algebraic, source=imported, candidate=88 |
| 194 | `branch` | 194 | 0.4323 | 2.9870e+04 | method=algebraic, source=imported, candidate=92 |
| 195 | `branch` | 195 | 0.4312 | 1.1085e+02 | method=algebraic, source=imported, candidate=263 |
| 196 | `branch` | 196 | 0.4311 | 1.2754e+04 | method=algebraic, source=imported, candidate=123 |
| 197 | `branch` | 197 | 0.4309 | 2.9870e+04 | method=algebraic, source=imported, candidate=91 |
| 198 | `branch` | 198 | 0.4305 | 1.1704e+03 | method=algebraic, source=imported, candidate=131 |
| 199 | `branch` | 199 | 0.4305 | 2.5174e+04 | method=algebraic, source=imported, candidate=100 |
| 200 | `branch` | 200 | 0.4303 | 5.2785e+04 | method=algebraic, source=imported, candidate=26 |
| 201 | `branch` | 201 | 0.4300 | 1.1004e+02 | method=algebraic, source=imported, candidate=266 |
| 202 | `branch` | 202 | 0.4299 | 2.1929e+04 | method=algebraic, source=imported, candidate=109 |
| 203 | `branch` | 203 | 0.4277 | 1.1085e+02 | method=algebraic, source=imported, candidate=262 |
| 204 | `branch` | 204 | 0.4244 | 2.1929e+04 | method=algebraic, source=imported, candidate=108 |
| 205 | `branch` | 205 | 0.4235 | 9.8485e+04 | method=algebraic, source=imported, candidate=16 |
| 206 | `branch` | 206 | 0.4222 | 3.3257e+04 | method=algebraic, source=imported, candidate=86 |
| 207 | `branch` | 207 | 0.4211 | 1.5781e+04 | method=algebraic, source=imported, candidate=118 |
| 208 | `branch` | 208 | 0.4201 | 3.3257e+04 | method=algebraic, source=imported, candidate=85 |
| 209 | `branch` | 209 | 0.4195 | 3.5288e+04 | method=algebraic, source=imported, candidate=76 |
| 210 | `branch` | 210 | 0.4191 | 3.4984e+04 | method=algebraic, source=imported, candidate=82 |
| 211 | `branch` | 211 | 0.4191 | 1.4401e+06 | method=algebraic, source=imported, candidate=8 |
| 212 | `branch` | 212 | 0.4185 | 1.8277e+06 | method=algebraic, source=imported, candidate=3 |
| 214 | `branch` | 214 | 0.4163 | 1.1407e+05 | method=algebraic, source=imported, candidate=14 |
| 215 | `branch` | 215 | 0.4159 | 1.1407e+05 | method=algebraic, source=imported, candidate=15 |
| 216 | `branch` | 216 | 0.4158 | 3.5821e+04 | method=algebraic, source=imported, candidate=72 |
| 217 | `branch` | 217 | 0.4156 | 3.4984e+04 | method=algebraic, source=imported, candidate=81 |
| 218 | `branch` | 218 | 0.4135 | 3.5979e+04 | method=algebraic, source=imported, candidate=69 |
| 219 | `branch` | 219 | 0.4117 | 1.4401e+06 | method=algebraic, source=imported, candidate=7 |
| 220 | `branch` | 220 | 0.4102 | 6.3183e+04 | method=algebraic, source=imported, candidate=18 |
| 221 | `branch` | 221 | 0.4097 | 2.8944e+03 | method=algebraic, source=imported, candidate=154 |
| 222 | `branch` | 222 | 0.4097 | 5.2785e+04 | method=algebraic, source=imported, candidate=25 |
| 223 | `branch` | 223 | 0.4088 | 1.5368e+06 | method=algebraic, source=imported, candidate=5 |
| 224 | `branch` | 224 | 0.4080 | 1.0039e+06 | method=algebraic, source=imported, candidate=10 |
| 225 | `branch` | 225 | 0.4067 | 2.8944e+03 | method=algebraic, source=imported, candidate=153 |
| 226 | `branch` | 226 | 0.4066 | 2.7965e+04 | method=algebraic, source=imported, candidate=94 |
| 227 | `branch` | 227 | 0.4065 | 1.5368e+06 | method=algebraic, source=imported, candidate=6 |
| 228 | `branch` | 228 | 0.4046 | 2.7965e+04 | method=algebraic, source=imported, candidate=93 |
| 229 | `branch` | 229 | 0.4039 | 4.7362e+03 | method=algebraic, source=imported, candidate=140 |
| 230 | `branch` | 230 | 0.4034 | 3.0151e+04 | method=algebraic, source=imported, candidate=90 |
| 231 | `branch` | 231 | 0.4005 | 1.8277e+06 | method=algebraic, source=imported, candidate=4 |
| 232 | `branch` | 232 | 0.4002 | 1.7627e+04 | method=algebraic, source=imported, candidate=112 |
| 233 | `branch` | 233 | 0.3995 | 3.5533e+03 | method=algebraic, source=imported, candidate=126 |
| 234 | `branch` | 234 | 0.3983 | 8.6819e+03 | method=algebraic, source=imported, candidate=129 |
| 235 | `branch` | 235 | 0.3970 | 2.2358e+05 | method=algebraic, source=imported, candidate=11 |
| 236 | `branch` | 236 | 0.3965 | 3.0151e+04 | method=algebraic, source=imported, candidate=89 |
| 237 | `branch` | 237 | 0.3935 | 8.6819e+03 | method=algebraic, source=imported, candidate=130 |
| 238 | `branch` | 238 | 0.3908 | 1.7627e+04 | method=algebraic, source=imported, candidate=111 |
| 239 | `branch` | 239 | 0.3905 | 1.2546e+04 | method=algebraic, source=imported, candidate=124 |
| 240 | `branch` | 240 | 0.3905 | 2.0853e+06 | method=algebraic, source=imported, candidate=2 |
| 241 | `branch` | 241 | 0.3901 | 4.7362e+03 | method=algebraic, source=imported, candidate=139 |
| 242 | `branch` | 242 | 0.3880 | 2.3604e+04 | method=algebraic, source=imported, candidate=105 |
| 243 | `branch` | 243 | 0.3827 | 4.6880e+03 | method=algebraic, source=imported, candidate=138 |
| 244 | `branch` | 244 | 0.3812 | 2.3604e+04 | method=algebraic, source=imported, candidate=104 |
| 245 | `branch` | 245 | 0.3773 | 1.2517e+04 | method=algebraic, source=imported, candidate=125 |
| 246 | `branch` | 246 | 0.3768 | 4.6880e+03 | method=algebraic, source=imported, candidate=137 |
| 247 | `branch` | 247 | 0.3742 | 3.6492e+04 | method=algebraic, source=imported, candidate=62 |
| 248 | `branch` | 248 | 0.3738 | 1.0039e+06 | method=algebraic, source=imported, candidate=9 |
| 249 | `branch` | 249 | 0.3723 | 3.6492e+04 | method=algebraic, source=imported, candidate=61 |
| 250 | `branch` | 250 | 0.3711 | 3.9137e+04 | method=algebraic, source=imported, candidate=49 |
| 251 | `branch` | 251 | 0.3702 | 3.9137e+04 | method=algebraic, source=imported, candidate=50 |
| 252 | `branch` | 252 | 0.3693 | 3.7791e+04 | method=algebraic, source=imported, candidate=56 |
| 253 | `branch` | 253 | 0.3676 | 3.7701e+04 | method=algebraic, source=imported, candidate=58 |
| 254 | `branch` | 254 | 0.3648 | 3.7791e+04 | method=algebraic, source=imported, candidate=55 |
| 255 | `branch` | 255 | 0.3635 | 3.6128e+04 | method=algebraic, source=imported, candidate=64 |
| 256 | `branch` | 256 | 0.3605 | 3.6128e+04 | method=algebraic, source=imported, candidate=63 |
| 257 | `branch` | 257 | 0.3601 | 3.7701e+04 | method=algebraic, source=imported, candidate=57 |
| 258 | `branch` | 258 | 0.3589 | 3.6075e+04 | method=algebraic, source=imported, candidate=66 |
| 259 | `branch` | 259 | 0.3567 | 2.5258e+04 | method=algebraic, source=imported, candidate=99 |
| 260 | `branch` | 260 | 0.3567 | 3.8433e+04 | method=algebraic, source=imported, candidate=54 |
| 261 | `branch` | 261 | 0.3563 | 1.7022e+04 | method=algebraic, source=imported, candidate=114 |
| 262 | `branch` | 262 | 0.3562 | 2.5955e+04 | method=algebraic, source=imported, candidate=98 |
| 263 | `branch` | 263 | 0.3562 | 3.8433e+04 | method=algebraic, source=imported, candidate=53 |
| 264 | `branch` | 264 | 0.3559 | 3.6075e+04 | method=algebraic, source=imported, candidate=65 |
| 265 | `branch` | 265 | 0.3337 | 2.7570e+04 | method=algebraic, source=imported, candidate=95 |
| 266 | `branch` | 266 | 0.3179 | 3.8538e+04 | method=algebraic, source=imported, candidate=51 |
| 267 | `branch` | 267 | 0.3102 | 5.8657e+04 | method=algebraic, source=imported, candidate=20 |
| 268 | `branch` | 268 | 0.3100 | 5.6225e+04 | method=algebraic, source=imported, candidate=24 |
| 269 | `branch` | 269 | 0.3082 | 4.1451e+04 | method=algebraic, source=imported, candidate=31 |
| 270 | `branch` | 270 | 0.3060 | 4.4604e+04 | method=algebraic, source=imported, candidate=29 |
| 271 | `branch` | 271 | 0.3005 | 3.6719e+04 | method=algebraic, source=imported, candidate=60 |
| 272 | `branch` | 272 | 0.2995 | 1.7505e+05 | method=algebraic, source=imported, candidate=12 |
| 273 | `branch` | 273 | 0.2986 | 3.9856e+04 | method=algebraic, source=imported, candidate=48 |
| 274 | `branch` | 274 | 0.2979 | 3.8538e+04 | method=algebraic, source=imported, candidate=52 |
| 275 | `branch` | 275 | 0.2970 | 5.8657e+04 | method=algebraic, source=imported, candidate=19 |
| 276 | `branch` | 276 | 0.2956 | 5.6225e+04 | method=algebraic, source=imported, candidate=23 |
| 277 | `branch` | 277 | 0.2955 | 4.1451e+04 | method=algebraic, source=imported, candidate=32 |
| 278 | `branch` | 278 | 0.2955 | 3.9856e+04 | method=algebraic, source=imported, candidate=47 |
| 279 | `branch` | 279 | 0.2926 | 3.6740e+04 | method=algebraic, source=imported, candidate=59 |
| 280 | `branch` | 280 | 0.2922 | 4.0217e+04 | method=algebraic, source=imported, candidate=44 |
| 281 | `branch` | 281 | 0.2904 | 4.0204e+04 | method=algebraic, source=imported, candidate=45 |
| 282 | `branch` | 282 | 0.2902 | 4.0217e+04 | method=algebraic, source=imported, candidate=43 |
| 283 | `branch` | 283 | 0.2880 | 4.4604e+04 | method=algebraic, source=imported, candidate=30 |
| 284 | `branch` | 284 | 0.2871 | 4.0204e+04 | method=algebraic, source=imported, candidate=46 |
| 285 | `branch` | 285 | 0.2850 | 4.0228e+04 | method=algebraic, source=imported, candidate=41 |
| 286 | `branch` | 286 | 0.2835 | 1.7505e+05 | method=algebraic, source=imported, candidate=13 |
| 287 | `branch` | 287 | 0.2827 | 4.0228e+04 | method=algebraic, source=imported, candidate=42 |
| 288 | `branch` | 288 | 0.2810 | 4.0308e+04 | method=algebraic, source=imported, candidate=39 |
| 289 | `branch` | 289 | 0.2785 | 4.0317e+04 | method=algebraic, source=imported, candidate=37 |
| 290 | `branch` | 290 | 0.2771 | 4.1397e+04 | method=algebraic, source=imported, candidate=33 |
| 291 | `branch` | 291 | 0.2765 | 6.9689e+06 | method=algebraic, source=imported, candidate=1 |
| 292 | `branch` | 292 | 0.2743 | 4.1397e+04 | method=algebraic, source=imported, candidate=34 |
| 293 | `branch` | 293 | 0.2731 | 5.6873e+04 | method=algebraic, source=imported, candidate=22 |
| 294 | `branch` | 294 | 0.2731 | 5.6873e+04 | method=algebraic, source=imported, candidate=21 |
| 295 | `branch` | 295 | 0.2685 | 4.4985e+04 | method=algebraic, source=imported, candidate=28 |
| 296 | `branch` | 296 | 0.2670 | 4.4985e+04 | method=algebraic, source=imported, candidate=27 |
| 297 | `branch` | 297 | 0.2501 | Inf | method=algebraic, source=imported, candidate=40 |
| 298 | `branch` | 298 | 0.2498 | Inf | method=algebraic, source=imported, candidate=38 |
| 1 | `synthesized` | 1 | 42.3899 | 4.2390e+01 | method=direct_opt, source=synthesized, polished=true |
| 2 | `synthesized` | 3 | 42.3325 | 4.2332e+01 | method=direct_opt, source=synthesized, polished=true |
| 4 | `synthesized` | 4 | 42.4749 | 4.2475e+01 | method=direct_opt, source=synthesized, polished=true |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `branch` | `duplicate` | 6.2753e+01 | method=direct_opt, source=synthesized, candidate=289, polished=true |
| 2 | `branch` | `duplicate` | 5.2339e+01 | method=algebraic, source=imported, candidate=296 |
| 3 | `branch` | `duplicate` | 1.1432e+02 | method=algebraic, source=imported, candidate=257 |
| 4 | `branch` | `duplicate` | 6.5668e+01 | method=algebraic, source=imported, candidate=285 |
| 5 | `branch` | `duplicate` | 6.9854e+01 | method=algebraic, source=imported, candidate=282 |
| 6 | `branch` | `duplicate` | 1.1432e+02 | method=algebraic, source=imported, candidate=258 |
| 7 | `branch` | `duplicate` | 5.2339e+01 | method=algebraic, source=imported, candidate=295 |
| 8 | `branch` | `duplicate` | 6.9564e+01 | method=algebraic, source=imported, candidate=279 |
| 9 | `branch` | `duplicate` | 6.5668e+01 | method=algebraic, source=imported, candidate=284 |
| 10 | `branch` | `duplicate` | 6.9854e+01 | method=algebraic, source=imported, candidate=283 |
| 11 | `branch` | `duplicate` | 7.6830e+01 | method=algebraic, source=imported, candidate=274 |
| 12 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 13 | `branch` | `duplicate` | 6.2146e+01 | method=algebraic, source=imported, candidate=287 |
| 14 | `branch` | `duplicate` | 9.0363e+01 | method=algebraic, source=imported, candidate=271 |
| 15 | `branch` | `duplicate` | 9.1517e+01 | method=algebraic, source=imported, candidate=270 |
| 16 | `block` | `catastrophic_fit` | 3.2181e+09 | method=direct_opt, source=assembled |
| 17 | `branch` | `duplicate` | 1.1492e+02 | method=algebraic, source=imported, candidate=259 |
| 18 | `branch` | `duplicate` | 1.4420e+02 | method=algebraic, source=imported, candidate=248 |
| 19 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 20 | `branch` | `duplicate` | 6.7603e+01 | method=algebraic, source=imported, candidate=280 |
| 21 | `branch` | `duplicate` | 1.9272e+02 | method=algebraic, source=imported, candidate=242 |
| 22 | `branch` | `duplicate` | 6.7603e+01 | method=algebraic, source=imported, candidate=281 |
| 23 | `branch` | `duplicate` | 1.9815e+02 | method=algebraic, source=imported, candidate=241 |
| 24 | `branch` | `duplicate` | 1.2647e+02 | method=algebraic, source=imported, candidate=251 |
| 25 | `branch` | `duplicate` | 1.2038e+02 | method=algebraic, source=imported, candidate=253 |
| 26 | `branch` | `duplicate` | 5.8289e+01 | method=algebraic, source=imported, candidate=290 |
| 27 | `branch` | `duplicate` | 4.8426e+02 | method=algebraic, source=imported, candidate=206 |
| 28 | `branch` | `duplicate` | 7.5479e+01 | method=algebraic, source=imported, candidate=275 |
| 29 | `branch` | `duplicate` | 5.3233e+01 | method=algebraic, source=imported, candidate=293 |
| 30 | `branch` | `duplicate` | 1.4420e+02 | method=algebraic, source=imported, candidate=247 |
| 31 | `branch` | `duplicate` | 2.8808e+02 | method=algebraic, source=imported, candidate=228 |
| 32 | `branch` | `duplicate` | 5.3220e+01 | method=algebraic, source=imported, candidate=294 |
| 33 | `branch` | `duplicate` | 6.2167e+01 | method=algebraic, source=imported, candidate=286 |
| 34 | `branch` | `duplicate` | 4.4630e+02 | method=algebraic, source=imported, candidate=212 |
| 35 | `branch` | `duplicate` | 4.6701e+01 | method=algebraic, source=imported, candidate=298 |
| 36 | `branch` | `duplicate` | 1.1747e+02 | method=algebraic, source=imported, candidate=256 |
| 37 | `branch` | `duplicate` | 1.5368e+02 | method=algebraic, source=imported, candidate=246 |
| 38 | `branch` | `duplicate` | 7.0820e+02 | method=algebraic, source=imported, candidate=187 |
| 39 | `branch` | `duplicate` | 3.5785e+02 | method=algebraic, source=imported, candidate=224 |
| 40 | `branch` | `duplicate` | 4.6701e+01 | method=algebraic, source=imported, candidate=297 |
| 41 | `branch` | `duplicate` | 3.6898e+02 | method=algebraic, source=imported, candidate=222 |
| 42 | `branch` | `duplicate` | 3.4043e+02 | method=algebraic, source=imported, candidate=230 |
| 43 | `branch` | `duplicate` | 4.8426e+02 | method=algebraic, source=imported, candidate=207 |
| 44 | `branch` | `duplicate` | 5.6793e+01 | method=algebraic, source=imported, candidate=292 |
| 45 | `branch` | `duplicate` | 1.5390e+02 | method=algebraic, source=imported, candidate=245 |
| 46 | `branch` | `duplicate` | 2.9161e+02 | method=algebraic, source=imported, candidate=233 |
| 47 | `branch` | `duplicate` | 1.2038e+02 | method=algebraic, source=imported, candidate=252 |
| 48 | `branch` | `duplicate` | 7.2040e+01 | method=algebraic, source=imported, candidate=276 |
| 49 | `branch` | `duplicate` | 5.6793e+01 | method=algebraic, source=imported, candidate=291 |
| 50 | `branch` | `duplicate` | 2.2958e+02 | method=algebraic, source=imported, candidate=238 |
| 51 | `branch` | `duplicate` | 7.2040e+01 | method=algebraic, source=imported, candidate=277 |
| 52 | `branch` | `duplicate` | 2.8808e+02 | method=algebraic, source=imported, candidate=227 |
| 53 | `branch` | `duplicate` | 1.0010e+03 | method=algebraic, source=imported, candidate=179 |
| 54 | `branch` | `duplicate` | 7.0820e+02 | method=algebraic, source=imported, candidate=186 |
| 55 | `branch` | `duplicate` | 3.4391e+02 | method=algebraic, source=imported, candidate=229 |
| 56 | `branch` | `duplicate` | 3.5580e+02 | method=algebraic, source=imported, candidate=226 |
| 57 | `branch` | `duplicate` | 3.5785e+02 | method=algebraic, source=imported, candidate=225 |
| 58 | `branch` | `duplicate` | 1.3841e+03 | method=algebraic, source=imported, candidate=174 |
| 59 | `branch` | `duplicate` | 1.3967e+03 | method=algebraic, source=imported, candidate=173 |
| 60 | `branch` | `duplicate` | 3.6898e+02 | method=algebraic, source=imported, candidate=223 |
| 61 | `branch` | `duplicate` | 2.1196e+03 | method=algebraic, source=imported, candidate=158 |
| 62 | `branch` | `duplicate` | 4.9052e+02 | method=algebraic, source=imported, candidate=204 |
| 63 | `branch` | `duplicate` | 4.8547e+02 | method=algebraic, source=imported, candidate=205 |
| 64 | `branch` | `duplicate` | 4.9185e+02 | method=algebraic, source=imported, candidate=201 |
| 65 | `branch` | `duplicate` | 1.0863e+02 | method=algebraic, source=imported, candidate=264 |
| 66 | `branch` | `duplicate` | 7.7243e+01 | method=algebraic, source=imported, candidate=273 |
| 67 | `branch` | `duplicate` | 1.7923e+03 | method=algebraic, source=imported, candidate=166 |
| 68 | `branch` | `duplicate` | 1.3970e+03 | method=algebraic, source=imported, candidate=171 |
| 69 | `branch` | `duplicate` | 1.1108e+02 | method=algebraic, source=imported, candidate=260 |
| 70 | `branch` | `duplicate` | 1.1651e+02 | method=algebraic, source=imported, candidate=254 |
| 71 | `branch` | `duplicate` | 1.0355e+02 | method=algebraic, source=imported, candidate=269 |
| 72 | `branch` | `duplicate` | 1.0010e+03 | method=algebraic, source=imported, candidate=178 |
| 73 | `branch` | `duplicate` | 2.4383e+02 | method=algebraic, source=imported, candidate=237 |
| 74 | `branch` | `duplicate` | 2.5253e+02 | method=algebraic, source=imported, candidate=236 |
| 75 | `branch` | `duplicate` | 1.0355e+02 | method=algebraic, source=imported, candidate=268 |
| 76 | `branch` | `duplicate` | 1.0863e+02 | method=algebraic, source=imported, candidate=265 |
| 77 | `branch` | `duplicate` | 1.1108e+02 | method=algebraic, source=imported, candidate=261 |
| 78 | `branch` | `duplicate` | 2.0281e+02 | method=algebraic, source=imported, candidate=240 |
| 79 | `branch` | `duplicate` | 4.2477e+02 | method=algebraic, source=imported, candidate=214 |
| 80 | `branch` | `duplicate` | 1.1651e+02 | method=algebraic, source=imported, candidate=255 |
| 81 | `branch` | `duplicate` | 4.5900e+03 | method=algebraic, source=imported, candidate=142 |
| 82 | `branch` | `duplicate` | 2.0690e+02 | method=algebraic, source=imported, candidate=239 |
| 83 | `branch` | `duplicate` | 1.3841e+03 | method=algebraic, source=imported, candidate=175 |
| 84 | `branch` | `duplicate` | 7.7243e+01 | method=algebraic, source=imported, candidate=272 |
| 85 | `branch` | `duplicate` | 3.8887e+03 | method=algebraic, source=imported, candidate=147 |
| 86 | `branch` | `duplicate` | 3.0706e+02 | method=algebraic, source=imported, candidate=232 |
| 87 | `branch` | `duplicate` | 4.9943e+02 | method=algebraic, source=imported, candidate=199 |
| 88 | `branch` | `duplicate` | 7.9976e+02 | method=algebraic, source=imported, candidate=184 |
| 89 | `branch` | `duplicate` | 2.1196e+03 | method=algebraic, source=imported, candidate=157 |
| 90 | `branch` | `duplicate` | 4.2477e+02 | method=algebraic, source=imported, candidate=213 |
| 91 | `branch` | `duplicate` | 4.9052e+02 | method=algebraic, source=imported, candidate=203 |
| 92 | `branch` | `duplicate` | 1.3970e+03 | method=algebraic, source=imported, candidate=170 |
| 93 | `branch` | `duplicate` | 1.2161e+03 | method=algebraic, source=imported, candidate=176 |
| 94 | `branch` | `duplicate` | 4.9185e+02 | method=algebraic, source=imported, candidate=202 |
| 95 | `branch` | `duplicate` | 1.7934e+02 | method=algebraic, source=imported, candidate=244 |
| 96 | `branch` | `duplicate` | 5.3472e+02 | method=algebraic, source=imported, candidate=193 |
| 97 | `branch` | `duplicate` | 1.9177e+03 | method=algebraic, source=imported, candidate=162 |
| 98 | `branch` | `duplicate` | 2.7749e+02 | method=algebraic, source=imported, candidate=235 |
| 99 | `branch` | `duplicate` | 3.0706e+02 | method=algebraic, source=imported, candidate=231 |
| 100 | `branch` | `duplicate` | 3.7639e+02 | method=algebraic, source=imported, candidate=221 |
| 101 | `branch` | `duplicate` | 1.7934e+02 | method=algebraic, source=imported, candidate=243 |
| 102 | `branch` | `duplicate` | 3.0077e+03 | method=algebraic, source=imported, candidate=152 |
| 103 | `branch` | `duplicate` | 7.9976e+02 | method=algebraic, source=imported, candidate=185 |
| 104 | `branch` | `duplicate` | 4.4946e+03 | method=algebraic, source=imported, candidate=145 |
| 105 | `branch` | `duplicate` | 3.8887e+03 | method=algebraic, source=imported, candidate=148 |
| 106 | `branch` | `duplicate` | 9.1848e+03 | method=algebraic, source=imported, candidate=127 |
| 107 | `branch` | `duplicate` | 1.3880e+02 | method=algebraic, source=imported, candidate=249 |
| 108 | `branch` | `duplicate` | 4.0415e+02 | method=algebraic, source=imported, candidate=219 |
| 109 | `branch` | `duplicate` | 2.7749e+02 | method=algebraic, source=imported, candidate=234 |
| 110 | `branch` | `duplicate` | 5.4610e+02 | method=algebraic, source=imported, candidate=190 |
| 111 | `branch` | `duplicate` | 4.5573e+02 | method=algebraic, source=imported, candidate=211 |
| 112 | `branch` | `duplicate` | 3.7639e+02 | method=algebraic, source=imported, candidate=220 |
| 113 | `branch` | `duplicate` | 1.3880e+02 | method=algebraic, source=imported, candidate=250 |
| 114 | `branch` | `duplicate` | 4.5900e+03 | method=algebraic, source=imported, candidate=143 |
| 115 | `branch` | `duplicate` | 5.3858e+02 | method=algebraic, source=imported, candidate=192 |
| 116 | `branch` | `duplicate` | 6.1046e+02 | method=algebraic, source=imported, candidate=188 |
| 117 | `branch` | `duplicate` | 1.7923e+03 | method=algebraic, source=imported, candidate=165 |
| 118 | `branch` | `duplicate` | 5.3934e+02 | method=algebraic, source=imported, candidate=191 |
| 119 | `branch` | `duplicate` | 1.5226e+03 | method=algebraic, source=imported, candidate=167 |
| 120 | `branch` | `duplicate` | 1.5123e+03 | method=algebraic, source=imported, candidate=168 |
| 121 | `branch` | `duplicate` | 4.6605e+03 | method=algebraic, source=imported, candidate=141 |
| 122 | `branch` | `duplicate` | 4.5945e+02 | method=algebraic, source=imported, candidate=210 |
| 123 | `branch` | `duplicate` | 9.8873e+02 | method=algebraic, source=imported, candidate=180 |
| 124 | `branch` | `duplicate` | 4.9943e+02 | method=algebraic, source=imported, candidate=200 |
| 125 | `branch` | `duplicate` | 2.6996e+04 | method=algebraic, source=imported, candidate=96 |
| 126 | `branch` | `duplicate` | 5.1306e+02 | method=algebraic, source=imported, candidate=196 |
| 127 | `branch` | `duplicate` | 5.8884e+02 | method=algebraic, source=imported, candidate=189 |
| 128 | `branch` | `duplicate` | 1.9177e+03 | method=algebraic, source=imported, candidate=161 |
| 129 | `branch` | `duplicate` | 9.1848e+03 | method=algebraic, source=imported, candidate=128 |
| 130 | `branch` | `duplicate` | 4.7309e+02 | method=algebraic, source=imported, candidate=208 |
| 131 | `branch` | `duplicate` | 2.8417e+03 | method=algebraic, source=imported, candidate=156 |
| 132 | `branch` | `duplicate` | 1.5123e+03 | method=algebraic, source=imported, candidate=169 |
| 133 | `branch` | `duplicate` | 1.6313e+04 | method=algebraic, source=imported, candidate=115 |
| 134 | `branch` | `duplicate` | 2.6996e+04 | method=algebraic, source=imported, candidate=97 |
| 135 | `branch` | `duplicate` | 5.3219e+02 | method=algebraic, source=imported, candidate=194 |
| 136 | `branch` | `duplicate` | 2.8417e+03 | method=algebraic, source=imported, candidate=155 |
| 137 | `branch` | `duplicate` | 1.0612e+03 | method=algebraic, source=imported, candidate=177 |
| 138 | `branch` | `duplicate` | 4.4946e+03 | method=algebraic, source=imported, candidate=144 |
| 139 | `branch` | `duplicate` | 1.6313e+04 | method=algebraic, source=imported, candidate=116 |
| 140 | `branch` | `duplicate` | 5.0579e+02 | method=algebraic, source=imported, candidate=198 |
| 141 | `branch` | `duplicate` | 3.5088e+04 | method=algebraic, source=imported, candidate=79 |
| 142 | `branch` | `duplicate` | 4.3390e+03 | method=algebraic, source=imported, candidate=146 |
| 143 | `branch` | `duplicate` | 3.5088e+04 | method=algebraic, source=imported, candidate=78 |
| 144 | `branch` | `duplicate` | 5.0654e+02 | method=algebraic, source=imported, candidate=197 |
| 145 | `branch` | `duplicate` | 4.6783e+02 | method=algebraic, source=imported, candidate=209 |
| 146 | `branch` | `duplicate` | 5.2513e+02 | method=algebraic, source=imported, candidate=195 |
| 147 | `branch` | `duplicate` | 3.6015e+04 | method=algebraic, source=imported, candidate=67 |
| 148 | `branch` | `duplicate` | 3.0077e+03 | method=algebraic, source=imported, candidate=151 |
| 149 | `branch` | `duplicate` | 3.6015e+04 | method=algebraic, source=imported, candidate=68 |
| 150 | `branch` | `duplicate` | 4.1715e+02 | method=algebraic, source=imported, candidate=218 |
| 151 | `branch` | `duplicate` | 8.9082e+02 | method=algebraic, source=imported, candidate=183 |
| 152 | `branch` | `duplicate` | 3.4009e+03 | method=algebraic, source=imported, candidate=150 |
| 153 | `branch` | `duplicate` | 3.4009e+03 | method=algebraic, source=imported, candidate=149 |
| 154 | `branch` | `duplicate` | 4.1918e+02 | method=algebraic, source=imported, candidate=215 |
| 155 | `branch` | `duplicate` | 5.5309e+03 | method=algebraic, source=imported, candidate=133 |
| 156 | `branch` | `duplicate` | 4.8991e+03 | method=algebraic, source=imported, candidate=136 |
| 157 | `branch` | `duplicate` | 5.1958e+03 | method=algebraic, source=imported, candidate=135 |
| 158 | `branch` | `duplicate` | 5.1958e+03 | method=algebraic, source=imported, candidate=134 |
| 159 | `branch` | `duplicate` | 4.1787e+02 | method=algebraic, source=imported, candidate=216 |
| 160 | `branch` | `duplicate` | 4.1786e+02 | method=algebraic, source=imported, candidate=217 |
| 161 | `branch` | `duplicate` | 5.5309e+03 | method=algebraic, source=imported, candidate=132 |
| 162 | `branch` | `duplicate` | 1.7926e+03 | method=algebraic, source=imported, candidate=163 |
| 163 | `branch` | `duplicate` | 1.7574e+04 | method=algebraic, source=imported, candidate=113 |
| 164 | `branch` | `duplicate` | 3.4930e+04 | method=algebraic, source=imported, candidate=83 |
| 165 | `branch` | `duplicate` | 1.9891e+03 | method=algebraic, source=imported, candidate=159 |
| 166 | `branch` | `duplicate` | 2.1166e+04 | method=algebraic, source=imported, candidate=110 |
| 167 | `branch` | `duplicate` | 9.3026e+02 | method=algebraic, source=imported, candidate=181 |
| 168 | `branch` | `duplicate` | 1.7926e+03 | method=algebraic, source=imported, candidate=164 |
| 169 | `branch` | `duplicate` | 9.3026e+02 | method=algebraic, source=imported, candidate=182 |
| 170 | `branch` | `duplicate` | 1.3469e+04 | method=algebraic, source=imported, candidate=121 |
| 171 | `branch` | `duplicate` | 1.3817e+04 | method=algebraic, source=imported, candidate=119 |
| 172 | `branch` | `duplicate` | 2.3539e+04 | method=algebraic, source=imported, candidate=107 |
| 173 | `branch` | `duplicate` | 2.5174e+04 | method=algebraic, source=imported, candidate=101 |
| 174 | `branch` | `duplicate` | 4.1049e+04 | method=algebraic, source=imported, candidate=36 |
| 175 | `branch` | `duplicate` | 3.4930e+04 | method=algebraic, source=imported, candidate=84 |
| 176 | `branch` | `duplicate` | 3.5691e+04 | method=algebraic, source=imported, candidate=70 |
| 177 | `branch` | `duplicate` | 2.4777e+04 | method=algebraic, source=imported, candidate=103 |
| 178 | `branch` | `duplicate` | 1.3469e+04 | method=algebraic, source=imported, candidate=120 |
| 179 | `branch` | `duplicate` | 1.5781e+04 | method=algebraic, source=imported, candidate=117 |
| 180 | `branch` | `duplicate` | 3.5032e+04 | method=algebraic, source=imported, candidate=80 |
| 181 | `branch` | `duplicate` | 3.5490e+04 | method=algebraic, source=imported, candidate=74 |
| 182 | `branch` | `duplicate` | 3.5212e+04 | method=algebraic, source=imported, candidate=77 |
| 183 | `branch` | `duplicate` | 3.5691e+04 | method=algebraic, source=imported, candidate=71 |
| 184 | `branch` | `duplicate` | 3.3015e+04 | method=algebraic, source=imported, candidate=87 |
| 185 | `branch` | `duplicate` | 2.4777e+04 | method=algebraic, source=imported, candidate=102 |
| 186 | `branch` | `duplicate` | 1.9891e+03 | method=algebraic, source=imported, candidate=160 |
| 187 | `branch` | `duplicate` | 9.8485e+04 | method=algebraic, source=imported, candidate=17 |
| 188 | `branch` | `duplicate` | 2.3539e+04 | method=algebraic, source=imported, candidate=106 |
| 189 | `branch` | `duplicate` | 1.2754e+04 | method=algebraic, source=imported, candidate=122 |
| 190 | `branch` | `duplicate` | 4.1049e+04 | method=algebraic, source=imported, candidate=35 |
| 191 | `branch` | `duplicate` | 1.1004e+02 | method=algebraic, source=imported, candidate=267 |
| 192 | `branch` | `duplicate` | 3.2624e+04 | method=algebraic, source=imported, candidate=88 |
| 193 | `branch` | `duplicate` | 2.9870e+04 | method=algebraic, source=imported, candidate=92 |
| 194 | `branch` | `duplicate` | 1.1085e+02 | method=algebraic, source=imported, candidate=263 |
| 195 | `branch` | `duplicate` | 1.2754e+04 | method=algebraic, source=imported, candidate=123 |
| 196 | `branch` | `duplicate` | 2.9870e+04 | method=algebraic, source=imported, candidate=91 |
| 197 | `branch` | `duplicate` | 1.1704e+03 | method=algebraic, source=imported, candidate=131 |
| 198 | `branch` | `duplicate` | 2.5174e+04 | method=algebraic, source=imported, candidate=100 |
| 199 | `branch` | `duplicate` | 5.2785e+04 | method=algebraic, source=imported, candidate=26 |
| 200 | `branch` | `duplicate` | 1.1004e+02 | method=algebraic, source=imported, candidate=266 |
| 201 | `branch` | `duplicate` | 2.1929e+04 | method=algebraic, source=imported, candidate=109 |
| 202 | `branch` | `duplicate` | 1.1085e+02 | method=algebraic, source=imported, candidate=262 |
| 203 | `branch` | `duplicate` | 2.1929e+04 | method=algebraic, source=imported, candidate=108 |
| 204 | `branch` | `duplicate` | 9.8485e+04 | method=algebraic, source=imported, candidate=16 |
| 205 | `branch` | `duplicate` | 3.3257e+04 | method=algebraic, source=imported, candidate=86 |
| 206 | `branch` | `duplicate` | 1.5781e+04 | method=algebraic, source=imported, candidate=118 |
| 207 | `branch` | `duplicate` | 3.3257e+04 | method=algebraic, source=imported, candidate=85 |
| 208 | `branch` | `duplicate` | 3.5288e+04 | method=algebraic, source=imported, candidate=76 |
| 209 | `branch` | `duplicate` | 3.4984e+04 | method=algebraic, source=imported, candidate=82 |
| 210 | `branch` | `duplicate` | 1.4401e+06 | method=algebraic, source=imported, candidate=8 |
| 211 | `branch` | `duplicate` | 1.8277e+06 | method=algebraic, source=imported, candidate=3 |
| 212 | `branch` | `duplicate` | 1.1407e+05 | method=algebraic, source=imported, candidate=14 |
| 213 | `branch` | `duplicate` | 1.1407e+05 | method=algebraic, source=imported, candidate=15 |
| 214 | `branch` | `duplicate` | 3.5821e+04 | method=algebraic, source=imported, candidate=72 |
| 215 | `branch` | `duplicate` | 3.4984e+04 | method=algebraic, source=imported, candidate=81 |
| 216 | `branch` | `duplicate` | 3.5979e+04 | method=algebraic, source=imported, candidate=69 |
| 217 | `branch` | `duplicate` | 1.4401e+06 | method=algebraic, source=imported, candidate=7 |
| 218 | `branch` | `duplicate` | 6.3183e+04 | method=algebraic, source=imported, candidate=18 |
| 219 | `branch` | `duplicate` | 2.8944e+03 | method=algebraic, source=imported, candidate=154 |
| 220 | `branch` | `duplicate` | 5.2785e+04 | method=algebraic, source=imported, candidate=25 |
| 221 | `branch` | `duplicate` | 1.5368e+06 | method=algebraic, source=imported, candidate=5 |
| 222 | `branch` | `duplicate` | 1.0039e+06 | method=algebraic, source=imported, candidate=10 |
| 223 | `branch` | `duplicate` | 2.8944e+03 | method=algebraic, source=imported, candidate=153 |
| 224 | `branch` | `duplicate` | 2.7965e+04 | method=algebraic, source=imported, candidate=94 |
| 225 | `branch` | `duplicate` | 1.5368e+06 | method=algebraic, source=imported, candidate=6 |
| 226 | `branch` | `duplicate` | 2.7965e+04 | method=algebraic, source=imported, candidate=93 |
| 227 | `branch` | `duplicate` | 4.7362e+03 | method=algebraic, source=imported, candidate=140 |
| 228 | `branch` | `duplicate` | 3.0151e+04 | method=algebraic, source=imported, candidate=90 |
| 229 | `branch` | `duplicate` | 1.8277e+06 | method=algebraic, source=imported, candidate=4 |
| 230 | `branch` | `duplicate` | 1.7627e+04 | method=algebraic, source=imported, candidate=112 |
| 231 | `branch` | `duplicate` | 3.5533e+03 | method=algebraic, source=imported, candidate=126 |
| 232 | `branch` | `duplicate` | 8.6819e+03 | method=algebraic, source=imported, candidate=129 |
| 233 | `branch` | `duplicate` | 2.2358e+05 | method=algebraic, source=imported, candidate=11 |
| 234 | `branch` | `duplicate` | 3.0151e+04 | method=algebraic, source=imported, candidate=89 |
| 235 | `branch` | `duplicate` | 8.6819e+03 | method=algebraic, source=imported, candidate=130 |
| 236 | `branch` | `duplicate` | 1.7627e+04 | method=algebraic, source=imported, candidate=111 |
| 237 | `branch` | `duplicate` | 1.2546e+04 | method=algebraic, source=imported, candidate=124 |
| 238 | `branch` | `duplicate` | 2.0853e+06 | method=algebraic, source=imported, candidate=2 |
| 239 | `branch` | `duplicate` | 4.7362e+03 | method=algebraic, source=imported, candidate=139 |
| 240 | `branch` | `duplicate` | 2.3604e+04 | method=algebraic, source=imported, candidate=105 |
| 241 | `branch` | `duplicate` | 4.6880e+03 | method=algebraic, source=imported, candidate=138 |
| 242 | `branch` | `duplicate` | 2.3604e+04 | method=algebraic, source=imported, candidate=104 |
| 243 | `branch` | `duplicate` | 1.2517e+04 | method=algebraic, source=imported, candidate=125 |
| 244 | `branch` | `duplicate` | 4.6880e+03 | method=algebraic, source=imported, candidate=137 |
| 245 | `branch` | `duplicate` | 3.6492e+04 | method=algebraic, source=imported, candidate=62 |
| 246 | `branch` | `duplicate` | 1.0039e+06 | method=algebraic, source=imported, candidate=9 |
| 247 | `branch` | `duplicate` | 3.6492e+04 | method=algebraic, source=imported, candidate=61 |
| 248 | `branch` | `duplicate` | 3.9137e+04 | method=algebraic, source=imported, candidate=49 |
| 249 | `branch` | `duplicate` | 3.9137e+04 | method=algebraic, source=imported, candidate=50 |
| 250 | `branch` | `duplicate` | 3.7791e+04 | method=algebraic, source=imported, candidate=56 |
| 251 | `branch` | `duplicate` | 3.7701e+04 | method=algebraic, source=imported, candidate=58 |
| 252 | `branch` | `duplicate` | 3.7791e+04 | method=algebraic, source=imported, candidate=55 |
| 253 | `branch` | `duplicate` | 3.6128e+04 | method=algebraic, source=imported, candidate=64 |
| 254 | `branch` | `duplicate` | 3.6128e+04 | method=algebraic, source=imported, candidate=63 |
| 255 | `branch` | `duplicate` | 3.7701e+04 | method=algebraic, source=imported, candidate=57 |
| 256 | `branch` | `duplicate` | 3.6075e+04 | method=algebraic, source=imported, candidate=66 |
| 257 | `branch` | `duplicate` | 2.5258e+04 | method=algebraic, source=imported, candidate=99 |
| 258 | `branch` | `duplicate` | 3.8433e+04 | method=algebraic, source=imported, candidate=54 |
| 259 | `branch` | `duplicate` | 1.7022e+04 | method=algebraic, source=imported, candidate=114 |
| 260 | `branch` | `duplicate` | 2.5955e+04 | method=algebraic, source=imported, candidate=98 |
| 261 | `branch` | `duplicate` | 3.8433e+04 | method=algebraic, source=imported, candidate=53 |
| 262 | `branch` | `duplicate` | 3.6075e+04 | method=algebraic, source=imported, candidate=65 |
| 263 | `branch` | `duplicate` | 2.7570e+04 | method=algebraic, source=imported, candidate=95 |
| 264 | `branch` | `duplicate` | 3.8538e+04 | method=algebraic, source=imported, candidate=51 |
| 265 | `branch` | `duplicate` | 5.8657e+04 | method=algebraic, source=imported, candidate=20 |
| 266 | `branch` | `duplicate` | 5.6225e+04 | method=algebraic, source=imported, candidate=24 |
| 267 | `branch` | `duplicate` | 4.1451e+04 | method=algebraic, source=imported, candidate=31 |
| 268 | `branch` | `duplicate` | 4.4604e+04 | method=algebraic, source=imported, candidate=29 |
| 269 | `branch` | `duplicate` | 3.6719e+04 | method=algebraic, source=imported, candidate=60 |
| 270 | `branch` | `duplicate` | 1.7505e+05 | method=algebraic, source=imported, candidate=12 |
| 271 | `branch` | `duplicate` | 3.9856e+04 | method=algebraic, source=imported, candidate=48 |
| 272 | `branch` | `duplicate` | 3.8538e+04 | method=algebraic, source=imported, candidate=52 |
| 273 | `branch` | `duplicate` | 5.8657e+04 | method=algebraic, source=imported, candidate=19 |
| 274 | `branch` | `duplicate` | 5.6225e+04 | method=algebraic, source=imported, candidate=23 |
| 275 | `branch` | `duplicate` | 4.1451e+04 | method=algebraic, source=imported, candidate=32 |
| 276 | `branch` | `duplicate` | 3.9856e+04 | method=algebraic, source=imported, candidate=47 |
| 277 | `branch` | `duplicate` | 3.6740e+04 | method=algebraic, source=imported, candidate=59 |
| 278 | `branch` | `duplicate` | 4.0217e+04 | method=algebraic, source=imported, candidate=44 |
| 279 | `branch` | `duplicate` | 4.0204e+04 | method=algebraic, source=imported, candidate=45 |
| 280 | `branch` | `duplicate` | 4.0217e+04 | method=algebraic, source=imported, candidate=43 |
| 281 | `branch` | `duplicate` | 4.4604e+04 | method=algebraic, source=imported, candidate=30 |
| 282 | `branch` | `duplicate` | 4.0204e+04 | method=algebraic, source=imported, candidate=46 |
| 283 | `branch` | `duplicate` | 4.0228e+04 | method=algebraic, source=imported, candidate=41 |
| 284 | `branch` | `duplicate` | 1.7505e+05 | method=algebraic, source=imported, candidate=13 |
| 285 | `branch` | `duplicate` | 4.0228e+04 | method=algebraic, source=imported, candidate=42 |
| 286 | `branch` | `duplicate` | 4.0308e+04 | method=algebraic, source=imported, candidate=39 |
| 287 | `branch` | `duplicate` | 4.0317e+04 | method=algebraic, source=imported, candidate=37 |
| 288 | `branch` | `duplicate` | 4.1397e+04 | method=algebraic, source=imported, candidate=33 |
| 289 | `branch` | `duplicate` | 6.9689e+06 | method=algebraic, source=imported, candidate=1 |
| 290 | `branch` | `duplicate` | 4.1397e+04 | method=algebraic, source=imported, candidate=34 |
| 291 | `branch` | `duplicate` | 5.6873e+04 | method=algebraic, source=imported, candidate=22 |
| 292 | `branch` | `duplicate` | 5.6873e+04 | method=algebraic, source=imported, candidate=21 |
| 293 | `branch` | `duplicate` | 4.4985e+04 | method=algebraic, source=imported, candidate=28 |
| 294 | `branch` | `duplicate` | 4.4985e+04 | method=algebraic, source=imported, candidate=27 |
| 295 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=40 |
| 296 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=38 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 6.9689e+06 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 2.0853e+06 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 1.8277e+06 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 1.8277e+06 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 1.5368e+06 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 1.5368e+06 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 1.4401e+06 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 1.4401e+06 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 1.0039e+06 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 1.0039e+06 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 2.2358e+05 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 1.7505e+05 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 1.7505e+05 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 1.1407e+05 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 1.1407e+05 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 9.8485e+04 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 9.8485e+04 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 6.3183e+04 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 5.8657e+04 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 5.8657e+04 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 5.6873e+04 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 5.6873e+04 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 5.6225e+04 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 5.6225e+04 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 5.2785e+04 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 5.2785e+04 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 4.4985e+04 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 4.4985e+04 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 4.4604e+04 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 4.4604e+04 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 4.1451e+04 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 4.1451e+04 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 4.1397e+04 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 4.1397e+04 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | 4.1049e+04 | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | 4.1049e+04 | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 4.0317e+04 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | Inf | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 4.0308e+04 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | Inf | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 4.0228e+04 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 4.0228e+04 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 4.0217e+04 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 4.0217e+04 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 4.0204e+04 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 4.0204e+04 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 3.9856e+04 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 3.9856e+04 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 3.9137e+04 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 3.9137e+04 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 3.8538e+04 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 3.8538e+04 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | 3.8433e+04 | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | 3.8433e+04 | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 3.7791e+04 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 3.7791e+04 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 3.7701e+04 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 3.7701e+04 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 3.6740e+04 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 3.6719e+04 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 3.6492e+04 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 3.6492e+04 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 3.6128e+04 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 3.6128e+04 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 3.6075e+04 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 3.6075e+04 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 3.6015e+04 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 3.6015e+04 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 3.5979e+04 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 3.5691e+04 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 3.5691e+04 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 3.5821e+04 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#74` | 3.5490e+04 | method=algebraic, source=imported, candidate=74 |
| 74 | `baseline` | `baseline#76` | 3.5288e+04 | method=algebraic, source=imported, candidate=76 |
| 75 | `baseline` | `baseline#77` | 3.5212e+04 | method=algebraic, source=imported, candidate=77 |
| 76 | `baseline` | `baseline#78` | 3.5088e+04 | method=algebraic, source=imported, candidate=78 |
| 77 | `baseline` | `baseline#79` | 3.5088e+04 | method=algebraic, source=imported, candidate=79 |
| 78 | `baseline` | `baseline#80` | 3.5032e+04 | method=algebraic, source=imported, candidate=80 |
| 79 | `baseline` | `baseline#81` | 3.4984e+04 | method=algebraic, source=imported, candidate=81 |
| 80 | `baseline` | `baseline#82` | 3.4984e+04 | method=algebraic, source=imported, candidate=82 |
| 81 | `baseline` | `baseline#83` | 3.4930e+04 | method=algebraic, source=imported, candidate=83 |
| 82 | `baseline` | `baseline#84` | 3.4930e+04 | method=algebraic, source=imported, candidate=84 |
| 83 | `baseline` | `baseline#85` | 3.3257e+04 | method=algebraic, source=imported, candidate=85 |
| 84 | `baseline` | `baseline#86` | 3.3257e+04 | method=algebraic, source=imported, candidate=86 |
| 85 | `baseline` | `baseline#87` | 3.3015e+04 | method=algebraic, source=imported, candidate=87 |
| 86 | `baseline` | `baseline#88` | 3.2624e+04 | method=algebraic, source=imported, candidate=88 |
| 87 | `baseline` | `baseline#89` | 3.0151e+04 | method=algebraic, source=imported, candidate=89 |
| 88 | `baseline` | `baseline#90` | 3.0151e+04 | method=algebraic, source=imported, candidate=90 |
| 89 | `baseline` | `baseline#91` | 2.9870e+04 | method=algebraic, source=imported, candidate=91 |
| 90 | `baseline` | `baseline#92` | 2.9870e+04 | method=algebraic, source=imported, candidate=92 |
| 91 | `baseline` | `baseline#93` | 2.7965e+04 | method=algebraic, source=imported, candidate=93 |
| 92 | `baseline` | `baseline#94` | 2.7965e+04 | method=algebraic, source=imported, candidate=94 |
| 93 | `baseline` | `baseline#95` | 2.7570e+04 | method=algebraic, source=imported, candidate=95 |
| 94 | `baseline` | `baseline#96` | 2.6996e+04 | method=algebraic, source=imported, candidate=96 |
| 95 | `baseline` | `baseline#97` | 2.6996e+04 | method=algebraic, source=imported, candidate=97 |
| 96 | `baseline` | `baseline#98` | 2.5955e+04 | method=algebraic, source=imported, candidate=98 |
| 97 | `baseline` | `baseline#99` | 2.5258e+04 | method=algebraic, source=imported, candidate=99 |
| 98 | `baseline` | `baseline#100` | 2.5174e+04 | method=algebraic, source=imported, candidate=100 |
| 99 | `baseline` | `baseline#101` | 2.5174e+04 | method=algebraic, source=imported, candidate=101 |
| 100 | `baseline` | `baseline#102` | 2.4777e+04 | method=algebraic, source=imported, candidate=102 |
| 101 | `baseline` | `baseline#103` | 2.4777e+04 | method=algebraic, source=imported, candidate=103 |
| 102 | `baseline` | `baseline#104` | 2.3604e+04 | method=algebraic, source=imported, candidate=104 |
| 103 | `baseline` | `baseline#105` | 2.3604e+04 | method=algebraic, source=imported, candidate=105 |
| 104 | `baseline` | `baseline#106` | 2.3539e+04 | method=algebraic, source=imported, candidate=106 |
| 105 | `baseline` | `baseline#107` | 2.3539e+04 | method=algebraic, source=imported, candidate=107 |
| 106 | `baseline` | `baseline#108` | 2.1929e+04 | method=algebraic, source=imported, candidate=108 |
| 107 | `baseline` | `baseline#109` | 2.1929e+04 | method=algebraic, source=imported, candidate=109 |
| 108 | `baseline` | `baseline#110` | 2.1166e+04 | method=algebraic, source=imported, candidate=110 |
| 109 | `baseline` | `baseline#111` | 1.7627e+04 | method=algebraic, source=imported, candidate=111 |
| 110 | `baseline` | `baseline#112` | 1.7627e+04 | method=algebraic, source=imported, candidate=112 |
| 111 | `baseline` | `baseline#113` | 1.7574e+04 | method=algebraic, source=imported, candidate=113 |
| 112 | `baseline` | `baseline#114` | 1.7022e+04 | method=algebraic, source=imported, candidate=114 |
| 113 | `baseline` | `baseline#115` | 1.6313e+04 | method=algebraic, source=imported, candidate=115 |
| 114 | `baseline` | `baseline#116` | 1.6313e+04 | method=algebraic, source=imported, candidate=116 |
| 115 | `baseline` | `baseline#117` | 1.5781e+04 | method=algebraic, source=imported, candidate=117 |
| 116 | `baseline` | `baseline#118` | 1.5781e+04 | method=algebraic, source=imported, candidate=118 |
| 117 | `baseline` | `baseline#119` | 1.3817e+04 | method=algebraic, source=imported, candidate=119 |
| 118 | `baseline` | `baseline#120` | 1.3469e+04 | method=algebraic, source=imported, candidate=120 |
| 119 | `baseline` | `baseline#121` | 1.3469e+04 | method=algebraic, source=imported, candidate=121 |
| 120 | `baseline` | `baseline#122` | 1.2754e+04 | method=algebraic, source=imported, candidate=122 |
| 121 | `baseline` | `baseline#123` | 1.2754e+04 | method=algebraic, source=imported, candidate=123 |
| 122 | `baseline` | `baseline#124` | 1.2546e+04 | method=algebraic, source=imported, candidate=124 |
| 123 | `baseline` | `baseline#125` | 1.2517e+04 | method=algebraic, source=imported, candidate=125 |
| 124 | `baseline` | `baseline#126` | 3.5533e+03 | method=algebraic, source=imported, candidate=126 |
| 125 | `baseline` | `baseline#127` | 9.1848e+03 | method=algebraic, source=imported, candidate=127 |
| 126 | `baseline` | `baseline#128` | 9.1848e+03 | method=algebraic, source=imported, candidate=128 |
| 127 | `baseline` | `baseline#129` | 8.6819e+03 | method=algebraic, source=imported, candidate=129 |
| 128 | `baseline` | `baseline#130` | 8.6819e+03 | method=algebraic, source=imported, candidate=130 |
| 129 | `baseline` | `baseline#131` | 1.1704e+03 | method=algebraic, source=imported, candidate=131 |
| 130 | `baseline` | `baseline#132` | 5.5309e+03 | method=algebraic, source=imported, candidate=132 |
| 131 | `baseline` | `baseline#133` | 5.5309e+03 | method=algebraic, source=imported, candidate=133 |
| 132 | `baseline` | `baseline#134` | 5.1958e+03 | method=algebraic, source=imported, candidate=134 |
| 133 | `baseline` | `baseline#135` | 5.1958e+03 | method=algebraic, source=imported, candidate=135 |
| 134 | `baseline` | `baseline#136` | 4.8991e+03 | method=algebraic, source=imported, candidate=136 |
| 135 | `baseline` | `baseline#137` | 4.6880e+03 | method=algebraic, source=imported, candidate=137 |
| 136 | `baseline` | `baseline#138` | 4.6880e+03 | method=algebraic, source=imported, candidate=138 |
| 137 | `baseline` | `baseline#139` | 4.7362e+03 | method=algebraic, source=imported, candidate=139 |
| 138 | `baseline` | `baseline#140` | 4.7362e+03 | method=algebraic, source=imported, candidate=140 |
| 139 | `baseline` | `baseline#141` | 4.6605e+03 | method=algebraic, source=imported, candidate=141 |
| 140 | `baseline` | `baseline#142` | 4.5900e+03 | method=algebraic, source=imported, candidate=142 |
| 141 | `baseline` | `baseline#143` | 4.5900e+03 | method=algebraic, source=imported, candidate=143 |
| 142 | `baseline` | `baseline#144` | 4.4946e+03 | method=algebraic, source=imported, candidate=144 |
| 143 | `baseline` | `baseline#145` | 4.4946e+03 | method=algebraic, source=imported, candidate=145 |
| 144 | `baseline` | `baseline#146` | 4.3390e+03 | method=algebraic, source=imported, candidate=146 |
| 145 | `baseline` | `baseline#147` | 3.8887e+03 | method=algebraic, source=imported, candidate=147 |
| 146 | `baseline` | `baseline#148` | 3.8887e+03 | method=algebraic, source=imported, candidate=148 |
| 147 | `baseline` | `baseline#149` | 3.4009e+03 | method=algebraic, source=imported, candidate=149 |
| 148 | `baseline` | `baseline#150` | 3.4009e+03 | method=algebraic, source=imported, candidate=150 |
| 149 | `baseline` | `baseline#151` | 3.0077e+03 | method=algebraic, source=imported, candidate=151 |
| 150 | `baseline` | `baseline#152` | 3.0077e+03 | method=algebraic, source=imported, candidate=152 |
| 151 | `baseline` | `baseline#153` | 2.8944e+03 | method=algebraic, source=imported, candidate=153 |
| 152 | `baseline` | `baseline#154` | 2.8944e+03 | method=algebraic, source=imported, candidate=154 |
| 153 | `baseline` | `baseline#155` | 2.8417e+03 | method=algebraic, source=imported, candidate=155 |
| 154 | `baseline` | `baseline#156` | 2.8417e+03 | method=algebraic, source=imported, candidate=156 |
| 155 | `baseline` | `baseline#157` | 2.1196e+03 | method=algebraic, source=imported, candidate=157 |
| 156 | `baseline` | `baseline#158` | 2.1196e+03 | method=algebraic, source=imported, candidate=158 |
| 157 | `baseline` | `baseline#159` | 1.9891e+03 | method=algebraic, source=imported, candidate=159 |
| 158 | `baseline` | `baseline#160` | 1.9891e+03 | method=algebraic, source=imported, candidate=160 |
| 159 | `baseline` | `baseline#161` | 1.9177e+03 | method=algebraic, source=imported, candidate=161 |
| 160 | `baseline` | `baseline#162` | 1.9177e+03 | method=algebraic, source=imported, candidate=162 |
| 161 | `baseline` | `baseline#163` | 1.7926e+03 | method=algebraic, source=imported, candidate=163 |
| 162 | `baseline` | `baseline#164` | 1.7926e+03 | method=algebraic, source=imported, candidate=164 |
| 163 | `baseline` | `baseline#165` | 1.7923e+03 | method=algebraic, source=imported, candidate=165 |
| 164 | `baseline` | `baseline#166` | 1.7923e+03 | method=algebraic, source=imported, candidate=166 |
| 165 | `baseline` | `baseline#167` | 1.5226e+03 | method=algebraic, source=imported, candidate=167 |
| 166 | `baseline` | `baseline#168` | 1.5123e+03 | method=algebraic, source=imported, candidate=168 |
| 167 | `baseline` | `baseline#169` | 1.5123e+03 | method=algebraic, source=imported, candidate=169 |
| 168 | `baseline` | `baseline#170` | 1.3970e+03 | method=algebraic, source=imported, candidate=170 |
| 169 | `baseline` | `baseline#171` | 1.3970e+03 | method=algebraic, source=imported, candidate=171 |
| 170 | `baseline` | `baseline#175` | 1.3841e+03 | method=algebraic, source=imported, candidate=175 |
| 171 | `baseline` | `baseline#173` | 1.3967e+03 | method=algebraic, source=imported, candidate=173 |
| 172 | `baseline` | `baseline#174` | 1.3841e+03 | method=algebraic, source=imported, candidate=174 |
| 173 | `baseline` | `baseline#176` | 1.2161e+03 | method=algebraic, source=imported, candidate=176 |
| 174 | `baseline` | `baseline#177` | 1.0612e+03 | method=algebraic, source=imported, candidate=177 |
| 175 | `baseline` | `baseline#178` | 1.0010e+03 | method=algebraic, source=imported, candidate=178 |
| 176 | `baseline` | `baseline#179` | 1.0010e+03 | method=algebraic, source=imported, candidate=179 |
| 177 | `baseline` | `baseline#180` | 9.8873e+02 | method=algebraic, source=imported, candidate=180 |
| 178 | `baseline` | `baseline#181` | 9.3026e+02 | method=algebraic, source=imported, candidate=181 |
| 179 | `baseline` | `baseline#182` | 9.3026e+02 | method=algebraic, source=imported, candidate=182 |
| 180 | `baseline` | `baseline#183` | 8.9082e+02 | method=algebraic, source=imported, candidate=183 |
| 181 | `baseline` | `baseline#184` | 7.9976e+02 | method=algebraic, source=imported, candidate=184 |
| 182 | `baseline` | `baseline#185` | 7.9976e+02 | method=algebraic, source=imported, candidate=185 |
| 183 | `baseline` | `baseline#186` | 7.0820e+02 | method=algebraic, source=imported, candidate=186 |
| 184 | `baseline` | `baseline#187` | 7.0820e+02 | method=algebraic, source=imported, candidate=187 |
| 185 | `baseline` | `baseline#188` | 6.1046e+02 | method=algebraic, source=imported, candidate=188 |
| 186 | `baseline` | `baseline#189` | 5.8884e+02 | method=algebraic, source=imported, candidate=189 |
| 187 | `baseline` | `baseline#190` | 5.4610e+02 | method=algebraic, source=imported, candidate=190 |
| 188 | `baseline` | `baseline#191` | 5.3934e+02 | method=algebraic, source=imported, candidate=191 |
| 189 | `baseline` | `baseline#192` | 5.3858e+02 | method=algebraic, source=imported, candidate=192 |
| 190 | `baseline` | `baseline#193` | 5.3472e+02 | method=algebraic, source=imported, candidate=193 |
| 191 | `baseline` | `baseline#194` | 5.3219e+02 | method=algebraic, source=imported, candidate=194 |
| 192 | `baseline` | `baseline#195` | 5.2513e+02 | method=algebraic, source=imported, candidate=195 |
| 193 | `baseline` | `baseline#196` | 5.1306e+02 | method=algebraic, source=imported, candidate=196 |
| 194 | `baseline` | `baseline#197` | 5.0654e+02 | method=algebraic, source=imported, candidate=197 |
| 195 | `baseline` | `baseline#198` | 5.0579e+02 | method=algebraic, source=imported, candidate=198 |
| 196 | `baseline` | `baseline#199` | 4.9943e+02 | method=algebraic, source=imported, candidate=199 |
| 197 | `baseline` | `baseline#200` | 4.9943e+02 | method=algebraic, source=imported, candidate=200 |
| 198 | `baseline` | `baseline#201` | 4.9185e+02 | method=algebraic, source=imported, candidate=201 |
| 199 | `baseline` | `baseline#202` | 4.9185e+02 | method=algebraic, source=imported, candidate=202 |
| 200 | `baseline` | `baseline#203` | 4.9052e+02 | method=algebraic, source=imported, candidate=203 |
| 201 | `baseline` | `baseline#204` | 4.9052e+02 | method=algebraic, source=imported, candidate=204 |
| 202 | `baseline` | `baseline#205` | 4.8547e+02 | method=algebraic, source=imported, candidate=205 |
| 203 | `baseline` | `baseline#206` | 4.8426e+02 | method=algebraic, source=imported, candidate=206 |
| 204 | `baseline` | `baseline#207` | 4.8426e+02 | method=algebraic, source=imported, candidate=207 |
| 205 | `baseline` | `baseline#208` | 4.7309e+02 | method=algebraic, source=imported, candidate=208 |
| 206 | `baseline` | `baseline#209` | 4.6783e+02 | method=algebraic, source=imported, candidate=209 |
| 207 | `baseline` | `baseline#210` | 4.5945e+02 | method=algebraic, source=imported, candidate=210 |
| 208 | `baseline` | `baseline#211` | 4.5573e+02 | method=algebraic, source=imported, candidate=211 |
| 209 | `baseline` | `baseline#212` | 4.4630e+02 | method=algebraic, source=imported, candidate=212 |
| 210 | `baseline` | `baseline#213` | 4.2477e+02 | method=algebraic, source=imported, candidate=213 |
| 211 | `baseline` | `baseline#214` | 4.2477e+02 | method=algebraic, source=imported, candidate=214 |
| 212 | `baseline` | `baseline#215` | 4.1918e+02 | method=algebraic, source=imported, candidate=215 |
| 213 | `baseline` | `baseline#216` | 4.1787e+02 | method=algebraic, source=imported, candidate=216 |
| 214 | `baseline` | `baseline#217` | 4.1786e+02 | method=algebraic, source=imported, candidate=217 |
| 215 | `baseline` | `baseline#218` | 4.1715e+02 | method=algebraic, source=imported, candidate=218 |
| 216 | `baseline` | `baseline#219` | 4.0415e+02 | method=algebraic, source=imported, candidate=219 |
| 217 | `baseline` | `baseline#220` | 3.7639e+02 | method=algebraic, source=imported, candidate=220 |
| 218 | `baseline` | `baseline#221` | 3.7639e+02 | method=algebraic, source=imported, candidate=221 |
| 219 | `baseline` | `baseline#222` | 3.6898e+02 | method=algebraic, source=imported, candidate=222 |
| 220 | `baseline` | `baseline#223` | 3.6898e+02 | method=algebraic, source=imported, candidate=223 |
| 221 | `baseline` | `baseline#224` | 3.5785e+02 | method=algebraic, source=imported, candidate=224 |
| 222 | `baseline` | `baseline#225` | 3.5785e+02 | method=algebraic, source=imported, candidate=225 |
| 223 | `baseline` | `baseline#226` | 3.5580e+02 | method=algebraic, source=imported, candidate=226 |
| 224 | `baseline` | `baseline#227` | 2.8808e+02 | method=algebraic, source=imported, candidate=227 |
| 225 | `baseline` | `baseline#228` | 2.8808e+02 | method=algebraic, source=imported, candidate=228 |
| 226 | `baseline` | `baseline#229` | 3.4391e+02 | method=algebraic, source=imported, candidate=229 |
| 227 | `baseline` | `baseline#230` | 3.4043e+02 | method=algebraic, source=imported, candidate=230 |
| 228 | `baseline` | `baseline#231` | 3.0706e+02 | method=algebraic, source=imported, candidate=231 |
| 229 | `baseline` | `baseline#232` | 3.0706e+02 | method=algebraic, source=imported, candidate=232 |
| 230 | `baseline` | `baseline#233` | 2.9161e+02 | method=algebraic, source=imported, candidate=233 |
| 231 | `baseline` | `baseline#234` | 2.7749e+02 | method=algebraic, source=imported, candidate=234 |
| 232 | `baseline` | `baseline#235` | 2.7749e+02 | method=algebraic, source=imported, candidate=235 |
| 233 | `baseline` | `baseline#236` | 2.5253e+02 | method=algebraic, source=imported, candidate=236 |
| 234 | `baseline` | `baseline#237` | 2.4383e+02 | method=algebraic, source=imported, candidate=237 |
| 235 | `baseline` | `baseline#238` | 2.2958e+02 | method=algebraic, source=imported, candidate=238 |
| 236 | `baseline` | `baseline#239` | 2.0690e+02 | method=algebraic, source=imported, candidate=239 |
| 237 | `baseline` | `baseline#240` | 2.0281e+02 | method=algebraic, source=imported, candidate=240 |
| 238 | `baseline` | `baseline#241` | 1.9815e+02 | method=algebraic, source=imported, candidate=241 |
| 239 | `baseline` | `baseline#242` | 1.9272e+02 | method=algebraic, source=imported, candidate=242 |
| 240 | `baseline` | `baseline#243` | 1.7934e+02 | method=algebraic, source=imported, candidate=243 |
| 241 | `baseline` | `baseline#244` | 1.7934e+02 | method=algebraic, source=imported, candidate=244 |
| 242 | `baseline` | `baseline#245` | 1.5390e+02 | method=algebraic, source=imported, candidate=245 |
| 243 | `baseline` | `baseline#246` | 1.5368e+02 | method=algebraic, source=imported, candidate=246 |
| 244 | `baseline` | `baseline#247` | 1.4420e+02 | method=algebraic, source=imported, candidate=247 |
| 245 | `baseline` | `baseline#248` | 1.4420e+02 | method=algebraic, source=imported, candidate=248 |
| 246 | `baseline` | `baseline#249` | 1.3880e+02 | method=algebraic, source=imported, candidate=249 |
| 247 | `baseline` | `baseline#250` | 1.3880e+02 | method=algebraic, source=imported, candidate=250 |
| 248 | `baseline` | `baseline#251` | 1.2647e+02 | method=algebraic, source=imported, candidate=251 |
| 249 | `baseline` | `baseline#252` | 1.2038e+02 | method=algebraic, source=imported, candidate=252 |
| 250 | `baseline` | `baseline#253` | 1.2038e+02 | method=algebraic, source=imported, candidate=253 |
| 251 | `baseline` | `baseline#254` | 1.1651e+02 | method=algebraic, source=imported, candidate=254 |
| 252 | `baseline` | `baseline#255` | 1.1651e+02 | method=algebraic, source=imported, candidate=255 |
| 253 | `baseline` | `baseline#256` | 1.1747e+02 | method=algebraic, source=imported, candidate=256 |
| 254 | `baseline` | `baseline#257` | 1.1432e+02 | method=algebraic, source=imported, candidate=257 |
| 255 | `baseline` | `baseline#258` | 1.1432e+02 | method=algebraic, source=imported, candidate=258 |
| 256 | `baseline` | `baseline#259` | 1.1492e+02 | method=algebraic, source=imported, candidate=259 |
| 257 | `baseline` | `baseline#260` | 1.1108e+02 | method=algebraic, source=imported, candidate=260 |
| 258 | `baseline` | `baseline#261` | 1.1108e+02 | method=algebraic, source=imported, candidate=261 |
| 259 | `baseline` | `baseline#262` | 1.1085e+02 | method=algebraic, source=imported, candidate=262 |
| 260 | `baseline` | `baseline#263` | 1.1085e+02 | method=algebraic, source=imported, candidate=263 |
| 261 | `baseline` | `baseline#264` | 1.0863e+02 | method=algebraic, source=imported, candidate=264 |
| 262 | `baseline` | `baseline#265` | 1.0863e+02 | method=algebraic, source=imported, candidate=265 |
| 263 | `baseline` | `baseline#266` | 1.1004e+02 | method=algebraic, source=imported, candidate=266 |
| 264 | `baseline` | `baseline#267` | 1.1004e+02 | method=algebraic, source=imported, candidate=267 |
| 265 | `baseline` | `baseline#268` | 1.0355e+02 | method=algebraic, source=imported, candidate=268 |
| 266 | `baseline` | `baseline#269` | 1.0355e+02 | method=algebraic, source=imported, candidate=269 |
| 267 | `baseline` | `baseline#270` | 9.1517e+01 | method=algebraic, source=imported, candidate=270 |
| 268 | `baseline` | `baseline#271` | 9.0363e+01 | method=algebraic, source=imported, candidate=271 |
| 269 | `baseline` | `baseline#272` | 7.7243e+01 | method=algebraic, source=imported, candidate=272 |
| 270 | `baseline` | `baseline#273` | 7.7243e+01 | method=algebraic, source=imported, candidate=273 |
| 271 | `baseline` | `baseline#274` | 7.6830e+01 | method=algebraic, source=imported, candidate=274 |
| 272 | `baseline` | `baseline#275` | 7.5479e+01 | method=algebraic, source=imported, candidate=275 |
| 273 | `baseline` | `baseline#276` | 7.2040e+01 | method=algebraic, source=imported, candidate=276 |
| 274 | `baseline` | `baseline#277` | 7.2040e+01 | method=algebraic, source=imported, candidate=277 |
| 275 | `baseline` | `baseline#278` | 6.9564e+01 | method=algebraic, source=imported, candidate=278 |
| 276 | `baseline` | `baseline#279` | 6.9564e+01 | method=algebraic, source=imported, candidate=279 |
| 277 | `baseline` | `baseline#280` | 6.7603e+01 | method=algebraic, source=imported, candidate=280 |
| 278 | `baseline` | `baseline#281` | 6.7603e+01 | method=algebraic, source=imported, candidate=281 |
| 279 | `baseline` | `baseline#282` | 6.9854e+01 | method=algebraic, source=imported, candidate=282 |
| 280 | `baseline` | `baseline#283` | 6.9854e+01 | method=algebraic, source=imported, candidate=283 |
| 281 | `baseline` | `baseline#284` | 6.5668e+01 | method=algebraic, source=imported, candidate=284 |
| 282 | `baseline` | `baseline#285` | 6.5668e+01 | method=algebraic, source=imported, candidate=285 |
| 283 | `baseline` | `baseline#286` | 6.2167e+01 | method=algebraic, source=imported, candidate=286 |
| 284 | `baseline` | `baseline#287` | 6.2146e+01 | method=algebraic, source=imported, candidate=287 |
| 285 | `baseline` | `baseline#288` | 6.2753e+01 | method=algebraic, source=imported, candidate=288 |
| 286 | `baseline` | `baseline#289` | 6.2753e+01 | method=algebraic, source=imported, candidate=289 |
| 287 | `baseline` | `baseline#290` | 5.8289e+01 | method=algebraic, source=imported, candidate=290 |
| 288 | `baseline` | `baseline#291` | 5.6793e+01 | method=algebraic, source=imported, candidate=291 |
| 289 | `baseline` | `baseline#292` | 5.6793e+01 | method=algebraic, source=imported, candidate=292 |
| 290 | `baseline` | `baseline#293` | 5.3233e+01 | method=algebraic, source=imported, candidate=293 |
| 291 | `baseline` | `baseline#294` | 5.3220e+01 | method=algebraic, source=imported, candidate=294 |
| 292 | `baseline` | `baseline#295` | 5.2339e+01 | method=algebraic, source=imported, candidate=295 |
| 293 | `baseline` | `baseline#296` | 5.2339e+01 | method=algebraic, source=imported, candidate=296 |
| 294 | `baseline` | `baseline#297` | 4.6701e+01 | method=algebraic, source=imported, candidate=297 |
| 295 | `baseline` | `baseline#298` | 4.6701e+01 | method=algebraic, source=imported, candidate=298 |
| 296 | `block` | `block#1, block#2` | 5.2075e+04 | method=direct_opt, source=assembled |
| 297 | `synthesized` | `synthesized#1` | 4.2390e+01 | method=direct_opt, source=synthesized, polished=true |
| 298 | `branch` | `branch#2` | 4.2398e+01 | method=direct_opt, source=synthesized, candidate=288, polished=true |
| 299 | `synthesized` | `synthesized#2, synthesized#3` | 4.2332e+01 | method=direct_opt, source=synthesized, polished=true |
| 300 | `block` | `block#3, block#4` | 8.4887e+03 | method=direct_opt, source=assembled |
| 301 | `branch` | `branch#3` | 4.2530e+01 | method=direct_opt, source=synthesized, candidate=278, polished=true |
| 302 | `synthesized` | `synthesized#4` | 4.2475e+01 | method=direct_opt, source=synthesized, polished=true |
| 303 | `block` | `block#5` | 4.0246e+04 | method=direct_opt, source=assembled |
| 304 | `block` | `block#6` | 4.0158e+04 | method=direct_opt, source=assembled |
| 305 | `block` | `block#7, block#8` | 4.0302e+04 | method=direct_opt, source=assembled |
| 306 | `block` | `block#9` | 4.0321e+04 | method=direct_opt, source=assembled |
| 307 | `block` | `block#10` | 4.0308e+04 | method=direct_opt, source=assembled |
| 308 | `block` | `block#11` | 6.7229e+04 | method=direct_opt, source=assembled |
| 309 | `block` | `block#12, block#13` | 7.4130e+07 | method=direct_opt, source=assembled |
| 310 | `block` | `block#16` | 6.8808e+07 | method=direct_opt, source=assembled |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `baseline` | 31 | 4.3682e+01 | 28351.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=107, polished=true |
| 2 | `baseline` | 25 | 4.3682e+01 | 28325.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=106, polished=true |
| 3 | `baseline` | 9 | 4.2383e+01 | 16405.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=285, polished=true |
| 4 | `baseline` | 2 | 4.2179e+01 | 619.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=196, polished=true |
| 5 | `baseline` | 2 | 4.2183e+01 | 1179.82% | 0 | 0.5000 | method=algebraic, source=imported, candidate=230, polished=true |
| 6 | `baseline` | 2 | 4.2184e+01 | 1197.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=241, polished=true |
| 7 | `baseline` | 2 | 4.2185e+01 | 1211.77% | 0 | 0.5000 | method=algebraic, source=imported, candidate=127, polished=true |
| 8 | `baseline` | 1 | 4.2172e+01 | 241.87% | 0 | 0.5000 | method=algebraic, source=imported, candidate=115, polished=true |
| 9 | `baseline` | 1 | 4.2173e+01 | 6783.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=227, polished=true |
| 10 | `baseline` | 1 | 4.2176e+01 | 452.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=228, polished=true |
| 11 | `baseline` | 1 | 4.2178e+01 | 573.36% | 0 | 0.5000 | method=algebraic, source=imported, candidate=295, polished=true |
| 12 | `baseline` | 1 | 4.2179e+01 | 596.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=258, polished=true |
| 13 | `baseline` | 1 | 4.2179e+01 | 597.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=205, polished=true |
| 14 | `baseline` | 1 | 4.2179e+01 | 600.96% | 0 | 0.5000 | method=algebraic, source=imported, candidate=7, polished=true |
| 15 | `baseline` | 1 | 4.2179e+01 | 609.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=194, polished=true |
| 16 | `baseline` | 1 | 4.2179e+01 | 606.55% | 0 | 0.5000 | method=algebraic, source=imported, candidate=283, polished=true |
| 17 | `baseline` | 1 | 4.2179e+01 | 613.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=279, polished=true |
| 18 | `baseline` | 1 | 4.2180e+01 | 628.41% | 0 | 0.5000 | method=algebraic, source=imported, candidate=191, polished=true |
| 19 | `baseline` | 1 | 4.2180e+01 | 622.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=176, polished=true |
| 20 | `baseline` | 1 | 4.2180e+01 | 631.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=271, polished=true |
| 21 | `baseline` | 1 | 4.2180e+01 | 640.04% | 0 | 0.5000 | method=algebraic, source=imported, candidate=190, polished=true |
| 22 | `baseline` | 1 | 4.2180e+01 | 641.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=143, polished=true |
| 23 | `baseline` | 1 | 4.2180e+01 | 636.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=128, polished=true |
| 24 | `baseline` | 1 | 4.2180e+01 | 638.35% | 0 | 0.5000 | method=algebraic, source=imported, candidate=270, polished=true |
| 25 | `baseline` | 1 | 4.2180e+01 | 648.59% | 0 | 0.5000 | method=algebraic, source=imported, candidate=177, polished=true |
| 26 | `baseline` | 1 | 4.2180e+01 | 658.76% | 0 | 0.5000 | method=algebraic, source=imported, candidate=180, polished=true |
| 27 | `baseline` | 1 | 4.2181e+01 | 656.34% | 0 | 0.5000 | method=algebraic, source=imported, candidate=212, polished=true |
| 28 | `baseline` | 1 | 4.2181e+01 | 665.04% | 0 | 0.5000 | method=algebraic, source=imported, candidate=119, polished=true |
| 29 | `baseline` | 1 | 4.2181e+01 | 679.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=136, polished=true |
| 30 | `baseline` | 1 | 4.2181e+01 | 683.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=186, polished=true |
| 31 | `synthesized` | 1 | 4.2181e+01 | 1166.05% | 0 | 0.5000 | method=direct_opt, source=synthesized, polished=true |
| 32 | `synthesized` | 1 | 4.2182e+01 | 1168.72% | 0 | 0.5000 | method=direct_opt, source=synthesized, polished=true |
| 33 | `branch` | 1 | 4.2182e+01 | 1171.11% | 0 | 0.5000 | method=direct_opt, source=synthesized, candidate=278, polished=true |
| 34 | `baseline` | 1 | 4.2182e+01 | 728.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=157, polished=true |
| 35 | `synthesized` | 1 | 4.2182e+01 | 1174.02% | 0 | 0.5000 | method=direct_opt, source=synthesized, polished=true |
| 36 | `baseline` | 1 | 4.2183e+01 | 752.69% | 0 | 0.5000 | method=algebraic, source=imported, candidate=80, polished=true |
| 37 | `baseline` | 1 | 4.2184e+01 | 1188.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=233, polished=true |
| 38 | `baseline` | 1 | 4.2184e+01 | 1194.05% | 0 | 0.5000 | method=algebraic, source=imported, candidate=296, polished=true |
| 39 | `baseline` | 1 | 4.2184e+01 | 793.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 40 | `baseline` | 1 | 4.2185e+01 | 1209.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=278, polished=true |
| 41 | `baseline` | 1 | 4.2186e+01 | 1210.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=206, polished=true |
| 42 | `baseline` | 1 | 4.2186e+01 | 1216.15% | 0 | 0.5000 | method=algebraic, source=imported, candidate=187, polished=true |
| 43 | `baseline` | 1 | 4.2186e+01 | 1223.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=142, polished=true |
| 44 | `baseline` | 1 | 4.2186e+01 | 1221.30% | 0 | 0.5000 | method=algebraic, source=imported, candidate=274, polished=true |
| 45 | `baseline` | 1 | 4.2186e+01 | 838.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=77, polished=true |
| 46 | `baseline` | 1 | 4.2187e+01 | 853.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=71, polished=true |
| 47 | `baseline` | 1 | 4.2187e+01 | 1040.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=184, polished=true |
| 48 | `baseline` | 1 | 4.2188e+01 | 1248.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=113, polished=true |
| 49 | `baseline` | 1 | 4.2189e+01 | 907.96% | 0 | 0.5000 | method=algebraic, source=imported, candidate=185, polished=true |
| 50 | `baseline` | 1 | 4.2189e+01 | 1266.14% | 0 | 0.5000 | method=algebraic, source=imported, candidate=18, polished=true |
| 51 | `baseline` | 1 | 4.2189e+01 | 1278.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=167, polished=true |
| 52 | `baseline` | 1 | 4.2190e+01 | 1285.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=110, polished=true |
| 53 | `baseline` | 1 | 4.2192e+01 | 988.05% | 0 | 0.5000 | method=algebraic, source=imported, candidate=74, polished=true |
| 54 | `baseline` | 1 | 4.2192e+01 | 1319.75% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 55 | `baseline` | 1 | 4.2196e+01 | 1083.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=87, polished=true |
| 56 | `baseline` | 1 | 4.2198e+01 | 1431.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=188, polished=true |
| 57 | `baseline` | 1 | 4.2200e+01 | 1467.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=3, polished=true |
| 58 | `baseline` | 1 | 4.2204e+01 | 1531.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=219, polished=true |
| 59 | `baseline` | 1 | 4.2213e+01 | 1682.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 60 | `baseline` | 1 | 4.2214e+01 | 1670.35% | 0 | 0.5000 | method=algebraic, source=imported, candidate=189, polished=true |
| 61 | `baseline` | 1 | 4.2215e+01 | 1595.43% | 0 | 0.5000 | method=algebraic, source=imported, candidate=96, polished=true |
| 62 | `baseline` | 1 | 4.2253e+01 | 2273.60% | 0 | 0.5000 | method=algebraic, source=imported, candidate=11, polished=true |
| 63 | `baseline` | 1 | 4.2261e+01 | 2130.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=97, polished=true |
| 64 | `baseline` | 1 | 4.2285e+01 | 2439.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=78, polished=true |
| 65 | `baseline` | 1 | 4.2303e+01 | 2725.71% | 0 | 0.5000 | method=algebraic, source=imported, candidate=79, polished=true |
| 66 | `baseline` | 1 | 4.2383e+01 | 16395.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=173, polished=true |
| 67 | `branch` | 1 | 4.2383e+01 | 16372.25% | 0 | 0.5000 | method=direct_opt, source=synthesized, candidate=288, polished=true |
| 68 | `baseline` | 1 | 4.2383e+01 | 16354.25% | 0 | 0.5000 | method=algebraic, source=imported, candidate=288, polished=true |
| 69 | `block` | 1 | 4.2383e+01 | 16360.51% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 70 | `baseline` | 1 | 4.2383e+01 | 16315.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=145, polished=true |
| 71 | `baseline` | 1 | 4.2386e+01 | 16573.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=158, polished=true |
| 72 | `baseline` | 1 | 4.2398e+01 | 16000.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=200, polished=true |
| 73 | `baseline` | 1 | 4.2401e+01 | 16707.69% | 0 | 0.5000 | method=algebraic, source=imported, candidate=281, polished=true |
| 74 | `baseline` | 1 | 4.2402e+01 | 16761.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=248, polished=true |
| 75 | `baseline` | 1 | 4.2412e+01 | 15775.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=178, polished=true |
| 76 | `baseline` | 1 | 4.2413e+01 | 16965.36% | 0 | 0.5000 | method=algebraic, source=imported, candidate=147, polished=true |
| 77 | `baseline` | 1 | 4.2419e+01 | 15699.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=236, polished=true |
| 78 | `baseline` | 1 | 4.2419e+01 | 15698.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=237, polished=true |
| 79 | `baseline` | 1 | 4.2423e+01 | 15650.33% | 0 | 0.5000 | method=algebraic, source=imported, candidate=148, polished=true |
| 80 | `baseline` | 1 | 4.2425e+01 | 16905.41% | 0 | 0.5000 | method=algebraic, source=imported, candidate=280, polished=true |
| 81 | `baseline` | 1 | 4.2426e+01 | 15614.02% | 0 | 0.5000 | method=algebraic, source=imported, candidate=144, polished=true |
| 82 | `baseline` | 1 | 4.2428e+01 | 16882.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=238, polished=true |
| 83 | `baseline` | 1 | 4.2431e+01 | 15626.99% | 0 | 0.5000 | method=algebraic, source=imported, candidate=151, polished=true |
| 84 | `baseline` | 1 | 4.2440e+01 | 15479.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=284, polished=true |
| 85 | `baseline` | 1 | 4.2449e+01 | 16851.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=225, polished=true |
| 86 | `baseline` | 1 | 4.2456e+01 | 15341.34% | 0 | 0.5000 | method=algebraic, source=imported, candidate=175, polished=true |
| 87 | `baseline` | 1 | 4.2463e+01 | 15286.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=207, polished=true |
| 88 | `baseline` | 1 | 4.2487e+01 | 17180.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=247, polished=true |
| 89 | `baseline` | 1 | 4.2554e+01 | 5073.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=141, polished=true |
| 90 | `baseline` | 1 | 4.2591e+01 | 5464.73% | 0 | 0.5000 | method=algebraic, source=imported, candidate=146, polished=true |
| 91 | `baseline` | 1 | 4.2627e+01 | 17529.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=117, polished=true |
| 92 | `baseline` | 1 | 4.2632e+01 | 17479.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=290, polished=true |
| 93 | `baseline` | 1 | 4.2635e+01 | 17566.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=152, polished=true |
| 94 | `baseline` | 1 | 4.2640e+01 | 5821.65% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 95 | `baseline` | 1 | 4.2642e+01 | 5979.93% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 96 | `baseline` | 1 | 4.2673e+01 | 6295.07% | 0 | 0.5000 | method=algebraic, source=imported, candidate=25, polished=true |
| 97 | `baseline` | 1 | 4.2712e+01 | 19959.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=160, polished=true |
| 98 | `baseline` | 1 | 4.2953e+01 | 18005.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=256, polished=true |
| 99 | `baseline` | 1 | 4.3433e+01 | 17616.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=223, polished=true |
| 100 | `baseline` | 1 | 4.3477e+01 | 18973.88% | 0 | 0.5000 | method=algebraic, source=imported, candidate=159, polished=true |
| 101 | `block` | 1 | 4.3673e+01 | 18017.53% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 102 | `block` | 1 | 4.3693e+01 | 18029.98% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 103 | `baseline` | 1 | 4.3720e+01 | 42764.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=213, polished=true |
| 104 | `baseline` | 1 | 4.3732e+01 | 46849.12% | 0 | 0.5000 | method=algebraic, source=imported, candidate=266, polished=true |
| 105 | `baseline` | 1 | 4.3760e+01 | 59340.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=130, polished=true |
| 106 | `baseline` | 1 | 4.3770e+01 | 65328.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=268, polished=true |
| 107 | `baseline` | 1 | 4.3782e+01 | 238.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=116, polished=true |
| 108 | `baseline` | 1 | 4.3784e+01 | 75182.30% | 0 | 0.5000 | method=algebraic, source=imported, candidate=182, polished=true |
| 109 | `baseline` | 1 | 4.3819e+01 | 123179.60% | 0 | 0.5000 | method=algebraic, source=imported, candidate=250, polished=true |
| 110 | `baseline` | 1 | 4.3840e+01 | 196620.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=263, polished=true |
| 111 | `baseline` | 1 | 4.3846e+01 | 253463.47% | 0 | 0.5000 | method=algebraic, source=imported, candidate=51, polished=true |
| 112 | `baseline` | 1 | 4.3850e+01 | 299848.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=265, polished=true |
| 113 | `baseline` | 1 | 4.3850e+01 | 300319.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=52, polished=true |
| 114 | `baseline` | 1 | 4.3858e+01 | 470886.66% | 0 | 0.5000 | method=algebraic, source=imported, candidate=153, polished=true |
| 115 | `baseline` | 1 | 4.3859e+01 | 529032.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=243, polished=true |
| 116 | `baseline` | 1 | 4.3860e+01 | 583354.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=20, polished=true |
| 117 | `baseline` | 1 | 4.3861e+01 | 636687.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=19, polished=true |
| 118 | `baseline` | 1 | 4.3862e+01 | 762513.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=59, polished=true |
| 119 | `baseline` | 1 | 4.3866e+01 | 1721927.54% | 0 | 0.5000 | method=algebraic, source=imported, candidate=28, polished=true |
| 120 | `baseline` | 1 | 4.3866e+01 | 1765895.62% | 0 | 0.5000 | method=algebraic, source=imported, candidate=255, polished=true |
| 121 | `baseline` | 1 | 4.3866e+01 | 2655561.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 122 | `baseline` | 1 | 4.3866e+01 | 2868447.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=32, polished=true |
| 123 | `baseline` | 1 | 4.3866e+01 | 5720620.38% | 0 | 0.5000 | method=algebraic, source=imported, candidate=30, polished=true |
| 124 | `baseline` | 1 | 4.3872e+01 | 543196.33% | 0 | 0.5000 | method=algebraic, source=imported, candidate=244, polished=true |
| 125 | `baseline` | 1 | 4.3875e+01 | 488980.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 126 | `baseline` | 1 | 4.3878e+01 | 359820.37% | 0 | 0.5000 | method=algebraic, source=imported, candidate=264, polished=true |
| 127 | `block` | 1 | 4.3941e+01 | 18139.22% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 128 | `baseline` | 1 | 4.4235e+01 | 20427.77% | 0 | 0.5000 | method=algebraic, source=imported, candidate=220, polished=true |
| 129 | `baseline` | 1 | 4.4247e+01 | 66349.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=234, polished=true |
| 130 | `baseline` | 1 | 4.4294e+01 | 59344.77% | 0 | 0.5000 | method=algebraic, source=imported, candidate=231, polished=true |
| 131 | `baseline` | 1 | 4.4335e+01 | 1210.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=70, polished=true |
| 132 | `baseline` | 1 | 4.4405e+01 | 110505.59% | 0 | 0.5000 | method=algebraic, source=imported, candidate=273, polished=true |
| 133 | `baseline` | 1 | 4.4933e+01 | 1768601.98% | 0 | 0.5000 | method=algebraic, source=imported, candidate=254, polished=true |
| 134 | `baseline` | 1 | 4.4958e+01 | 20563.97% | 0 | 0.5000 | method=algebraic, source=imported, candidate=221, polished=true |
| 135 | `baseline` | 1 | 4.9956e+01 | 985135.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=33, polished=true |
| 136 | `baseline` | 1 | 5.0105e+01 | 1550432.86% | 0 | 0.5000 | method=algebraic, source=imported, candidate=24, polished=true |
| 137 | `baseline` | 1 | 5.2184e+01 | 5722504.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=29, polished=true |
| 138 | `baseline` | 1 | 5.4535e+01 | 6777.64% | 0 | 0.5000 | method=algebraic, source=imported, candidate=26, polished=true |
| 139 | `baseline` | 1 | 6.7814e+01 | 2874719.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=31, polished=true |
| 140 | `baseline` | 1 | 7.4413e+01 | 487675.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=22, polished=true |
| 141 | `baseline` | 1 | 8.0210e+01 | 756006.88% | 0 | 0.5000 | method=algebraic, source=imported, candidate=139, polished=true |
| 142 | `baseline` | 1 | 8.5909e+01 | 2658191.09% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 143 | `baseline` | 1 | 9.1018e+01 | 1610.27% | 0 | 0.5000 | method=algebraic, source=imported, candidate=197, polished=true |
| 144 | `baseline` | 1 | 1.0405e+02 | 1656.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=198, polished=true |
| 145 | `baseline` | 1 | 1.1252e+02 | 1705592.07% | 0 | 0.5000 | method=algebraic, source=imported, candidate=27, polished=true |
| 146 | `baseline` | 1 | 1.2983e+02 | 1549626.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=23, polished=true |
| 147 | `baseline` | 1 | 1.4021e+02 | 13250.08% | 0 | 0.5000 | method=algebraic, source=imported, candidate=170, polished=true |
| 148 | `baseline` | 1 | 1.4840e+02 | 2414.87% | 0 | 0.5000 | method=algebraic, source=imported, candidate=76, polished=true |
| 149 | `baseline` | 1 | 2.0710e+02 | 13252.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=171, polished=true |
| 150 | `baseline` | 1 | 3.2543e+02 | 198074.60% | 0 | 0.5000 | method=algebraic, source=imported, candidate=129, polished=true |
| 151 | `baseline` | 1 | 3.2637e+02 | 270616.28% | 0 | 0.5000 | method=algebraic, source=imported, candidate=95, polished=true |
| 152 | `baseline` | 1 | 3.3142e+02 | 3811.42% | 0 | 0.5000 | method=algebraic, source=imported, candidate=210, polished=true |
| 153 | `baseline` | 1 | 3.3220e+02 | 1447.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=69, polished=true |
| 154 | `baseline` | 1 | 3.3966e+02 | 1694.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=72, polished=true |
| 155 | `baseline` | 1 | 3.5384e+02 | 2306.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=88, polished=true |
| 156 | `baseline` | 1 | 3.6953e+02 | 849018.87% | 0 | 0.5000 | method=algebraic, source=imported, candidate=34, polished=true |
| 157 | `block` | 1 | 3.8025e+02 | 15264.65% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 158 | `baseline` | 1 | 3.8870e+02 | 4273.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=209, polished=true |
| 159 | `baseline` | 1 | 4.1715e+02 | 15367.07% | 0 | 0.5000 | method=algebraic, source=imported, candidate=218, polished=true |
| 160 | `baseline` | 1 | 4.1786e+02 | 31922.79% | 0 | 0.5000 | method=algebraic, source=imported, candidate=217, polished=true |
| 161 | `baseline` | 1 | 4.1786e+02 | 30714.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=216, polished=true |
| 162 | `baseline` | 1 | 4.1918e+02 | 15678.68% | 0 | 0.5000 | method=algebraic, source=imported, candidate=215, polished=true |
| 163 | `baseline` | 1 | 4.2040e+02 | 3818.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=211, polished=true |
| 164 | `baseline` | 1 | 4.4280e+02 | 4280.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=208, polished=true |
| 165 | `baseline` | 1 | 4.6814e+02 | 5050.33% | 0 | 0.5000 | method=algebraic, source=imported, candidate=183, polished=true |
| 166 | `baseline` | 1 | 4.9705e+02 | 5046.46% | 0 | 0.5000 | method=algebraic, source=imported, candidate=195, polished=true |
| 167 | `baseline` | 1 | 1.1704e+03 | 15735.80% | 0 | 0.5000 | method=algebraic, source=imported, candidate=131, polished=true |
| 168 | `baseline` | 1 | 1.1738e+03 | 484683.17% | 0 | 0.5000 | method=algebraic, source=imported, candidate=154, polished=true |
| 169 | `baseline` | 1 | 1.4231e+03 | 21133.14% | 0 | 0.5000 | method=algebraic, source=imported, candidate=56, polished=true |
| 170 | `baseline` | 1 | 2.0152e+03 | 781613.81% | 0 | 0.5000 | method=algebraic, source=imported, candidate=60, polished=true |
| 171 | `baseline` | 1 | 2.7030e+03 | 6985.53% | 0 | 0.5000 | method=algebraic, source=imported, candidate=156, polished=true |
| 172 | `baseline` | 1 | 2.7074e+03 | 6986.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=155, polished=true |
| 173 | `baseline` | 1 | 2.8613e+03 | 7496.76% | 0 | 0.5000 | method=algebraic, source=imported, candidate=150, polished=true |
| 174 | `baseline` | 1 | 3.0280e+03 | 7497.09% | 0 | 0.5000 | method=algebraic, source=imported, candidate=149, polished=true |
| 175 | `baseline` | 1 | 3.5533e+03 | 15422.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=126, polished=true |
| 176 | `baseline` | 1 | 4.6880e+03 | 149573.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=138, polished=true |
| 177 | `baseline` | 1 | 4.7362e+03 | 710713.18% | 0 | 0.5000 | method=algebraic, source=imported, candidate=140, polished=true |
| 178 | `baseline` | 1 | 4.7637e+03 | 8851.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=134, polished=true |
| 179 | `baseline` | 1 | 5.0368e+03 | 8851.44% | 0 | 0.5000 | method=algebraic, source=imported, candidate=135, polished=true |
| 180 | `baseline` | 1 | 5.1355e+03 | 9112.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=132, polished=true |
| 181 | `baseline` | 1 | 5.4080e+03 | 9111.66% | 0 | 0.5000 | method=algebraic, source=imported, candidate=133, polished=true |
| 182 | `baseline` | 1 | 5.4138e+03 | 41097.83% | 0 | 0.5000 | method=algebraic, source=imported, candidate=58, polished=true |
| 183 | `block` | 1 | 8.4887e+03 | 36674.30% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 184 | `baseline` | 1 | 8.8361e+03 | 875820.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=125, polished=true |
| 185 | `block` | 1 | 1.1315e+04 | 36672.89% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 186 | `baseline` | 1 | 1.2310e+04 | 79341.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=114, polished=true |
| 187 | `baseline` | 1 | 1.2546e+04 | 875820.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=124, polished=true |
| 188 | `baseline` | 1 | 1.2723e+04 | 165630.13% | 0 | 0.5000 | method=algebraic, source=imported, candidate=105, polished=true |
| 189 | `baseline` | 1 | 1.6972e+04 | 4120.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=68, polished=true |
| 190 | `baseline` | 1 | 1.8713e+04 | 4118.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=67, polished=true |
| 191 | `baseline` | 1 | 2.1929e+04 | 18223.00% | 0 | 0.5000 | method=algebraic, source=imported, candidate=109, polished=true |
| 192 | `baseline` | 1 | 2.1929e+04 | 18206.68% | 0 | 0.5000 | method=algebraic, source=imported, candidate=108, polished=true |
| 193 | `baseline` | 1 | 2.3604e+04 | 165629.03% | 0 | 0.5000 | method=algebraic, source=imported, candidate=104, polished=true |
| 194 | `baseline` | 1 | 2.4056e+04 | 19544.54% | 0 | 0.5000 | method=algebraic, source=imported, candidate=103, polished=true |
| 195 | `baseline` | 1 | 2.4536e+04 | 18409.10% | 0 | 0.5000 | method=algebraic, source=imported, candidate=90, polished=true |
| 196 | `baseline` | 1 | 2.4777e+04 | 19532.98% | 0 | 0.5000 | method=algebraic, source=imported, candidate=102, polished=true |
| 197 | `baseline` | 1 | 2.5258e+04 | 86534.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=99, polished=true |
| 198 | `baseline` | 1 | 2.5955e+04 | 86534.61% | 0 | 0.5000 | method=algebraic, source=imported, candidate=98, polished=true |
| 199 | `baseline` | 1 | 2.7965e+04 | 38873.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=94, polished=true |
| 200 | `baseline` | 1 | 2.7965e+04 | 38865.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=93, polished=true |
| 201 | `baseline` | 1 | 2.9870e+04 | 37484.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=92, polished=true |
| 202 | `baseline` | 1 | 2.9870e+04 | 37478.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=91, polished=true |
| 203 | `baseline` | 1 | 3.0151e+04 | 18388.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=89, polished=true |
| 204 | `baseline` | 1 | 3.1707e+04 | 39585.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=83, polished=true |
| 205 | `baseline` | 1 | 3.3257e+04 | 62575.30% | 0 | 0.5000 | method=algebraic, source=imported, candidate=86, polished=true |
| 206 | `baseline` | 1 | 3.3257e+04 | 62572.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=85, polished=true |
| 207 | `baseline` | 1 | 3.4930e+04 | 39580.63% | 0 | 0.5000 | method=algebraic, source=imported, candidate=84, polished=true |
| 208 | `baseline` | 1 | 3.4984e+04 | 85013.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=82, polished=true |
| 209 | `baseline` | 1 | 3.4984e+04 | 85010.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=81, polished=true |
| 210 | `baseline` | 1 | 3.5072e+04 | 14022.95% | 0 | 0.5000 | method=algebraic, source=imported, candidate=57, polished=true |
| 211 | `baseline` | 1 | 3.5398e+04 | 14963.87% | 0 | 0.5000 | method=algebraic, source=imported, candidate=55, polished=true |
| 212 | `baseline` | 1 | 3.6075e+04 | 176161.90% | 0 | 0.5000 | method=algebraic, source=imported, candidate=66, polished=true |
| 213 | `baseline` | 1 | 3.6075e+04 | 176160.82% | 0 | 0.5000 | method=algebraic, source=imported, candidate=65, polished=true |
| 214 | `baseline` | 1 | 3.6080e+04 | 59513.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=49, polished=true |
| 215 | `baseline` | 1 | 3.6128e+04 | 157516.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=64, polished=true |
| 216 | `baseline` | 1 | 3.6128e+04 | 157515.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=63, polished=true |
| 217 | `block` | 1 | 3.6307e+04 | 29742.38% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 218 | `baseline` | 1 | 3.6492e+04 | 283803.70% | 0 | 0.5000 | method=algebraic, source=imported, candidate=62, polished=true |
| 219 | `baseline` | 1 | 3.6492e+04 | 283803.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=61, polished=true |
| 220 | `baseline` | 1 | 3.7336e+04 | 59370.42% | 0 | 0.5000 | method=algebraic, source=imported, candidate=50, polished=true |
| 221 | `baseline` | 1 | 3.7906e+04 | 403011.59% | 0 | 0.5000 | method=algebraic, source=imported, candidate=47, polished=true |
| 222 | `baseline` | 1 | 3.8433e+04 | 368148.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=54, polished=true |
| 223 | `baseline` | 1 | 3.8433e+04 | 368147.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=53, polished=true |
| 224 | `baseline` | 1 | 3.8973e+04 | 289527.49% | 0 | 0.5000 | method=algebraic, source=imported, candidate=48, polished=true |
| 225 | `baseline` | 1 | 3.9618e+04 | 1329427.71% | 0 | 0.5000 | method=algebraic, source=imported, candidate=46, polished=true |
| 226 | `baseline` | 1 | 3.9687e+04 | 1284505.71% | 0 | 0.5000 | method=algebraic, source=imported, candidate=43, polished=true |
| 227 | `baseline` | 1 | 3.9713e+04 | 1687335.32% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 228 | `baseline` | 1 | 4.0012e+04 | 1308364.21% | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 229 | `baseline` | 1 | 4.0064e+04 | 1281193.28% | 0 | 0.5000 | method=algebraic, source=imported, candidate=44, polished=true |
| 230 | `baseline` | 1 | 4.0107e+04 | 1650821.88% | 0 | 0.5000 | method=algebraic, source=imported, candidate=41, polished=true |
| 231 | `block` | 1 | 4.0131e+04 | 31796.55% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 232 | `block` | 1 | 4.0246e+04 | 17597035.31% | 0 | 0.5000 | method=direct_opt, source=assembled, polished=true |
| 233 | `baseline` | 1 | 4.0308e+04 | 17597035.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=39, polished=true |
| 234 | `baseline` | 1 | 4.0317e+04 | 12661234.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=37, polished=true |
| 235 | `baseline` | 1 | 4.0746e+04 | 503756.39% | 0 | 0.5000 | method=algebraic, source=imported, candidate=36, polished=true |
| 236 | `baseline` | 1 | 4.1049e+04 | 503755.06% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 237 | `baseline` | 1 | 4.8993e+04 | 7102.19% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 238 | `baseline` | 1 | 3.1734e+05 | 7096.29% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 239 | `baseline` | 1 | 6.1289e+05 | 360267.48% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 240 | `baseline` | 1 | 1.3771e+06 | 7348.40% | 0 | 0.5000 | method=algebraic, source=imported, candidate=5, polished=true |
| 241 | `baseline` | 1 | 1.3783e+06 | 7004.72% | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 242 | `baseline` | 1 | 6.9689e+06 | 31954.38% | 0 | 0.5000 | method=algebraic, source=imported, candidate=1, polished=true |
| 243 | `baseline` | 1 | Inf | 12669370.11% | 0 | 0.5000 | method=algebraic, source=imported, candidate=38, polished=true |
| 244 | `baseline` | 1 | Inf | 17659476.84% | 0 | 0.5000 | method=algebraic, source=imported, candidate=40, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 6.9689e+06 | 6.9689e+06 | 31954.38% | 0.065 | `` |
| 2 | `baseline` | 2.0853e+06 | 6.1289e+05 | 360267.48% | 0.366 | `` |
| 3 | `baseline` | 1.8277e+06 | 4.2200e+01 | 1467.45% | 1.507 | `` |
| 4 | `baseline` | 1.8277e+06 | 4.2184e+01 | 793.89% | 1.873 | `` |
| 5 | `baseline` | 1.5368e+06 | 1.3771e+06 | 7348.40% | 0.551 | `` |
| 6 | `baseline` | 1.5368e+06 | 1.3783e+06 | 7004.72% | 0.779 | `` |
| 7 | `baseline` | 1.4401e+06 | 4.2179e+01 | 600.96% | 1.713 | `` |
| 8 | `baseline` | 1.4401e+06 | 4.2213e+01 | 1682.03% | 1.394 | `` |
| 9 | `baseline` | 1.0039e+06 | 3.1734e+05 | 7096.29% | 1.631 | `` |
| 10 | `baseline` | 1.0039e+06 | 4.8993e+04 | 7102.19% | 0.684 | `` |
| 11 | `baseline` | 2.2358e+05 | 4.2253e+01 | 2273.60% | 1.551 | `` |
| 12 | `baseline` | 1.7505e+05 | 8.5909e+01 | 2658191.09% | 1.670 | `` |
| 13 | `baseline` | 1.7505e+05 | 4.3866e+01 | 2655561.72% | 3.076 | `` |
| 14 | `baseline` | 1.1407e+05 | 4.2640e+01 | 5821.65% | 0.925 | `` |
| 15 | `baseline` | 1.1407e+05 | 4.2642e+01 | 5979.93% | 1.881 | `` |
| 16 | `baseline` | 9.8485e+04 | 4.2179e+01 | 620.24% | 1.617 | `` |
| 17 | `baseline` | 9.8485e+04 | 4.2192e+01 | 1319.75% | 1.412 | `` |
| 18 | `baseline` | 6.3183e+04 | 4.2189e+01 | 1266.14% | 1.387 | `` |
| 19 | `baseline` | 5.8657e+04 | 4.3861e+01 | 636687.81% | 2.565 | `` |
| 20 | `baseline` | 5.8657e+04 | 4.3860e+01 | 583354.32% | 1.299 | `` |
| 21 | `baseline` | 5.6873e+04 | 4.3875e+01 | 488980.63% | 1.749 | `` |
| 22 | `baseline` | 5.6873e+04 | 7.4413e+01 | 487675.72% | 1.344 | `` |
| 23 | `baseline` | 5.6225e+04 | 1.2983e+02 | 1549626.70% | 0.738 | `` |
| 24 | `baseline` | 5.6225e+04 | 5.0105e+01 | 1550432.86% | 1.262 | `` |
| 25 | `baseline` | 5.2785e+04 | 4.2673e+01 | 6295.07% | 1.983 | `` |
| 26 | `baseline` | 5.2785e+04 | 5.4535e+01 | 6777.64% | 0.695 | `` |
| 27 | `baseline` | 4.4985e+04 | 1.1252e+02 | 1705592.07% | 1.472 | `` |
| 28 | `baseline` | 4.4985e+04 | 4.3866e+01 | 1721927.54% | 2.983 | `` |
| 29 | `baseline` | 4.4604e+04 | 5.2184e+01 | 5722504.70% | 2.811 | `` |
| 30 | `baseline` | 4.4604e+04 | 4.3866e+01 | 5720620.38% | 2.159 | `` |
| 31 | `baseline` | 4.1451e+04 | 6.7814e+01 | 2874719.45% | 1.726 | `` |
| 32 | `baseline` | 4.1451e+04 | 4.3866e+01 | 2868447.17% | 3.153 | `` |
| 33 | `baseline` | 4.1397e+04 | 4.9956e+01 | 985135.83% | 2.669 | `` |
| 34 | `baseline` | 4.1397e+04 | 3.6953e+02 | 849018.87% | 3.430 | `` |
| 35 | `baseline` | 4.1049e+04 | 4.1049e+04 | 503755.06% | 0.151 | `` |
| 36 | `baseline` | 4.1049e+04 | 4.0746e+04 | 503756.39% | 0.389 | `` |
| 37 | `baseline` | 4.0317e+04 | 4.0317e+04 | 12661234.85% | 0.076 | `` |
| 38 | `baseline` | Inf | Inf | 12669370.11% | 0.078 | `` |
| 39 | `baseline` | 4.0308e+04 | 4.0308e+04 | 17597035.31% | 0.068 | `` |
| 40 | `baseline` | Inf | Inf | 17659476.84% | 0.067 | `` |
| 41 | `baseline` | 4.0228e+04 | 4.0107e+04 | 1650821.88% | 0.476 | `` |
| 42 | `baseline` | 4.0228e+04 | 3.9713e+04 | 1687335.32% | 1.236 | `` |
| 43 | `baseline` | 4.0217e+04 | 3.9687e+04 | 1284505.71% | 0.907 | `` |
| 44 | `baseline` | 4.0217e+04 | 4.0064e+04 | 1281193.28% | 0.489 | `` |
| 45 | `baseline` | 4.0204e+04 | 4.0012e+04 | 1308364.21% | 0.452 | `` |
| 46 | `baseline` | 4.0204e+04 | 3.9618e+04 | 1329427.71% | 0.829 | `` |
| 47 | `baseline` | 3.9856e+04 | 3.7906e+04 | 403011.59% | 1.404 | `` |
| 48 | `baseline` | 3.9856e+04 | 3.8973e+04 | 289527.49% | 0.416 | `` |
| 49 | `baseline` | 3.9137e+04 | 3.6080e+04 | 59513.89% | 0.848 | `` |
| 50 | `baseline` | 3.9137e+04 | 3.7336e+04 | 59370.42% | 0.524 | `` |
| 51 | `baseline` | 3.8538e+04 | 4.3846e+01 | 253463.47% | 1.935 | `` |
| 52 | `baseline` | 3.8538e+04 | 4.3850e+01 | 300319.03% | 1.174 | `` |
| 53 | `baseline` | 3.8433e+04 | 3.8433e+04 | 368147.92% | 0.077 | `` |
| 54 | `baseline` | 3.8433e+04 | 3.8433e+04 | 368148.52% | 0.124 | `` |
| 55 | `baseline` | 3.7791e+04 | 3.5398e+04 | 14963.87% | 1.099 | `` |
| 56 | `baseline` | 3.7791e+04 | 1.4231e+03 | 21133.14% | 2.562 | `` |
| 57 | `baseline` | 3.7701e+04 | 3.5072e+04 | 14022.95% | 1.091 | `` |
| 58 | `baseline` | 3.7701e+04 | 5.4138e+03 | 41097.83% | 3.136 | `` |
| 59 | `baseline` | 3.6740e+04 | 4.3862e+01 | 762513.20% | 2.024 | `` |
| 60 | `baseline` | 3.6719e+04 | 2.0152e+03 | 781613.81% | 1.468 | `` |
| 61 | `baseline` | 3.6492e+04 | 3.6492e+04 | 283803.01% | 0.088 | `` |
| 62 | `baseline` | 3.6492e+04 | 3.6492e+04 | 283803.70% | 0.106 | `` |
| 63 | `baseline` | 3.6128e+04 | 3.6128e+04 | 157515.19% | 0.061 | `` |
| 64 | `baseline` | 3.6128e+04 | 3.6128e+04 | 157516.52% | 0.113 | `` |
| 65 | `baseline` | 3.6075e+04 | 3.6075e+04 | 176160.82% | 0.087 | `` |
| 66 | `baseline` | 3.6075e+04 | 3.6075e+04 | 176161.90% | 0.063 | `` |
| 67 | `baseline` | 3.6015e+04 | 1.8713e+04 | 4118.91% | 1.737 | `` |
| 68 | `baseline` | 3.6015e+04 | 1.6972e+04 | 4120.63% | 1.806 | `` |
| 69 | `baseline` | 3.5979e+04 | 3.3220e+02 | 1447.01% | 1.255 | `` |
| 70 | `baseline` | 3.5691e+04 | 4.4335e+01 | 1210.03% | 1.452 | `` |
| 71 | `baseline` | 3.5691e+04 | 4.2187e+01 | 853.64% | 1.656 | `` |
| 72 | `baseline` | 3.5821e+04 | 3.3966e+02 | 1694.84% | 1.305 | `` |
| 73 | `baseline` | 3.5490e+04 | 4.2192e+01 | 988.05% | 1.569 | `` |
| 74 | `baseline` | 3.5288e+04 | 1.4840e+02 | 2414.87% | 1.360 | `` |
| 75 | `baseline` | 3.5212e+04 | 4.2186e+01 | 838.73% | 1.601 | `` |
| 76 | `baseline` | 3.5088e+04 | 4.2285e+01 | 2439.48% | 1.754 | `` |
| 77 | `baseline` | 3.5088e+04 | 4.2303e+01 | 2725.71% | 1.592 | `` |
| 78 | `baseline` | 3.5032e+04 | 4.2183e+01 | 752.69% | 1.586 | `` |
| 79 | `baseline` | 3.4984e+04 | 3.4984e+04 | 85010.94% | 0.110 | `` |
| 80 | `baseline` | 3.4984e+04 | 3.4984e+04 | 85013.20% | 0.148 | `` |
| 81 | `baseline` | 3.4930e+04 | 3.1707e+04 | 39585.06% | 0.287 | `` |
| 82 | `baseline` | 3.4930e+04 | 3.4930e+04 | 39580.63% | 0.098 | `` |
| 83 | `baseline` | 3.3257e+04 | 3.3257e+04 | 62572.90% | 0.135 | `` |
| 84 | `baseline` | 3.3257e+04 | 3.3257e+04 | 62575.30% | 0.108 | `` |
| 85 | `baseline` | 3.3015e+04 | 4.2196e+01 | 1083.64% | 1.629 | `` |
| 86 | `baseline` | 3.2624e+04 | 3.5384e+02 | 2306.46% | 1.292 | `` |
| 87 | `baseline` | 3.0151e+04 | 3.0151e+04 | 18388.95% | 0.122 | `` |
| 88 | `baseline` | 3.0151e+04 | 2.4536e+04 | 18409.10% | 0.240 | `` |
| 89 | `baseline` | 2.9870e+04 | 2.9870e+04 | 37478.94% | 0.130 | `` |
| 90 | `baseline` | 2.9870e+04 | 2.9870e+04 | 37484.52% | 0.109 | `` |
| 91 | `baseline` | 2.7965e+04 | 2.7965e+04 | 38865.49% | 0.123 | `` |
| 92 | `baseline` | 2.7965e+04 | 2.7965e+04 | 38873.89% | 0.145 | `` |
| 93 | `baseline` | 2.7570e+04 | 3.2637e+02 | 270616.28% | 0.981 | `` |
| 94 | `baseline` | 2.6996e+04 | 4.2215e+01 | 1595.43% | 2.004 | `` |
| 95 | `baseline` | 2.6996e+04 | 4.2261e+01 | 2130.49% | 2.130 | `` |
| 96 | `baseline` | 2.5955e+04 | 2.5955e+04 | 86534.61% | 0.079 | `` |
| 97 | `baseline` | 2.5258e+04 | 2.5258e+04 | 86534.84% | 0.078 | `` |
| 98 | `baseline` | 2.5174e+04 | 4.3682e+01 | 28325.18% | 1.639 | `` |
| 99 | `baseline` | 2.5174e+04 | 4.3682e+01 | 28351.97% | 1.828 | `` |
| 100 | `baseline` | 2.4777e+04 | 2.4777e+04 | 19532.98% | 0.117 | `` |
| 101 | `baseline` | 2.4777e+04 | 2.4056e+04 | 19544.54% | 0.160 | `` |
| 102 | `baseline` | 2.3604e+04 | 2.3604e+04 | 165629.03% | 0.416 | `` |
| 103 | `baseline` | 2.3604e+04 | 1.2723e+04 | 165630.13% | 0.175 | `` |
| 104 | `baseline` | 2.3539e+04 | 4.3682e+01 | 28325.19% | 1.758 | `` |
| 105 | `baseline` | 2.3539e+04 | 4.3682e+01 | 28351.97% | 1.828 | `` |
| 106 | `baseline` | 2.1929e+04 | 2.1929e+04 | 18206.68% | 0.107 | `` |
| 107 | `baseline` | 2.1929e+04 | 2.1929e+04 | 18223.00% | 0.132 | `` |
| 108 | `baseline` | 2.1166e+04 | 4.2190e+01 | 1285.20% | 1.448 | `` |
| 109 | `baseline` | 1.7627e+04 | 4.3682e+01 | 28325.19% | 1.949 | `` |
| 110 | `baseline` | 1.7627e+04 | 4.3682e+01 | 28351.97% | 1.642 | `` |
| 111 | `baseline` | 1.7574e+04 | 4.2188e+01 | 1248.57% | 1.396 | `` |
| 112 | `baseline` | 1.7022e+04 | 1.2310e+04 | 79341.91% | 0.164 | `` |
| 113 | `baseline` | 1.6313e+04 | 4.2172e+01 | 241.87% | 1.347 | `` |
| 114 | `baseline` | 1.6313e+04 | 4.3782e+01 | 238.72% | 1.473 | `` |
| 115 | `baseline` | 1.5781e+04 | 4.2627e+01 | 17529.81% | 1.798 | `` |
| 116 | `baseline` | 1.5781e+04 | 4.3682e+01 | 28325.19% | 2.430 | `` |
| 117 | `baseline` | 1.3817e+04 | 4.2181e+01 | 665.04% | 1.630 | `` |
| 118 | `baseline` | 1.3469e+04 | 4.3682e+01 | 28325.19% | 1.970 | `` |
| 119 | `baseline` | 1.3469e+04 | 4.3682e+01 | 28351.97% | 1.558 | `` |
| 120 | `baseline` | 1.2754e+04 | 4.3682e+01 | 28351.97% | 1.675 | `` |
| 121 | `baseline` | 1.2754e+04 | 4.3682e+01 | 28325.19% | 1.963 | `` |
| 122 | `baseline` | 1.2546e+04 | 1.2546e+04 | 875820.20% | 0.068 | `` |
| 123 | `baseline` | 1.2517e+04 | 8.8361e+03 | 875820.01% | 0.691 | `` |
| 124 | `baseline` | 3.5533e+03 | 3.5533e+03 | 15422.85% | 0.084 | `` |
| 125 | `baseline` | 9.1848e+03 | 4.2185e+01 | 1211.77% | 1.543 | `` |
| 126 | `baseline` | 9.1848e+03 | 4.2180e+01 | 636.02% | 1.609 | `` |
| 127 | `baseline` | 8.6819e+03 | 3.2543e+02 | 198074.60% | 0.719 | `` |
| 128 | `baseline` | 8.6819e+03 | 4.3760e+01 | 59340.39% | 1.797 | `` |
| 129 | `baseline` | 1.1704e+03 | 1.1704e+03 | 15735.80% | 0.041 | `` |
| 130 | `baseline` | 5.5309e+03 | 5.1355e+03 | 9112.13% | 1.597 | `` |
| 131 | `baseline` | 5.5309e+03 | 5.4080e+03 | 9111.66% | 1.580 | `` |
| 132 | `baseline` | 5.1958e+03 | 4.7637e+03 | 8851.91% | 1.751 | `` |
| 133 | `baseline` | 5.1958e+03 | 5.0368e+03 | 8851.44% | 1.612 | `` |
| 134 | `baseline` | 4.8991e+03 | 4.2181e+01 | 679.25% | 1.581 | `` |
| 135 | `baseline` | 4.6880e+03 | 4.3682e+01 | 28351.97% | 1.601 | `` |
| 136 | `baseline` | 4.6880e+03 | 4.6880e+03 | 149573.78% | 0.331 | `` |
| 137 | `baseline` | 4.7362e+03 | 8.0210e+01 | 756006.88% | 1.333 | `` |
| 138 | `baseline` | 4.7362e+03 | 4.7362e+03 | 710713.18% | 0.269 | `` |
| 139 | `baseline` | 4.6605e+03 | 4.2554e+01 | 5073.95% | 0.456 | `` |
| 140 | `baseline` | 4.5900e+03 | 4.2186e+01 | 1223.31% | 1.411 | `` |
| 141 | `baseline` | 4.5900e+03 | 4.2180e+01 | 641.63% | 1.593 | `` |
| 142 | `baseline` | 4.4946e+03 | 4.2426e+01 | 15614.02% | 1.608 | `` |
| 143 | `baseline` | 4.4946e+03 | 4.2383e+01 | 16315.92% | 1.477 | `` |
| 144 | `baseline` | 4.3390e+03 | 4.2591e+01 | 5464.73% | 1.932 | `` |
| 145 | `baseline` | 3.8887e+03 | 4.2413e+01 | 16965.36% | 1.554 | `` |
| 146 | `baseline` | 3.8887e+03 | 4.2423e+01 | 15650.33% | 1.519 | `` |
| 147 | `baseline` | 3.4009e+03 | 3.0280e+03 | 7497.09% | 1.532 | `` |
| 148 | `baseline` | 3.4009e+03 | 2.8613e+03 | 7496.76% | 1.525 | `` |
| 149 | `baseline` | 3.0077e+03 | 4.2431e+01 | 15626.99% | 2.153 | `` |
| 150 | `baseline` | 3.0077e+03 | 4.2635e+01 | 17566.39% | 2.050 | `` |
| 151 | `baseline` | 2.8944e+03 | 4.3858e+01 | 470886.66% | 1.985 | `` |
| 152 | `baseline` | 2.8944e+03 | 1.1738e+03 | 484683.17% | 1.056 | `` |
| 153 | `baseline` | 2.8417e+03 | 2.7074e+03 | 6986.39% | 1.627 | `` |
| 154 | `baseline` | 2.8417e+03 | 2.7030e+03 | 6985.53% | 1.525 | `` |
| 155 | `baseline` | 2.1196e+03 | 4.2182e+01 | 728.19% | 1.731 | `` |
| 156 | `baseline` | 2.1196e+03 | 4.2386e+01 | 16573.19% | 1.523 | `` |
| 157 | `baseline` | 1.9891e+03 | 4.3477e+01 | 18973.88% | 1.528 | `` |
| 158 | `baseline` | 1.9891e+03 | 4.2712e+01 | 19959.64% | 1.577 | `` |
| 159 | `baseline` | 1.9177e+03 | 4.3682e+01 | 28325.18% | 1.593 | `` |
| 160 | `baseline` | 1.9177e+03 | 4.3682e+01 | 28351.97% | 1.424 | `` |
| 161 | `baseline` | 1.7926e+03 | 4.3682e+01 | 28351.97% | 1.667 | `` |
| 162 | `baseline` | 1.7926e+03 | 4.3682e+01 | 28325.19% | 1.937 | `` |
| 163 | `baseline` | 1.7923e+03 | 4.3682e+01 | 28325.19% | 1.250 | `` |
| 164 | `baseline` | 1.7923e+03 | 4.3682e+01 | 28351.97% | 1.653 | `` |
| 165 | `baseline` | 1.5226e+03 | 4.2189e+01 | 1278.43% | 1.367 | `` |
| 166 | `baseline` | 1.5123e+03 | 4.3682e+01 | 28351.97% | 1.664 | `` |
| 167 | `baseline` | 1.5123e+03 | 4.3682e+01 | 28325.19% | 1.156 | `` |
| 168 | `baseline` | 1.3970e+03 | 1.4021e+02 | 13250.08% | 1.360 | `` |
| 169 | `baseline` | 1.3970e+03 | 2.0710e+02 | 13252.89% | 1.595 | `` |
| 170 | `baseline` | 1.3841e+03 | 4.2456e+01 | 15341.34% | 1.523 | `` |
| 171 | `baseline` | 1.3967e+03 | 4.2383e+01 | 16395.85% | 2.082 | `` |
| 172 | `baseline` | 1.3841e+03 | 4.2383e+01 | 16405.78% | 1.559 | `` |
| 173 | `baseline` | 1.2161e+03 | 4.2180e+01 | 622.25% | 1.580 | `` |
| 174 | `baseline` | 1.0612e+03 | 4.2180e+01 | 648.59% | 1.562 | `` |
| 175 | `baseline` | 1.0010e+03 | 4.2412e+01 | 15775.78% | 1.525 | `` |
| 176 | `baseline` | 1.0010e+03 | 4.2383e+01 | 16405.78% | 1.403 | `` |
| 177 | `baseline` | 9.8873e+02 | 4.2180e+01 | 658.76% | 1.546 | `` |
| 178 | `baseline` | 9.3026e+02 | 4.3682e+01 | 28351.97% | 1.533 | `` |
| 179 | `baseline` | 9.3026e+02 | 4.3784e+01 | 75182.30% | 1.460 | `` |
| 180 | `baseline` | 8.9082e+02 | 4.6814e+02 | 5050.33% | 1.715 | `` |
| 181 | `baseline` | 7.9976e+02 | 4.2187e+01 | 1040.83% | 1.453 | `` |
| 182 | `baseline` | 7.9976e+02 | 4.2189e+01 | 907.96% | 1.575 | `` |
| 183 | `baseline` | 7.0820e+02 | 4.2181e+01 | 683.97% | 1.570 | `` |
| 184 | `baseline` | 7.0820e+02 | 4.2186e+01 | 1216.15% | 1.428 | `` |
| 185 | `baseline` | 6.1046e+02 | 4.2198e+01 | 1431.44% | 1.359 | `` |
| 186 | `baseline` | 5.8884e+02 | 4.2214e+01 | 1670.35% | 1.331 | `` |
| 187 | `baseline` | 5.4610e+02 | 4.2180e+01 | 640.04% | 1.571 | `` |
| 188 | `baseline` | 5.3934e+02 | 4.2180e+01 | 628.41% | 1.548 | `` |
| 189 | `baseline` | 5.3858e+02 | 4.3682e+01 | 28325.19% | 1.570 | `` |
| 190 | `baseline` | 5.3472e+02 | 4.3682e+01 | 28351.96% | 0.402 | `` |
| 191 | `baseline` | 5.3219e+02 | 4.2179e+01 | 609.72% | 1.571 | `` |
| 192 | `baseline` | 5.2513e+02 | 4.9705e+02 | 5046.46% | 0.271 | `` |
| 193 | `baseline` | 5.1306e+02 | 4.2179e+01 | 619.62% | 1.803 | `` |
| 194 | `baseline` | 5.0654e+02 | 9.1018e+01 | 1610.27% | 1.703 | `` |
| 195 | `baseline` | 5.0579e+02 | 1.0405e+02 | 1656.03% | 1.241 | `` |
| 196 | `baseline` | 4.9943e+02 | 4.2383e+01 | 16405.78% | 1.585 | `` |
| 197 | `baseline` | 4.9943e+02 | 4.2398e+01 | 16000.45% | 1.521 | `` |
| 198 | `baseline` | 4.9185e+02 | 4.3682e+01 | 28351.97% | 1.676 | `` |
| 199 | `baseline` | 4.9185e+02 | 4.3682e+01 | 28325.19% | 1.568 | `` |
| 200 | `baseline` | 4.9052e+02 | 4.3682e+01 | 28325.19% | 1.704 | `` |
| 201 | `baseline` | 4.9052e+02 | 4.3682e+01 | 28351.97% | 1.632 | `` |
| 202 | `baseline` | 4.8547e+02 | 4.2179e+01 | 597.15% | 1.575 | `` |
| 203 | `baseline` | 4.8426e+02 | 4.2186e+01 | 1210.03% | 1.391 | `` |
| 204 | `baseline` | 4.8426e+02 | 4.2463e+01 | 15286.00% | 1.576 | `` |
| 205 | `baseline` | 4.7309e+02 | 4.4280e+02 | 4280.85% | 1.532 | `` |
| 206 | `baseline` | 4.6783e+02 | 3.8870e+02 | 4273.63% | 0.471 | `` |
| 207 | `baseline` | 4.5945e+02 | 3.3142e+02 | 3811.42% | 0.933 | `` |
| 208 | `baseline` | 4.5573e+02 | 4.2040e+02 | 3818.95% | 1.527 | `` |
| 209 | `baseline` | 4.4630e+02 | 4.2181e+01 | 656.34% | 1.574 | `` |
| 210 | `baseline` | 4.2477e+02 | 4.3720e+01 | 42764.48% | 0.429 | `` |
| 211 | `baseline` | 4.2477e+02 | 4.3682e+01 | 28351.97% | 1.323 | `` |
| 212 | `baseline` | 4.1918e+02 | 4.1918e+02 | 15678.68% | 0.371 | `` |
| 213 | `baseline` | 4.1787e+02 | 4.1786e+02 | 30714.01% | 0.553 | `` |
| 214 | `baseline` | 4.1786e+02 | 4.1786e+02 | 31922.79% | 0.961 | `` |
| 215 | `baseline` | 4.1715e+02 | 4.1715e+02 | 15367.07% | 0.321 | `` |
| 216 | `baseline` | 4.0415e+02 | 4.2204e+01 | 1531.06% | 1.332 | `` |
| 217 | `baseline` | 3.7639e+02 | 4.4235e+01 | 20427.77% | 1.557 | `` |
| 218 | `baseline` | 3.7639e+02 | 4.4958e+01 | 20563.97% | 1.503 | `` |
| 219 | `baseline` | 3.6898e+02 | 4.2383e+01 | 16405.78% | 1.024 | `` |
| 220 | `baseline` | 3.6898e+02 | 4.3433e+01 | 17616.85% | 0.474 | `` |
| 221 | `baseline` | 3.5785e+02 | 4.2383e+01 | 16405.78% | 1.386 | `` |
| 222 | `baseline` | 3.5785e+02 | 4.2449e+01 | 16851.89% | 2.060 | `` |
| 223 | `baseline` | 3.5580e+02 | 4.2383e+01 | 16405.78% | 1.700 | `` |
| 224 | `baseline` | 2.8808e+02 | 4.2173e+01 | 6783.44% | 1.475 | `` |
| 225 | `baseline` | 2.8808e+02 | 4.2176e+01 | 452.20% | 1.483 | `` |
| 226 | `baseline` | 3.4391e+02 | 4.2383e+01 | 16405.78% | 1.591 | `` |
| 227 | `baseline` | 3.4043e+02 | 4.2183e+01 | 1179.82% | 1.388 | `` |
| 228 | `baseline` | 3.0706e+02 | 4.4294e+01 | 59344.77% | 0.238 | `` |
| 229 | `baseline` | 3.0706e+02 | 4.3682e+01 | 28351.97% | 0.621 | `` |
| 230 | `baseline` | 2.9161e+02 | 4.2184e+01 | 1188.53% | 1.393 | `` |
| 231 | `baseline` | 2.7749e+02 | 4.4247e+01 | 66349.46% | 0.261 | `` |
| 232 | `baseline` | 2.7749e+02 | 4.3682e+01 | 28351.97% | 1.675 | `` |
| 233 | `baseline` | 2.5253e+02 | 4.2419e+01 | 15699.53% | 1.531 | `` |
| 234 | `baseline` | 2.4383e+02 | 4.2419e+01 | 15698.46% | 1.477 | `` |
| 235 | `baseline` | 2.2958e+02 | 4.2428e+01 | 16882.90% | 1.467 | `` |
| 236 | `baseline` | 2.0690e+02 | 4.3682e+01 | 28325.19% | 1.803 | `` |
| 237 | `baseline` | 2.0281e+02 | 4.3682e+01 | 28325.19% | 1.931 | `` |
| 238 | `baseline` | 1.9815e+02 | 4.2184e+01 | 1197.73% | 1.375 | `` |
| 239 | `baseline` | 1.9272e+02 | 4.2185e+01 | 1211.49% | 1.395 | `` |
| 240 | `baseline` | 1.7934e+02 | 4.3859e+01 | 529032.20% | 1.959 | `` |
| 241 | `baseline` | 1.7934e+02 | 4.3872e+01 | 543196.33% | 0.356 | `` |
| 242 | `baseline` | 1.5390e+02 | 4.3682e+01 | 28351.97% | 0.652 | `` |
| 243 | `baseline` | 1.5368e+02 | 4.3682e+01 | 28351.97% | 1.659 | `` |
| 244 | `baseline` | 1.4420e+02 | 4.2487e+01 | 17180.72% | 1.484 | `` |
| 245 | `baseline` | 1.4420e+02 | 4.2402e+01 | 16761.39% | 1.467 | `` |
| 246 | `baseline` | 1.3880e+02 | 4.3682e+01 | 28351.97% | 0.662 | `` |
| 247 | `baseline` | 1.3880e+02 | 4.3819e+01 | 123179.60% | 1.792 | `` |
| 248 | `baseline` | 1.2647e+02 | 4.3682e+01 | 28351.97% | 1.627 | `` |
| 249 | `baseline` | 1.2038e+02 | 4.3682e+01 | 28325.19% | 1.258 | `` |
| 250 | `baseline` | 1.2038e+02 | 4.3682e+01 | 28351.97% | 1.658 | `` |
| 251 | `baseline` | 1.1651e+02 | 4.4933e+01 | 1768601.98% | 0.383 | `` |
| 252 | `baseline` | 1.1651e+02 | 4.3866e+01 | 1765895.62% | 2.535 | `` |
| 253 | `baseline` | 1.1747e+02 | 4.2953e+01 | 18005.39% | 1.490 | `` |
| 254 | `baseline` | 1.1432e+02 | 4.2183e+01 | 1179.78% | 1.406 | `` |
| 255 | `baseline` | 1.1432e+02 | 4.2179e+01 | 596.44% | 1.573 | `` |
| 256 | `baseline` | 1.1492e+02 | 4.3682e+01 | 28351.97% | 1.403 | `` |
| 257 | `baseline` | 1.1108e+02 | 4.3682e+01 | 28351.97% | 1.459 | `` |
| 258 | `baseline` | 1.1108e+02 | 4.3682e+01 | 28325.19% | 1.918 | `` |
| 259 | `baseline` | 1.1085e+02 | 4.3682e+01 | 28325.19% | 1.713 | `` |
| 260 | `baseline` | 1.1085e+02 | 4.3840e+01 | 196620.72% | 0.425 | `` |
| 261 | `baseline` | 1.0863e+02 | 4.3878e+01 | 359820.37% | 0.305 | `` |
| 262 | `baseline` | 1.0863e+02 | 4.3850e+01 | 299848.48% | 1.971 | `` |
| 263 | `baseline` | 1.1004e+02 | 4.3732e+01 | 46849.12% | 1.119 | `` |
| 264 | `baseline` | 1.1004e+02 | 4.3682e+01 | 28351.97% | 1.546 | `` |
| 265 | `baseline` | 1.0355e+02 | 4.3770e+01 | 65328.46% | 0.974 | `` |
| 266 | `baseline` | 1.0355e+02 | 4.3682e+01 | 28351.97% | 1.624 | `` |
| 267 | `baseline` | 9.1517e+01 | 4.2180e+01 | 638.35% | 1.582 | `` |
| 268 | `baseline` | 9.0363e+01 | 4.2180e+01 | 631.90% | 1.588 | `` |
| 269 | `baseline` | 7.7243e+01 | 4.3682e+01 | 28325.18% | 1.673 | `` |
| 270 | `baseline` | 7.7243e+01 | 4.4405e+01 | 110505.59% | 0.277 | `` |
| 271 | `baseline` | 7.6830e+01 | 4.2186e+01 | 1221.30% | 1.646 | `` |
| 272 | `baseline` | 7.5479e+01 | 4.3682e+01 | 28325.19% | 1.911 | `` |
| 273 | `baseline` | 7.2040e+01 | 4.3682e+01 | 28351.97% | 1.140 | `` |
| 274 | `baseline` | 7.2040e+01 | 4.3682e+01 | 28325.18% | 1.676 | `` |
| 275 | `baseline` | 6.9564e+01 | 4.2185e+01 | 1209.44% | 1.426 | `` |
| 276 | `baseline` | 6.9564e+01 | 4.2179e+01 | 613.83% | 1.653 | `` |
| 277 | `baseline` | 6.7603e+01 | 4.2425e+01 | 16905.41% | 1.587 | `` |
| 278 | `baseline` | 6.7603e+01 | 4.2401e+01 | 16707.69% | 1.543 | `` |
| 279 | `baseline` | 6.9854e+01 | 4.2184e+01 | 1197.90% | 1.376 | `` |
| 280 | `baseline` | 6.9854e+01 | 4.2179e+01 | 606.55% | 1.531 | `` |
| 281 | `baseline` | 6.5668e+01 | 4.2440e+01 | 15479.89% | 1.535 | `` |
| 282 | `baseline` | 6.5668e+01 | 4.2383e+01 | 16405.78% | 1.400 | `` |
| 283 | `baseline` | 6.2167e+01 | 4.3682e+01 | 28325.19% | 1.877 | `` |
| 284 | `baseline` | 6.2146e+01 | 4.3682e+01 | 28351.97% | 1.624 | `` |
| 285 | `baseline` | 6.2753e+01 | 4.2383e+01 | 16354.25% | 1.468 | `` |
| 286 | `baseline` | 6.2753e+01 | 4.2383e+01 | 16405.78% | 1.045 | `` |
| 287 | `baseline` | 5.8289e+01 | 4.2632e+01 | 17479.48% | 1.520 | `` |
| 288 | `baseline` | 5.6793e+01 | 4.3682e+01 | 28325.19% | 1.710 | `` |
| 289 | `baseline` | 5.6793e+01 | 4.3682e+01 | 28351.97% | 1.442 | `` |
| 290 | `baseline` | 5.3233e+01 | 4.3682e+01 | 28351.97% | 0.629 | `` |
| 291 | `baseline` | 5.3220e+01 | 4.3682e+01 | 28325.19% | 0.761 | `` |
| 292 | `baseline` | 5.2339e+01 | 4.2178e+01 | 573.36% | 1.532 | `` |
| 293 | `baseline` | 5.2339e+01 | 4.2184e+01 | 1194.05% | 1.375 | `` |
| 294 | `baseline` | 4.6701e+01 | 4.3682e+01 | 28325.19% | 2.341 | `` |
| 295 | `baseline` | 4.6701e+01 | 4.3682e+01 | 28351.97% | 2.004 | `` |
| 296 | `block` | 5.2075e+04 | 4.2383e+01 | 16360.51% | 1.470 | `` |
| 297 | `synthesized` | 4.2390e+01 | 4.2182e+01 | 1168.72% | 1.388 | `` |
| 298 | `branch` | 4.2398e+01 | 4.2383e+01 | 16372.25% | 1.525 | `` |
| 299 | `synthesized` | 4.2332e+01 | 4.2181e+01 | 1166.05% | 1.366 | `` |
| 300 | `block` | 8.4887e+03 | 8.4887e+03 | 36674.30% | 0.097 | `` |
| 301 | `branch` | 4.2530e+01 | 4.2182e+01 | 1171.11% | 1.354 | `` |
| 302 | `synthesized` | 4.2475e+01 | 4.2182e+01 | 1174.02% | 1.386 | `` |
| 303 | `block` | 4.0246e+04 | 4.0246e+04 | 17597035.31% | 0.066 | `` |
| 304 | `block` | 4.0158e+04 | 4.3673e+01 | 18017.53% | 2.990 | `` |
| 305 | `block` | 4.0302e+04 | 4.3941e+01 | 18139.22% | 3.302 | `` |
| 306 | `block` | 4.0321e+04 | 3.6307e+04 | 29742.38% | 4.673 | `` |
| 307 | `block` | 4.0308e+04 | 4.0131e+04 | 31796.55% | 1.567 | `` |
| 308 | `block` | 6.7229e+04 | 4.3693e+01 | 18029.98% | 2.820 | `` |
| 309 | `block` | 7.4130e+07 | 3.8025e+02 | 15264.65% | 1.884 | `` |
| 310 | `block` | 6.8808e+07 | 1.1315e+04 | 36672.89% | 0.703 | `` |

