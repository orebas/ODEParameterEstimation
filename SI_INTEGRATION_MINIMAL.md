# Minimal SI.jl Integration Plan

## Goal
Replace ODEPE's iterative equation construction with SI.jl's polynomial system. No fallbacks, no alternatives - SI.jl becomes the default and only path for equation construction.

## Current vs. New Flow

### Current (Iterative):
```
Data → Derivatives (GPR) → Iterative Scanning → Equation System → Solve
```

### New (SI.jl):
```
Model → SI.jl Analysis → Polynomial System → [Same derivatives/solving as before]
```

## Implementation Steps

### Step 1: Add Dependency
```julia
# Project.toml
[deps]
StructuralIdentifiability = "220ca800-aa68-49bb-acd8-6037fa93a544"
```

### Step 2: Create Conversion Module
```julia
# src/core/si_equation_builder.jl

using StructuralIdentifiability
using ModelingToolkit
using Nemo
using AbstractAlgebra
using OrderedCollections

"""
Get polynomial equation system from SI.jl
Returns equations in the format ODEPE expects
"""
function get_si_equation_system(
    ode::OrderedODESystem,
    measured_quantities::Vector{ModelingToolkit.Equation},
    data_sample::OrderedDict;
    kwargs...
)
    # 1. Convert to SI.jl format (based on PE.jl's preprocess_ode)
    si_ode, symbol_map, gens = convert_to_si_ode(ode, measured_quantities)
    
    # 2. Run SI.jl analysis
    id_result = StructuralIdentifiability.identifiability_ode(
        si_ode, 
        StructuralIdentifiability.get_parameters(si_ode);
        p = 0.99,
        kwargs...
    )
    
    # 3. Extract polynomial system
    poly_system = id_result["polynomial_system"]
    transcendence_subs = id_result["transcendence_basis_subs"]
    
    # 4. Convert back to Symbolics format that ODEPE expects
    equations = convert_si_polys_to_symbolics(
        poly_system,
        symbol_map,
        transcendence_subs
    )
    
    # 5. Return in ODEPE's expected format
    return equations, id_result["all_unidentifiable"]
end
```

### Step 3: Replace Equation Construction in optimized_multishot_estimation.jl

**BEFORE (iterative):**
```julia
# In optimized_multishot_parameter_estimation()
# Lines where iterative scanning builds equations
for iteration in 1:max_iterations
    # ... iterative equation building ...
end
```

**AFTER (SI.jl):**
```julia
# In optimized_multishot_parameter_estimation()
# Replace iterative construction with single SI.jl call
equations, unidentifiable = get_si_equation_system(
    problem.model,
    problem.measured_quantities,
    problem.data_sample
)

# Use equations exactly as before for the rest of the workflow
```

### Step 4: Type Conversion Functions

```julia
# src/core/si_equation_builder.jl

function convert_to_si_ode(
    ode::OrderedODESystem,
    measured_quantities::Vector{ModelingToolkit.Equation}
)
    # Based directly on PE.jl's preprocess_ode
    # Convert ModelingToolkit → Nemo polynomial ring
    
    model = ode.system
    states = ode.original_states
    params = ode.original_parameters
    
    # Create Nemo polynomial ring
    generators = string.(vcat(states, params))
    R, gens = Nemo.polynomial_ring(Nemo.QQ, generators)
    
    # Convert equations to Nemo format
    # ... (following PE.jl pattern)
    
    return si_ode, symbol_map, gens
end

function convert_si_polys_to_symbolics(
    polys::Vector,
    symbol_map::Dict,
    transcendence_subs::Dict
)
    # Convert Nemo polynomials → Symbolics expressions
    # This is the key integration point
    
    symbolic_eqs = []
    for poly in polys
        # Apply transcendence substitutions
        poly_subst = substitute(poly, transcendence_subs)
        
        # Convert Nemo → Symbolics
        sym_eq = nemo_to_symbolics(poly_subst, symbol_map)
        push!(symbolic_eqs, sym_eq)
    end
    
    return symbolic_eqs
end
```

## Key Integration Points

### In multipoint_estimation.jl
Replace the iterative scanning loop with:
```julia
# Get equations from SI.jl (once, not iteratively)
equations, unidentifiable = get_si_equation_system(PEP.model, measured_quantities, data)
```

### In optimized_multishot_estimation.jl
Same replacement - use SI.jl equations instead of iterative construction.

## What Stays the Same
- GPR for derivatives (modular, can experiment later)
- Numerical evaluation and solving
- Template reuse for multiple shooting points
- All optimization and polishing steps

## Testing Approach
1. Run SI.jl on all test models
2. Verify equation system matches expected structure
3. Compare parameter estimation results with current method
4. No fallback - if SI.jl fails, we fix it or report the issue

## Expected Challenges
1. **Type conversions**: Nemo ↔ Symbolics is the main technical challenge
2. **Variable naming**: Need to maintain consistent naming between systems
3. **Transcendence basis**: Properly handling the substitutions SI.jl provides

## Success Criteria
- SI.jl successfully generates equations for 100% of test cases
- No performance regression
- Cleaner, more maintainable code
- Better handling of previously difficult cases