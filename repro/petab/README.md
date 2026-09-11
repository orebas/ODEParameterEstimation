# Canonical PEtab pilot

Run from the ODEPE repository root. Julia commands always disable startup files.
The bootstrap reads the current global dependency versions and development
paths, then creates `/tmp/odepe-petab-pilot-env`. It does not edit the global
Project or Manifest. `ODEPE_PETAB_ENV` overrides the destination.

```sh
julia --startup-file=no repro/petab/setup.jl

git clone https://github.com/Benchmarking-Initiative/Benchmark-Models-PEtab.git /tmp/odepe-petab-models
git -C /tmp/odepe-petab-models checkout ddaa86d13f708926c57ec8918ce75a6b50e2e562

uv venv --python 3.14 /tmp/odepe-pypesto-env
uv pip sync --python /tmp/odepe-pypesto-env/bin/python repro/petab/python-requirements.lock.txt

julia --startup-file=no repro/petab/test.jl
ODEPE_PETAB_MODELS=/tmp/odepe-petab-models/Benchmark-Models julia --startup-file=no repro/petab/check_adapter.jl

python3 repro/petab/run_pilot.py \
  --model-root /tmp/odepe-petab-models/Benchmark-Models \
  --output repro/petab/results
python3 repro/petab/summarize.py repro/petab/results --require-complete
```

AMICI model compilation needs a C/C++ compiler and CMake. The Python lock
includes SWIG. Julia Fides maintains its own Python environment through
CondaPkg; this is separate from the AMICI environment. The Julia environment
snapshot and dependency report accompany the retained pilot artifacts.

`targets.toml` fixes the model revision, seed, main/challenge lists and time cap.
The supervisor verifies the checkout revision, refuses incomplete existing cells,
and skips completed attempts. It never silently retries failures. Use a new
output directory for a new campaign. `--models` and `--methods` select a subset.
For a Python-only run, first generate the shared start record with a Julia method.

Each method runs in a separate process. Package loading is excluded, with a
separate 30-minute load watchdog. Model import, translation, compilation, initial
objective evaluation and estimation count toward the 900-second budget. A timed
out attempt retains its latest checkpoint. Julia and Python baselines use
Fides/BFGS, identical vectors mapped by parameter ID, and the same default Fides
termination tolerances. Solver choices and preparation costs differ. The two
nonautonomous Julia models use QNDF to avoid an upstream Rosenbrock time-gradient
compatibility error. This configuration is shared by Julia baseline and ODEPE
refinement.

Results distinguish the raw algebraic PEtab objective from subsequent exact
likelihood refinement. Successful termination is not proof of a global optimum.
One start, development-era configuration changes and overlapping workers do not
support speed or reliability rankings. `development_attempts.json` records
implementation retries; those reuse the same vector and are not new starts.

## Small experiment groups

The optional methods `odepe_blocks2`, `odepe_blocks4`, and `odepe_blocks6` select
the first 2, 4, or 6 conditions in canonical measurement-row order. They share
parameters across local state blocks, build observation jets through at most
order four by default, and apply the core multipoint basis selector to the combined pool.
`--max-derivative-order 10` explicitly raises the cap (accepted range: 0–10).
Only states outside every measured signal's ODE dependency closure are omitted.
The original full PEtab objective is used for both scoring and refinement.

```sh
python3 repro/petab/run_pilot.py \
  --models Bruno_JExpBot2016 --methods odepe_blocks2 odepe_blocks4 \
  --output repro/petab/new_block_results
```

Copy a model's existing `MODEL.start.json` into the new output directory to reuse
an exact earlier start; otherwise the same seeded scaled-bounds sampler is used.
Never overwrite `pilot_results`. The retained `block_results` starts are copies
of that original pilot. Each checkpoint records the active construction stage,
equation count, unknown count, and numerical rank. A deficient capped pool
is a bounded construction result, not a structural-identifiability conclusion.
Successful small groups may leave parameters of other conditions at the recorded
start until the full-objective optimizer refines them.

The [experiment-block record](../../docs/2026-09-11_petab_experiment_blocks.md)
reports these attempts separately from the original 30-cell pilot.

The separate `derivative10_results` directory retains the requested higher-cap
Fujita and Sneyd trials. `inspect_blocks.jl MODEL GROUP_SIZE CAP OUTPUT_JSON`
reconstructs a selected system without interpolation or solving and records its
equations, variable mapping, degrees, monomial counts, and loose total-degree
bound. Run it with Julia's `--startup-file=no --compiled-modules=existing` flags.
It uses the existing optional environment and canonical model checkout.

`/tmp/odepe-pypesto-env/bin/python repro/petab/explain_bruno.py` independently
re-evaluates the recorded Bruno vectors by matrix exponentiation of the canonical
SBML model. It writes the full 77-row prediction table, raw state comparisons,
likelihood decomposition, and PNG/PDF plots to `bruno_explained` without fitting.
See the [detailed explanation](../../docs/2026-09-11_petab_derivatives_and_bruno.md).

The checked-in `pilot_results/*.json` files retain successes, unsupported cases,
timeouts and failure reasons. Generated AMICI models, ready markers, verbose
logs and environment/bootstrap failures are ignored. Newer worker records also
include source/environment digests and thread controls; earlier pilot records
predate that instrumentation and must not be described as having those fields.
Perelson's stored zero `preparation_residual` also predates the diagnostic fix
that checks every fixed initial-state constraint; it is not evidence of exact
algebraic preparation. Its reported PEtab objectives already enforced the
original preparation. Early rejected-candidate records lack the raw states and
provenance that the current adapter retains.

```sh
# Core gates use the original dependency environment, without PEtab:
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark
```

See [the public API and limitations](../../docs/petab.md) and
[the implementation/results record](../../docs/2026-09-10_petab_pilot.md).
