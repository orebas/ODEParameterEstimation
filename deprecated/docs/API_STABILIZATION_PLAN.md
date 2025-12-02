# API Stabilization Plan

## Current Status

We've made progress in standardizing the API and improving type stability:
1. Created an abstract `AbstractInterpolator` type and standardized interpolation functions
2. Added type annotations to method signatures where possible
3. Updated core type definitions with more specific types
4. Added comprehensive docstrings
5. Fixed parameter naming inconsistencies

However, we've encountered compatibility issues in the existing codebase when trying to fully type-specify all parameters.

## Recommended Approach

Rather than attempting to change everything at once, we should adopt a more incremental approach:

### Phase 1: Non-disruptive Improvements
1. **Documentation and naming standardization**:
   - Continue adding docstrings to all functions
   - Standardize parameter names (e.g., `reltol/abstol` consistently)
   - Update comments to be more informative

2. **Minimal type annotations**:
   - Add return type annotations to functions
   - Add type annotations only to parameters that are consistently typed throughout the codebase
   - Use `Any` or `Union` types where needed to maintain compatibility

3. **Interpolator framework**:
   - Continue improving the interpolator framework as it's isolated and less likely to cause compatibility issues
   - Add more specialized interpolator types as needed

### Phase 2: Gradual Type Stabilization
1. **Create test suite**:
   - Develop comprehensive test cases for each part of the codebase
   - Ensure all existing functionality works correctly

2. **Incremental typing**:
   - Add more specific type annotations to one function at a time
   - Run tests after each change to ensure compatibility
   - Create a more consistent parameter passing pattern

3. **Refactor multi-type functions**:
   - Address functions that return different types conditionally
   - Create specialized versions for different input types if needed

### Phase 3: Performance Optimization
1. **Identify performance bottlenecks**:
   - Use profiling tools to identify slow functions
   - Focus on most frequently called code paths

2. **Code optimization**:
   - Add `@inbounds` to performance-critical loops
   - Add `@inline` to small, frequently called functions
   - Use `StaticArrays` for small fixed-size arrays
   - Add `@fastmath` where appropriate

3. **Benchmark improvements**:
   - Measure execution time before and after optimizations
   - Document performance gains

## Next Steps

1. **Focus on high-value functions first**:
   - `multipoint_parameter_estimation` and related functions
   - Interpolation and derivative calculations
   - Numerical solvers

2. **Create a compatibility layer**:
   - If needed, create wrapper functions that maintain the old API
   - Gradually migrate callers to the new API

3. **Update documentation**:
   - Document the new, more consistent API
   - Add examples showing proper usage of each function

## Implementation Timeline

1. **Immediate**:
   - Roll back any disruptive type annotations
   - Fix naming inconsistencies
   - Add comprehensive docstrings

2. **Short-term (1-2 weeks)**:
   - Focus on non-disruptive improvements
   - Add minimal type annotations
   - Enhance the interpolator framework

3. **Medium-term (2-4 weeks)**:
   - Implement a test suite
   - Begin incremental typing
   - Start refactoring multi-type functions

4. **Long-term (4+ weeks)**:
   - Optimize performance
   - Complete API standardization
   - Finalize documentation