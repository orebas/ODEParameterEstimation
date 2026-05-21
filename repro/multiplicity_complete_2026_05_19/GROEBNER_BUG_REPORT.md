# Groebner.jl 0.10.3 — `_process_chunk` BoundsError on a 30-poly system

## TL;DR

`Groebner.groebner` on a 30-polynomial / 27-variable system over `Nemo.QQ`
crashes with an internal `BoundsError(Int32[…], (5,))` inside
`_process_chunk` at `groebner.jl:210`. The polynomial system is the
identifiability ideal of an ODE model (biohydrogenation cascade) produced
by `SIAN-Julia.identifiability_ode`.

The single-task / classic-modular / mod-p paths all succeed; only the
default multimodular-parallel path crashes.

## Versions

- Julia 1.12.6
- Nemo 0.54.2
- Groebner 0.10.3
- (Polynomial-system source: SIAN-Julia identifiability pipeline)

## Repro

`bioh_gb_input.jl` in this directory is a self-contained ~12 KB Julia
script. It builds a `Nemo.polynomial_ring` with `internal_ordering=:degrevlex`,
defines 30 polynomials over QQ, then calls `Groebner.groebner(polys)`.

Run:

```
julia --startup-file=no bioh_gb_input.jl
```

Expected: prints the GB and `quotient_basis` dim.
Observed: crashes inside `_process_chunk`.

## Stack trace excerpt

```
TaskFailedException
    nested task error: BoundsError: attempt to access 4-element Vector{Int32} at index [5]
    Stacktrace:
     [1] throw_boundserror(A::Vector{Int32}, I::Tuple{Int64})
       @ Base ./essentials.jl:15
     [2] getindex
       @ ./essentials.jl:919 [inlined]
     [3] #_process_chunk##0
       @ ~/.julia/packages/Groebner/Q7HGS/src/groebner/groebner.jl:210 [inlined]
     [4] ntuple
       @ ./ntuple.jl:19 [inlined]
     [5] _process_chunk(chunk::Vector{Int64}, ring::Groebner.PolyRing{DegRevLex{...}, UInt64},
                       basis_zz::Groebner.Basis{BigInt}, composite::Int64,
                       trace::Groebner.Trace{Groebner.CompositeNumber{4, Int32},
                                              Groebner.CompositeNumber{4, Int32}, …},
                       primes::Vector{Int32}, …)
       @ Groebner ~/.julia/packages/Groebner/Q7HGS/src/groebner/groebner.jl:210
     [6] _groebner_learn_and_apply##8#9 at groebner.jl:286
```

Key observation: the `Vector{Int32}` being indexed has length 4, but the
code attempts `[5]`. The `composite::Int64` and `Groebner.CompositeNumber{4, ...}`
in the type signature suggest the bug is related to the 4-prime batch
size used in the learn-and-apply path.

## Workarounds (all succeed on the same input)

These all complete successfully and return `quotient_basis_dim = 2`:

```
Groebner.groebner(polys; tasks=1)               # disables multitask
Groebner.groebner(polys; modular=:classic_modular)  # disables learn-and-apply
Groebner.groebner([change_ring_to_GF(p, 1073741827) for p in polys])  # mod p
```

So the algebraic correctness is fine — the crash is specifically in
the multitask multimodular-learn-and-apply implementation.

## What the polynomial system is

The 30-poly system is the identifiability ideal produced by SIAN-Julia
on the biohydrogenation ODE benchmark (Hong et al., a 4-state
Michaelis-Menten chain with 6 unknown rate constants and 1 continuously
unidentifiable state). The Groebner basis is needed to compute the
algebraic multiplicity M = number of distinct (state, parameter)
tuples consistent with a generic observation.

Other systems we tested (lotka_volterra, daisy_mamil4, seir, slow_fast,
plus ~20 others from the wallaby benchmark) all run cleanly under the
default Groebner path. Biohydrogenation is the only one that triggers
the bug.

## Polynomial system characteristics

- 27 variables (mix of jet-state vars and 6 parameters)
- 30 polynomials (29 of the form `Et_hat[i]`, 1 of the form `z_aux·Q - 1`)
- Total degrees range up to ~8
- Coefficients are integers / rationals from a SIAN sampling step
  (numerators up to ~10^15 in some cases)
- Variable ordering: degrevlex with parameters listed last

`bioh_gb_input.jl` has the explicit polynomial definitions; happy to
share more characterization if helpful.

## Trigger: coefficient magnitude (verified diagnostic)

`bioh_small_coefs_repro.jl` runs the same polynomial system but with each
coefficient replaced by a random integer in [-100, 100] (same monomial
layout). Result:

```
Original coefficient digit counts:  min=1, max=355, median=1
Small  coefficient digit counts:    min=1, max=3
Calling Groebner.groebner on small-coef version...
  ✓ SUCCEEDED: gb has 1 elements
    → coefficient magnitude was the trigger
```

So **the crash is triggered by coefficient size, not by the monomial /
variable layout**. The original system has a few coefficients with 355
digits (from SIAN's D2-based sampling, which scales as `1/(1-p)` and
times the Bezout product of polynomial degrees — for biohydrogenation
that's astronomically large).

The mean / median is still single-digit; only a handful of the
coefficients blow up. But that's enough to trigger the crash.

## Suggested fix direction (speculative)

The `Vector{Int32}` size mismatch (length 4 vs. index 5) inside
`_process_chunk` looks like an off-by-one in how the learn-and-apply
algorithm tracks how many primes it has lifted vs. how many it expects
to lift in the next batch. With 355-digit coefficients, the algorithm
likely needs many more primes than a default 4-prime batch can lift
the modular results onto, and somewhere the "we need another batch"
counter races ahead of the actual batch allocation.

The `CompositeNumber{4, Int32}` type in the call's signature is the
4-prime SIMD batch type; the size-4 vector being indexed at `[5]` is
plausibly the batch's per-prime tracker.

This is still speculation; the actual fix may be different.

## Files

- `bioh_gb_input.jl` — self-contained repro (~12 KB)
- `GROEBNER_BUG_REPORT.md` — this file
- Related upstream context (not needed to reproduce):
  - `MULTIPLICITY_COMPLETE.md` — algebraic multiplicity catalog
  - `M_INFERENCE_TECHNICAL.md` — survey of SI.jl / SIAN-Julia / ODEPE
    paths to computing M

## Contact

Filed as part of the [ParameterEstimationBenchmarking
multiplicity-inference investigation](https://github.com/orebas/ODEParameterEstimation)
(May 2026).
