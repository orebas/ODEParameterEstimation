# Single-start PEtab feasibility pilot

Canonical benchmark revision: `ddaa86d13f708926c57ec8918ce75a6b50e2e562`. Seed: `20260910`. Budget: 900 seconds per method/problem, excluding package load.

Lower NLLH is better **within the same problem**. Values retain the original likelihood and preparation. These attempts do not establish speed, reliability or global optimality. Separate development retries are recorded in `../development_attempts.json`.

| Problem | ODEPE algebraic NLLH | ODEPE refined NLLH | Julia/Fides NLLH | AMICI/Fides NLLH |
|---|---:|---:|---:|---:|
| Perelson_Science1996 | 1.30353447e+12 | 227.567598 | 10842.6294 | 10842.6294 |
| Bertozzi_PNAS2020 | no_valid_candidates | no_valid_candidates | 158.867978 | 158.86427 |
| Okuonghae_ChaosSolitonsFractals2020 | timeout | timeout | 675.447369 | 675.447369 |
| Bruno_JExpBot2016 | timeout | timeout | 874.201246 | 874.201236 |
| Fujita_SciSignal2010 | timeout | timeout | 1.21734279e+11 (optimizer_stopped) | 10010.951 (optimizer_stopped) |
| Zhao_QuantBiol2020 | timeout | timeout | 522.306369 | 547.512377 |
| Sneyd_PNAS2002 | timeout | timeout | -130.4261 | -130.4261 |
| Boehm_JProteomeRes2014 | timeout | timeout | 164.425703 | 164.425697 |
| Crauste_CellSystems2017 | failed | failed | optimization_failed | optimization_failed |
| Raia_CancerResearch2011 | timeout | timeout | 478.631231 | 478.62922 |

## Failures and limits

- **Bertozzi_PNAS2020 / odepe**: no_valid_candidates. No algebraic vector passed the original PEtab bounds and objective checks
- **Okuonghae_ChaosSolitonsFractals2020 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Bruno_JExpBot2016 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Fujita_SciSignal2010 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Fujita_SciSignal2010 / petab_julia**: optimizer_stopped. Finite objective returned without optimizer convergence (DELTA_TOO_SMALL)
- **Fujita_SciSignal2010 / pypesto_amici**: optimizer_stopped. Finite objective returned without optimizer convergence (ExitFlag.DELTA_TOO_SMALL)
- **Zhao_QuantBiol2020 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Sneyd_PNAS2002 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Boehm_JProteomeRes2014 / odepe**: timeout. Time budget exhausted before a scored candidate was returned
- **Crauste_CellSystems2017 / odepe**: failed. ArgumentError: Algebraic interpolation needs an observed interval common to all signals
- **Crauste_CellSystems2017 / petab_julia**: optimization_failed. Original objective was nonfinite at the shared starting vector; no alternative start was sampled
- **Crauste_CellSystems2017 / pypesto_amici**: optimization_failed. Original objective was nonfinite at the shared starting vector; no alternative start was sampled
- **Raia_CancerResearch2011 / odepe**: timeout. Time budget exhausted before a scored candidate was returned

The CSV retains stage counts, termination codes and measured times. Several workers overlapped, and the early attempts predate source/thread instrumentation; those timings are not a performance comparison.
