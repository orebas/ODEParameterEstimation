# Receptor Fast Probe Findings - 2026-05-28

These are script-only repro findings. They do not change production solver code.

## Main Result

The failing operation is specifically HC.jl `ParameterHomotopy`, whose local
implementation is the real straight parameter path
`F(x; t * p_start + (1 - t) * p_target)`. It has no gamma option.

HC.jl's gamma option belongs to `StraightLineHomotopy` between fixed start and
target systems:

`gamma * t * F(x; p_start) + (1 - t) * F(x; p_target)`.

On receptor, that true gamma-trick is much more reliable than the parameter
path.

## Current Trim

Baseline three-point run, output: `out/baseline_homotopy.jsonl`.

- Fresh solves at points `1`, `37`, and `201` each found truth and swap.
- Straight parameter tracking lost truth and swap on `1->37`, `37->201`,
  `201->37`, and `37->1`.

True gamma straight-line homotopy, current trim:

- Long jump `1->201`: 10/10 seeds carried truth and swap.
  Output: `out_gamma_current/gamma_straight.jsonl`.
- Split path `1->37` and `37->201`: 10/10 seeds carried truth and swap on both
  segments.
  Output: `out_gamma_current_3pt/gamma_straight.jsonl`.

Complex parameter detours on current trim:

- Long jump `1->201`: best settings were good but not perfect:
  - 1 midpoint, `eta=0.03`: 9/10 seeds carried truth and swap.
  - 3 midpoints, `eta=0.1`: 9/10 seeds carried truth and swap.
  Output: `out_long_jump/complex_detour.jsonl`.
- Split path:
  - `1->37`: 0/10 for all tested detour settings.
  - `37->201`: best tested setting was 6/10.
  Output: `out/complex_detour.jsonl`.

Real path subdivision did not help: `1,2,4,8,16` real segments all lost every
tracked root on `1->201`. Output: `out/path_subdivision.jsonl`.

## Trim Variants

The alternate trim probes needed one harness fix: SIAN full equations use data
placeholders such as `y1_1` and `y2_8`; `common.jl` now canonicalizes them to
the template data variables before HC conversion.

Mixed-volume scan, output: `out/trim_probe.jsonl`.

- Current trim: mixed volume `6402`.
- `pins_low_order_first`: mixed volume `163`.
- `support_first`: mixed volume `163`.
- `pins_cap_4`: mixed volume `280`.
- `pins_cap_0`: mixed volume `585`.
- One random trim: mixed volume `8128`.

Solve-enabled trim scan:

- Low-BKK trims fresh-solve much faster and find truth/swap at the source.
- Straight parameter tracking still loses truth/swap.

Trim plus complex parameter detours:

- `support_first`, long jump `1->201`:
  - 1 midpoint, `eta=0.1`: 10/10 seeds.
  - 3 midpoints, `eta=0.03`: 10/10 seeds.
  - 3 midpoints, `eta=0.1`: 10/10 seeds.
  Output: `out_support_trim_detour/trim_complex_detour.jsonl`.
- `pins_low_order_first`, long jump `1->201`:
  best tested settings reached 9/10.
  Output: `out/trim_complex_detour.jsonl`.

Trim plus true gamma:

- `support_first`, long jump `1->201`: 10/10 seeds.
  Output: `out_gamma_support/gamma_straight.jsonl`.
- `support_first`, split path:
  - `1->37`: 10/10 seeds.
  - `37->201`: truth in 9/10, swap in 5/10, both in 4/10.
  Output: `out_gamma_support_3pt/gamma_straight.jsonl`.

Variable-cost trim frontiers:

- Active trim comparisons should keep the prior full-rank target: rank `32`
  against the same `32` solve variables. A rank `31` trim is not equivalent to
  a 31-variable square solve in the current probe; it leaves one local null
  direction in the 32-variable solve space.
- Deferred experiment: for noisy-data designs, inspect rank-deficient trims
  such as the observed-derivative cap-6 rank-31 case by projecting the Jacobian
  nullspace onto parameters. If the missing direction only moves nuisance jets,
  a lower-derivative formulation may still recover parameters after elimination
  or projection. This is intentionally out of scope for the current full-rank
  trim comparisons.

## Representation Changes

Output: `out/representation_probe.jsonl`.

- `y1 + y2` is conserved to about `8.9e-16`, so an automated rewrite is
  plausible.
- `sum_ca` and `sum_diff` reduce the selected system from 32 to 31 variables.
- However, inferred path counts/mixed volumes got worse:
  - original: `6402`, fresh solve about `123s`.
  - `sum_ca`: `7176`, fresh solve about `189s`.
  - `sum_diff`: `8044`, fresh solve about `226s`.

This simple representation rewrite is not a practical win as tested.

## Point Selection And Fallback

Output: `out/point_selection.jsonl`.

- Oracle derivative magnitudes are much larger on the left of the interval:
  max data value about `2.37e9` at `t=-0.5` versus `2.64e4` at `t=0.5`.
- This supports the existing scaling diagnosis, but point choice alone does
  not explain the homotopy collapse.

Output: `out/fallback_probe.jsonl`.

- The current "physical full-residual valid" filter found no usable source
  starts under the tested residual criterion.
- Count-based fallback is still too crude, but this specific filter is not yet
  a production-ready replacement.

## Practical Direction

The strongest practical candidate is:

1. Keep column scaling.
2. After a fresh source solve, track to target using HC.jl fixed-system
   `StraightLineHomotopy` with random complex gamma, not `ParameterHomotopy`.
3. Use all finite source roots, then classify/filter at the target.
4. Consider a low-BKK trim such as `support_first` for speed, but current trim
   plus gamma was more robust on the three-point split.

The most important implementation note is that "gamma-tricking parameter
homotopy" is not an HC.jl option on `ParameterHomotopy`; it is a different
homotopy construction between the fixed start and target systems.
