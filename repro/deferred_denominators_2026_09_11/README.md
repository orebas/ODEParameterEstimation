# Deferred denominator construction validation

This checks the scheduling change in `populate_derivatives` and the PEtab
experiment frontier. It does not change fraction simplification, derivative
limits, identifiability, or polynomial basis scoring.

## Package gates

Run from the global Julia environment containing this development checkout:

```sh
julia --startup-file=no test/current.jl test_deferred_derivatives.jl
julia --startup-file=no test/current.jl unit
julia --startup-file=no test/current.jl
julia --startup-file=no test/current.jl benchmark
julia --startup-file=no --compiled-modules=existing repro/petab/test.jl
```

`test/current.jl` uses `Pkg.test(...; allow_reresolve=false)`. The optional PEtab
contracts use the existing pilot environment; no dependency resolution is needed.

## Rational benchmark inputs

The fixtures retain complete data and extract model definitions from previous
benchmark runs. Each `source.json` records source paths and SHA-256 hashes. The
original launch code is not executed. No rows are downsampled.

| Model | Source case | Samples per observable | Nominal noise | Denominators |
|---|---|---:|---:|---|
| Biohydrogenation | Numbat May 14, instance 2 | 750 | 10⁻⁶ | States and parameters |
| Repressilator | Multipoint March 26, instance 1 | 1,501 | 10⁻⁴ | States and parameters |
| FitzHugh–Nagumo | FINAL6, instance 1 | 1,001 | Clean | Parameter `g` |

`run_rational.jl` checks the data against the generating ODE before estimating.
It uses the normal estimator with the current nine default interpolators and
ordinary noise filtering, 20 warped anchors, two-point systems with up to 15
pairs, algebraic polish, and bounded logarithmic trajectory polish. Bounds are
the benchmark's broad `[10⁻⁵, 10]` box. Trajectory polish is capped at 120 seconds
per candidate. Terminal direct optimization and UQ are disabled. All actual
options and effective interpolators are saved in `result.toml`.

The returned fit-based ranking is preserved. Recovery against generating truth
is reported for every returned branch, alongside first-ranked and best-of-branch
maximum relative parameter errors. Individual state errors and identifiability
flags are retained; biohydrogenation's unobserved `x7` is not a parameter-recovery
criterion. These are regression checks, not comparative throughput measurements.
The worker's `complete` status means it returned ranked candidates; recovery
accuracy must be assessed from the recorded errors.

```sh
python3 repro/deferred_denominators_2026_09_11/supervise.py biohydrogenation /tmp/deferred-biohydrogenation --seconds 3600
python3 repro/deferred_denominators_2026_09_11/supervise.py repressilator /tmp/deferred-repressilator --seconds 3600
python3 repro/deferred_denominators_2026_09_11/supervise.py fitzhugh_nagumo /tmp/deferred-fhn --seconds 3600
```

The runner fixes Julia and BLAS thread counts to one, retains a worker log and
phase timings, takes sampling profiles during long work, and records external
timeouts separately from worker results. Output directories must be new.
An optional `--julia-optimize 0` runs a separate compiler diagnostic with the
same estimator settings and lower LLVM optimization. The supervisor records
the exact Julia command so such runs cannot be confused with the default run.

```sh
python3 repro/deferred_denominators_2026_09_11/supervise.py biohydrogenation /tmp/deferred-biohydrogenation-o0 --seconds 3600 --julia-optimize 0
```

`retain_evidence.py WORKER_OUTPUT EVIDENCE_FILE` keeps all recovery coordinates,
options, progress messages, phase summaries, and source hashes in compact JSON. Full individual
timing records and the large serialized estimator-identity string remain in
the original worker output and are explicitly listed as omitted from the copy.
It also renames the worker's `raw_count` field to `preclustering_candidate_count`:
that count is taken after result processing and possible branch replacement,
so it does not necessarily count the original algebraic candidates.
The extracted model fixtures and saved polynomial/patch snapshots retain their
original whitespace to preserve the recorded hashes.

## Previous-producer compatibility

This probe loads the exact producer from the recorded base Git revision into a
separate process. It compares rational/cleared tables and the numerical Jacobian
on the retained biohydrogenation model, including its existing overflow guard.

```sh
julia --startup-file=no --compiled-modules=existing repro/deferred_denominators_2026_09_11/run_compatibility.jl /tmp/deferred-compatibility.toml
```

## Sneyd construction check

This requires the existing PEtab pilot environment and benchmark checkout used
by `repro/petab/dense_single/common.jl`. It runs one condition through derivative
order 3, crossing the previous order-2 clearing bottleneck. Its expected outcome
is a rank-deficient pool with **zero calls to polynomial construction**. It does
not attempt parameter recovery or a structural-identifiability certificate.

```sh
python3 repro/deferred_denominators_2026_09_11/supervise.py sneyd /tmp/deferred-sneyd --seconds 600
```

Measured outcomes and their limits are recorded in
[`docs/2026-09-11_deferred_denominator_construction.md`](../../docs/2026-09-11_deferred_denominator_construction.md).
