# Dense synthetic single-experiment studies

This small study separates basic ODEPE recovery from the sparse, noisy,
multi-experiment PEtab comparison. It uses one condition each from Bruno, Fujita,
and Sneyd, with 201 noise-free samples per observable over the original physical
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
python3 repro/petab/dense_single/supervise.py sneyd /tmp/dense-sneyd --seconds 900
python3 repro/petab/dense_single/supervise.py sneyd_profile /tmp/sneyd-denominators --seconds 180
python3 repro/petab/dense_single/report.py /tmp/dense-bruno /tmp/dense-fujita /tmp/sneyd-denominators
```

Use fresh output directories. `ODEPE_PETAB_ENV` and `ODEPE_PETAB_MODEL_ROOT` override
the environment and canonical model checkout. The default checkout is the same
`ddaa86d13f708926c57ec8918ce75a6b50e2e562` revision as the original PEtab pilot.
The supervisor allows up to 600 seconds for package loading and preparation;
the requested estimation limit starts immediately before the normal estimator,
including its compilation and structural analysis. For `sneyd_profile` it starts
just before the isolated original `clear_denoms` call. This is not an HC-only limit.

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

`inspect_fujita_pool.jl` reconstructs only the low-level SIAN polynomial pool,
with multiplicity disabled through the existing keyword; it does not run global
SI or estimation. `inspect_fujita.py` uses the existing Python environment's
SymPy to count support in the saved template or reconstructed JSON pool.
`inspect_sneyd_gcd.jl` traces GCD inputs in an isolated process; its only method
replacement adds recording before calling the same GCD backend. Bound it with
an external timeout, as polynomial expansion can prevent reaching the GCD hook:

```sh
timeout --signal=INT --kill-after=15s 240s julia --startup-file=no --compiled-modules=existing repro/petab/dense_single/inspect_fujita_pool.jl /tmp/fujita-pool.json
/tmp/odepe-pypesto-env/bin/python repro/petab/dense_single/inspect_fujita.py /tmp/fujita-pool.json /tmp/fujita-support.json
timeout --signal=INT --kill-after=15s 210s julia --startup-file=no --compiled-modules=existing repro/petab/dense_single/inspect_sneyd_gcd.jl /tmp/sneyd-gcd.json
```

The [anatomy follow-up](../../../docs/2026-09-11_symbolic_system_anatomy.md)
contains the resulting counts, representative equations, and interpretation.

## September 14 follow-up

The [follow-up record](../../../docs/2026-09-14_dense_single_followup.md) resumes
the dense studies after the reusable-polisher fix. Its compact evidence is in
[`evidence/followup_20260914/`](evidence/followup_20260914/). The normal Sneyd
estimator now finishes SIAN rank construction, then exceeds its global-SI budget.
The following Fujita studies isolate solver work on the retained 85-equation
SIAN basis; they do not estimate parameters from the synthetic observation grid.

Python diagnostics use the existing Python installation's SymPy, NumPy, and
SciPy. `reduce_fujita_jets.py` requires the adjacent independently retained
`fujita_full_pool_support.json` as an input cross-check. Every eliminated variable
has a constant-coefficient defining equation, with exact reconstruction checks.
Only the 85-, 75-, and 55-variable snapshots used by HC are committed; the other
snapshots can be regenerated and their original hashes are retained.

```sh
python3 repro/petab/dense_single/inspect_sneyd_rates.py /tmp/dense-sneyd/result.json /tmp/sneyd-rates.json
python3 repro/petab/dense_single/reduce_fujita_jets.py repro/petab/dense_single/evidence/fujita_full_pool.json /tmp/fujita-reduced
python3 repro/petab/dense_single/compare_mixed_volume.py /tmp/fujita-reduced /tmp/fujita-mv --sizes 85 75 55 --seconds 180
python3 repro/petab/dense_single/compare_mixed_volume.py /tmp/fujita-reduced /tmp/fujita-mv-reordered --sizes 85 75 --ordering few_terms --seconds 180
python3 repro/petab/dense_single/make_fujita_start_pair.py repro/petab/dense_single/evidence/fujita_full_pool.json /tmp/fujita-starts.json
python3 repro/petab/dense_single/supervise.py fujita_tracking /tmp/fujita-tracking --input /tmp/fujita-starts.json --seconds 180
python3 repro/petab/dense_single/supervise.py fujita_discovery /tmp/fujita-discovery --input /tmp/fujita-starts.json --seconds 240
python3 repro/petab/dense_single/verify_fujita_tracking.py repro/petab/dense_single/evidence/fujita_full_pool.json /tmp/fujita-discovery /tmp/fujita-discovery/verification.json
```

Mixed-volume workers have independent 180-second loading and operation budgets,
and at most three workers run concurrently. Their latest version records the
tropical-regeneration stage and completed mixed cells. An independent canary
returns mixed volume 2 for x² − d = 0, y − x = 0. These are torus volumes, not
affine root counts.

`make_fujita_start_pair.py` draws physical coordinates using a fixed seed and
forward-generates exact state/observation jets. All three fixtures satisfy the
full 88-equation pool over ℚ. They use no published parameter values or fitted
observations. `fujita_tracking` supplies one root and compares straight parameter
tracking with γ-straight tracking; every finite endpoint is checked against the
full pool and the independently generated target root. `fujita_discovery` first
runs HC's existing monodromy solver with a 120-second internal timeout, then
tracks the roots found to both targets. Monodromy's heuristic root deduplication
and no-progress stopping rule do not certify completeness.

The supervisors snapshot the actual Julia worker and Python supervisor for
these HC diagnostics. Older measurement snapshots are retained unchanged,
including the original direct `HC.mixed_volume` worker. The reordered measurement
snapshot preceded a counter-scope correction; it never returned a mixed cell
and thus never executed that counter increment. The corrected counter loop is
validated by the volume-2 canary.

## SI request audit and longer mixed-volume run

The [SI cost report](../../../docs/2026-09-14_identifiability_cost_and_mixed_volume.md)
supersedes the earlier monodromy recommendation. That diagnostic remains
reproducible, but its two successful exact targets do not establish robust
runtime or root completeness.

`probe_si_cost.jl` reimports a retained single-condition model, verifies its
physical equations and observable definitions against the saved report, uses
the retained data for ordinary rescaling, and calls SI directly. It bypasses
SIAN, multiplicity computation, interpolation, and HC, so it measures only the
selected SI request after loading/preparation. `--seconds` limits the complete
SI operation (including repeated local trials), not each trial independently.

```sh
python3 repro/petab/dense_single/supervise.py si_sneyd /tmp/si-sneyd-local --si-mode local --seconds 600
python3 repro/petab/dense_single/supervise.py si_fujita /tmp/si-fujita-local --si-mode local --seconds 600
python3 repro/petab/dense_single/supervise.py si_fujita /tmp/si-fujita-global --si-mode global --seconds 600
python3 repro/petab/dense_single/supervise.py si_sneyd /tmp/si-sneyd-absent --si-mode functions_absent --seconds 600
python3 repro/petab/dense_single/supervise.py si_sneyd /tmp/si-sneyd-fixed --si-mode local_fixed --seconds 600
python3 repro/petab/dense_single/supervise.py si_fujita /tmp/si-fujita-fixed --si-mode local_fixed --seconds 600
python3 repro/petab/dense_single/compare_mixed_volume.py repro/petab/dense_single/evidence/followup_20260914/fujita_reduction /tmp/fujita-mv-long --sizes 85 --ordering original --seconds 1800
```

`local` uses single-experiment probability 0.999 and three seeds, retaining both
individual identifiability and SI's coordinate transcendence basis. `global`
uses the original probability 0.99. `functions_absent` disables only final
generator simplification; `functions_standard` is available for comparison.
`local_fixed` additionally substitutes the returned parameter basis at ones
and distinct positive rationals, then repeats local analysis of the remaining
parameters and states at three seeds. That mode asserts the basis contains
only parameters; it is not a general state-fixing implementation.

The mixed-volume rerun uses the same 85-equation SIAN basis and original order,
with ten times the earlier stage budget. Source snapshots and input hashes are
retained with each run under
[`evidence/si_cost_20260914/`](evidence/si_cost_20260914/). The baseline algorithm
itself is unchanged by these probes.
