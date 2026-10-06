# Your own data

To estimate from measurements you already have, hand them to the problem as
`data`. Nothing else changes.

## Measurements in vectors

Take a model with two states, both measured, and two unknown rates:

```@example own
using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters a b
@variables x1(t) x2(t) y1(t) y2(t)
@named oscillator = System([D(x1) ~ -a * x2, D(x2) ~ b * x1], t)
measured = [y1 ~ x1, y2 ~ x2]
nothing # hide
```

Measurements are a vector of times and one vector of values for each measured
quantity. These three stand in for yours:

```@example own
times = collect(range(0, 5; length = 41))
series1 = cos.(0.6 .* times .+ 0.3)
series2 = 1.5 .* sin.(0.6 .* times .+ 0.3)
nothing # hide
```

Give them under the names on the left-hand sides of the measured quantities,
with the times under `t`:

```@example own
problem = ParameterEstimationProblem(oscillator, measured;
    data = (t = times, y1 = series1, y2 = series2))

results = estimate(problem)
results[1]
```

Those two curves solve the model for `a = 0.4` and `b = 0.9`, which is what
came back, along with their values at the first time point.

## Measurements in a table

`data` can be anything with named columns, such as a `DataFrame` read from a
file:

```julia
using CSV, DataFrames

table = CSV.read("measurements.csv", DataFrame)   # columns t, y1 and y2
problem = ParameterEstimationProblem(oscillator, measured; data = table)
```

Other columns are ignored, and the rows do not have to be in time order. A
dictionary works too: `Dict("t" => times, "y1" => series1, "y2" => series2)`.

Every series needs a value at every time. If the table has gaps, either drop
those rows (`dropmissing(table)`) or describe each series separately, as below.

## Series measured at different times

When the quantities were not measured at the same times, describe each series
on its own with an [`ObservationSeries`](@ref) and collect them in an
[`ObservationData`](@ref):

```@example own
times1 = collect(range(0, 5; length = 41))
times2 = collect(range(0.1, 4.9; length = 33))

data = ObservationData([
    ObservationSeries("y1", "run 1", x1, times1, cos.(0.6 .* times1 .+ 0.3)),
    ObservationSeries("y2", "run 1", x2, times2, 1.5 .* sin.(0.6 .* times2 .+ 0.3)),
])

problem = ParameterEstimationProblem(oscillator, measured; data)
estimate(problem)[1]
```

Each series takes a name, a name for the experiment it belongs to, the quantity
that was measured, its times and its values. The quantity is the right-hand
side of the measured quantity, `x1` and not `y1`. Initial conditions are
reported at time zero unless you pass `initial_time` to `ObservationData`.

## How much data is enough

The method works from the shape of each curve, so it needs enough points to
see that shape: a few dozen per series, spread over a stretch of time in which
the system is doing something. A long tail where everything has settled adds
little.

## If the measurements are noisy

The example above used exact numbers. Real measurements are not exact, and
`estimate` allows for that: it fits its answers to the data before returning
them. [Noisy data](@ref) shows how much that matters, and what else helps.

## Checking the result

A result holds numbers, not a judgement of whether the model is right. Simulate
the model with the estimates and look at it against the measurements, as in
[Seeing the fit](@ref). If the curve misses the data, the model does not
describe them, whatever the parameters.
