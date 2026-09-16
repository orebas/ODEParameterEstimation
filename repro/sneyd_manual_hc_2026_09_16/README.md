# Manual joint Sneyd estimation with exact prepared derivatives

See [the report](../../docs/2026-09-16_sneyd_manual_hc.md).
This is an independent oracle-data experiment, not a production estimator change.

`build.py` constructs all nine conditions with their common known preparation,
generates exact first/second/third rooted derivatives, and performs exact
data-dependent elimination. It exports all remaining condition equations and
an equivalent basis obtained by constant row operations. `oracle.json` is
separate from `system.json`; HC never reads the oracle or receives a truth root.

Requirements used: Python 3.14.4, SymPy 1.14.0, mpmath 1.3.0; Julia 1.13.0,
HomotopyContinuation 2.22.4, JSON 1.8.0 from the existing PEtab pilot environment.
No dependency resolution or package installation was performed. Input model:
`Benchmarking-Initiative/Benchmark-Models-PEtab` revision
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`, folder
`Benchmark-Models/Sneyd_PNAS2002`. The helper imported from the preceding
prepared-jet study checks the model against the SBML equations and observable.

From the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 repro/sneyd_manual_hc_2026_09_16/build.py \
  --model-dir /path/to/Benchmark-Models-PEtab/Benchmark-Models/Sneyd_PNAS2002

JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --compiled-modules=existing \
  repro/sneyd_manual_hc_2026_09_16/solve.jl \
  repro/sneyd_manual_hc_2026_09_16/evidence/moderate/system.json \
  repro/sneyd_manual_hc_2026_09_16/evidence/moderate/hc.json \
  repro/sneyd_manual_hc_2026_09_16/evidence/nominal/system.json \
  repro/sneyd_manual_hc_2026_09_16/evidence/nominal/hc.json

JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --compiled-modules=existing \
  repro/sneyd_manual_hc_2026_09_16/float_polyhedral.jl \
  repro/sneyd_manual_hc_2026_09_16/evidence/nominal/system.json \
  repro/sneyd_manual_hc_2026_09_16/evidence/nominal/hc_float.json

PYTHONDONTWRITEBYTECODE=1 python3 repro/sneyd_manual_hc_2026_09_16/validate.py \
  --model-dir /path/to/Benchmark-Models-PEtab/Benchmark-Models/Sneyd_PNAS2002
```

The Julia scripts activate `ODEPE_PETAB_ENV`, defaulting to the existing
`/tmp/odepe-petab-pilot-env`. For the sandboxed recorded run, a writable first
depot was supplied with
`JULIA_DEPOT_PATH=/tmp/odepe-sneyd-manual-depot:/home/orebas/.julia`, retaining
access to the installed packages. The ordinary depot initially rejected Pkg's
manifest-usage log write; redirecting that write allowed the run without a
dependency change. Julia loading emitted undeclared-import warnings, retained
in the logs; the numerical and symbolic checks subsequently completed.

Evidence per parameter set:

- `system.json`: exact rational polynomial coefficients, all oracle jets and
  known inputs, data-derived combinations, row-reduced equivalent equations,
  excluded denominators, and independently selected square rows.
- `oracle.json`: generating parameters and expected combinations, used only
  by construction assertions and validation.
- `hc.json`: all path codes, returned complex vectors, timings, compilation
  timings, rational coefficient roundtrip checks, and certification counts
  where applicable. Failed entry-point calls are retained.
- `hc_float.json`: nominal-value polyhedral controls with an explicit Float64
  coefficient cast, with certification attempted against the exact system.
- `validation.json` / `validation_float.json`: exact elimination certificate,
  unrefined HC recovery errors, positivity/reality checks, and separate
  100-digit refinement against the full-data row-reduced equations.

Refinement can move a root of a selected subsystem to the unique solution of
the full system. The recorded *unrefined* errors and physical checks determine
whether an HC candidate itself recovered the generating model; do not count
every successful refinement as a correct initial HC result.

The original quartic derivatives of orders 4–6 are also generated. Recovering
the positive rooted derivatives from them gives exactly the same input system.
This is not a separate enumeration of all complex fourth-root branches.

These scripts assume exact consistent oracle derivatives. Exact row reduction
of an overdetermined system with noisy data is not an estimator proposal.
