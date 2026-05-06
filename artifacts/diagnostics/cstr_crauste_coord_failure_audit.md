# Coordinate Failure Audit for `crauste_3_1em8` and `cstr_1_1em8`

Date: 2026-04-17

## Purpose

The bilby benchmark's `Success@X%` logic is effectively a max-relative-error test over all retained states and parameters. One badly estimated weak coordinate can therefore make an otherwise decent run count as a full failure.

This note isolates which coordinates are actually causing failure on two hard cases:

- `crauste_3_1em8`
- `cstr_1_1em8`

It uses the benchmark-selected rows from:

- `parameter_comparison_crauste_*_noise_1e-08.csv`
- `parameter_comparison_cstr_*_noise_1e-08.csv`

and the local diagnostic interpretation already recorded in:

- `artifacts/diagnostics/cstr_crauste_deep_dive/summary.md`

## Benchmark row mapping

The comparison CSV `Run` column is the per-system row ordinal, not the case suffix.

- `crauste_3_1em8` corresponds to `Run = 4`
- `cstr_1_1em8` corresponds to `Run = 2`

## `crauste_3_1em8`

### ODEPE polish: failure coordinates

The benchmark-selected `odepe_polish` row is not uniformly bad. Its failure is concentrated in a subset of coordinates:

- `mu_PE`: `850.47%`
- `mu_LE`: `635.45%`
- `L`: `379.41%`
- `delta_LM`: `236.75%`
- `mu_EE`: `209.01%`
- `M`: `148.28%`
- `P`: `141.05%`
- `rho_P`: `95.37%`

There are also coordinates that are only moderately wrong:

- `mu_LL`: `86.25%`
- `E`: `73.43%`
- `delta_NE`: `70.23%`
- `mu_P`: `66.72%`
- `rho_E`: `55.74%`

And a few that are already quite good:

- `delta_EL`: `3.09%`
- `mu_N`: `0.27%`
- `Npop`: `0.012%`

### ODEPE no-polish: same pattern, much worse

The benchmark-selected `odepe_nopolish` row is catastrophic on the same broad subset, while still being nearly exact on a few coordinates:

- `mu_LE`: `1,176,856.02%`
- `mu_PE`: `51,301.21%`
- `L`: `26,067.78%`
- `M`: `21,672.09%`
- `mu_P`: `911.71%`
- `mu_PL`: `604.29%`
- `delta_LM`: `472.56%`
- `mu_EE`: `417.83%`

But some coordinates are already very close:

- `E`: `1.10%`
- `delta_NE`: `0.55%`
- `mu_N`: `0.0048%`
- `P`: `0.0011%`
- `Npop`: `0.000040%`

### AMIGO2: essentially exact

On the same benchmark row, `amigo2_run` is nearly perfect. The largest relative error is:

- `mu_LE`: `3.20%`

Everything else is at or near machine precision on the reported row.

### Interpretation

This is not a case where ODEPE misses every coordinate equally. The failure is concentrated in a handful of weak or unstable directions.

That lines up with the local diagnostic picture from the deeper audit:

- Jacobian condition number around `1.90e15`
- sensitivity concentration around `0.924`
- derivative accuracy bottleneck on noisy higher-order information

In the earlier coordinate-level diagnostic probe, the worst `crauste` coordinates (`mu_PE`, `mu_LE`, `delta_NE`, `mu_EE`, `mu_PL`, `mu_P`, `rho_P`) were also the ones with very small Jacobian-column norms and/or unstable sensitivity proxies.

So for `crauste`, the benchmark's max-relative-error style success criterion is amplifying weakness in a subset of directions, not exposing a uniformly useless estimate.

That does **not** make the benchmark unfair. It does mean we should distinguish:

- "strict benchmark success"
- "how many directions are genuinely wrong"

## `cstr_1_1em8`

### ODEPE polish and no-polish are identical

For this case, `odepe_polish` and `odepe_nopolish` pick the same benchmark-selected row.

The relative errors are:

- `r_eff`: `98.58%`
- `dH_rhoCP`: `96.81%`
- `C`: `26.43%`
- `Tin`: `6.43%`
- `UA_VrhoCP`: `2.09%`
- `Temp`: `1.71%`
- `tau`: `0.91%`

### AMIGO2 is exact

The benchmark-selected AMIGO2 row is essentially exact:

- largest reported relative error is `C = 0.00119%`
- everything else is zero at the printed precision

### Interpretation

This case is different from `crauste`.

The failure is not spread across many weak directions. It is dominated by two coordinates:

- `r_eff`
- `dH_rhoCP`

and, secondarily, by `C`.

That is exactly what the model structure suggests should be hard:

- only one observable: `y1 = 700 * Temp`
- `C`, `r_eff`, and `dH_rhoCP` interact through latent dynamics
- the observed channel does not directly pin them down separately

So for `cstr`, the benchmark failure is still max-relative-error sensitive, but the deeper issue looks structural:

- latent-state / identifiability difficulty
- not mainly a finalist-set or polishing-breadth problem

## Current best understanding

### `crauste`

- The benchmark failure is concentrated in a subset of weak directions.
- This is the kind of case where better basin discovery, finalist retention, and practical-identifiability-aware analysis can still matter.
- It is also the kind of case where `Success@X%` can make a partly-good solution look fully bad.

### `cstr`

- The benchmark failure is dominated by two latent/weak coordinates, not by broad solution collapse.
- This still supports the earlier conclusion that `cstr` should stay on the bounds/observability/identifiability track, not the frontier/finalist track.

## Practical consequence

For analysis, the strict bilby metrics should be kept, but they should be supplemented by coordinate-level views:

- which coordinates fail
- how concentrated the failure is
- whether the failing coordinates are weak or practically unidentifiable directions

Without that, `Success@X%` can overstate how bad a run is, especially on `crauste`.
