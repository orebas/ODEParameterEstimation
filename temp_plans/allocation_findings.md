# Allocation Profiling Findings — ODEParameterEstimation

## Overview

This document records all profiling results collected so far, the settings used,
key architectural findings, and recommendations for further investigation.

**Date:** 2026-02-05
**Commit:** `43d251b` (Code quality: type-stabilize structs, remove dead code, fix silent catches)

---

## 1. Profiling Infrastructure

### Built-in Phase Profiling

The package includes a `profile_phases` option in `EstimationOptions` that wraps each
major phase of `optimized_multishot_parameter_estimation` with `@timed`:

```julia
opts = EstimationOptions(profile_phases = true, ...)
```

This uses the `_record_phase!` helper (optimized_multishot_estimation.jl:25-33) which
has **zero overhead** when `stats=nothing` (the default). Phases recorded:
1. Setup (identifiability + interpolants)
2. SI Template (SIAN analysis)
3. Equation construction + Solving
4. Result processing

### Standalone Profiling Scripts

| Script | Purpose |
|--------|---------|
| `src/examples/profiling/profile_allocations.jl` | PProf-based allocation flamegraph (requires PProf.jl in global env) |
| `src/examples/profiling/track_allocations.sh` | Julia `--track-allocation=user` per-line `.jl.mem` files |
| `temp_plans/profile_biohydrogenation.jl` | **NEW**: Granular sub-phase profiling with production settings |

---

## 2. Phase-Level Profiling Results

### Settings Used

The results below were collected with **non-production settings** (smaller datasize,
different interpolator) which makes them useful for structural insight but NOT
representative of production allocation costs:

```julia
# Settings used for phase-level profiling
opts = EstimationOptions(
    datasize = 201,               # Production uses 2001
    interpolator = InterpolatorAAADGPR,  # Production uses InterpolatorAGPRobust
    system_solver = SolverHC,
    shooting_points = 1,          # Production uses 8
    profile_phases = true,
    # try_more_methods = true (default — causes double pipeline)
)
```

**Key difference from production:** `datasize=201` vs `2001` means GP kernel matrices
are 201×201 instead of 2001×2001 — a 100× reduction in GP memory. The
`InterpolatorAGPRobust` used in production is also heavier than `InterpolatorAAADGPR`.

### Simple Model (Warmup/Compilation Run Only)

*1 state, 2 parameters, 1 observable — the simplest model*

| Phase | Time (s) | Allocs | GC % |
|-------|----------|--------|------|
| Setup (identifiability + interpolants) | 3.42 | 12.3 MiB | 4.1% |
| SI Template (SIAN analysis) | 8.71 | 156.2 MiB | 12.3% |
| Eq construction + Solving | 14.23 | 891.4 MiB | 18.7% |
| Result processing | 2.11 | 45.3 MiB | 3.4% |
| **TOTAL** | **28.47** | **1.1 GiB** | **11.2%** |

*Note: This was a first-run result including JIT compilation. A subsequent run with
`profile_phases=true` showed only 25.9 MiB total (see next section).*

### Simple Model (Steady-State, Second Run)

| Phase | Time (s) | Allocs | GC % |
|-------|----------|--------|------|
| Setup | 0.00 | 1.5 MiB | 0.0% |
| SI Template | 0.03 | 16.8 MiB | 0.0% |
| Eq construction + Solving | 0.01 | 3.8 MiB | 0.0% |
| Result processing | 0.01 | 3.9 MiB | 0.0% |
| **TOTAL** | **0.05** | **25.9 MiB** | **0.0%** |

### Medium-Complexity Models (datasize=201, InterpolatorAAADGPR)

Each model was run **twice** in the same Julia session (Run 1 = JIT, Run 2 = steady-state).
The `try_more_methods=true` default means the pipeline runs twice per "run" (once with
the user's interpolator, once with `InterpolatorAAAD`). Both passes are included in the
totals below.

#### Brusselator (2 states, 4 parameters)

| Phase | Run 1 Time | Run 1 Allocs | Run 2 Time | Run 2 Allocs |
|-------|-----------|-------------|-----------|-------------|
| Setup | 5.42s | 821 MiB | 3.18s | 505 MiB |
| SI Template | 33.10s | 5.18 GiB | 0.03s | 18 MiB |
| Eq+Solving | 34.69s | 7.22 GiB | 0.29s | 42 MiB |
| Result processing | 11.27s | 5.03 GiB | 0.00s | 76 KiB |
| **TOTAL** | **84.49s** | **18.23 GiB** | **3.51s** | **564 MiB** |

#### Biohydrogenation (4 states, 6 parameters, 2 observables)

| Phase | Run 1 Time | Run 1 Allocs | Run 2 Time | Run 2 Allocs |
|-------|-----------|-------------|-----------|-------------|
| Setup | 19.71s | 4.90 GiB | 14.08s | 3.90 GiB |
| SI Template | 3.89s | 786 MiB | 0.45s | 193 MiB |
| Eq+Solving | 43.44s | 7.39 GiB | 1.04s | 124 MiB |
| Result processing | 0.00s | 212 KiB | 0.00s | 119 KiB |
| **TOTAL** | **67.04s** | **13.06 GiB** | **15.56s** | **4.21 GiB** |

#### DAISY MAMIL3 (3 states, 5 parameters)

| Phase | Run 1 Time | Run 1 Allocs | Run 2 Time | Run 2 Allocs |
|-------|-----------|-------------|-----------|-------------|
| Setup | 0.67s | 105 MiB | 0.01s | 3 MiB |
| SI Template | 0.29s | 73 MiB | 0.10s | 46 MiB |
| Eq+Solving | 4.38s | 1.44 GiB | 0.16s | 24 MiB |
| Result processing | 10.53s | 4.96 GiB | 0.01s | 4 MiB |
| **TOTAL** | **15.87s** | **6.57 GiB** | **0.28s** | **77 MiB** |

#### FitzHugh-Nagumo (2 states, 3 parameters)

| Phase | Run 1 Time | Run 1 Allocs | Run 2 Time | Run 2 Allocs |
|-------|-----------|-------------|-----------|-------------|
| Setup | 0.75s | 133 MiB | 0.01s | 6 MiB |
| SI Template | 0.56s | 76 MiB | 0.04s | 19 MiB |
| Eq+Solving | 4.51s | 1.28 GiB | 0.15s | 28 MiB |
| Result processing | 9.81s | 4.96 GiB | 0.02s | 6 MiB |
| **TOTAL** | **15.64s** | **6.45 GiB** | **0.21s** | **59 MiB** |

#### SEIR (4 states, 3 parameters — 26 equations)

| Phase | Run 1 Time | Run 1 Allocs | Run 2 Time | Run 2 Allocs |
|-------|-----------|-------------|-----------|-------------|
| Setup | 1.20s | 226 MiB | 0.29s | 78 MiB |
| SI Template | 0.23s | 68 MiB | 0.12s | 51 MiB |
| Eq+Solving | 6.85s | 2.36 GiB | 0.35s | 32 MiB |
| Result processing | 0.00s | 93 KiB | 0.00s | 93 KiB |
| **TOTAL** | **8.28s** | **2.65 GiB** | **0.76s** | **161 MiB** |

*Note: SEIR found 0 solutions — the HC solver may struggle with 26×26 systems.*

### Steady-State Summary (Run 2 — What Matters for Production)

| Model | Total Time | Total Allocs | Dominant Phase |
|-------|-----------|-------------|---------------|
| simple | 0.05s | 25.9 MiB | SI Template (16.8 MiB) |
| brusselator | 3.51s | 564 MiB | Setup (505 MiB) |
| **biohydrogenation** | **15.56s** | **4.21 GiB** | **Setup (3.90 GiB = 93%)** |
| daisy_mamil3 | 0.28s | 77 MiB | SI Template (46 MiB) |
| fitzhugh_nagumo | 0.21s | 59 MiB | Eq+Solving (28 MiB) |
| seir | 0.76s | 161 MiB | Setup (78 MiB) |

---

## 3. Key Architectural Findings

### Finding 1: The Pipeline Runs Twice (Double Cost)

`analyze_parameter_estimation_problem` (analysis_utils.jl:343-457) runs the **entire**
`optimized_multishot_parameter_estimation` **twice** when `opts.try_more_methods=true`
(the default):

1. First pass with the user's interpolator (e.g., `InterpolatorAGPRobust`)
2. Second pass with `InterpolatorAAAD` as a fallback

**Impact:** Every allocation cost is **doubled**. The two profiling tables we observed
per model correspond to these two passes.

**Location:**
```
analysis_utils.jl:390-409  (the try_more_methods block)
```

**Recommendation:** If the first pass succeeds (finds solutions with acceptable error),
skip the second pass entirely. This could halve total allocation for many models.

### Finding 2: Setup Dominates for Biohydrogenation (93%)

For the biohydrogenation model at steady-state, **Setup** accounts for 3.90 GiB out of
4.21 GiB total (93%). This phase contains:

1. **`create_interpolants`** — GP kernel matrix construction
   - With `InterpolatorAGPRobust` and `datasize=2001`: builds 2001×2001 kernel matrices
   - O(n²) memory for kernel, O(n³) compute for Cholesky
   - Each observable gets its own GP, so 2 observables × 2001×2001 = ~61 MiB just for kernel storage
   - But the actual cost is higher due to Cholesky factorization intermediates

2. **`determine_optimal_points_count`** — iterative identifiability analysis
   - Calls `multipoint_local_identifiability_analysis` multiple times
   - Each call runs `populate_derivatives` (symbolic derivative chain) and
     `multipoint_numerical_jacobian` (numerical Jacobian at random points)

The profiling script `temp_plans/profile_biohydrogenation.jl` will break these apart.

### Finding 3: JIT Compilation Dominates First-Run Costs

First-run allocations are 3-30× higher than steady-state:
- `fitzhugh_nagumo`: 6.45 GiB → 59 MiB (109× reduction)
- `brusselator`: 18.23 GiB → 564 MiB (32× reduction)
- `biohydrogenation`: 13.06 GiB → 4.21 GiB (only 3× — real work dominates)

The fact that biohydrogenation shows only 3× reduction confirms that its allocations
are dominated by **real computational work** (GP construction, identifiability analysis),
not JIT compilation.

### Finding 4: Result Processing is Mostly JIT

Result processing drops from ~5 GiB to near-zero on second run for most models. This
phase includes ODE backward integration for solution validation, which triggers
compilation of `ODEProblem` + `solve` for the specific model on first use.

For biohydrogenation, result processing is negligible (119 KiB) because **no solutions
were found** in the test run. The Eq+Solving phase returned empty results.

### Finding 5: Production Settings Will Amplify Setup Costs

The profiling above used `datasize=201`. Production uses `datasize=2001`:

| Component | datasize=201 | datasize=2001 | Scaling |
|-----------|-------------|--------------|---------|
| GP kernel matrix | 201×201 = 40K entries | 2001×2001 = 4M entries | **100×** |
| GP Cholesky | O(201³) ≈ 8M flops | O(2001³) ≈ 8B flops | **1000×** |
| Interpolation queries | Fast (small model) | Same (pointwise) | 1× |

Additionally, `InterpolatorAGPRobust` (production) is heavier than `InterpolatorAAADGPR`
(used in profiling) because it:
- Uses a squared exponential kernel with length-scale optimization
- Includes a robust fallback mechanism for smooth/noiseless data
- May run multiple GP fits with different hyperparameters

---

## 4. Pipeline Call Chain

```
analyze_parameter_estimation_problem(PEP, opts)        [analysis_utils.jl:343]
├── optimized_multishot_parameter_estimation(PEP, opts)  [optimized_multishot_estimation.jl:976]
│   │
│   ├── Phase 1: setup_parameter_estimation(PEP, ...)   [parameter_estimation_helpers.jl:27]
│   │   ├── unpack_ODE(model)
│   │   ├── create_interpolants(mq, data, t, interp_fn)  [parameter_estimation.jl:128]
│   │   ├── determine_optimal_points_count(...)           [parameter_estimation.jl:152]
│   │   │   └── multipoint_local_identifiability_analysis (×N)  [parameter_estimation.jl:961]
│   │   │       ├── populate_derivatives(model, mq, max_level, udict)
│   │   │       ├── multipoint_numerical_jacobian(...)
│   │   │       └── nullspace analysis (LinearAlgebra)
│   │   └── pick_points(t_vector, n_points, interpolants, hint)
│   │
│   ├── Phase 2: SI Template
│   │   ├── get_si_equation_system(model, mq, data; DD, ...)  [si_equation_builder.jl:277]
│   │   │   ├── convert_to_si_ode() → ODE for SI.jl
│   │   │   ├── SIAN.get_equations() + rank-based construction
│   │   │   └── nemo_to_symbolics conversion
│   │   └── Iterative fix loop (DOF analysis)
│   │       ├── count equations vs unknowns (obs_data_vars from DD.obs_lhs)
│   │       ├── select_one_parameter_to_fix() [Jacobian-based DOF]
│   │       └── re-run get_si_equation_system with fixed params
│   │
│   ├── Phase 3: Equation Construction + Solving (per shooting point)
│   │   ├── construct_equation_system_from_si_template(...)  [si_template_integration.jl:23]
│   │   ├── system_solver(equations, varlist)  [homotopy_continuation.jl:656]
│   │   └── solve_with_robust(..., polish_only=true)  [solve_with_robust.jl]
│   │
│   └── Phase 4: Result Processing
│       ├── process_estimation_results(PEP, sol_data, setup_data)  [parameter_estimation_helpers.jl:446]
│       │   ├── lookup_value() for each param/state
│       │   ├── ODEProblem construction
│       │   └── ODE backward integration (shooting → t=0)
│       └── analyze_estimation_result(PEP, solved_res)
│
├── [if try_more_methods=true]
│   └── optimized_multishot_parameter_estimation(PEP, opts_aaad)  ← SECOND FULL RUN
│       └── (same pipeline with InterpolatorAAAD)
│
└── analyze_estimation_result(PEP, merged_solutions)
```

---

## 5. How to Replicate

### Phase-Level Profiling (Quick)

```julia
# In Julia REPL (global environment):
include(joinpath(homedir(), ".julia", "dev", "ODEParameterEstimation", "src", "examples", "load_examples.jl"))
using SciMLBase, NonlinearSolve, LeastSquaresOptim

pep = biohydrogenation()
opts = EstimationOptions(
    datasize = 201,
    system_solver = SolverHC,
    interpolator = InterpolatorAAADGPR,
    shooting_points = 1,
    profile_phases = true,
    nooutput = false,
)
sampled = sample_problem_data(pep, opts)

# Warmup
analyze_parameter_estimation_problem(sampled, opts)
# Measured
@time analyze_parameter_estimation_problem(sampled, opts)
```

### Sub-Phase Profiling (Granular)

```bash
# From project root:
julia temp_plans/profile_biohydrogenation.jl
```

This uses **production settings** (datasize=2001, InterpolatorAGPRobust) and breaks each
phase into sub-functions with individual `@timed` measurements.

### Allocation Flamegraph (Deep)

```bash
# Requires PProf.jl in global env: julia -e 'using Pkg; Pkg.add("PProf")'
julia src/examples/profiling/profile_allocations.jl
```

### Per-Line Allocation Tracking

```bash
bash src/examples/profiling/track_allocations.sh biohydrogenation
```

---

## 6. Recommendations for Further Investigation

### Answered by profile_biohydrogenation.jl (2026-02-05):

1. **What fraction of Setup is GP construction vs identifiability analysis?**
   - **ANSWERED:** `create_interpolants` = 188.36 GiB (93.3% of total).
     `determine_optimal_points_count` = 3.57 GiB (1.8%).
     **GP construction is 53× larger than identifiability analysis.**

2. **What's the cost of each shooting point?**
   - **ANSWERED:** 8 shooting points total ~4.41 GiB (2.2% of total).
     HC.solve = 451.5 MiB (56 MiB/point), polish = 3.90 GiB (488 MiB/point).
     Polishing (solve_with_robust) costs 8.6× more than HC solving per point.
     Equation construction is negligible (8 MiB/point).

3. **Does the iterative fix loop re-run SIAN?**
   - **ANSWERED:** For biohydrogenation, the system converged in iteration 1
     (25 equations, 25 unknowns). No parameter fixing was needed. The iterative
     fix loop cost only 7.6 MiB.

### Medium-Term Optimizations:

4. **Fix GP interpolation (THE critical path — 93.3% of all allocations)**
   - `create_interpolants` with `InterpolatorAGPRobust` at datasize=2001 allocates
     **188.36 GiB** and takes 92 seconds. This is the single dominant bottleneck.
   - The "robust" GP variant likely runs multiple hyperparameter optimization
     iterations, each rebuilding kernel matrices.
   - Even a 10× reduction here would save more than eliminating all other phases combined.

5. **Cache GP interpolants across pipeline passes**
   - When `try_more_methods=true`, the GP interpolants from pass 1 could be
     reused in pass 2 (only the AAAD interpolants change)
   - Estimated savings: 188 GiB for biohydrogenation (the GP is the same data)

6. **Early termination for try_more_methods**
   - If pass 1 finds solutions with error < threshold, skip pass 2
   - Would halve allocation for successful models (~202 GiB saved)

7. **Reduce solution polishing cost**
   - `solve_with_robust` polishing costs 3.90 GiB across 8 points
   - Each polish rebuilds a symbolic Jacobian — could be cached across points

8. **Precompile ODE backward integration**
   - Result processing allocates 5.40 GiB (mostly ODE re-simulation for 20 solutions)
   - A `PrecompileTools.jl` workload could reduce first-run cost

### Long-Term:

9. **Replace GP interpolation with something O(n)**
   - Cubic splines are O(n) construction vs O(n²) for GP
   - For smooth, noiseless data (which is the common case), splines
     may be equally accurate with dramatically less memory
   - Moving from GP to splines would reduce 188 GiB to ~MiB scale

10. **Sparse kernel approximation**
    - If GP interpolation is needed for uncertainty, use inducing points
    - Reduces O(n²) to O(nm) where m << n

---

## 7. Production-Settings Results (NEW — 2026-02-05)

### Biohydrogenation with Production Settings

**Settings:** `datasize=2001, InterpolatorAGPRobust, SolverHC, 8 shooting points,
try_more_methods=false` (single pipeline pass).

| Phase / Sub-phase | Time (s) | Allocs | % of Total |
|-------------------|----------|--------|------------|
| **1. Setup** | **105.65** | **191.93 GiB** | **95.0%** |
|    1a. create_interpolants | 92.49 | **188.36 GiB** | **93.3%** |
|    1b. determine_optimal_points_count | 13.16 | 3.57 GiB | 1.8% |
|    1c. pick_points | 0.00 | 592 B | 0.0% |
| **2. SI Template** | **0.52** | **205.1 MiB** | **0.1%** |
|    2a. get_si_equation_system (initial) | 0.42 | 197.5 MiB | 0.1% |
|    2b. iterative_fix_loop | 0.11 | 7.6 MiB | 0.0% |
| **3. Equation construction + Solving** | **21.36** | **4.41 GiB** | **2.2%** |
|    3a. construct_equation_system (×8) | 0.08 | 63.3 MiB | 0.0% |
|    3b. system_solver / HC.solve (×8) | 5.27 | 451.5 MiB | 0.2% |
|    3c. polish / solve_with_robust (×8) | 16.01 | 3.90 GiB | 1.9% |
| **4. Result processing** | **14.52** | **5.45 GiB** | **2.7%** |
|    4a. process_estimation_results (ODE solve) | 14.05 | 5.40 GiB | 2.7% |
|    4b. analyze_estimation_result (scoring) | 0.47 | 55.6 MiB | 0.0% |
| **TOTAL** | **142.05** | **201.98 GiB** | **100%** |

### Additional Context
- Solutions found: 20 (across 8 shooting points, ~2-3 per point)
- `sample_problem_data` (ODE solve for synthetic data): 45.88s, 13.19 GiB (separate from pipeline)
- With `try_more_methods=true` (default), estimated total: ~404 GiB

---

## 8. Key Numbers to Remember

| Metric | Value | Context |
|--------|-------|---------|
| **create_interpolants (production)** | **188.36 GiB, 92.5s** | **THE bottleneck (93.3%)** |
| Biohydrogenation total (production) | 201.98 GiB, 142s | datasize=2001, InterpolatorAGPRobust |
| Biohydrogenation total (small) | 4.21 GiB | datasize=201, InterpolatorAAADGPR |
| GP scaling: 201→2001 | 4.21→202 GiB (**48×**) | Worse than theoretical 100× due to hyperopt |
| Double pipeline overhead | 2× total | try_more_methods=true (default) |
| HC.solve per point | 56 MiB, 0.66s | Very efficient |
| Polish per point | 488 MiB, 2.0s | 8.6× more than HC |
| ODE backward integration | 5.40 GiB | For 20 solutions validation |
| JIT compilation overhead | 3-109× first run | Model-dependent |
| Simple model steady-state | 25.9 MiB | Baseline for "zero work" |
