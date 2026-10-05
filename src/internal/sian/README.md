# Internal symbolic construction backend

This private module contains the SIAN functionality used by ODEPE's equation
builder. It has no dependency on SIAN or on the parent ODEPE module. It consumes
the existing StructuralIdentifiability ODE representation through its fields
and uses Nemo for exact polynomial arithmetic.

Source: <https://github.com/alexeyovchinnikov/SIAN-Julia>, as preserved in
<https://github.com/orebas/SIAN-Julia/commit/2f78ca8a0cc93f99eb2f800f08c1dbd20f8b28d9>.
The MIT notice is retained in `LICENSE`. The upstream utility file also notes
that several helpers were adapted from another repository without identifying
it; that attribution history is preserved here.

The extraction includes `max_poly_system.jl`, `get_x_eq.jl`, `get_y_eq.jl`,
`sample_point.jl`, and the required subset of `util.jl`. Changes are namespace
isolation, typed optional indices in ring conversions, and omission of unused
helpers. Equation, variable and sample order are preserved.

## Replacement boundary

All production calls are in `core/si_equation_builder.jl`. The module supplies
jet equations, recurrences, exact sampling/Jacobians, jet ordering and ring
conversion. ODEPE continues to own rank selection, representative fixing and
multiplicity counting; StructuralIdentifiability continues to own structural
classification. This module neither copies nor calls SIAN's identifiability
driver, parser, model type, weighted-ordering driver or replica API.

To replace/extract it, preserve the helper signatures and tuple shapes, change
the equation builder's qualified calls, and remove its include from the parent
module. Exact oracle fixtures and independent multiplicity contracts live in
the standard tests. Optional upstream regeneration lives in `test/reference`.
