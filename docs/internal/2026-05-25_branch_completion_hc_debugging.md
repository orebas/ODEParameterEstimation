# Branch Completion / HC Debugging Notes

Date: 2026-05-25

Status: **the SEIR puzzle below is resolved** — see
[`2026-05-25_zero_ic_jet_degeneracy.md`](2026-05-25_zero_ic_jet_degeneracy.md).
Short version: `In(0) = 0` is a critical point of the identifiability map, so the
t0-instantiated jet system is rank-deficient (`cond(J) = 4.4e17`,
`mixed_volume = 0`) and is satisfied by the true parameters *and* both spurious
"branches" at once. HC is not at fault; the evaluation point is degenerate. The
HC-wrapper changes (keep singular roots, do not project complex roots) are still
worth reviewing on their own merits. This note is retained as the handoff for
another reviewer who knows ODEParameterEstimation.jl,
HomotopyContinuation.jl, or the SI-template code path.

## Goal

We are experimenting with an algebraic branch-completion mode for systems with
algebraic multiplicity `M > 1`.

The desired behavior is:

1. Run the normal ODEPE pipeline to get a high-quality top candidate.
2. Treat that top candidate as an anchor.
3. Compute the exact observable/state derivative jet implied by the anchor.
4. Reuse the already-built SI template.
5. Substitute the anchor jet into the template to get a concrete polynomial
   system.
6. Solve that system to recover the algebraic sibling branches.
7. Replace the normal returned candidate set with the completed algebraic branch
   set.

This is meant to make ODEPE return the expected algebraic branch set, rather
than returning duplicate rows from the same branch or depending on chance that
the normal multi-shot pool contains every branch.

The important conceptual point: branch completion should not be a second
estimator. It should be an algebraic completion step around the best candidate
already found by the existing estimator.

## Code Reused

Branch completion deliberately reuses the existing pipeline components:

- Existing normal pipeline chooses the anchor:
  - interpolation
  - shooting points
  - multipoint solves
  - parameter homotopy
  - candidate synthesis
  - polish, when enabled
  - normal output ranking

- Existing SI template:
  - `setup_data.si_template` from `optimized_multishot_parameter_estimation`
  - no SIAN rerun inside branch completion

- Existing derivative machinery:
  - `_consensus_candidate_pep`
  - `build_perfect_interpolants`
  - oracle Taylor coefficient helpers

- Existing SI-template instantiation path:
  - `instantiate_si_template_equations(...)`
  - factored out of `construct_equation_system_from_si_template(...)`

- Existing HC wrapper:
  - `solve_with_hc(...)`

- Existing result reconstruction:
  - `process_estimation_results(...)`

The main new file is:

- `src/core/branch_completion.jl`

Related changed files:

- `src/ODEParameterEstimation.jl`
- `src/core/analysis_utils.jl`
- `src/core/homotopy_continuation.jl`
- `src/core/optimized_multishot_estimation.jl`
- `src/core/si_template_integration.jl`
- `src/types/estimation_options.jl`
- `test/fast_core.jl`

## Current Branch-Completion Flow

The entry point is:

```julia
maybe_replace_with_branch_completion(PEP, solved_res, setup_data, opts)
```

This runs after the normal candidate pool has been generated and optionally
polished/synthesized.

It currently does:

1. Check `opts.branch_completion`.
2. Check there is at least one candidate in `solved_res`.
3. Determine algebraic multiplicity from `opts.algebraic_multiplicity` or
   `setup_data.si_template.rank_trimming_metadata.algebraic_multiplicity`.
4. Rank the normal candidates with the same output ranking path.
5. Try up to `opts.branch_completion_max_anchors` top anchors.
6. For each anchor, call:

```julia
complete_branches_from_anchor_report(PEP, anchor, setup_data, opts)
```

The report path exists because silent fallback was confusing and bad. It records
statuses such as:

- `:completed`
- `:no_hc_roots`
- `:non_square_template`
- `:all_failed_dropped_equations`
- `:template_instantiation_failed`
- `:anchor_interpolants_failed`

If completion succeeds, returned rows are tagged with provenance note
`:branch_completion` and `:branch_completion_replaced`.

If completion fails, the original pool is returned and tagged with
`:branch_completion_kept_original_pool` plus the reason.

## Important Policy Decisions So Far

### Bounds Should Not Filter Algebraic Siblings

Originally branch completion applied `opts.opt_lb` / `opts.opt_ub` to completed
rows. This caused `slow_fast` to return only one completed row even though HC
had found and processed two roots.

With bounds on:

```text
slow_fast: n_hc_roots=2, n_processed=2, n_bounds_passed=1, returned=1
```

With bounds off:

```text
slow_fast: returned 2 branch-completed rows
```

The current position is that if this mode is explicitly returning algebraic
branches, optimizer search bounds should not discard algebraic siblings. Bounds
may be a useful search-domain notion for polish/optimization, but not for
branch existence.

The explicit bounds filter was removed from branch completion.

### Singular HC Roots Should Not Be Dropped Globally

`solve_with_hc(...)` previously called:

```julia
HomotopyContinuation.solutions(res, only_real = true, real_tol = 1e-9)
```

HC.jl's `solutions(...)` defaults to `only_nonsingular = true`, so singular
solutions were silently dropped. That was probably not intended for ODEPE,
because algebraic systems can produce singular but valid roots.

The wrapper was changed to:

```julia
HomotopyContinuation.solutions(
    res;
    only_nonsingular = false,
    only_real = true,
    real_atol = real_tol,
)
```

### Do Not Project Complex Roots to Real Parts

The old wrapper also had this fallback:

```julia
if isempty(real_solutions)
    sols = HomotopyContinuation.solutions(res)
end
```

Then it returned `real(s[j])` for each coordinate. That means genuinely complex
roots were projected onto the real axis and treated as candidate rows.

This produced bad `seir` branch-completion rows with worse fit error:

```text
completed row 1 err ~ 1.3e-3
completed row 2 err ~ 6.7e-3
```

while the anchor had:

```text
anchor err ~ 2e-14
```

Those completed rows were not valid algebraic equivalents; they were real parts
of complex roots. The fallback has been removed. Now if there are no real roots,
`solve_with_hc` returns no rows.

## The Current Puzzling Case: SEIR Branch Completion

The focused system is `seir` under full-fat-ish local settings:

- `datasize = 101`
- `noise_level = 0.0`
- `shooting_points = 20`
- `shooting_warp = true`
- `use_parameter_homotopy = true`
- `use_multipoint = true`
- `multipoint_n_points = 2`
- `multipoint_max_pairs = 15`
- `synthesize_aggregate_candidates = true`
- no polish in the focused local probe
- `algebraic_multiplicity = 2`
- `branch_completion = true`

The normal pipeline returns two excellent candidates:

```text
baseline row 1 err = 2.05368005527328e-14
states: S=420.01056337722684, E=5.62234793784651,
        In=1.2795795700830634e-13, N=1000.0
params: a=0.08320754663852091,
        b=0.46047786217746406,
        nu=0.2667924533631822

baseline row 2 err = 2.3437743607991532e-14
states: S=352.1317801877017, E=5.319028342517032,
        In=-2.3808610440999783e-14, N=1000.0
params: a=0.06799360647273368,
        b=0.48915369730500985,
        nu=0.28200639353832047
```

Branch completion uses row 1 as the anchor.

It reuses the existing SI template and instantiates it with the anchor-implied
exact jet at `t0`. It produces a 26 equation / 26 variable polynomial system.

The anchor vector is purely real and directly satisfies both:

- the Symbolics-side instantiated system
- the HC-converted system

Residuals:

```text
Symbolics residual at anchor = 1.9964221423241503e-13
HC evaluate(system, anchor)  = 2.294504902641914e-13
```

But HC global solve from scratch reports no real roots:

```text
Result with 3 solutions
=======================
• 6 paths tracked
• 0 non-singular solutions (0 real)
• 3 singular solutions (0 real)
• start_system: :polyhedral
```

The three roots are not almost-real. Imaginary summaries:

```text
root 1: max |imag| = 2.7234e4, max |real| = 1.4014e4, relative imag = 1.94
root 2: max |imag| = 4.7480e5, max |real| = 1.3399e5, relative imag = 3.54
root 3: max |imag| = 6.9177e2, max |real| = 1.3721e3, relative imag = 0.50
```

So this is not a tight realness tolerance problem.

## Debug Artifact

The concrete instantiated system and raw roots are dumped at:

```text
/tmp/seir_branch_completion_debug_20260525_175819.jl
```

This artifact includes:

- `status`
- `model`
- `n_equations`
- `n_vars`
- `anchor_err`
- `anchor_residual`
- `hc_anchor_residual`
- HC result summary
- imaginary summaries
- variable order
- anchor values
- anchor states/parameters
- all instantiated equations as strings
- all HC roots

The first few equations are:

```text
1.2795795700830634e-13 - In_0
In_1 - E_0*nu_0 + In_0*a_0
1000.0 - N_0
N_1
1.499999999999488 - In_1
```

The variable order begins:

```text
In_0, nu_0, a_0, E_0, In_1, N_0, N_1, E_1, In_2, b_0, S_0, ...
```

The anchor values begin:

```text
In_0 = 1.2795795700830634e-13
nu_0 = 0.2667924533631822
a_0  = 0.08320754663852091
E_0  = 5.62234793784651
In_1 = 1.499999999999488
N_0  = 1000.0
N_1  = 0.0
E_1  = -1.499999999999474
```

## Direct HC Checks Run

A direct check script was started:

```text
/tmp/seir_hc_direct_checks.jl
```

It reported:

```text
n_equations = 26
n_vars = 26
symbolics_anchor_residual = 1.9964221423241503e-13
hc_anchor_residual = 2.294504902641914e-13
mixed_volume = 0
paths_polyhedral = 6
paths_total_degree = 1259712
```

The polyhedral solve reported:

```text
Result with 1 solution
• 6 paths tracked
• 0 non-singular solutions (0 real)
• 1 singular solution (0 real)
```

The single root was complex:

```text
max_abs_imag = 47600.61233108714
residual = 6.782296188893515e-8
```

The total-degree solve was not allowed to continue because it would track
1,259,712 paths. The process was killed intentionally.

A cheaper Newton-from-anchor script is currently/was recently running:

```text
/tmp/seir_hc_anchor_newton_check.jl
```

It skips total-degree solving and attempts:

```julia
HomotopyContinuation.newton(hc_system, anchor; max_iters=50,
    atol=1e-12, rtol=1e-12, extended_precision=true)
```

At the time this note was written, its final result had not yet been recorded.

Update: the Newton-from-anchor script finished with:

```text
n_equations = 26
n_vars = 26
symbolics_anchor_residual = 1.9964221423241503e-13
hc_anchor_residual = 2.294504902641914e-13
mixed_volume = 0
paths_polyhedral = 6
paths_total_degree = 1259712
newton_anchor_return_code = rejected
newton_anchor_accuracy = 111.2255156770006
newton_anchor_residual = 4.421286455193217
newton_anchor_final_residual = 76.64195083214571
newton_anchor_max_abs_imag = 0.0
newton_anchor_max_delta = 193.9903386024006
```

So a direct Newton call from the anchor is not a quick fix. It moves far from
the anchor and is rejected, despite the initial anchor residual being near
machine precision. This is additional evidence that the anchored system is
singular/ill-conditioned in a way that makes standard local Newton correction
unreliable.

## Why This Does Not Immediately Invalidate All ODEPE HC Use

This case is not the normal ODEPE solve.

Normal ODEPE solves many systems created from production interpolated derivative
values at shooting/multipoint locations. Those systems can be more generic, less
specialized, and not forced to pass through a final anchor-implied exact jet.

The failing branch-completion system is a highly specialized instantiated
system:

- anchored at a final candidate,
- exact-jet substituted,
- at `t0`,
- with several variables forced by equations like `N_1 = 0`, `N_2 = 0`,
  `N_3 = 0`, `N_4 = 0`,
- apparently degenerate: `mixed_volume(hc_system) = 0`, while
  `paths_to_track(..., :polyhedral) = 6`.

So the current evidence points more toward:

- a degenerate/specialized branch-completion system,
- singular root behavior,
- or a bad way of asking HC to rediscover a known anchor root,

than toward "HC is unusable in all of ODEPE."

That said, it does raise an important general concern: if a specialized system
has a directly verifiable real root and HC's global solve does not report it,
then branch completion should not rely solely on a fresh global polyhedral solve
of the anchored system.

## Leading Hypotheses

### Hypothesis 1: Degenerate Specialized System

The anchored `seir` system is not generic. The anchor root may lie on a singular
component or near a non-isolated/ill-conditioned specialization.

Evidence:

- `mixed_volume(hc_system) = 0`
- `paths_polyhedral = 6`
- HC reports singular roots only
- direct anchor residual is tiny

### Hypothesis 2: Need Deflation / Local Recovery Around Anchor

If the anchor is a known root, requiring a global polyhedral solve to rediscover
it may be the wrong approach. We may need:

- Newton refinement from the anchor,
- deflation,
- local algebraic solve after fixing/linearizing some variables,
- parameter homotopy from a generic nearby perturbation back to the anchor jet,
- or a specialized singular-root recovery path.

### Hypothesis 3: The Trimmed Template Is Numerically Bad for Completion

The template used for normal solving is rank-trimmed/squarified. It may be good
for generic noisy solves but bad for exact branch completion at a singular
anchor.

Need to compare:

- trimmed selected equations,
- full equation set,
- dropped-equation verification,
- alternative square subsets,
- equation scaling / variable scaling.

### Hypothesis 4: The Anchor Is Locally Valid but Not a Member of the Same
Global Branch Set HC Is Tracking

This is less likely because `HC.evaluate(hc_system, anchor)` is tiny for the
same converted system, same variable order, and same equations. But it remains
possible that the system is non-isolated or has structure that makes "root
count" semantics misleading.

## Reproduction Commands

From repo root:

```bash
julia --startup-file=no /tmp/seir_branch_completion_probe.jl
```

Expected current behavior:

```text
returned_rows=2
branch_completed_rows=0
status_notes=branch_completion_kept_original_pool|branch_completion_no_hc_roots
debug_status=no_hc_roots
anchor_residual ~= 2e-13
hc_anchor_residual ~= 2.3e-13
HC reports 3 singular non-real roots
```

Dump the system:

```bash
julia --startup-file=no /tmp/seir_branch_completion_dump.jl
```

Expected output:

```text
/tmp/seir_branch_completion_debug_<timestamp>.jl
```

Direct HC checks:

```bash
julia --startup-file=no /tmp/seir_hc_anchor_newton_check.jl
```

Avoid running `/tmp/seir_hc_direct_checks.jl` unless you edit out the
total-degree solve, because `paths_total_degree = 1259712`.

Run core regression:

```bash
julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'
```

Last observed result after current edits:

```text
Fast Core Contracts | 313 / 313 passed
```

## Questions for a Reviewer

1. Why does `HomotopyContinuation.mixed_volume(hc_system)` return `0` while
   `paths_to_track(hc_system; start_system=:polyhedral)` returns `6`?

2. Given a directly verified real anchor root, what is the right HC.jl workflow
   to recover or certify that root?

3. Is `newton(hc_system, anchor)` expected to succeed or fail on this kind of
   singular system?

4. Should branch completion use a parameter-homotopy strategy instead of a
   fresh global solve?

5. Should branch completion instantiate the full template and choose a different
   square subsystem, instead of using the same rank-trimmed template as normal
   estimation?

6. Are the equations with many exact-zero derivative constraints (`N_1`, `N_2`,
   `N_3`, `N_4`) creating a degenerate root-count problem?

7. Can we use the known anchor root plus algebraic multiplicity to construct a
   better completion problem, rather than rediscovering the anchor with HC?

## Current Recommendation

Do not enable branch completion as a default yet.

Keep the infrastructure and diagnostics, but treat this as an experimental
branch-aware ablation until the `seir` anchored-system issue is understood.

Separately, the shared HC wrapper changes are probably correct and should be
reviewed carefully:

1. Keep singular roots:

```julia
only_nonsingular = false
```

2. Do not project complex roots to real parts.

Those changes align better with algebraic solving semantics, but they can change
behavior outside branch completion, so they deserve explicit regression tests.
