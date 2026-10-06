# More than one answer

For some models the data cannot single out one set of parameter values. That is
a property of the model and of what was measured. It is not a failure of the
fit, and more data or better data does not change it. There are two ways it
happens, and the package reports both.

## Several separate answers

Two substances decay at their own rates, and only their total is measured:

```@example several
using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters a b
@variables x1(t) x2(t) y(t)
@named decays = System([D(x1) ~ -a * x1, D(x2) ~ -b * x2], t)

problem = ParameterEstimationProblem(decays, [y ~ x1 + x2];
    true_values = [a => 0.5, b => 1.5, x1 => 2.0, x2 => 1.0])
problem = sample_problem_data(problem; datasize = 41, time_interval = [0.0, 3.0])

results = estimate(problem)
```

There are two results, and they are the same answer with the substances
swapped:

```@example several
results[1]
```

```@example several
results[2]
```

Both reproduce the total exactly, and nothing in the data says which substance
is which. If you know something more, for instance that the first one decays
more slowly, that picks the answer. The package cannot know it, so it gives you
every answer the data allow.

## Parameters that cannot be determined

In this model two rates only ever appear as a sum, and the third state is
never measured:

```@example fixed
using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

@parameters a b c d
@variables x1(t) x2(t) x3(t) y1(t) y2(t)
@named chain = System([D(x1) ~ -a * x1, D(x2) ~ (b + c) * x1, D(x3) ~ d * x1], t)

problem = ParameterEstimationProblem(chain, [y1 ~ x1, y2 ~ x2];
    true_values = [a => 0.1, b => 0.2, c => 0.3, d => 0.4, x1 => 2.0, x2 => 3.0, x3 => 4.0])
problem = sample_problem_data(problem; datasize = 41, time_interval = [0.0, 5.0])

best = estimate(problem)[1]
```

The data determine `a`, the two measured states, and the sum `b + c`:

```@example fixed
best[b] + best[c]
```

They say nothing about how that sum splits into `b` and `c`, and nothing about
`d` or `x3`. Those are marked *not identifiable*. To solve for everything else
the package fixes each of them at some value, and that value is what is
printed. It is arbitrary. Do not read anything into it.

The same information is available as a set:

```@example fixed
best.all_unidentifiable
```

There are two ways out. One is to measure more: with `x3` measured as well,
`d` can be found. The other is to say less: write the model with a single
parameter in place of `b + c`, and it has one answer.

[StructuralIdentifiability.jl](https://github.com/SciML/StructuralIdentifiability.jl)
answers these questions for a model before any data exist. This package runs
it for you at the start of every estimation.
