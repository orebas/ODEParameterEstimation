# Residual Polish Ablation: Clarified Views

- Source summary: `/home/orebas/.julia/dev/ODEParameterEstimation/test/../artifacts/diagnostics/residual_polish_ablation_ungated_expanded/summary.md`
- Source table: `/home/orebas/.julia/dev/ODEParameterEstimation/test/../artifacts/diagnostics/residual_polish_ablation_ungated_expanded/summary.tsv`
- Purpose: separate benchmark-like `best-in-set` reporting from operational `fit-selected` reporting, and rename `linear` / `log-positive` to clearer coordinate terms.

## Terminology

- `original-space`: the old `linear` setting. Optimize directly in the original coordinates.
- `log-space`: the old `log-positive` setting. Optimize in `log(x)` and evaluate the objective in `x`.
- `best-in-set`: benchmark-like oracle selection. This is the closest like-for-like view against the bilby benchmark, because the benchmark uses oracle selection via `select_best_estimation(...)` in `summarize_results.py`.
- `fit-selected`: operational selection. This is what the current local pipeline would return when it chooses a winner by fit among analyzed candidates.

## Best-In-Set / Oracle View: Original-Space Arms

| Case | Imported best | Saved `amigo2` | Saved `odepe_polish` | Scalar original-space | Residual LM original-space | FastShortcut original-space | TrustRegion original-space | LeastSquaresOptim LM original-space | LeastSquaresOptim Dogleg original-space | FastLevenbergMarquardt original-space |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 1.22% | 6.9282e-03% | 6.0007e-03% | 7.0667e-03% | 1.22% | Inf | 7.0667e-03% | 7.0667e-03% | 7.0667e-03% | 7.0667e-03% |
| `crauste_7_1em4` | 6445.99% | 19.62% | 167.02% | 6445.99% | 411.66% | Inf | 411.66% | 411.66% | 411.66% | 411.66% |
| `fitzhugh_nagumo_2_1em4` | 6.11% | 1.31% | 3.20% | 1.31% | 6.11% | Inf | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 34.09% | 0.05% | 0.63% | 0.05% | 34.09% | Inf | 0.05% | 0.05% | 0.05% | 0.05% |
| `flexible_arm_0_1em4` | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% |
| `daisy_mamil3_7_1em4` | 3.37% | 3.1820e-03% | 0.40% | 3.1264e-03% | 3.37% | Inf | 3.1264e-03% | 3.1264e-03% | 3.1264e-03% | 3.1264e-03% |
| `daisy_mamil4_6_1em4` | 15.98% | 0.33% | 0.31% | 0.33% | 13.85% | Inf | 0.33% | 0.33% | 0.33% | 0.02% |
| `brusselator_5_1em4` | 0.02% | 0.03% | 0.05% | Inf | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% |
| `forced_lotka_volterra_0_1em4` | 4.10% | 0.00% | 1.1545e-03% | 2.7877e-04% | 4.10% | Inf | 2.7878e-04% | 2.7878e-04% | 2.7878e-04% | 2.7878e-04% |

## Best-In-Set / Oracle View: Log-Space Arms

| Case | Imported best | Saved `amigo2` | Saved `odepe_polish` | Scalar log-space | Residual LM log-space | FastShortcut log-space | TrustRegion log-space | LeastSquaresOptim LM log-space | LeastSquaresOptim Dogleg log-space | FastLevenbergMarquardt log-space |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 1.22% | 6.9282e-03% | 6.0007e-03% | 7.0667e-03% | 1.22% | Inf | 7.0667e-03% | 7.0667e-03% | 7.0667e-03% | 7.0667e-03% |
| `crauste_7_1em4` | 6445.99% | 19.62% | 167.02% | 322.18% | 411.66% | Inf | 394.46% | 411.66% | 411.66% | 411.66% |
| `fitzhugh_nagumo_2_1em4` | 6.11% | 1.31% | 3.20% | 1.31% | 6.11% | Inf | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 34.09% | 0.05% | 0.63% | 0.05% | 34.09% | Inf | 34.09% | 34.09% | 22.00% | 0.05% |
| `flexible_arm_0_1em4` | 6.62% | 0.54% | 3.60% | 6.62% | 6.62% | Inf | 6.62% | 6.62% | 6.62% | 6.62% |
| `daisy_mamil3_7_1em4` | 3.37% | 3.1820e-03% | 0.40% | 3.1264e-03% | 3.37% | Inf | 3.1264e-03% | 3.1264e-03% | 3.1264e-03% | 3.1264e-03% |
| `daisy_mamil4_6_1em4` | 15.98% | 0.33% | 0.31% | 6.48% | 13.85% | Inf | 0.33% | 13.85% | 0.33% | 1.72% |
| `brusselator_5_1em4` | 0.02% | 0.03% | 0.05% | Inf | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% | 0.05% |
| `forced_lotka_volterra_0_1em4` | 4.10% | 0.00% | 1.1545e-03% | 2.7878e-04% | 4.10% | Inf | 2.7878e-04% | 2.7878e-04% | 2.7878e-04% | 2.7878e-04% |

## Fit-Selected / Operational View: Original-Space Arms

| Case | Saved `amigo2` | Saved `odepe_polish` | Scalar original-space | Residual LM original-space | FastShortcut original-space | TrustRegion original-space | LeastSquaresOptim LM original-space | LeastSquaresOptim Dogleg original-space | FastLevenbergMarquardt original-space |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 6.9282e-03% | 6.0007e-03% | 0.01% | 1.22% | N/A | 0.01% | 0.01% | 0.01% | 0.01% |
| `crauste_7_1em4` | 19.62% | 167.02% | 198638.81% | 463991.90% | N/A | 163909.75% | 5775.27% | 163909.75% | 73762.77% |
| `fitzhugh_nagumo_2_1em4` | 1.31% | 3.20% | 1.31% | 6.94% | N/A | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 0.05% | 0.63% | 37.08% | 5763.67% | N/A | 37.08% | 37.08% | 37.08% | 37.08% |
| `flexible_arm_0_1em4` | 0.54% | 3.60% | 32.64% | 34.94% | N/A | 32.61% | 35.26% | 32.61% | 32.61% |
| `daisy_mamil3_7_1em4` | 3.1820e-03% | 0.40% | 0.00% | 4.11% | N/A | 0.00% | 0.00% | 0.00% | 0.00% |
| `daisy_mamil4_6_1em4` | 0.33% | 0.31% | 0.33% | 66.08% | N/A | 25.31% | 0.33% | 25.31% | 0.33% |
| `brusselator_5_1em4` | 0.03% | 0.05% | Inf | 2.32% | 2.32% | 2.32% | 2.32% | 2.32% | 2.32% |
| `forced_lotka_volterra_0_1em4` | 0.00% | 1.1545e-03% | 0.00% | 4.10% | N/A | 0.00% | 0.00% | 0.00% | 0.00% |

## Fit-Selected / Operational View: Log-Space Arms

| Case | Saved `amigo2` | Saved `odepe_polish` | Scalar log-space | Residual LM log-space | FastShortcut log-space | TrustRegion log-space | LeastSquaresOptim LM log-space | LeastSquaresOptim Dogleg log-space | FastLevenbergMarquardt log-space |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 6.9282e-03% | 6.0007e-03% | 0.01% | 1.22% | N/A | 0.01% | 0.01% | 0.01% | 0.01% |
| `crauste_7_1em4` | 19.62% | 167.02% | 1739.10% | 163909.75% | N/A | 486.84% | 106274.32% | 163909.75% | 1209.35% |
| `fitzhugh_nagumo_2_1em4` | 1.31% | 3.20% | 1.31% | 6.94% | N/A | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 0.05% | 0.63% | 0.05% | 109.53% | N/A | 109.94% | 3927675226114354.50% | 22.00% | 0.05% |
| `flexible_arm_0_1em4` | 0.54% | 3.60% | 30.93% | 38.87% | N/A | 32.61% | 32.84% | 34.22% | 34.03% |
| `daisy_mamil3_7_1em4` | 3.1820e-03% | 0.40% | 0.00% | 4.11% | N/A | 0.00% | 0.00% | 0.00% | 0.00% |
| `daisy_mamil4_6_1em4` | 0.33% | 0.31% | 23.65% | 27.86% | N/A | 25.31% | 25.02% | 25.31% | 24.17% |
| `brusselator_5_1em4` | 0.03% | 0.05% | Inf | 2.32% | 2.32% | 2.32% | 2.32% | 2.32% | 2.32% |
| `forced_lotka_volterra_0_1em4` | 0.00% | 1.1545e-03% | 0.00% | 4.10% | N/A | 0.00% | 0.00% | 0.00% | 0.00% |

