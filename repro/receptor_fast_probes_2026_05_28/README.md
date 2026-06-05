# Receptor Fast Probes — 2026-05-28

Script-only probes for `receptor_subtype_binding_branch`. These do not change
production code. They are intended to test mechanism before running expensive
wallaby-style validation.

Run from the repository root with plain Julia:

```bash
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/point_selection_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/representation_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/trim_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/variable_cost_trim_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/baseline_homotopy_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/path_subdivision_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/complex_detour_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/gamma_straight_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/trim_complex_detour_probe.jl
julia --startup-file=no repro/receptor_fast_probes_2026_05_28/fallback_probe.jl
```

Outputs default to `repro/receptor_fast_probes_2026_05_28/out/*.jsonl`.
Override with `ODEPE_RECEPTOR_FAST_OUT=/path/to/out`.

## Probe Order

1. `point_selection_probe.jl`: cheap oracle derivative magnitude map. Optional
   fresh solves with `ODEPE_RECEPTOR_POINT_SOLVE=1`.
2. `representation_probe.jl`: compares original, `S=Ca+Cb`/`Ca`, and
   `S=Ca+Cb`/`Delta=Ca-Cb` coordinate systems. Optional fresh solve with
   `ODEPE_RECEPTOR_REP_SOLVE=1`.
3. `trim_probe.jl`: script-local greedy trim variants. Default records ranks
   and selected equation sets only. Set `ODEPE_RECEPTOR_TRIM_SOLVE=1` to solve.
4. `variable_cost_trim_probe.jl`: derivative-cap and marginal-new-variable trim
   frontiers for noisy-data trim design.
5. `baseline_homotopy_probe.jl`: straight parameter homotopy, forward and reverse.
6. `path_subdivision_probe.jl`: straight real path split into multiple segments.
7. `complex_detour_probe.jl`: fixed-endpoint complex detours. Set
   `ODEPE_RECEPTOR_FAST_GENERIC_COMPLEX_SEED=1` for generic-complex seed probes.
8. `gamma_straight_probe.jl`: true HC.jl gamma trick between fixed start and
   target systems, not a parameter-path homotopy.
9. `trim_complex_detour_probe.jl`: runs complex detours on selected alternate
   trim systems.
10. `fallback_probe.jl`: tests whether losing only spurious paths can avoid a
   fresh fallback.

## Useful Environment Knobs

- `ODEPE_RECEPTOR_FAST_DATASIZE=201`
- `ODEPE_RECEPTOR_FAST_POINTS=3`
- `ODEPE_RECEPTOR_FAST_MIXED_VOLUME=1`
- `ODEPE_RECEPTOR_FAST_BRANCH_TOL=1e-2`
- `ODEPE_RECEPTOR_FAST_RESIDUAL_TOL=1e-6`
- `ODEPE_RECEPTOR_FAST_ETAS=1e-3,1e-2,1e-1,0.3`
- `ODEPE_RECEPTOR_FAST_SEEDS=1,2,3,4,5,6,7,8,9,10`
- `ODEPE_RECEPTOR_FAST_WAYPOINTS=1,3`
- `ODEPE_RECEPTOR_FAST_REAL_SEGMENTS=1,2,4,8`
- `ODEPE_RECEPTOR_TRIM_RANDOM_SEEDS=1,2,...`
- `ODEPE_RECEPTOR_TRIM_PIN_CAPS=0,1,2,3,4`
- `ODEPE_RECEPTOR_TRIM_CASES=pins_low_order_first,pins_cap_4`
- `ODEPE_RECEPTOR_TRIM_DETOUR_CASES=pins_low_order_first,pins_cap_4`
- `ODEPE_RECEPTOR_GAMMA_CASES=support_first,current`
- `ODEPE_RECEPTOR_VARTRIM_MAX_CAP=10`
- `ODEPE_RECEPTOR_VARTRIM_TIES=support,data_order`
- `ODEPE_RECEPTOR_COST_Y1=1.0`
- `ODEPE_RECEPTOR_COST_Y2=1.0`

## Interpretation Gates

- Complex detours are promising if truth/swap track without fresh fallback in
  most seeds.
- Trim variants are promising only if they improve solve behavior without
  relying on top-order data pins such as `y2_8`. Current trim comparisons should
  preserve the established full-rank target: rank `32` for the same `32` solve
  variables.
- Representation changes are promising only if they reduce unknown count,
  mixed volume, or required derivative order in a way that could be automated.
- Selective fallback is promising if physical/full-residual-valid branches
  survive while lost branches are spurious.
- Deferred lower-derivative experiment: inspect nullspaces of rank-deficient
  trims and test whether the free directions affect parameters or only nuisance
  jets.
