# Probe 2 — Soft-wall source change summary

Diff stat:
```
src/core/parameter_estimation.jl |  7 ++++++
src/core/polish_residual.jl      | 52 ++++++++++++++++++++++++++++++++++-
src/types/estimation_options.jl  | 21 ++++++++++++++++
3 files changed, 79 insertions(+), 1 deletion(-)
```

## What got added

### 1. `src/types/estimation_options.jl`

- Two new opt-in fields on `EstimationOptions`:
  - `polish_softwall_lambda::Float64 = 0.0` — penalty strength
  - `polish_softwall_epsilon::Float64 = 0.05` — band width as fraction of half-range
- Docstring entries explaining each.
- Validation in `validate_options`: λ_sw must be ≥ 0; ε_sw must be in [0, 0.5).

### 2. `src/core/parameter_estimation.jl`

- Two new fields on `PolishContext` struct: `softwall_lambda::Float64 = 0.0`
  and `softwall_epsilon::Float64 = 0.05`.
- Populated from `opts.polish_softwall_lambda` and `opts.polish_softwall_epsilon`
  at the constructor (around line 2199).

### 3. `src/core/polish_residual.jl`

Three small additions inside `_polish_single_residual`:

a. Setup (after the existing regularization block):
```julia
λ_sw = max(ctx.softwall_lambda, 0.0)
ε_sw = ctx.softwall_epsilon
use_softwall = λ_sw > 0.0 && !isnothing(internal_lb) && !isnothing(internal_ub) && 0.0 <= ε_sw < 0.5
softwall_scale = use_softwall ? sqrt(λ_sw) : 0.0
# Pre-compute per-parameter midpoint, halfrange, threshold in internal coords
if use_softwall
    sw_midpoint = ...; sw_halfrange = ...; sw_threshold = ...
end

residual_count = n_obs_residual + (use_regularization ? n_unknowns : 0) + (use_softwall ? n_unknowns : 0)
```

b. Append rows to residual closure (after existing regularization block):
```julia
if use_softwall
    @inbounds for i in eachindex(p_internal)
        deviation = abs(p_internal[i] - sw_midpoint[i])
        thresh = sw_threshold[i]
        half = sw_halfrange[i]
        if deviation > thresh && half > 0
            over = (deviation - thresh) / half
            res[idx] = softwall_scale * over
        else
            res[idx] = zero(eltype(res))
        end
        idx += 1
    end
end
```

## Math

Per parameter `i`, in transformed internal coordinates (log-space or
shifted-log-space, with bounds `internal_lb[i]` and `internal_ub[i]`):

- `midpoint_i = (internal_lb + internal_ub) / 2`
- `halfrange_i = (internal_ub - internal_lb) / 2`
- `threshold_i = (1 - ε_sw) * halfrange_i`
- `deviation_i = |p_internal[i] - midpoint_i|`
- `over_i = max(0, deviation_i - threshold_i) / halfrange_i`
- Residual row contribution: `√λ_sw · over_i`
- Penalty in SSR (loss): `λ_sw · over_i²`

Zero inside the central `(1 - 2·ε_sw)·halfrange` band. Quadratic ramp-up
past the threshold. Grows to a maximum of `λ_sw · ε_sw²` when a parameter
sits exactly at either bound.

## Default behavior unchanged

With default `polish_softwall_lambda = 0.0`, `use_softwall = false` and
zero rows are added to the residual. The residual closure short-circuits
the soft-wall block via `if use_softwall`. No CPU cost.

## Verification

- `test/fast_core.jl` passes 258/258 with the source change applied [V].
- `test/feature_regressions.jl` not run yet at writeup time [pending].

## Activation

```julia
opts = EstimationOptions(
    # ... existing options ...
    polish_softwall_lambda = 1e-2,    # turn on with moderate strength
    polish_softwall_epsilon = 0.05,   # default band width
)
```
