# Multi-Point Polynomial System Research — Complete Writeup (2026-03-24)

## The Problem

ODEPE estimates ODE parameters by fitting GP interpolants to data, extracting derivatives, substituting into a SIAN-generated polynomial system, and solving with HC.jl. GP derivative accuracy degrades with order (order-2 is 25× worse than order-0 at 31 data points). We want to use data from 2+ time points to reduce the highest derivative orders needed.

## How the System Is Built

SIAN generates a polynomial template from the ODE via a 3-stage pipeline:
1. **Prolongation loop**: rank-based selection of output derivative equations + cascade of state equations
2. **Extra Y equations**: adds remaining valid output equations without rank check
3. **Algebraic independence trimming**: greedy row selection to get maximal independent subset

No Groebner bases in system construction (only in separate global identifiability testing).

The template is instantiated at a time point by substituting GP interpolation values for observable derivatives.

## The Right Way to Think About It

The polynomial system has two kinds of equations:

**Structural equations (CHOICES):** These are the k-th time derivatives of the ODE equations F. Each one is an exact algebraic relationship between state derivative variables and parameters. Choosing to include the k-th derivative equation brings in state derivative variables up to order k+1.

**Data equations (CONSEQUENCES):** These pin observed state derivative variables to interpolated values: `constant - variable = 0`. They are NOT independent choices — they are a NECESSARY CONSEQUENCE of including a structural equation that references an observed derivative. If a structural equation introduces `r_3` and `r` is observed, we MUST request `r_3` from the interpolator.

**The fundamental accounting:**
- Each structural equation adds 1 equation and potentially introduces new state derivative variables
- For each new OBSERVED state derivative, a data equation is automatically added (1 eq + 0 new vars, since the variable was already introduced by the structural equation)
- For each new UNOBSERVED state derivative, we may need another structural equation to close the system

**At 1 point:** The system is square — SIAN's prolongation ensures this.

**At N points:** Each point contributes its own copy of structural and data equations (with separate state variables but shared parameters). The parameters become overdetermined by `n_params * (N-1)`. To get back to square, we need to REMOVE structural equations (and their data consequences automatically go away too).

**Which structural equations to remove:** The ones that generate the HIGHEST-ORDER interpolation requests. Removing a high-order structural equation eliminates the need for high-order derivative data, which is exactly the noisiest data.

## What We Built and Tested

### Template combination approach
Take the standard template, instantiate at 2 points, rename per-point state variables (YES they are properly separated — `x_0` vs `x_0_pt2`), combine, select a square subset.

### Greedy equation selection
We tried sorting equations by various criteria and greedily adding them if they increase Jacobian rank. Key findings:

- **The processing ORDER matters** for the greedy algorithm. Processing all of one point first can get stuck (24/25 for lotka_volterra with A-first or B-first ordering). Interleaving (A1,B1,A2,B2,...) avoids this.
- **Interleaved greedy works well** for most models. Results with 2 points, 51 data points, 0 noise:

| Model | 1pt best err | 2pt interleaved err | 2pt best random | Improvement |
|-------|-------------|--------------------|-----------------|----|
| simple | 0.000 | 0.000 | 0.000 | — |
| lotka_volterra | 0.034 | 0.002 | 0.0003 | 17× |
| fitzhugh_nagumo | 65.9 | NOT SQ (one run) / 1.87 (random) | 1.87 | 35× |
| forced_lv_sinusoidal | 0.89 | 0.45 | — | 2× |
| biohydrogenation | 1.18 | 3.06 (worse) | timeout | — |

### QR pivot selection
Rank-revealing QR on J^T gives a principled row selection. BUT it produces systems with much higher algebraic degree (13 solutions vs 2 for lotka_volterra). QR optimizes for numerical conditioning, not algebraic structure. It preferentially selects higher-order equations (larger Jacobian entries) which is exactly wrong for our problem. **QR is not the right tool here.**

### Key equation structure analysis (lotka_volterra)

```
STRUCTURAL equations (9 total, these are the CHOICES):
  Eq 2:  d/dt(F)    max_ord=1
  Eq 5:  d/dt(F)    max_ord=1
  Eq 4:  d²/dt²(F)  max_ord=2
  Eq 8:  d²/dt²(F)  max_ord=2
  Eq 7:  d³/dt³(F)  max_ord=3
  Eq 11: d³/dt³(F)  max_ord=3
  Eq 10: d⁴/dt⁴(F)  max_ord=4
  Eq 14: d⁴/dt⁴(F)  max_ord=4
  Eq 13: d⁵/dt⁵(F)  max_ord=5

DATA equations (5 total, these are CONSEQUENCES):
  Eq 1:  pin r_0  (order 0 — function value, accurate)
  Eq 3:  pin r_1  (order 1 — first derivative)
  Eq 6:  pin r_2  (order 2 — second derivative)
  Eq 9:  pin r_3  (order 3 — third derivative, noisy)
  Eq 12: pin r_4  (order 4 — fourth derivative, very noisy)
```

At 2 points, overdetermined by 3 (= n_params). Remove the 3 highest-order structural equations (Eq 13 ord=5, Eq 10 ord=4, Eq 14 ord=4). This eliminates the need for r_4 and r_5 derivative requests. The multi-point prolongation independently found the same result: β goes from [5] to [[4],[3]].

## Bugs Found and Fixed

### 1. `convert_to_hc_format` string replacement collision
**File:** `src/core/homotopy_continuation.jl:630-644` and `:866-880`
**Bug:** `replace(s, mapping...)` doesn't guarantee longest-match. Variable `x2_0` matches inside `x2_0_pt2`, corrupting the equation string.
**Fix:** Two-pass replacement with unique placeholders, sorted by key length descending.
**Impact:** ALL previous "HC.jl finds 0 solutions on combined systems" were caused by this. Tests: 96/96 pass after fix.

### 2. Derivative order parsing for renamed variables
**Bug:** `parse_derivative_variable_name("r_1_pt2")` incorrectly returns order=2 (parses last `_N` as the derivative order, but `_pt2` is the point suffix, not the order).
**Fix:** Strip `_ptN` suffix before parsing: `replace(name, r"_pt\d+$" => "")` then parse.
**Impact:** The "low-order-first" strategy was treating ALL point B equations as order 0, making it equivalent to the default interleaved ordering. With the fix, low-order preference works correctly but still produces the same selection as interleaved for the tested models.

### 3. Greedy ordering sensitivity
**Bug:** Processing all of one point's equations first (A1..A14, then B1..B14) can get stuck at rank N-1 because the Nth rank direction requires two equations from the other point simultaneously.
**Fix:** Interleave equations from both points (A1,B1,A2,B2,...).
**Impact:** Interleaved ordering reliably reaches square for all models except biohydrogenation.

## Next Steps

### The correct algorithm (based on the structural understanding above)

1. Start with the full multi-point system (all structural + all data equations from all points)
2. Identify the structural equations by derivative level
3. Remove the highest-level structural equations first (starting from the top)
4. When a structural equation is removed, also remove the data equations it uniquely required
5. After each removal, check if the system is square
6. Stop when square
7. Verify rank (should be automatic if the removal respects the prolongation structure)

This is a top-down approach: start overdetermined, strip from the top. It's deterministic, ordering-independent, and directly implements the principle "avoid the highest-order derivative requests."

### Models to test
- lotka_volterra (3 params, 1 obs — needs high derivatives, should show big improvement)
- forced_lv_sinusoidal (4 params, transcendental — our main benchmark)
- biohydrogenation (6 params, 2 obs — previously couldn't reach square)
- hiv (10 params, 4 obs — large system)
- fitzhugh_nagumo (3 params, 1 obs — single observable)

### Experiment 8 v3 results (with all bug fixes, 2 points, n=51, noise=0)

| Model | 1pt best | Interleaved | Low-ord | Random(5) | Improve |
|-------|---------|-------------|---------|-----------|---------|
| simple | 0.000 | 0.000 | 0.000 | 0.000 | 1.7× |
| lotka_volterra | 0.513 | NOT SQ | NOT SQ | **0.054** | **9.4×** |
| fitzhugh_nagumo | 65.86 | NOT SQ | NOT SQ | **1.87** | **35.2×** |
| forced_lv_sin | 0.888 | **0.450** | **0.450** | 1.94 | **2.0×** |
| biohydrogenation | 1.182 | 3.06 (4 sols) | 3.06 | timeout | 0.4× |
| hiv, daisy, seir, treatment | — | not reached (biohydro timeout) | — | — | — |

**HC.jl scalability is the main bottleneck.** The mixed cell computation for the 44-var biohydrogenation system takes 28+ minutes per attempt. Random permutation search is impractical for systems over ~30 variables.

**Interleaved vs low-order interleaved:** With the derivative parsing fix, these now select DIFFERENT equations (verified on lotka_volterra), but produce the SAME accuracy for the tested models.

**Interleaved fails at NOT SQUARE for lotka_volterra and fitzhugh_nagumo** but random permutations find working selections. This is the greedy ordering sensitivity issue.

### Experiment 9: Top-down stripping — PARTIAL (has a bug)

The simple "remove highest-order structural equations" approach doesn't reach square because:
- Removing a structural equation makes some variables orphaned (reduces var count)
- But the data equations pinning those orphaned variables may also pin variables that OTHER structural equations still need
- So the variable removal partially cancels the equation removal, and the gap doesn't close

**The fix:** After removing a structural equation, recompute which observed derivatives are still NEEDED by the remaining structural equations. Remove data equations for derivatives that are no longer needed by ANY structural equation. Then recompute orphaned variables.

This is a dependency graph: structural equations → needed variables → data equations. Removing a structural equation can cascade through: if no other structural equation needs variable X, then the data equation pinning X can also be removed, and variable X becomes orphaned.

**Fixed:** After each structural equation removal, recompute which observed derivatives are still needed. Remove data equations for derivatives no longer needed by ANY structural equation. This properly cascades the removal and reaches square.

### Experiment 9 v2 Results (2 points, n=51, noise=0)

| Model | 1pt err | 2pt err | Improve | HC sols | HC time | Bezout |
|-------|---------|---------|---------|---------|---------|--------|
| simple | 0.000 | 0.000 | — | 1 | 2.4s | 4 |
| **lotka_volterra** | 0.513 | **0.073** | **7.1×** | 2 | 3.5s | 177K |
| fitzhugh_nagumo | 65.86 | 66.76 | 1.0× | 2 | 4.0s | 65K |
| **forced_lv_sin** | 0.888 | **0.450** | **2.0×** | 1 | 2.6s | 81 |
| biohydrogenation | 1.182 | HC FAIL | — | 0 | — | 2.6M overflow |
| hiv | 0.471 | 5.49 | 0.1× worse | 2 | 6.3s | 47.8M |
| daisy_mamil3 | 0.008 | HC FAIL | — | 0 | — | 2K overflow |
| **seir** | 0.753 | **0.060** | **12.5×** | 2 | 7.9s | 5.5B |
| treatment | 1.670 | 94.33 | 0× worse | 2 | 16.4s | — |

**All 9 models reach SQUARE deterministically.** No ordering sensitivity, no random search.
3/9 improve (lotka_volterra 7×, forced_lv 2×, seir 12.5×).
2/9 fail due to HC.jl Bezout overflow.
3/9 get worse (hiv, treatment significantly; fitzhugh_nagumo trivially).
1/9 unchanged (simple).

HC.jl is fast when it works (2-17s) despite enormous Bezout bounds. The mixed volume (actual paths) is tiny (1-15).

**HC.jl issues:**
- biohydrogenation: Bezout 2,654,208 → OverflowError in start system
- daisy_mamil3: Bezout 2,048 → same overflow (surprising at such small Bezout!)
- Both are square systems that should be solvable — the overflow is an HC.jl implementation issue, not mathematical

**Models that got worse:** hiv and treatment found solutions with higher error than 1-point. This could be because the top-down stripping removes equations that were important for distinguishing the correct branch from spurious ones. The 1-point system had a better selection of equations for those models.

### HC.jl failure investigation (biohydrogenation)

The 26×26 stripped biohydrogenation system has Bezout 2,654,208. All HC.jl methods fail:
- Polyhedral: OverflowError in start system
- Total degree: 2.6M paths = hours
- Monodromy: needs a starting solution but can't find one
- Newton from random: fails to converge (best residual 484)

**However:** HC.jl works fine on the 1-point 25×25 system (4 solutions in 54s, best err=1.18). This means we can:
1. Solve each point independently with HC.jl (works)
2. Combine the two good 1-point solutions into a starting point for the 2-point system
3. Use monodromy from that starting point to find all solutions of the 2-point system

This is Strategy D: HC.jl for topology on the 1-point system, monodromy for the multi-point system starting from the 1-point solutions. Not yet implemented.

### ROOT CAUSE of HC.jl failure: Mixed volume = 0 (2026-03-25)

The 2-point stripped biohydrogenation system has **mixed volume 0** — meaning the Newton polytopes don't span the full space. HC.jl's polyhedral homotopy correctly can't compute a start system.

Key comparison:
- 1-point 25×25: Bezout 23.9M, mixed volume > 0, HC.jl solves in 54s (4 solutions)
- 2-point 26×26 stripped: Bezout 2.6M, **mixed volume = 0**, HC.jl fails

The top-down stripping produced a system that is algebraically valid (square, full Jacobian rank at generic points) but polytopally degenerate. The removed equations were needed for the Newton polytope structure even though they weren't needed for the Jacobian rank.

Equation degrees in the 2-point stripped system: 12 data (degree 1) + 14 structural (degrees 2-4). Product of degrees = 2,654,208. But the mixed volume is 0 because the high-degree monomials don't span enough directions when combined with the many degree-1 (data) equations.

**This suggests the stripping is too aggressive** — it removes structural equations that, while algebraically redundant for rank, are needed for the polytope structure. A less aggressive stripping (keeping more structural equations, allowing a non-square system solved by least-squares) might be better.

Or: monodromy starting from 1-point solutions would bypass the mixed volume issue entirely.

### Experiment 9 v3: Rank-Aware Stripping (2026-03-26)

**The fix:** Added Jacobian rank checking to the stripping loop. Pre-compute the full Jacobian once, check `rank(J[kept_rows, :])` at each removal step. If rank drops below `remaining_var_count`, restore the equation and skip it.

For biohydrogenation, the rank guard fires 5 times — preventing 5 structural equation removals that would have broken algebraic independence. The algorithm finds a different, larger stripped system that preserves rank.

For daisy_mamil3, the rank guard fires 3 times, fixing the previous HC.jl overflow.

**Results (2 points, n=51, noise=0):**

| Model | 1pt err | 2pt err | Improve | Sols | Time |
|-------|---------|---------|---------|------|------|
| simple | 0.000 | 0.000 | — | 1 | 2.1s |
| **lotka_volterra** | 0.513 | **0.073** | **7.1×** | 2 | 3.6s |
| fitzhugh_nagumo | 65.86 | 66.76 | 1.0× | 2 | 3.4s |
| **forced_lv_sin** | 0.888 | **0.450** | **2.0×** | 1 | 2.7s |
| biohydrogenation | 1.182 | 3.07 | 0.4× | 4 | 11.5s |
| hiv | 0.471 | 5.49 | 0.1× | 2 | 5.6s |
| **daisy_mamil3** | 0.008 | **0.003** | **2.9×** | 1 | 8.8s |
| **seir** | 0.753 | **0.060** | **12.5×** | 2 | 18.8s |
| treatment | 1.670 | 94.33 | 0× | 2 | 17.8s |

**ALL 9 models now produce solvable systems.** No more HC.jl failures.
4/9 improve (lotka_volterra 7×, forced_lv 2×, daisy_mamil3 2.9×, seir 12.5×).
3/9 get worse (biohydro, hiv, treatment — need investigation).
2/9 neutral (simple, fitzhugh_nagumo).

### What to measure
- Which derivative orders are eliminated
- HC.jl solution count and accuracy
- Comparison to 1-point baseline at same data settings
- Whether it matches the prolongation results (which independently found the same derivative reductions)

## Code and Scripts

| File | Purpose |
|------|---------|
| `src/core/homotopy_continuation.jl:630-644` | Fixed string replacement bug |
| `experiments/multipoint/analyze_lv_careful.jl` | Detailed lotka_volterra analysis |
| `experiments/multipoint/analyze_flv_careful.jl` | Detailed forced_lv analysis |
| `experiments/multipoint/analyze_equation_structure.jl` | Structural vs data equation classification |
| `experiments/multipoint/exp08_interleaved.jl` | Interleaved greedy benchmark |
| `experiments/multipoint/exp04_multipoint_prolongation.jl` | Multi-point prolongation (Nemo ring) |
| `temp_plans/2026-03-23_multipoint_complete_record.md` | Full experiment log |
