# Log-Space Polish Ablation

- Generated: `2026-04-23 00:45:29`
- Basis: imported bilby `odepe_nopolish` pools
- Comparison: same pool, same simulation loss, `:linear` vs `:log_positive` polish
- Benchmark success tolerance: `10%` max relative error

| Case | Saved `amigo2` RMSE | Saved `odepe_polish` RMSE | Linear selected RMSE | Log selected RMSE | Linear best-in-set RMSE | Log best-in-set RMSE | Log status |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `brusselator_5_1em4` | 0.03% | 0.05% | Inf | Inf | Inf | Inf | `ok` |

## Case Notes

### `brusselator_5_1em4`

- Imported raw candidate count: `123`
- Research box override: `script_standard_positive_box` (`[1e-5, 10]` on all polished coordinates)
- Saved references:
  - `amigo2_run` RMSE: 0.03%
  - `odepe_nopolish` RMSE: 0.34%
  - `odepe_polish` RMSE: 0.05%
- Linear polish:
  - status: `ok`
  - selected benchmark RMSE: Inf
  - selected max relative error: Inf
  - selected success: `false`
  - selected local relative RMSE: Inf
  - best-in-set benchmark RMSE: Inf
  - best-in-set local relative RMSE: Inf
  - runtime: `60.440 s`
- Log-positive polish:
  - status: `ok`
  - selected benchmark RMSE: Inf
  - selected max relative error: Inf
  - selected success: `false`
  - selected local relative RMSE: Inf
  - best-in-set benchmark RMSE: Inf
  - best-in-set local relative RMSE: Inf
  - runtime: `2.232 s`
  - vs linear selected benchmark RMSE: `tie`
  - vs linear best-in-set benchmark RMSE: `tie`
  - vs linear selected local relative RMSE: `tie`
  - vs linear best-in-set local relative RMSE: `tie`

