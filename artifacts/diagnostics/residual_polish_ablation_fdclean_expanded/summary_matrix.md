# Residual Polish Matrix

- Generated: `2026-04-23 00:18:22`
- Source TSV: `/home/orebas/.julia/dev/ODEParameterEstimation/test/../artifacts/diagnostics/residual_polish_ablation_fdclean_expanded/summary.tsv`
- Values: best-in-set benchmark RMSE
- Lower is better

| case | saved amigo | saved odepe_polish | scalar linear | scalar log | LM linear | LM log | TrustRegion linear | TrustRegion log | LSO LM linear | LSO LM log | LSO dogleg linear | LSO dogleg log | FastLM linear | FastLM log |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sirt_treatment_0_1em4` | 0.01% | 0.01% | 0.01% | 0.01% | 1.22% | 1.22% | 0.01% | 0.01% | 0.01% | 0.01% | 0.01% | 0.01% | 0.01% | 0.01% |
| `crauste_7_1em4` | 19.62% | 167.02% | 6445.99% | 331.47% | 414.05% | 414.05% | 414.05% | 394.46% | 414.05% | 414.05% | 414.05% | 414.05% | 2137.72% | 1209.35% |
| `fitzhugh_nagumo_2_1em4` | 1.31% | 3.2% | 1.31% | 1.31% | 6.11% | 6.11% | 1.31% | 1.31% | 1.31% | 1.31% | 1.31% | 1.31% | 1.31% | 1.31% |
| `seir_4_1em4` | 0.05% | 0.63% | 0.05% | 0.05% | 109.53% | 75.65% | 0.05% | 96.58% | 37.08% | 109.53% | 0.05% | 22.0% | 0.05% | 0.05% |
| `flexible_arm_0_1em4` | 0.54% | 3.6% | 32.64% | 30.93% | 32.61% | 32.61% | 32.61% | 32.61% | 32.61% | 18.75% | 32.61% | 32.61% | 32.61% | 32.61% |
| `daisy_mamil3_7_1em4` | 0.0% | 0.4% | 0.0% | 0.0% | 3.37% | 3.37% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% |
| `daisy_mamil4_6_1em4` | 0.33% | 0.31% | 0.33% | 6.48% | 33.82% | 27.86% | 0.33% | 0.33% | 0.33% | 25.02% | 0.33% | 0.33% | 0.02% | 1.72% |
| `brusselator_5_1em4` | 0.03% | 0.05% | Inf | Inf | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% | 0.24% |
| `forced_lotka_volterra_0_1em4` | 0.0% | 0.0% | 0.0% | 0.0% | 4.1% | 4.1% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% | 0.0% |

## Notes

- This matrix shows both scalar baselines and every residual solver in both coordinate systems.
- It is a readability companion to `summary.md`, not a recomputation.
