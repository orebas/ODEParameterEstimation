# Structural Residuals Method - Future Research

## Concept
Instead of fitting data directly, minimize the residuals of the structural equations that define the system. The polynomials from SI.jl represent constraints that must be satisfied - we can use these as an alternative optimization objective.

## Key Idea
- SI.jl generates polynomials that are identically zero for correct parameters
- Evaluate these polynomials using model-derived derivatives (not data derivatives)
- Sum of squared polynomial residuals becomes the loss function

## Potential Benefits
- Avoids differentiating noisy data
- May have better optimization landscape for poorly identifiable models
- Could handle sloppy parameter spaces better

## Implementation Notes
- Would require symbolic derivative generation from ModelingToolkit
- Need to evaluate polynomials along ODE solution trajectory
- Could combine with data-fitting loss as hybrid approach

## Status
**NOT IMPLEMENTED - FUTURE RESEARCH ONLY**

This is out of scope for the current SI.jl integration, which simply uses SI.jl for equation construction.