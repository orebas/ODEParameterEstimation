# Sneyd: exclude the initial shooting anchor

Research comparison against `../sneyd_fourth_root_2026_09_15`, using its
six-state, nine-independent-rate model and fourth-rooted clean data. All 201
samples remain available to interpolation. The ordinary 20 warped shooting
indices are computed by a copy of the production selector; only index 1 is
removed inside this owned Julia process. The first remaining anchor is
t = 0.0098. Initial conditions at t = 0 remain unknown and are still reported
there. Production source files are unchanged.

Results and interpretation are in
[`docs/2026-09-15_sneyd_interior_anchors.md`](../../docs/2026-09-15_sneyd_interior_anchors.md).
The completed comparison finds initialization failure at every tested time;
the generic p₀-to-p₀ control succeeds for 7/7 unscaled roots and 0/7 after the
existing column scaling.

Run from the repository root with the existing optional dependency environment:

```sh
python3 repro/sneyd_interior_2026_09_15/supervise.py \
  /tmp/odepe-sneyd-free-coefficients-spec-20260915.json \
  /tmp/odepe-sneyd-root-exclude-zero-v1 \
  --cache /tmp/odepe-sneyd-root-start-cache-20260915.json \
  --anchor-mode exclude_zero --seconds 5400
```

Use a fresh output directory. The supervisor snapshots the harness, retains the
prior selected polynomial family, enforces the wall limit, and profiles the
worker. `all` retains the original anchors; `midpoint` selects only index 101.
The matched baseline check applies to `free root estimate`.

The observer checks that the selected polynomial family and generic parameter
point match the previous study before solving. It persists every returned
generic root in unscaled coordinates, with a family fingerprint and environment
identity, so later anchor comparisons can reuse the same pool. This does not
certify that the pool contains every root. Neither the cache nor the observer
uses generating parameters as starts.

Every HC invocation records its input, actual path return codes, final path
vectors, and stopping homotopy coordinate. `residual_at_homotopy_t` is the
residual at that coordinate, not necessarily the target-system residual.
Successful finite paths, failures, and paths to infinity are recorded
separately. The ordinary solver, gamma retries, and fresh-solve fallback are
unchanged.

Removing an anchor can change both automatic column scales and the default
gamma seed, since both depend on the target list. The observer retains all
interpolated derivatives, the scale vector, and the actual gamma values. An
extra evaluation at t = 0 is diagnostic and does not add a shooting location.

The small harness check uses x² − d = 0 to exercise capture, cache reuse, path
recording, and the normal parameterized solver:

```sh
julia --startup-file=no --compiled-modules=existing \
  repro/sneyd_interior_2026_09_15/validate_hooks.jl \
  /tmp/odepe-sneyd-interior-hook-check
```

Once the first run has written `generic_start_solutions.json` and
`parameter_homotopy_1.json`, an independent diagnostic can replay t = 0 and
five selected interior/end times. It uses the identical scale vector and
identical gamma stream for each target, then records successful roots and
their target-system residuals. It calls the ordinary gamma tracker directly,
so an empty result does not invoke a fresh polyhedral solve. It produces no
trajectory fit and does not substitute a different estimator:

```sh
python3 repro/sneyd_interior_2026_09_15/supervise_replay.py \
  /tmp/odepe-sneyd-root-exclude-zero-v1 /tmp/odepe-sneyd-anchor-replay-v1 \
  --seconds 1800
```

The replay reconstructs and checks every captured polynomial coefficient and
exponent before tracking. Its fixed diagnostic gamma stream differs from the
target-list-derived stream in the full run. No finite endpoint from this
diagnostic is called a fitted parameter estimate.

`probe_derivatives.jl MAIN_RUN FRESH_OUTPUT` independently evaluates the first
ordinary interpolator. `compare_derivatives.py SPEC PROBE_JSON OUTPUT_JSON`
compares those derivatives with c Qᵏ exp(Qt) x₀ at 90 decimal digits using
mpmath. These are generator diagnostics only. The completed run's derivative
vectors and scales match this probe exactly.

`check_generic_scaling.jl MAIN_RUN FRESH_OUTPUT` sends the saved generic roots
from p₀ back to the same p₀, first unscaled and then with the full run's column
scales. This separates starting-root initialization from any real-data anchor.
Use Julia with `--startup-file=no` and the existing optional environment, as
in the other scripts.
