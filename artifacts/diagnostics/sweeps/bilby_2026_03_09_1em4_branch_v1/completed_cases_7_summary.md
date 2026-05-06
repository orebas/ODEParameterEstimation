# Branch v1 Completed Cases Summary

Generated from completed individual case studies after the broader batch was split into per-case runs.

## Cases

| Case | Baseline | Consensus v0 | Synth v0 | Branch v1 | Best Strategy |
|------|----------|--------------|----------|-----------|---------------|
| `dc_motor_1_1em4` | 10.23% | 10.23% | 10.23% | 10.23% | `best_fit_baseline` |
| `daisy_mamil3_7_1em4` | 5.46% | 5.46% | 5.46% | 0.01% | `branch_consensus_v1` |
| `fitzhugh_nagumo_2_1em4` | 322.22% | 322.22% | 322.22% | 1.48% | `branch_consensus_v1` |
| `fitzhugh_nagumo_3_1em4` | 10.59% | 7.09% | 7.09% | 7.09% | `family_consensus` |
| `aircraft_pitch_4_1em4` | 123.56% | 256.97% | 256.97% | 123.54% | `branch_consensus_v1` |
| `brusselator_1_1em4` | 3.41% | 3.41% | 3.41% | 3.41% | `best_fit_baseline` |
| `daisy_mamil3_4_1em4` | 1.47% | 1.47% | 1.47% | 0.01% | `branch_consensus_v1` |

## Aggregate

- Completed cases: `7`
- Branch v1 beat baseline: `5 / 7`
- Branch v1 beat consensus v0: `4 / 7`
- Branch v1 tied consensus v0: `1 / 7`
- Branch v1 was overall best: `4 / 7`

## Notes

- `branch_consensus_v1` was strongest on the hard Daisy and FitzHugh near-miss cases.
- `branch_consensus_v1` matched or preserved the best answer on the small-pool control cases.
- `fitzhugh_nagumo_3_1em4` remained a clean `consensus_v0` selector win; branch v1 matched it but did not improve beyond it.
- `seir_2_1em4` and `sirt_treatment_7_1em4` were not completed in this pass because the individual runs were materially slower than the rest of the subset.
