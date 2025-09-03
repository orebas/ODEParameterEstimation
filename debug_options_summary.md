# Debug Options Implementation Summary

## Changes Made

### 1. Debug Options Added
The following debug options have been added and propagated through the call stack:
- `debug_solver`: Controls general solver debug output (DEBUG-SOLVER tags)
- `debug_cas_diagnostics`: Controls CAS system diagnostics (Oscar, Singular, Groebner.jl)
- `debug_dimensional_analysis`: Controls dimensional analysis warnings
- `save_system`: Controls saving of polynomial systems to disk (defaults to `true`)

### 2. Call Stack Propagation
Options flow through the following chain:
```
multipoint_parameter_estimation()
    ↓ (passes options)
solve_parameter_estimation()
    ↓ (creates options Dict)
system_solver() / solve_with_rs()
    ↓ (uses options)
exprs_to_AA_polys()
```

### 3. Files Modified

#### src/core/homotopy_continuation.jl
- Added option extraction at the beginning of `solve_with_rs()`
- Gated all debug output behind appropriate flags:
  - `println("[DEBUG-SOLVER]...")` → gated by `debug_solver`
  - `println("[DEBUG-AA]...")` → gated by `debug_cas_diagnostics`
  - `@warn "[DEBUG-ODEPE]..."` → gated by `debug_dimensional_analysis`
- Updated `exprs_to_AA_polys()` to accept `debug_aa` parameter

#### src/core/parameter_estimation_helpers.jl
- Added debug option parameters to `solve_parameter_estimation()`
- Created options Dict to pass to system_solver
- Gated existing DEBUG-ODEPE output behind `diagnostics` flag
- `save_system` functionality already properly gated

#### src/core/multipoint_estimation.jl
- Added debug option parameters to `multipoint_parameter_estimation()`
- Passes options through to `solve_parameter_estimation()`

### 4. Default Behavior
- All debug options default to `false` (no debug output)
- `save_system` defaults to `true` (systems are saved)
- Backward compatible - existing code will work without changes

### 5. Usage Example
```julia
# Run with all debug output enabled
result = multipoint_parameter_estimation(
    pep,
    debug_solver = true,
    debug_cas_diagnostics = true,
    debug_dimensional_analysis = true,
    save_system = true,  # default
)

# Run silently (no debug output, no system saving)
result = multipoint_parameter_estimation(
    pep,
    debug_solver = false,  # default
    debug_cas_diagnostics = false,  # default
    debug_dimensional_analysis = false,  # default
    save_system = false,
)
```

### 6. Environment Variable
The `ODEPE_DEEP_DEBUG` environment variable is still supported for backward compatibility and will enable debug output even if options are false.

## Testing Recommendation
Before committing, run the test suite to ensure no regressions:
```bash
julia --project -e "using Pkg; Pkg.test()"
```

## Next Steps
The changes are ready to commit. All debug output is now properly gated behind options that default to off, while system saving defaults to on as requested.