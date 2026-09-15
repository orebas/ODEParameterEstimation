# Performance: simplifying a 55-term polynomial allocates 4.67 GB on a warmed call

Draft for SymbolicUtils.jl; not submitted.

`Symbolics.simplify` on a degree-6 polynomial in ten scalar variables takes
about 7.3 seconds and cumulatively allocates 4.67 GB, including on a second
call in the same process. The polynomial is linear in five of the variables.
It comes from a denominator-cleared ODE recurrence, but the reproducer needs
only Symbolics and Julia's standard library.

Symbolics [reexports the simplifier from SymbolicUtils](https://github.com/JuliaSymbolics/Symbolics.jl/blob/master/docs/src/manual/expression_manipulation.md).

## Reproducer

Use [`simplify.jl`](simplify.jl) together with
[`sneyd_equation.jl`](sneyd_equation.jl) in an environment containing Symbolics:

```sh
julia --startup-file=no simplify.jl equation
```

The actual measured operation is:

```julia
using Symbolics
include("sneyd_equation.jl")
simplify(l4_0 + l4_0)  # load the generic operation
@time simplify(sneyd_equation)
@time simplify(sneyd_equation)
```

Julia 1.13.0, Symbolics 7.39.0, SymbolicUtils 4.46.1:

| Input / operation | First call | Second call | Second-call allocated bytes |
|---|---:|---:|---:|
| Whole polynomial / `simplify` | 7.270679 s | 7.329521 s | 4,672,372,320 |
| Whole polynomial / `expand` | 0.003319 s | 0.000982 s | 981,640 |
| Reported two-summand fragment / `simplify` | 0.001843 s | 0.001966 s | 765,152 |

These are individual observations, with other validation processes potentially
running concurrently. Allocated bytes are cumulative allocations, not peak RSS.
`expand` has a narrower purpose than general simplification; it is included to
show the scale of ordinary polynomial manipulation on the same expression.

The full polynomial has 55 monomials, total degree 6, and five parameter
variables plus five state-derivative variables. The error fragment alone is
not a sufficient performance reproducer.

## Observed stacks and context

The parent application was repeatedly simplifying equations to test whether
they became zero after substituting fixed parameters. Its timed-out stacks
were in the associative-commutative common-factor rules in `PLUS_DISTRIBUTE`,
including:

```text
*(~~x, ~α) + *(~~x, ~β) => *(~α + ~β, (~~x)...)
```

The watchdog interrupted the matcher while examining:

```julia
IPR_O_10*l4_0*(100.0 + l_2_0^2)*l_6_0 +
    IPR_O_9*l6_0*l_2_0*l_4_0*(21.0 + l_6_0)
```

This suggests excessive work in common-factor pattern matching across the
larger expression. We have not isolated a particular bad matching decision
or established the asymptotic complexity. No incorrect simplification result
has been demonstrated.

Separately, the installed `Rule` catch-all replaces an interrupt with
`RuleRewriteError`, losing the original cause. The original application
timeout should not be interpreted as evidence that the displayed rule is
algebraically incorrect.

Our application now specializes and checks zero in its existing Nemo
polynomial representation. The standalone simplifier cost remains relevant
independently of that application fix.
