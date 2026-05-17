# Deep-failure characterization: brusselator_5_0

System: **brusselator**  | Noise: **0**

## ODE

State variables: ['X', 'Yc']

Parameters: ['a', 'b']

Observables:
```
  y1 = 2.0*X
  y2 = 2.0*Yc
```

ODE system:
```
  dYc/dt = 6.0*b*X - 16.0*a*Yc*(X^2)
  dX/dt = 0.5 - 0.5*X - 3.0*b*X + 16.0*a*Yc*(X^2)
```

Truth:
- params: {'a': 0.667, 'b': 0.79}
- ICs: {'X': 0.469, 'Yc': 0.568}

## Result.csv summary

- rows: 79
- err range: [4.571e+13, 8.02e+68]
- oracle range: [9.33, 8.73e+07]
- rank-1 oracle: 8.73e+07
- best-oracle row: rank 32, oracle 9.33
- polish_source_hc_idx == -1: 64 of 79
- SIAN non_identifiable: []
- ODEPE all_unidentifiable: []

## Best (from metadata)

- raw_count: 102
- primary_method: algebraic
- source_type: single_point
- aggregation_strategy: none
- rescue_path: algebraic_resolve_t0
- was_terminal_fallback: False
- notes: ['hc_no_solutions', 'cascading_attempted', 'cascading_substitution']
- best params: {'a': 0.001744464329756682, 'b': 0.35604373973612974}
- best states (non-trfn): {'X(t)': 87338481.5, 'Yc(t)': 0.5680000021136726}

## Per-axis status at the best-oracle row (rank 32)

| axis | estimate | truth | rel_err |
|---|---|---|---|
| X(t) | 1e-05 | 0.469 | 0.469 |
| b | 10 | 0.79 | 9.21 |
| a | 10 | 0.667 | 9.33 |
| Yc(t) | 1e-05 | 0.568 | 0.568 |

## Failure mode classification

**Primary: HC failure — polynomial system has no real solutions.**

The smoking gun is in `best.notes`: `['hc_no_solutions', 'cascading_attempted', 'cascading_substitution']`. HC.jl returned zero real solutions on the truncated polynomial system. The pipeline fell back to `rescue_path: algebraic_resolve_t0` (cascading substitution) to populate candidates — but those rescue candidates have err = 4.6e13 to 8e68 (astronomical), meaning the rescue can't compensate for the algebraic failure.

raw_count=102 is also tiny — about 10× smaller than typical cells (which see 500–2000). The HC.jl machinery isn't generating its usual pool.

This is the **column-scaling / stiff polynomial pathology** that cluster-claude's `INVESTIGATION_column_scaling.md` documents. Brusselator at zero noise has nonlinear `X²·Yc·a` term that produces an ill-conditioned polynomial system after squaring up. **Truth is structurally identifiable but numerically unreachable.**

Best-oracle row has bound-saturation everywhere (X=1e-5 lower bound, a=10 upper bound, b=10 upper bound). The "best" the pipeline can produce is a pile of bound-saturated junk.
