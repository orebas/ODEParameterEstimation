# `Groebner.groebner` non-termination on a (near-)positive-dimensional ideal

**Package:** Groebner.jl **v0.10.3** (called from StructuralIdentifiability.jl)
**Symptom:** `Groebner.groebner(J)` burns one+ cores indefinitely (hours, no progress, no error)
on a specific `Vector{QQMPolyRingElem}` input — catastrophic coefficient swell.

## Where it fires

`StructuralIdentifiability.jl/src/primality_check.jl:4`, inside the primality check:

```julia
function check_primality_zerodim(J::Array{QQMPolyRingElem, 1})
    J = Groebner.groebner(J)        # <-- hangs here
    basis = Groebner.quotient_basis(J)
    ...
```

`check_primality` (same file) deliberately builds `J` to be **zero-dimensional** by evaluating
the non-leader variables at random integers. But for the input below that randomization does not
break the underlying degeneracy, so `J` is a zero-dimensional ideal that sits *infinitesimally*
off a positive-dimensional locus — its reduced Gröbner basis over ℚ has astronomically large
rational coefficients, and Buchberger/F4 never finishes.

## The mathematical origin (so the input isn't mysterious)

The ideal comes from a structural-identifiability problem for a 5-state ODE
(`latent_subpopulation_branch`) with three exchangeable subpopulations and observable
`y2 = I1 + I2 + I3`:

```
S' = -b1*S*I1 - b2*S*I2 - b3*S*I3
I1' = b1*S*I1 - a1*I1
I2' = b2*S*I2 - a2*I2
I3' = b3*S*I3 - a3*I3
R'  = a1*I1 + a2*I2 + a3*I3
y1 = S,   y2 = I1 + I2 + I3,   y3 = R
```

The downstream solver hands SIAN a candidate with the parameters **pinned at a symmetric point**:

```
a1 = 0.5515444564623
a2 = 0.5280653476711991      b1 = 0.604353296407284
a3 = 0.5280653476711998      b2 = 0.5932284607536389
                             b3 = 0.5932284607536389
```

Note `a2 ≈ a3` (differ by ~1 ULP) and `b2 = b3`. Subpopulations 2 and 3 are then dynamically
identical, and with only their sum observed, `I2 − I3` is a free direction → the variety is
positive-dimensional. The 1-ULP float difference, after SIAN rationalizes the floats to exact ℚ
(e.g. `0.557… → 67859272//121670595`), turns this into a *near-degenerate* zero-dimensional ideal
with monster coefficients — the worst case for a rational Gröbner basis.

## Reproduce

1. **`capture.jl`** — drives the exact pipeline path (`apply_prefixed_params_to_model` →
   `get_si_equation_system`) on the symmetric candidate, with a runtime override of
   `check_primality_zerodim` that `Serialization.serialize`s `J` to
   `/tmp/gb_capture_<n>polys.jls` immediately before the groebner call. Run it, wait for the
   `[GB-CAPTURE] serialized ...` log line, then kill it (it will hang in groebner):

   ```
   julia --startup-file=no capture.jl
   ```

   (Needs the ODEParameterEstimation `julia_odepe` env. NB: run on an *idle* machine — loading the
   env contends badly with other heavy Julia jobs.)

2. **`mwe.jl`** — the pure-Groebner reproducer once `J` is on disk:

   ```
   julia --startup-file=no mwe.jl /tmp/gb_capture_<n>polys.jls
   ```

   ```julia
   using Groebner, Serialization
   J = deserialize(ARGS[1])
   @time Groebner.groebner(J)        # hangs
   ```

## What would help the Groebner side

- Detect (near-)positive-dimensionality / coefficient blow-up early and bail with an error
  instead of spinning (StructuralIdentifiability already handles the *exact* positive-dimensional
  case via a `DomainError` elsewhere — this near-degenerate one slips through).
- A coefficient-size or iteration budget / timeout knob on `groebner`.
