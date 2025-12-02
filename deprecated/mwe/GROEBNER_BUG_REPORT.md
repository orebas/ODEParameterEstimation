# Groebner.jl Threading Bug Report

## Summary
BoundsError in `_groebner_learn_and_apply_threaded` when running with multiple threads.
With 7 threads, tries to access index [8] in a 7-element Vector - off-by-one error.

## Environment
- Julia: 1.12.2
- Groebner.jl: 0.9.5
- Threads: 7 (JULIA_NUM_THREADS=7)

## Error Details
```
BoundsError: attempt to access 7-element Vector{Groebner.Trace{...}} at index [8]

Stacktrace:
 [1] throw_boundserror at ./essentials.jl:15
 [2] getindex at ./essentials.jl:919
 [3] macro expansion at ~/.julia/packages/Groebner/k40dp/src/groebner/groebner.jl:450
 [4] _groebner_learn_and_apply_threaded##6 at ./threadingconstructs.jl:276
```

## How to Reproduce

### Option 1: StructuralIdentifiability (reproduces the bug)
```julia
# Run: julia -t 7 mwe_si_groebner.jl

using StructuralIdentifiability
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters a b
@variables x1(t) x2(t) y1(t) y2(t)

eqs = [D(x1) ~ -a * x2, D(x2) ~ b * x1]
measured = [y1 ~ x1, y2 ~ x2]

@named sys = ODESystem(eqs, t, [x1, x2], [a, b])

# This triggers the bug
result = assess_identifiability(sys; measured_quantities=measured)
```

### Option 2: Pure Groebner (does NOT reproduce)
Simple Groebner calls do NOT reproduce the bug:
```julia
using Groebner
using Nemo

R, (x1, x2) = Nemo.polynomial_ring(Nemo.QQ, ["x1", "x2"])
polys = [x1^2 + x2 - 1, x1 + x2^2 - 1]
gb = Groebner.groebner(polys)  # Works fine
```

## Key Observations

1. **Threading correlation**: Error accesses index 8 with 7 threads - suggests off-by-one in thread indexing

2. **Triggered by SI's internal path**: The bug occurs through:
   - `StructuralIdentifiability.assess_identifiability`
   - → `check_primality_zerodim`
   - → `Groebner.groebner(J)` on `Vector{QQMPolyRingElem}`

3. **Error location**: `groebner.jl:450` in `_groebner_learn_and_apply_threaded`

4. **Ordering details from error**: The trace shows:
   ```
   output order : Lex(4) × Lex(1,2) × Lex(3)
   ```
   ProductOrdering may be relevant to triggering the bug.

5. **Working around**: The bug doesn't occur with:
   - Single thread (`julia -t 1`)
   - Direct Groebner calls on simple systems

## Workaround
Run Julia with a single thread:
```bash
julia -t 1 your_script.jl
```

## Files
- `mwe_si_groebner.jl` - Minimal example using StructuralIdentifiability (reproduces bug)
- `mwe_groebner_nemo.jl` - Pure Groebner tests (does NOT reproduce)
