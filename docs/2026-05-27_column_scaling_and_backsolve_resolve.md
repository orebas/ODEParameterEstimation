# Column scaling + the receptor cost diagnosis (2026-05-26/27 session record)

A consolidated record of a long investigation that (1) diagnosed why `receptor_subtype_binding_branch`
failed, (2) implemented and validated **data-driven column scaling** (now default-ON), and (3) traced
receptor's ~87-min cost — **by measurement (`profile_phases`)** — to the main polynomial solve run **28×**
(9 interpolators × ~3 homotopy-collapse fallbacks), **NOT** the backsolve/`[RESOLVE]` (a misdiagnosis that
earlier drafts made and that measurement disproved). Detailed artifacts:
`repro/receptor_solution_count_2026_05_26/REPORT.md` (Exp A–K),
`repro/column_scaling_impl_2026_05_26/CONCLUSION.md` (column scaling), and
`repro/receptor_breakdown_2026_05_27/` (the cost measurement).

---

## 1. TL;DR

- **Column scaling shipped, default-ON, regression-clean** (446/446 with ON). It rescales each
  polynomial-jet unknown `x = D·x̂` by per-derivative-order observable magnitudes, solving the rescaled
  system (mixed_volume unchanged) and unscaling. `EstimationOptions.use_column_scaling`.
- **It is a solver-*reach* aid, not a data-sensitivity fix** (proven). It helps HC *find* roots whose
  coordinates span a huge dynamic range; it provably cannot reduce noise amplification or fix
  parameter-homotopy tracking.
- **Receptor becomes a solvable M=2 benchmark case with it on:** end-to-end it recovers both branches
  (truth+swap) at 0.4% with scaling vs 0/2 (8.5%) without.
- **Receptor's ~87-min cost is the main polynomial SOLVE, run 28×** (`profile_phases`: "Equation
  construction + Solving" = 5154s / 99.5%; Result processing = 1.77s; resolves ≈ 14s). The 28 fresh
  6402-path polyhedral solves = **9 interpolators** (the default `interpolators` list) **× ~3 fresh solves
  each** (the parameter homotopy collapses 16→4, 17→2 → fresh fallback at each shooting point). The
  backsolve and `[RESOLVE]` are NOT the cost; the speed levers are **(a) fewer interpolators** and
  **(b) fixing the homotopy collapse** — see §6–7. (Earlier drafts blamed the `[RESOLVE]`/SIAN-rebuild and
  proposed a backsolve filter — **measurement disproved both**; corrected below.)

---

## 2. Column scaling — implementation

Three source files (solver layer only — `si_equation_builder.jl` / the rank-trim untouched):
- `src/types/estimation_options.jl`: `use_column_scaling::Bool` (default `true`).
- `src/core/homotopy_continuation.jl`: helpers `compute_column_scales(solve_vars, data_vars, param_values_list)`
  and `scale_hc_system(hc_system, hc_variables, scales)`, wired into `solve_with_hc_parameterized`
  (scale the system once before the solve loop; unscale each returned solution; fast-path no-op when all
  scales == 1).
- `src/core/optimized_multishot_estimation.jl`: threads `opts.use_column_scaling` into `solver_options`.

Scale rule: `order_mag[k]` = max over points and data_vars of derivative order `k` of `|value|`;
scale(var) = 1.0 for order-0 vars (params + order-0 ICs), `max(order_mag[k], 1)` for order k≥1.
Unit tests: `test/column_scaling.jl` (12/12).

---

## 3. Column scaling — theory (why the results are what they are)

Column scaling is the change of variables `x = D·x̂`, `D` a **constant nonsingular diagonal**:
- It changes `∂F/∂x̂ = (∂F/∂x)·D` — the conditioning the **path-tracker** sees — so it helps HC
  **reach roots it otherwise can't** (extreme-coordinate targets). → helps **fresh polyhedral solves**.
- It leaves `∂x/∂data` **invariant** (`D`/`D⁻¹` cancel) and leaves any homotopy path's **fold/singular
  points invariant** (same parameter values). → it **cannot** reduce noise amplification, and **cannot**
  fix parameter-homotopy tracking failures.

**Net: a solver-reach aid, not a data-sensitivity fix.** This single fact predicts every result below.

---

## 4. Column scaling — validation

- **Regression:** 446/446 with default ON (`fast_core` 313 + `feature_regressions` 133), unchanged from
  OFF. Off-path is a byte-identical no-op (`col_scales = ones` ⇒ `1.0*x`).
- **Broad off-vs-on benchmark** (9 systems, same data, `benchmark_off_vs_on.jl`): **`best_max` identical
  off→on on every system** (no recovery regression anywhere). Candidate-**set** similarity (`set-Δ`):
  **~1e-13 (identical) on well-conditioned** systems (simple, lotka, vanderpol, harmonic, daisy_mamil3,
  slowfast); **0.34–0.97 on ill-conditioned ones** (daisy_mamil4, seir, biohydrogenation) — the
  *spurious tail* reshuffles where conditioning is bad, but the **best/recovered candidate is unchanged**.
- **Controlled noisy sweep** (`run_sweep_v3.jl`, same data off vs on): off==on to every digit → the
  earlier "8× bioh-under-noise win" was a noise-realization artifact, gone once data was held fixed
  (consistent with the theory: noise amplification is scale-invariant).
- **Wall-time:** zero when off; ≈off when on (mixed_volume invariant; one-time `subs`).
- **Caveat for M>1 systems:** on ill-conditioned / M>1 systems the *full* candidate list (→ `result.csv`
  ordering / UQ) can shift in the spurious tail; re-baseline full-output diffs there (the recovered
  branch is stable).

---

## 5. Receptor diagnosis recap (the blind spot is scaling, not geometry)

`receptor_subtype_binding_branch`: states L,Ca,Cb; 6 params; obs y1=L, y2=Ca+Cb; M=2 (a↔b swap).
- Generic finite count = 18 (certified); `mixed_volume`=6402 is a loose BKK *path* bound.
- The t≈−0.3 "blind spot" is **not geometric**: truth is an exact root there (residual 1e−11) that
  unscaled polyhedral **fails to track** because truth's coordinates span ~10⁷ (high-order jets explode
  ~10×/order near the transient). NOT fixed by precision/steps (aggressive tracker = 0 gain) or equation
  reconditioning (500× better conditioning, blind spot survived). **Fixed by column scaling** (6/6 seeds
  vs 0/8) or monodromy completion.
- Separate, lower-priority: the rank-trim drops the linear `y1`-derivative pins (`L_k = y1_k`) because
  they're locally rank-redundant → admits 16 spurious roots. Principled SIAN behavior; NOT the blind-spot
  cause. (See REPORT.md Exp G–K + the two-model PAL consult.)

---

## 6. The `[RESOLVE]` / backsolve findings — measured, and NOT the cost

After a parameter candidate is found, the pipeline backsolves its state ICs (backward ODE from a
shooting point to t0). When that "blows up" (IC non-finite or `|IC| > 1e9·data_scale`, or err>1e15),
`resolve_states_with_fixed_params` (`[RESOLVE]`, `si_template_integration.jl:374`) fires — re-running
SIAN with the candidate's params fixed to solve for states algebraically.

**Measured in the real pipeline (`repro/receptor_breakdown_2026_05_27/`, profiled e2e):**
- **Result processing (all backsolves) = 1.77s.** Backsolving every candidate at shoot point t=0.5 →
  t0=−0.5 returns `retcode=Success` in **2–73 ms** each; truth recovers the exact ICs `[2.0, 0.1, 0.2]`,
  spurious candidates land at **finite but non-physical** ICs (negative occupancies, e.g. `[2.0,−2.22,2.52]`).
  **There is no 1e163 blow-up** over the real shooting interval (an earlier claim from a non-representative
  synthesized test in `receptor_backsolve_test.jl` — **retracted**).
- The full run does show **75 `dt_epsilon` backsolve aborts** (`Unstable`: "dt forced below floating-point
  epsilon … true solution unstable") on spurious candidates at certain points — but each aborts **instantly**
  (that's why Result processing is 1.77s). These trigger **28 `[RESOLVE]`s**, each a **7×7, 1-path** solve
  measured at **~0.03s warm** (≈14s total; the SIAN re-run behind it is 0.0s warm —
  `repro/resolve_cache_spike_2026_05_27/`).

**So the backsolve and `[RESOLVE]` together cost < 16s of the 87 min** — not a recovery problem (truth+swap
recover) and not a speed problem. The historical clamp `_clamp_params_for_backsolve`
(`parameter_estimation_helpers.jl:572`, params-only, opt-in) is irrelevant here: passing
`opt_lb/opt_ub=[1e-5,10]` left wall time, recovery, and `[RESOLVE]` count **unchanged** (5206s vs 5202s;
truth+swap 4.083e-3 both; 58 vs 78 fires — `bounds_compare.jl`). Clamping the spurious *params* can't stop
a state-driven instability, and there is no expensive blow-up integration to filter.

---

## 7. Where the 87 minutes actually go (measured by `profile_phases`)

| phase | time | % |
|---|---|---|
| SI Template (SIAN) | 16s | 0.3% |
| **Equation construction + Solving** | **5154s** | **99.5%** |
| Result processing (backsolves) | 1.77s | 0.03% |
| Synthesize aggregates | 6.6s | 0.1% |

The 5154s = **28 fresh 6402-path polyhedral solves** (`grep -c 'mixed_volume: 6402'`), which decompose as:
- **× 9 interpolators** — the default `opts.interpolators` list has 9 methods (AGPRobust, AGPRobustRQ,
  S3AdaptSE, S3AdaptRQ, ChebyshevBIC, ChebyshevAICc, AAADGPR, AAAD, S2AAAMLE), and with
  `auto_filter_interpolators=false` the whole list runs. (`opts.interpolator`, the singular field, is only
  used when the list is *empty* — `resolve_interpolator_list`, `estimation_options.jl:798`.) The solve loop
  at `optimized_multishot_estimation.jl:1513` runs the full parameter-homotopy sequence per interpolator.
- **× ~3 fresh solves per interpolator** — the parameter homotopy **collapses** (tracking lands 16→4 then
  17→2; `terminated_max_steps`, not `at_infinity`), firing a fresh 6402-path **fallback**
  (`homotopy_continuation.jl:1061`) at points 2 and 3 instead of cheap tracking. Per interpolator: 1 fresh +
  2 fallbacks. Measured standalone: ~308s for one interpolator's 5-solve sequence
  (`repro/receptor_breakdown_2026_05_27/homotopy_solve_count.jl`).

**The two real speed levers (a backsolve filter is NOT one — there is nothing expensive to filter):**
1. **Interpolator count — ×9.** For clean data, AAAD alone recovers truth+swap; `interpolators=[InterpolatorAAAD]`
   → 1 interpolator → ~9× (86min → ~10min). Trades multi-interpolator robustness (matters under noise).
2. **Homotopy collapse — ×3.** Each interpolator pays 3 fresh polyhedral solves instead of 1. Fixing the
   homotopy (monodromy completion / re-tracking) → 1 solve/interpolator → ~3×. The principled fix
   (parameter homotopy *should* track), helping every multi-shooting-point system.

**Retracted (2026-05-27):** earlier drafts — and the `repro/resolve_cache_spike_2026_05_27` plan — said the
cost was the per-candidate SIAN rebuild / `[RESOLVE]` solves and proposed a *conservative backsolve filter*
as "the real speed lever." Measurement refuted this: SIAN builds are 0.0s warm, resolves ≈14s, backsolves
1.77s. The cost is the **main solve × interpolators × homotopy-collapse fallbacks**. No backsolve filter and
no SIAN cache were implemented (both would save ~nothing). The honest cost lesson: **profile before
optimizing** — three successive "the cost is X" hypotheses (SIAN rebuild, then resolve solves, then main
solves alone) were each wrong until `profile_phases` gave the real split.

---

## 8. Reproduce

```bash
cd /home/orebas/.julia/dev/ODEParameterEstimation
julia --startup-file=no -e 'using ODEParameterEstimation, Test; include("test/column_scaling.jl")'   # helpers 12/12
julia --startup-file=no repro/column_scaling_impl_2026_05_26/run_sweep_v3.jl          # benign+inert (controlled)
julia --startup-file=no repro/column_scaling_impl_2026_05_26/benchmark_off_vs_on.jl   # do-no-harm + set-Δ (9 systems)
julia --startup-file=no repro/column_scaling_impl_2026_05_26/receptor_e2e.jl          # receptor recovery (truth+swap)
# --- cost diagnosis (2026-05-27): measure, don't guess ---
julia --startup-file=no repro/receptor_breakdown_2026_05_27/receptor_profiled.jl        # profile_phases: the 99.5% phase
julia --startup-file=no repro/receptor_breakdown_2026_05_27/homotopy_solve_count.jl     # 5 solves/interpolator, the collapse
julia --startup-file=no repro/receptor_breakdown_2026_05_27/backsolve_failmode.jl       # backsolves Success ~ms (no 1e163)
julia --startup-file=no repro/receptor_breakdown_2026_05_27/resolve_timing.jl           # per-[RESOLVE] ≈ 0.03s warm
```
> Note: `repro/column_scaling_impl_2026_05_26/receptor_backsolve_test.jl`'s "spurious → ~1e163" result is
> **retracted** — over the real shooting interval all candidates backsolve `Success` in ms (see §6).

## 9. Artifacts
- `repro/column_scaling_impl_2026_05_26/CONCLUSION.md` — implementation + validation + all scripts/logs.
- `repro/receptor_solution_count_2026_05_26/REPORT.md` — receptor diagnosis (Exp A–K, PAL consult).
- `test/column_scaling.jl` — helper unit tests.
- Memory: `project_2026_05_27_column_scaling_implemented`, `project_2026_05_26_receptor_solution_count`.
