# Multi-Interpolator Pipeline & Homotopy Complex-Projection Fix

**Date:** 2026-03-05

---

## 1. Multi-Interpolator Pipeline

**Problem:** Running multiple GP kernel variants (SE, RQ, SE+RQ, SE*RQ) required separate full pipeline invocations, each repeating the expensive SIAN/SI identifiability analysis (~20s on HIV model).

**Solution:** A new `interpolators` field on `EstimationOptions` accepts a list of `InterpolatorMethod` values. The identifiability analysis and SI template construction run once (via new `setup_identifiability()` function), then each interpolator gets its own interpolant creation + HC solve pass. Results are tagged with `interpolator_source::Symbol` on `ParameterEstimationResult` so downstream code can attribute solutions to their source.

**Key files changed:**
- `src/types/estimation_options.jl` -- `interpolators`, `custom_interpolators` fields; `resolve_interpolator_list()`, `interpolator_method_to_symbol()` helpers; three new kernel enum values (`InterpolatorAGPRobustRQ`, `InterpolatorAGPRobustSEpRQ`, `InterpolatorAGPRobustSExRQ`)
- `src/types/core_types.jl` -- `interpolator_source` field + backward-compatible constructor
- `src/core/parameter_estimation_helpers.jl` -- `setup_identifiability()` extracted
- `src/core/optimized_multishot_estimation.jl` -- multi-interpolator loop with shared SI template
- `src/core/derivatives.jl` -- `kernel_type` parameter on `agp_gpr_robust` for RQ/composite kernels
- `src/core/analysis_utils.jl` -- `try_more_methods` guard when `interpolators` list is active

**Backward compatibility:** When `interpolators` is empty (default), the pipeline falls back to the single `interpolator` field. Zero breaking changes for existing callers.

---

## 2. Homotopy Complex-Projection Fix

**Problem:** `solve_with_hc_parameterized` (the parameter homotopy path) extracted only `only_real=true` solutions at each shooting point. When all HC roots were complex at a point -- common when interpolation noise perturbs the system -- zero solutions were returned. The non-homotopy path (`solve_with_hc`) had a fallback: when 0 real solutions exist, project ALL solutions to their real parts. These projected points often polish to genuine solutions.

**Result before fix:** Homotopy produced ~50% fewer solutions than non-homotopy:
- Solo AGP: 16 (Hom) vs 32 (NoHom)
- Multi 5-interpolator: 79 (Hom) vs 147 (NoHom)

**Fix:** 7-line insertion in `src/core/homotopy_continuation.jl` (line 972) adding the same conditional fallback: when `isempty(real_solutions_hc)`, take all solutions and let the existing `real()` projection + downstream polishing handle them.

**Why conditional (not always-project):** When real solutions exist, complex projections add noise -- conjugate pairs `a +/- bi` project to `a`, which is typically not near any real root. When 0 real solutions exist, projection is the only way to recover near-real candidates.

**Verification:** Ran `run_interpolator_experiment.jl` (4 configs x 2 passes, wombat HIV model, datasize=1500, noise=1e-8):

| Config | n_sol (before) | n_sol (after) | max_rel_err |
|--------|---------------|---------------|-------------|
| Solo AGP+Hom | 16 | **32** | 1.85e+00 |
| Solo AGP NoHom | 32 | **32** | 1.85e+00 |
| Multi+Hom (5 interps) | 79 | **147** | 1.00e+00 |
| Multi NoHom (5 interps) | 147 | **147** | 1.00e+00 |

Per-interpolator comparison (Multi, timed pass): all 5 interpolators tied on both solution count and best error between Hom and NoHom.

---

## Summary

The multi-interpolator pipeline eliminates redundant identifiability analysis when comparing kernel variants, reducing 5-interpolator wall time from ~5x solo to ~1.2x. The homotopy fix closes a solution extraction gap that caused parameter homotopy to drop half its solutions, bringing it to exact parity with fresh-solve on the HIV benchmark.
