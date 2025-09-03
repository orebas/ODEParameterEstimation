# StructuralIdentifiability.jl Integration Plan for ODEParameterEstimation.jl

## Executive Summary
Integrate StructuralIdentifiability.jl (SI.jl) into ODEParameterEstimation.jl using a hybrid "Structural Residual Method" that leverages SI.jl for robust equation construction while preserving the existing numerical optimization framework.

## Current Situation
- ODEPE's iterative equation construction works 90% of the time
- Need more robust approach for the 10% failure cases
- Must preserve optimized workflow benefits (template reuse, performance)

## Proposed Solution: Structural Residual Method

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│           optimized_multishot_parameter_estimation          │
│                                                             │
│  ┌──────────────────────┐    ┌─────────────────────────┐  │
│  │  method=:iterative   │    │ method=:structural_res. │  │
│  │  (current, 90% OK)   │    │   (new, for 10% hard)   │  │
│  └──────────────────────┘    └─────────────────────────┘  │
│           │                            │                    │
│           ▼                            ▼                    │
│  ┌──────────────────────┐    ┌─────────────────────────┐  │
│  │  Iterative scanning  │    │    SI.jl analysis      │  │
│  │  equation building   │    │  (one-time symbolic)    │  │
│  └──────────────────────┘    └─────────────────────────┘  │
│           │                            │                    │
│           ▼                            ▼                    │
│  ┌──────────────────────┐    ┌─────────────────────────┐  │
│  │   Template reuse     │    │  Structural residuals  │  │
│  │   for multishot      │    │    as cost function     │  │
│  └──────────────────────┘    └─────────────────────────┘  │
│           │                            │                    │
│           ▼                            ▼                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Shared numerical optimization backend         │  │
│  │              (Optimization.jl, solvers)               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Innovation: Structural Residuals
Instead of differentiating noisy data (error-prone), we:
1. Use SI.jl to generate polynomial constraints that must be satisfied
2. Evaluate these constraints using model-derived derivatives (noise-free)
3. Minimize structural residuals as the optimization objective

## Implementation Plan

### Phase 1: Infrastructure Setup

#### 1.1 Add StructuralIdentifiability dependency
```julia
# Project.toml
[deps]
StructuralIdentifiability = "220ca800-aa68-49bb-acd8-6037fa93a544"
```

#### 1.2 Create new module for SI integration
```julia
# src/core/structural_identifiability_integration.jl
module SIIntegration

using StructuralIdentifiability
using ModelingToolkit
using Symbolics
using Nemo
using AbstractAlgebra
using OrderedCollections

# Type conversion utilities
include("si_type_conversion.jl")

# Main integration functions
export check_identifiability_odepe
export generate_structural_equations
export build_structural_loss

end
```

### Phase 2: Type Conversion Layer

#### 2.1 Symbolics ↔ Nemo conversions
```julia
# src/core/si_type_conversion.jl

"""Convert ModelingToolkit ODESystem to SI.jl ODE format"""
function mtk_to_si_ode(
    ode::ModelingToolkit.ODESystem,
    measured_quantities::Vector{ModelingToolkit.Equation},
    inputs::Vector{Num} = Vector{Num}()
)
    # Based on PE.jl's preprocess_ode
    # Returns: SI.ODE object, symbol mapping
end

"""Convert Nemo polynomial back to Symbolics expression"""
function nemo_to_symbolics(
    nemo_expr::Nemo.QQMPolyRingElem,
    var_map::Dict
)
    # Map Nemo variables back to Symbolics.Num
end

"""Convert SI.jl polynomial system to evaluatable functions"""
function si_polys_to_functions(
    polys::Vector,
    var_map::Dict
)
    # Use ModelingToolkit.build_function for compilation
end
```

### Phase 3: Structural Equation Generation

#### 3.1 One-time symbolic analysis
```julia
# src/core/structural_identifiability_integration.jl

function generate_structural_equations(
    ode::ModelingToolkit.ODESystem,
    measured_quantities::Vector{ModelingToolkit.Equation};
    max_derivatives::Int = 3
)
    # Step 1: Check identifiability
    si_ode, symbol_map = mtk_to_si_ode(ode, measured_quantities)
    id_result = StructuralIdentifiability.check_identifiability(si_ode)
    
    # Step 2: Extract polynomial system
    poly_system = id_result.polynomial_system
    transcendence_basis = id_result.transcendence_basis_subs
    
    # Step 3: Generate derivative functions
    derivative_funcs = generate_derivative_functions(
        ode, measured_quantities, max_derivatives
    )
    
    # Step 4: Convert to evaluatable form
    structural_eqs = si_polys_to_functions(poly_system, symbol_map)
    
    return (
        equations = structural_eqs,
        derivatives = derivative_funcs,
        identifiability = id_result,
        symbol_map = symbol_map
    )
end
```

#### 3.2 Symbolic derivative generation
```julia
function generate_derivative_functions(
    ode::ModelingToolkit.ODESystem,
    measured_quantities::Vector{ModelingToolkit.Equation},
    max_order::Int
)
    t = ModelingToolkit.get_iv(ode)
    derivative_funcs = OrderedDict()
    
    for mq in measured_quantities
        y = mq.lhs
        derivs = [y]
        
        for i in 1:max_order
            # Use ModelingToolkit's derivative operator
            dy = ModelingToolkit.derivative(derivs[end], t)
            # Expand using chain rule and ODE equations
            dy_expanded = expand_derivatives(dy, ode)
            push!(derivs, dy_expanded)
        end
        
        # Compile to efficient functions
        for (i, d) in enumerate(derivs)
            func = ModelingToolkit.build_function(
                d, 
                ModelingToolkit.unknowns(ode),
                ModelingToolkit.parameters(ode),
                t;
                expression = Val(false)
            )
            derivative_funcs[(y, i-1)] = func
        end
    end
    
    return derivative_funcs
end
```

### Phase 4: Structural Loss Function

#### 4.1 Cost function construction
```julia
function build_structural_loss(
    structural_eqs,
    derivative_funcs,
    ode::ModelingToolkit.ODESystem,
    data_times::Vector{Float64}
)
    function structural_loss(p::Vector, u0::Vector)
        # Solve ODE with current parameters
        prob = ODEProblem(ode, u0, (data_times[1], data_times[end]), p)
        sol = solve(prob, AutoVern9(Rodas4P()))
        
        total_loss = 0.0
        
        for t in data_times
            # Get state at time t
            u_t = sol(t)
            
            # Evaluate all derivatives
            deriv_vals = OrderedDict()
            for ((y, order), func) in derivative_funcs
                deriv_vals[(y, order)] = func(u_t, p, t)
            end
            
            # Evaluate structural equations
            for eq in structural_eqs
                residual = eq(deriv_vals, p)
                total_loss += residual^2
            end
        end
        
        return total_loss
    end
    
    return structural_loss
end
```

### Phase 5: Integration with Optimized Workflow

#### 5.1 Method selector in main function
```julia
# src/core/optimized_multishot_estimation.jl

function optimized_multishot_parameter_estimation(
    problem::ParameterEstimationProblem;
    method::Symbol = :iterative,  # :iterative or :structural_residual
    kwargs...
)
    if method == :structural_residual
        return solve_with_structural_residual(problem; kwargs...)
    elseif method == :iterative
        # Existing iterative implementation
        return solve_with_iterative_scanning(problem; kwargs...)
    else
        throw(ArgumentError("Unknown method: $method"))
    end
end
```

#### 5.2 Structural residual solver
```julia
function solve_with_structural_residual(
    problem::ParameterEstimationProblem;
    kwargs...
)
    # Step 1: Generate structural equations (once)
    structural_data = generate_structural_equations(
        problem.model.system,
        problem.measured_quantities
    )
    
    # Check if model is identifiable
    if !isempty(structural_data.identifiability.non_identifiable)
        @warn "Non-identifiable parameters detected: " *
              "$(structural_data.identifiability.non_identifiable)"
    end
    
    # Step 2: Build loss function
    loss_fn = build_structural_loss(
        structural_data.equations,
        structural_data.derivatives,
        problem.model.system,
        problem.data_sample["t"]
    )
    
    # Step 3: Setup optimization problem
    opt_prob = OptimizationProblem(
        loss_fn,
        initial_guess(problem),
        problem.model.original_parameters
    )
    
    # Step 4: Solve
    sol = solve(opt_prob, BFGS())
    
    # Step 5: Convert to ParameterEstimationResult
    return process_optimization_result(sol, problem)
end
```

## Risk Analysis & Mitigation

### Risk 1: Performance Impact
**Risk**: Structural residual evaluation more expensive than simple data fitting
**Mitigation**: 
- Cache compiled derivative functions
- Use parallel evaluation across time points
- Implement hybrid loss: `L = L_structural + α*L_data`

### Risk 2: Type Conversion Complexity
**Risk**: Complex conversions between Symbolics, Nemo, AbstractAlgebra
**Mitigation**:
- Comprehensive test suite for conversions
- Clear error messages for unsupported expressions
- Fallback to iterative method on conversion failure

### Risk 3: Numerical Conditioning
**Risk**: Polynomial residuals may have different scaling than data residuals
**Mitigation**:
- Automatic scaling based on typical residual magnitudes
- Adaptive weighting between structural and data terms
- Optimizer tolerance tuning

## Testing Strategy

### Test Cases
1. **Simple Linear ODE**: Verify exact recovery of parameters
2. **Lotka-Volterra**: Known difficult case, compare methods
3. **Non-identifiable System**: Verify proper warnings/handling
4. **Noisy Data**: Compare robustness vs iterative method
5. **Performance Benchmark**: Measure overhead vs benefits

### Validation Metrics
- Parameter recovery accuracy
- Convergence rate
- Computational time
- Robustness to noise
- Handling of non-identifiability

## Implementation Timeline

### Week 1: Foundation
- [ ] Add SI.jl dependency
- [ ] Create type conversion utilities
- [ ] Basic mtk_to_si_ode function

### Week 2: Symbolic Analysis
- [ ] Implement generate_structural_equations
- [ ] Build derivative function generation
- [ ] Test symbolic components

### Week 3: Integration
- [ ] Create structural_loss function
- [ ] Integrate with optimization framework
- [ ] Add method selector

### Week 4: Testing & Refinement
- [ ] Comprehensive test suite
- [ ] Performance optimization
- [ ] Documentation

## Fallback Strategy
If structural residual method proves problematic:
1. Use SI.jl ONLY for identifiability checking
2. Extract variable ordering from SI.jl for equation construction
3. Keep numerical evaluation as-is

## Success Criteria
- Solves 95%+ of test cases (up from 90%)
- No performance regression for simple cases
- Clear improvement on known difficult problems
- Maintainable, well-documented code

## Open Questions
1. Should we expose SI.jl's identifiability results to users?
2. How to handle partially identifiable systems?
3. Default method selection heuristic?

## References
- ParameterEstimation.jl SI integration: src/identifiability/
- StructuralIdentifiability.jl docs
- ModelingToolkit symbolic differentiation
- DataInterpolations.jl for potential future enhancements