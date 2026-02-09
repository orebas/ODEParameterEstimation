# Plan: Parameter Homotopy for Multi-Shooting Point Estimation

## Problem

Currently, the multishot parameter estimation solves the polynomial system **from scratch** at each shooting point. With `shooting_points = 8` (default), this means 9 independent HC.solve() calls. Each call:
1. Computes start system (total degree or polyhedral)
2. Tracks all paths from start to target
3. Filters real solutions

**Observation**: The polynomial **structure** is identical across shooting points. Only the **coefficients** change (interpolated data values y(t_k), y'(t_k), etc.).

## Proposed Solution: Parameter Homotopy

Use HomotopyContinuation.jl's parameter homotopy feature:
1. Treat interpolated observable values as **parameters** (change between points)
2. Treat unknown params/states as **variables** (what we solve for)
3. Solve fresh at first shooting point
4. **Track solutions** to subsequent points using parameter homotopy

### HC.jl Parameter Homotopy API

```julia
# Create parameterized system
@var x[1:n]  # variables (unknown params/states)
@var p[1:m]  # parameters (data values)
F = System(equations, variables=x, parameters=p)

# Solve at first point (fresh)
result1 = solve(F; target_parameters=p_values_1)
solutions1 = solutions(result1, only_real=true)

# Track to second point (fast!)
result2 = solve(F, solutions1;
    start_parameters=p_values_1,
    target_parameters=p_values_2)
```

## Expected Performance

| Scenario | Fresh Solve (current) | Parameter Homotopy |
|----------|----------------------|-------------------|
| First point | O(bezout) paths | O(bezout) paths |
| Subsequent points | O(bezout) paths each | O(total_sols) paths each |

For a system with Bezout bound ~1000 but only ~50 total solutions (real + complex), parameter homotopy tracks **50 paths** instead of **1000 paths** per subsequent point.

**Expected speedup**: 2-20x for shooting_points >= 3

## CRITICAL: Track ALL Solutions, Not Just Real

**Why?** Solutions can transition between real and complex as parameters change:
- A real solution at t₁ may become complex at t₂
- A complex solution at t₁ may become real at t₂

**Correct approach:**
1. At first point: fresh solve, get ALL solutions (real + complex)
2. Track ALL solutions to subsequent points
3. Filter for real solutions at EACH target point (for output)
4. Continue tracking ALL solutions to next point

This is how HC.jl's parameter homotopy works by default when you pass all start solutions.

## Existing Templating Infrastructure (to leverage)

The codebase already has excellent separation of structure from time-specific data:

### `EquationTemplate` struct (optimized_multishot_estimation.jl:117-137)
```julia
struct EquationTemplate
    obs_equations::Vector{Tuple{Any, Any, Int, Int}}  # (LHS, RHS, obs_idx, deriv_level)
    state_equations::Vector{Tuple{Any, Any}}          # (LHS, RHS)
    solve_variables::Vector{Any}                       # What we solve for
    fixed_params::OrderedDict{Num, Float64}           # Fixed unidentifiable params
    deriv_levels::OrderedDict{Int, Int}               # Required derivative orders
    ...
end
```

### `build_equations_at_time_point()` (lines 794-862)
Already substitutes interpolated values at specific time points. This is the function that varies between shooting points.

**Key insight for parameter homotopy**: The `obs_equations` contain RHS expressions with variables like `y1(t)`, `y1'(t)`. Currently these get numerically substituted. For parameter homotopy, these should become HC parameters instead.

## Implementation Approach

### Key Insight: What are "parameters"?

Looking at the SI template equations, the observable derivative variables appear as coefficients:
```julia
# Example equation from SI template:
-u_sin_0 + y2(t)           # y2(t) = interpolated value at t
tau_0 * y1ˍt(t) - y1(t)    # y1(t), y1ˍt(t) = interpolated values
```

These `y1(t)`, `y1ˍt(t)`, `y2(t)` etc. are substituted with numerical values at each shooting point. They should be HC **parameters**.

The actual unknowns (`tau_0`, `u_sin_0`, `T_0`, etc.) are HC **variables**.

### Files to Modify

| File | Changes |
|------|---------|
| `src/core/homotopy_continuation.jl` | Add `convert_to_hc_format_parameterized()` and `solve_with_hc_parameterized()` |
| `src/core/optimized_multishot_estimation.jl` | Use parameterized solver when shooting_points >= 3 |
| `src/types/estimation_options.jl` | Add `use_parameter_homotopy::Bool = true` option |

### Detailed Changes

#### 1. New function in `homotopy_continuation.jl`

```julia
"""
    solve_with_hc_parameterized(poly_system, solve_vars, data_vars, param_values_list)

Solve a polynomial system at multiple parameter values using parameter homotopy.
- poly_system: Symbolic equations
- solve_vars: Variables to solve for (params/states)
- data_vars: Variables that become HC parameters (interpolated observables)
- param_values_list: Vector of parameter value vectors, one per shooting point

Returns: Vector of real solutions at each point
"""
function solve_with_hc_parameterized(poly_system, solve_vars, data_vars, param_values_list; options=Dict())
    # Convert to HC format with parameters
    hc_system, hc_vars, hc_params = convert_to_hc_format_with_params(
        poly_system, solve_vars, data_vars
    )

    all_real_results = []
    prev_all_solutions = nothing  # Track ALL solutions (real + complex)
    prev_params = nothing

    for (i, current_params) in enumerate(param_values_list)
        if i == 1 || isnothing(prev_all_solutions)
            # Fresh solve at first point - get ALL solutions
            result = HomotopyContinuation.solve(hc_system;
                target_parameters=current_params,
                show_progress=false)
            all_solutions = HomotopyContinuation.solutions(result)  # ALL, not just real
        else
            # Parameter homotopy from previous point - track ALL solutions
            result = HomotopyContinuation.solve(hc_system, prev_all_solutions;
                start_parameters=prev_params,
                target_parameters=current_params,
                show_progress=false)
            all_solutions = HomotopyContinuation.solutions(result)

            # Fallback if tracking lost too many solutions
            if length(all_solutions) < length(prev_all_solutions) / 2
                @warn "Parameter homotopy lost solutions at point $i, doing fresh solve"
                result = HomotopyContinuation.solve(hc_system;
                    target_parameters=current_params,
                    show_progress=false)
                all_solutions = HomotopyContinuation.solutions(result)
            end
        end

        # Filter for REAL solutions at this point (for output)
        real_solutions = HomotopyContinuation.solutions(result, only_real=true, real_tol=1e-9)
        push!(all_real_results, real_solutions)

        # Track ALL solutions to next point (real + complex)
        prev_all_solutions = all_solutions
        prev_params = current_params
    end

    return all_real_results
end
```

#### 2. Conversion function with parameters

```julia
function convert_to_hc_format_with_params(poly_system, solve_vars, data_vars)
    # Use HC.ModelKit to create symbolic variables and parameters
    hc_vars = HC.ModelKit.Variable.(Symbol.(string.(solve_vars)))
    hc_params = HC.ModelKit.Variable.(Symbol.(string.(data_vars)))

    # Build substitution dictionary
    subst = Dict{Any, Any}()
    for (sv, hv) in zip(solve_vars, hc_vars)
        subst[sv] = hv
    end
    for (dv, hp) in zip(data_vars, hc_params)
        subst[dv] = hp
    end

    # Convert equations (similar to existing convert_to_hc_format but with params)
    hc_equations = []
    for eq in poly_system
        # ... string-based conversion with variable and parameter substitution ...
    end

    hc_system = HC.System(hc_equations, variables=hc_vars, parameters=hc_params)
    return hc_system, hc_vars, hc_params
end
```

#### 3. Integration in `optimized_multishot_estimation.jl`

In the main estimation loop (~line 1181), add a branch:

```julia
if opts.use_parameter_homotopy && length(point_indices) >= 3 && opts.system_solver == SolverHC
    # Use parameter homotopy approach
    data_vars = extract_data_variables(si_template, DD)  # y1(t), y1'(t), etc.
    param_values_list = [evaluate_data_at_point(interpolants, data_vars, t_vector[idx])
                         for idx in point_indices]

    all_solutions_by_point = solve_with_hc_parameterized(
        template_equations, solve_variables, data_vars, param_values_list
    )

    # Process results...
else
    # Use existing per-point solving
    for point_idx in point_indices
        # ... existing code ...
    end
end
```

## Trade-offs and When to Use

### Use Parameter Homotopy When:
- `shooting_points >= 3` (amortizes setup cost)
- Using `SolverHC` (doesn't apply to NLOpt solvers)
- System has many more paths than real solutions (common case)

### Don't Use When:
- Only 1-2 shooting points
- Parameter values change dramatically between points (may lose paths)
- System has few paths anyway (no benefit)

### Fallback Strategy:
- If tracking loses all solutions → fresh solve at that point
- If tracked count << expected → log warning, continue
- Can disable with `use_parameter_homotopy = false`

## Verification Strategy

### Test 1: Correctness
Run existing models (simple, lotka_volterra, biohydrogenation) with and without parameter homotopy. Solutions should match within tolerance.

### Test 2: Performance
```julia
# Profile with/without parameter homotopy
@time run_estimation(model; use_parameter_homotopy=false, shooting_points=10)
@time run_estimation(model; use_parameter_homotopy=true, shooting_points=10)
```

Expected: 2-10x speedup for the HC solving portion.

### Test 3: Edge Cases
- Test with shooting_points=1,2,3 (boundary cases)
- Test with models that have few vs many solutions
- Test with noisy data (interpolation values may be erratic)

## Risks

1. **Path crossing/failures**: Between shooting points, some solution paths may cross or hit singularities
   - Mitigation: Fallback to fresh solve

2. **Different solution counts**: Some models may have different numbers of real solutions at different parameter values
   - Mitigation: Track all paths, filter reals at each point

3. **Increased complexity**: More code paths, harder to debug
   - Mitigation: Keep it optional, good logging, maintain fallback

## Open Research Questions

1. **Performance vs Reliability tradeoff**: Will parameter homotopy be faster AND more reliable, or is there a tradeoff?

2. **Path loss rate**: How often do paths fail during parameter homotopy? If frequent, fallback overhead may negate speedup.

3. **Solution count stability**: Do real solution counts vary significantly between shooting points? If yes, tracking complex solutions is essential.

4. **Bezout bound vs actual solutions**: What's the typical ratio? Higher ratio = more benefit from parameter homotopy.

## Configuration Notes

- Default `shooting_points = 10` (per user)
- Parameter homotopy makes sense when shooting_points >= 3
- Should be opt-out (default on) since it's a transparent optimization

## Next Steps for Research

1. **Benchmark**: Run a few models (simple, lotka_volterra, biohydrogenation) with timing to measure actual HC solve time vs total time
2. **Solution analysis**: Log solution counts (real vs total) at each shooting point to understand variability
3. **Prototype**: Build minimal parameter homotopy wrapper and test on one model before full integration
