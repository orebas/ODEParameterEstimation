# Codex handoff — noise-frontier timing + receptor rerun

Created: 2026-06-06T23:32:33-04:00.

## Why this note exists

We are switching tasks. This records the recent ODEPE changes and the live receptor
timing run so we can resume without reconstructing context from logs.

Immediate question when we return: **did the new noise-frontier/system-hoisting work
materially reduce receptor wall time, and where is the remaining time going?**

## Code work just done

Local repo: `/home/orebas/.julia/dev/ODEParameterEstimation`.

Implemented in ODEPE:

- `with_estimation_timing(f)` and `timing_breakdown_to_dict(timing)` exported from
  `src/ODEParameterEstimation.jl`.
- `src/core/optimized_multishot_estimation.jl` now records structured timing even
  when `profile_phases=false`.
- Single-point noise-frontier construction is cached across interpolators.
- Single-point `:generic_start` HC solves are cached by polynomial-system structure.
- Multipoint template construction is cached across interpolators.
- Multipoint `:generic_start` HC solves are cached by multipoint polynomial-system
  structure and passed into `solve_multipoint_parameterized`.
- Timing details now include:
  - `single_point_frontier_seconds_by_source`
  - `single_point_generic_start_seconds_by_source`
  - `multipoint_template_seconds_by_source`
  - `multipoint_generic_start_seconds_by_source`
  - `multipoint_eval_seconds_by_source`
  - `multipoint_solve_seconds_by_source`
  - `noise_frontier_*_cache_hits/misses`
  - `sp_generic_start_cache_hits/misses`
  - `mp_generic_start_cache_hits/misses`
  - `resolve_states_with_fixed_params_summary`
  - `resolve_states_with_fixed_params_records`
- `src/core/si_template_integration.jl` records per-call resolver timing for:
  `ordered_model`, `fixed_model`, `sian_rerun`, `ensure_template_dd`,
  `instantiate`, `hc_solve`, `cascading`, and `cascade_hc_solve`.
- Resolver calls are tagged with contexts, currently including
  `:backsolve_recovery` and `:synthesis`.
- `src/core/synthesize_aggregates.jl` wraps synthesis resolve calls in the timing
  context.
- The benchmark template in
  `/home/orebas/ParameterEstimationBenchmark-local/templates/julia_template_for_estimation_odepe_v2.jl`
  now stores `metadata["timing"]`.

Validation already run after the final guard patch:

- `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/fast_core.jl")'`
  passed: 349/349.
- `julia --startup-file=no -e 'using ODEParameterEstimation; include("test/feature_regressions.jl")'`
  passed: 133/133.
- `git diff --check` was clean in ODEPE and the benchmark-template repo.

No commit was made.

## Dirty worktree caveat

Before this work there were unrelated dirty/untracked files. Leave them alone unless
Oren explicitly asks:

- `artifacts/diagnostics/forced_decay_polynomialized/report.html`
- `artifacts/diagnostics/forced_decay_polynomialized/summary.txt`
- `repro/receptor_fast_probes_2026_05_28/out/variable_cost_trim.jsonl`
- untracked `repro/noise_frontier_e2e_2026_06_05/`

The ODEPE files changed by this work are:

- `src/ODEParameterEstimation.jl`
- `src/core/optimized_multishot_estimation.jl`
- `src/core/si_template_integration.jl`
- `src/core/synthesize_aggregates.jl`
- `test/fast_core.jl`

The benchmark repo file changed by this work is:

- `/home/orebas/ParameterEstimationBenchmark-local/templates/julia_template_for_estimation_odepe_v2.jl`

## Baseline receptor run

Existing completed cell, preserved for comparison:

`repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8`

Key facts:

- It completed successfully.
- `wall_time_seconds.txt`: `49461.932530879974` seconds, about 13.7 hours.
- No new `metadata["timing"]` payload because that script predated the wrapper.
- `odepe_metadata.json` status was `ok`.
- `raw_count = 2`, `best_count = 2`.
- Best max relative error was about `0.05306409520241273`.
- Best solution source was branch completion:
  `interpolator_source = "branch_completion"`,
  `source_type = "branch_completed"`,
  notes included `branch_completion` and `branch_completion_replaced`.

## Active receptor timing run

Fresh cell, copied from the baseline receptor cell so we do not overwrite old
artifacts:

`repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606`

Changes versus baseline:

- Same data/options/script structure.
- The solve call in this copied `script.jl` is wrapped with:
  `ODEParameterEstimation.with_estimation_timing()`.
- On completion, `odepe_metadata.json` should include `metadata["timing"]`.

Launch details:

- tmux session: `nf_receptor_timing_20260606`
- process chain at launch:
  - tmux process: `2913357`
  - wrapper bash: `2913360`
  - Julia: `2913361`
- launched with:
  - `JULIA_NUM_THREADS=7`
  - `OPENBLAS_NUM_THREADS=1`
  - `MKL_NUM_THREADS=1`
  - `OMP_NUM_THREADS=1`
- `started_at.txt`: 2026-06-06 around 23:22 local time.

Current observed state at this note:

- `tmux ls` shows `nf_receptor_timing_20260606`.
- Julia process `2913361` is alive.
- `stderr.txt` is active; `stdout.txt` may stay empty for a long time because Julia
  `@info`/warnings are going to stderr.
- The run has progressed past ODEPE precompile diagnostics into receptor
  SI-template construction and mixed-volume calculation.
- Last observed stderr context included:
  - SI template summary: 32 equations, max derivative order 10.
  - final instantiated template: 40 equations, 40 variables.
  - mixed-volume progress lines.

## How to monitor

From repo root:

```bash
tmux ls
tmux attach -t nf_receptor_timing_20260606
ps -o pid,ppid,stat,etime,pcpu,pmem,comm,args -p 2913361
tail -f repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/stderr.txt
tail -f repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/stdout.txt
```

Do not rely only on `stdout.txt`; most diagnostic signal is currently in
`stderr.txt`.

On completion, inspect:

```bash
cat repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/status.txt
cat repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/rc.txt
cat repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/wall_time_seconds.txt
ls -lh repro/noise_frontier_e2e_2026_06_05/receptor_subtype_binding_branch_3_1em8_timing_20260606/result.csv
```

Then inspect `odepe_metadata.json`, especially `metadata["timing"]`.

## What to look for in timing

Primary comparison:

- Baseline wall time: about 13.7 hours.
- New run wall time: `wall_time_seconds.txt` in the timing cell.

Expected useful timing fields:

- Top-level phase list in `metadata["timing"]["phases"]`.
- Cache counters in `metadata["timing"]["details"]`:
  - `noise_frontier_sp_cache_hits`
  - `noise_frontier_sp_cache_misses`
  - `noise_frontier_mp_cache_hits`
  - `noise_frontier_mp_cache_misses`
  - `sp_generic_start_cache_hits`
  - `sp_generic_start_cache_misses`
  - `mp_generic_start_cache_hits`
  - `mp_generic_start_cache_misses`
- Per-source timing dictionaries:
  - `single_point_frontier_seconds_by_source`
  - `single_point_generic_start_seconds_by_source`
  - `single_point_hc_seconds_by_source`
  - `multipoint_template_seconds_by_source`
  - `multipoint_generic_start_seconds_by_source`
  - `multipoint_eval_seconds_by_source`
  - `multipoint_solve_seconds_by_source`
- Resolver timing:
  - `resolve_states_with_fixed_params_summary`
  - `resolve_states_with_fixed_params_records`

The big questions:

- Did SP noise-frontier construction happen once and then cache-hit for later
  interpolators?
- Did SP generic-start solve happen once per structure rather than once per
  interpolator?
- Did MP template and MP generic-start solve happen once per structure?
- How much of the wall is still in MP tracking versus branch completion versus
  backsolve recovery versus polish?
- Are there many `resolve_states_with_fixed_params` calls under
  `:backsolve_recovery`, and are they slow?
- Did accuracy change relative to the baseline `0.05306409520241273` max relative
  error / two branch-completed solutions?

## Gotchas

- `repro/noise_frontier_e2e_2026_06_05/run_detached.sh` launches both receptor and
  biohydrogenation and truncates existing cell logs. Do not use it casually.
- The active timing cell is a fresh directory. Do not overwrite the baseline
  `receptor_subtype_binding_branch_3_1em8` directory.
- `rc.txt` only exists after `run_cell_inner.sh` exits. While the run is active,
  absence of `rc.txt` is expected.
- Historical warning from Claude handoff still applies: `pgrep -f julia` can match
  the checker itself. Prefer explicit `ps -p <pid>` when a PID is known.
- If stdout appears stuck but CPU is high or stderr is advancing, the run is not
  necessarily stuck.
