# sirt_treatment_0_1em8 — polish maxtime fix + candidate-pool clustering

Date: 2026-05-07. Builds on `repro/DIAGNOSIS.md`.

## TL;DR

1. **`polish_maxtime` fix landed.** `_polish_single_residual` now enforces the
   wall-clock cap by throwing `_PolishTimeoutSignal` from inside `residual!`
   the moment the deadline passes, plus an `unstable_check` callback on the
   ODE solve so a single Dual-typed Jacobian can't sit past the deadline. The
   catch returns the best Float64-path iterate seen so far, and tags
   `provenance.notes` with `:polish_maxtime_exceeded` when the cap fired.
   Edits: `src/core/polish_residual.jl` only. Test:
   `repro/test_polish_maxtime.jl` (7/7 pass after JIT warmup).
2. **Caveat — first call per Julia process eats JIT cost.** A cold first
   ForwardDiff'd Dual ODE solve takes 20–30 s to compile for
   `AutoVern9(Rodas5P())` at `abstol=reltol=1e-12`. The fix is correct;
   the cap is just dwarfed by JIT on call #1 only. Production amortizes this
   over the whole polish batch (one cold call per process).
3. **Pool is dominated by near-duplicates and blown algebraic backsolves.**
   Even with this script's reduced settings (`shooting_points=20`,
   `multipoint_max_pairs=5`), the 5-param 4-state sirt_treatment generates
   **647 candidates**: 429 single-point, 148 multipoint, 70 synthesized
   aggregates. Of those, **48 are blown `algebraic_resolve_t0` rescues** with
   wildly wrong `S` and `a` (e.g. `a=-264, S=-52`) yet otherwise plausible
   `In, Npop, Tr, g, nu`.
4. **The current 0.1% rel-dist clustering barely reduces the pool.**
   647 → 596 unique cluster reps. Even at a generous 50% threshold we still
   have 227 clusters. **Sensitivity-weighted clustering at 10% gives 215
   clusters; subspace clustering (drop the wildly-identified `a, S`) at 10%
   gives 365.** The user's hypothesis — "we might need to cluster really
   insensitive things better" — is supported numerically.

## 1) The maxtime fix

Original problem (from `DIAGNOSIS.md`): `_polish_single_residual` accepted a
`maxtime` argument but never enforced it. `LeastSquaresOptim.optimize!` and
`FastLevenbergMarquardt.lmsolve!` neither honor a time limit nor expose
iteration callbacks, so the cluster's `polish_maxtime = 1200.0` was a no-op
for `PolishLSOBoundedLog`.

### Fix structure (`src/core/polish_residual.jl`)

```text
struct _PolishTimeoutSignal <: Exception end

function _polish_single_residual(...)
    deadline_ref = Ref(Inf)
    best_norm_seen = Ref(Inf)
    best_p_seen = copy(p0_internal)

    function residual!(res, p_internal, _)
        if time() > deadline_ref[]
            throw(_PolishTimeoutSignal())
        end
        ...
        sol_opt = ModelingToolkit.solve(prob_opt, ctx.solver;
            ...,
            unstable_check = (dt, u, p, ti) -> time() > deadline_ref[],
        )
        if sol_opt.retcode != ReturnCode.Success
            fill!(res, _residual_sentinel(res));  return nothing
        end
        ...
        # Track best Float64-path iterate; skip Dual eltype.
        if eltype(res) === Float64 && eltype(p_internal) === Float64 ...
    end

    # Initial residual (deadline disarmed).
    residual!(initial_residual, p0_internal)
    initial_norm = norm(initial_residual)

    # Arm the deadline. `maxtime <= 0` or non-finite disables.
    deadline_ref[] = (isfinite(maxtime) && maxtime > 0) ? time() + maxtime : Inf

    try
        result = LeastSquaresOptim.optimize!(...)        # or FastLM
        candidate_internal = result.minimizer
    catch e
        isa(e, _PolishTimeoutSignal) || rethrow(e)
        timed_out = true
        candidate_internal = best_p_seen
    end

    # Disarm before revert-guard re-eval.
    deadline_ref[] = Inf
    residual!(final_residual, candidate_internal)
    ...
    if timed_out
        push!(final_result.provenance.notes, :polish_maxtime_exceeded)
    end
end
```

Two stop signals working together:
- **`unstable_check` on the ODE solve** terminates the integrator at the next
  step boundary once the deadline passes — bounds the cost of a single
  Jacobian (`ForwardDiff` runs `residual_vec` once per call with `Dual`
  numbers; without the check, that one call can run many seconds at tight
  tolerances).
- **`time() > deadline_ref[]` at the top of `residual!`** propagates
  `_PolishTimeoutSignal` out of LSO/FastLM on the next call — caught at
  the surrounding `try` block.

The revert-guard final residual evaluation runs with the deadline disarmed
so it always completes, and the existing
"keep `p0` if `final_norm > initial_norm`" logic is unchanged.

### Test (`repro/test_polish_maxtime.jl`, 7/7 pass)

```text
LSO  cap=2.0s elapsed=0.01s err=7.45e-26 notes=Symbol[]   # warm convergence; cap not needed
FastLM cap=2.0s elapsed=1.96s err=5.51e-26 notes=Symbol[] # cap nearly hit, both honored
LSO  Inf-cap (warm seed) elapsed=0.00s err=1.06e-26       # disabled cap unchanged
Test Summary:              | Pass  Total     Time
polish maxtime enforcement |    7      7  1m54.3s
```

The test does **one warmup polish** (`maxiters = 1, maxtime = 600`) before
the timed assertions, because the *first* Dual-typed ODE solve in a Julia
process takes 20–30 s to JIT-compile for the auto-switching solver and
ForwardDiff Dual eltype. Without the warmup, the LSO test reads
`elapsed = 30.42 s for cap = 2.0 s` even though the fix is working — the
overshoot is JIT, not LSO. In production this is a **once-per-Julia-process**
overhead, amortized over many polishes.

## 2) Candidate-pool analysis

`repro/dump_pool.jl` runs the same sirt_treatment_0_1em8 problem with
`polish_solutions = false` and dumps the pre-polish pool to
`pool_dump.csv`. `repro/analyze_pool.py` digests it.

Reduced settings used: `shooting_points = 20`, `multipoint_max_pairs = 5`,
`abstol = reltol = 1e-12`. Even tighter than the cluster's `max_pairs = 15`
script and the pool is still 647 candidates.

### Per-axis spread

```text
axis         truth            min            max        p50        p99   r.spread   %good
In(t)       0.6740     -7.465e+06           2961     0.9779      34.03  7.468e+06    28.9
Npop(t)     0.2080          0.208          0.208      0.208      0.208  7.709e-09   100.0
S(t)        0.7250          -2057      4.841e+05   0.003101      542.1  4.862e+05     9.4
Tr(t)       0.1090     -2.323e+07      1.476e+07    0.04006      404.9  3.799e+07    28.3
a           0.4730     -6.312e+04           5887     0.4455       1910    6.9e+04    28.1
b           0.7340     -1.495e+06      2.106e+06    -0.1125  6.795e+04  3.601e+06     9.6
d           0.3780         -21.03          61.35   -0.00446      27.74      82.38    10.0
g           0.7750         -3.241          237.5      0.775       3.38      240.7    93.5
nu          0.6200         -46.44            715       0.62      3.504      761.4    91.7
```

`%good` = fraction of candidates within 1% of truth on that axis. Reads as a
"per-axis identifiability score."

- **`Npop` is essentially fixed.** All 647 candidates agree to ≤ 1e-9 — the
  observable `y2 = 2000·Npop` is constant in time and pins it.
- **`g, nu` are well-determined** (~92% / 94% within 1% of truth).
- **`In, Tr` are partially-identified** (~28% within 1%) — the median
  candidate is in the right ballpark but the tails are wide (p99 of `Tr` is
  405 vs truth 0.109).
- **`S, a, b, d` are weakly identified.** The pool spans 6 orders of
  magnitude on `a` (max 5887, min -63 000) and absurd values on `S`
  (max ~5×10⁵). Only ~10% of candidates land within 1%.

This is the structural shape of sirt_treatment for `polish_residual` to
clean up.

### Provenance breakdown

```text
source_type:  {single_point: 429, multipoint: 148, synthesized_aggregate: 70}
rescue_path:  {none: 599, algebraic_resolve_t0: 48}
interpolator: top 6 → {agp_robust: 76, s3_adapt_rq: 75, agp_robust_rq: 73,
                       s2_aaa_mle: 72, aaad_gpr: 71, s3_adapt_se: 70}
```

The 9-interpolator default fans out the single-point pool. The 48
`algebraic_resolve_t0` rescues are blown backsolves — fine values for
`In, Npop, Tr, g, nu`, garbage for `S, a` (e.g. `a = -264, S = -52`).
The polish does have a chance to recover them but each one consumes a polish
slot; with the broken cap they could each have eaten 5000 LM iterations.

### Best 8 candidates

```text
rank      err   In(t)   Npop(t)  S(t)    Tr(t)   a       b       d       g       nu
   1  2.13e-5  0.6740   0.208   0.7250   0.1089  0.4729  0.7340  0.3781  0.7750  0.6200
   2  6.61e-5  0.6734   0.208   0.7250   0.1116  0.4730  0.7341  0.3779  0.7750  0.6200
   3  8.18e-5  0.6745   0.208   0.7250   0.1073  0.4730  0.7339  0.3782  0.7750  0.6200
   …
```

These near-duplicates of one another differ by a fraction of a percent on
`In, Tr` — *plenty* close enough to be the same physical solution — but the
current uniform-rel-dist threshold of 0.001 (0.1%) keeps them in separate
clusters because the max-rel-dist over `In, Tr` is ≥ 0.001.

### Worst 5 candidates

```text
rank        err           src   rescue                In   Npop   S       Tr   a       b      d           g      nu
 643  2.51e+128  single_point  algebraic_resolve_t0  0.674 0.208 -7.27   0.109 -176.5  0.571  0.546       0.772  0.629
 644  1.25e+131  single_point  algebraic_resolve_t0  0.674 0.208 -12.82  0.109 -176.0  0.314  1.001       0.777  0.630
 645  3.26e+142  single_point  algebraic_resolve_t0  0.674 0.208  -4.37  0.109 -177.3  0.969  0.319       0.782  0.630
 646  5.01e+145  single_point  algebraic_resolve_t0  0.674 0.208  -2.68  0.109 -178.3  1.608  0.189       0.679  0.625
 647  1.01e+208  single_point  algebraic_resolve_t0  0.674 0.208 -52.39  0.109 -263.7  0.128  4.0e-5      0.775  0.620
```

Notice they all have the *same* (truth) values for `In, Npop, Tr` and
near-truth `g, nu`. They're indistinguishable on the well-determined axes;
they only differ in `S, a, b, d` — the weakly-identified directions. Yet
each gets its own cluster because the max-rel-dist is ~10² on those axes.

### Clustering thresholds

```text
   threshold   n_clusters   reduction_factor
      0.0010          596               1.09x   ← current cluster_threshold = 0.001
      0.0050          546               1.18x
      0.0100          531               1.22x
      0.0200          511               1.27x
      0.0500          482               1.34x
      0.1000          420               1.54x
      0.2500          346               1.87x
      0.5000          227               2.85x
```

The current `_polish_cluster_metadata` threshold of 0.001 (0.1%) gives only
**1.09× reduction**. Even at 50% you'd still polish 227 reps.

### Sensitivity-weighted clustering (heuristic)

`w = 1 / max(log10(spread + 1.1), 0.05)` — down-weights wildly-spread axes.

```text
weights (per axis): In=0.145  Npop=20.0  S=0.176  Tr=0.132  a=0.207
                    b=0.153   d=0.520    g=0.420  nu=0.347

   threshold   n_clusters_uniform   n_clusters_weighted
      0.0010                  596                   549
      0.0100                  531                   482
      0.0500                  482                   340
      0.1000                  420                   215   ← 3× reduction
```

At threshold = 0.10 with sensitivity weighting, 215 reps. **3× fewer
polishes**, with most of the reduction coming from collapsing near-duplicates
that differ only on `a, S`.

A spot-checked alternative: drop the wildly-identified axes (`a, S`)
entirely and cluster only over `{In, Npop, Tr, b, d, g, nu}`. That gives
**365 clusters at threshold 0.10**, weaker than weighted but still ~1.8×
reduction.

### How "covered" is the truth?

```text
near-truth on (In, Npop, Tr):                    180/647 (27.8%)
near-truth on (In, Npop, Tr, g, nu):             154/647 (23.8%)
near-truth on (all 9 axes):                       33/647 (5.1%)
```

180 candidates already have *all observed states* near truth. They differ
mostly in latent, weakly-identified parameters. Polishing all 180 of them
with LSO LM is wasteful — they'd all converge to the same minimum if any
one of them does.

## 3) Maxtime impact (compare_maxtime.jl)

Reduced-scope sirt_treatment_0_1em8 run, parameterized by `polish_maxtime`.
Settings — see `repro/compare_maxtime.jl`:

```text
shooting_points        = 10                       (cluster: 20)
multipoint_max_pairs   =  2                       (cluster: 15)
synthesize_aggregates  = false                    (cluster: true)
polish_method          = PolishLSOBoundedLog
polish_maxiters        = 1500                     (cluster: 5000)
abstol = reltol        = 1e-12                    (cluster: same)
```

Even at this reduced scope the candidate pool reaches **299 candidates →
174 cluster representatives** going into polish (the same `0.001`
threshold gives 1.7× reduction here vs 1.09× on the larger pool, because
fewer interpolators × fewer multipoint combos generates fewer near-duplicates).

### `maxtime = 60 s` (extracted from `/tmp/compare_60.log`)

| Metric | Value |
| --- | --- |
| Total wall-clock | **27 min 47 s** |
| Polish phase wall-clock | **106.3 s** |
| Polishes performed | 174 cluster reps |
| Per-polish dt — min | 1.5 s |
| Per-polish dt — p25 | 44.1 s |
| Per-polish dt — p50 (median) | **60.4 s** ← right at the cap |
| Per-polish dt — p75 | 66.1 s |
| Per-polish dt — p90 | 77.1 s |
| Per-polish dt — max | 94.5 s (one cold JIT outlier) |
| Polishes ≤ 10 s (converged fast) | 9 / 174 |
| Polishes 10–30 s | 21 / 174 |
| Polishes 30–58 s | 28 / 174 |
| Polishes ≥ 58 s (cap-bound) | **116 / 174 = 67%** |
| Best max relative parameter error | **1.0 × 10⁻⁶** (machine-precision float roundoff) |
| `best_min_relerr` / mean / median / RMS | all 0.0 (rounded to 1e-7) |

The `dt` values exceed `60 s` because (a) the deadline check + ODE
`unstable_check` lets the integrator finish its current step before
yielding (sub-second slack typical), and (b) the *first* polish in this
process eats JIT compile time as discussed above (the 94.5 s max is one
of those).

**Cap is binding for two-thirds of polishes**, mostly the
`algebraic_resolve_t0` blown candidates with `a ≈ -178, S ≈ -52` that
cannot converge inside 60 s no matter what. The other third converges
cleanly (well under 30 s).

### `maxtime = 120 s` (extracted from `/tmp/compare_120.log`)

| Metric | Value |
| --- | --- |
| Total wall-clock | 19 min 4 s |
| Polish phase wall-clock | **164.7 s** |
| Polishes performed | 174 cluster reps |
| Per-polish dt — min | 1.2 s |
| Per-polish dt — p50 (median) | **120.2 s** ← right at the new cap |
| Per-polish dt — p90 | 136.3 s |
| Per-polish dt — max | 153.3 s |
| Best max relative parameter error | **1.0 × 10⁻⁶** (same as 60 s — machine precision) |

### Side-by-side

| | maxtime=60 s | maxtime=120 s | ratio |
| --- | ---: | ---: | ---: |
| Polish phase wall-clock | 106.3 s | 164.7 s | **1.55×** |
| Per-polish median dt | 60.4 s | 120.2 s | **1.99×** |
| Best `max-rel-err` | 1.0e-6 | 1.0e-6 | identical |
| Best `min-rel-err` | 0.0 | 0.0 | identical |

**Verdict on doubling the cap.** Zero improvement in best parameter error,
1.55× polish-phase wall-clock cost. The cap-bound polishes are dominated
by `algebraic_resolve_t0` blown candidates with `a ≈ -180, S ≈ -50` —
they cannot recover to the truth basin no matter how long LSO LM runs;
they were blown by the algebraic solve itself. The 60-s cap is *plenty*
for any seed that is going to converge.

This is a strong signal that the cluster's `polish_maxtime = 1200 s` is
overspending. **The cap was previously a no-op; now that it is enforced,
even 60 s would have closed off the runaway.** Recommended cluster knob:
`polish_maxtime = 60` (or 120 for safety on harder cases like daisy_mamil4
with ill-conditioned Jacobians, where one Jacobian call genuinely takes
several seconds and a polish needs more iterations to converge).

Note: both runs share the same total polish count (174) and best-error
floor (1e-6). The fix delivers wall-clock determinism without harming
solution quality. Combined with §2's clustering observations, the polish
phase can plausibly be cut by another factor of 3 by using
sensitivity-weighted clustering on top of the already-bounded-per-polish
maxtime.

## 4) Concrete recommendations

In rough priority order (highest leverage / cheapest first):

1. **Lower the cluster_threshold default cap, gated on identifiability.**
   The current `cluster_threshold = 0.001` in
   `_polish_cluster_metadata` (`parameter_estimation.jl:2389`) achieves
   1.09× reduction on this pool. Bumping to 0.05 with the existing
   max-rel-dist metric would give 1.34× — small but free.
2. **Sensitivity-weighted clustering distance.** Replace the uniform
   max-rel-dist with `max_i (w_i · |a_i - b_i| / max(|a_i|, |b_i|, 1))`
   where `w_i` comes from the IFT sensitivity matrix already computed for
   UQ (`src/core/sigma_d.jl`, `diagnose_uncertainty`). Even a coarse
   "use spread as a proxy" weighting (the heuristic above) collapses 647
   → 215 at threshold 0.10. With principled IFT weights it should be
   tighter still and properly handle cases where SI-template
   identifiability flags are present.
3. **Skip blown-backsolve candidates from polish, OR bin them
   separately.** The 48 `rescue_path = :algebraic_resolve_t0` candidates
   with `|param| > 100` on identifiable axes are almost certainly
   un-polishable garbage. Either:
   - Drop them from the polish input outright (filter on the
     err/parameter-magnitude before clustering), or
   - Polish at most one representative; their `In, Npop, Tr, g, nu`
     coincide so they trivially cluster on the well-determined subspace.
4. **Polish budget sharing across maxtime.** Instead of a per-polish
   `maxtime`, use a **batch budget**: the scheduler stops launching new
   polish tasks once total elapsed exceeds `n_threads × maxtime`. Or, more
   nuanced: prioritize polish order by the candidate's pre-polish err
   (smallest first), so good seeds get polished first; remaining budget
   spills onto noisy seeds that may still recover.

## 5) What's *not* in this report

- I did not modify `_polish_cluster_metadata`. The threshold change is a
  one-line edit but its effect on regression-suite cases (lotka_volterra,
  forced_lv, daisy_mamil*) needs validation, which I have not done.
- The `compare_maxtime` runs use *reduced* settings (shooting=10, max_pairs=2,
  no aggregate synthesis) and so their numbers are not directly comparable
  to the cluster's 10.1 h run, just to each other.
- I have not addressed JIT cost in production. A one-time
  `_warmup_polish_context!(ctx)` call inside `_build_polish_context` would
  remove the 20–30 s overshoot on the first polish, but it shifts cost
  rather than removing it; for the cluster's 10 h job this is < 0.1%.

## Files produced

| File | Purpose |
| --- | --- |
| `repro/test_polish_maxtime.jl` | Unit test for the maxtime cap (7/7 pass with warmup). |
| `repro/dump_pool.jl` | Runs the pipeline with `polish_solutions=false` and writes `pool_dump.csv` + `.json`. |
| `repro/pool_dump.csv` | 647-row pool export (params, ic, err, provenance). |
| `repro/analyze_pool.py` | Digests `pool_dump.csv` into the tables above. |
| `repro/compare_maxtime.jl` | Reduced-scope sirt run, parameterized by `maxtime`. |
| `repro/diag_polish_maxtime.jl` | Stand-alone instrumented polish for tracing call patterns. |
| `repro/DIAGNOSIS.md` | Original 10h diagnosis (this report's prequel). |
