# Dense synthetic single-experiment studies

This small study separates basic ODEPE recovery from the sparse, noisy,
multi-experiment PEtab comparison. It uses one Bruno condition and one Fujita
condition, with 201 noise-free samples per observable over the original physical
time interval. Published nominal values are **generating truth**, never fitting
starts. Recovery is reported for the estimator's returned first-ranked result.

`common.jl` extracts the imported condition, proves and removes any invariant
zero states, then removes states with no influence on the measured observables.
The full and reduced simulations must agree to a relative signal tolerance of
`1e-7`. Retained initial states are estimated freely, including published zeros;
this follows the ordinary synthetic benchmark's problem definition.

`run.jl` uses `analyze_parameter_estimation_problem`, not the experimental PEtab
block constructor. It inherits all nine default interpolators and normal noise
filtering, 20 warped shooting points, parameter homotopy, two-point multipoint
systems with 15 pairs, aggregate candidates, and bounded logarithmic least-squares
polishing. UQ is disabled. Differences from the retained PEB configuration are
explicit in every result: original PEtab parameter bounds, nonnegative free ICs,
120 seconds per trajectory polish, and no terminal direct-optimization fallback.

Existing instrumentation is enabled through `RunContext(capture_timing=true)`,
`profile_phases`, `heartbeat`, `diagnostics`, and HC progress. The context is kept
outside the call so completed detailed timing records survive exceptions. The
supervisor additionally requests ten-second Julia sampling profiles. Julia 1.13
also emits compilation traces during these requests; these instrumented, cold
runs are not comparative timing benchmarks. Profile reports may be deferred
until Julia reaches a yield point, so the immediate signal stack in `worker.log`
is useful when an operation never completes.

With the existing optional environment prepared by `../setup.jl`:

```sh
python3 repro/petab/dense_single/supervise.py bruno /tmp/dense-bruno --seconds 1200
python3 repro/petab/dense_single/supervise.py fujita /tmp/dense-fujita --seconds 1200
python3 repro/petab/dense_single/supervise.py sneyd_profile /tmp/sneyd-denominators --seconds 180
python3 repro/petab/dense_single/report.py /tmp/dense-bruno /tmp/dense-fujita /tmp/sneyd-denominators
```

Use fresh output directories. `ODEPE_PETAB_ENV` and `ODEPE_PETAB_MODEL_ROOT` override
the environment and canonical model checkout. The default checkout is the same
`ddaa86d13f708926c57ec8918ce75a6b50e2e562` revision as the original PEtab pilot.
The supervisor allows up to 600 seconds for package loading and preparation;
the requested estimation limit starts immediately before the normal estimator,
including its compilation and structural analysis. For Sneyd it starts just
before the isolated original `clear_denoms` call. This is not an HC-only limit.

`profile_denominators.jl` separately measures construction of the first two
observation derivatives and fraction flattening without polynomial GCD, checks
the flattened expressions numerically, then profiles the existing denominator
helper on the second derivative. It changes no production behavior and does not
claim that the larger flattened polynomial will be cheap for HC to solve.

Local `results/` retain logs, full timing records, sampled profiles, and generated
systems. `report.py` promotes compact evidence and the synthetic data, with
hashes of every original artifact. Promote a run before changing the core checkout:
the reporter records the current clean `src/`/`ext/` revision at first promotion
and preserves it on subsequent refreshes. The retained Bruno and Fujita attempts
also include hash-verified snapshots of their executed Julia harness source.
Results and interpretation are recorded in
[`docs/2026-09-11_dense_single_experiments.md`](../../../docs/2026-09-11_dense_single_experiments.md).
