# Examples Directory

This directory is a mix of model definitions, runnable workflows, investigation scripts, and a small amount of parked material. It is now treated as a maintained package surface, but not every file here has the same status.

## Categories

### Model Buckets

Model constructors are still grouped in shared source files under [models](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/models), so the primary categorization now lives in [load_examples.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/load_examples.jl) rather than in one-file-per-model moves.

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

- [models](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/models)
- [load_examples.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/load_examples.jl)
- [first_example.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/first_example.jl)
- [control_investigations](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/control_investigations)
- [biohydrogenation](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/biohydrogenation)
- [cstr_adiabatic](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/cstr_adiabatic)
- [petab](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/petab)

### Experimental

Useful workflows or driver scripts that are still actively used, but are not polished public examples.

- [run_examples.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/run_examples.jl)
- [compare_interpolators.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/compare_interpolators.jl)
- [paper-runner.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/paper-runner.jl)
- [profiling](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/profiling)
- [benchmarks](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/benchmarks)
- [run_cstr_benchmark.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/run_cstr_benchmark.jl)
- [run_cstr_benchmark_scaled.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/run_cstr_benchmark_scaled.jl)

### Parked / Investigation

These are useful for debugging, reproductions, or one-off analysis, but should not be treated as the primary package example surface.

- [failing](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/failing)
- [hiv_identifiability_test](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/hiv_identifiability_test)
- [debug_bicycle.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/debug_bicycle.jl)
- [build_function_eval_minimal.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/build_function_eval_minimal.jl)
- [build_function_mismatch_demo.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/build_function_mismatch_demo.jl)
- [build_function_varorder_probe.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/build_function_varorder_probe.jl)
- [pointpicker.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/pointpicker.jl)
- [problem_analysis.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/problem_analysis.jl)
- [study_approx.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/study_approx.jl)
- [test_parameter_homotopy.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/test_parameter_homotopy.jl)
- [test_regression.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/test_regression.jl)
- [test_transcendental.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/test_transcendental.jl)
- [test_transcendental_extended.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/test_transcendental_extended.jl)
- [validate_control_systems.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/validate_control_systems.jl)

## Generated Artifacts

Generated artifacts should not be committed as part of the examples surface.

Examples:

- saved polynomial systems
- logs
- plots
- output CSVs and similar run products

The main `.gitignore` now explicitly ignores the common example-output locations.

## Notes

- [run_examples.jl](/home/orebas/.julia/dev/ODEParameterEstimation/src/examples/run_examples.jl) is still a real working driver and should be treated as experimental infrastructure, not disposable junk.
- Future cleanup should move the directory toward a clearer split between maintained workflows, experimental drivers, and parked investigations.
