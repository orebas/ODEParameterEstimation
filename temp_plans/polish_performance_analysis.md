# Polish Performance Analysis (2026-02-15)

## Biohydrogenation Benchmark Results

Ran with the PolishContext refactor on biohydrogenation model (4 states, 4 params, 4 observables).

### Phase Timing

| Phase | Iteration 1 | Iteration 2 |
|-------|-------------|-------------|
| Identifiability (SIAN) | ~60s | cached |
| Interpolation + DD | ~5s | ~5s |
| System building | <1s | <1s |
| HomotopyContinuation solve | ~20s | ~20s |
| Backsolve | <1s | <1s |
| **Polish (BFGS)** | **~190s** | **~190s** |
| Total | ~280s | ~220s |

Polish dominates runtime — ~70% of each iteration.

### Per-Solution Polish Details

Each iteration produces ~30 candidate solutions. Typical per-solution:
- **Iterations**: 5-6 BFGS iterations
- **Time**: ~6.3s per solution
- **Memory**: ~24 GiB allocated per solution (GC handles it)
- **Convergence**: All converge to error ~7.35e-9
- **Outliers**: Occasional solution takes ~25s (782s total across all in worst case), diverging before convergence

Many solutions converge to the SAME optimum — redundant work.

### Key Observation

Of ~30 algebraic solutions, most are duplicates or near-duplicates that all converge to the same polished result. Pre-polish clustering would eliminate redundant BFGS runs.

## AD Backend Gate Test Results

Tested 5 autodiff backends on a simple Lotka-Volterra ODE parameter estimation problem (2 states, 2 params). The objective function solves an ODE with `AutoVern9(Rodas4P())` and computes L2 loss against data.

### Results

| Backend | Status | Time | Notes |
|---------|--------|------|-------|
| **ForwardDiff** | **Works** | 0.185s | Only viable option for ODE polish |
| FiniteDiff | Works | 0.387s | 2.1x slower, less accurate (finite differences) |
| ReverseDiff | **FAILS** | - | `StackOverflowError` — cannot tape through adaptive ODE solver |
| Zygote | **FAILS** | - | `CompileError` in SymbolicUtils hashcons — Symbolics incompatible |
| Enzyme | **FAILS** | - | `RuntimeActivityError` — ODE solver too dynamic for static analysis |

### Why Only ForwardDiff Works

Adaptive ODE solvers (like `AutoVern9(Rodas4P())`) have **dynamic control flow**: variable step counts, adaptive order selection, stiffness detection with solver switching. This means:

- **ReverseDiff** tries to record the full computation graph (tape) — the recursive ODE stepper structure overflows the stack
- **Zygote** (source-to-source AD) can't compile through SymbolicUtils internals used by ModelingToolkit
- **Enzyme** (LLVM-level AD) needs static activity analysis — adaptive solvers are too dynamic
- **ForwardDiff** (dual numbers) just propagates through every operation transparently — no graph recording, no compilation, no activity analysis needed
- **FiniteDiff** works trivially (just evaluates the function) but is 2x slower and introduces finite-difference approximation error

**Conclusion**: ForwardDiff is the only AD backend for ODE-based polish. Don't waste time trying alternatives.

## Ranked Optimization Ideas

These are practical optimizations for the polish phase, ordered by expected impact:

### 1. Pre-polish clustering (~3.3x speedup) — HIGH PRIORITY

Cluster the ~30 algebraic solutions BEFORE running BFGS polish. Most are near-duplicates that converge to the same optimum.

- **Expected**: 30 solutions -> ~10 clusters -> 10 BFGS runs instead of 30
- **Gotcha**: Unidentifiable parameters (e.g. theta) must be excluded from distance metric
- **Where**: `parameter_estimation_helpers.jl:685` and `optimized_multishot_estimation.jl:1682`
- See `pre_polish_clustering.md` for full implementation plan

### 2. Skip hopeless candidates

Some algebraic solutions have initial errors orders of magnitude worse than the best. Skip solutions where initial objective is >100x worse than the current best.

### 3. Early termination on divergence

If BFGS objective increases for 2+ consecutive iterations, abort that solution. This would catch the 782s outlier case.

### 4. Drop Fminbox for unconstrained L-BFGS

Currently using `Fminbox(LBFGS())` with box constraints. If parameter bounds aren't critical, plain `LBFGS()` avoids the projection overhead.

### 5. Reduce ODE tolerance during polish

Current: `abstol=1e-13, reltol=1e-13`. During early BFGS iterations (when we're far from optimum), `1e-10` would be sufficient and cheaper. Could use a two-phase approach: coarse tolerance first, fine tolerance for final iterations.

### 6. Parallel polish (future)

Each solution's BFGS is independent — natural candidate for `Threads.@threads`. Currently single-threaded. Blocked by thread-safety of ODE solver allocations.

## Instructions for Future Reference

- **Don't try alternative AD backends** — ForwardDiff is the only one that works through adaptive ODE solvers (tested 2026-02-15)
- **Pre-polish clustering is the highest-impact optimization** — implement it before trying anything else
- **Profile before optimizing** — use `temp_plans/profile_biohydrogenation.jl` as a template
- **Memory allocations are dominated by ODE solves** — 24 GiB per solution is mostly GC-collected temporaries, not a memory leak
