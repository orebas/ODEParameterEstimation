# Feature: Shooting Point Transparency and Control
## Date: 2026-02-17

**Requested by**: Alexander Demin (Sasha)
**Context**: Sasha observed that ODEPE solves polynomial systems at multiple time points
and assembles the final answer from these. He wants to:
1. Know which time points contributed to each result
2. Force the use of a particular time point

---

## 1. CURRENT STATE (How It Works Today)

### 1.1 Shooting Point Selection

**FlowStandard** (`optimized_multishot_parameter_estimation` in
`src/core/optimized_multishot_estimation.jl`, lines 1172-1189):
- Default: `shooting_points=8` → 8 evenly spaced indices via
  `range(1, length(t_vector), length=n_points)`
- Special case: `shooting_points=0` → single midpoint at index 0.499*len

**FlowDeprecated** (`multishot_parameter_estimation` in
`src/core/multipoint_estimation.jl`, lines 114-119):
- Iterates `i in 1:(shooting_points+1)` with `point_hint = i/(shooting_points+1)`
- Each hint is passed to `pick_points()` in `pointpicker.jl` which converts to an index

### 1.2 Result Assembly

Solutions from all shooting points are concatenated into a flat list:
```julia
append!(all_solutions, solutions)              # line 1376/1481
push!(solution_time_indices, point_idx)         # line 1378/1484 (FlowStandard only)
```

Then `analyze_estimation_result()` in `analysis_utils.jl`:
1. Filters by error threshold (0.5)
2. Sorts by error
3. Clusters by `solution_distance()` (threshold 1e-5)
4. Returns best solution from each cluster

### 1.3 What's Tracked vs. What's Lost

**Tracked internally (FlowStandard only)**:
- `solution_time_indices::Vector{Int}` — maps each raw solution to its shooting point
  index in `t_vector`. Stored in `solution_data` NamedTuple (line 1518).
- Used in `process_estimation_results` (line 523 of `parameter_estimation_helpers.jl`)
  to compute `shoot_idx` → `t_shoot` for backsolving ICs.

**Lost in the final output**:
- `ParameterEstimationResult.at_time` is set to `t_vector[lowest_time_index]` (the
  *earliest* time in the data), NOT the shooting time.
- `ParameterEstimationResult.report_time` is also set to `t_vector[lowest_time_index]`.
- After clustering, there's no indication of which shooting point(s) contributed
  to each cluster.
- FlowDeprecated path: `solution_time_indices` doesn't exist at all.

**User-facing control**:
- `EstimationOptions.point_hint::Float64` — normalized [0,1] hint for time selection
- `EstimationOptions.shooting_points::Int` — number of shooting points (default: 8)
- No way to specify exact time values or exact indices

---

## 2. PROPOSED CHANGES

### 2.1 Feature A: Report Shooting Point Origin Per Solution

**Goal**: Each `ParameterEstimationResult` should report the time point at which the
polynomial system was solved to produce that solution.

**Change 1 — Add field to `ParameterEstimationResult`** (`src/types/core_types.jl:84-95`):
```julia
mutable struct ParameterEstimationResult
    parameters::OrderedDict{Num, Float64}
    states::OrderedDict{Num, Float64}
    at_time::Float64
    err::Union{Nothing, Float64}
    return_code::Union{Nothing, Symbol}
    datasize::Int64
    report_time::Union{Nothing, Float64}
    unident_dict::Union{Nothing, OrderedDict{Num, Float64}}
    all_unidentifiable::Set{Num}
    solution::Union{Nothing, SciMLBase.AbstractODESolution}
    shooting_time::Union{Nothing, Float64}        # NEW: time point where poly system was solved
    shooting_point_index::Union{Nothing, Int}      # NEW: index into t_vector
end
```

The new fields default to `nothing` for backward compatibility.

**Change 2 — Populate during result processing** (`src/core/parameter_estimation_helpers.jl`):
In the section around line 523 where `shoot_idx` is already computed:
```julia
shoot_idx = hasfield(typeof(solution_data), :solution_time_indices) && ...
t_shoot = t_vector[shoot_idx]
```
Store `t_shoot` and `shoot_idx` into the `ParameterEstimationResult` being constructed.

**Change 3 — Display in analysis output** (`src/core/analysis_utils.jl`):
When printing cluster results, also print which shooting points contributed:
```
Cluster 1: 5 similar solutions
  Contributing shooting times: t=0.125, t=0.375, t=0.625 (3 of 8 points)
  Best solution (Error: 0.000123):
  ...
```

**Change 4 — Aggregate per-cluster provenance**:
After clustering, for each cluster, collect the set of `shooting_time` values from
all solutions in that cluster. This shows which time points converged to the same answer.

### 2.2 Feature B: Force Specific Time Points

**Goal**: User can specify exact time values (or indices) for shooting.

**Change 5 — Add option to `EstimationOptions`** (`src/types/estimation_options.jl`):
```julia
# In the "Multi-point and Multi-shot Parameters" section:
forced_shooting_times::Union{Nothing, Vector{Float64}} = nothing
forced_shooting_indices::Union{Nothing, Vector{Int}} = nothing
```

**Change 6 — Use forced times in FlowStandard**
(`src/core/optimized_multishot_estimation.jl`, lines 1172-1189):
```julia
if !isnothing(opts.forced_shooting_indices)
    point_indices = opts.forced_shooting_indices
    n_points = length(point_indices)
elseif !isnothing(opts.forced_shooting_times)
    # Find nearest index for each requested time
    point_indices = [argmin(abs.(t_vector .- t)) for t in opts.forced_shooting_times]
    n_points = length(point_indices)
elseif opts.shooting_points == 0
    ...  # existing logic
```

**Change 7 — Use forced times in FlowDeprecated**
(`src/core/multipoint_estimation.jl`, lines 113-120):
Similar override: if `forced_shooting_times` is set, compute point_hints from them
instead of using the evenly-spaced loop.

**Change 8 — Validate in `validate_options()`** (`src/types/estimation_options.jl`):
- Warn if both `forced_shooting_times` and `forced_shooting_indices` are set
- Warn if `forced_shooting_indices` has out-of-range values

---

## 3. USAGE EXAMPLES (After Implementation)

### 3a. See which time points contributed
```julia
opts = EstimationOptions(shooting_points = 8)
meta, results, uq = analyze_parameter_estimation_problem(pep, opts)

# results[1] is a tuple: (best_solutions_from_clusters, besterror, ...)
for (i, sol) in enumerate(results[1])
    println("Cluster $i:")
    println("  Shooting time: t = $(sol.shooting_time)")
    println("  Error: $(sol.err)")
    println("  Parameters: $(sol.parameters)")
end
```

### 3b. Force a specific time point
```julia
opts = EstimationOptions(
    forced_shooting_times = [0.5],   # solve only at t=0.5
    shooting_points = 1,
)
meta, results, uq = analyze_parameter_estimation_problem(pep, opts)
```

### 3c. Force multiple specific time points
```julia
opts = EstimationOptions(
    forced_shooting_times = [0.0, 0.25, 0.5, 0.75, 1.0],
)
meta, results, uq = analyze_parameter_estimation_problem(pep, opts)
```

---

## 4. FILES TO MODIFY

| File | Change |
|------|--------|
| `src/types/core_types.jl` | Add `shooting_time` and `shooting_point_index` fields to `ParameterEstimationResult` |
| `src/types/estimation_options.jl` | Add `forced_shooting_times` and `forced_shooting_indices` to `EstimationOptions`; update `validate_options` |
| `src/core/parameter_estimation_helpers.jl` | Populate `shooting_time`/`shooting_point_index` in result construction |
| `src/core/optimized_multishot_estimation.jl` | Honor `forced_shooting_times`/`forced_shooting_indices` in point selection |
| `src/core/multipoint_estimation.jl` | Honor forced times in FlowDeprecated path |
| `src/core/analysis_utils.jl` | Display shooting point provenance per cluster |
| `test/test_core_types.jl` | Update tests for new fields |

---

## 5. BACKWARD COMPATIBILITY

- New fields in `ParameterEstimationResult` default to `nothing` — all existing code
  that constructs results without these fields will need updating, but external code
  that reads results won't break (fields are optional/nullable).
- New options in `EstimationOptions` default to `nothing` — existing calls unchanged.
- The FlowDeprecated path is lower priority (FlowStandard is the default).

---

## 6. IMPLEMENTATION PRIORITY

1. **Add `shooting_time` field to result struct** (most useful for Sasha's question)
2. **Populate it in FlowStandard** (the default/active path)
3. **Display per-cluster provenance** (most visible improvement)
4. **Add `forced_shooting_times` option** (Sasha's second request)
5. **Update FlowDeprecated** (lower priority — it's not the default)
6. **Tests** (throughout)

---

## 7. SCOPE AND COMPLEXITY

This is a **medium-sized** feature:
- ~6 files modified
- Core logic changes are small (the shooting index tracking already exists internally)
- Main work is plumbing the information through to the user-facing result struct
- Display changes in `analysis_utils.jl` are straightforward
- Forced time points require touching the shooting point selection in 2 places

Estimated: 2-4 hours of focused development.
