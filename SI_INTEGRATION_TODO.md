# SI.jl Integration TODO

## Current State
The SI.jl integration is partially complete but needs more work to fully replace the iterative equation construction.

## What's Done
✅ Added StructuralIdentifiability.jl dependency
✅ Created type conversion functions (Symbolics ↔ Nemo)
✅ Set up basic SI.jl ODE conversion
✅ Added identifiability checking using SI.jl's assess_identifiability
✅ Created template-based construction framework
✅ Fixed ambiguous `substitute` calls by qualifying with `Symbolics.`

## What's Needed
1. **Extract polynomial system from SI.jl**: The main challenge is that ParameterEstimation.jl uses a complex custom implementation with SIAN functions that aren't directly available in StructuralIdentifiability.jl's public API.

2. **Options to proceed**:
   - Option A: Import and use ParameterEstimation.jl's identifiability_ode function directly
   - Option B: Implement our own polynomial system extraction using SI.jl's internal functions
   - Option C: Use SI.jl only for identifiability checking, keep iterative construction for equations

3. **Current workaround**: The `use_si_template` parameter is set to `false` by default until the full implementation is complete. This allows the package to compile and run with the existing iterative method while SI.jl integration is being developed.

## Technical Challenges
- PE.jl uses SIAN module functions that wrap SI.jl internals
- The polynomial system extraction requires deep integration with Nemo/AbstractAlgebra types
- Need to map derivative variables correctly between SI.jl and ODEPE's notation

## Next Steps
1. Study PE.jl's SIAN module implementation more closely
2. Determine if we can access SI.jl's polynomial generation directly
3. Implement proper polynomial system extraction
4. Re-enable `use_si_template = true` as default once working