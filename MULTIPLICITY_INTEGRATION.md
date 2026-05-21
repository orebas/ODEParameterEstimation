# Algebraic multiplicity (M) — handoff note

**Audience:** anyone (human or any claude instance) picking up the ODEPE
multiplicity-aware output work. Last updated 2026-05-20.

## What's in production now (committed to `main`)

`analyze_parameter_estimation_problem(pep, opts)` auto-computes the algebraic
multiplicity **M** during the SI template build, populates
`opts.algebraic_multiplicity` if the caller left it unset, and truncates the
returned candidate list to `min(M, branch_top_k, length(cluster_reps))` rows.

The new return field is exposed on the NamedTuple from
`analyze_estimation_result`:

```julia
analysis = analyze_estimation_result(pep, results; opts = opts)
analysis.algebraic_multiplicity   # Int (e.g., 1 or 2), or `nothing` for
                                   # systems with no locally identifiable vars
```

Positional destructure (the form benchmark scripts use) still works because
NamedTuples support both positional and named access.

## Required upstream dependency: Groebner.jl PR #218

The default `Groebner.groebner` path has an off-by-one in
`_groebner_learn_and_apply` when the parallel-task count is not a power of
two (most wallaby cluster setups). The bug fires on **biohydrogenation**
specifically among the 23 wallaby systems.

Fix is at <https://github.com/sumiya11/Groebner.jl/pull/218> (codex's patch
replacing `align_up`'s bitmask with `cld(x,n) * n`). Until it merges and
ships:

```julia
using Pkg
Pkg.develop(path = "/home/orebas/.julia/dev/Groebner")  # local fork w/ the patch
```

Once Groebner.jl releases a version including PR #218, do
`Pkg.free("Groebner")` and the package picks up the registered version.

**There is no fallback in ODEPE for Groebner failures.** If Groebner crashes
on a new system, ODEPE errors out cleanly rather than degrading silently.
This was a deliberate choice — fallbacks were obscuring real bugs.

## What was deliberately NOT done

- **No SIAN-Julia patch.** Earlier drafts of this work patched SIAN to
  expose `algebraic_multiplicity` from its internal Groebner step. That
  dependency has been removed; ODEPE is now compatible with stock SIAN
  v1.8.0. The Groebner call lives inside ODEPE's own
  `get_polynomial_system_from_sian` (reuses `Et_eval_base` etc. that are
  already computed).
- **No public `auto_algebraic_multiplicity(pep)` helper.** Earlier drafts
  shipped one; it was redundant with the in-pipeline auto-detection.
  Dropped to keep the API small.

## Note for PEB / benchmark software

**ODEPE auto-computes M now. PEB should stop passing it in the script
template.** Specifically: `generate_scripts.py` that currently sets
`opts.algebraic_multiplicity = M` from `config/systems.json` should be
updated to NOT set that field. Let ODEPE compute it.

Why: cleaner separation of concerns. The catalog at
`config/systems.json[*].algebraic_multiplicity` is now redundant — it
matches what ODEPE computes for all 23 wallaby systems (verified by
`repro/multiplicity_complete_2026_05_19/test_compute_M.txt`). Keeping
the catalog as a fallback or sanity reference is fine, but the
*injection* into per-cell scripts should stop.

The explicit-value path still works: any user who sets
`opts.algebraic_multiplicity` explicitly overrides the auto value.

## Source code changes (this work)

- `src/core/si_equation_builder.jl`: gb step at end of
  `get_polynomial_system_from_sian` (reusing `Et_eval_base`, `Q`, `u_hat`,
  `gens_Rjet`, `mu`, `not_int_cond_params`). No try/catch on Groebner —
  failures throw. Timing is logged unconditionally:

  ```
  [SI-TEMPLATE] algebraic_multiplicity M = 2  (setup 0.0s, Groebner 4.96s,
                quotient_basis 0.41s, ring: 27 vars × 32 polys)
  ```

- `src/core/optimized_multishot_estimation.jl`: added
  `_LAST_ESTIMATION_AUTO_M::Ref{Union{Nothing, Int}}` (internal); set from
  `si_template.rank_trimming_metadata.algebraic_multiplicity` after the
  SI template build. Cleared at function entry.

- `src/core/analysis_utils.jl`: in
  `analyze_parameter_estimation_problem`, if `opts.algebraic_multiplicity ===
  nothing` and `_LAST_ESTIMATION_AUTO_M[]` is non-nothing, reconstruct
  `opts` with the auto value before calling `analyze_estimation_result`.
  Converted that function's return from `Tuple` to `NamedTuple` (drop-in
  compatible — positional destructure preserved).

- `test/fast_core.jl`: updated one test that did `analysis[2:end]` (range
  indexing, not supported on NamedTuple) to use named-field access.

Total: ~80 lines added, ~10 modified, 1 small test update.

## Expected behavior on the 23 wallaby systems

| Multiplicity | Systems | Per-cell Groebner cost |
|---|---|---|
| M = 1 (19) | aircraft_pitch, bicycle_model, boost_converter, brusselator, crauste, cstr, daisy_mamil3, dc_motor, fitzhugh_nagumo, flexible_arm, forced_lotka_volterra, harmonic_oscillator, hiv, lotka_volterra, mass_spring_damper, quadrotor, repressilator, sirt_treatment, vanderpol | < 1s except crauste/cstr/hiv (1–8s) |
| M = 2 (4) | daisy_mamil4, seir, slow_fast, biohydrogenation | 0.3–8s |

Net cost: ~30–60 minutes added to a full 1147-cell wallaby run.

`result.csv` now has at most M rows per cell instead of K=20:
- 19 systems × 50 cells: 1 row each (was 20)
- 4 systems × 50 cells: 2 rows each (was 20)

Per `repro/wallaby_analysis/m_truncation_impact.md` (cluster's earlier
analysis): top-1 unchanged, K=20 oracle ceiling drops -2.6pp (polish) /
-4.1pp (nopolish) at @10% — that's the *visibility* of the oracle metric
dropping, not the *quality* of solutions. M-bounded paper metric: 0pp
change by definition.

## Verification

```bash
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
# Expected: 259/259 PASS

julia --startup-file=no repro/multiplicity_complete_2026_05_19/test_compute_M.jl
# Expected: 30/30 PASS (23 wallaby + 7 synthetic)
```

## Background reading (in repro/multiplicity_complete_2026_05_19/)

- `MULTIPLICITY_COMPLETE.md` — algebraic multiplicity catalog for all 23
  wallaby systems, branch transformations, plug-in procedure
- `M_INFERENCE_TECHNICAL.md` — deep dive on SI.jl / SIAN-Julia / ODEPE
  paths and why this implementation lives where it does
- `GROEBNER_BUG_REPORT.md` — the upstream Groebner bug we hit + workaround
  matrix (now resolved by PR #218)
- `compute_M.jl` + `test_compute_M.jl` — standalone reference implementation
  (used to validate the in-pipeline version against 30 systems)
- Various per-system diagnostic scripts (branches_in_bounds.py,
  biohydrogenation_actual_branches.py, etc.)
