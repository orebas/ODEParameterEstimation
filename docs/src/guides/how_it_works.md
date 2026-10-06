# How it works

Most parameter-estimation tools search. They start from a guess, simulate the
model, and adjust the guess to shrink the mismatch with the data. That works
when the guess is good. When it is not, the search can settle on a wrong
answer, and nothing tells you whether a different answer would fit just as
well.

This package solves equations instead.

## The idea

Take a model with one parameter and one measured quantity:

```math
x'(t) = -a\,x(t), \qquad y(t) = x(t).
```

Differentiating the measurement gives ``y' = x' = -a\,y``. So if the data tell
us ``y`` and ``y'`` at some time, then ``a = -y'/y``. That is an equation for
``a``, and solving it takes no search.

The same thing works in general. Differentiate the measured quantities a few
times, use the model to rewrite each derivative of a state, and you get
polynomial equations that link the unknown parameters and states to the values
of ``y, y', y'', \dots`` at a chosen time. Take enough derivatives and there
are as many equations as unknowns.

## The steps

1. **Find out what can be determined.**
   [StructuralIdentifiability.jl](https://github.com/SciML/StructuralIdentifiability.jl)
   works out, from the model alone, which parameters and initial conditions the
   measured quantities determine. Anything they do not determine is given a
   fixed value and flagged in the result.
2. **Estimate derivatives from the data.** Each measured series is fitted with a
   smooth curve, and the curve is differentiated. Several kinds of curve are
   used: Gaussian processes, which cope with noise, and rational and Chebyshev
   approximations, which are very accurate on clean data.
3. **Build the polynomial equations and solve them.** The derivative values go
   into the equations, at several time points and for each fitted curve.
   [HomotopyContinuation.jl](https://www.juliahomotopycontinuation.org) finds
   all the solutions of each system.
4. **Test every candidate against the data.** Each real solution gives parameter
   values and initial conditions. The model is simulated with them and compared
   with the measurements.
5. **Refine.** The candidates that come close are then fitted to the data by
   least squares, each starting from its own values. On exact data this
   changes nothing. On noisy data it is what makes the answer accurate.
6. **Report the distinct answers.** Candidates that agree are merged, and the
   rest are ranked by how well they fit. The package works out how many
   solutions the equations have and returns at most that many.

## What follows from this

- **Every answer, not one.** If two parameter sets explain the data equally
  well, you get both. See [More than one answer](@ref).
- **Rational models only.** The equations must be polynomial, so the model has
  to be built from polynomials and their ratios. See [Which models work](@ref).
- **Derivatives are the hard part.** Noise grows with every derivative taken,
  so on noisy data the solutions of the equations are rough, and the
  refinement step does the rest. See [Noisy data](@ref).

## Papers

The method is described in

> O. Bassik, Y. Berman, S. Go, H. Hong, I. Ilmer, A. Ovchinnikov, C. Rackauckas,
> P. Soto, C. Yap. *Robust parameter estimation for rational ordinary
> differential equations.* Applied Mathematics and Computation 509 (2026).
> [doi:10.1016/j.amc.2025.129638](https://doi.org/10.1016/j.amc.2025.129638),
> [arXiv:2303.02159](https://arxiv.org/abs/2303.02159).

Its extension to noisy data, which estimates the derivatives with Gaussian
processes, is described in

> O. Bassik, A. Demin, A. Ovchinnikov. *Practical algebraic parameter
> estimation for noisy data via Gaussian process regression.*
> [arXiv:2609.30451](https://arxiv.org/abs/2609.30451) (2026).
