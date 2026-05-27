# seir zero-IC jet degeneracy — reproduction

Supporting scripts for
[`docs/2026-05-25_zero_ic_jet_degeneracy.md`](../../docs/2026-05-25_zero_ic_jet_degeneracy.md).

These confirm that the `seir` branch-completion failure is a degenerate
evaluation point (`In(0) = 0`), not an HC or template bug.

| script | shows |
|---|---|
| `trajectory_check.jl` | both "branches" drift 2–4% from the true `In(t)` at the tail — they are not observationally equivalent to truth |
| `three_roots_check.jl` | truth, anchor, and branch-2 are **all** roots of the same t0 system (‖F‖ = 1.8e-9 / 2.3e-13 / 1.3e-9) |
| `cascade_mixed_volume_probe.jl` | full system `mixed_volume = 0`; cascade-eliminating single-var eqs gives `mixed_volume = 6` but still 0 real roots; `cond(J) = 4.4e17`; Newton-from-anchor rejected |

All scripts are self-contained (the instantiated system and candidate values are
embedded; no `/tmp` dependency).

```bash
julia --startup-file=no trajectory_check.jl
julia --startup-file=no three_roots_check.jl
julia --startup-file=no cascade_mixed_volume_probe.jl
```
