# Residual-Vector Polish Ablation

- Generated: `2026-04-23 12:17:59`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: scalar SSE polish vs residual-vector least-squares polish on the same pool
- Research analysis mode: `ungated`
- Residual solver roster: `LeastSquaresOptimJL(:lm)`, `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)`, `LeastSquaresOptimJL(:dogleg)`, `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)`, `FastLevenbergMarquardt.lmsolve!()`, `FastLevenbergMarquardt.lmsolve!() with lb/ub`
- Benchmark success tolerance: `10%` max relative error

| Case | Imported best RMSE | Analyzed imported best RMSE | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Scalar log best | residual LeastSquaresOptim LM log best | residual LeastSquaresOptim LM bounded log best | residual LeastSquaresOptim Dogleg log best | residual LeastSquaresOptim Dogleg bounded log best | residual FastLevenbergMarquardt log best | residual FastLevenbergMarquardt bounded log best |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `daisy_mamil4_6_1em4` | 15.98% | 15.98% | 0.33% | 0.31% | 6.48% | 13.85% | 0.33% | 0.33% | 0.33% | 1.72% | 1.06% |

## Solver Summary vs `scalar + log`

| Arm | Best-in-set vs `scalar_log` | Selected vs `scalar_log` | Median runtime ratio |
| --- | --- | --- | ---: |
| `LeastSquaresOptimJL(:lm)` | 0 better / 0 tie / 1 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.407x |
| `LeastSquaresOptim.optimize!(LevenbergMarquardt(); lower/upper)` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 0.437x |
| `LeastSquaresOptimJL(:dogleg)` | 1 better / 0 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.216x |
| `LeastSquaresOptim.optimize!(Dogleg(); lower/upper)` | 1 better / 0 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.290x |
| `FastLevenbergMarquardt.lmsolve!()` | 1 better / 0 tie / 0 worse / 0 unsupported | 0 better / 0 tie / 1 worse / 0 unsupported | 0.160x |
| `FastLevenbergMarquardt.lmsolve!() with lb/ub` | 1 better / 0 tie / 0 worse / 0 unsupported | 1 better / 0 tie / 0 worse / 0 unsupported | 0.387x |

## Case Notes

### `daisy_mamil4_6_1em4`

- Imported raw candidate count: `119`
- Imported pool stage metrics:
  - imported best benchmark RMSE: 15.98%
  - analyzed imported selected benchmark RMSE: 66.08%
  - analyzed imported best benchmark RMSE: 15.98%
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.33%
  - `odepe_nopolish` RMSE: 33.82%
  - `odepe_polish` RMSE: 0.31%
- scalar original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `386.349 s`
- scalar log-space:
  - status: `ok`
  - selected benchmark RMSE: 23.65%
  - best-in-set benchmark RMSE: 6.48%
  - selected local relative RMSE: 48.11%
  - best-in-set local relative RMSE: 13.60%
  - runtime: `234.905 s`
- residual LeastSquaresOptim LM original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `137.661 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.02%
  - best-in-set benchmark RMSE: 13.85%
  - selected local relative RMSE: 71.61%
  - best-in-set local relative RMSE: 39.20%
  - runtime: `95.508 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM log-space vs scalar log-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `100.899 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `102.597 s`
  - polished representative count: `119`
- residual LeastSquaresOptim LM bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim LM bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `72.860 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `50.729 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual LeastSquaresOptim Dogleg bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `60.146 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.33%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.77%
  - runtime: `68.031 s`
  - polished representative count: `119`
- residual LeastSquaresOptim Dogleg bounded original-space vs scalar original-space best-in-set benchmark RMSE: `worse`
- residual LeastSquaresOptim Dogleg bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt original-space:
  - status: `ok`
  - selected benchmark RMSE: 0.33%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 0.77%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `77.990 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt log-space:
  - status: `ok`
  - selected benchmark RMSE: 24.17%
  - best-in-set benchmark RMSE: 1.72%
  - selected local relative RMSE: 49.82%
  - best-in-set local relative RMSE: 4.14%
  - runtime: `37.622 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt log-space vs scalar log-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded original-space:
  - status: `ok`
  - selected benchmark RMSE: 25.31%
  - best-in-set benchmark RMSE: 0.02%
  - selected local relative RMSE: 53.41%
  - best-in-set local relative RMSE: 0.04%
  - runtime: `89.012 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt bounded log-space:
  - status: `ok`
  - selected benchmark RMSE: 1.06%
  - best-in-set benchmark RMSE: 1.06%
  - selected local relative RMSE: 2.51%
  - best-in-set local relative RMSE: 2.51%
  - runtime: `90.827 s`
  - polished representative count: `119`
- residual FastLevenbergMarquardt bounded original-space vs scalar original-space best-in-set benchmark RMSE: `better`
- residual FastLevenbergMarquardt bounded log-space vs scalar log-space best-in-set benchmark RMSE: `better`

