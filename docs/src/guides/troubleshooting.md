# Troubleshooting

## The first call is slow

That is Julia compiling code for your model. It happens once for each model in
a session, and the second call to `estimate` shows the real speed.

## It is still running

Pass `progress = true` to see which stage it is in. If it is working through
the interpolators one after another, a shorter `interpolators` list or fewer
`shooting_points` will cut the time. See [Going faster](@ref). Large models
can take a long time in any case. See [Size](@ref).

## The estimates are off

Simulate the model with the estimates and plot it against the data, as in
[Seeing the fit](@ref). Then:

- **The curve misses the data.** With noisy data, more points help. See
  [Noisy data](@ref). If the data are clean and the curve still misses, the
  model probably does not describe them.
- **The curve fits, but the values are not what you expected.** The data may
  allow more than one answer. Look at the other results, and at whether any
  values are marked *not identifiable*. See [More than one answer](@ref).

## There are several results, or values marked "not identifiable"

Both are the package telling you something about the model, and
[More than one answer](@ref) explains what.

## There are no results

`estimate` returned an empty vector: none of the solutions of the equations
held up when checked against the data. Check that the time points and values
are what you meant to pass, and that the model can produce curves like them.
Running with `nooutput = false` prints what each stage found.

## "This model is not rational"

The model applies a function such as `sin` or `exp` to a state or an unknown
parameter. [Which models work](@ref) says what is allowed and how such a model
can sometimes be rewritten.

## "This model needs derivative … of the measured data"

Too few quantities are measured for the number of unknowns. Measuring one more
state usually brings the required derivatives down.

## The results change from run to run

Several steps use random numbers. Pass a `seed`. See
[Repeatable results](@ref).

## Something else

Please [open an issue](https://github.com/orebas/ODEParameterEstimation.jl/issues)
with the model and, if you can share it, the data. A simulated data set that
shows the same behavior is just as useful.
