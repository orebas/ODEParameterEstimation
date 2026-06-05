# Handoff: Gamma Straight-Line Homotopy And Trim Findings

Date: 2026-05-28

Scope: receptor fast probes only. No production solver behavior has been changed.

## Executive Recommendation

Implement a new HC tracking mode that uses HC.jl's true gamma trick:

```julia
HomotopyContinuation.solve(hc_system, hc_system, start_solutions;
    start_parameters = p_start,
    target_parameters = p_target,
    gamma = cis(2pi * rand()),
    show_progress = false)
```

This is **not** `ParameterHomotopy`. It is HC.jl's fixed-system
`StraightLineHomotopy` between `F(x; p_start)` and `F(x; p_target)`:

```text
H(x,t) = gamma * t * F(x; p_start) + (1 - t) * F(x; p_target)
```

The existing production path uses:

```julia
HomotopyContinuation.solve(hc_system, prev_all_solutions;
    start_parameters = prev_params,
    target_parameters = current_params,
    show_progress = show_progress)
```

That calls HC.jl `ParameterHomotopy`, i.e. the straight parameter path:

```text
F(x; t * p_start + (1 - t) * p_target)
```

The local HC.jl implementation of `ParameterHomotopy` has no gamma argument.
Passing a gamma-like idea to parameter homotopy is therefore the wrong target.

## Evidence

Probe script:

- `repro/receptor_fast_probes_2026_05_28/gamma_straight_probe.jl`

Core probe function:

```julia
function gamma_track(sys, starts, p0, p1, gamma)
    elapsed = @elapsed res = HC.solve(sys, sys, starts;
        start_parameters = p0,
        target_parameters = p1,
        gamma = gamma,
        show_progress = false)
    sets = solution_sets(res)
    return (result = res, seconds = elapsed, finite = sets.finite, real = sets.real,
        histogram = path_histogram(res),
        success = count(pr -> (try pr.return_code == :success catch; false end),
            HC.path_results(res)),
        started = length(starts))
end
```

### Current Trim, Three-Point Split

Output:

- `repro/receptor_fast_probes_2026_05_28/out_gamma_current_3pt/gamma_straight.jsonl`

Shooting points were `[1, 37, 201]`, corresponding to times `[-0.5, -0.32, 0.5]`.

Fresh solve:

- Point/source for `1->37`: 16 finite, 8 real; truth and swap present.
- Point/source for `37->201`: 16 finite, 8 real; truth and swap present.

Existing straight parameter tracking:

- `1->37`: 4 finite/real, truth absent, swap absent.
- `37->201`: 2 finite/real, truth absent, swap absent.

Gamma straight-line tracking:

- `1->37`: 10/10 gamma seeds carried truth and swap.
- `37->201`: 10/10 gamma seeds carried truth and swap.

This is the strongest evidence because the current trim is the current
production-style equation set.

### Current Trim, Long Jump

Output:

- `repro/receptor_fast_probes_2026_05_28/out_gamma_current/gamma_straight.jsonl`

Result:

- Existing straight parameter path `1->201`: truth absent, swap absent.
- Gamma straight-line `1->201`: 10/10 gamma seeds carried truth and swap.

### Complex Parameter Detours Are Weaker

Output:

- long jump: `repro/receptor_fast_probes_2026_05_28/out_long_jump/complex_detour.jsonl`
- split path: `repro/receptor_fast_probes_2026_05_28/out/complex_detour.jsonl`

Best long-jump current-trim results:

- 1 midpoint, `eta=0.03`: 9/10 seeds carried truth and swap.
- 3 midpoints, `eta=0.1`: 9/10 seeds carried truth and swap.

Split path current-trim results:

- `1->37`: 0/10 for all tested complex parameter detours.
- `37->201`: best tested setting was 6/10.

Interpretation: deforming the parameter path into complex space helps in some
cases, but it is not the same fix. The true gamma straight-line homotopy is
more robust in these probes.

## Production Implementation Sketch

Production target:

- `src/core/homotopy_continuation.jl`
- current function: `solve_with_hc_parameterized`

Existing production algorithm:

1. Build `hc_system` with parameters.
2. Optionally apply column scaling once for all parameter points.
3. Fresh solve at first point:
   `HC.solve(hc_system; target_parameters = current_params)`.
4. For later points, track all previous finite solutions using
   `HC.solve(hc_system, prev_all_solutions; start_parameters, target_parameters)`.
5. If count drops below the initial count, fresh solve fallback.

Recommended implementation:

1. Add an option, e.g. `:homotopy_tracking_mode`, with values:
   - `:parameter` default initially
   - `:gamma_straight`
   - maybe `:gamma_straight_fallback`
2. Keep the same fresh solve at the first point.
3. When tracking from `prev_params` to `current_params`, use:

```julia
gamma = get(options, :gamma, nothing)
if isnothing(gamma)
    gamma = cis(2pi * rand(rng))
end

result = HomotopyContinuation.solve(hc_system, hc_system, prev_all_solutions;
    start_parameters = prev_params,
    target_parameters = current_params,
    gamma = gamma,
    show_progress = show_progress)
```

4. Collect solutions the same way:

```julia
all_solutions = HomotopyContinuation.solutions(result)
real_solutions_hc = HomotopyContinuation.solutions(result;
    only_real = true,
    real_tol = real_tol)
```

5. Preserve column scaling exactly as now. Gamma mode should operate on the
   already scaled `hc_system`, and the extraction path should unscale as before.
6. Do not only track real solutions. Track all finite source roots; truth/swap
   can move through complex space.
7. Seed policy:
   - try one random gamma first.
   - if target validation fails or path count is suspicious, retry a small
     number of gamma seeds, e.g. 3 or 5.
   - record gamma, path histogram, target finite count, real count, and elapsed
     time in diagnostics.
8. Fallback policy:
   - keep fresh fallback for now.
   - make gamma-straight the first fallback before fresh solving, or make it the
     default tracking mode behind an option.

Suggested first implementation:

```julia
function track_with_gamma_straight(hc_system, starts, p_start, p_target;
        show_progress = false,
        gamma = cis(2pi * rand()))
    HomotopyContinuation.solve(hc_system, hc_system, starts;
        start_parameters = p_start,
        target_parameters = p_target,
        gamma = gamma,
        show_progress = show_progress)
end
```

Then wire it into `solve_with_hc_parameterized` at the current tracking site.
The current tracking site is the branch that starts with:

```julia
result = HomotopyContinuation.solve(hc_system, prev_all_solutions;
    start_parameters = prev_params,
    target_parameters = current_params,
    show_progress = show_progress)
```

Replace that call only when the selected tracking mode is gamma-straight.

## Validation Criteria For The Implementation

Use the receptor probe as a regression target:

```bash
env ODEPE_RECEPTOR_FAST_OUT=repro/receptor_fast_probes_2026_05_28/out_gamma_current_3pt \
    ODEPE_RECEPTOR_FAST_POINTS=3 \
    ODEPE_RECEPTOR_GAMMA_CASES=current \
    ODEPE_RECEPTOR_FAST_SEEDS=1,2,3,4,5,6,7,8,9,10 \
    julia --startup-file=no repro/receptor_fast_probes_2026_05_28/gamma_straight_probe.jl
```

Expected result:

- ordinary parameter-straight rows lose truth/swap.
- gamma-straight rows preserve truth/swap on both `1->37` and `37->201`.

For production tests, do not depend on receptor-specific truth/swap labels.
Instead check:

- finite solution count does not collapse unexpectedly,
- at least one accepted real/physical branch survives,
- residuals after unscaling are acceptable,
- existing non-receptor examples are not slower or less reliable in default mode.

## Trim Findings

Probe scripts:

- `repro/receptor_fast_probes_2026_05_28/trim_probe.jl`
- `repro/receptor_fast_probes_2026_05_28/trim_complex_detour_probe.jl`
- `repro/receptor_fast_probes_2026_05_28/gamma_straight_probe.jl`

Important harness issue fixed:

- The full SIAN equation list uses data placeholders like `y1_1`, `y2_8`.
- The template data variables use expressions like `Differential(t, 1)(y1(t))`.
- Alternate trims can select placeholder equations that the current trim avoids.
- The probe harness now canonicalizes placeholders before HC conversion.
- If alternate trims are implemented in production, this mapping must be
  handled there too.

Mixed volume results:

| Trim | Mixed volume | Notes |
| --- | ---: | --- |
| current | 6402 | Current selected equations 1-32 |
| `pins_low_order_first` | 163 | Huge BKK reduction, uses many data pin equations |
| `support_first` | 163 | Same BKK as low-order pins, different ordering |
| `pins_cap_4` | 280 | Needs emergency high-order equations `[38,39,40]` |
| `pins_cap_0` | 585 | Needs emergency high-order equations `[34..40]` |
| random seed 1 | 8128 | Worse than current |

Solve-enabled trim results:

- `pins_low_order_first`: fresh solve about 19s, truth/swap present at source.
- `support_first`: fresh solve about 14s, truth/swap present at source.
- `pins_cap_4`: fresh solve about 21s, truth/swap present at source.
- `pins_cap_0`: fresh solve about 337s despite lower BKK; not attractive.
- All tested trims still lost truth/swap under ordinary straight parameter
  tracking.

Trim plus complex parameter detours:

- `support_first`, long jump `1->201`:
  - 1 midpoint, `eta=0.1`: 10/10 seeds.
  - 3 midpoints, `eta=0.03`: 10/10 seeds.
  - 3 midpoints, `eta=0.1`: 10/10 seeds.
- `pins_low_order_first` reached 9/10 in the tested settings.

Trim plus true gamma:

- `support_first`, long jump `1->201`: 10/10 seeds.
- `support_first`, split path:
  - `1->37`: 10/10 seeds.
  - `37->201`: truth in 9/10, swap in 5/10, both in 4/10.
- Current trim plus true gamma was more robust on the split path: 10/10 on both
  segments.

## Trim Recommendation

Do not make a low-BKK trim the production default yet.

Recommended path:

1. Implement gamma-straight tracking first on the current trim.
2. Add a diagnostics-only or opt-in trim policy interface.
3. Add `support_first` as an experimental trim policy because it has the best
   BKK reduction and good long-jump behavior.
4. Before defaulting to a low-BKK trim, validate it on:
   - receptor split paths,
   - receptor long jump,
   - branch completion,
   - non-receptor examples,
   - noisy/interpolated data, not only oracle data.

The reason to keep investigating trims is speed: reducing BKK from 6402 to 163
is enormous. The reason not to default them immediately is robustness: current
trim plus gamma was the only tested combination that was 10/10 on both split
segments.

## Bottom Line

The short-term fix is not "complexify parameter homotopy." It is:

1. keep the existing system/trim/column scaling,
2. after a fresh source solve, track all finite roots with fixed-system
   `StraightLineHomotopy` and random gamma,
3. retry a few gamma seeds before fresh fallback,
4. only then consider low-BKK trims as a speed optimization.
