# Which models work

## The rule

The right-hand sides of the model and the measured quantities have to be
*rational*: built from the states, the parameters and numbers using `+`, `-`,
`*`, `/` and whole-number powers.

That covers a lot of ground:

- mass-action chemistry, and anything else made of products of concentrations
- population and epidemic models such as Lotka–Volterra, SIR and SEIR
- compartment models from pharmacokinetics
- saturating terms such as `V * x / (K + x)`, and Hill terms with whole-number
  exponents
- linear systems

Parameters can go wherever states can: multiplied together, in denominators,
and in the measured quantities.

## Inputs that depend on time

`sin(c * t)`, `cos(c * t)` and `exp(c * t)` are accepted when `c` is a number.
They depend on time alone, so they are known in advance:

```@example models
using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters a b
@variables x(t) y(t)
@named forced = System([D(x) ~ -a * x + b * sin(0.5 * t)], t)

problem = ParameterEstimationProblem(forced, [y ~ x]; true_values = [a => 0.5, b => 2.0, x => 1.0])
problem = sample_problem_data(problem; datasize = 51, time_interval = [0.0, 10.0])
estimate(problem)[1]
```

## What is not accepted

Any other function of a state or of an unknown parameter: `sin(θ)`,
`exp(-E / T)`, `sqrt(h)`, `log(x)`. The package refuses such a model before it
does any work:

```@example models
@parameters g
@variables θ(t) ω(t)
@named pendulum = System([D(θ) ~ ω, D(ω) ~ -g * sin(θ)], t)

problem = ParameterEstimationProblem(pendulum, [y ~ θ]; data = (t = [0.0, 0.1, 0.2], y = [0.5, 0.49, 0.46]))
try
    estimate(problem)
catch err
    showerror(stdout, err)
end
```

Three more things are outside the rule: a frequency that is itself unknown,
as in `sin(w * t)`, a power with an unknown exponent, and time on its own, as
in `b * t`.

## Rewriting a model so that it is accepted

Many models that break the rule can be rewritten to follow it by adding
states. The idea is always the same: give the offending term a name, write
down its derivative, and tell the package its values.

**A function of a measured state.** In the pendulum, call `sin(θ)` and
`cos(θ)` by the names `s` and `c`. Their derivatives are `c * ω` and `-s * ω`,
which are polynomial. Since `θ` is measured, `s` and `c` are as good as
measured too: their data are the sine and cosine of the angle data.

```@example models
using OrdinaryDiffEq

# Angles of a pendulum with g = 9.8, released from rest at 0.5 radians.
times = collect(range(0, 2; length = 81))
swing = solve(ODEProblem((u, p, t) -> [u[2], -9.8 * sin(u[1])], [0.5, 0.0], (0.0, 2.0)), Vern9(); saveat = times, abstol = 1e-12, reltol = 1e-12)
angles = swing[1, :]

@variables s(t) c(t) ys(t) yc(t)
@named pendulum = System([D(θ) ~ ω, D(ω) ~ -g * s, D(s) ~ c * ω, D(c) ~ -s * ω], t)

problem = ParameterEstimationProblem(pendulum, [y ~ θ, ys ~ s, yc ~ c];
    data = (t = times, y = angles, ys = sin.(angles), yc = cos.(angles)))
estimate(problem)[1]
```

**Time itself.** Add a state `τ` with `D(τ) ~ 1` and use it wherever the model
has a bare `t`. Its data are the time points:

```julia
@variables τ(t) yτ(t)
@named ramp = System([D(x) ~ -a * x + b * τ, D(τ) ~ 1], t)

problem = ParameterEstimationProblem(ramp, [y ~ x, yτ ~ τ];
    data = (t = times, y = measurements, yτ = times))
```

## What has to be measured

Not every state needs to be measured. The states you do not measure are
estimated along with the parameters, as initial conditions. What matters is
that every unknown leaves a trace in what you measure. One that leaves none is
reported as not identifiable. See [More than one answer](@ref).

The fewer quantities you measure, the higher the derivatives of the data the
method needs, and high derivatives are hard to get from noisy data. A model
that needs more than the twentieth derivative is refused.

## Size

The cost grows quickly with the number of unknowns, and it depends on the
shape of the equations more than on the amount of data. Models with up to about
a dozen parameters are the usual range. Larger ones can work, and take much
longer. [Example models](@ref) lists some of each kind.
