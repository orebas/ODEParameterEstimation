# Reusable polynomial polishing and Jacobian comparison

The raw single-point root polisher now compiles a polynomial structure with
numerical observation data as runtime arguments. The selected noise-frontier
system can reuse that function across roots, shooting points, and interpolators.
ForwardDiff remains the default, with one derivative direction per chunk;
symbolic and finite-difference Jacobians are selectable. Dependencies are unchanged.

## Why compilation was repeated

Previously, the caller substituted each shooting point's numerical observation
jets into the equations before `solve_with_robust` called `build_function`.
Changing those constants changed the generated function. ForwardDiff then
needed a dual-number specialization for the new function. Already compiling its
Float64 evaluation did not avoid this specialization.

The May 19 change (`e85a9f4`) selected ForwardDiff to address memory growth from
symbolic Jacobian construction. Its memory MWE constructed the AD closures but
never called them. It therefore did not measure this repeated AD compilation.
The September 11 deferred-denominator change did not modify the polisher, and
the retained before/after biohydrogenation derivative tables matched exactly.
We have not isolated a Julia/compiler-version regression.

The earlier biohydrogenation timeout occurred in **single-point** root polishing,
after that interpolator's single-point HC solves. Its 3,600-second limit covered
the whole estimation stage, not one compilation. The separate `--optimize=0`
completion spent 1,016.9 seconds in 585 root-polishing calls.

## Implementation and scope

Write the polynomial equations as F(z, d) = 0, where z contains the algebraic
unknowns and d contains the observation values and derivatives at an anchor.
The compiled residual has signature `F!(residual, z, d)`. A solve-local closure
binds its own copy of d, while the generated function stays the same. Symbolics
supports these separate runtime argument groups directly in
[`build_function`](https://docs.sciml.ai/Symbolics/stable/manual/build_function/).

[`PreparedRobustSystem`](../src/core/robust_system.jl) stores the residual and,
when selected, a compiled symbolic Jacobian J = ∂F/∂z. ForwardDiff and FiniteDiff
receive workspaces owned by each solve. The run-local cache key includes the
equations, unknown order, data-symbol order, Jacobian method, and AD chunk size;
it retains the full key rather than relying on a hash alone.

Both ordinary single-point and parameter-homotopy callers use this cache.
The legacy construction policy can rename or reorder unknowns, so it conservatively
caches the instantiated system across roots at one point. It does not receive
the same cross-point reuse guarantee. A genuinely different selected equation
system also needs another kernel. This change concerns raw algebraic polishing;
it does not redesign trajectory polishing or multipoint HC evaluation.

For optimization-based solves, the gradient of ½‖F‖² is computed as JᵀF using
the existing residual/Jacobian kernels. This avoids generating a separate
expanded symbolic gradient. Rectangular least-squares problems now declare
their residual and Jacobian dimensions explicitly to NonlinearSolve; otherwise
the in-place generated residual could write past a buffer sized for the unknowns.
The FiniteDiff cache likewise receives the unknown and residual buffers in the
proper order. The new rectangular tests cover both TrustRegion and BFGS.

## Comparison on the actual biohydrogenation system

The retained capture is the first AGPRobust interpolator's **selected** system:
25 equations, 25 unknowns, 12 numerical data entries, total degree at most four,
375 monomials summed over equations, and at most 73 monomials in one equation.
It contains 75 HC candidates from 20 shooting points. This is more representative
than the initial saved-SI-template probe (383 terms and nine data symbols).

The following measurements use Julia 1.13.0 and in-place Jacobian evaluations.
Errors are maximum relative matrix-norm discrepancies across the 75 roots,
against a symbolic Jacobian evaluated with 256-bit arithmetic. Warm times average
1,000 evaluations at the first point.

| Method | First evaluation | Warm evaluation | Maximum relative discrepancy |
|---|---:|---:|---:|
| Compiled symbolic | 0.65 s | 0.68 µs | 3.7 × 10⁻¹⁴ |
| ForwardDiff, chunk 1 | 0.64 s | 14.69 µs | 3.7 × 10⁻¹⁴ |
| ForwardDiff, automatic chunk 9 | 2.33 s | 7.86 µs | 3.7 × 10⁻¹⁴ |
| Central finite differences | 0.29 s | 14.80 µs | 2.2 × 10⁻⁸ |
| Complex step | 0.77 s | 16.89 µs | 2.4 × 10⁻¹³ |
| HC interpreted Jacobian | 3.57 s | 9.40 µs | 3.1 × 10⁻¹⁴ |
| HC compiled Jacobian | 3.07 s | 0.80 µs | 3.9 × 10⁻¹⁴ |

These first-evaluation numbers exclude construction. Shared residual construction
took 0.26 seconds; symbolic differentiation took another 4.19 seconds, almost
entirely Julia compilation. HC interpreted construction took 10.84 seconds and
included the first shared HC conversion; compiled construction subsequently took
0.51 seconds. Methods were measured sequentially, so shared library warmup and
concurrent workloads limit cold-start comparisons. The central-difference probe
is also distinct from the production `:finitediff` callback's library default.

Both symbolic differentiation and ForwardDiff compute the derivative of F;
their floating-point evaluation order can differ. In the initial solver replay,
ForwardDiff polished all 75 candidates. Symbolic polishing accepted 74, with one
solver-return-code failure at point 9, root 3. The caller retains the original HC
candidate when polishing fails. Among shared successful results, the largest
relative root-vector difference was 5.3 × 10⁻¹⁹. This is a reason to keep the
default conservative, not evidence that the symbolic derivative is incorrect.

The legacy ForwardDiff replay took 13.08 seconds for its first root and 2.23
seconds for the first root at the next point, almost entirely compilation;
other roots at those points took about 3 ms. The prepared ForwardDiff replay
took 3.60 seconds for all 75 roots, including 3.58 seconds for the first call.
The remaining 74 took 0.017 seconds altogether. These replay timings precede
the rectangular-buffer fix; a final-source replay is retained separately.

Chunk 1 reduces first-use AD compilation here, at a small warm evaluation cost.
This is a workload choice, not a universal optimum; ForwardDiff's
[configuration guide](https://juliadiff.org/ForwardDiff.jl/stable/user/advanced/#Configuring-Chunk-Size)
also recommends benchmarking chunk sizes for the target function. The implementation
does not add complex-step or HC backends: they did not justify additional
production plumbing in this measured case.

```julia
EstimationOptions(polish_solver_jacobian = :forwarddiff,
                  polish_solver_chunk_size = 1)  # defaults
EstimationOptions(polish_solver_jacobian = :symbolic)
EstimationOptions(polish_solver_jacobian = :forwarddiff,
                  polish_solver_chunk_size = 0)  # automatic chunk selection
```

## Full biohydrogenation validation

The normal-compiler run completed in **1,502.6 seconds (25.0 minutes)** with the
same frozen 750-sample data (nominal noise 10⁻⁶), all nine interpolators, 20 anchors,
and two-point multipoint estimation. It recorded:

- One prepared kernel, with 179 hits after its first construction.
- 585 raw polishing calls totaling **24.66 seconds**; the longest took 5.93 seconds.
- ForwardDiff chunk 1 and the prepared data-parameterized system in every call.
- Completion through trajectory polishing and branch completion.

This demonstrates completion with normal optimization. The old `--optimize=0`
timing used different compiler settings and concurrent workloads, so the ratio
of total runtimes is not a controlled speedup estimate.

The existing parameter-recovery failure remains: the selected k₁₀ is 5.01170
versus generating 0.741 (576% relative error), despite fit error 9.38 × 10⁻¹⁰.
The unidentifiable x₇ initial state remains fixed at 4 in original coordinates.
This is a compilation/caching validation, not successful parameter recovery for
that fixture. Earlier rational-model validation remains documented in the
[deferred-denominator record](2026-09-11_deferred_denominator_construction.md).

The full worker loaded the code before the final `LinearAlgebra.mul!`
qualification in the BFGS gradient branch. Its raw polishing used TrustRegion,
which does not enter that branch. Final-source package gates and a final-source
captured-root replay are recorded with the artifacts below.

## Reproduction and test evidence

Scripts, input capture, per-candidate results, full-run estimates, and timing
summaries are in
[`repro/biohydrogenation_compilation_2026_09_13`](../repro/biohydrogenation_compilation_2026_09_13/README.md).
The new full-suite contracts in [`test_robust_system.jl`](../test/test_robust_system.jl)
check parameter-dependent Jacobians, data changes, symbol order, cache identity,
both root branches, rectangular solves, the existing unprepared API, and kernel
reuse through both single-point estimator routes. Option validation adds four
assertions in `test_options_contracts.jl`.

Final Julia 1.13.0 validation passed **1,934/1,934** full-suite assertions in
15m03.8s and **10/10** recovery-benchmark assertions in 10m42.2s. The gates
overlapped in separate processes, and these times exclude package loading and
precompilation. Tests used `test/current.jl` and
`Pkg.test(...; allow_reresolve=false)`, preserving the current development
overrides and dependency versions. `validation.json` retains the final source
hashes, active-manifest hash, gate results, benchmark errors, and log hashes.
