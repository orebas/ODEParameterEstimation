# ODEParameterEstimation.jl Guidelines

## Build/Test Commands
- Activate the project: `julia --project`
- Run tests: `julia --project -e "using Pkg; Pkg.test()"`
- Run specific test: `julia --project test/specific_test.jl`
- Run examples: `julia --project -e "include(\"src/examples/run_examples.jl\")"`

## Code Style Guidelines
- Imports: Group related packages, with ModelingToolkit, OrdinaryDiffEq first
- Types: Use concrete types for function arguments, especially core types
- Functions: Document with docstrings using the triple quote format with Arguments/Returns sections
- Naming: Use snake_case for functions/variables, PascalCase for types
- Error handling: Use informative error messages with try/catch for numerical operations
- Parameters: Use OrderedDict for parameters and states to maintain consistent ordering 
- ODE convention: Use t as the independent variable, D for differentiation
- Documentation: Document complex algorithms with explanatory inline comments

## Type Stability Guidelines
- Avoid `Any` type in struct fields and function signatures
- Ensure functions return consistent types
- Use concrete parameter types instead of generic ones
- Add explicit return type annotations to complex functions
- Prefer using Union types over Any when multiple specific types are possible
- Use @code_warntype to check for type instabilities in critical functions

## Constants and Configuration
- Default ODE solver: `package_wide_default_ode_solver = AutoVern9(Rodas4P())`
- Algorithm thresholds are defined in core_types.jl

## Naming Conventions
- Error thresholds: Use descriptive names with consistent notation (e.g., `XXX_THRESHOLD`)
- Function parameters: Use consistent names across similar functions:
  - `abstol`/`reltol` for tolerances (not atol/rtol)
  - `interp_func` for interpolation functions
  - Put `problem` or `model` as first parameter when applicable
- File organization: Keep related functionality in the same file or module