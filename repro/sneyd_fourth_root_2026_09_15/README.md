# Sneyd: change only the observation to its positive fourth root

This research harness compares `y = (0.9 A + 0.1 O)^4` with
`z = fourth_root(y) = 0.9 A + 0.1 O`. It transforms the same 201 retained,
noiseless samples **before interpolation**. One experimental condition, the
time grid, six hidden states, and six freely estimated initial values are
preserved. It does not observe all states, add a population-normalization
constraint, or replace the model with characteristic coefficients.

Two dynamics are available:

- `free`: the previous nine-independent-rate model, including the shared
  return rate. This remains the same separate inference problem as the earlier
  free-coefficient study.
- `rational`: the original fourteen kinetic parameters and their rational
  reaction-rate maps, imported by a frozen copy of the previous native dense
  single-condition constructor.

Run from the global Julia environment through the Python supervisor. The
worker activates the **existing** optional PEtab environment internally. No
package resolution, installation, or dependency changes are performed.
The recorded run uses Julia 1.13.0, the optional environment at
`/tmp/odepe-petab-pilot-env`, and the Benchmark-Models-PEtab checkout at
`/tmp/odepe-petab-full-20260910` (revision
`ddaa86d13f708926c57ec8918ce75a6b50e2e562`). Set `ODEPE_PETAB_ENV` and
`ODEPE_PETAB_MODEL_ROOT` to existing equivalents when reproducing elsewhere;
the latter points to the checkout's `Benchmark-Models` subdirectory.

```sh
python3 repro/sneyd_free_coefficients_2026_09_15/prepare.py /tmp/sneyd-root-spec.json
python3 repro/sneyd_fourth_root_2026_09_15/supervise.py \
  /tmp/sneyd-root-spec.json /tmp/sneyd-free-root \
  --model free --observation root --phase estimate --seconds 1800
```

All output paths must be fresh. Use `--observation quartic` for the matched
control and `--model rational` for the original kinetic model.

## Available probes and budgets

| Phase | Request | Estimation/operation-stage budget |
|---|---|---:|
| `estimate` | Normal estimation, M unknown, selection MV disabled; ordinary polyhedral generic-start solve | 1,800 s |
| `selection` | Normal template and subsystem selection with MV scoring enabled; capture and stop before generic-start solving | 1,200 s |
| `multiplicity` | Representative-fixed production multiplicity input, followed by default QQ Gröbner/quotient counting | 2,400 s |
| `global` | SI full parameter-and-state identifiability classification | 600 s |
| `functions` | SI identifiable functions, `simplify=:absent`, `with_states=false` | 600 s |
| `denominators` | Old eager request: clear denominators of the second Lie derivative before structural fixing | 600 s |
| `local` | Optional local-classification diagnostic | 600 s |

`--seconds` sets the budget; the table records intended comparison budgets,
not hardcoded phase-dependent defaults. Loading and preparation have a
separate 600 s watchdog. Julia and BLAS each use one thread. Workers can run
concurrently, so single-run wall times are diagnostics rather than a rigorous
speed benchmark. The supervisor records its status separately from the
worker's status and sends periodic profiling signals.

The completed campaign runs both observations for `free/estimate`,
`rational/estimate`, and `rational/denominators`. It also runs the rooted
`rational/functions`, `rational/multiplicity`, and `rational/selection` probes,
compared with the previously retained quartic attempts. There are nine final
workers and three fresh pairs; `global` and `local` are available diagnostics,
not additional standalone runs in this campaign. See the
[results record](../../docs/2026-09-15_sneyd_fourth_root.md) for the distinctions
between stage budgets, operation time, historical controls, and actual errors.

The estimator retains the previous nine interpolators, 20 warped shooting
anchors, root polishing, bounded trajectory polishing, and no terminal
optimizer fallback. The free-rate arm is single point; the rational arm
retains its previous two-point multipoint configuration (15 pairs). A failure
at the first generic system means the remaining anchors/interpolators and MP
stage have not been exercised.

The nine interpolators are the configured list. The unchanged automatic noise
heuristic can filter that list even for clean data with a fast transient;
records and logs distinguish configured and effective interpolators. In
particular, the rooted free-rate signal triggers the AAAD threshold. Both arms
still begin with AGPRobust and the same generic algebraic-solver request.

## Interpretation and isolation

- Within a model/phase pair only the observation equation and corresponding
  samples change. Constructor, seed, bounds, and algorithm options match.
  Normal automatic power-of-two rescaling stays enabled and is recorded;
  any differences it induces are reported explicitly.
- Historical `M=544` is **not** supplied to rooted estimation. Both observation
  arms estimate with M unknown. The separate M probe uses the earlier fixed
  coordinate slice in both arms and verifies a consistent exact synthetic
  sample before counting. It retains all constraints and saturation.
- The observation transformation does not certify that the structural slice
  obtained by fixing parameters to one contains a positive representative.
  In particular the earlier free-rate positivity obstruction is not repaired.
- A candidate's fitted error belongs to its active observation. Returned
  trajectories are separately rescored on both the original `y` and rooted
  `z` scales using their reported initial-state time. Rankings are never
  chosen using the generating parameter values.
- `capture_and_solve.jl` instruments a fresh research process, captures the
  exact selected HC system, then invokes the unchanged production method.
  Empty generic starts terminate that diagnostic rather than silently
  repeating fresh solves at every anchor. The selection-only phase stops at
  the capture boundary.
- This is a clean-data experiment. The real noisy PEtab measurements and
  their Gaussian likelihood are not transformed or fitted here.

Every run snapshots its research sources and input. Records include hashes,
dependency versions, model equations, generating values, bounds, data,
rescaling, all estimation options, timing checkpoints, and captured polynomial
systems when reached. Harness setup failures are retained separately from
mathematical outcomes.

The promising `free/root/estimate` worker was extended from 1,800 to 5,400 s
after it completed mixed-volume setup and found a nonsingular generic root.
`extend_running.py` verifies and pauses only that run's original Python
supervisor, monitors the same Julia process, and restores the supervisor to
reap it. It changes no Julia solver state. The original 1,800 s checkpoint,
original supervisor report, and explicit extension report are retained
separately. A fresh reproduction of the longer run can simply specify
`--seconds 5400`.

Two additional exact checks are available:

```sh
python3 repro/sneyd_fourth_root_2026_09_15/compare_captures.py \
  /tmp/sneyd-free-quartic /tmp/sneyd-free-root /tmp/sneyd-family-comparison.json
python3 repro/sneyd_fourth_root_2026_09_15/free_rate_side_count.py \
  /tmp/sneyd-root-spec.json /tmp/sneyd-free-reference-count.json --seconds 60
```

The first verifies the full captured dynamical and observation equations in
physical units. The second counts the small characteristic map only as a side
diagnostic; it does not substitute that model into estimation or change HC's
stopping rule.

`julia --startup-file=no repro/sneyd_fourth_root_2026_09_15/validate_scores.jl SPEC OUTPUT`
checks the trajectory-rescoring helper using the generating parameters and
rejects an incorrect report time. These are validation inputs, not recovered
estimates.

Completed worker directories are retained under `evidence/` with lossless gzip
compression. Each run's `manifest.json` records both original and compressed
SHA-256 hashes. For example, decompress a run into a fresh scratch directory
before passing it to `summarize.py` or `compare_captures.py`. The retained
`source/` files are the exact sources executed by that worker; setup attempts
are stored separately and excluded from the result summary.
