# Examples Directory

This directory contains model definitions and maintained runnable workflows.
The investigation scripts, benchmarks, and PEtab pilot are preserved on the
[research branch](https://github.com/orebas/ODEParameterEstimation.jl/tree/research/src/examples).

If you are looking for the current user-facing package workflow rather than the example inventory, start with:

- [README.md](../../README.md)
- [2026-03-17_user_quickstart.md](../../docs/internal/2026-03-17_user_quickstart.md)
- [2026-03-17_results_and_api.md](../../docs/internal/2026-03-17_results_and_api.md)

## Categories

### Model Buckets

Model constructors are still grouped in shared source files under [models](models), so the primary categorization now lives in [load_examples.jl](load_examples.jl) rather than in one-file-per-model moves.

For the current interpretation of the categories and the main known failure classes, see:

- [2026-03-17_model_taxonomy.md](../../docs/internal/2026-03-17_model_taxonomy.md)

- `GREEN_MODELS`
  Straightforward maintained examples that currently run well.
- `STRUCTURAL_UNIDENTIFIABILITY_MODELS`
  Models kept specifically as identifiability demonstrations.
- `HARD_MODELS`
  Models that run, but are harder, less accurate, or more experimental.
- `LIMITATION_MODELS`
  Models retained in-package for known limitations, active failures, or future work.
- `STANDARD_MODELS`
  The default runnable set: `GREEN_MODELS` plus `STRUCTURAL_UNIDENTIFIABILITY_MODELS`.

### Maintained

These are part of the intended package-facing examples surface and should stay current with the supported contract.

- [models](models)
- [load_examples.jl](load_examples.jl)
- [first_example.jl](first_example.jl)
- [run_examples.jl](run_examples.jl)
- [control_investigations](control_investigations)
- [biohydrogenation](biohydrogenation)
- [cstr_adiabatic](cstr_adiabatic)

### Continuing research

The [research examples](https://github.com/orebas/ODEParameterEstimation.jl/tree/research/src/examples)
retain the interpolator comparison, paper runner, profiling, benchmarks,
failure investigations, and one-off analysis scripts. Use that branch to
continue those studies. Cherry-pick selected core fixes into it; merging the
`main` cleanup commit would remove the preserved experiments.

## Generated Artifacts

Generated artifacts should not be committed as part of the examples surface.

Examples:

- saved polynomial systems
- logs
- plots
- output CSVs and similar run products

The main `.gitignore` now explicitly ignores the common example-output locations.
