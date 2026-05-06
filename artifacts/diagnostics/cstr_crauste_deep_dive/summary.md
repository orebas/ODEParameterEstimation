# CSTR and Crauste Benchmark Deep Dive

_Generated: 2026-04-15 14:55:00_

## Benchmark Model Provenance

- Repo default `crauste()` is the old wrong model; benchmark `crauste` matches the corrected 25-day, 12-parameter formulation.
- Repo default `cstr()` is not the bilby benchmark model; the benchmark uses the scaled fixed-activation 3-state formulation with a single observable.
- This deep dive treats the bilby generated scripts and data files as the source of truth.

## Cstr

### Aggregate Benchmark Snapshot

| Noise | Method | Mean RMSE | Median RMSE | Mean Max Rel Err | Success |
| --- | --- | ---: | ---: | ---: | ---: |
| 0e+00 | amigo2_run | 6.3118e-04 | 0.0000e+00 | 0.0034 | 8/8 |
| 0e+00 | odepe_nopolish | 0.2523 | 0.2799 | 0.7552 | 2/8 |
| 0e+00 | odepe_polish | 0.2569 | 0.2901 | 0.7552 | 2/8 |
| 0e+00 | odepe_multipoint | 0.4176 | 0.3297 | 2.0636 | 0/8 |
| 1e-08 | amigo2_run | 0.0032 | 1.2746e-05 | 0.0186 | 7/8 |
| 1e-08 | odepe_nopolish | 0.4006 | 0.2951 | 1.5527 | 0/8 |
| 1e-08 | odepe_polish | 0.5083 | 0.2951 | 1.9672 | 0/8 |
| 1e-08 | odepe_multipoint | 0.3745 | 0.3660 | 1.7217 | 0/6 |
| 1e-06 | amigo2_run | 0.4626 | 0.0016 | 3.9548 | 7/8 |
| 1e-06 | odepe_nopolish | 0.4800 | 0.3440 | 2.0389 | 0/8 |
| 1e-06 | odepe_polish | 0.4926 | 0.3292 | 2.1007 | 0/8 |
| 1e-06 | odepe_multipoint | 0.6418 | 0.3365 | 3.9510 | 0/7 |
| 1e-04 | amigo2_run | 1.7138 | 0.6020 | 16.2663 | 2/8 |
| 1e-04 | odepe_nopolish | 1.5636 | 0.4112 | 7.3123 | 0/8 |
| 1e-04 | odepe_polish | 1.4287 | 0.4372 | 6.8985 | 0/8 |
| 1e-04 | odepe_multipoint | 0.4169 | 0.3211 | 1.6020 | 0/8 |
| 1e-02 | amigo2_run | 2.3713 | 2.3619 | 20.0916 | 0/8 |
| 1e-02 | odepe_nopolish | 0.8349 | 0.7243 | 3.4594 | 0/8 |
| 1e-02 | odepe_polish | 0.8250 | 0.7243 | 3.4252 | 0/8 |
| 1e-02 | odepe_multipoint | 0.9129 | 0.5336 | 2.8961 | 0/3 |

### Case `cstr_1_0`

- Noise: `0e+00`
- Observables: `1`
- States: `3`
- Parameters: `4`

#### Selected Winner Metrics

| Method | RMSE | Max Rel Err | Success |
| --- | ---: | ---: | ---: |
| amigo2_run | 0.0050 | 0.0274 | true |
| odepe_nopolish | 0.0075 | 0.0416 | true |
| odepe_polish | 0.0074 | 0.0413 | true |
| odepe_multipoint | 0.1359 | 2.0464 | false |

#### Exported ODEPE Pool Audit

| Method | Rows | Nonfinite Rows | Box-Violating Rows | First-Row Truth RMSE | Best Truth RMSE | Best Truth Row | Better-Than-First Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| odepe_nopolish | 101 | 0 | 100 | 10.5196 | 0.6548 | 66 | 65 |
| odepe_polish | 113 | 0 | 111 | 6.1550e+07 | 0.6548 | 71 | 109 |
| odepe_multipoint | 73 | 0 | 72 | 0.5414 | 0.5414 | 1 | 0 |

#### Local Diagnostic Pass (`InterpolatorAAADGPR`)

| Metric | Value |
| --- | --- |
| Diagnostic mode | `direct` |
| Difficulty | `hard` |
| Bottleneck | cstr_derivative_only_after_direct_trig_failure |
| Best eval point | 9.9867 |
| Worst derivative error | 1.0004 |
| Production solution count | -1 |
| Jacobian condition number | NaN |
| Effective rank | -1 |
| Root sensitivity | NaN |
| Sensitivity nonlinearity | NaN |
| Sensitivity concentration | NaN |
| Pathological concentration | false |
| UQ status | `skipped` |
| UQ max CV | NaN |

#### Preliminary Diagnosis

- Polish does not materially rescue the exported ODEPE solution on this case.
- The exported `odepe_polish` pool does not hide a much better truth-close basin; this is not primarily a finalist-ranking miss.
- The saved polished pool contains rows outside the nominal `[1e-5, 10]` box, so bound enforcement needs to be audited separately from search quality.

### Case `cstr_1_1em8`

- Noise: `1e-08`
- Observables: `1`
- States: `3`
- Parameters: `4`

#### Selected Winner Metrics

| Method | RMSE | Max Rel Err | Success |
| --- | ---: | ---: | ---: |
| amigo2_run | 0.0253 | 0.1468 | false |
| odepe_nopolish | 0.1834 | 0.9169 | false |
| odepe_polish | 0.1834 | 0.9169 | false |
| odepe_multipoint | 0.4576 | 2.1503 | false |

#### Exported ODEPE Pool Audit

| Method | Rows | Nonfinite Rows | Box-Violating Rows | First-Row Truth RMSE | Best Truth RMSE | Best Truth Row | Better-Than-First Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| odepe_nopolish | 85 | 0 | 83 | 3.0626 | 0.5323 | 71 | 10 |
| odepe_polish | 94 | 0 | 92 | 3.0626 | 0.5323 | 71 | 10 |
| odepe_multipoint | 56 | 0 | 54 | 0.6835 | 0.6835 | 1 | 0 |

#### Local Diagnostic Pass (`InterpolatorAAADGPR`)

| Metric | Value |
| --- | --- |
| Diagnostic mode | `direct` |
| Difficulty | `hard` |
| Bottleneck | cstr_derivative_only_after_direct_trig_failure |
| Best eval point | 9.9867 |
| Worst derivative error | 1.0004 |
| Production solution count | -1 |
| Jacobian condition number | NaN |
| Effective rank | -1 |
| Root sensitivity | NaN |
| Sensitivity nonlinearity | NaN |
| Sensitivity concentration | NaN |
| Pathological concentration | false |
| UQ status | `skipped` |
| UQ max CV | NaN |

#### Preliminary Diagnosis

- Polish does not materially rescue the exported ODEPE solution on this case.
- The exported `odepe_polish` pool does not hide a much better truth-close basin; this is not primarily a finalist-ranking miss.
- The saved polished pool contains rows outside the nominal `[1e-5, 10]` box, so bound enforcement needs to be audited separately from search quality.

## Crauste

### Aggregate Benchmark Snapshot

| Noise | Method | Mean RMSE | Median RMSE | Mean Max Rel Err | Success |
| --- | --- | ---: | ---: | ---: | ---: |
| 0e+00 | amigo2_run | 0.1097 | 0.0000e+00 | 2.6710 | 6/8 |
| 0e+00 | odepe_nopolish | 6.0587e-04 | 4.5230e-05 | 0.0144 | 7/8 |
| 0e+00 | odepe_polish | 5.4530e-04 | 3.6397e-05 | 0.0133 | 7/8 |
| 0e+00 | odepe_multipoint | 9.5155 | 0.1430 | 55.2913 | 1/8 |
| 1e-08 | amigo2_run | 0.0238 | 6.9551e-04 | 0.2527 | 5/8 |
| 1e-08 | odepe_nopolish | 52.4849 | 0.2756 | 1.4758e+03 | 1/8 |
| 1e-08 | odepe_polish | 0.7342 | 0.3454 | 5.4988 | 1/8 |
| 1e-08 | odepe_multipoint | 7.5436 | 0.1386 | 134.7884 | 1/8 |
| 1e-06 | amigo2_run | 0.0961 | 0.0047 | 0.6127 | 5/8 |
| 1e-06 | odepe_nopolish | 110.1943 | 1.3810 | 2.9062e+03 | 0/8 |
| 1e-06 | odepe_polish | 1.5275 | 1.6219 | 14.9168 | 0/8 |
| 1e-06 | odepe_multipoint | 89.3962 | 2.4515 | 651.1831 | 0/8 |
| 1e-04 | amigo2_run | 0.4093 | 0.1679 | 3.2471 | 1/8 |
| 1e-04 | odepe_nopolish | 809.1907 | 18.4620 | 2.1746e+04 | 0/8 |
| 1e-04 | odepe_polish | 1.9446 | 1.8653 | 14.1023 | 0/8 |
| 1e-04 | odepe_multipoint | 3.0163e+03 | 10.1754 | 1.4608e+04 | 0/7 |
| 1e-02 | amigo2_run | 1.3319 | 0.4716 | 22.4200 | 0/8 |
| 1e-02 | odepe_nopolish | 2.7877e+03 | 476.2916 | 1.9136e+04 | 0/8 |
| 1e-02 | odepe_polish | 2.2012 | 2.1463 | 15.7588 | 0/8 |
| 1e-02 | odepe_multipoint | 3.3365e+03 | 459.7140 | 3.1867e+04 | 0/8 |

### Case `crauste_3_1em8`

- Noise: `1e-08`
- Observables: `4`
- States: `5`
- Parameters: `12`

#### Selected Winner Metrics

| Method | RMSE | Max Rel Err | Success |
| --- | ---: | ---: | ---: |
| amigo2_run | 7.2761e-06 | 9.9502e-05 | true |
| odepe_nopolish | 0.2923 | 4.1064 | false |
| odepe_polish | 1.9784 | 14.3870 | false |
| odepe_multipoint | 0.1985 | 3.1854 | false |

#### Exported ODEPE Pool Audit

| Method | Rows | Nonfinite Rows | Box-Violating Rows | First-Row Truth RMSE | Best Truth RMSE | Best Truth Row | Better-Than-First Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| odepe_nopolish | 13 | 0 | 13 | 8.7285e+03 | 2.8582e+03 | 13 | 3 |
| odepe_polish | 171 | 0 | 13 | 8.7285e+03 | 2.9190 | 33 | 161 |
| odepe_multipoint | 33 | 0 | 33 | 179.1237 | 179.1237 | 1 | 0 |

#### Local Diagnostic Pass (`InterpolatorAAADGPR`)

| Metric | Value |
| --- | --- |
| Diagnostic mode | `direct` |
| Difficulty | `hard` |
| Bottleneck | Derivative error 151.6% at y1(t) order 4; Jacobian cond 1.90e+15 |
| Best eval point | 12.4833 |
| Worst derivative error | 1.5158 |
| Production solution count | 2 |
| Jacobian condition number | 1.9006e+15 |
| Effective rank | 35 |
| Root sensitivity | 9.9418e+05 |
| Sensitivity nonlinearity | 0.6048 |
| Sensitivity concentration | 0.9241 |
| Pathological concentration | true |
| UQ status | `missing` |
| UQ max CV | NaN |

#### Preliminary Diagnosis

- The exported selected result is close to the best truth-close basin visible in the saved pool, so additional basin discovery may still be required.
- Polish expands basin quality substantially relative to the raw exported pool.
- The local sensitivity audit is still pathological, but not in the same one-observable way as `cstr`; this looks more like a noisy search/basin problem than a spec problem.

