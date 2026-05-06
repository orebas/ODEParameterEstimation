# Tryhard Finalist Benchmark Case: slow_fast_2_1em4

- Model: `slow_fast`
- Role: `guard`
- Selected via: `family_priority`
- Generated: `2026-04-14T12:37:19.379`
- Status: `ok`
- Nopolish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/slow_fast_2_1em4`
- Polish case dir: `/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_polish/slow_fast_2_1em4`

## Comparison-Table Reference

- Classification: `both_success`
- Comparison CSV ODEPE mean/max relative error: 0.02% / 0.08%
- Comparison CSV ODEPE runtime: 6204.125 s

## Benchmark References

| Strategy | Candidate Count | Combined RMSE | Worst Error | Fit Error |
|----------|-----------------|---------------|-------------|-----------|
| `odepe_nopolish` | 280 | 0.03% | k1 (0.07%) | 9.2429e-05 |
| `odepe_polish` | 541 | 0.06% | k1 (0.14%) | 8.8307e-05 |

## Imported Raw Pool

- Raw imported candidates: 280
- Best raw fit index: 279
- Best raw oracle index: 279
- Best-fit vs best-truth combined-RMSE gap: 0.00%

## Local Tryhard Runtime

- Reference CSV load/scoring: 5.442 s
- Consensus/block context: 16.961 s
- 4x4 baseline evidence report: 103.491 s
- 4x4 block no-polish report: 5.906 s
- Polish context build: 0.019 s
- Baseline-only finalists: 260.144 s
- Additive-only finalists: 278.241 s
- Reasonable frontier finalists: 261.366 s
- Local total (excluding reference load): 1879.043 s

## Local Policy Comparison

| Strategy | Status | Ranked Best RMSE | Best Finalist In Set | Finalists | Winner Sources | Fit Error | Notes |
|----------|--------|------------------|----------------------|-----------|----------------|-----------|-------|
| `best imported raw` | `ok` | 0.03% | 0.03% | 257 | `raw` | 9.2429e-05 | benchmark nopolish best-fit reference |
| `benchmark odepe_polish` | `ok` | 0.06% | 0.06% | 541 | `benchmark` | 8.8307e-05 | saved benchmark polished reference |
| `block_v2_no_polish_4x4` | `ok` | 9.96% | 9.96% | 271 | `block` | 1.0587e-01 | best block seed before polish |
| `baseline_polish_finalists` | `ok` | 1130.42% | 0.01% | 31 | `baseline` | 8.8291e-05 | baseline standard-polish declustered seeds only |
| `additive_generator_finalists` | `ok` | 1130.42% | 0.01% | 43 | `branch` | 8.8291e-05 | all additive generator seeds only |
| `reasonable_frontier_finalists` | `ok` | 1130.42% | 0.01% | 31 | `baseline` | 8.8291e-05 | baseline seeds plus filtered additive frontier, then polished |

## Finalist-Set Outcome

- Benchmark `odepe_polish` vs merged finalist set: `finalist_set_better`
- Improvement mode: `both_seed_families_win`
- Baseline best finalist index / RMSE: 2 / 0.01%
- Additive best finalist index / RMSE: 2 / 0.01%
- Frontier best finalist index / RMSE: 2 / 0.01%
- Baseline preserved seeds: 257
- Additive candidate seeds: 271
- Frontier admitted seeds: 259
- Rejected additive seeds: 269
- Successful merged polished seeds: 259
- Returned merged finalists: 31

## Baseline Seed Pool

| Rank | Source | Candidate Index | Fit Error | Lineage |
|------|--------|-----------------|-----------|---------|
| 1 | `baseline` | 1 | 2.2022e+05 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | 2 | 2.2022e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | 3 | 3.6005e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | 4 | 3.6005e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | 5 | 1.5242e+05 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | 6 | 1.5242e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | 7 | 1.9937e+04 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | 8 | 1.9937e+04 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | 9 | 1.3112e+04 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | 10 | 1.3112e+04 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | 11 | 8.6108e+03 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | 12 | 8.6108e+03 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | 13 | 2.6047e+03 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | 14 | 2.6047e+03 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | 15 | 2.3564e+03 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | 16 | 2.3564e+03 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | 17 | 1.2146e+03 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | 18 | 1.2146e+03 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | 19 | 1.1924e+03 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | 20 | 1.1924e+03 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | 21 | 4.1208e+02 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | 22 | 4.1208e+02 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | 23 | 3.4591e+02 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | 24 | 3.4591e+02 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | 25 | 3.2656e+02 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | 26 | 3.2656e+02 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | 27 | 2.3525e+02 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | 28 | 2.3525e+02 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | 29 | 1.6517e+02 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | 30 | 1.6517e+02 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | 31 | 1.5164e+02 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | 32 | 1.5164e+02 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | 33 | 1.3550e+02 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | 34 | 1.3550e+02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | 35 | Inf | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | 36 | Inf | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | 37 | 1.0549e+02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | 38 | 1.0549e+02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | 39 | 1.0060e+02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | 40 | 1.0060e+02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | 41 | 9.0199e+01 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | 42 | 9.0199e+01 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | 43 | 4.3917e+01 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | 44 | 4.3917e+01 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | 45 | 1.7768e+01 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | 46 | 1.7768e+01 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | 47 | 1.0556e+01 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | 48 | 1.0556e+01 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | 49 | 3.8081e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | 50 | 3.8081e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | 51 | 3.2038e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | 52 | 3.2038e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | 53 | Inf | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | 54 | Inf | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | 55 | 2.3876e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | 56 | 2.3876e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | 57 | 2.4629e+00 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | 58 | 2.4629e+00 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | 59 | 2.5371e+00 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | 60 | 2.5371e+00 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | 61 | 1.6085e+00 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | 62 | 1.6085e+00 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | 63 | 1.2789e+00 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | 64 | 1.2789e+00 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | 65 | 7.4062e-01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | 66 | 7.4062e-01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | 67 | 5.8697e-01 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | 68 | 5.8697e-01 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | 69 | 3.1921e-01 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | 70 | 3.1921e-01 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | 71 | 2.3165e-01 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | 72 | 2.3165e-01 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | 73 | 2.8207e-01 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | 74 | 2.8207e-01 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | 75 | 2.1904e-01 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | 76 | 2.1904e-01 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | 77 | 1.6821e-01 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | 78 | 1.6821e-01 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | 79 | 1.3475e-01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | 80 | 1.3475e-01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | 81 | 1.0492e-01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | 82 | 1.0492e-01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | 83 | 1.0096e-01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | 84 | 1.0096e-01 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | 85 | 8.4145e-02 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | 86 | 8.4145e-02 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | 87 | 8.0882e-02 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | 88 | 8.0882e-02 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | 89 | 9.2711e-02 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | 90 | 9.2711e-02 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | 91 | 5.7617e-02 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | 92 | 5.7617e-02 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | 93 | 5.5908e-02 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | 94 | 5.5908e-02 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | 95 | 6.8896e-02 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | 96 | 6.8896e-02 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | 97 | 3.6748e-02 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | 98 | 3.6748e-02 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | 99 | 2.7829e-02 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | 100 | 2.7829e-02 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | 101 | 4.9294e-02 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | 102 | 4.9294e-02 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | 103 | 2.7130e-02 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | 104 | 2.7130e-02 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | 105 | 2.4930e-02 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | 106 | 2.4930e-02 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | 107 | 1.9637e-02 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | 108 | 1.9637e-02 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | 109 | 2.1454e-02 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | 110 | 2.1454e-02 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | 111 | 1.9658e-02 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | 112 | 1.9658e-02 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | 113 | 1.7632e-02 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | 114 | 1.7632e-02 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | 115 | 1.6921e-02 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | 116 | 1.6921e-02 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | 117 | 1.3835e-02 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | 118 | 1.3835e-02 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | 119 | 2.2163e-02 | method=algebraic, source=imported, candidate=119 |
| 120 | `baseline` | 120 | 2.2163e-02 | method=algebraic, source=imported, candidate=120 |
| 121 | `baseline` | 121 | 2.2647e-02 | method=algebraic, source=imported, candidate=121 |
| 122 | `baseline` | 122 | 2.2647e-02 | method=algebraic, source=imported, candidate=122 |
| 123 | `baseline` | 123 | 2.1462e-02 | method=algebraic, source=imported, candidate=123 |
| 124 | `baseline` | 124 | 2.1462e-02 | method=algebraic, source=imported, candidate=124 |
| 125 | `baseline` | 125 | 1.2650e-02 | method=algebraic, source=imported, candidate=125 |
| 126 | `baseline` | 126 | 1.2650e-02 | method=algebraic, source=imported, candidate=126 |
| 127 | `baseline` | 127 | 1.1199e-02 | method=algebraic, source=imported, candidate=127 |
| 128 | `baseline` | 128 | 1.1199e-02 | method=algebraic, source=imported, candidate=128 |
| 129 | `baseline` | 129 | 9.7684e-03 | method=algebraic, source=imported, candidate=129 |
| 130 | `baseline` | 130 | 9.7684e-03 | method=algebraic, source=imported, candidate=130 |
| 131 | `baseline` | 131 | 9.5914e-03 | method=algebraic, source=imported, candidate=131 |
| 132 | `baseline` | 132 | 9.5914e-03 | method=algebraic, source=imported, candidate=132 |
| 133 | `baseline` | 133 | 1.0616e-02 | method=algebraic, source=imported, candidate=133 |
| 134 | `baseline` | 134 | 1.0616e-02 | method=algebraic, source=imported, candidate=134 |
| 135 | `baseline` | 135 | 8.5209e-03 | method=algebraic, source=imported, candidate=135 |
| 136 | `baseline` | 136 | 8.5209e-03 | method=algebraic, source=imported, candidate=136 |
| 137 | `baseline` | 137 | 6.8889e-03 | method=algebraic, source=imported, candidate=137 |
| 138 | `baseline` | 138 | 6.8889e-03 | method=algebraic, source=imported, candidate=138 |
| 139 | `baseline` | 139 | 1.1447e-02 | method=algebraic, source=imported, candidate=139 |
| 140 | `baseline` | 140 | 1.1447e-02 | method=algebraic, source=imported, candidate=140 |
| 141 | `baseline` | 141 | 6.6444e-03 | method=algebraic, source=imported, candidate=141 |
| 142 | `baseline` | 142 | 6.6444e-03 | method=algebraic, source=imported, candidate=142 |
| 143 | `baseline` | 143 | 4.9843e-03 | method=algebraic, source=imported, candidate=143 |
| 144 | `baseline` | 144 | 4.9843e-03 | method=algebraic, source=imported, candidate=144 |
| 145 | `baseline` | 145 | 4.7409e-03 | method=algebraic, source=imported, candidate=145 |
| 146 | `baseline` | 146 | 4.7409e-03 | method=algebraic, source=imported, candidate=146 |
| 147 | `baseline` | 147 | 5.8658e-03 | method=algebraic, source=imported, candidate=147 |
| 148 | `baseline` | 148 | 5.8658e-03 | method=algebraic, source=imported, candidate=148 |
| 149 | `baseline` | 149 | 6.2239e-03 | method=algebraic, source=imported, candidate=149 |
| 150 | `baseline` | 150 | 6.2239e-03 | method=algebraic, source=imported, candidate=150 |
| 151 | `baseline` | 151 | 5.1240e-03 | method=algebraic, source=imported, candidate=151 |
| 152 | `baseline` | 152 | 5.1240e-03 | method=algebraic, source=imported, candidate=152 |
| 153 | `baseline` | 153 | 4.8806e-03 | method=algebraic, source=imported, candidate=153 |
| 154 | `baseline` | 154 | 4.8806e-03 | method=algebraic, source=imported, candidate=154 |
| 155 | `baseline` | 155 | 4.5264e-03 | method=algebraic, source=imported, candidate=155 |
| 156 | `baseline` | 156 | 4.5264e-03 | method=algebraic, source=imported, candidate=156 |
| 157 | `baseline` | 157 | 3.7610e-03 | method=algebraic, source=imported, candidate=157 |
| 158 | `baseline` | 158 | 3.7610e-03 | method=algebraic, source=imported, candidate=158 |
| 159 | `baseline` | 159 | 3.3327e-03 | method=algebraic, source=imported, candidate=159 |
| 160 | `baseline` | 160 | 3.3327e-03 | method=algebraic, source=imported, candidate=160 |
| 161 | `baseline` | 173 | 3.0674e-03 | method=algebraic, source=imported, candidate=173 |
| 162 | `baseline` | 162 | 3.5439e-03 | method=algebraic, source=imported, candidate=162 |
| 163 | `baseline` | 163 | 2.6205e-03 | method=algebraic, source=imported, candidate=163 |
| 164 | `baseline` | 164 | 2.6205e-03 | method=algebraic, source=imported, candidate=164 |
| 165 | `baseline` | 165 | 3.1038e-03 | method=algebraic, source=imported, candidate=165 |
| 166 | `baseline` | 166 | 3.1038e-03 | method=algebraic, source=imported, candidate=166 |
| 167 | `baseline` | 167 | 2.3567e-03 | method=algebraic, source=imported, candidate=167 |
| 168 | `baseline` | 168 | 2.3567e-03 | method=algebraic, source=imported, candidate=168 |
| 169 | `baseline` | 169 | 3.7023e-03 | method=algebraic, source=imported, candidate=169 |
| 170 | `baseline` | 170 | 3.7023e-03 | method=algebraic, source=imported, candidate=170 |
| 171 | `baseline` | 171 | 2.2666e-03 | method=algebraic, source=imported, candidate=171 |
| 172 | `baseline` | 172 | 2.2666e-03 | method=algebraic, source=imported, candidate=172 |
| 173 | `baseline` | 174 | 3.0674e-03 | method=algebraic, source=imported, candidate=174 |
| 174 | `baseline` | 175 | 2.1253e-03 | method=algebraic, source=imported, candidate=175 |
| 175 | `baseline` | 176 | 2.1253e-03 | method=algebraic, source=imported, candidate=176 |
| 176 | `baseline` | 177 | 2.0709e-03 | method=algebraic, source=imported, candidate=177 |
| 177 | `baseline` | 178 | 2.0709e-03 | method=algebraic, source=imported, candidate=178 |
| 178 | `baseline` | 179 | 3.0773e-03 | method=algebraic, source=imported, candidate=179 |
| 179 | `baseline` | 180 | 3.0773e-03 | method=algebraic, source=imported, candidate=180 |
| 180 | `baseline` | 181 | 2.0217e-03 | method=algebraic, source=imported, candidate=181 |
| 181 | `baseline` | 192 | 1.6992e-03 | method=algebraic, source=imported, candidate=192 |
| 182 | `baseline` | 183 | 3.1544e-03 | method=algebraic, source=imported, candidate=183 |
| 183 | `baseline` | 184 | 3.1544e-03 | method=algebraic, source=imported, candidate=184 |
| 184 | `baseline` | 185 | 2.0380e-03 | method=algebraic, source=imported, candidate=185 |
| 185 | `baseline` | 186 | 2.0380e-03 | method=algebraic, source=imported, candidate=186 |
| 186 | `baseline` | 187 | 1.8247e-03 | method=algebraic, source=imported, candidate=187 |
| 187 | `baseline` | 189 | 1.6505e-03 | method=algebraic, source=imported, candidate=189 |
| 188 | `baseline` | 190 | 1.6505e-03 | method=algebraic, source=imported, candidate=190 |
| 189 | `baseline` | 191 | 1.6992e-03 | method=algebraic, source=imported, candidate=191 |
| 190 | `baseline` | 193 | 1.6521e-03 | method=algebraic, source=imported, candidate=193 |
| 191 | `baseline` | 207 | 9.0469e-04 | method=algebraic, source=imported, candidate=207 |
| 192 | `baseline` | 195 | 2.3057e-03 | method=algebraic, source=imported, candidate=195 |
| 193 | `baseline` | 199 | 1.7233e-03 | method=algebraic, source=imported, candidate=199 |
| 194 | `baseline` | 197 | 1.6379e-03 | method=algebraic, source=imported, candidate=197 |
| 195 | `baseline` | 198 | 1.6379e-03 | method=algebraic, source=imported, candidate=198 |
| 196 | `baseline` | 200 | 1.7233e-03 | method=algebraic, source=imported, candidate=200 |
| 197 | `baseline` | 201 | 1.4954e-03 | method=algebraic, source=imported, candidate=201 |
| 198 | `baseline` | 202 | 1.4954e-03 | method=algebraic, source=imported, candidate=202 |
| 199 | `baseline` | 203 | 1.3323e-03 | method=algebraic, source=imported, candidate=203 |
| 200 | `baseline` | 204 | 1.3323e-03 | method=algebraic, source=imported, candidate=204 |
| 201 | `baseline` | 205 | 1.0576e-03 | method=algebraic, source=imported, candidate=205 |
| 202 | `baseline` | 206 | 1.0576e-03 | method=algebraic, source=imported, candidate=206 |
| 203 | `baseline` | 208 | 9.0469e-04 | method=algebraic, source=imported, candidate=208 |
| 204 | `baseline` | 209 | 7.0718e-04 | method=algebraic, source=imported, candidate=209 |
| 205 | `baseline` | 210 | 7.0718e-04 | method=algebraic, source=imported, candidate=210 |
| 206 | `baseline` | 211 | 7.4315e-04 | method=algebraic, source=imported, candidate=211 |
| 207 | `baseline` | 212 | 7.4315e-04 | method=algebraic, source=imported, candidate=212 |
| 208 | `baseline` | 213 | 5.6675e-04 | method=algebraic, source=imported, candidate=213 |
| 209 | `baseline` | 214 | 5.6675e-04 | method=algebraic, source=imported, candidate=214 |
| 210 | `baseline` | 215 | 5.5913e-04 | method=algebraic, source=imported, candidate=215 |
| 211 | `baseline` | 272 | 1.0508e-04 | method=algebraic, source=imported, candidate=272 |
| 212 | `baseline` | 217 | 5.0333e-04 | method=algebraic, source=imported, candidate=217 |
| 213 | `baseline` | 218 | 5.0333e-04 | method=algebraic, source=imported, candidate=218 |
| 214 | `baseline` | 219 | 6.0320e-04 | method=algebraic, source=imported, candidate=219 |
| 215 | `baseline` | 220 | 6.0320e-04 | method=algebraic, source=imported, candidate=220 |
| 216 | `baseline` | 222 | 4.9453e-04 | method=algebraic, source=imported, candidate=222 |
| 217 | `baseline` | 223 | 4.3154e-04 | method=algebraic, source=imported, candidate=223 |
| 218 | `baseline` | 224 | 4.3154e-04 | method=algebraic, source=imported, candidate=224 |
| 219 | `baseline` | 225 | 3.4966e-04 | method=algebraic, source=imported, candidate=225 |
| 220 | `baseline` | 231 | 2.6337e-04 | method=algebraic, source=imported, candidate=231 |
| 221 | `baseline` | 227 | 2.7173e-04 | method=algebraic, source=imported, candidate=227 |
| 222 | `baseline` | 251 | 1.9795e-04 | method=algebraic, source=imported, candidate=251 |
| 223 | `baseline` | 239 | 2.3355e-04 | method=algebraic, source=imported, candidate=239 |
| 224 | `baseline` | 230 | 2.5123e-04 | method=algebraic, source=imported, candidate=230 |
| 225 | `baseline` | 232 | 2.6337e-04 | method=algebraic, source=imported, candidate=232 |
| 226 | `baseline` | 234 | 2.6822e-04 | method=algebraic, source=imported, candidate=234 |
| 227 | `baseline` | 235 | 2.3988e-04 | method=algebraic, source=imported, candidate=235 |
| 228 | `baseline` | 236 | 2.3988e-04 | method=algebraic, source=imported, candidate=236 |
| 229 | `baseline` | 237 | 2.3936e-04 | method=algebraic, source=imported, candidate=237 |
| 230 | `baseline` | 240 | 2.3355e-04 | method=algebraic, source=imported, candidate=240 |
| 231 | `baseline` | 241 | 2.4270e-04 | method=algebraic, source=imported, candidate=241 |
| 232 | `baseline` | 253 | 2.0478e-04 | method=algebraic, source=imported, candidate=253 |
| 233 | `baseline` | 244 | 2.4689e-04 | method=algebraic, source=imported, candidate=244 |
| 234 | `baseline` | 245 | 2.0981e-04 | method=algebraic, source=imported, candidate=245 |
| 235 | `baseline` | 246 | 2.0981e-04 | method=algebraic, source=imported, candidate=246 |
| 236 | `baseline` | 255 | 1.8195e-04 | method=algebraic, source=imported, candidate=255 |
| 237 | `baseline` | 248 | 2.2173e-04 | method=algebraic, source=imported, candidate=248 |
| 238 | `baseline` | 249 | 2.0818e-04 | method=algebraic, source=imported, candidate=249 |
| 239 | `baseline` | 277 | 9.5814e-05 | method=algebraic, source=imported, candidate=277 |
| 240 | `baseline` | 252 | 1.9795e-04 | method=algebraic, source=imported, candidate=252 |
| 241 | `baseline` | 254 | 2.0478e-04 | method=algebraic, source=imported, candidate=254 |
| 242 | `baseline` | 256 | 1.8195e-04 | method=algebraic, source=imported, candidate=256 |
| 243 | `baseline` | 258 | 1.6685e-04 | method=algebraic, source=imported, candidate=258 |
| 244 | `baseline` | 259 | 1.5392e-04 | method=algebraic, source=imported, candidate=259 |
| 245 | `baseline` | 270 | 1.1299e-04 | method=algebraic, source=imported, candidate=270 |
| 246 | `baseline` | 280 | 9.2429e-05 | method=algebraic, source=imported, candidate=280 |
| 247 | `baseline` | 263 | 1.4895e-04 | method=algebraic, source=imported, candidate=263 |
| 248 | `baseline` | 264 | 1.4895e-04 | method=algebraic, source=imported, candidate=264 |
| 249 | `baseline` | 265 | 1.4365e-04 | method=algebraic, source=imported, candidate=265 |
| 250 | `baseline` | 267 | 1.3535e-04 | method=algebraic, source=imported, candidate=267 |
| 251 | `baseline` | 268 | 1.3535e-04 | method=algebraic, source=imported, candidate=268 |
| 252 | `baseline` | 269 | 1.1299e-04 | method=algebraic, source=imported, candidate=269 |
| 253 | `baseline` | 271 | 1.0508e-04 | method=algebraic, source=imported, candidate=271 |
| 254 | `baseline` | 273 | 9.9801e-05 | method=algebraic, source=imported, candidate=273 |
| 255 | `baseline` | 279 | 9.2429e-05 | method=algebraic, source=imported, candidate=279 |
| 256 | `baseline` | 276 | 9.7065e-05 | method=algebraic, source=imported, candidate=276 |
| 257 | `baseline` | 278 | 9.5814e-05 | method=algebraic, source=imported, candidate=278 |

## Additive Seed Pool

| Rank | Sources | Source Id | Generator Score | Fit Error | Lineage |
|------|---------|-----------|-----------------|-----------|---------|
| 1 | `block` | 1 | 0.0000 | 1.0587e-01 | method=direct_opt, source=assembled |
| 3 | `block` | 3 | 0.3409 | 5.9846e+06 | method=direct_opt, source=assembled |
| 5 | `block` | 5 | 0.4149 | 1.0915e+08 | method=direct_opt, source=assembled |
| 6 | `block` | 6 | 0.4205 | 1.4113e+08 | method=direct_opt, source=assembled |
| 8 | `block` | 8 | 0.5538 | 1.9877e+10 | method=direct_opt, source=assembled |
| 10 | `block` | 10 | 0.5542 | 2.0241e+10 | method=direct_opt, source=assembled |
| 11 | `block` | 11 | 0.8456 | Inf | method=direct_opt, source=assembled |
| 13 | `block` | 13 | 0.8456 | Inf | method=direct_opt, source=assembled |
| 14 | `block` | 14 | 0.8779 | Inf | method=direct_opt, source=assembled |
| 16 | `block` | 16 | 0.8779 | Inf | method=direct_opt, source=assembled |
| 17 | `block` | 17 | 0.8901 | 1.0996e+16 | method=direct_opt, source=assembled |
| 18 | `block` | 18 | 0.9516 | Inf | method=direct_opt, source=assembled |
| 19 | `block` | 19 | 0.9632 | Inf | method=direct_opt, source=assembled |
| 20 | `block` | 20 | 1.0000 | Inf | method=direct_opt, source=assembled |
| 1 | `branch+synthesized` | 3 | 0.6690 | 8.8291e-05 | method=direct_opt, source=synthesized, candidate=279, polished=true |
| 4 | `branch` | 4 | 0.6649 | 1.0508e-04 | method=algebraic, source=imported, candidate=272 |
| 5 | `branch` | 5 | 0.6639 | 1.4365e-04 | method=algebraic, source=imported, candidate=266 |
| 7 | `branch` | 7 | 0.6608 | 1.1299e-04 | method=algebraic, source=imported, candidate=270 |
| 8 | `branch` | 8 | 0.6601 | 1.3535e-04 | method=algebraic, source=imported, candidate=267 |
| 14 | `branch` | 14 | 0.6460 | 1.9795e-04 | method=algebraic, source=imported, candidate=251 |
| 15 | `branch` | 15 | 0.6398 | 1.8195e-04 | method=algebraic, source=imported, candidate=255 |
| 16 | `branch` | 16 | 0.6388 | 2.0478e-04 | method=algebraic, source=imported, candidate=253 |
| 17 | `branch` | 17 | 0.6365 | 2.6337e-04 | method=algebraic, source=imported, candidate=231 |
| 21 | `branch` | 28 | 0.6241 | 2.3355e-04 | method=algebraic, source=imported, candidate=239 |
| 22 | `branch` | 22 | 0.6284 | 2.0981e-04 | method=algebraic, source=imported, candidate=245 |
| 23 | `branch` | 23 | 0.6267 | 4.9453e-04 | method=algebraic, source=imported, candidate=221 |
| 27 | `branch` | 27 | 0.6241 | 4.3154e-04 | method=algebraic, source=imported, candidate=224 |
| 30 | `branch` | 30 | 0.6214 | 6.0320e-04 | method=algebraic, source=imported, candidate=219 |
| 31 | `branch` | 31 | 0.6197 | 2.3988e-04 | method=algebraic, source=imported, candidate=236 |
| 33 | `branch` | 33 | 0.6156 | 9.5814e-05 | method=algebraic, source=imported, candidate=278 |
| 34 | `branch` | 34 | 0.6146 | 9.2429e-05 | method=algebraic, source=imported, candidate=280 |
| 35 | `branch` | 35 | 0.6139 | 9.0469e-04 | method=algebraic, source=imported, candidate=207 |
| 36 | `branch` | 36 | 0.6138 | 1.0576e-03 | method=algebraic, source=imported, candidate=206 |
| 37 | `branch` | 37 | 0.6127 | 9.9801e-05 | method=algebraic, source=imported, candidate=273 |
| 38 | `branch` | 38 | 0.6117 | 1.3323e-03 | method=algebraic, source=imported, candidate=204 |
| 39 | `branch` | 39 | 0.6108 | 1.3535e-04 | method=algebraic, source=imported, candidate=268 |
| 40 | `branch` | 40 | 0.6103 | 1.4365e-04 | method=algebraic, source=imported, candidate=265 |
| 41 | `branch` | 41 | 0.6092 | 1.0508e-04 | method=algebraic, source=imported, candidate=271 |
| 43 | `branch` | 43 | 0.6067 | 1.4954e-03 | method=algebraic, source=imported, candidate=202 |
| 44 | `branch` | 44 | 0.6059 | 1.5392e-04 | method=algebraic, source=imported, candidate=259 |
| 45 | `branch` | 45 | 0.6052 | 9.7065e-05 | method=algebraic, source=imported, candidate=276 |
| 46 | `branch` | 46 | 0.6025 | 1.7233e-03 | method=algebraic, source=imported, candidate=199 |
| 48 | `branch` | 48 | 0.6009 | 1.9795e-04 | method=algebraic, source=imported, candidate=252 |
| 49 | `branch` | 49 | 0.5989 | 2.0818e-04 | method=algebraic, source=imported, candidate=249 |
| 50 | `branch` | 50 | 0.5989 | 1.1299e-04 | method=algebraic, source=imported, candidate=269 |
| 51 | `branch` | 51 | 0.5978 | 1.6379e-03 | method=algebraic, source=imported, candidate=198 |
| 52 | `branch` | 52 | 0.5973 | 2.0380e-03 | method=algebraic, source=imported, candidate=186 |
| 53 | `branch` | 53 | 0.5959 | 5.0333e-04 | method=algebraic, source=imported, candidate=218 |
| 54 | `branch` | 54 | 0.5957 | 1.6685e-04 | method=algebraic, source=imported, candidate=258 |
| 55 | `branch` | 55 | 0.5953 | 5.6675e-04 | method=algebraic, source=imported, candidate=214 |
| 56 | `branch` | 56 | 0.5946 | 7.0718e-04 | method=algebraic, source=imported, candidate=209 |
| 57 | `branch` | 57 | 0.5924 | 2.0709e-03 | method=algebraic, source=imported, candidate=178 |
| 58 | `branch` | 58 | 0.5919 | 2.6337e-04 | method=algebraic, source=imported, candidate=232 |
| 59 | `branch` | 59 | 0.5902 | 2.4270e-04 | method=algebraic, source=imported, candidate=241 |
| 60 | `branch` | 60 | 0.5900 | 3.4966e-04 | method=algebraic, source=imported, candidate=225 |
| 61 | `branch` | 61 | 0.5884 | 1.4895e-04 | method=algebraic, source=imported, candidate=264 |
| 62 | `branch` | 62 | 0.5845 | 2.6205e-03 | method=algebraic, source=imported, candidate=163 |
| 64 | `branch` | 64 | 0.5829 | 2.6822e-04 | method=algebraic, source=imported, candidate=234 |
| 65 | `branch` | 65 | 0.5777 | 3.0674e-03 | method=algebraic, source=imported, candidate=173 |
| 66 | `branch` | 66 | 0.5755 | 2.0478e-04 | method=algebraic, source=imported, candidate=254 |
| 67 | `branch` | 67 | 0.5749 | 1.8195e-04 | method=algebraic, source=imported, candidate=256 |
| 68 | `branch` | 68 | 0.5742 | 3.3327e-03 | method=algebraic, source=imported, candidate=159 |
| 69 | `branch` | 69 | 0.5736 | 2.7173e-04 | method=algebraic, source=imported, candidate=227 |
| 70 | `branch` | 70 | 0.5728 | 7.4315e-04 | method=algebraic, source=imported, candidate=212 |
| 71 | `branch` | 71 | 0.5722 | 2.0981e-04 | method=algebraic, source=imported, candidate=246 |
| 72 | `branch` | 72 | 0.5706 | 3.7610e-03 | method=algebraic, source=imported, candidate=157 |
| 74 | `branch` | 74 | 0.5684 | 2.2173e-04 | method=algebraic, source=imported, candidate=248 |
| 75 | `branch` | 75 | 0.5683 | 3.1544e-03 | method=algebraic, source=imported, candidate=184 |
| 76 | `branch` | 76 | 0.5675 | 2.3936e-04 | method=algebraic, source=imported, candidate=237 |
| 77 | `branch` | 77 | 0.5670 | 2.3355e-04 | method=algebraic, source=imported, candidate=240 |
| 78 | `branch` | 78 | 0.5645 | 3.7023e-03 | method=algebraic, source=imported, candidate=169 |
| 79 | `branch` | 79 | 0.5644 | 4.9453e-04 | method=algebraic, source=imported, candidate=222 |
| 80 | `branch` | 80 | 0.5644 | 2.5123e-04 | method=algebraic, source=imported, candidate=230 |
| 81 | `branch` | 81 | 0.5622 | 4.3154e-04 | method=algebraic, source=imported, candidate=223 |
| 82 | `branch` | 82 | 0.5615 | 2.4689e-04 | method=algebraic, source=imported, candidate=244 |
| 83 | `branch` | 83 | 0.5610 | 5.5913e-04 | method=algebraic, source=imported, candidate=215 |
| 84 | `branch` | 84 | 0.5610 | 3.1038e-03 | method=algebraic, source=imported, candidate=166 |
| 85 | `branch` | 85 | 0.5605 | 2.2666e-03 | method=algebraic, source=imported, candidate=171 |
| 86 | `branch` | 86 | 0.5602 | 4.7409e-03 | method=algebraic, source=imported, candidate=145 |
| 87 | `branch` | 87 | 0.5598 | 2.3988e-04 | method=algebraic, source=imported, candidate=235 |
| 88 | `branch` | 88 | 0.5511 | 1.6505e-03 | method=algebraic, source=imported, candidate=190 |
| 89 | `branch` | 89 | 0.5498 | 5.8658e-03 | method=algebraic, source=imported, candidate=147 |
| 90 | `branch` | 90 | 0.5489 | 5.6675e-04 | method=algebraic, source=imported, candidate=213 |
| 91 | `branch` | 91 | 0.5488 | 3.0773e-03 | method=algebraic, source=imported, candidate=179 |
| 92 | `branch` | 92 | 0.5465 | 5.0333e-04 | method=algebraic, source=imported, candidate=217 |
| 93 | `branch` | 93 | 0.5458 | 4.8806e-03 | method=algebraic, source=imported, candidate=154 |
| 94 | `branch` | 94 | 0.5452 | 6.0320e-04 | method=algebraic, source=imported, candidate=220 |
| 95 | `branch` | 95 | 0.5433 | 9.0469e-04 | method=algebraic, source=imported, candidate=208 |
| 96 | `branch` | 96 | 0.5404 | 1.0576e-03 | method=algebraic, source=imported, candidate=205 |
| 97 | `branch` | 97 | 0.5404 | 1.6992e-03 | method=algebraic, source=imported, candidate=192 |
| 98 | `branch` | 98 | 0.5368 | 1.1199e-02 | method=algebraic, source=imported, candidate=128 |
| 100 | `branch` | 100 | 0.5353 | 1.6379e-03 | method=algebraic, source=imported, candidate=197 |
| 101 | `branch` | 101 | 0.5353 | 1.3323e-03 | method=algebraic, source=imported, candidate=203 |
| 102 | `branch` | 102 | 0.5352 | 1.6521e-03 | method=algebraic, source=imported, candidate=193 |
| 103 | `branch` | 103 | 0.5339 | 7.0718e-04 | method=algebraic, source=imported, candidate=210 |
| 104 | `branch` | 104 | 0.5326 | 5.1240e-03 | method=algebraic, source=imported, candidate=152 |
| 105 | `branch` | 105 | 0.5326 | 4.9843e-03 | method=algebraic, source=imported, candidate=144 |
| 107 | `branch` | 107 | 0.5313 | 1.4954e-03 | method=algebraic, source=imported, candidate=201 |
| 108 | `branch` | 108 | 0.5280 | 1.3835e-02 | method=algebraic, source=imported, candidate=118 |
| 109 | `branch` | 109 | 0.5272 | 2.1253e-03 | method=algebraic, source=imported, candidate=175 |
| 110 | `branch` | 110 | 0.5270 | 2.0380e-03 | method=algebraic, source=imported, candidate=185 |
| 111 | `branch` | 111 | 0.5267 | 6.2239e-03 | method=algebraic, source=imported, candidate=150 |
| 112 | `branch` | 112 | 0.5263 | 9.5914e-03 | method=algebraic, source=imported, candidate=132 |
| 113 | `branch` | 113 | 0.5263 | 2.0709e-03 | method=algebraic, source=imported, candidate=177 |
| 114 | `branch` | 114 | 0.5223 | 2.3567e-03 | method=algebraic, source=imported, candidate=167 |
| 115 | `branch` | 115 | 0.5192 | 7.4315e-04 | method=algebraic, source=imported, candidate=211 |
| 116 | `branch` | 116 | 0.5187 | 2.2647e-02 | method=algebraic, source=imported, candidate=122 |
| 117 | `branch` | 117 | 0.5177 | 3.0773e-03 | method=algebraic, source=imported, candidate=180 |
| 118 | `branch` | 118 | 0.5168 | 1.7233e-03 | method=algebraic, source=imported, candidate=200 |
| 119 | `branch` | 119 | 0.5167 | 9.7684e-03 | method=algebraic, source=imported, candidate=129 |
| 120 | `branch` | 120 | 0.5124 | 1.0616e-02 | method=algebraic, source=imported, candidate=133 |
| 121 | `branch` | 121 | 0.5123 | 1.2650e-02 | method=algebraic, source=imported, candidate=126 |
| 122 | `branch` | 122 | 0.5109 | 2.7130e-02 | method=algebraic, source=imported, candidate=103 |
| 123 | `branch` | 123 | 0.5087 | 2.6205e-03 | method=algebraic, source=imported, candidate=164 |
| 124 | `branch` | 124 | 0.5082 | 1.6921e-02 | method=algebraic, source=imported, candidate=115 |
| 125 | `branch` | 125 | 0.5057 | 2.2163e-02 | method=algebraic, source=imported, candidate=119 |
| 126 | `branch` | 126 | 0.5052 | 4.5264e-03 | method=algebraic, source=imported, candidate=155 |
| 127 | `branch` | 127 | 0.5030 | 1.1447e-02 | method=algebraic, source=imported, candidate=139 |
| 128 | `branch` | 128 | 0.5025 | 1.7632e-02 | method=algebraic, source=imported, candidate=113 |
| 129 | `branch` | 129 | 0.5022 | 6.2239e-03 | method=algebraic, source=imported, candidate=149 |
| 130 | `branch` | 130 | 0.5016 | 1.6505e-03 | method=algebraic, source=imported, candidate=189 |
| 131 | `branch` | 131 | 0.5006 | 1.9658e-02 | method=algebraic, source=imported, candidate=111 |
| 132 | `branch` | 132 | 0.4993 | 6.8896e-02 | method=algebraic, source=imported, candidate=96 |
| 133 | `branch` | 133 | 0.4985 | 2.3057e-03 | method=algebraic, source=imported, candidate=195 |
| 134 | `branch` | 134 | 0.4977 | 2.2666e-03 | method=algebraic, source=imported, candidate=172 |
| 135 | `branch` | 135 | 0.4971 | 6.6444e-03 | method=algebraic, source=imported, candidate=141 |
| 136 | `branch` | 136 | 0.4958 | 2.1454e-02 | method=algebraic, source=imported, candidate=110 |
| 137 | `branch` | 137 | 0.4957 | 6.8889e-03 | method=algebraic, source=imported, candidate=138 |
| 138 | `branch` | 138 | 0.4948 | 4.9294e-02 | method=algebraic, source=imported, candidate=101 |
| 139 | `branch` | 139 | 0.4900 | 3.0674e-03 | method=algebraic, source=imported, candidate=174 |
| 140 | `branch` | 140 | 0.4898 | 9.2711e-02 | method=algebraic, source=imported, candidate=90 |
| 141 | `branch` | 141 | 0.4896 | 1.0616e-02 | method=algebraic, source=imported, candidate=134 |
| 142 | `branch` | 142 | 0.4891 | 3.3327e-03 | method=algebraic, source=imported, candidate=160 |
| 143 | `branch` | 143 | 0.4867 | 1.6992e-03 | method=algebraic, source=imported, candidate=191 |
| 144 | `branch` | 144 | 0.4844 | 3.7610e-03 | method=algebraic, source=imported, candidate=158 |
| 145 | `branch` | 145 | 0.4840 | 2.4930e-02 | method=algebraic, source=imported, candidate=105 |
| 146 | `branch` | 146 | 0.4832 | 1.8247e-03 | method=algebraic, source=imported, candidate=187 |
| 147 | `branch` | 147 | 0.4831 | 8.5209e-03 | method=algebraic, source=imported, candidate=136 |
| 148 | `branch` | 148 | 0.4824 | 1.1447e-02 | method=algebraic, source=imported, candidate=140 |
| 149 | `branch` | 149 | 0.4823 | 5.8658e-03 | method=algebraic, source=imported, candidate=148 |
| 150 | `branch` | 150 | 0.4802 | 8.0882e-02 | method=algebraic, source=imported, candidate=87 |
| 151 | `branch` | 151 | 0.4798 | 3.1544e-03 | method=algebraic, source=imported, candidate=183 |
| 152 | `branch` | 152 | 0.4795 | 1.6821e-01 | method=algebraic, source=imported, candidate=77 |
| 153 | `branch` | 153 | 0.4789 | 2.0217e-03 | method=algebraic, source=imported, candidate=181 |
| 154 | `branch` | 154 | 0.4780 | 2.1253e-03 | method=algebraic, source=imported, candidate=176 |
| 155 | `branch` | 155 | 0.4779 | 2.7829e-02 | method=algebraic, source=imported, candidate=100 |
| 156 | `branch` | 156 | 0.4776 | 2.1462e-02 | method=algebraic, source=imported, candidate=124 |
| 157 | `branch` | 157 | 0.4771 | 3.5439e-03 | method=algebraic, source=imported, candidate=162 |
| 158 | `branch` | 158 | 0.4749 | 5.1240e-03 | method=algebraic, source=imported, candidate=151 |
| 159 | `branch` | 159 | 0.4741 | 4.5264e-03 | method=algebraic, source=imported, candidate=156 |
| 160 | `branch` | 160 | 0.4740 | 2.3567e-03 | method=algebraic, source=imported, candidate=168 |
| 161 | `branch` | 161 | 0.4730 | 3.7023e-03 | method=algebraic, source=imported, candidate=170 |
| 162 | `branch` | 162 | 0.4721 | 2.3165e-01 | method=algebraic, source=imported, candidate=72 |
| 163 | `branch` | 163 | 0.4719 | 4.7409e-03 | method=algebraic, source=imported, candidate=146 |
| 164 | `branch` | 164 | 0.4717 | 3.6748e-02 | method=algebraic, source=imported, candidate=98 |
| 165 | `branch` | 165 | 0.4674 | 3.1038e-03 | method=algebraic, source=imported, candidate=165 |
| 166 | `branch` | 166 | 0.4672 | 1.0492e-01 | method=algebraic, source=imported, candidate=82 |
| 167 | `branch` | 167 | 0.4649 | 6.6444e-03 | method=algebraic, source=imported, candidate=142 |
| 168 | `branch` | 168 | 0.4620 | 1.2789e+00 | method=algebraic, source=imported, candidate=64 |
| 169 | `branch` | 169 | 0.4609 | 2.1462e-02 | method=algebraic, source=imported, candidate=123 |
| 170 | `branch` | 170 | 0.4608 | 4.9843e-03 | method=algebraic, source=imported, candidate=143 |
| 171 | `branch` | 171 | 0.4608 | 5.5908e-02 | method=algebraic, source=imported, candidate=93 |
| 172 | `branch` | 172 | 0.4545 | 6.8889e-03 | method=algebraic, source=imported, candidate=137 |
| 173 | `branch` | 173 | 0.4543 | 1.9637e-02 | method=algebraic, source=imported, candidate=108 |
| 174 | `branch` | 174 | 0.4521 | 4.8806e-03 | method=algebraic, source=imported, candidate=153 |
| 175 | `branch` | 175 | 0.4515 | 3.8081e+00 | method=algebraic, source=imported, candidate=50 |
| 176 | `branch` | 176 | 0.4514 | 9.5914e-03 | method=algebraic, source=imported, candidate=131 |
| 177 | `branch` | 177 | 0.4513 | 8.5209e-03 | method=algebraic, source=imported, candidate=135 |
| 178 | `branch` | 178 | 0.4492 | 8.4145e-02 | method=algebraic, source=imported, candidate=86 |
| 179 | `branch` | 179 | 0.4441 | 9.7684e-03 | method=algebraic, source=imported, candidate=130 |
| 180 | `branch` | 180 | 0.4439 | 1.7632e-02 | method=algebraic, source=imported, candidate=114 |
| 181 | `branch` | 181 | 0.4433 | 3.1921e-01 | method=algebraic, source=imported, candidate=69 |
| 182 | `branch` | 182 | 0.4416 | 1.1199e-02 | method=algebraic, source=imported, candidate=127 |
| 183 | `branch` | 183 | 0.4394 | 1.2650e-02 | method=algebraic, source=imported, candidate=125 |
| 184 | `branch` | 184 | 0.4389 | 2.5371e+00 | method=algebraic, source=imported, candidate=60 |
| 185 | `branch` | 185 | 0.4383 | 1.3475e-01 | method=algebraic, source=imported, candidate=80 |
| 186 | `branch` | 186 | 0.4360 | 1.6921e-02 | method=algebraic, source=imported, candidate=116 |
| 187 | `branch` | 187 | 0.4347 | 5.7617e-02 | method=algebraic, source=imported, candidate=92 |
| 188 | `branch` | 188 | 0.4327 | 1.3835e-02 | method=algebraic, source=imported, candidate=117 |
| 189 | `branch` | 189 | 0.4284 | 1.9658e-02 | method=algebraic, source=imported, candidate=112 |
| 190 | `branch` | 190 | 0.4274 | 1.0096e-01 | method=algebraic, source=imported, candidate=84 |
| 191 | `branch` | 191 | 0.4258 | 2.7829e-02 | method=algebraic, source=imported, candidate=99 |
| 192 | `branch` | 192 | 0.4240 | 2.1904e-01 | method=algebraic, source=imported, candidate=76 |
| 193 | `branch` | 193 | 0.4212 | 2.8207e-01 | method=algebraic, source=imported, candidate=73 |
| 194 | `branch` | 194 | 0.4180 | 8.0882e-02 | method=algebraic, source=imported, candidate=88 |
| 195 | `branch` | 195 | 0.4161 | 2.1904e-01 | method=algebraic, source=imported, candidate=75 |
| 196 | `branch` | 196 | 0.4145 | 2.4930e-02 | method=algebraic, source=imported, candidate=106 |
| 197 | `branch` | 197 | 0.4140 | 5.8697e-01 | method=algebraic, source=imported, candidate=67 |
| 198 | `branch` | 198 | 0.4140 | 2.1454e-02 | method=algebraic, source=imported, candidate=109 |
| 199 | `branch` | 199 | 0.4137 | 5.5908e-02 | method=algebraic, source=imported, candidate=94 |
| 200 | `branch` | 200 | 0.4132 | 1.3475e-01 | method=algebraic, source=imported, candidate=79 |
| 201 | `branch` | 201 | 0.4119 | 2.8207e-01 | method=algebraic, source=imported, candidate=74 |
| 202 | `branch` | 202 | 0.4115 | 2.2647e-02 | method=algebraic, source=imported, candidate=121 |
| 203 | `branch` | 203 | 0.4101 | 3.1921e-01 | method=algebraic, source=imported, candidate=70 |
| 204 | `branch` | 204 | 0.4063 | 5.8697e-01 | method=algebraic, source=imported, candidate=68 |
| 205 | `branch` | 205 | 0.4063 | 1.6085e+00 | method=algebraic, source=imported, candidate=61 |
| 206 | `branch` | 206 | 0.4055 | 2.7130e-02 | method=algebraic, source=imported, candidate=104 |
| 207 | `branch` | 207 | 0.4041 | 3.6748e-02 | method=algebraic, source=imported, candidate=97 |
| 208 | `branch` | 208 | 0.4033 | 7.4062e-01 | method=algebraic, source=imported, candidate=66 |
| 209 | `branch` | 209 | 0.4008 | 2.2163e-02 | method=algebraic, source=imported, candidate=120 |
| 210 | `branch` | 210 | 0.4008 | 1.9637e-02 | method=algebraic, source=imported, candidate=107 |
| 211 | `branch` | 211 | 0.3996 | 1.6085e+00 | method=algebraic, source=imported, candidate=62 |
| 212 | `branch` | 212 | 0.3978 | 3.2038e+00 | method=algebraic, source=imported, candidate=52 |
| 213 | `branch` | 213 | 0.3961 | 8.4145e-02 | method=algebraic, source=imported, candidate=85 |
| 214 | `branch` | 214 | 0.3959 | 1.2789e+00 | method=algebraic, source=imported, candidate=63 |
| 215 | `branch` | 215 | 0.3947 | 2.5371e+00 | method=algebraic, source=imported, candidate=59 |
| 216 | `branch` | 216 | 0.3945 | 1.0096e-01 | method=algebraic, source=imported, candidate=83 |
| 217 | `branch` | 217 | 0.3932 | 3.8081e+00 | method=algebraic, source=imported, candidate=49 |
| 218 | `branch` | 218 | 0.3930 | 3.2038e+00 | method=algebraic, source=imported, candidate=51 |
| 219 | `branch` | 219 | 0.3860 | 4.3917e+01 | method=algebraic, source=imported, candidate=43 |
| 220 | `branch` | 220 | 0.3857 | 5.7617e-02 | method=algebraic, source=imported, candidate=91 |
| 221 | `branch` | 221 | 0.3839 | 6.8896e-02 | method=algebraic, source=imported, candidate=95 |
| 222 | `branch` | 222 | 0.3827 | 4.9294e-02 | method=algebraic, source=imported, candidate=102 |
| 223 | `branch` | 223 | 0.3727 | 9.2711e-02 | method=algebraic, source=imported, candidate=89 |
| 224 | `branch` | 224 | 0.3658 | 1.0492e-01 | method=algebraic, source=imported, candidate=81 |
| 225 | `branch` | 225 | 0.3619 | 8.6108e+03 | method=algebraic, source=imported, candidate=11 |
| 226 | `branch` | 226 | 0.3595 | 1.6821e-01 | method=algebraic, source=imported, candidate=78 |
| 227 | `branch` | 227 | 0.3579 | 1.9937e+04 | method=algebraic, source=imported, candidate=7 |
| 228 | `branch` | 228 | 0.3572 | 2.3165e-01 | method=algebraic, source=imported, candidate=71 |
| 229 | `branch` | 229 | 0.3466 | 7.4062e-01 | method=algebraic, source=imported, candidate=65 |
| 230 | `branch` | 230 | 0.3439 | 1.5242e+05 | method=algebraic, source=imported, candidate=5 |
| 231 | `branch` | 231 | 0.3398 | 2.2022e+05 | method=algebraic, source=imported, candidate=1 |
| 232 | `branch` | 232 | 0.3376 | 1.7768e+01 | method=algebraic, source=imported, candidate=46 |
| 233 | `branch` | 233 | 0.3359 | 1.7768e+01 | method=algebraic, source=imported, candidate=45 |
| 234 | `branch` | 234 | 0.3269 | 2.4629e+00 | method=algebraic, source=imported, candidate=57 |
| 235 | `branch` | 235 | 0.3253 | 4.3917e+01 | method=algebraic, source=imported, candidate=44 |
| 236 | `branch` | 236 | 0.3239 | 2.3876e+00 | method=algebraic, source=imported, candidate=56 |
| 237 | `branch` | 237 | 0.3184 | 1.0556e+01 | method=algebraic, source=imported, candidate=48 |
| 238 | `branch` | 238 | 0.3167 | 2.4629e+00 | method=algebraic, source=imported, candidate=58 |
| 239 | `branch` | 239 | 0.3145 | 2.3876e+00 | method=algebraic, source=imported, candidate=55 |
| 240 | `branch` | 240 | 0.3071 | 1.5164e+02 | method=algebraic, source=imported, candidate=32 |
| 241 | `branch` | 241 | 0.3052 | 1.3550e+02 | method=algebraic, source=imported, candidate=34 |
| 242 | `branch` | 242 | 0.3023 | 1.0556e+01 | method=algebraic, source=imported, candidate=47 |
| 243 | `branch` | 243 | 0.3022 | 8.6108e+03 | method=algebraic, source=imported, candidate=12 |
| 244 | `branch` | 244 | 0.3019 | 1.0060e+02 | method=algebraic, source=imported, candidate=40 |
| 245 | `branch` | 245 | 0.3008 | 1.0549e+02 | method=algebraic, source=imported, candidate=37 |
| 246 | `branch` | 246 | 0.2972 | 1.5164e+02 | method=algebraic, source=imported, candidate=31 |
| 247 | `branch` | 247 | 0.2972 | 1.9937e+04 | method=algebraic, source=imported, candidate=8 |
| 248 | `branch` | 248 | 0.2952 | 1.3550e+02 | method=algebraic, source=imported, candidate=33 |
| 249 | `branch` | 249 | 0.2951 | 1.0549e+02 | method=algebraic, source=imported, candidate=38 |
| 250 | `branch` | 250 | 0.2949 | 2.3525e+02 | method=algebraic, source=imported, candidate=27 |
| 251 | `branch` | 251 | 0.2940 | 1.0060e+02 | method=algebraic, source=imported, candidate=39 |
| 252 | `branch` | 252 | 0.2903 | 1.2146e+03 | method=algebraic, source=imported, candidate=17 |
| 253 | `branch` | 253 | 0.2892 | 1.6517e+02 | method=algebraic, source=imported, candidate=30 |
| 254 | `branch` | 254 | 0.2887 | 4.1208e+02 | method=algebraic, source=imported, candidate=21 |
| 255 | `branch` | 255 | 0.2877 | 1.2146e+03 | method=algebraic, source=imported, candidate=18 |
| 256 | `branch` | 256 | 0.2866 | Inf | method=algebraic, source=imported, candidate=54 |
| 257 | `branch` | 257 | 0.2860 | 3.4591e+02 | method=algebraic, source=imported, candidate=24 |
| 258 | `branch` | 258 | 0.2844 | 3.2656e+02 | method=algebraic, source=imported, candidate=26 |
| 259 | `branch` | 259 | 0.2842 | 1.5242e+05 | method=algebraic, source=imported, candidate=6 |
| 260 | `branch` | 260 | 0.2841 | 9.0199e+01 | method=algebraic, source=imported, candidate=42 |
| 261 | `branch` | 261 | 0.2829 | 1.1924e+03 | method=algebraic, source=imported, candidate=19 |
| 262 | `branch` | 262 | 0.2824 | 3.6005e+05 | method=algebraic, source=imported, candidate=3 |
| 263 | `branch` | 263 | 0.2812 | 1.3112e+04 | method=algebraic, source=imported, candidate=9 |
| 264 | `branch` | 264 | 0.2809 | 9.0199e+01 | method=algebraic, source=imported, candidate=41 |
| 265 | `branch` | 265 | 0.2806 | 2.2022e+05 | method=algebraic, source=imported, candidate=2 |
| 266 | `branch` | 266 | 0.2797 | 2.3564e+03 | method=algebraic, source=imported, candidate=16 |
| 267 | `branch` | 267 | 0.2794 | 3.6005e+05 | method=algebraic, source=imported, candidate=4 |
| 268 | `branch` | 268 | 0.2794 | 2.3525e+02 | method=algebraic, source=imported, candidate=28 |
| 269 | `branch` | 269 | 0.2786 | 2.6047e+03 | method=algebraic, source=imported, candidate=13 |
| 270 | `branch` | 270 | 0.2784 | 4.1208e+02 | method=algebraic, source=imported, candidate=22 |
| 271 | `branch` | 271 | 0.2767 | 1.3112e+04 | method=algebraic, source=imported, candidate=10 |
| 272 | `branch` | 272 | 0.2755 | 2.3564e+03 | method=algebraic, source=imported, candidate=15 |
| 273 | `branch` | 273 | 0.2720 | 1.1924e+03 | method=algebraic, source=imported, candidate=20 |
| 274 | `branch` | 274 | 0.2719 | 2.6047e+03 | method=algebraic, source=imported, candidate=14 |
| 275 | `branch` | 275 | 0.2715 | 1.6517e+02 | method=algebraic, source=imported, candidate=29 |
| 276 | `branch` | 276 | 0.2697 | Inf | method=algebraic, source=imported, candidate=53 |
| 277 | `branch` | 277 | 0.2677 | 3.4591e+02 | method=algebraic, source=imported, candidate=23 |
| 278 | `branch` | 278 | 0.2672 | 3.2656e+02 | method=algebraic, source=imported, candidate=25 |
| 279 | `branch` | 279 | 0.2632 | Inf | method=algebraic, source=imported, candidate=36 |
| 280 | `branch` | 280 | 0.2493 | Inf | method=algebraic, source=imported, candidate=35 |

## Rejected Additive Seeds

| Rank | Sources | Reason | Fit Error | Lineage |
|------|---------|--------|-----------|---------|
| 1 | `branch+synthesized` | `duplicate` | 8.8291e-05 | method=direct_opt, source=synthesized, candidate=279, polished=true |
| 2 | `block` | `catastrophic_fit` | 5.9846e+06 | method=direct_opt, source=assembled |
| 3 | `branch` | `duplicate` | 1.0508e-04 | method=algebraic, source=imported, candidate=272 |
| 4 | `block` | `catastrophic_fit` | 1.0915e+08 | method=direct_opt, source=assembled |
| 5 | `branch` | `duplicate` | 1.4365e-04 | method=algebraic, source=imported, candidate=266 |
| 6 | `block` | `catastrophic_fit` | 1.4113e+08 | method=direct_opt, source=assembled |
| 7 | `branch` | `duplicate` | 1.1299e-04 | method=algebraic, source=imported, candidate=270 |
| 8 | `block` | `catastrophic_fit` | 1.9877e+10 | method=direct_opt, source=assembled |
| 9 | `branch` | `duplicate` | 1.3535e-04 | method=algebraic, source=imported, candidate=267 |
| 10 | `block` | `catastrophic_fit` | 2.0241e+10 | method=direct_opt, source=assembled |
| 11 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 12 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 13 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 14 | `branch` | `duplicate` | 1.9795e-04 | method=algebraic, source=imported, candidate=251 |
| 15 | `branch` | `duplicate` | 1.8195e-04 | method=algebraic, source=imported, candidate=255 |
| 16 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 17 | `branch` | `duplicate` | 2.0478e-04 | method=algebraic, source=imported, candidate=253 |
| 18 | `block` | `catastrophic_fit` | 1.0996e+16 | method=direct_opt, source=assembled |
| 19 | `branch` | `duplicate` | 2.6337e-04 | method=algebraic, source=imported, candidate=231 |
| 20 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 21 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 22 | `block` | `nonfinite_fit` | Inf | method=direct_opt, source=assembled |
| 23 | `branch` | `duplicate` | 2.3355e-04 | method=algebraic, source=imported, candidate=239 |
| 24 | `branch` | `duplicate` | 2.0981e-04 | method=algebraic, source=imported, candidate=245 |
| 25 | `branch` | `duplicate` | 4.3154e-04 | method=algebraic, source=imported, candidate=224 |
| 26 | `branch` | `duplicate` | 6.0320e-04 | method=algebraic, source=imported, candidate=219 |
| 27 | `branch` | `duplicate` | 2.3988e-04 | method=algebraic, source=imported, candidate=236 |
| 28 | `branch` | `duplicate` | 9.5814e-05 | method=algebraic, source=imported, candidate=278 |
| 29 | `branch` | `duplicate` | 9.2429e-05 | method=algebraic, source=imported, candidate=280 |
| 30 | `branch` | `duplicate` | 9.0469e-04 | method=algebraic, source=imported, candidate=207 |
| 31 | `branch` | `duplicate` | 1.0576e-03 | method=algebraic, source=imported, candidate=206 |
| 32 | `branch` | `duplicate` | 9.9801e-05 | method=algebraic, source=imported, candidate=273 |
| 33 | `branch` | `duplicate` | 1.3323e-03 | method=algebraic, source=imported, candidate=204 |
| 34 | `branch` | `duplicate` | 1.3535e-04 | method=algebraic, source=imported, candidate=268 |
| 35 | `branch` | `duplicate` | 1.4365e-04 | method=algebraic, source=imported, candidate=265 |
| 36 | `branch` | `duplicate` | 1.0508e-04 | method=algebraic, source=imported, candidate=271 |
| 37 | `branch` | `duplicate` | 1.4954e-03 | method=algebraic, source=imported, candidate=202 |
| 38 | `branch` | `duplicate` | 1.5392e-04 | method=algebraic, source=imported, candidate=259 |
| 39 | `branch` | `duplicate` | 9.7065e-05 | method=algebraic, source=imported, candidate=276 |
| 40 | `branch` | `duplicate` | 1.7233e-03 | method=algebraic, source=imported, candidate=199 |
| 41 | `branch` | `duplicate` | 1.9795e-04 | method=algebraic, source=imported, candidate=252 |
| 42 | `branch` | `duplicate` | 2.0818e-04 | method=algebraic, source=imported, candidate=249 |
| 43 | `branch` | `duplicate` | 1.1299e-04 | method=algebraic, source=imported, candidate=269 |
| 44 | `branch` | `duplicate` | 1.6379e-03 | method=algebraic, source=imported, candidate=198 |
| 45 | `branch` | `duplicate` | 2.0380e-03 | method=algebraic, source=imported, candidate=186 |
| 46 | `branch` | `duplicate` | 5.0333e-04 | method=algebraic, source=imported, candidate=218 |
| 47 | `branch` | `duplicate` | 1.6685e-04 | method=algebraic, source=imported, candidate=258 |
| 48 | `branch` | `duplicate` | 5.6675e-04 | method=algebraic, source=imported, candidate=214 |
| 49 | `branch` | `duplicate` | 7.0718e-04 | method=algebraic, source=imported, candidate=209 |
| 50 | `branch` | `duplicate` | 2.0709e-03 | method=algebraic, source=imported, candidate=178 |
| 51 | `branch` | `duplicate` | 2.6337e-04 | method=algebraic, source=imported, candidate=232 |
| 52 | `branch` | `duplicate` | 2.4270e-04 | method=algebraic, source=imported, candidate=241 |
| 53 | `branch` | `duplicate` | 3.4966e-04 | method=algebraic, source=imported, candidate=225 |
| 54 | `branch` | `duplicate` | 1.4895e-04 | method=algebraic, source=imported, candidate=264 |
| 55 | `branch` | `duplicate` | 2.6205e-03 | method=algebraic, source=imported, candidate=163 |
| 56 | `branch` | `duplicate` | 2.6822e-04 | method=algebraic, source=imported, candidate=234 |
| 57 | `branch` | `duplicate` | 3.0674e-03 | method=algebraic, source=imported, candidate=173 |
| 58 | `branch` | `duplicate` | 2.0478e-04 | method=algebraic, source=imported, candidate=254 |
| 59 | `branch` | `duplicate` | 1.8195e-04 | method=algebraic, source=imported, candidate=256 |
| 60 | `branch` | `duplicate` | 3.3327e-03 | method=algebraic, source=imported, candidate=159 |
| 61 | `branch` | `duplicate` | 2.7173e-04 | method=algebraic, source=imported, candidate=227 |
| 62 | `branch` | `duplicate` | 7.4315e-04 | method=algebraic, source=imported, candidate=212 |
| 63 | `branch` | `duplicate` | 2.0981e-04 | method=algebraic, source=imported, candidate=246 |
| 64 | `branch` | `duplicate` | 3.7610e-03 | method=algebraic, source=imported, candidate=157 |
| 65 | `branch` | `duplicate` | 2.2173e-04 | method=algebraic, source=imported, candidate=248 |
| 66 | `branch` | `duplicate` | 3.1544e-03 | method=algebraic, source=imported, candidate=184 |
| 67 | `branch` | `duplicate` | 2.3936e-04 | method=algebraic, source=imported, candidate=237 |
| 68 | `branch` | `duplicate` | 2.3355e-04 | method=algebraic, source=imported, candidate=240 |
| 69 | `branch` | `duplicate` | 3.7023e-03 | method=algebraic, source=imported, candidate=169 |
| 70 | `branch` | `duplicate` | 4.9453e-04 | method=algebraic, source=imported, candidate=222 |
| 71 | `branch` | `duplicate` | 2.5123e-04 | method=algebraic, source=imported, candidate=230 |
| 72 | `branch` | `duplicate` | 4.3154e-04 | method=algebraic, source=imported, candidate=223 |
| 73 | `branch` | `duplicate` | 2.4689e-04 | method=algebraic, source=imported, candidate=244 |
| 74 | `branch` | `duplicate` | 5.5913e-04 | method=algebraic, source=imported, candidate=215 |
| 75 | `branch` | `duplicate` | 3.1038e-03 | method=algebraic, source=imported, candidate=166 |
| 76 | `branch` | `duplicate` | 2.2666e-03 | method=algebraic, source=imported, candidate=171 |
| 77 | `branch` | `duplicate` | 4.7409e-03 | method=algebraic, source=imported, candidate=145 |
| 78 | `branch` | `duplicate` | 2.3988e-04 | method=algebraic, source=imported, candidate=235 |
| 79 | `branch` | `duplicate` | 1.6505e-03 | method=algebraic, source=imported, candidate=190 |
| 80 | `branch` | `duplicate` | 5.8658e-03 | method=algebraic, source=imported, candidate=147 |
| 81 | `branch` | `duplicate` | 5.6675e-04 | method=algebraic, source=imported, candidate=213 |
| 82 | `branch` | `duplicate` | 3.0773e-03 | method=algebraic, source=imported, candidate=179 |
| 83 | `branch` | `duplicate` | 5.0333e-04 | method=algebraic, source=imported, candidate=217 |
| 84 | `branch` | `duplicate` | 4.8806e-03 | method=algebraic, source=imported, candidate=154 |
| 85 | `branch` | `duplicate` | 6.0320e-04 | method=algebraic, source=imported, candidate=220 |
| 86 | `branch` | `duplicate` | 9.0469e-04 | method=algebraic, source=imported, candidate=208 |
| 87 | `branch` | `duplicate` | 1.0576e-03 | method=algebraic, source=imported, candidate=205 |
| 88 | `branch` | `duplicate` | 1.6992e-03 | method=algebraic, source=imported, candidate=192 |
| 89 | `branch` | `duplicate` | 1.1199e-02 | method=algebraic, source=imported, candidate=128 |
| 90 | `branch` | `duplicate` | 1.6379e-03 | method=algebraic, source=imported, candidate=197 |
| 91 | `branch` | `duplicate` | 1.3323e-03 | method=algebraic, source=imported, candidate=203 |
| 92 | `branch` | `duplicate` | 1.6521e-03 | method=algebraic, source=imported, candidate=193 |
| 93 | `branch` | `duplicate` | 7.0718e-04 | method=algebraic, source=imported, candidate=210 |
| 94 | `branch` | `duplicate` | 5.1240e-03 | method=algebraic, source=imported, candidate=152 |
| 95 | `branch` | `duplicate` | 4.9843e-03 | method=algebraic, source=imported, candidate=144 |
| 96 | `branch` | `duplicate` | 1.4954e-03 | method=algebraic, source=imported, candidate=201 |
| 97 | `branch` | `duplicate` | 1.3835e-02 | method=algebraic, source=imported, candidate=118 |
| 98 | `branch` | `duplicate` | 2.1253e-03 | method=algebraic, source=imported, candidate=175 |
| 99 | `branch` | `duplicate` | 2.0380e-03 | method=algebraic, source=imported, candidate=185 |
| 100 | `branch` | `duplicate` | 6.2239e-03 | method=algebraic, source=imported, candidate=150 |
| 101 | `branch` | `duplicate` | 9.5914e-03 | method=algebraic, source=imported, candidate=132 |
| 102 | `branch` | `duplicate` | 2.0709e-03 | method=algebraic, source=imported, candidate=177 |
| 103 | `branch` | `duplicate` | 2.3567e-03 | method=algebraic, source=imported, candidate=167 |
| 104 | `branch` | `duplicate` | 7.4315e-04 | method=algebraic, source=imported, candidate=211 |
| 105 | `branch` | `duplicate` | 2.2647e-02 | method=algebraic, source=imported, candidate=122 |
| 106 | `branch` | `duplicate` | 3.0773e-03 | method=algebraic, source=imported, candidate=180 |
| 107 | `branch` | `duplicate` | 1.7233e-03 | method=algebraic, source=imported, candidate=200 |
| 108 | `branch` | `duplicate` | 9.7684e-03 | method=algebraic, source=imported, candidate=129 |
| 109 | `branch` | `duplicate` | 1.0616e-02 | method=algebraic, source=imported, candidate=133 |
| 110 | `branch` | `duplicate` | 1.2650e-02 | method=algebraic, source=imported, candidate=126 |
| 111 | `branch` | `duplicate` | 2.7130e-02 | method=algebraic, source=imported, candidate=103 |
| 112 | `branch` | `duplicate` | 2.6205e-03 | method=algebraic, source=imported, candidate=164 |
| 113 | `branch` | `duplicate` | 1.6921e-02 | method=algebraic, source=imported, candidate=115 |
| 114 | `branch` | `duplicate` | 2.2163e-02 | method=algebraic, source=imported, candidate=119 |
| 115 | `branch` | `duplicate` | 4.5264e-03 | method=algebraic, source=imported, candidate=155 |
| 116 | `branch` | `duplicate` | 1.1447e-02 | method=algebraic, source=imported, candidate=139 |
| 117 | `branch` | `duplicate` | 1.7632e-02 | method=algebraic, source=imported, candidate=113 |
| 118 | `branch` | `duplicate` | 6.2239e-03 | method=algebraic, source=imported, candidate=149 |
| 119 | `branch` | `duplicate` | 1.6505e-03 | method=algebraic, source=imported, candidate=189 |
| 120 | `branch` | `duplicate` | 1.9658e-02 | method=algebraic, source=imported, candidate=111 |
| 121 | `branch` | `duplicate` | 6.8896e-02 | method=algebraic, source=imported, candidate=96 |
| 122 | `branch` | `duplicate` | 2.3057e-03 | method=algebraic, source=imported, candidate=195 |
| 123 | `branch` | `duplicate` | 2.2666e-03 | method=algebraic, source=imported, candidate=172 |
| 124 | `branch` | `duplicate` | 6.6444e-03 | method=algebraic, source=imported, candidate=141 |
| 125 | `branch` | `duplicate` | 2.1454e-02 | method=algebraic, source=imported, candidate=110 |
| 126 | `branch` | `duplicate` | 6.8889e-03 | method=algebraic, source=imported, candidate=138 |
| 127 | `branch` | `duplicate` | 4.9294e-02 | method=algebraic, source=imported, candidate=101 |
| 128 | `branch` | `duplicate` | 3.0674e-03 | method=algebraic, source=imported, candidate=174 |
| 129 | `branch` | `duplicate` | 9.2711e-02 | method=algebraic, source=imported, candidate=90 |
| 130 | `branch` | `duplicate` | 1.0616e-02 | method=algebraic, source=imported, candidate=134 |
| 131 | `branch` | `duplicate` | 3.3327e-03 | method=algebraic, source=imported, candidate=160 |
| 132 | `branch` | `duplicate` | 1.6992e-03 | method=algebraic, source=imported, candidate=191 |
| 133 | `branch` | `duplicate` | 3.7610e-03 | method=algebraic, source=imported, candidate=158 |
| 134 | `branch` | `duplicate` | 2.4930e-02 | method=algebraic, source=imported, candidate=105 |
| 135 | `branch` | `duplicate` | 1.8247e-03 | method=algebraic, source=imported, candidate=187 |
| 136 | `branch` | `duplicate` | 8.5209e-03 | method=algebraic, source=imported, candidate=136 |
| 137 | `branch` | `duplicate` | 1.1447e-02 | method=algebraic, source=imported, candidate=140 |
| 138 | `branch` | `duplicate` | 5.8658e-03 | method=algebraic, source=imported, candidate=148 |
| 139 | `branch` | `duplicate` | 8.0882e-02 | method=algebraic, source=imported, candidate=87 |
| 140 | `branch` | `duplicate` | 3.1544e-03 | method=algebraic, source=imported, candidate=183 |
| 141 | `branch` | `duplicate` | 1.6821e-01 | method=algebraic, source=imported, candidate=77 |
| 142 | `branch` | `duplicate` | 2.0217e-03 | method=algebraic, source=imported, candidate=181 |
| 143 | `branch` | `duplicate` | 2.1253e-03 | method=algebraic, source=imported, candidate=176 |
| 144 | `branch` | `duplicate` | 2.7829e-02 | method=algebraic, source=imported, candidate=100 |
| 145 | `branch` | `duplicate` | 2.1462e-02 | method=algebraic, source=imported, candidate=124 |
| 146 | `branch` | `duplicate` | 3.5439e-03 | method=algebraic, source=imported, candidate=162 |
| 147 | `branch` | `duplicate` | 5.1240e-03 | method=algebraic, source=imported, candidate=151 |
| 148 | `branch` | `duplicate` | 4.5264e-03 | method=algebraic, source=imported, candidate=156 |
| 149 | `branch` | `duplicate` | 2.3567e-03 | method=algebraic, source=imported, candidate=168 |
| 150 | `branch` | `duplicate` | 3.7023e-03 | method=algebraic, source=imported, candidate=170 |
| 151 | `branch` | `duplicate` | 2.3165e-01 | method=algebraic, source=imported, candidate=72 |
| 152 | `branch` | `duplicate` | 4.7409e-03 | method=algebraic, source=imported, candidate=146 |
| 153 | `branch` | `duplicate` | 3.6748e-02 | method=algebraic, source=imported, candidate=98 |
| 154 | `branch` | `duplicate` | 3.1038e-03 | method=algebraic, source=imported, candidate=165 |
| 155 | `branch` | `duplicate` | 1.0492e-01 | method=algebraic, source=imported, candidate=82 |
| 156 | `branch` | `duplicate` | 6.6444e-03 | method=algebraic, source=imported, candidate=142 |
| 157 | `branch` | `duplicate` | 1.2789e+00 | method=algebraic, source=imported, candidate=64 |
| 158 | `branch` | `duplicate` | 2.1462e-02 | method=algebraic, source=imported, candidate=123 |
| 159 | `branch` | `duplicate` | 4.9843e-03 | method=algebraic, source=imported, candidate=143 |
| 160 | `branch` | `duplicate` | 5.5908e-02 | method=algebraic, source=imported, candidate=93 |
| 161 | `branch` | `duplicate` | 6.8889e-03 | method=algebraic, source=imported, candidate=137 |
| 162 | `branch` | `duplicate` | 1.9637e-02 | method=algebraic, source=imported, candidate=108 |
| 163 | `branch` | `duplicate` | 4.8806e-03 | method=algebraic, source=imported, candidate=153 |
| 164 | `branch` | `duplicate` | 3.8081e+00 | method=algebraic, source=imported, candidate=50 |
| 165 | `branch` | `duplicate` | 9.5914e-03 | method=algebraic, source=imported, candidate=131 |
| 166 | `branch` | `duplicate` | 8.5209e-03 | method=algebraic, source=imported, candidate=135 |
| 167 | `branch` | `duplicate` | 8.4145e-02 | method=algebraic, source=imported, candidate=86 |
| 168 | `branch` | `duplicate` | 9.7684e-03 | method=algebraic, source=imported, candidate=130 |
| 169 | `branch` | `duplicate` | 1.7632e-02 | method=algebraic, source=imported, candidate=114 |
| 170 | `branch` | `duplicate` | 3.1921e-01 | method=algebraic, source=imported, candidate=69 |
| 171 | `branch` | `duplicate` | 1.1199e-02 | method=algebraic, source=imported, candidate=127 |
| 172 | `branch` | `duplicate` | 1.2650e-02 | method=algebraic, source=imported, candidate=125 |
| 173 | `branch` | `duplicate` | 2.5371e+00 | method=algebraic, source=imported, candidate=60 |
| 174 | `branch` | `duplicate` | 1.3475e-01 | method=algebraic, source=imported, candidate=80 |
| 175 | `branch` | `duplicate` | 1.6921e-02 | method=algebraic, source=imported, candidate=116 |
| 176 | `branch` | `duplicate` | 5.7617e-02 | method=algebraic, source=imported, candidate=92 |
| 177 | `branch` | `duplicate` | 1.3835e-02 | method=algebraic, source=imported, candidate=117 |
| 178 | `branch` | `duplicate` | 1.9658e-02 | method=algebraic, source=imported, candidate=112 |
| 179 | `branch` | `duplicate` | 1.0096e-01 | method=algebraic, source=imported, candidate=84 |
| 180 | `branch` | `duplicate` | 2.7829e-02 | method=algebraic, source=imported, candidate=99 |
| 181 | `branch` | `duplicate` | 2.1904e-01 | method=algebraic, source=imported, candidate=76 |
| 182 | `branch` | `duplicate` | 2.8207e-01 | method=algebraic, source=imported, candidate=73 |
| 183 | `branch` | `duplicate` | 8.0882e-02 | method=algebraic, source=imported, candidate=88 |
| 184 | `branch` | `duplicate` | 2.1904e-01 | method=algebraic, source=imported, candidate=75 |
| 185 | `branch` | `duplicate` | 2.4930e-02 | method=algebraic, source=imported, candidate=106 |
| 186 | `branch` | `duplicate` | 5.8697e-01 | method=algebraic, source=imported, candidate=67 |
| 187 | `branch` | `duplicate` | 2.1454e-02 | method=algebraic, source=imported, candidate=109 |
| 188 | `branch` | `duplicate` | 5.5908e-02 | method=algebraic, source=imported, candidate=94 |
| 189 | `branch` | `duplicate` | 1.3475e-01 | method=algebraic, source=imported, candidate=79 |
| 190 | `branch` | `duplicate` | 2.8207e-01 | method=algebraic, source=imported, candidate=74 |
| 191 | `branch` | `duplicate` | 2.2647e-02 | method=algebraic, source=imported, candidate=121 |
| 192 | `branch` | `duplicate` | 3.1921e-01 | method=algebraic, source=imported, candidate=70 |
| 193 | `branch` | `duplicate` | 5.8697e-01 | method=algebraic, source=imported, candidate=68 |
| 194 | `branch` | `duplicate` | 1.6085e+00 | method=algebraic, source=imported, candidate=61 |
| 195 | `branch` | `duplicate` | 2.7130e-02 | method=algebraic, source=imported, candidate=104 |
| 196 | `branch` | `duplicate` | 3.6748e-02 | method=algebraic, source=imported, candidate=97 |
| 197 | `branch` | `duplicate` | 7.4062e-01 | method=algebraic, source=imported, candidate=66 |
| 198 | `branch` | `duplicate` | 2.2163e-02 | method=algebraic, source=imported, candidate=120 |
| 199 | `branch` | `duplicate` | 1.9637e-02 | method=algebraic, source=imported, candidate=107 |
| 200 | `branch` | `duplicate` | 1.6085e+00 | method=algebraic, source=imported, candidate=62 |
| 201 | `branch` | `duplicate` | 3.2038e+00 | method=algebraic, source=imported, candidate=52 |
| 202 | `branch` | `duplicate` | 8.4145e-02 | method=algebraic, source=imported, candidate=85 |
| 203 | `branch` | `duplicate` | 1.2789e+00 | method=algebraic, source=imported, candidate=63 |
| 204 | `branch` | `duplicate` | 2.5371e+00 | method=algebraic, source=imported, candidate=59 |
| 205 | `branch` | `duplicate` | 1.0096e-01 | method=algebraic, source=imported, candidate=83 |
| 206 | `branch` | `duplicate` | 3.8081e+00 | method=algebraic, source=imported, candidate=49 |
| 207 | `branch` | `duplicate` | 3.2038e+00 | method=algebraic, source=imported, candidate=51 |
| 208 | `branch` | `duplicate` | 4.3917e+01 | method=algebraic, source=imported, candidate=43 |
| 209 | `branch` | `duplicate` | 5.7617e-02 | method=algebraic, source=imported, candidate=91 |
| 210 | `branch` | `duplicate` | 6.8896e-02 | method=algebraic, source=imported, candidate=95 |
| 211 | `branch` | `duplicate` | 4.9294e-02 | method=algebraic, source=imported, candidate=102 |
| 212 | `branch` | `duplicate` | 9.2711e-02 | method=algebraic, source=imported, candidate=89 |
| 213 | `branch` | `duplicate` | 1.0492e-01 | method=algebraic, source=imported, candidate=81 |
| 214 | `branch` | `duplicate` | 8.6108e+03 | method=algebraic, source=imported, candidate=11 |
| 215 | `branch` | `duplicate` | 1.6821e-01 | method=algebraic, source=imported, candidate=78 |
| 216 | `branch` | `duplicate` | 1.9937e+04 | method=algebraic, source=imported, candidate=7 |
| 217 | `branch` | `duplicate` | 2.3165e-01 | method=algebraic, source=imported, candidate=71 |
| 218 | `branch` | `duplicate` | 7.4062e-01 | method=algebraic, source=imported, candidate=65 |
| 219 | `branch` | `duplicate` | 1.5242e+05 | method=algebraic, source=imported, candidate=5 |
| 220 | `branch` | `duplicate` | 2.2022e+05 | method=algebraic, source=imported, candidate=1 |
| 221 | `branch` | `duplicate` | 1.7768e+01 | method=algebraic, source=imported, candidate=46 |
| 222 | `branch` | `duplicate` | 1.7768e+01 | method=algebraic, source=imported, candidate=45 |
| 223 | `branch` | `duplicate` | 2.4629e+00 | method=algebraic, source=imported, candidate=57 |
| 224 | `branch` | `duplicate` | 4.3917e+01 | method=algebraic, source=imported, candidate=44 |
| 225 | `branch` | `duplicate` | 2.3876e+00 | method=algebraic, source=imported, candidate=56 |
| 226 | `branch` | `duplicate` | 1.0556e+01 | method=algebraic, source=imported, candidate=48 |
| 227 | `branch` | `duplicate` | 2.4629e+00 | method=algebraic, source=imported, candidate=58 |
| 228 | `branch` | `duplicate` | 2.3876e+00 | method=algebraic, source=imported, candidate=55 |
| 229 | `branch` | `duplicate` | 1.5164e+02 | method=algebraic, source=imported, candidate=32 |
| 230 | `branch` | `duplicate` | 1.3550e+02 | method=algebraic, source=imported, candidate=34 |
| 231 | `branch` | `duplicate` | 1.0556e+01 | method=algebraic, source=imported, candidate=47 |
| 232 | `branch` | `duplicate` | 8.6108e+03 | method=algebraic, source=imported, candidate=12 |
| 233 | `branch` | `duplicate` | 1.0060e+02 | method=algebraic, source=imported, candidate=40 |
| 234 | `branch` | `duplicate` | 1.0549e+02 | method=algebraic, source=imported, candidate=37 |
| 235 | `branch` | `duplicate` | 1.5164e+02 | method=algebraic, source=imported, candidate=31 |
| 236 | `branch` | `duplicate` | 1.9937e+04 | method=algebraic, source=imported, candidate=8 |
| 237 | `branch` | `duplicate` | 1.3550e+02 | method=algebraic, source=imported, candidate=33 |
| 238 | `branch` | `duplicate` | 1.0549e+02 | method=algebraic, source=imported, candidate=38 |
| 239 | `branch` | `duplicate` | 2.3525e+02 | method=algebraic, source=imported, candidate=27 |
| 240 | `branch` | `duplicate` | 1.0060e+02 | method=algebraic, source=imported, candidate=39 |
| 241 | `branch` | `duplicate` | 1.2146e+03 | method=algebraic, source=imported, candidate=17 |
| 242 | `branch` | `duplicate` | 1.6517e+02 | method=algebraic, source=imported, candidate=30 |
| 243 | `branch` | `duplicate` | 4.1208e+02 | method=algebraic, source=imported, candidate=21 |
| 244 | `branch` | `duplicate` | 1.2146e+03 | method=algebraic, source=imported, candidate=18 |
| 245 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=54 |
| 246 | `branch` | `duplicate` | 3.4591e+02 | method=algebraic, source=imported, candidate=24 |
| 247 | `branch` | `duplicate` | 3.2656e+02 | method=algebraic, source=imported, candidate=26 |
| 248 | `branch` | `duplicate` | 1.5242e+05 | method=algebraic, source=imported, candidate=6 |
| 249 | `branch` | `duplicate` | 9.0199e+01 | method=algebraic, source=imported, candidate=42 |
| 250 | `branch` | `duplicate` | 1.1924e+03 | method=algebraic, source=imported, candidate=19 |
| 251 | `branch` | `duplicate` | 3.6005e+05 | method=algebraic, source=imported, candidate=3 |
| 252 | `branch` | `duplicate` | 1.3112e+04 | method=algebraic, source=imported, candidate=9 |
| 253 | `branch` | `duplicate` | 9.0199e+01 | method=algebraic, source=imported, candidate=41 |
| 254 | `branch` | `duplicate` | 2.2022e+05 | method=algebraic, source=imported, candidate=2 |
| 255 | `branch` | `duplicate` | 2.3564e+03 | method=algebraic, source=imported, candidate=16 |
| 256 | `branch` | `duplicate` | 3.6005e+05 | method=algebraic, source=imported, candidate=4 |
| 257 | `branch` | `duplicate` | 2.3525e+02 | method=algebraic, source=imported, candidate=28 |
| 258 | `branch` | `duplicate` | 2.6047e+03 | method=algebraic, source=imported, candidate=13 |
| 259 | `branch` | `duplicate` | 4.1208e+02 | method=algebraic, source=imported, candidate=22 |
| 260 | `branch` | `duplicate` | 1.3112e+04 | method=algebraic, source=imported, candidate=10 |
| 261 | `branch` | `duplicate` | 2.3564e+03 | method=algebraic, source=imported, candidate=15 |
| 262 | `branch` | `duplicate` | 1.1924e+03 | method=algebraic, source=imported, candidate=20 |
| 263 | `branch` | `duplicate` | 2.6047e+03 | method=algebraic, source=imported, candidate=14 |
| 264 | `branch` | `duplicate` | 1.6517e+02 | method=algebraic, source=imported, candidate=29 |
| 265 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=53 |
| 266 | `branch` | `duplicate` | 3.4591e+02 | method=algebraic, source=imported, candidate=23 |
| 267 | `branch` | `duplicate` | 3.2656e+02 | method=algebraic, source=imported, candidate=25 |
| 268 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=36 |
| 269 | `branch` | `nonfinite_fit` | Inf | method=algebraic, source=imported, candidate=35 |

## Reasonable Frontier Seed Pool

| Rank | Sources | Members | Seed Fit Error | Representative Lineage |
|------|---------|---------|----------------|------------------------|
| 1 | `baseline` | `baseline#1` | 2.2022e+05 | method=algebraic, source=imported, candidate=1 |
| 2 | `baseline` | `baseline#2` | 2.2022e+05 | method=algebraic, source=imported, candidate=2 |
| 3 | `baseline` | `baseline#3` | 3.6005e+05 | method=algebraic, source=imported, candidate=3 |
| 4 | `baseline` | `baseline#4` | 3.6005e+05 | method=algebraic, source=imported, candidate=4 |
| 5 | `baseline` | `baseline#5` | 1.5242e+05 | method=algebraic, source=imported, candidate=5 |
| 6 | `baseline` | `baseline#6` | 1.5242e+05 | method=algebraic, source=imported, candidate=6 |
| 7 | `baseline` | `baseline#7` | 1.9937e+04 | method=algebraic, source=imported, candidate=7 |
| 8 | `baseline` | `baseline#8` | 1.9937e+04 | method=algebraic, source=imported, candidate=8 |
| 9 | `baseline` | `baseline#9` | 1.3112e+04 | method=algebraic, source=imported, candidate=9 |
| 10 | `baseline` | `baseline#10` | 1.3112e+04 | method=algebraic, source=imported, candidate=10 |
| 11 | `baseline` | `baseline#11` | 8.6108e+03 | method=algebraic, source=imported, candidate=11 |
| 12 | `baseline` | `baseline#12` | 8.6108e+03 | method=algebraic, source=imported, candidate=12 |
| 13 | `baseline` | `baseline#13` | 2.6047e+03 | method=algebraic, source=imported, candidate=13 |
| 14 | `baseline` | `baseline#14` | 2.6047e+03 | method=algebraic, source=imported, candidate=14 |
| 15 | `baseline` | `baseline#15` | 2.3564e+03 | method=algebraic, source=imported, candidate=15 |
| 16 | `baseline` | `baseline#16` | 2.3564e+03 | method=algebraic, source=imported, candidate=16 |
| 17 | `baseline` | `baseline#17` | 1.2146e+03 | method=algebraic, source=imported, candidate=17 |
| 18 | `baseline` | `baseline#18` | 1.2146e+03 | method=algebraic, source=imported, candidate=18 |
| 19 | `baseline` | `baseline#19` | 1.1924e+03 | method=algebraic, source=imported, candidate=19 |
| 20 | `baseline` | `baseline#20` | 1.1924e+03 | method=algebraic, source=imported, candidate=20 |
| 21 | `baseline` | `baseline#21` | 4.1208e+02 | method=algebraic, source=imported, candidate=21 |
| 22 | `baseline` | `baseline#22` | 4.1208e+02 | method=algebraic, source=imported, candidate=22 |
| 23 | `baseline` | `baseline#23` | 3.4591e+02 | method=algebraic, source=imported, candidate=23 |
| 24 | `baseline` | `baseline#24` | 3.4591e+02 | method=algebraic, source=imported, candidate=24 |
| 25 | `baseline` | `baseline#25` | 3.2656e+02 | method=algebraic, source=imported, candidate=25 |
| 26 | `baseline` | `baseline#26` | 3.2656e+02 | method=algebraic, source=imported, candidate=26 |
| 27 | `baseline` | `baseline#27` | 2.3525e+02 | method=algebraic, source=imported, candidate=27 |
| 28 | `baseline` | `baseline#28` | 2.3525e+02 | method=algebraic, source=imported, candidate=28 |
| 29 | `baseline` | `baseline#29` | 1.6517e+02 | method=algebraic, source=imported, candidate=29 |
| 30 | `baseline` | `baseline#30` | 1.6517e+02 | method=algebraic, source=imported, candidate=30 |
| 31 | `baseline` | `baseline#31` | 1.5164e+02 | method=algebraic, source=imported, candidate=31 |
| 32 | `baseline` | `baseline#32` | 1.5164e+02 | method=algebraic, source=imported, candidate=32 |
| 33 | `baseline` | `baseline#33` | 1.3550e+02 | method=algebraic, source=imported, candidate=33 |
| 34 | `baseline` | `baseline#34` | 1.3550e+02 | method=algebraic, source=imported, candidate=34 |
| 35 | `baseline` | `baseline#35` | Inf | method=algebraic, source=imported, candidate=35 |
| 36 | `baseline` | `baseline#36` | Inf | method=algebraic, source=imported, candidate=36 |
| 37 | `baseline` | `baseline#37` | 1.0549e+02 | method=algebraic, source=imported, candidate=37 |
| 38 | `baseline` | `baseline#38` | 1.0549e+02 | method=algebraic, source=imported, candidate=38 |
| 39 | `baseline` | `baseline#39` | 1.0060e+02 | method=algebraic, source=imported, candidate=39 |
| 40 | `baseline` | `baseline#40` | 1.0060e+02 | method=algebraic, source=imported, candidate=40 |
| 41 | `baseline` | `baseline#41` | 9.0199e+01 | method=algebraic, source=imported, candidate=41 |
| 42 | `baseline` | `baseline#42` | 9.0199e+01 | method=algebraic, source=imported, candidate=42 |
| 43 | `baseline` | `baseline#43` | 4.3917e+01 | method=algebraic, source=imported, candidate=43 |
| 44 | `baseline` | `baseline#44` | 4.3917e+01 | method=algebraic, source=imported, candidate=44 |
| 45 | `baseline` | `baseline#45` | 1.7768e+01 | method=algebraic, source=imported, candidate=45 |
| 46 | `baseline` | `baseline#46` | 1.7768e+01 | method=algebraic, source=imported, candidate=46 |
| 47 | `baseline` | `baseline#47` | 1.0556e+01 | method=algebraic, source=imported, candidate=47 |
| 48 | `baseline` | `baseline#48` | 1.0556e+01 | method=algebraic, source=imported, candidate=48 |
| 49 | `baseline` | `baseline#49` | 3.8081e+00 | method=algebraic, source=imported, candidate=49 |
| 50 | `baseline` | `baseline#50` | 3.8081e+00 | method=algebraic, source=imported, candidate=50 |
| 51 | `baseline` | `baseline#51` | 3.2038e+00 | method=algebraic, source=imported, candidate=51 |
| 52 | `baseline` | `baseline#52` | 3.2038e+00 | method=algebraic, source=imported, candidate=52 |
| 53 | `baseline` | `baseline#53` | Inf | method=algebraic, source=imported, candidate=53 |
| 54 | `baseline` | `baseline#54` | Inf | method=algebraic, source=imported, candidate=54 |
| 55 | `baseline` | `baseline#55` | 2.3876e+00 | method=algebraic, source=imported, candidate=55 |
| 56 | `baseline` | `baseline#56` | 2.3876e+00 | method=algebraic, source=imported, candidate=56 |
| 57 | `baseline` | `baseline#57` | 2.4629e+00 | method=algebraic, source=imported, candidate=57 |
| 58 | `baseline` | `baseline#58` | 2.4629e+00 | method=algebraic, source=imported, candidate=58 |
| 59 | `baseline` | `baseline#59` | 2.5371e+00 | method=algebraic, source=imported, candidate=59 |
| 60 | `baseline` | `baseline#60` | 2.5371e+00 | method=algebraic, source=imported, candidate=60 |
| 61 | `baseline` | `baseline#61` | 1.6085e+00 | method=algebraic, source=imported, candidate=61 |
| 62 | `baseline` | `baseline#62` | 1.6085e+00 | method=algebraic, source=imported, candidate=62 |
| 63 | `baseline` | `baseline#63` | 1.2789e+00 | method=algebraic, source=imported, candidate=63 |
| 64 | `baseline` | `baseline#64` | 1.2789e+00 | method=algebraic, source=imported, candidate=64 |
| 65 | `baseline` | `baseline#65` | 7.4062e-01 | method=algebraic, source=imported, candidate=65 |
| 66 | `baseline` | `baseline#66` | 7.4062e-01 | method=algebraic, source=imported, candidate=66 |
| 67 | `baseline` | `baseline#67` | 5.8697e-01 | method=algebraic, source=imported, candidate=67 |
| 68 | `baseline` | `baseline#68` | 5.8697e-01 | method=algebraic, source=imported, candidate=68 |
| 69 | `baseline` | `baseline#69` | 3.1921e-01 | method=algebraic, source=imported, candidate=69 |
| 70 | `baseline` | `baseline#70` | 3.1921e-01 | method=algebraic, source=imported, candidate=70 |
| 71 | `baseline` | `baseline#71` | 2.3165e-01 | method=algebraic, source=imported, candidate=71 |
| 72 | `baseline` | `baseline#72` | 2.3165e-01 | method=algebraic, source=imported, candidate=72 |
| 73 | `baseline` | `baseline#73` | 2.8207e-01 | method=algebraic, source=imported, candidate=73 |
| 74 | `baseline` | `baseline#74` | 2.8207e-01 | method=algebraic, source=imported, candidate=74 |
| 75 | `baseline` | `baseline#75` | 2.1904e-01 | method=algebraic, source=imported, candidate=75 |
| 76 | `baseline` | `baseline#76` | 2.1904e-01 | method=algebraic, source=imported, candidate=76 |
| 77 | `baseline` | `baseline#77` | 1.6821e-01 | method=algebraic, source=imported, candidate=77 |
| 78 | `baseline` | `baseline#78` | 1.6821e-01 | method=algebraic, source=imported, candidate=78 |
| 79 | `baseline` | `baseline#79` | 1.3475e-01 | method=algebraic, source=imported, candidate=79 |
| 80 | `baseline` | `baseline#80` | 1.3475e-01 | method=algebraic, source=imported, candidate=80 |
| 81 | `baseline` | `baseline#81` | 1.0492e-01 | method=algebraic, source=imported, candidate=81 |
| 82 | `baseline` | `baseline#82` | 1.0492e-01 | method=algebraic, source=imported, candidate=82 |
| 83 | `baseline` | `baseline#83` | 1.0096e-01 | method=algebraic, source=imported, candidate=83 |
| 84 | `baseline` | `baseline#84` | 1.0096e-01 | method=algebraic, source=imported, candidate=84 |
| 85 | `baseline` | `baseline#85` | 8.4145e-02 | method=algebraic, source=imported, candidate=85 |
| 86 | `baseline` | `baseline#86` | 8.4145e-02 | method=algebraic, source=imported, candidate=86 |
| 87 | `baseline` | `baseline#87` | 8.0882e-02 | method=algebraic, source=imported, candidate=87 |
| 88 | `baseline` | `baseline#88` | 8.0882e-02 | method=algebraic, source=imported, candidate=88 |
| 89 | `baseline` | `baseline#89` | 9.2711e-02 | method=algebraic, source=imported, candidate=89 |
| 90 | `baseline` | `baseline#90` | 9.2711e-02 | method=algebraic, source=imported, candidate=90 |
| 91 | `baseline` | `baseline#91` | 5.7617e-02 | method=algebraic, source=imported, candidate=91 |
| 92 | `baseline` | `baseline#92` | 5.7617e-02 | method=algebraic, source=imported, candidate=92 |
| 93 | `baseline` | `baseline#93` | 5.5908e-02 | method=algebraic, source=imported, candidate=93 |
| 94 | `baseline` | `baseline#94` | 5.5908e-02 | method=algebraic, source=imported, candidate=94 |
| 95 | `baseline` | `baseline#95` | 6.8896e-02 | method=algebraic, source=imported, candidate=95 |
| 96 | `baseline` | `baseline#96` | 6.8896e-02 | method=algebraic, source=imported, candidate=96 |
| 97 | `baseline` | `baseline#97` | 3.6748e-02 | method=algebraic, source=imported, candidate=97 |
| 98 | `baseline` | `baseline#98` | 3.6748e-02 | method=algebraic, source=imported, candidate=98 |
| 99 | `baseline` | `baseline#99` | 2.7829e-02 | method=algebraic, source=imported, candidate=99 |
| 100 | `baseline` | `baseline#100` | 2.7829e-02 | method=algebraic, source=imported, candidate=100 |
| 101 | `baseline` | `baseline#101` | 4.9294e-02 | method=algebraic, source=imported, candidate=101 |
| 102 | `baseline` | `baseline#102` | 4.9294e-02 | method=algebraic, source=imported, candidate=102 |
| 103 | `baseline` | `baseline#103` | 2.7130e-02 | method=algebraic, source=imported, candidate=103 |
| 104 | `baseline` | `baseline#104` | 2.7130e-02 | method=algebraic, source=imported, candidate=104 |
| 105 | `baseline` | `baseline#105` | 2.4930e-02 | method=algebraic, source=imported, candidate=105 |
| 106 | `baseline` | `baseline#106` | 2.4930e-02 | method=algebraic, source=imported, candidate=106 |
| 107 | `baseline` | `baseline#107` | 1.9637e-02 | method=algebraic, source=imported, candidate=107 |
| 108 | `baseline` | `baseline#108` | 1.9637e-02 | method=algebraic, source=imported, candidate=108 |
| 109 | `baseline` | `baseline#109` | 2.1454e-02 | method=algebraic, source=imported, candidate=109 |
| 110 | `baseline` | `baseline#110` | 2.1454e-02 | method=algebraic, source=imported, candidate=110 |
| 111 | `baseline` | `baseline#111` | 1.9658e-02 | method=algebraic, source=imported, candidate=111 |
| 112 | `baseline` | `baseline#112` | 1.9658e-02 | method=algebraic, source=imported, candidate=112 |
| 113 | `baseline` | `baseline#113` | 1.7632e-02 | method=algebraic, source=imported, candidate=113 |
| 114 | `baseline` | `baseline#114` | 1.7632e-02 | method=algebraic, source=imported, candidate=114 |
| 115 | `baseline` | `baseline#115` | 1.6921e-02 | method=algebraic, source=imported, candidate=115 |
| 116 | `baseline` | `baseline#116` | 1.6921e-02 | method=algebraic, source=imported, candidate=116 |
| 117 | `baseline` | `baseline#117` | 1.3835e-02 | method=algebraic, source=imported, candidate=117 |
| 118 | `baseline` | `baseline#118` | 1.3835e-02 | method=algebraic, source=imported, candidate=118 |
| 119 | `baseline` | `baseline#119` | 2.2163e-02 | method=algebraic, source=imported, candidate=119 |
| 120 | `baseline` | `baseline#120` | 2.2163e-02 | method=algebraic, source=imported, candidate=120 |
| 121 | `baseline` | `baseline#121` | 2.2647e-02 | method=algebraic, source=imported, candidate=121 |
| 122 | `baseline` | `baseline#122` | 2.2647e-02 | method=algebraic, source=imported, candidate=122 |
| 123 | `baseline` | `baseline#123` | 2.1462e-02 | method=algebraic, source=imported, candidate=123 |
| 124 | `baseline` | `baseline#124` | 2.1462e-02 | method=algebraic, source=imported, candidate=124 |
| 125 | `baseline` | `baseline#125` | 1.2650e-02 | method=algebraic, source=imported, candidate=125 |
| 126 | `baseline` | `baseline#126` | 1.2650e-02 | method=algebraic, source=imported, candidate=126 |
| 127 | `baseline` | `baseline#127` | 1.1199e-02 | method=algebraic, source=imported, candidate=127 |
| 128 | `baseline` | `baseline#128` | 1.1199e-02 | method=algebraic, source=imported, candidate=128 |
| 129 | `baseline` | `baseline#129` | 9.7684e-03 | method=algebraic, source=imported, candidate=129 |
| 130 | `baseline` | `baseline#130` | 9.7684e-03 | method=algebraic, source=imported, candidate=130 |
| 131 | `baseline` | `baseline#131` | 9.5914e-03 | method=algebraic, source=imported, candidate=131 |
| 132 | `baseline` | `baseline#132` | 9.5914e-03 | method=algebraic, source=imported, candidate=132 |
| 133 | `baseline` | `baseline#133` | 1.0616e-02 | method=algebraic, source=imported, candidate=133 |
| 134 | `baseline` | `baseline#134` | 1.0616e-02 | method=algebraic, source=imported, candidate=134 |
| 135 | `baseline` | `baseline#135` | 8.5209e-03 | method=algebraic, source=imported, candidate=135 |
| 136 | `baseline` | `baseline#136` | 8.5209e-03 | method=algebraic, source=imported, candidate=136 |
| 137 | `baseline` | `baseline#137` | 6.8889e-03 | method=algebraic, source=imported, candidate=137 |
| 138 | `baseline` | `baseline#138` | 6.8889e-03 | method=algebraic, source=imported, candidate=138 |
| 139 | `baseline` | `baseline#139` | 1.1447e-02 | method=algebraic, source=imported, candidate=139 |
| 140 | `baseline` | `baseline#140` | 1.1447e-02 | method=algebraic, source=imported, candidate=140 |
| 141 | `baseline` | `baseline#141` | 6.6444e-03 | method=algebraic, source=imported, candidate=141 |
| 142 | `baseline` | `baseline#142` | 6.6444e-03 | method=algebraic, source=imported, candidate=142 |
| 143 | `baseline` | `baseline#143` | 4.9843e-03 | method=algebraic, source=imported, candidate=143 |
| 144 | `baseline` | `baseline#144` | 4.9843e-03 | method=algebraic, source=imported, candidate=144 |
| 145 | `baseline` | `baseline#145` | 4.7409e-03 | method=algebraic, source=imported, candidate=145 |
| 146 | `baseline` | `baseline#146` | 4.7409e-03 | method=algebraic, source=imported, candidate=146 |
| 147 | `baseline` | `baseline#147` | 5.8658e-03 | method=algebraic, source=imported, candidate=147 |
| 148 | `baseline` | `baseline#148` | 5.8658e-03 | method=algebraic, source=imported, candidate=148 |
| 149 | `baseline` | `baseline#149` | 6.2239e-03 | method=algebraic, source=imported, candidate=149 |
| 150 | `baseline` | `baseline#150` | 6.2239e-03 | method=algebraic, source=imported, candidate=150 |
| 151 | `baseline` | `baseline#151` | 5.1240e-03 | method=algebraic, source=imported, candidate=151 |
| 152 | `baseline` | `baseline#152` | 5.1240e-03 | method=algebraic, source=imported, candidate=152 |
| 153 | `baseline` | `baseline#153` | 4.8806e-03 | method=algebraic, source=imported, candidate=153 |
| 154 | `baseline` | `baseline#154` | 4.8806e-03 | method=algebraic, source=imported, candidate=154 |
| 155 | `baseline` | `baseline#155` | 4.5264e-03 | method=algebraic, source=imported, candidate=155 |
| 156 | `baseline` | `baseline#156` | 4.5264e-03 | method=algebraic, source=imported, candidate=156 |
| 157 | `baseline` | `baseline#157` | 3.7610e-03 | method=algebraic, source=imported, candidate=157 |
| 158 | `baseline` | `baseline#158` | 3.7610e-03 | method=algebraic, source=imported, candidate=158 |
| 159 | `baseline` | `baseline#159` | 3.3327e-03 | method=algebraic, source=imported, candidate=159 |
| 160 | `baseline` | `baseline#160` | 3.3327e-03 | method=algebraic, source=imported, candidate=160 |
| 161 | `baseline` | `baseline#173` | 3.0674e-03 | method=algebraic, source=imported, candidate=173 |
| 162 | `baseline` | `baseline#162` | 3.5439e-03 | method=algebraic, source=imported, candidate=162 |
| 163 | `baseline` | `baseline#163` | 2.6205e-03 | method=algebraic, source=imported, candidate=163 |
| 164 | `baseline` | `baseline#164` | 2.6205e-03 | method=algebraic, source=imported, candidate=164 |
| 165 | `baseline` | `baseline#165` | 3.1038e-03 | method=algebraic, source=imported, candidate=165 |
| 166 | `baseline` | `baseline#166` | 3.1038e-03 | method=algebraic, source=imported, candidate=166 |
| 167 | `baseline` | `baseline#167` | 2.3567e-03 | method=algebraic, source=imported, candidate=167 |
| 168 | `baseline` | `baseline#168` | 2.3567e-03 | method=algebraic, source=imported, candidate=168 |
| 169 | `baseline` | `baseline#169` | 3.7023e-03 | method=algebraic, source=imported, candidate=169 |
| 170 | `baseline` | `baseline#170` | 3.7023e-03 | method=algebraic, source=imported, candidate=170 |
| 171 | `baseline` | `baseline#171` | 2.2666e-03 | method=algebraic, source=imported, candidate=171 |
| 172 | `baseline` | `baseline#172` | 2.2666e-03 | method=algebraic, source=imported, candidate=172 |
| 173 | `baseline` | `baseline#174` | 3.0674e-03 | method=algebraic, source=imported, candidate=174 |
| 174 | `baseline` | `baseline#175` | 2.1253e-03 | method=algebraic, source=imported, candidate=175 |
| 175 | `baseline` | `baseline#176` | 2.1253e-03 | method=algebraic, source=imported, candidate=176 |
| 176 | `baseline` | `baseline#177` | 2.0709e-03 | method=algebraic, source=imported, candidate=177 |
| 177 | `baseline` | `baseline#178` | 2.0709e-03 | method=algebraic, source=imported, candidate=178 |
| 178 | `baseline` | `baseline#179` | 3.0773e-03 | method=algebraic, source=imported, candidate=179 |
| 179 | `baseline` | `baseline#180` | 3.0773e-03 | method=algebraic, source=imported, candidate=180 |
| 180 | `baseline` | `baseline#181` | 2.0217e-03 | method=algebraic, source=imported, candidate=181 |
| 181 | `baseline` | `baseline#192` | 1.6992e-03 | method=algebraic, source=imported, candidate=192 |
| 182 | `baseline` | `baseline#183` | 3.1544e-03 | method=algebraic, source=imported, candidate=183 |
| 183 | `baseline` | `baseline#184` | 3.1544e-03 | method=algebraic, source=imported, candidate=184 |
| 184 | `baseline` | `baseline#185` | 2.0380e-03 | method=algebraic, source=imported, candidate=185 |
| 185 | `baseline` | `baseline#186` | 2.0380e-03 | method=algebraic, source=imported, candidate=186 |
| 186 | `baseline` | `baseline#187` | 1.8247e-03 | method=algebraic, source=imported, candidate=187 |
| 187 | `baseline` | `baseline#189` | 1.6505e-03 | method=algebraic, source=imported, candidate=189 |
| 188 | `baseline` | `baseline#190` | 1.6505e-03 | method=algebraic, source=imported, candidate=190 |
| 189 | `baseline` | `baseline#191` | 1.6992e-03 | method=algebraic, source=imported, candidate=191 |
| 190 | `baseline` | `baseline#193` | 1.6521e-03 | method=algebraic, source=imported, candidate=193 |
| 191 | `baseline` | `baseline#207` | 9.0469e-04 | method=algebraic, source=imported, candidate=207 |
| 192 | `baseline` | `baseline#195` | 2.3057e-03 | method=algebraic, source=imported, candidate=195 |
| 193 | `baseline` | `baseline#199` | 1.7233e-03 | method=algebraic, source=imported, candidate=199 |
| 194 | `baseline` | `baseline#197` | 1.6379e-03 | method=algebraic, source=imported, candidate=197 |
| 195 | `baseline` | `baseline#198` | 1.6379e-03 | method=algebraic, source=imported, candidate=198 |
| 196 | `baseline` | `baseline#200` | 1.7233e-03 | method=algebraic, source=imported, candidate=200 |
| 197 | `baseline` | `baseline#201` | 1.4954e-03 | method=algebraic, source=imported, candidate=201 |
| 198 | `baseline` | `baseline#202` | 1.4954e-03 | method=algebraic, source=imported, candidate=202 |
| 199 | `baseline` | `baseline#203` | 1.3323e-03 | method=algebraic, source=imported, candidate=203 |
| 200 | `baseline` | `baseline#204` | 1.3323e-03 | method=algebraic, source=imported, candidate=204 |
| 201 | `baseline` | `baseline#205` | 1.0576e-03 | method=algebraic, source=imported, candidate=205 |
| 202 | `baseline` | `baseline#206` | 1.0576e-03 | method=algebraic, source=imported, candidate=206 |
| 203 | `baseline` | `baseline#208` | 9.0469e-04 | method=algebraic, source=imported, candidate=208 |
| 204 | `baseline` | `baseline#209` | 7.0718e-04 | method=algebraic, source=imported, candidate=209 |
| 205 | `baseline` | `baseline#210` | 7.0718e-04 | method=algebraic, source=imported, candidate=210 |
| 206 | `baseline` | `baseline#211` | 7.4315e-04 | method=algebraic, source=imported, candidate=211 |
| 207 | `baseline` | `baseline#212` | 7.4315e-04 | method=algebraic, source=imported, candidate=212 |
| 208 | `baseline` | `baseline#213` | 5.6675e-04 | method=algebraic, source=imported, candidate=213 |
| 209 | `baseline` | `baseline#214` | 5.6675e-04 | method=algebraic, source=imported, candidate=214 |
| 210 | `baseline` | `baseline#215` | 5.5913e-04 | method=algebraic, source=imported, candidate=215 |
| 211 | `baseline` | `baseline#272` | 1.0508e-04 | method=algebraic, source=imported, candidate=272 |
| 212 | `baseline` | `baseline#217` | 5.0333e-04 | method=algebraic, source=imported, candidate=217 |
| 213 | `baseline` | `baseline#218` | 5.0333e-04 | method=algebraic, source=imported, candidate=218 |
| 214 | `baseline` | `baseline#219` | 6.0320e-04 | method=algebraic, source=imported, candidate=219 |
| 215 | `baseline` | `baseline#220` | 6.0320e-04 | method=algebraic, source=imported, candidate=220 |
| 216 | `baseline` | `baseline#222` | 4.9453e-04 | method=algebraic, source=imported, candidate=222 |
| 217 | `baseline` | `baseline#223` | 4.3154e-04 | method=algebraic, source=imported, candidate=223 |
| 218 | `baseline` | `baseline#224` | 4.3154e-04 | method=algebraic, source=imported, candidate=224 |
| 219 | `baseline` | `baseline#225` | 3.4966e-04 | method=algebraic, source=imported, candidate=225 |
| 220 | `baseline` | `baseline#231` | 2.6337e-04 | method=algebraic, source=imported, candidate=231 |
| 221 | `baseline` | `baseline#227` | 2.7173e-04 | method=algebraic, source=imported, candidate=227 |
| 222 | `baseline` | `baseline#251` | 1.9795e-04 | method=algebraic, source=imported, candidate=251 |
| 223 | `baseline` | `baseline#239` | 2.3355e-04 | method=algebraic, source=imported, candidate=239 |
| 224 | `baseline` | `baseline#230` | 2.5123e-04 | method=algebraic, source=imported, candidate=230 |
| 225 | `baseline` | `baseline#232` | 2.6337e-04 | method=algebraic, source=imported, candidate=232 |
| 226 | `baseline` | `baseline#234` | 2.6822e-04 | method=algebraic, source=imported, candidate=234 |
| 227 | `baseline` | `baseline#235` | 2.3988e-04 | method=algebraic, source=imported, candidate=235 |
| 228 | `baseline` | `baseline#236` | 2.3988e-04 | method=algebraic, source=imported, candidate=236 |
| 229 | `baseline` | `baseline#237` | 2.3936e-04 | method=algebraic, source=imported, candidate=237 |
| 230 | `baseline` | `baseline#240` | 2.3355e-04 | method=algebraic, source=imported, candidate=240 |
| 231 | `baseline` | `baseline#241` | 2.4270e-04 | method=algebraic, source=imported, candidate=241 |
| 232 | `baseline` | `baseline#253` | 2.0478e-04 | method=algebraic, source=imported, candidate=253 |
| 233 | `baseline` | `baseline#244` | 2.4689e-04 | method=algebraic, source=imported, candidate=244 |
| 234 | `baseline` | `baseline#245` | 2.0981e-04 | method=algebraic, source=imported, candidate=245 |
| 235 | `baseline` | `baseline#246` | 2.0981e-04 | method=algebraic, source=imported, candidate=246 |
| 236 | `baseline` | `baseline#255` | 1.8195e-04 | method=algebraic, source=imported, candidate=255 |
| 237 | `baseline` | `baseline#248` | 2.2173e-04 | method=algebraic, source=imported, candidate=248 |
| 238 | `baseline` | `baseline#249` | 2.0818e-04 | method=algebraic, source=imported, candidate=249 |
| 239 | `baseline` | `baseline#277` | 9.5814e-05 | method=algebraic, source=imported, candidate=277 |
| 240 | `baseline` | `baseline#252` | 1.9795e-04 | method=algebraic, source=imported, candidate=252 |
| 241 | `baseline` | `baseline#254` | 2.0478e-04 | method=algebraic, source=imported, candidate=254 |
| 242 | `baseline` | `baseline#256` | 1.8195e-04 | method=algebraic, source=imported, candidate=256 |
| 243 | `baseline` | `baseline#258` | 1.6685e-04 | method=algebraic, source=imported, candidate=258 |
| 244 | `baseline` | `baseline#259` | 1.5392e-04 | method=algebraic, source=imported, candidate=259 |
| 245 | `baseline` | `baseline#270` | 1.1299e-04 | method=algebraic, source=imported, candidate=270 |
| 246 | `baseline` | `baseline#280` | 9.2429e-05 | method=algebraic, source=imported, candidate=280 |
| 247 | `baseline` | `baseline#263` | 1.4895e-04 | method=algebraic, source=imported, candidate=263 |
| 248 | `baseline` | `baseline#264` | 1.4895e-04 | method=algebraic, source=imported, candidate=264 |
| 249 | `baseline` | `baseline#265` | 1.4365e-04 | method=algebraic, source=imported, candidate=265 |
| 250 | `baseline` | `baseline#267` | 1.3535e-04 | method=algebraic, source=imported, candidate=267 |
| 251 | `baseline` | `baseline#268` | 1.3535e-04 | method=algebraic, source=imported, candidate=268 |
| 252 | `baseline` | `baseline#269` | 1.1299e-04 | method=algebraic, source=imported, candidate=269 |
| 253 | `baseline` | `baseline#271` | 1.0508e-04 | method=algebraic, source=imported, candidate=271 |
| 254 | `baseline` | `baseline#273` | 9.9801e-05 | method=algebraic, source=imported, candidate=273 |
| 255 | `baseline` | `baseline#279` | 9.2429e-05 | method=algebraic, source=imported, candidate=279 |
| 256 | `baseline` | `baseline#276` | 9.7065e-05 | method=algebraic, source=imported, candidate=276 |
| 257 | `baseline` | `baseline#278` | 9.5814e-05 | method=algebraic, source=imported, candidate=278 |
| 258 | `block` | `block#1, block#2` | 1.0587e-01 | method=direct_opt, source=assembled |
| 259 | `branch` | `branch#23, branch#29` | 4.9453e-04 | method=algebraic, source=imported, candidate=221 |

## Frontier Finalists

| Finalist | Source Mix | Members | Fit Error | Combined RMSE | Near-Bound Count | Margin | Lineage |
|----------|------------|---------|-----------|---------------|------------------|--------|---------|
| 1 | `baseline` | 121 | 8.8291e-05 | 1130.42% | 0 | 0.5000 | method=algebraic, source=imported, candidate=25, polished=true |
| 2 | `mixed` | 108 | 8.8291e-05 | 0.01% | 0 | 0.5000 | method=algebraic, source=imported, candidate=105, polished=true |
| 3 | `baseline` | 2 | 1.4961e-02 | 11599.80% | 0 | 0.5000 | method=algebraic, source=imported, candidate=71, polished=true |
| 4 | `baseline` | 1 | 8.8948e-05 | 1127.61% | 0 | 0.5000 | method=algebraic, source=imported, candidate=22, polished=true |
| 5 | `baseline` | 1 | 1.0825e-02 | 17837.04% | 0 | 0.5000 | method=algebraic, source=imported, candidate=12, polished=true |
| 6 | `baseline` | 1 | 1.1453e-02 | 30582.20% | 0 | 0.5000 | method=algebraic, source=imported, candidate=78, polished=true |
| 7 | `baseline` | 1 | 1.1464e-02 | 31008.33% | 0 | 0.5000 | method=algebraic, source=imported, candidate=8, polished=true |
| 8 | `baseline` | 1 | 1.1911e-02 | 62219.31% | 0 | 0.5000 | method=algebraic, source=imported, candidate=81, polished=true |
| 9 | `baseline` | 1 | 1.2129e-02 | 120347.78% | 0 | 0.5000 | method=algebraic, source=imported, candidate=6, polished=true |
| 10 | `baseline` | 1 | 1.2189e-02 | 161634.91% | 0 | 0.5000 | method=algebraic, source=imported, candidate=2, polished=true |
| 11 | `baseline` | 1 | 1.8844e-02 | 4984.37% | 0 | 0.5000 | method=algebraic, source=imported, candidate=63, polished=true |
| 12 | `baseline` | 1 | 2.1448e-02 | 3705.94% | 0 | 0.5000 | method=algebraic, source=imported, candidate=59, polished=true |
| 13 | `baseline` | 1 | 2.2052e-02 | 3532.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=49, polished=true |
| 14 | `baseline` | 1 | 1.1624e-01 | 653.23% | 0 | 0.5000 | method=algebraic, source=imported, candidate=45, polished=true |
| 15 | `baseline` | 1 | 9.4095e-01 | 179009.51% | 0 | 0.5000 | method=algebraic, source=imported, candidate=9, polished=true |
| 16 | `baseline` | 1 | 9.4095e-01 | 245104.92% | 0 | 0.5000 | method=algebraic, source=imported, candidate=21, polished=true |
| 17 | `baseline` | 1 | 9.4143e-01 | 187653.57% | 0 | 0.5000 | method=algebraic, source=imported, candidate=17, polished=true |
| 18 | `baseline` | 1 | 2.3876e+00 | 206213.34% | 0 | 0.5000 | method=algebraic, source=imported, candidate=55, polished=true |
| 19 | `baseline` | 1 | 3.8192e+00 | 275566.45% | 0 | 0.5000 | method=algebraic, source=imported, candidate=39, polished=true |
| 20 | `baseline` | 1 | 6.3875e+00 | 317143.75% | 0 | 0.5000 | method=algebraic, source=imported, candidate=15, polished=true |
| 21 | `baseline` | 1 | 6.8012e+00 | 190023.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=42, polished=true |
| 22 | `baseline` | 1 | 7.4436e+00 | 293317.89% | 0 | 0.5000 | method=algebraic, source=imported, candidate=14, polished=true |
| 23 | `baseline` | 1 | 7.8474e+00 | 1081762.22% | 0 | 0.5000 | method=algebraic, source=imported, candidate=16, polished=true |
| 24 | `baseline` | 1 | 8.2562e+00 | 184855.52% | 0 | 0.5000 | method=algebraic, source=imported, candidate=18, polished=true |
| 25 | `baseline` | 1 | 1.1022e+01 | 1401421.85% | 0 | 0.5000 | method=algebraic, source=imported, candidate=13, polished=true |
| 26 | `baseline` | 1 | 1.3115e+01 | 142309.24% | 0 | 0.5000 | method=algebraic, source=imported, candidate=10, polished=true |
| 27 | `baseline` | 1 | 8.5501e+04 | 72668.82% | 0 | 0.5000 | method=algebraic, source=imported, candidate=4, polished=true |
| 28 | `baseline` | 1 | Inf | 1748073.42% | 0 | 0.5000 | method=algebraic, source=imported, candidate=35, polished=true |
| 29 | `baseline` | 1 | Inf | 241946.37% | 0 | 0.5000 | method=algebraic, source=imported, candidate=36, polished=true |
| 30 | `baseline` | 1 | Inf | 1748073.41% | 0 | 0.5000 | method=algebraic, source=imported, candidate=53, polished=true |
| 31 | `baseline` | 1 | Inf | 326583.41% | 0 | 0.5000 | method=algebraic, source=imported, candidate=54, polished=true |

## Frontier Polished Seed Results

| Rank | Sources | Seed Fit Error | Polished Fit Error | Polished Combined RMSE | Polish s | Error |
|------|---------|----------------|--------------------|------------------------|----------|-------|
| 1 | `baseline` | 2.2022e+05 | 8.8291e-05 | 1130.42% | 2.737 | `` |
| 2 | `baseline` | 2.2022e+05 | 1.2189e-02 | 161634.91% | 3.270 | `` |
| 3 | `baseline` | 3.6005e+05 | 8.8291e-05 | 0.01% | 1.981 | `` |
| 4 | `baseline` | 3.6005e+05 | 8.5501e+04 | 72668.82% | 3.557 | `` |
| 5 | `baseline` | 1.5242e+05 | 8.8291e-05 | 1130.42% | 3.333 | `` |
| 6 | `baseline` | 1.5242e+05 | 1.2129e-02 | 120347.78% | 3.448 | `` |
| 7 | `baseline` | 1.9937e+04 | 8.8291e-05 | 1130.42% | 2.236 | `` |
| 8 | `baseline` | 1.9937e+04 | 1.1464e-02 | 31008.33% | 3.358 | `` |
| 9 | `baseline` | 1.3112e+04 | 9.4095e-01 | 179009.51% | 6.764 | `` |
| 10 | `baseline` | 1.3112e+04 | 1.3115e+01 | 142309.24% | 4.038 | `` |
| 11 | `baseline` | 8.6108e+03 | 8.8291e-05 | 1130.42% | 1.917 | `` |
| 12 | `baseline` | 8.6108e+03 | 1.0825e-02 | 17837.04% | 3.146 | `` |
| 13 | `baseline` | 2.6047e+03 | 1.1022e+01 | 1401421.85% | 1.711 | `` |
| 14 | `baseline` | 2.6047e+03 | 7.4436e+00 | 293317.89% | 3.763 | `` |
| 15 | `baseline` | 2.3564e+03 | 6.3875e+00 | 317143.75% | 3.607 | `` |
| 16 | `baseline` | 2.3564e+03 | 7.8474e+00 | 1081762.22% | 1.960 | `` |
| 17 | `baseline` | 1.2146e+03 | 9.4143e-01 | 187653.57% | 2.751 | `` |
| 18 | `baseline` | 1.2146e+03 | 8.2562e+00 | 184855.52% | 1.626 | `` |
| 19 | `baseline` | 1.1924e+03 | 8.8291e-05 | 0.01% | 2.566 | `` |
| 20 | `baseline` | 1.1924e+03 | 8.8291e-05 | 1130.42% | 3.164 | `` |
| 21 | `baseline` | 4.1208e+02 | 9.4095e-01 | 245104.92% | 3.466 | `` |
| 22 | `baseline` | 4.1208e+02 | 8.8948e-05 | 1127.61% | 4.747 | `` |
| 23 | `baseline` | 3.4591e+02 | 8.8291e-05 | 1130.42% | 3.435 | `` |
| 24 | `baseline` | 3.4591e+02 | 8.8291e-05 | 0.01% | 3.163 | `` |
| 25 | `baseline` | 3.2656e+02 | 8.8291e-05 | 1130.42% | 3.512 | `` |
| 26 | `baseline` | 3.2656e+02 | 8.8291e-05 | 0.01% | 2.987 | `` |
| 27 | `baseline` | 2.3525e+02 | 8.8291e-05 | 0.01% | 2.546 | `` |
| 28 | `baseline` | 2.3525e+02 | 8.8291e-05 | 1130.42% | 3.032 | `` |
| 29 | `baseline` | 1.6517e+02 | 8.8291e-05 | 1130.42% | 4.255 | `` |
| 30 | `baseline` | 1.6517e+02 | 8.8291e-05 | 0.01% | 3.541 | `` |
| 31 | `baseline` | 1.5164e+02 | 8.8291e-05 | 1130.42% | 3.164 | `` |
| 32 | `baseline` | 1.5164e+02 | 8.8291e-05 | 0.01% | 2.162 | `` |
| 33 | `baseline` | 1.3550e+02 | 8.8291e-05 | 1130.42% | 2.786 | `` |
| 34 | `baseline` | 1.3550e+02 | 8.8291e-05 | 0.01% | 1.902 | `` |
| 35 | `baseline` | Inf | Inf | 1748073.42% | 0.291 | `` |
| 36 | `baseline` | Inf | Inf | 241946.37% | 0.092 | `` |
| 37 | `baseline` | 1.0549e+02 | 8.8291e-05 | 0.01% | 2.324 | `` |
| 38 | `baseline` | 1.0549e+02 | 8.8291e-05 | 1130.42% | 3.079 | `` |
| 39 | `baseline` | 1.0060e+02 | 3.8192e+00 | 275566.45% | 1.093 | `` |
| 40 | `baseline` | 1.0060e+02 | 8.8291e-05 | 0.01% | 3.375 | `` |
| 41 | `baseline` | 9.0199e+01 | 8.8291e-05 | 1130.42% | 3.056 | `` |
| 42 | `baseline` | 9.0199e+01 | 6.8012e+00 | 190023.89% | 2.765 | `` |
| 43 | `baseline` | 4.3917e+01 | 8.8291e-05 | 0.01% | 0.617 | `` |
| 44 | `baseline` | 4.3917e+01 | 1.4964e-02 | 11589.92% | 3.233 | `` |
| 45 | `baseline` | 1.7768e+01 | 1.1624e-01 | 653.23% | 3.160 | `` |
| 46 | `baseline` | 1.7768e+01 | 8.8291e-05 | 0.01% | 0.645 | `` |
| 47 | `baseline` | 1.0556e+01 | 8.8291e-05 | 1130.42% | 2.979 | `` |
| 48 | `baseline` | 1.0556e+01 | 8.8291e-05 | 0.01% | 2.392 | `` |
| 49 | `baseline` | 3.8081e+00 | 2.2052e-02 | 3532.51% | 3.401 | `` |
| 50 | `baseline` | 3.8081e+00 | 8.8291e-05 | 0.01% | 0.406 | `` |
| 51 | `baseline` | 3.2038e+00 | 8.8291e-05 | 1130.42% | 1.929 | `` |
| 52 | `baseline` | 3.2038e+00 | 8.8291e-05 | 0.01% | 0.426 | `` |
| 53 | `baseline` | Inf | Inf | 1748073.41% | 0.084 | `` |
| 54 | `baseline` | Inf | Inf | 326583.41% | 0.083 | `` |
| 55 | `baseline` | 2.3876e+00 | 2.3876e+00 | 206213.34% | 0.560 | `` |
| 56 | `baseline` | 2.3876e+00 | 8.8291e-05 | 0.01% | 1.876 | `` |
| 57 | `baseline` | 2.4629e+00 | 8.8291e-05 | 0.01% | 1.488 | `` |
| 58 | `baseline` | 2.4629e+00 | 8.8291e-05 | 1130.42% | 2.630 | `` |
| 59 | `baseline` | 2.5371e+00 | 2.1448e-02 | 3705.94% | 3.269 | `` |
| 60 | `baseline` | 2.5371e+00 | 8.8291e-05 | 0.01% | 0.576 | `` |
| 61 | `baseline` | 1.6085e+00 | 8.8291e-05 | 0.01% | 0.318 | `` |
| 62 | `baseline` | 1.6085e+00 | 8.8291e-05 | 1130.42% | 1.797 | `` |
| 63 | `baseline` | 1.2789e+00 | 1.8844e-02 | 4984.37% | 3.485 | `` |
| 64 | `baseline` | 1.2789e+00 | 8.8291e-05 | 0.01% | 0.575 | `` |
| 65 | `baseline` | 7.4062e-01 | 8.8291e-05 | 1130.42% | 0.670 | `` |
| 66 | `baseline` | 7.4062e-01 | 8.8291e-05 | 0.01% | 0.299 | `` |
| 67 | `baseline` | 5.8697e-01 | 8.8291e-05 | 0.01% | 0.334 | `` |
| 68 | `baseline` | 5.8697e-01 | 8.8291e-05 | 1130.42% | 1.377 | `` |
| 69 | `baseline` | 3.1921e-01 | 8.8291e-05 | 0.01% | 0.260 | `` |
| 70 | `baseline` | 3.1921e-01 | 8.8291e-05 | 1130.42% | 1.884 | `` |
| 71 | `baseline` | 2.3165e-01 | 1.4961e-02 | 11599.80% | 3.460 | `` |
| 72 | `baseline` | 2.3165e-01 | 8.8291e-05 | 0.01% | 0.278 | `` |
| 73 | `baseline` | 2.8207e-01 | 8.8291e-05 | 0.01% | 0.368 | `` |
| 74 | `baseline` | 2.8207e-01 | 8.8291e-05 | 1130.42% | 1.474 | `` |
| 75 | `baseline` | 2.1904e-01 | 8.8291e-05 | 1130.42% | 1.565 | `` |
| 76 | `baseline` | 2.1904e-01 | 8.8291e-05 | 0.01% | 0.415 | `` |
| 77 | `baseline` | 1.6821e-01 | 8.8291e-05 | 0.01% | 0.244 | `` |
| 78 | `baseline` | 1.6821e-01 | 1.1453e-02 | 30582.20% | 3.281 | `` |
| 79 | `baseline` | 1.3475e-01 | 8.8291e-05 | 1130.42% | 0.353 | `` |
| 80 | `baseline` | 1.3475e-01 | 8.8291e-05 | 0.01% | 0.353 | `` |
| 81 | `baseline` | 1.0492e-01 | 1.1911e-02 | 62219.31% | 3.577 | `` |
| 82 | `baseline` | 1.0492e-01 | 8.8291e-05 | 0.01% | 0.402 | `` |
| 83 | `baseline` | 1.0096e-01 | 8.8291e-05 | 1130.42% | 0.757 | `` |
| 84 | `baseline` | 1.0096e-01 | 8.8291e-05 | 0.01% | 0.192 | `` |
| 85 | `baseline` | 8.4145e-02 | 8.8291e-05 | 1130.42% | 0.743 | `` |
| 86 | `baseline` | 8.4145e-02 | 8.8291e-05 | 0.01% | 0.350 | `` |
| 87 | `baseline` | 8.0882e-02 | 8.8291e-05 | 0.01% | 0.136 | `` |
| 88 | `baseline` | 8.0882e-02 | 8.8291e-05 | 1130.42% | 1.217 | `` |
| 89 | `baseline` | 9.2711e-02 | 8.8291e-05 | 1130.42% | 3.348 | `` |
| 90 | `baseline` | 9.2711e-02 | 8.8291e-05 | 0.01% | 0.255 | `` |
| 91 | `baseline` | 5.7617e-02 | 8.8291e-05 | 1130.42% | 0.591 | `` |
| 92 | `baseline` | 5.7617e-02 | 8.8291e-05 | 0.01% | 0.153 | `` |
| 93 | `baseline` | 5.5908e-02 | 8.8291e-05 | 0.01% | 0.349 | `` |
| 94 | `baseline` | 5.5908e-02 | 8.8291e-05 | 1130.42% | 0.478 | `` |
| 95 | `baseline` | 6.8896e-02 | 8.8291e-05 | 1130.42% | 2.614 | `` |
| 96 | `baseline` | 6.8896e-02 | 8.8291e-05 | 0.01% | 0.316 | `` |
| 97 | `baseline` | 3.6748e-02 | 8.8291e-05 | 1130.42% | 2.023 | `` |
| 98 | `baseline` | 3.6748e-02 | 8.8291e-05 | 0.01% | 0.137 | `` |
| 99 | `baseline` | 2.7829e-02 | 8.8291e-05 | 1130.42% | 0.295 | `` |
| 100 | `baseline` | 2.7829e-02 | 8.8291e-05 | 0.01% | 0.299 | `` |
| 101 | `baseline` | 4.9294e-02 | 8.8291e-05 | 0.01% | 0.226 | `` |
| 102 | `baseline` | 4.9294e-02 | 8.8291e-05 | 1130.42% | 2.243 | `` |
| 103 | `baseline` | 2.7130e-02 | 8.8291e-05 | 0.01% | 0.347 | `` |
| 104 | `baseline` | 2.7130e-02 | 8.8291e-05 | 1130.42% | 2.121 | `` |
| 105 | `baseline` | 2.4930e-02 | 8.8291e-05 | 0.01% | 0.176 | `` |
| 106 | `baseline` | 2.4930e-02 | 8.8291e-05 | 1130.42% | 1.978 | `` |
| 107 | `baseline` | 1.9637e-02 | 8.8291e-05 | 1130.42% | 0.701 | `` |
| 108 | `baseline` | 1.9637e-02 | 8.8291e-05 | 0.01% | 0.153 | `` |
| 109 | `baseline` | 2.1454e-02 | 8.8291e-05 | 1130.42% | 0.388 | `` |
| 110 | `baseline` | 2.1454e-02 | 8.8291e-05 | 0.01% | 0.155 | `` |
| 111 | `baseline` | 1.9658e-02 | 8.8291e-05 | 0.01% | 0.150 | `` |
| 112 | `baseline` | 1.9658e-02 | 8.8291e-05 | 1130.42% | 0.393 | `` |
| 113 | `baseline` | 1.7632e-02 | 8.8291e-05 | 0.01% | 0.155 | `` |
| 114 | `baseline` | 1.7632e-02 | 8.8291e-05 | 1130.42% | 1.146 | `` |
| 115 | `baseline` | 1.6921e-02 | 8.8291e-05 | 0.01% | 0.119 | `` |
| 116 | `baseline` | 1.6921e-02 | 8.8291e-05 | 1130.42% | 0.578 | `` |
| 117 | `baseline` | 1.3835e-02 | 8.8291e-05 | 1130.42% | 1.513 | `` |
| 118 | `baseline` | 1.3835e-02 | 8.8291e-05 | 0.01% | 0.158 | `` |
| 119 | `baseline` | 2.2163e-02 | 8.8291e-05 | 0.01% | 0.351 | `` |
| 120 | `baseline` | 2.2163e-02 | 8.8291e-05 | 1130.42% | 1.290 | `` |
| 121 | `baseline` | 2.2647e-02 | 8.8291e-05 | 1130.42% | 0.759 | `` |
| 122 | `baseline` | 2.2647e-02 | 8.8291e-05 | 0.01% | 0.185 | `` |
| 123 | `baseline` | 2.1462e-02 | 8.8291e-05 | 1130.42% | 0.840 | `` |
| 124 | `baseline` | 2.1462e-02 | 8.8291e-05 | 0.01% | 0.359 | `` |
| 125 | `baseline` | 1.2650e-02 | 8.8291e-05 | 1130.42% | 1.477 | `` |
| 126 | `baseline` | 1.2650e-02 | 8.8291e-05 | 0.01% | 0.188 | `` |
| 127 | `baseline` | 1.1199e-02 | 8.8291e-05 | 1130.42% | 1.471 | `` |
| 128 | `baseline` | 1.1199e-02 | 8.8291e-05 | 0.01% | 0.316 | `` |
| 129 | `baseline` | 9.7684e-03 | 8.8291e-05 | 0.01% | 0.115 | `` |
| 130 | `baseline` | 9.7684e-03 | 8.8291e-05 | 1130.42% | 0.220 | `` |
| 131 | `baseline` | 9.5914e-03 | 8.8291e-05 | 1130.42% | 1.515 | `` |
| 132 | `baseline` | 9.5914e-03 | 8.8291e-05 | 0.01% | 0.174 | `` |
| 133 | `baseline` | 1.0616e-02 | 8.8291e-05 | 0.01% | 0.139 | `` |
| 134 | `baseline` | 1.0616e-02 | 8.8291e-05 | 1130.42% | 0.575 | `` |
| 135 | `baseline` | 8.5209e-03 | 8.8291e-05 | 1130.42% | 0.643 | `` |
| 136 | `baseline` | 8.5209e-03 | 8.8291e-05 | 0.01% | 0.154 | `` |
| 137 | `baseline` | 6.8889e-03 | 8.8291e-05 | 1130.42% | 0.524 | `` |
| 138 | `baseline` | 6.8889e-03 | 8.8291e-05 | 0.01% | 0.129 | `` |
| 139 | `baseline` | 1.1447e-02 | 8.8291e-05 | 0.01% | 0.181 | `` |
| 140 | `baseline` | 1.1447e-02 | 8.8291e-05 | 1130.42% | 0.974 | `` |
| 141 | `baseline` | 6.6444e-03 | 8.8291e-05 | 0.01% | 0.146 | `` |
| 142 | `baseline` | 6.6444e-03 | 8.8291e-05 | 1130.42% | 0.766 | `` |
| 143 | `baseline` | 4.9843e-03 | 8.8291e-05 | 1130.42% | 0.250 | `` |
| 144 | `baseline` | 4.9843e-03 | 8.8291e-05 | 0.01% | 0.251 | `` |
| 145 | `baseline` | 4.7409e-03 | 8.8291e-05 | 0.01% | 0.200 | `` |
| 146 | `baseline` | 4.7409e-03 | 8.8291e-05 | 1130.42% | 1.199 | `` |
| 147 | `baseline` | 5.8658e-03 | 8.8291e-05 | 0.01% | 0.185 | `` |
| 148 | `baseline` | 5.8658e-03 | 8.8291e-05 | 1130.42% | 0.577 | `` |
| 149 | `baseline` | 6.2239e-03 | 8.8291e-05 | 1130.42% | 0.580 | `` |
| 150 | `baseline` | 6.2239e-03 | 8.8291e-05 | 0.01% | 0.149 | `` |
| 151 | `baseline` | 5.1240e-03 | 8.8291e-05 | 1130.42% | 0.800 | `` |
| 152 | `baseline` | 5.1240e-03 | 8.8291e-05 | 0.01% | 0.308 | `` |
| 153 | `baseline` | 4.8806e-03 | 8.8291e-05 | 1130.42% | 0.422 | `` |
| 154 | `baseline` | 4.8806e-03 | 8.8291e-05 | 0.01% | 0.350 | `` |
| 155 | `baseline` | 4.5264e-03 | 8.8291e-05 | 0.01% | 0.164 | `` |
| 156 | `baseline` | 4.5264e-03 | 8.8291e-05 | 1130.42% | 0.651 | `` |
| 157 | `baseline` | 3.7610e-03 | 8.8291e-05 | 0.01% | 0.200 | `` |
| 158 | `baseline` | 3.7610e-03 | 8.8291e-05 | 1130.42% | 1.146 | `` |
| 159 | `baseline` | 3.3327e-03 | 8.8291e-05 | 0.01% | 0.207 | `` |
| 160 | `baseline` | 3.3327e-03 | 8.8291e-05 | 1130.42% | 1.092 | `` |
| 161 | `baseline` | 3.0674e-03 | 8.8291e-05 | 0.01% | 0.185 | `` |
| 162 | `baseline` | 3.5439e-03 | 8.8291e-05 | 1130.42% | 0.639 | `` |
| 163 | `baseline` | 2.6205e-03 | 8.8291e-05 | 0.01% | 0.180 | `` |
| 164 | `baseline` | 2.6205e-03 | 8.8291e-05 | 1130.42% | 1.054 | `` |
| 165 | `baseline` | 3.1038e-03 | 8.8291e-05 | 1130.42% | 0.446 | `` |
| 166 | `baseline` | 3.1038e-03 | 8.8291e-05 | 0.01% | 0.334 | `` |
| 167 | `baseline` | 2.3567e-03 | 8.8291e-05 | 0.01% | 0.121 | `` |
| 168 | `baseline` | 2.3567e-03 | 8.8291e-05 | 1130.42% | 0.450 | `` |
| 169 | `baseline` | 3.7023e-03 | 8.8291e-05 | 0.01% | 0.155 | `` |
| 170 | `baseline` | 3.7023e-03 | 8.8291e-05 | 1130.42% | 0.791 | `` |
| 171 | `baseline` | 2.2666e-03 | 8.8291e-05 | 0.01% | 0.153 | `` |
| 172 | `baseline` | 2.2666e-03 | 8.8291e-05 | 1130.42% | 0.680 | `` |
| 173 | `baseline` | 3.0674e-03 | 8.8291e-05 | 1130.42% | 0.653 | `` |
| 174 | `baseline` | 2.1253e-03 | 8.8291e-05 | 0.01% | 0.121 | `` |
| 175 | `baseline` | 2.1253e-03 | 8.8291e-05 | 1130.42% | 0.526 | `` |
| 176 | `baseline` | 2.0709e-03 | 8.8291e-05 | 1130.42% | 0.434 | `` |
| 177 | `baseline` | 2.0709e-03 | 8.8291e-05 | 0.01% | 0.119 | `` |
| 178 | `baseline` | 3.0773e-03 | 8.8291e-05 | 0.01% | 0.156 | `` |
| 179 | `baseline` | 3.0773e-03 | 8.8291e-05 | 1130.42% | 0.745 | `` |
| 180 | `baseline` | 2.0217e-03 | 8.8291e-05 | 1130.42% | 0.530 | `` |
| 181 | `baseline` | 1.6992e-03 | 8.8291e-05 | 0.01% | 0.124 | `` |
| 182 | `baseline` | 3.1544e-03 | 8.8291e-05 | 1130.42% | 0.683 | `` |
| 183 | `baseline` | 3.1544e-03 | 8.8291e-05 | 0.01% | 0.362 | `` |
| 184 | `baseline` | 2.0380e-03 | 8.8291e-05 | 1130.42% | 0.679 | `` |
| 185 | `baseline` | 2.0380e-03 | 8.8291e-05 | 0.01% | 0.143 | `` |
| 186 | `baseline` | 1.8247e-03 | 8.8291e-05 | 1130.42% | 0.483 | `` |
| 187 | `baseline` | 1.6505e-03 | 8.8291e-05 | 1130.42% | 0.287 | `` |
| 188 | `baseline` | 1.6505e-03 | 8.8291e-05 | 0.01% | 0.113 | `` |
| 189 | `baseline` | 1.6992e-03 | 8.8291e-05 | 1130.42% | 0.519 | `` |
| 190 | `baseline` | 1.6521e-03 | 8.8291e-05 | 1130.42% | 0.342 | `` |
| 191 | `baseline` | 9.0469e-04 | 8.8291e-05 | 0.01% | 0.099 | `` |
| 192 | `baseline` | 2.3057e-03 | 8.8291e-05 | 1130.42% | 0.639 | `` |
| 193 | `baseline` | 1.7233e-03 | 8.8291e-05 | 0.01% | 0.170 | `` |
| 194 | `baseline` | 1.6379e-03 | 8.8291e-05 | 1130.42% | 0.814 | `` |
| 195 | `baseline` | 1.6379e-03 | 8.8291e-05 | 0.01% | 0.328 | `` |
| 196 | `baseline` | 1.7233e-03 | 8.8291e-05 | 1130.42% | 0.662 | `` |
| 197 | `baseline` | 1.4954e-03 | 8.8291e-05 | 1130.42% | 0.366 | `` |
| 198 | `baseline` | 1.4954e-03 | 8.8291e-05 | 0.01% | 0.316 | `` |
| 199 | `baseline` | 1.3323e-03 | 8.8291e-05 | 1130.42% | 0.359 | `` |
| 200 | `baseline` | 1.3323e-03 | 8.8291e-05 | 0.01% | 0.345 | `` |
| 201 | `baseline` | 1.0576e-03 | 8.8291e-05 | 1130.42% | 0.255 | `` |
| 202 | `baseline` | 1.0576e-03 | 8.8291e-05 | 0.01% | 0.171 | `` |
| 203 | `baseline` | 9.0469e-04 | 8.8291e-05 | 1130.42% | 0.402 | `` |
| 204 | `baseline` | 7.0718e-04 | 8.8291e-05 | 0.01% | 0.189 | `` |
| 205 | `baseline` | 7.0718e-04 | 8.8291e-05 | 1130.42% | 0.730 | `` |
| 206 | `baseline` | 7.4315e-04 | 8.8291e-05 | 1130.42% | 0.417 | `` |
| 207 | `baseline` | 7.4315e-04 | 8.8291e-05 | 0.01% | 0.274 | `` |
| 208 | `baseline` | 5.6675e-04 | 8.8291e-05 | 1130.42% | 0.306 | `` |
| 209 | `baseline` | 5.6675e-04 | 8.8291e-05 | 0.01% | 0.121 | `` |
| 210 | `baseline` | 5.5913e-04 | 8.8291e-05 | 1130.42% | 0.304 | `` |
| 211 | `baseline` | 1.0508e-04 | 8.8291e-05 | 0.01% | 0.116 | `` |
| 212 | `baseline` | 5.0333e-04 | 8.8291e-05 | 1130.42% | 0.206 | `` |
| 213 | `baseline` | 5.0333e-04 | 8.8291e-05 | 0.01% | 0.257 | `` |
| 214 | `baseline` | 6.0320e-04 | 8.8291e-05 | 0.01% | 0.153 | `` |
| 215 | `baseline` | 6.0320e-04 | 8.8291e-05 | 1130.42% | 0.574 | `` |
| 216 | `baseline` | 4.9453e-04 | 8.8291e-05 | 1130.42% | 0.186 | `` |
| 217 | `baseline` | 4.3154e-04 | 8.8291e-05 | 1130.42% | 0.643 | `` |
| 218 | `baseline` | 4.3154e-04 | 8.8291e-05 | 0.01% | 0.152 | `` |
| 219 | `baseline` | 3.4966e-04 | 8.8291e-05 | 1130.42% | 0.428 | `` |
| 220 | `baseline` | 2.6337e-04 | 8.8291e-05 | 0.01% | 0.130 | `` |
| 221 | `baseline` | 2.7173e-04 | 8.8291e-05 | 1130.42% | 0.519 | `` |
| 222 | `baseline` | 1.9795e-04 | 8.8291e-05 | 0.01% | 0.103 | `` |
| 223 | `baseline` | 2.3355e-04 | 8.8291e-05 | 0.01% | 0.127 | `` |
| 224 | `baseline` | 2.5123e-04 | 8.8291e-05 | 1130.42% | 0.559 | `` |
| 225 | `baseline` | 2.6337e-04 | 8.8291e-05 | 1130.42% | 0.383 | `` |
| 226 | `baseline` | 2.6822e-04 | 8.8291e-05 | 1130.42% | 0.527 | `` |
| 227 | `baseline` | 2.3988e-04 | 8.8291e-05 | 1130.42% | 0.467 | `` |
| 228 | `baseline` | 2.3988e-04 | 8.8291e-05 | 0.01% | 0.117 | `` |
| 229 | `baseline` | 2.3936e-04 | 8.8291e-05 | 1130.42% | 0.499 | `` |
| 230 | `baseline` | 2.3355e-04 | 8.8291e-05 | 1130.42% | 0.349 | `` |
| 231 | `baseline` | 2.4270e-04 | 8.8291e-05 | 1130.42% | 0.462 | `` |
| 232 | `baseline` | 2.0478e-04 | 8.8291e-05 | 0.01% | 0.115 | `` |
| 233 | `baseline` | 2.4689e-04 | 8.8291e-05 | 1130.42% | 0.484 | `` |
| 234 | `baseline` | 2.0981e-04 | 8.8291e-05 | 0.01% | 0.115 | `` |
| 235 | `baseline` | 2.0981e-04 | 8.8291e-05 | 1130.42% | 0.183 | `` |
| 236 | `baseline` | 1.8195e-04 | 8.8291e-05 | 0.01% | 0.253 | `` |
| 237 | `baseline` | 2.2173e-04 | 8.8291e-05 | 1130.42% | 0.281 | `` |
| 238 | `baseline` | 2.0818e-04 | 8.8291e-05 | 1130.42% | 0.470 | `` |
| 239 | `baseline` | 9.5814e-05 | 8.8291e-05 | 0.01% | 0.128 | `` |
| 240 | `baseline` | 1.9795e-04 | 8.8291e-05 | 1130.42% | 0.495 | `` |
| 241 | `baseline` | 2.0478e-04 | 8.8291e-05 | 1130.42% | 0.314 | `` |
| 242 | `baseline` | 1.8195e-04 | 8.8291e-05 | 1130.42% | 0.433 | `` |
| 243 | `baseline` | 1.6685e-04 | 8.8291e-05 | 1130.42% | 0.188 | `` |
| 244 | `baseline` | 1.5392e-04 | 8.8291e-05 | 1130.42% | 0.221 | `` |
| 245 | `baseline` | 1.1299e-04 | 8.8291e-05 | 0.01% | 0.248 | `` |
| 246 | `baseline` | 9.2429e-05 | 8.8291e-05 | 1130.42% | 0.229 | `` |
| 247 | `baseline` | 1.4895e-04 | 8.8291e-05 | 0.01% | 0.123 | `` |
| 248 | `baseline` | 1.4895e-04 | 8.8291e-05 | 1130.42% | 0.431 | `` |
| 249 | `baseline` | 1.4365e-04 | 8.8291e-05 | 1130.42% | 0.323 | `` |
| 250 | `baseline` | 1.3535e-04 | 8.8291e-05 | 0.01% | 0.278 | `` |
| 251 | `baseline` | 1.3535e-04 | 8.8291e-05 | 1130.42% | 0.311 | `` |
| 252 | `baseline` | 1.1299e-04 | 8.8291e-05 | 1130.42% | 0.431 | `` |
| 253 | `baseline` | 1.0508e-04 | 8.8291e-05 | 1130.42% | 0.215 | `` |
| 254 | `baseline` | 9.9801e-05 | 8.8291e-05 | 1130.42% | 0.213 | `` |
| 255 | `baseline` | 9.2429e-05 | 8.8291e-05 | 0.01% | 0.243 | `` |
| 256 | `baseline` | 9.7065e-05 | 8.8291e-05 | 1130.42% | 0.120 | `` |
| 257 | `baseline` | 9.5814e-05 | 8.8291e-05 | 1130.42% | 0.210 | `` |
| 258 | `block` | 1.0587e-01 | 8.8291e-05 | 0.01% | 0.354 | `` |
| 259 | `branch` | 4.9453e-04 | 8.8291e-05 | 0.01% | 0.120 | `` |

