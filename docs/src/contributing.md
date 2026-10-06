# Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/orebas/ODEParameterEstimation.jl).

## Running the tests

Add your checkout with `Pkg.develop`, then run these from Julia's default
environment:

```bash
julia --startup-file=no test/current.jl unit        # quick tests of the parts
julia --startup-file=no test/current.jl             # everything
julia --startup-file=no test/current.jl benchmark   # recovery from noisy data on full-size models
```

Run the full suite for any change that touches estimation. `unit` is for quick
iteration and does not replace it.

To check that the package installs and passes with dependencies taken from the
registry only, with none of your local development versions:

```bash
julia --startup-file=no test/registered.jl
```

## Building this manual

```bash
julia --startup-file=no --project=docs -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=docs docs/make.jl
```

The pages are in `docs/src`. Their examples run during the build, so a page
that builds is a page whose code works. Open `docs/build/index.html` to read
the result.

## Engineering notes

[`docs/internal`](https://github.com/orebas/ODEParameterEstimation.jl/tree/main/docs/internal)
holds the notes written while the package was developed: investigations, design
discussions and release checklists. They are a record, not documentation, and
many describe code that has since changed. Its `review_map.md` says where
things are in the source.
