# Preserving PEtab coefficient definitions

This opt-in experiment starts at the PEtab/SBML boundary. It extracts the
explicit assignment graph and constant reaction coefficients, then tests a
lifted version of the previously frozen Sneyd multiplicity input. It does not
change the normal estimator, structural representative selection, or solver
defaults. The work began September 14; the final record is in
[`docs/2026-09-15_coefficient_lifting.md`](../../docs/2026-09-15_coefficient_lifting.md).

## Capture the adapter structure

Use the existing separate PEtab environment from `../petab/setup.jl`. None of
these commands resolves or changes package versions. Start Julia from the
global environment, as required by the repository instructions.

```sh
julia --startup-file=no --compiled-modules=existing --threads=1 \
  repro/coefficient_lifting_2026_09_14/capture.jl \
  /tmp/odepe-petab-full-20260910/Benchmark-Models/Sneyd_PNAS2002/Sneyd_PNAS2002.yaml \
  Ca_dose_response__1 /tmp/sneyd-coefficients.json
```

`capture.jl` calls the optional extension's `petab_coefficient_structure`.
The returned object includes three named SBML assignments, nine distinct
reaction coefficient maps, compact six-state dynamics, and the source
expressions' denominator exclusions. It checks expansion against the loaded
adapter's vector field. Estimated parameters stay symbolic; published nominal
kinetic values are not used in the construction.

The extractor currently accepts rational parameter-only assignment rules and
linear reaction fluxes in constant unit compartments. Unsupported constructs
raise errors on this experimental entry point; the ordinary adapter is
unaffected. This helper is not a new `estimate_petab_problem` option.

## Build the equivalent multiplicity input

```sh
python3 repro/coefficient_lifting_2026_09_14/build_sneyd.py \
  /tmp/sneyd-coefficients.json /tmp/sneyd-coefficient-comparison
```

This requires the existing Python SymPy environment. It preserves the exact
74-polynomial inspection sample documented in
`../sneyd_groebner_2026_09_14/README.md`. That is the September 14 inspection
sample, not the unrecorded coefficients of the earlier production timeout.

The builder verifies:

- The source coefficient maps reproduce every entry of the frozen SI state
  matrix, after its exact constant coordinate scalings.
- Each of the 61 ODE recurrence polynomials equals its lifted counterpart,
  after substitution, times a factor invertible on the original `Q != 0` domain.
- Each auxiliary coefficient has a unique defining value there: every new
  defining denominator divides a power of the original saturation polynomial.
- Every frozen observation equation and the original `z*Q-1` equation is kept.

The resulting localized coordinate rings are isomorphic, so algebraic
multiplicities are preserved, including singular roots. This is an exact
identity/domain check, not a Jacobian-rank heuristic or numerical residual
comparison. It does not certify that the random inspection sample represents
every possible experimental design.

The comparison lifts the nine **effective rates**, expanding the three named
assignments once while constructing their definitions. Directly introducing
all the intermediate ratios could additionally exclude denominator-zero
cases allowed by the current simplified SI model. That would require separate
domain analysis; it is deliberately not conflated with this comparison.

## Count

```sh
timeout --signal=INT --kill-after=20s 1200s \
  julia --startup-file=no --compiled-modules=existing --threads=1 \
  repro/coefficient_lifting_2026_09_14/count.jl \
  /tmp/sneyd-coefficient-comparison/lifted.json \
  /tmp/sneyd-coefficient-comparison/count_lifted.json
```

The script uses the existing optional environment only to make Nemo, Groebner,
and JSON available; it does not load PEtab or ODEPE. It records the input hash,
production Groebner defaults, monotonic elapsed time, and completion or
interruption. The external timeout includes Julia loading/input construction;
the recorded Gröbner time excludes them. A returned basis uses the library's
default probabilistic algorithm, not formal basis certification.

All output paths must be fresh. `original.json` can be passed to the same
counting script for a matched-input comparison. Concurrent validation runs
are not a controlled runtime benchmark.

The recorded lifted trial reached the 1,200-second limit in the first modular
F4 calculation, without a basis or count. `evidence/count_execution.json`
records the external outcome; `count_lifted.log.gz` preserves the interrupt
trace. That worker exited directly on SIGINT, leaving its raw status at
`running`. Its source is retained in `count_worker_at_run.jl.gz`; the current
worker disables immediate SIGINT exit to allow saving interruption metadata.

## Contracts

```sh
julia --startup-file=no --compiled-modules=existing repro/petab/test.jl
julia --startup-file=no test/current.jl
```

The optional contracts cover nested assignments, condition changes, agreement
with the loaded adapter, source changes, unsupported nonlinear fluxes, source
poles removed by fraction cancellation, finite sign branches, and a double
root whose algebraic multiplicity must survive lifting.
