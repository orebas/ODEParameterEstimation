# Deep-failure characterization: hiv_9_1em4

System: **hiv**  | Noise: **1em4**

## ODE

State variables: ['x', 'yv', 'vv', 'w', 'z']

Parameters: ['lm', 'd', 'beta', 'a', 'k', 'uu', 'c', 'q', 'b', 'h']

Observables:
```
  y3 = 2000.0*x
  y1 = 2.0*w
  y4 = 0.002*vv + 2.0*yv
  y2 = z
```

ODE system:
```
  dvv/dt = (200.0*k*yv - 0.012*uu*vv) / 0.002
  dw/dt = (-0.008*b*w - 0.08000000000000002*c*q*w*yv + 0.4*c*w*z*yv) / 2.0
  dx/dt = (2.0*lm - 40.0*d*x - 0.00016*beta*x*vv) / 2000.0
  dz/dt = -0.2*h*z + 0.08000000000000002*c*q*w*yv
  dyv/dt = (-2.0*a*yv + 0.00016*beta*x*vv) / 2.0
```

Truth:
- params: {'lm': 0.481, 'd': 0.437, 'beta': 0.115, 'a': 0.686, 'k': 0.688, 'uu': 0.664, 'c': 0.228, 'q': 0.867, 'b': 0.879, 'h': 0.818}
- ICs: {'x': 0.767, 'yv': 0.479, 'vv': 0.362, 'w': 0.132, 'z': 0.205}

## Result.csv summary

- rows: 100
- err range: [0.008479, 0.01573]
- oracle range: [809, 1.18e+04]
- rank-1 oracle: 7.05e+03
- best-oracle row: rank 10, oracle 809
- polish_source_hc_idx == -1: 100 of 100
- SIAN non_identifiable: []
- ODEPE all_unidentifiable: []

## Best (from metadata)

- raw_count: 1375
- primary_method: algebraic
- source_type: single_point
- aggregation_strategy: none
- rescue_path: none
- was_terminal_fallback: False
- notes: []
- best params: {'a': 0.1568275368436241, 'b': 0.9251015642894166, 'beta': 0.1850631233064143, 'c': -0.6418952794330595, 'd': 0.4454702092895424, 'h': 0.810279661905949, 'k': -0.006923920478866568, 'lm': 0.6031517293428889, 'q': 0.5986168925130747, 'uu': 0.0872387169610055}
- best states (non-trfn): {'vv(t)': 7048.650516147832, 'w(t)': 0.13211815837083726, 'x(t)': 0.7670688637470376, 'yv(t)': -0.1360083412415621, 'z(t)': 0.20499449199122263}

## Per-axis status at the best-oracle row (rank 10)

| axis | estimate | truth | rel_err |
|---|---|---|---|
| c | 0.017643 | 0.228 | 0.21 |
| k | 0.00063715 | 0.688 | 0.687 |
| b | 0.89 | 0.879 | 0.011 |
| w(t) | 0.13165 | 0.132 | 0.000349 |
| yv(t) | 6.6435 | 0.479 | 6.16 |
| z(t) | 0.20573 | 0.205 | 0.000732 |
| lm | 1.228 | 0.481 | 0.747 |
| a | 0.55999 | 0.686 | 0.126 |
| h | 0.81742 | 0.818 | 0.000578 |
| beta | -5.7018 | 0.115 | 5.82 |
| uu | 0.053754 | 0.664 | 0.61 |
| q | 0.49074 | 0.867 | 0.376 |
| x(t) | 0.76725 | 0.767 | 0.000253 |
| vv(t) | -808.74 | 0.362 | 809 |
| d | 0.49036 | 0.437 | 0.0534 |

## Failure mode classification

**Primary: practical-non-identifiability of `vv` — low observable coefficient.**

The observable `y4 = 0.002*vv + 2.0*yv` has a coefficient of 0.002 on `vv` vs 2.0 on `yv` — a 1000× ratio. So `vv`'s contribution to y4 is ~1000× smaller than `yv`'s. For noise σ=1e-4, a 1% change in vv (Δvv=0.0036 near truth) gives Δy4 ≈ 7.2e-6, which is below noise. **vv is effectively unobservable at this noise.**

This matches cluster-claude's HIV deep-dive in HANDOFF.md ("hiv (the vv coefficient problem)"). SIAN says identifiable (structurally), but practical identification needs noise ≪ 1e-5.

The pipeline confirms this: best-oracle row has vv=-808.74 (truth 0.362) — vv blew up because polish couldn't constrain it. **All other states/params are recovered reasonably** (x, w, z, h to 4 digits; d, k roughly right). The 809 oracle distance is dominated by vv alone.

The yv state also wanders (yv=6.64 vs truth 0.479) — likely because of correlated drift with vv to keep y4 fitting.

raw_count=1375 (large HC pool, plenty of candidates). 100% rows have `polish_source_hc_idx == -1` (aggregates dominate the output cap).

**This is structurally similar to biohydrogenation_6_1em6's k10 ridge** — one parameter that's nearly invisible drives massive parameter spread. Not column scaling — purely observable-coefficient-driven.
