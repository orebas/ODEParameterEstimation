# Deep-failure characterization: flexible_arm_5_1em2

System: **flexible_arm**  | Noise: **1em2**

## ODE

State variables: ['theta_m', 'omega_m', 'theta_t', 'omega_t']

Parameters: ['Jm', 'Jt', 'bm', 'bt', 'k']

Observables:
```
  y1 = 0.5*theta_m
  y2 = 0.5*theta_t
```

ODE system:
```
  dtheta_t/dt = omega_t
  domega_m/dt = (0.5 - 0.1*bm*omega_m - 20.0*k*(-0.5*theta_t + 0.5*theta_m)) / (0.1*Jm)
  domega_t/dt = (-0.05*bt*omega_t - 20.0*k*(0.5*theta_t - 0.5*theta_m)) / (0.05*Jt)
  dtheta_m/dt = omega_m
```

Truth:
- params: {'Jm': 0.177, 'Jt': 0.246, 'bm': 0.7, 'bt': 0.407, 'k': 0.419}
- ICs: {'theta_m': 0.799, 'omega_m': 0.815, 'theta_t': 0.444, 'omega_t': 0.658}

## Result.csv summary

- rows: 100
- err range: [0.003369, 481.4]
- oracle range: [1.25, 2.73e+04]
- rank-1 oracle: 4.4
- best-oracle row: rank 81, oracle 1.25
- polish_source_hc_idx == -1: 83 of 100
- SIAN non_identifiable: []
- ODEPE all_unidentifiable: []

## Best (from metadata)

- raw_count: 256
- primary_method: algebraic
- source_type: single_point
- aggregation_strategy: none
- rescue_path: none
- was_terminal_fallback: False
- notes: []
- best params: {'Jm': 0.4908277204952068, 'Jt': 0.9706266767777264, 'bm': 0.8989569249654269, 'bt': 0.011790583845224663, 'k': 0.008966083750625482}
- best states (non-trfn): {'omega_m(t)': 4.631175139391475, 'omega_t(t)': 5.053924370794678, 'theta_m(t)': -0.08217936206813559, 'theta_t(t)': -0.3511319986870547}

## Per-axis status at the best-oracle row (rank 81)

| axis | estimate | truth | rel_err |
|---|---|---|---|
| Jt | 1.9163e-05 | 0.246 | 0.246 |
| omega_t(t) | 1.9041 | 0.658 | 1.25 |
| k | 1.5009e-05 | 0.419 | 0.419 |
| omega_m(t) | 1.8098 | 0.815 | 0.995 |
| Jm | 0.35872 | 0.177 | 0.182 |
| bt | 2.6213e-05 | 0.407 | 0.407 |
| bm | 0.90286 | 0.7 | 0.203 |
| theta_m(t) | 0.60385 | 0.799 | 0.195 |
| theta_t(t) | 0.48432 | 0.444 | 0.0403 |

## Failure mode classification

**Primary: multi-parameter bound saturation + stiff oscillator dynamics under heavy noise.**

System: mechanical flexible-arm with two coupled rotors (theta_m, theta_t), torsional spring (k), inertia (Jm, Jt), damping (bm, bt). 5 parameters, 4 ICs, **2 observables** (theta_m and theta_t). Naturally oscillatory.

The best-oracle row (rank 81) shows:
- **Jt = 1.9e-5 (saturated at lower bound)** — truth 0.246
- **k = 1.5e-5 (saturated at lower bound)** — truth 0.419
- **bt = 2.6e-5 (saturated at lower bound)** — truth 0.407
- Other params (Jm, bm) drift to bound-distant but still wrong values.

Three parameters pegged at the lower bound simultaneously — multi-parameter bound saturation. The polish ridge here is in multiple directions at once.

err range [0.003, 481] — extremely wide, polish struggled across rows. 83/100 rows are `polish_source_hc_idx = -1` (aggregate-flooded).

raw_count=256 is moderate (smaller than typical 500–1500).

**Diagnosis: noise=1e-2 is high enough that the oscillator-period vs damping vs spring-stiffness combinations are degenerate to within noise.** The pipeline finds a low-dimensional manifold where (Jt → 0, k → 0, bt → 0) collapses the elastic coupling to "two free rotors", and on that manifold many parameter values fit the noisy data equally well.

This is **similar to biohydrogenation but with three saturating parameters instead of one**. Would benefit from soft-wall regularization specifically targeting these three parameters' lower bounds.

**Caveat**: at noise=0 (no noise), this system probably solves cleanly. The failure here is noise-driven, not algebraic.
