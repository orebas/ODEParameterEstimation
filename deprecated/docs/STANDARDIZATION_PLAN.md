# API Standardization and Type Stability Plan

## Core Type Improvements

### 1. Update `OrderedODESystem` 
- Add proper type annotations
- Consider making fields immutable

### 2. Refactor `ParameterEstimationProblem`
- Replace `Any` types with concrete types:
  ```julia
  struct ParameterEstimationProblem
      name::String
      model::OrderedODESystem
      measured_quantities::Vector{Equation}
      data_sample::Union{Nothing, OrderedDict{Any, Vector{Float64}}}
      recommended_time_interval::Union{Nothing, Vector{Float64}}
      solver::OrdinaryDiffEq.AbstractODEAlgorithm
      p_true::OrderedDict{Num, Float64}
      ic::OrderedDict{Num, Float64}
      unident_count::Int
  end
  ```

### 3. Refactor `ParameterEstimationResult`
- Provide concrete types for all fields:
  ```julia
  mutable struct ParameterEstimationResult
      parameters::OrderedDict{Num, Float64}
      states::OrderedDict{Num, Float64}
      at_time::Float64
      err::Union{Nothing, Float64}
      return_code::Symbol  # Use Symbol instead of Any
      datasize::Int64
      report_time::Float64
      unident_dict::Union{Nothing, OrderedDict{Num, Float64}}
      all_unidentifiable::Set{Num}
      solution::Union{Nothing, ODESolution}
  end
  ```

### 4. Refactor `DerivativeData`
- Replace all `Any` types with concrete types:
  ```julia
  mutable struct DerivativeData
      states_lhs_cleared::Vector{Vector{Num}}
      states_rhs_cleared::Vector{Vector{Num}}
      obs_lhs_cleared::Vector{Vector{Num}}
      obs_rhs_cleared::Vector{Vector{Num}}
      states_lhs::Vector{Vector{Num}}
      states_rhs::Vector{Vector{Num}}
      obs_lhs::Vector{Vector{Num}}
      obs_rhs::Vector{Vector{Num}}
      all_unidentifiable::Set{Num}
  end
  ```

## Consistent Naming Conventions

### 1. Parameter Order and Names
- Use consistent order across similar functions:
  - First parameter should be the problem/model
  - Second parameter should be the primary data
  - Follow with configuration options
- Standardize parameter names:
  - Use `abstol`/`reltol` consistently (not `atol`/`rtol`)
  - Use `interp_func` instead of `interpolator` 
  - Use `max_iterations` instead of `maxiter`

### 2. Return Values
- Ensure functions return values of consistent types
- Add return type annotations to functions
- Consider creating additional types for complex return values

### 3. Default Parameters
- Use consistent default value patterns across similar functions
- Prefer `nothing` over `:nothing` for optional parameters

## Type Stability Improvements

### 1. Fix Type-Unstable Functions
- `convert_to_real_or_complex_array`: Add type annotation to specify Union return type
  ```julia
  function convert_to_real_or_complex_array(values)::Union{Array{Float64,1}, Array{ComplexF64,1}}
  ```

- `lookup_value`: Add specific return type
  ```julia
  function lookup_value(key, dict)::Float64
  ```

- `multipoint_numerical_jacobian`: Add return type annotation
  ```julia
  function multipoint_numerical_jacobian(...)::Tuple{Matrix{Float64}, DerivativeData}
  ```

### 2. Interpolation API Standardization
- Create a consistent interface for interpolation functions
- Define an abstract type for interpolators:
  ```julia
  abstract type AbstractInterpolator end
  ```
- Ensure each interpolation function follows the same interface

### 3. Annotation and Static Analysis 
- Identify critical performance paths and add @inbounds where safe
- Add @inline annotations to small, frequently-called functions
- Add appropriate @fastmath annotations for numerical code

## Error Handling Standardization

### 1. Consistent Error Pattern
- Use `@error` for non-recoverable errors that should throw
- Use `@warn` for issues that can be handled
- Use `@debug` for debugging information

### 2. Error Messages
- Use descriptive error messages with information about:
  - The specific issue
  - Expected value ranges or types
  - Potential fixes

## Documentation Standardization

### 1. Function Documentation Template
- Apply consistent docstring format to all functions:
  ```julia
  """
      function_name(param1::Type1, param2::Type2) -> ReturnType

  Brief description of function purpose.

  # Arguments
  - `param1::Type1`: Description of first parameter
  - `param2::Type2`: Description of second parameter

  # Returns
  - Description of return value

  # Examples
  ```julia
  result = function_name(val1, val2)
  ```

  # Notes
  - Additional implementation details if needed
  """
  ```

### 2. Examples
- Add example usage to core functions
- Update README with standardized examples