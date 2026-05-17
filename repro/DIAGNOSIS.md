# Diagnosis — `sirt_treatment_0_1em8` (10.1h cluster wall-clock)

Author: investigation only — no code changes, no run executed.
Date: 2026-05-07

## TL;DR

The dominant cost is the **polish phase**, and there is a real bug that lets polish
runs over-spend wall-clock on hard cases:

> `_polish_single_residual` (the body behind `polish_method = PolishLSOBoundedLog`,
> the v2_polish default) accepts a `maxtime` argument but **never enforces it**.
> The 1200 s wall-clock cap from the script's `polish_maxtime = 1200.0` is silently
> ignored when the polish method is residual-mode (LSO LM or FastLM). Only
> `polish_maxiters = 5000` and the `1e-12` tolerances stop a polish.

That, combined with a candidate-pool that this script's settings inflate to a few
hundred clusters, plus `abstol = reltol = 1e-12` ODE solves inside every LM
iteration's residual-and-Jacobian, is the most likely path to a 10.1 h run on
sirt_treatment.

A second-order issue: **`sirt_treatment` is structurally a "near-flat" polish target.**
The state `Npop` has `D(Npop) ~ 0`; the only observable that constrains it is
`y2 ~ 2000·Npop`, which is linear in `Npop` and independent of all parameters.
The residual landscape for parameters that only multiply `Npop`-scaled bilinear
terms is ill-conditioned, and LSO LM at `tol = 1e-12` will iterate a long time
inside such valleys before declaring convergence (or hitting `maxiters = 5000`).

## Repro contents

| File | Notes |
| --- | --- |
| `script.jl` | machine-generated v2_polish numbat run; key knobs in §"Suspect knobs" |
| `data.csv` | 750 timepoints × 3 observables, additive 1e-8 noise |
| `cell_seed.txt` | `noise_free=3415265780`, `noise=948807732` |
| `README.md` | indicates 10.1 h on a 16-core node; suggests lowering `multipoint_max_pairs` from 15 → 3 or `polish_solutions = false` to confirm |

## Suspect knobs in `script.jl`

```
shooting_points       = 20         # was 12 in bilby (more candidates)
multipoint_n_points   = 2
multipoint_max_pairs  = 15         # up to 15 two-point combos per interpolator
synthesize_aggregate_candidates  ≡ true   (package default since 2026-05)
interpolator list     ≡ package default (~9 interpolators; auto_filter at 1e-8 keeps ~all)
polish_solutions      = true
polish_method         = PolishLSOBoundedLog   # residual-mode LSO LM (bounded log)
polish_maxiters       = 5000        # default is 100 → 50×
polish_maxtime        = 1200.0      # *** SEE BUG BELOW: this is a no-op for residual polish ***
polish_ode_maxiters   = 20000       # default 5000 → 4×
abstol = reltol       = 1e-12       # very tight; drives many ODE steps inside polish
opt_lb / opt_ub       = [1e-5, 10]^9   # bounds passed to LSO natively
terminal_fallback     = :direct_opt # only fires if 0 algebraic solutions
```

Per-polish cost ~∝ `LM_iters · (1 + chunk_jacobian_evals) · per_ODE_solve_cost`.
With `n_unknowns = 4 ICs + 5 params = 9`, ForwardDiff defaults a chunk size near
the input dim, so the Jacobian is ~1 ODE solve with `Dual{9}`. So **each LM
iteration is roughly 2 stiff-tolerance ODE solves over 750 saveat points**.

## How I traced this (annotated)

### 1) Polish-batch sizing — pool is large in this config

`src/core/optimized_multishot_estimation.jl:1809–1898` (multipoint pass) and
`src/core/synthesize_aggregates.jl:706–759` (aggregate synthesis) both feed the
polish pool that `_polish_batch_from_context` consumes at
`src/core/optimized_multishot_estimation.jl:2329`.

Concretely, per interpolator:

- single-point: up to `shooting_points × roots_per_shoot = 20 × N_sp` solutions
- multipoint:   up to `multipoint_max_pairs × roots_per_combo = 15 × N_mp` solutions

…and the loop runs over the **whole interpolator list** (9 by default, since the
`auto_filter_interpolators` noise gate doesn't cut anything at `1e-8`). Then
`_maybe_synthesize_aggregate_candidates` adds:

- Cat A (global param-only aggregates): 9 candidates
- Cat B (per-SP aggregates):             `2 × n_sps`  ≈ 40
- Cat C (per-SP+MP-anchored aggregates): `2 × n_sps`  ≈ 40
- Cat D (cheap extras + per-interpolator medians): ≤ `n_interp + 2`

→ For sirt_treatment, expect **a few hundred raw candidates and tens to ~100
cluster representatives** going into polish (cluster threshold is 0.1% rel. dist.,
`parameter_estimation.jl:2389`). Reference: bilby `sirt_treatment_7_1em4`
imported 77 raw candidates and ballooned to 339 polished entries
(`artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/sirt_treatment_7_1em4/study.md`),
**at the older, smaller config** (`shooting_points = 12`, no aggregate synthesis).

### 2) Per-polish cost — and the wall-clock-cap bug

The residual polish path is `src/core/polish_residual.jl:39–243`. The signature is

```
function _polish_single_residual(ctx, p0;
        solver_kind = :lso_direct,
        optimizer_factory = () -> LeastSquaresOptim.LevenbergMarquardt(),
        maxiters = 1000,
        maxtime = 300.0,           # <-- accepted
        lso_delta, lso_*_tol …
)
```

Inside the body, the actual LSO call (`polish_residual.jl:164–182`) is:

```julia
result = LeastSquaresOptim.optimize!(
    problem,
    opt;
    x_tol = lso_x_tol > 0 ? lso_x_tol : ctx.reltol,
    f_tol = lso_f_tol > 0 ? lso_f_tol : ctx.reltol,
    g_tol = lso_g_tol > 0 ? lso_g_tol : ctx.abstol,
    iterations = maxiters,
    Δ = lso_delta,
    lower = …, upper = …,
)
```

**`maxtime` is never read after line 45.** `LeastSquaresOptim.optimize!` has no
wall-clock-limit kwarg, and there is no `Threads.@spawn`-side timeout watchdog
or callback wrapper around it. Same story for the FastLM branch at
`polish_residual.jl:148–162` — `FastLevenbergMarquardt.lmsolve!` only takes
`xtol/ftol/gtol/maxit`.

Compare the **scalar** polish path (`parameter_estimation.jl:2204–2330`), where
the callback at lines 2295–2298 explicitly enforces `maxtime`:

```
elapsed = time() - start_time
if elapsed > maxtime
    stop_reason[] = "wall-clock timeout (…)"
    return true
end
```

Hence: the script's `polish_maxtime = 1200.0` only matters for legacy scalar
methods (`PolishNewtonTrust`, `PolishBFGS`, …). For the bake-off-winner default
`PolishLSOBoundedLog`, the only stop conditions are `iterations = 5000` and the
`1e-12` tolerances. **A single polish can run hours** if LM is making slow
gradient progress in a flat valley.

The cluster wall-clock breakdown that fits the data:

- Worst case (one polish per hour, 10 representatives, 16 threads):
  `~10 × 1h × 1 = 10 h` ← matches the observation
- Plausible case: 50–100 cluster reps × ~15 min average × 16 threads
  `→ ~1–2 h` …but tail of slowest reps dominates if a few hit 5000 iters

### 3) Why `sirt_treatment` is a hard polish target at `tol = 1e-12`

The state equations:

```
D(In)   ~ 1.52*b*S*In/Npop + 0.608*d*b*S*Tr/Npop − (0.2*a + 0.6*g)*In
D(Npop) ~ 0
D(S)    ~ −0.08*b*S*In/Npop − 0.032*d*b*S*Tr/Npop
D(Tr)   ~ 6.0*g*In − 0.2*nu*Tr
```

with `y1 ~ 10·Tr`, `y2 ~ 2000·Npop`, `y3 ~ 10·In`. Two structural facts:

1. `Npop` is a constant: `D(Npop) ~ 0`. `y2(t) = 2000·Npop` is a flat line, and
   `Npop` is identifiable only via that constant offset. The residual gradient
   in the `Npop` direction is well-scaled, but every parameter that appears as
   `1/Npop` is bilinear with `Npop` itself — so `b`, `d`, `nu` all share a
   pseudo-rank-1 mode with `Npop` for any candidate that started off-true on
   `Npop`. LSO LM at `tol = 1e-12` will spend many iterations zig-zagging in
   this near-null direction before either converging or hitting `maxiters`.
2. The ground-truth params are well inside `[1e-5, 10]`, but the `_log` policy
   (per-variable log space) compresses bounds non-uniformly when values differ
   in magnitude. The `In0 = 0.674`, `Npop0 = 0.208`, `S0 = 0.725`, `Tr0 = 0.109`
   IC vector is fine, but the `b * S / Npop` rate constant ≈ `0.734·0.725/0.208 ≈ 2.56`
   is not — the loss surface is steeper in linear coords than in log coords, so
   log-space LM may take small relative steps even when a few-percent step
   in linear coords would have done the job.

This is why prior `sirt_treatment` ablations
(`artifacts/diagnostics/residual_polish_ablation_fdclean_sirt_v3/summary.md`)
used a **box-clipped** scenario and converged 28 raw candidates in **6.6–8.3 s
total** — but those runs used `polish_maxiters = 100` (the default) and the
imported pool was already small. Scaling to ≥10× more candidates × 50× more
iterations is consistent with the 10 h observed.

### 4) Other contributors (small / unconfirmed)

- The script `using MKL` at the top sets MKL threading, which can serialize
  concurrent `Threads.@spawn` polish tasks if `MKL_NUM_THREADS` isn't pinned
  to 1. Worth checking on the cluster with `MKL_NUM_THREADS=1
  JULIA_NUM_THREADS=16` to keep BLAS calls inside the LM linear-solve from
  fighting Julia's task scheduler.
- `polish_ode_maxiters = 20000` lets a single ODE solve do up to 20 k internal
  steps. With `abstol = reltol = 1e-12` and stiff `In/Tr` dynamics on parameter
  candidates that are off-true, that's a real worst case (seconds per ODE
  solve, not milliseconds).
- The multipoint HC.jl solve at `n_points = 2` doubles the polynomial system
  size relative to single-point, which makes the up-front HC tracking the
  slowest part of `[MULTIPOINT]` lines in stdout. **This is not the dominant
  cost** — it shows up once per `(interpolator, max_pairs)` tuple, not per
  candidate — but it can add a few minutes to the prologue.

## Recommended next steps

In rough order of cheapness × diagnostic power:

1. **Fix the `maxtime` no-op.** This is a one-line bug. Either:
   - Wrap the LSO/FastLM call in an async task with a `Timer`, OR
   - Build a tiny manual residual loop that checks `time() - t0 > maxtime`
     between LM iterations (LSO doesn't expose iteration callbacks, so the
     async-with-timer approach is simpler).
   - Even a coarse `maxtime` enforced by aborting on the next residual
     evaluation (`error("polish maxtime")` from inside `residual!` once the
     deadline passes) would bound the worst case.

   Suggested edit point: `src/core/polish_residual.jl` — wrap the
   `LeastSquaresOptim.optimize!` and `FastLevenbergMarquardt.lmsolve!` calls
   in a `Task` + `timedwait`, or have `residual!` check `time() - t0 > maxtime`
   and `fill!(res, 0); throw(InterruptException())` to bail.

2. **Confirm experimentally with cheap variants** (the README already suggests):
   - `polish_solutions = false` → confirm pre-polish phases (HC, multipoint,
     synthesis) finish in a reasonable time. Expectation: minutes, not hours.
   - `multipoint_max_pairs = 3` AND `polish_maxiters = 200` → expect
     completion in tens of minutes; if it's still hours, the polish-cap bug
     isn't the only issue.
   - `polish_method = PolishNewtonTrust` (legacy scalar) with everything else
     unchanged → `maxtime = 1200` IS enforced for that path; if total
     runtime drops sharply, that's direct evidence.

3. **Per-polish profiling.** Add a `@info` line at the start and end of
   `_polish_single_residual` printing `(rep_idx, t_elapsed, n_iters_used,
    initial_norm, final_norm)`. Currently the only logging is the batch-level
   `Polish $task_idx/$n_unique` line in `_polish_batch_from_context`
   (`parameter_estimation.jl:2543`). With per-polish times it becomes obvious
   which seeds are stuck.

4. **Loosen polish stopping rules for clean-data cases.** With noise = 1e-8,
   `tol = 1e-12` is below the achievable optimum on a 750-sample residual
   anyway. `tol ≈ 1e-10` and `polish_maxiters = 500` would more than suffice
   for the 1e-8 cell while keeping the 1e-4 / 1e-2 cells able to use the
   tighter knobs (or just use the package default `polish_maxiters = 100`).

5. **Investigate `Npop` direction.** A small change at
   `src/core/parameter_estimation.jl` build-context that detects "constant
   states" (`D(state) ≡ 0`) and removes them from the polish unknowns (using
   `data_sample[y2_obs][1] / 2000` as the fixed value) would both shrink the
   Jacobian by 1 column and remove the worst near-null direction. Out of
   scope for this diagnosis but cheap if pursued.

## What I did not do

- I did not run `julia script.jl` (the README says expect 2–4× the cluster's
  10.1 h on a laptop). The diagnosis is from static analysis of the v2_polish
  config + reads of `polish_residual.jl`, `parameter_estimation.jl`,
  `optimized_multishot_estimation.jl`, and the prior bilby/ablation artifacts
  for `sirt_treatment`.
- I did not modify any code. The "fix the maxtime no-op" item above is the
  obvious next change but should be a separate, explicit task.

## Pointer summary

| Where | Why it matters |
| --- | --- |
| `src/core/polish_residual.jl:39–243` | residual polish body; `maxtime` accepted but never enforced |
| `src/core/parameter_estimation.jl:2295–2298` | scalar polish wall-clock check (the one the residual path lacks) |
| `src/core/parameter_estimation.jl:2389` | cluster threshold `0.001` (0.1% rel. dist.) |
| `src/core/optimized_multishot_estimation.jl:1809–1898` | multipoint candidate generation (15 pairs × interpolators) |
| `src/core/optimized_multishot_estimation.jl:2272–2284` | aggregate-candidate synthesis (Cat A/B/C/D) |
| `src/core/optimized_multishot_estimation.jl:2329` | the polish-batch entry point |
| `src/types/estimation_options.jl:172–181, 322–330` | polish defaults that v2_polish overrides 4×–50× upward |
| `artifacts/diagnostics/residual_polish_ablation_fdclean_sirt_v3/summary.md` | historical sirt polish times (6.6–8.3 s for 28 candidates @ default maxiters) |
| `artifacts/diagnostics/sweeps/bilby_2026_03_09_1em4_tryhard_polish/cases/sirt_treatment_7_1em4/study.md` | bilby 77 → 339 candidates, total ODEPE runtime 4839 s (still 7.4× short of the new run's 36000 s) |
