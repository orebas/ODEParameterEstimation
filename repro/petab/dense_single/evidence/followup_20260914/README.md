# Retained September 14 diagnostics

Interpretation is in
[`docs/2026-09-14_dense_single_followup.md`](../../../../../docs/2026-09-14_dense_single_followup.md).
Reproduction commands are in the [harness README](../../README.md).

- `sneyd/`: promoted ordinary-estimator timeout record, dense data, exact executed
  Julia harness snapshots, and independent effective-rate/matrix-exponential
  analysis. The promoted report retains hashes and excerpts of the original
  timing/profiling artifacts; those full original artifacts remain local.
- `fujita_reduction/`: verified exact-elimination record and the three equation
  snapshots used in the mixed-volume comparison. Hashes for all seven original
  snapshots are retained; their payloads include run-dependent elapsed times.
- `fujita_mv_original/`, `fujita_mv_reordered/`: bounded mixed-volume worker
  results, supervisor results, logs, and executed source. A worker status of
  `interrupted` accompanies an explicit supervisor `timeout`.
- `mv_canary/`: the independent two-equation volume-2 check, with its input.
- `fujita_tracking/`: one supplied root tracked to independent synthetic targets.
- `fujita_discovery/`: monodromy discovery followed by both target homotopies.
  The full result retains every discovered start and every finite endpoint.
  `verification.json` independently evaluates endpoints in the original full
  polynomial pool and checks numerical separation. The outer run completes;
  its nested monodromy call returns a partial set with status `timeout`.
- `environment.json`: unchanged Julia environment hashes, dependency versions,
  benchmark revision, and Python package versions.
- `current_harness_sha256.json`: hashes of the final research scripts. These can
  differ from older executed snapshots, which are retained unchanged.

The current source corrects the mixed-cell counter's Julia local scope. The
earlier reordered workers timed out before returning a cell and never executed
that counter increment. The corrected loop is exercised by the canary.

Absolute `/tmp` paths inside records describe the actual execution locations;
the retained inputs and snapshots provide portable reproductions. No public
PEtab likelihood fit or complete generic root count is claimed by these solver
diagnostics.
