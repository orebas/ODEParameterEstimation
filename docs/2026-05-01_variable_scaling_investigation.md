# Variable scaling / column-rescaling investigation

A future-work note for whoever (Claude, Codex, or human) picks up the
reconditioning thread. This is **investigation territory**, not a green-lit
implementation plan. The goal is to confirm the gap, prototype a fix,
and decide whether it earns its complexity.

## Why this is on the radar

Diagnostics on the IEEE paper's "challenging" systems (biohydrogenation,
DAISY MaMil4, crauste) revealed that the dominant failure mode for two
of them is Jacobian conditioning of the polynomial system that maps
data-derivatives to (parameters, initial conditions). Concrete numbers
from the new diagnostic framework:

| Case | cond(J) | rel err | bottleneck |
| --- | --- | --- | --- |
| biohydrogenation, noise=1e-8 | 4.5e+10 | 11% | conditioning + rank deficiency (24/25) |
| daisy_mamil4, noise=1e-8 | 2.0e+6 | 57% | conditioning |
| daisy_mamil4, noise=0 | 1.2e+6 | 2.6e-6 | conditioning (subdued by clean data) |

For these systems, derivative errors of 1e-8 to 1e-4 get amplified by
6 to 10 orders of magnitude in solution space. Tiny noise becomes huge
parameter error. The diagnostic correctly classifies these as
"moderate / Jacobian conditioning."

A standard reconditioning lever for ill-conditioned polynomial systems
is **variable rescaling** — substituting scaled variables before
constructing the polynomial system, so the Jacobian columns have
similar magnitudes. This is structurally different from the row-
equilibration that HC.jl already does (see below), and it is currently
**not done anywhere in the ODEPE → HC.jl pipeline**.

The full diagnostic write-up that prompted this investigation is at:
`/home/orebas/tex/ParameterEstimation-IEEE/docs/method_failure_modes.md`

## What the pipeline already does

**HC.jl already does row scaling.** In
`~/.julia/packages/HomotopyContinuation/<hash>/src/linear_algebra.jl`,
HC implements Skeel row equilibration (`skeel_row_scaling!`,
`apply_row_scaling!`, `row_scaling::Bool = true` at the public API
boundary). Every Newton step during homotopy continuation rescales the
rows of the local Jacobian to minimize cond bound with respect to row
scaling. This is automatic and on by default; ODEPE does not have to
invoke it. The relevant publication is R. D. Skeel, "Scaling for
numerical stability in Gaussian elimination" (1979).

**ODEPE does NOT do polynomial-system rescaling.** Searching the source
turns up GP-input normalization only (z-score on the response Y for GP
fits in `core/uncertainty_quantification.jl`,
`examples/study_approx.jl`). That is interpolant hygiene, not
polynomial-system reconditioning.

**Net:** ODEPE hands HC.jl a polynomial system in raw parameter units.
HC.jl row-equilibrates internally each Newton step, but neither layer
column-equilibrates. Parameters spanning several orders of magnitude
(e.g. biohydrogenation's `k0`, `E_R` in raw thermodynamic units;
daisy_mamil4's compartment rates) leave the Jacobian's columns
proportionally imbalanced.

## What "variable scaling" would mean here

Define a scaling vector `s = (s_1, ..., s_N)` for the unknowns
(parameters + initial-condition states). Substitute scaled variables
`p̃_i = p_i / s_i` before constructing the polynomial system. Solve
for `p̃` via the existing pipeline. Recover `p_i = s_i * p̃_i` at the
end. The substitution is mathematically equivalent (same roots) but
numerically very different: cond(J) is rescaled by the diagonal matrix
`diag(s)`, and choosing `s` well drives cond(J) toward its minimum
over diagonal scalings.

Choices for `s`:

1. **Bound-based.** `s_i = upper_bound_i` (the search box's top edge).
   Trivial to implement, requires only the existing `SEARCH_BOUNDS`
   config.
2. **Column-norm-based.** `s_i = ‖J(:, i)‖_2`, where J is the Jacobian
   evaluated at the candidate root. Closer to optimal but requires
   computing J at least once.
3. **Geometric mean of bounds.** `s_i = sqrt(lb_i * ub_i)` if both
   bounds are positive. Robust if the bound is loose.
4. **User-provided / system-defined.** Per-system scale hints in
   `systems.json` if the user has prior knowledge.

For an initial implementation, option 1 is the cheapest sane default.
Option 2 is what serious linear-algebra packages do but requires
plumbing.

## Three levels of intervention, increasing in invasiveness

### Level A: variable-substitution wrapper around the existing pipeline

Pure pre/post substitution. The polynomial-system construction code
runs unchanged in scaled coordinates; the only changes are at the I/O
boundary: substitute on the way in, unsubstitute the recovered roots
on the way out.

**Pros:**
- Smallest diff. Probably 50-100 lines.
- Fully transparent to HC.jl and the polish step (they see better-
  conditioned coordinates).
- Easy to A/B test with a flag in `EstimationOptions`.

**Cons:**
- All of the polynomial system has to be re-built every time the
  scaling changes. SI / structural-identifiability templates may need
  to be re-derived in scaled coordinates (or invariance verified).
- Polish-step `opt_lb` / `opt_ub` and convergence thresholds need to
  be expressed in scaled coordinates too. Easy to miss one.

**Files likely touched:**
- `src/core/parameter_estimation.jl` — top-level driver; needs to
  accept a `variable_scaling` option and apply substitution.
- `src/core/parameter_estimation_helpers.jl` — for the unsubstitution.
- `src/types/estimation_options.jl` — new option field.
- `src/types/core_types.jl` — possibly a scaled-coordinate variant
  of `ParameterEstimationProblem`.

### Level B: scaled coordinates throughout the pipeline

Make the polynomial system natively dimensionless by carrying scales
through the SI template generation, the symbolic differentiation, and
the polish step. This eliminates the mathematical-equivalence-but-
numerical-difference asymmetry entirely.

**Pros:**
- Cleanest from a numerical-accuracy standpoint.
- Polish step naturally inherits the scaling without separate plumbing.
- A column-norm-based `s` (option 2 above) becomes feasible because
  J is already computed mid-pipeline.

**Cons:**
- Bigger refactor. Probably 300-500 lines. Touches the symbolic stack.
- More integration testing.

### Level C: research direction

Investigate whether there's an even-better-conditioned formulation of
the algebraic problem itself. The differential-algebraic method has
freedom in *which* derivative orders to use and *what elimination
ordering* to apply. For specific bad-conditioning cases (e.g.
biohydrogenation's rank deficiency at noise > 0), there may be an
alternative formulation that is structurally better-conditioned.

Out of scope for this note. Mentioned for completeness.

## Verification approach

If/when implementing Level A:

1. Run the diagnostic on biohydrogenation_0_0 in scaled coordinates,
   compare cond(J) before vs after. Hypothesis: cond drops by 1-3
   orders of magnitude with bound-based scaling.
2. Run the full paper benchmark on a small subset (one or two systems
   at one or two noise levels) before and after the rescaling, verify
   that recovery accuracy improves and run-time doesn't regress.
3. Check that all existing regression tests in `test/fast_core.jl`,
   `test/feature_regressions.jl`, and the example smoke tests still
   pass.
4. Bonus: add a regression test that asserts cond(J) is below a
   threshold for biohydrogenation under a known scaling, so future
   refactors don't silently regress.

## What to NOT do

- Do not duplicate Skeel row scaling. HC.jl already does it; replicating
  it inside ODEPE would conflict.
- Do not silently change defaults on first iteration. Add the option,
  default it off, prove it helps on a benchmark subset, *then* discuss
  flipping the default.
- Do not assume the substitution is invariant to the SI step. Verify.

## Pointers

- Diagnostic data and per-case explanation:
  `/home/orebas/tex/ParameterEstimation-IEEE/docs/method_failure_modes.md`
- Diagnostic outputs (HTML + summary text + CSVs):
  `/home/orebas/sandbox/diagnostics-2026-04/<id>/artifacts/diagnostics/<system>/`
- HC.jl row-scaling source:
  `~/.julia/packages/HomotopyContinuation/<latest>/src/linear_algebra.jl`
  (search for `skeel_row_scaling!`)
- ODEPE GP-input normalization (for reference, NOT what we're doing):
  `src/core/uncertainty_quantification.jl`,
  `src/examples/study_approx.jl`
- Reproducibility audit (broader paper context):
  `/home/orebas/tex/ParameterEstimation-IEEE/docs/reproducibility_audit.md`
