# Deep-failure characterization: biohydrogenation_5_1em4

System: **biohydrogenation**  | Noise: **1em4**

## ODE

State variables: ['x4', 'x5', 'x6', 'x7']

Parameters: ['k5', 'k6', 'k7', 'k8', 'k9', 'k10']

Observables:
```
  y1 = 8.0*x4
  y2 = 0.5*x5
```

ODE system:
```
  dx5/dt = ((-0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5) + (8.0*k5*x4) / (4.0*k6 + 8.0*x4)) / 0.5
  dx7/dt = (0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (5.0*k10)
  dx4/dt = (-8.0*k5*x4) / (8.0*(4.0*k6 + 8.0*x4))
  dx6/dt = ((-0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (10.0*k10) + (0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5)) / 0.5
```

Truth:
- params: {'k5': 0.67, 'k6': 0.122, 'k7': 0.782, 'k8': 0.882, 'k9': 0.446, 'k10': 0.85}
- ICs: {'x4': 0.709, 'x5': 0.688, 'x6': 0.77, 'x7': 0.181}

## Result.csv summary

- rows: 100
- err range: [1.784e-05, 9.937e-05]
- oracle range: [0.718, 82]
- rank-1 oracle: 1.99
- best-oracle row: rank 4, oracle 0.718
- polish_source_hc_idx == -1: 19 of 100
- SIAN non_identifiable: []
- ODEPE all_unidentifiable: ['x7(t)']

## Best (from metadata)

- raw_count: 1306
- primary_method: algebraic
- source_type: single_point
- aggregation_strategy: none
- rescue_path: algebraic_resolve_t0
- was_terminal_fallback: False
- notes: ['representative_completion']
- best params: {'k10': -0.1787208536567391, 'k5': 0.6694395537992492, 'k6': 0.12149665751867346, 'k7': 0.5263897738012316, 'k8': 0.8672423325104611, 'k9': -1.541502083661858}
- best states (non-trfn): {'x4(t)': 0.7089844028468971, 'x5(t)': 0.6882993100782424, 'x6(t)': -0.8512145742383863, 'x7(t)': 0.0}

## Per-axis status at the best-oracle row (rank 4)

| axis | estimate | truth | rel_err |
|---|---|---|---|
| k10 | 0.13171 | 0.85 | 0.718 |
| k9 | 1.1107 | 0.446 | 0.665 |
| x6(t) | 0.091493 | 0.77 | 0.679 |
| k8 | 0.9952 | 0.882 | 0.113 |
| x5(t) | 0.6944 | 0.688 | 0.0064 |
| k7 | 0.7701 | 0.782 | 0.0119 |
| k6 | 0.12146 | 0.122 | 0.000536 |
| k5 | 0.66965 | 0.67 | 0.000347 |
| x4(t) | 0.70898 | 0.709 | 1.91e-05 |

## Failure mode classification

**Primary: numerical ridge in (k10, k9, x6) — same as biohydrogenation_6_1em6 but higher noise.**

This is the same pathology we deep-dived for `biohydrogenation_6_1em6`. The factor `(10·k10 - 0.5·x6) / (10·k10) → 1` for k10 ≫ 0.02 makes k10 nearly invisible. x7 doesn't enter observables (correctly flagged in `all_unidentifiable: ['x7(t)']`).

At noise=1e-4 (vs 1e-6 for the other case), the practical-identifiability degrades further:
- best-oracle row has k10=0.13 (truth 0.85), k9=1.11 (truth 0.446), x6=0.09 (truth 0.77) — three parameters wandering together.
- k5, k6, k7, x4 are recovered to ~0.01% — the "easy" parameters.
- x5 to 0.6% — also good.
- min_oracle = 0.72 means even the *best* row is 72% off on at least one identifiable parameter.

raw_count=1306 (large HC pool). 19 of 100 rows are `polish_source_hc_idx == -1` — much fewer aggregates than typical, so this isn't an aggregate-noise problem.

err range [1.8e-5, 1.0e-4] is at the noise floor (σ²·N ≈ 7.5e-6 for σ=1e-4 over 750 points × 2 obs). So polish IS converging to the noise floor — it just can't pick out the right (k10, k9, x6).

**This is a clean "numerical ridge" example.** Higher noise than biohydrogenation_6_1em6 makes the ridge wider in (k10, k9, x6) space. Would benefit from soft-wall regularization or per-parameter bound-saturation demotion.
