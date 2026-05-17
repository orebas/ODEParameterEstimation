# Deep-failure characterization: cstr_0_1em2

System: **cstr**  | Noise: **1em2**

## ODE

State variables: ['C', 'Temp', 'r_eff']

Parameters: ['tau', 'Tin', 'dH_rhoCP', 'UA_VrhoCP']

Observables:
```
  y1 = 700.0*Temp
```

ODE system:
```
  dC/dt = (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C
  dTemp/dt = (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)
  dr_eff/dt = 12.5*r_eff/(Temp^2)*((Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t))
```

Truth:
- params: {'tau': 0.278, 'Tin': 0.337, 'dH_rhoCP': 0.562, 'UA_VrhoCP': 0.191}
- ICs: {'C': 0.271, 'Temp': 0.812, 'r_eff': 0.171}

## Result.csv summary

- rows: 100
- err range: [0.08595, 0.4724]
- oracle range: [1.41, 9.23e+10]
- rank-1 oracle: 1.41
- best-oracle row: rank 1, oracle 1.41
- polish_source_hc_idx == -1: 100 of 100
- SIAN non_identifiable: []
- ODEPE all_unidentifiable: []

## Best (from metadata)

- raw_count: 729
- primary_method: algebraic
- source_type: single_point
- aggregation_strategy: none
- rescue_path: algebraic_resolve_t0
- was_terminal_fallback: False
- notes: []
- best params: {'Tin': 0.37645424970604163, 'UA_VrhoCP': -0.24656448437686604, 'dH_rhoCP': -0.46987859652882774, 'tau': 0.19330946338179672}
- best states (non-trfn): {'C(t)': -0.8685252987573387, 'Temp(t)': 0.8057070244941428, 'r_eff(t)': 1.5788099304700711}

## Per-axis status at the best-oracle row (rank 1)

| axis | estimate | truth | rel_err |
|---|---|---|---|
| r_eff(t) | 1.5788 | 0.171 | 1.41 |
| Temp(t) | 0.80571 | 0.812 | 0.00629 |
| dH_rhoCP | -0.46988 | 0.562 | 1.03 |
| tau | 0.19331 | 0.278 | 0.0847 |
| C(t) | -0.86853 | 0.271 | 1.14 |
| Tin | 0.37645 | 0.337 | 0.0395 |
| UA_VrhoCP | -0.24656 | 0.191 | 0.438 |

## Failure mode classification

**Primary: under-observed system + high noise + transcendental input.**

System characteristics:
- 7 unknowns (3 ICs + 4 params)
- **ONLY ONE observable**: `y1 = 700·Temp`
- Sinusoidal forcing: `0.057·UA_VrhoCP·sin(0.5·t)` in dTemp/dt
- Stiff coupling: dr_eff/dt has `1/Temp²` factor

SIAN says identifiable, but with one observable for 7 unknowns and noise=1e-2, the practical identifiability is borderline at best. The transcendental forcing helps (provides time-varying excitation), but the noise level swamps it.

Empirically:
- err range [0.086, 0.47] — polish struggling (above noise floor σ²·N ≈ 0.075).
- min_oracle = 1.41 (terrible).
- Best-oracle row: r_eff = 1.58 (truth 0.171, 9× off), C = -0.87 (truth 0.271, negative!), UA_VrhoCP = -0.25 (truth 0.191, negative!).
- Negative state values suggest **polish slid past the lower bound** during convergence — bound constraints may not be strict enough on this cell, or rescue_path produced negative outputs.

rescue_path: `algebraic_resolve_t0` was invoked (notes empty but rescue path noted). raw_count=729 is moderate.

**Most likely: cstr at noise=1e-2 is genuinely beyond what the pipeline can recover.** The single-observable / multi-unknown structure means noise variance directly contaminates 7-dimensional inversion. This is the "noise dominates observability" regime — not fixable by polish algorithm changes; would need either lower noise or additional observables.

Worth running cstr at noise=1e-4 to see if it succeeds — if yes, this is purely noise-driven; if no, there's a deeper algebraic issue.
