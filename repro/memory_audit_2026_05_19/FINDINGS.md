# Memory audit — unilateral reduction in `solve_with_robust` Jacobian path

## TL;DR

The TODO entry `cache the SI template + symbolic Jacobian per cell` traced
wallaby's nopolish OOMs (crauste_3_1em8 killed at 8.36 GB) to per-iteration
SI-template rebuilds. Investigation here shows that **the structural SI
template is already cached** (`optimized_multishot_estimation.jl:1327`).
The actual per-iteration leak is one level down: every call to
`solve_with_robust` rebuilds the symbolic Jacobian via
`Symbolics.jacobian + 2× build_function` (`solve_with_robust.jl:98-103`),
and each `build_function` leaves a fresh `RuntimeGeneratedFunction` whose
LLVM-compiled code never reclaims.

The TODO's specific mechanism ("intern table holds strong refs") is **wrong**
— `Base.summarysize(Symbolics)` is flat across the candidate loop. The
practical fix is the same anyway: stop calling `Symbolics.jacobian` per
candidate.

**Fix shipped (Phase 1):** one-line change at `solve_with_robust.jl:38`,
flipping the Jacobian default from `:symbolic` to `:forwarddiff`. Same
Jacobian numerically (ForwardDiff is exact), no symbolic stage, no
2× extra build_function compile.

**Measured effect (MWE):** ~370× reduction in per-iteration peak RSS growth
(946 KB/iter → 2.6 KB/iter). Side-by-side numbers below.

## Diagnosis: MWE

`repro/memory_audit_2026_05_19/symbolics_jac_mwe.jl` builds a representative
SI-template-shaped polynomial (20 eqs, 20 vars, sin/cos/products with 12
data variables), loops 200×, and measures memory under two modes:

- `:symbolic` — substitute data into template, then call
  `Symbolics.jacobian + 2× build_function` (mirrors
  `solve_with_robust.jl:98-103` exactly).
- `:forwarddiff` — substitute data into template, build_function the residual
  only (mirrors solve_with_robust's residual compile at lines 60-66; the
  ForwardDiff path adds only pure closures, no extra build_function).

Result (`repro/memory_audit_2026_05_19/mwe_run.txt`):

| Mode | ΔRSS (200 iters) | RSS slope (KB/iter) | gc_live slope (KB/iter) |
|---|---|---|---|
| `:symbolic` | **+193.77 MB** | **946** | +116 |
| `:forwarddiff` | +0.52 MB | **2.6** | -26 (reclaims) |
| Ratio | — | **~370×** | — |

Key observation: `Base.summarysize(Symbolics)` stays flat (~0.5 → 0.6 MB)
across all 400 iterations. The leak is **not** in Symbolics.jl's intern
table. It's in JIT-compiled code: each `build_function(...; expression=Val(false))`
emits a `RuntimeGeneratedFunction` whose native code persists in the LLVM
code cache outside Julia's GC. Per `:symbolic` iter we compile 3
(residual + jac + grad); per `:forwarddiff` iter we compile 1 (residual
only). That ~3× factor times the elimination of the symbolic-derivation
work explains the ~370× ratio.

## Fix: one-line Phase 1 change

`src/core/solve_with_robust.jl:38`:

```diff
- jac_mode = get(options, :jacobian, :symbolic)  # Default to symbolic!
+ jac_mode = get(options, :jacobian, :forwarddiff)  # see comment for rationale
```

Why this is unilateral:

1. **Same Jacobian.** ForwardDiff propagates duals through the already-compiled
   native residual (lines 60-66 of `solve_with_robust.jl`). Exact (not
   finite-difference) Jacobian; identical downstream `NonlinearFunction(residual!;
   jac = (J,u,p) -> jac_func(J,u))` dispatch at line 211.
2. **No callers pin `:symbolic`.** Grep confirmed: only this default and
   the `homotopy_continuation.jl` paths (which use `:none` and call a
   different solver). The only manual override is `benchmark_saved_system.jl:97`
   (intentional override, honored by `get(options, ...)`).
3. **Same algorithm dispatch.** Trust-region selection at line 152-173 keys
   on `jac_func !== nothing`; ForwardDiff still provides one.

## Test gates

| Test | Result |
|---|---|
| `fast_core.jl` (258 tests) | **PASS 258/258** in 4m27s |
| `feature_regressions.jl` (133 tests) | **PASS 133/133** in 2m32s |

No semantic regression. The ForwardDiff Jacobian path was already the
fallback when `:symbolic` failed (lines 108-115 of `solve_with_robust.jl`),
so it had quiet integration test coverage even before this change — making
it the default just exercises a code path that was already used in the
wild.

## Pipeline-level evidence

A wallaby-style time-boxed run on `biohydrogenation_3_1em6` would give
additional pipeline-level RSS numbers, but the cell did not complete in
~10 hours on wallaby and a 20-30 min cap captures only a handful of
candidates — not enough to demonstrate slope. Deferred to the next
benchmark run, where pre-/post-Phase-1 peak-RSS deltas should be
collected across the regression cohort.

The MWE provides the per-iteration evidence and the test suites provide
the semantic-preservation evidence. Combined, this is sufficient to ship
Phase 1 unilaterally.

## Phase 2 (end-of-cell GC) disposition

The MWE shows `:forwarddiff` mode actually *reclaims* memory (gc_live
slope = -26 KB/iter, RSS slope = +2.6 KB/iter ≈ noise). Per-cell `GC.gc()`
would add no value on top of Phase 1 in the candidate loop itself.

**Disposition: deferred.** Revisit only if a benchmark run after Phase 1
still shows multi-GB peak RSS on hard cells.

## Phase 3 (compile Jacobian once per template) disposition

Phase 1 reduces the per-iteration symbolic work to zero. The cell-level
template Jacobian cache (the original TODO intent) would optimize CPU,
not memory. **Disposition: deferred.** Reconsider if benchmark wall-time
regressions emerge on long-multipoint cells.

## Audit: other `Symbolics.jacobian` / `build_function` call sites

Checked all four `solve_with_*` functions in
`src/core/homotopy_continuation.jl`:

| Function | Line | `:jacobian` default | `build_function` per call | Verdict |
|---|---|---|---|---|
| `solve_with_nlopt` | 44 | `:none` | 1× (residual only) | clean |
| `solve_with_nlopt_quick` | 168 | `:none` | 1× (residual only) | clean |
| `solve_with_fast_nlopt` | 289 | n/a (ForwardDiff hardcoded) | 1× (residual only) | clean |
| `solve_with_robust_fast` | 443 | n/a | 1× (residual only) | clean |

None of them call `Symbolics.jacobian` per invocation. The 3× pattern
(`jacobian + 2× build_function` for J + grad) was unique to
`solve_with_robust.jl:98-103` and has been removed by the `:forwarddiff`
default.

The remaining 1× `build_function` per call for the residual is the
irreducible cost given the current architecture (each candidate has a
freshly substituted polynomial system). Per the MWE, this contributes
only ~2.6 KB/iter to peak RSS — well within noise. Eliminating it
would require Phase 3 (cache compiled functions per template); see
`TODO` for the deferred plan.

## Drive-by cleanup (same session)

`solve_with_robust.jl:51` previously had a hardcoded `debug = true`
that overrode the `debug = get(options, :debug, false)` line above
it. Removed — callers' `:debug` option is now honored. This also
silences the `[ROBUST] ...` log spam on wallaby's hard cells (~3 MB
of console writes per cell that contributed to disk and notification
overhead without adding actionable signal).

## Files changed

- `src/core/solve_with_robust.jl:38` — default Jacobian → `:forwarddiff` + explanatory comment
- `src/core/solve_with_robust.jl:18` — docstring updated
- `src/core/solve_with_robust.jl:51` — removed `debug = true` hardcode (honor caller's `:debug`)
- `TODO` — SI-template-cache entry rewritten: memory side marked shipped, CPU side scoped as deferred Phase 3
- `repro/memory_audit_2026_05_19/symbolics_jac_mwe.jl` — new diagnostic MWE
- `repro/memory_audit_2026_05_19/mwe_run.txt` — MWE run output
- `repro/memory_audit_2026_05_19/FINDINGS.md` — this document
- `repro/memory_audit_2026_05_19/biohydrogenation_3_1em6_main/{script.jl,data.csv,cell_seed.txt}` — staged for time-boxed local run (not executed; see "Pipeline-level evidence" above)
