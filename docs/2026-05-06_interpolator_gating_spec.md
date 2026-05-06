# Interpolator Gating Spec — Auto-Filter by Noise / SP Position / Order

Status: **specification only — not yet implemented**.
Authored: 2026-05-06.

## Problem

`EstimationOptions.interpolators` defaults to a 9-element list (AGPRobust variants, S3 family, AAAD, AAADGPR, S2AAAMLE, ChebyshevBIC, ...). Production runs ALL of them and aggregates candidates. Some interpolators are catastrophic at certain noise levels or at boundary shooting points but are still in the default list, polluting the candidate pool.

Concrete observed pathologies (from the 2026-05-05 forced_lv_0_1em2 sweep, file `artifacts/diagnostics/seed_strategy_recon_2026_05_04/G3_forced_lv_sp_mp_sweep.md`):

- **S2AAAMLE** at noise=1e-2: AAA on raw noisy data terminates at m=5 because Inf-norm residual saturates at noise floor. Resulting derivative-input rel-err 0.6–9.6 across 5 shooting points. Verified at `temp_plans/s2_aaa_tol_sweep.jl` (m=5 across all tolerances 1e-1..1e-10) and `temp_plans/s2_froissart_check.jl` (deflation makes it WORSE, not better).
- **ChebyshevBIC** at boundary shooting points (t<0.1·T or t>0.9·T): order-4 derivative rel-err 504% (left boundary) and 2080% (right boundary). Fine in interior.
- **FHD** at right boundary: 82.89% rel-err on order-2 (per project memory entry on FHD5).
- **AGPRobustMatern52** for derivatives ≥ order 3: kernel only C², derivatives mathematically undefined.

We want to auto-filter these out even when the user passes a "big list" so they don't pollute the pool.

## Noise estimation: pick ONE

Three candidates exist in the codebase:
- **(A)** GP `σₙ²_opt` from `agp_gpr_robust` (`src/core/derivatives.jl:1239-1257`). Optimized via Optim.LBFGS during any AGPRobust/S3 fit. Most physically meaningful.
- **(B)** `_estimate_noise_fraction` (`src/core/derivatives.jl:1839`). DFT high-frequency energy fraction. Cheap, no optimization.
- **(C)** `EstimationOptions.noise_level` (user-supplied; defaults to `0.0`).

**Recommended: (A).** Add a thin wrapper:

```julia
"""
    estimate_relative_noise(t, y) -> Float64

Run an SE-kernel GP fit on (t, y), return σₙ_opt / std(y_normalized).
This is the data-driven relative-noise estimate used by interpolator gating.
"""
function estimate_relative_noise(t::AbstractVector, y::AbstractVector)
    # Use the existing _optimize_se_hyperparams machinery (derivatives.jl:655)
    σₙ²_opt, _, _ = _optimize_se_hyperparams(t, y)
    return sqrt(σₙ²_opt)  # in normalized units (y is normalized inside the GP routine)
end
```

Cache the result if AGPRobust is in the user's list (run already happens — re-extract the optimized hyperparam).

## Per-interpolator gating rules

Cleanly tabulated below. The `applicable_when` predicate is checked at the corresponding gating point. If false → drop with `@warn` (once per method per estimation run).

| Method | applicable_when | Reason |
|---|---|---|
| `InterpolatorAAAD` / `AAADOld` | `σ̂ <= 1e-5` AND `n_data >= 10` | Pure AAA on raw data: same noise-floor m=5 pathology as S2 |
| `InterpolatorAAADGPR` | always | GP-pivoted; safe |
| `InterpolatorFHD` | `n_data >= 12` AND SP fraction `∈ [0.15, 0.85]` | Needs ≥N+1=6 support; right-boundary 82.89% rel-err |
| `InterpolatorAGPRobust*` (5 kernels) | `n_data >= 8` | GP-smoothed; safe |
| `InterpolatorAGPRobustMatern52` / `InterpolatorS3*Matern52` | `max_deriv_order_required <= 2` | Kernel only C² |
| `InterpolatorS2AAAMLE` | `σ̂ <= 1e-4` | AAA's Inf-norm tol saturates at noise floor → m=5 → derivatives diverge |
| `InterpolatorS3Adapt*` / `S3BIC*` | same as parent AGPRobust* | GP-denoised |
| `InterpolatorChebyshevAICc` / `InterpolatorChebyshevBIC` | SP fraction `∈ [0.10, 0.90]` | Order-4 boundary rel-err 504%/2080% |
| `InterpolatorFourierAdaptive` | `n_data >= 16` AND uniform sampling | FFT assumes uniform grid |
| `InterpolatorAGPUQ` | always (note: slow) | Safe but expensive |

### Notes
- `n_data`: length of `data_sample["t"]`.
- `σ̂`: result of `estimate_relative_noise(t_vec, y_first_observable_normalized)`.
- SP fraction: `(t_eval - t0) / (t_end - t0)` where `t0 = first(t_vec)`, `t_end = last(t_vec)`.
- `max_deriv_order_required`: derived from `setup_data.good_deriv_level` (max value).
- Tspan length itself is NOT a factor — model is invariant under time rescaling.

## Implementation: two gating points

### Gate (a): global filter — at the resolver

File: `src/types/estimation_options.jl:631` (function `resolve_interpolator_list`).

Add an optional positional argument `noise_estimate::Union{Nothing, Float64} = nothing` and `n_data::Union{Nothing, Int} = nothing` and `max_order::Union{Nothing, Int} = nothing`. Before returning `result`, drop methods whose `applicable_when` (the dataset-global predicates: noise, n_data, max_order) is false. Behavior on violation: drop silently except `@warn` once per method per estimation run.

```julia
function filter_interpolators_by_data(list, σ̂, n_data, max_order)
    out = empty(list)
    for (method, custom) in list
        if !global_applicable(method, σ̂, n_data, max_order)
            @warn "[INTERP-GATE] Skipping $method: σ̂=$σ̂, n_data=$n_data, max_order=$max_order"
            continue
        end
        push!(out, (method, custom))
    end
    return out
end
```

Where `global_applicable(method, σ̂, n, k)` encodes the table above (only the noise/n/order rules — NOT the per-SP rules).

Compute `σ̂` once at the top of `analyze_parameter_estimation_problem` (before the interpolator loop) using the wrapper above on the first observable's data. `n_data` and `max_order` come from `setup_data` (which is computed early).

### Gate (b): per-shooting-point filter — in the SP loop

File: `src/core/optimized_multishot_estimation.jl:1423` (just after `interp_sym = ...`).

Add a check:

```julia
if !is_interpolator_applicable_at_sp(interp_method, t_eval, t_vector)
    @debug "[INTERP-GATE-SP] Skipping (method=$interp_method, t=$t_eval) — boundary issue"
    continue
end
```

Where `is_interpolator_applicable_at_sp(method, t_eval, t_vec)` encodes the per-SP rules (Chebyshev SP fraction, FHD SP fraction).

This drops the (method, SP) pair without removing the method globally — Chebyshev still works at interior SPs.

## Validation experiment

Single experiment: re-run the existing forced_lv sweep harness (`temp_plans/forced_lv_sp_mp_sweep.jl`) with gating active vs current default. Expected outcomes:
- S2AAAMLE absent at noise=1e-2 → median pool error drops from 0.6–9.6 range to ≈ 1e-3 range (matches GP family)
- Chebyshev kept on interior SPs (1.083, 2.787) but skipped at boundaries (0.083, 5.000) → boundary outliers gone
- aaad_gpr, agp_robust, agp_robust_se_times_rq all kept everywhere

Cross-check the four bilby noise tiers using `forced_lotka_volterra_0_{0,1em6,1em4,1em2}/`:
- noise=0 and 1em6: S2/AAAD KEPT, no regression
- noise=1em4: AAAD dropped (boundary at 1e-5), S2 still in (boundary at 1e-4)
- noise=1em2: both AAAD and S2 dropped

Pass criterion: per-tier pool's best-error ≤ current best; pool size shrinks at noise=1e-2 by ≥ 1 method; no tier loses any successful estimate.

## Out of scope / non-goals

- Don't introduce new interpolator implementations. Gating EXISTING ones.
- Don't rely on `EstimationOptions.noise_level` user supply — must be data-driven.
- Don't introduce a "noise mode" or "high-noise mode" config flag — gating should be silent and automatic.
- Don't change the polish-time bound enforcement (already wired separately).
- Don't propose deprecating S2 entirely — leave it usable when σ̂ ≤ 1e-4.

## Estimated implementation effort

~2-3 hours: helper wrapper (~30 lines), 2 gating functions (~60 lines), 2 wiring points, tests for each gate, validation experiment runs.

## References

- Source agent: dispatched 2026-05-05, results in conversation transcript at `~/.claude/projects/-home-orebas--julia-dev-ODEParameterEstimation/db83e333-b9d5-4e48-9fce-b2fe9a266752.jsonl` (search "Auto-Filtering Interpolators")
- Memory note: `~/.claude/projects/-home-orebas--julia-dev-ODEParameterEstimation/memory/session_2026_05_05_aggregation.md` section E
- Empirical evidence: `artifacts/diagnostics/seed_strategy_recon_2026_05_04/G3_forced_lv_sp_mp_sweep.md`
