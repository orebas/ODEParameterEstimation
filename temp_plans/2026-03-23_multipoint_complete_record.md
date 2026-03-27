# Multi-Point Polynomial System Research — Complete Record (2026-03-23)

## Overview

Goal: Construct polynomial systems using data from 2+ time points with shared parameter unknowns, reducing dependence on noisy high-order GP derivatives. This is a research investigation, not yet integrated into the ODEPE pipeline.

All experiment scripts are in `experiments/multipoint/`.

---

## Part 1: Background — How the System Is Built

### The SIAN → ODEPE pipeline

The polynomial system ODEPE solves comes from SIAN, processed in 3 stages inside `get_polynomial_system_from_sian` (`si_equation_builder.jl:846-1068`):

**Stage 1 — Prolongation loop (lines 899-941):**
SIAN builds derivative chains X[i][j] (state) and Y[i][j] (output) by repeatedly applying the Lie derivative (chain rule through the ODE). Then iteratively selects Y equations that increase Jacobian rank at a generic random point. For each accepted Y equation, cascades X equations for any new state variables. Net effect per Y step: +1 equation, +0 net variables (cascade adds equal eqs and vars). System starts at Δ = -(n_params + n_ICs), each Y step adds +1.

**Stage 2 — Extra Y equations (lines 943-957):**
After the loop, adds ALL remaining Y equations whose variables are already in `x_theta_vars`, WITHOUT a rank check. Can make the system overdetermined.

**Stage 3 — Algebraic independence trimming (lines 1018-1030):**
Runs `algebraic_independence()` (`si_equation_builder.jl:565-605`) which greedily selects a maximal independent equation subset via Jacobian rank at a generic point. Trims back to (approximately) square.

**No Groebner bases in system construction.** Groebner is only used in SIAN's `identifiability_ode` (SIAN.jl:267) for global identifiability testing. Confirmed by reading all SIAN source files.

### After template creation

`construct_equation_system_from_si_template` (`si_template_integration.jl:23-290`) instantiates the template at a specific time point by substituting GP interpolation values for observable derivative variables. The result is a polynomial system in parameters + state derivatives, with numerical constants from interpolation baked in.

### Key SIAN infrastructure

- `add_to_vars_in_replica(poly, mu, new_ring, r)` (`SIAN/src/util.jl:354-389`): Dead code that renames non-parameter variables by appending `_r`. Written for multi-point but never called. Has a bug: uses `mu` (original ring param names) but jet ring params have `_0` suffix. We wrote a custom `lift_poly` instead.
- `create_jet_ring(var_list, param_list, max_ord)` (`util.jl:132-135`): Jet ring constructor.
- `differentiate_all(poly, gens, shft, max_ord)` (`util.jl:143-149`): Lie derivative.
- `sample_point(D1, x_vars, y_vars, u_vars, params, X_eq, Y_eq, Q)` (`sample_point.jl`): Random generic point for rank testing.
- `jacobi_matrix(polys, vars, vals)` (`util.jl:58-66`): Jacobian evaluated at a point.

---

## Part 2: Experiments

### Experiment 0: SI.jl Multi-Experiment Identifiability (exp00_si_me_query.jl, exp00b_me_and_deriv_orders.jl)

**Method:** Called `StructuralIdentifiability.assess_local_identifiability(si_ode; type=:ME)` on test models via `StructuralIdentifiability.mtk_to_si(model, mq)` which returns `(ODE_object, var_map)`.

**Results:** `num_exp=1` for ALL tested models (simple, lotka_volterra, forced_lv_sinusoidal, vanderpol, harmonic, crauste, hiv, seir). Multi-point is NOT needed for structural identifiability — benefit is purely numerical.

**PAL warning:** `:ME` models independent experiments with separate ICs, not multiple time samples from one trajectory. Don't conflate.

**Derivative order sweep:** Tried capping `good_deriv_level` at lower orders. Found that the TEMPLATE SIZE doesn't change — `good_deriv_level` controls which data values get substituted, not the equation count. The template is fixed by SIAN.

### Experiment 1: Equation Census (exp01_equation_census.jl)

**Method:** For each model, classified every template equation as DATA (carries interpolation noise, identified by different residuals between production and oracle interpolants) vs STRUCTURAL (exact ODE relation, zero residual difference).

**Key findings:**
- Equations alternate: DATA equations pin state derivative variables to interpolated constants; STRUCTURAL equations encode ODE relationships.
- Interpolation error grows with derivative order: for forced_lv_sinusoidal at n=31, order-0 error ~0.05, order-1 ~1.3-2.8, order-2 ~6.5-6.8.
- At 2 points, overdetermination = n_params exactly.

### Experiment 2: Variable Renaming + Jacobian Rank (exp02_multipoint_system.jl)

**Method:** Instantiated template at 2 points, renamed per-point state variables using `Symbolics.variable(Symbol(base * "_pt2"))`, combined, checked Jacobian rank at oracle values.

**Key finding:** Must use plain `Symbolics.variable(:name)` (no `(t)` suffix), not `@variables name(t)`. SIAN template variables don't have `(t)`. The HC.jl string-based converter (`convert_to_hc_format` in `homotopy_continuation.jl:615-646`) does text replacement that breaks with `(t)` suffix collisions (e.g., `x2_0(t)` matches inside `x2_0_pt2(t)`).

**Results:** Combined 2-point systems have full Jacobian rank for most models/strategies. Multiple drop strategies tested (split, drop from A only, drop from B only).

### Experiment 3: HC.jl Solve with Equation Dropping (exp03_hcjl_solve.jl)

**Method:** Took the combined 2-point system, dropped n_params equations to make it square, tried HC.jl.

**Result:** HC.jl finds ZERO solutions for ALL models, ALL drop strategies. This was interpreted as the system being positive-dimensional (dropping equations removes constraints).

**Later corrected:** This interpretation was wrong. The systems DO have isolated roots (Newton converges). HC.jl fails to track solutions through the homotopy — it's an HC.jl numerical issue, not a mathematical one.

### Experiment 4: Multi-Point Prolongation (exp04_multipoint_prolongation.jl)

**Method:** Re-implemented SIAN's prolongation algorithm (Stage 1 only) with multi-point structure:
1. Created extended Nemo jet ring with per-point state/output variables and shared parameters
2. Lifted X and Y equation chains to both points using custom `lift_poly` function
3. Ran the rank-based selection loop trying Y equations from either point
4. Cascade adds X equations for the correct point

**Custom `lift_poly` function** (in exp04, lines ~96-130): Maps Nemo polynomial from single-point ring to combined ring. For each ring variable: if it's a parameter (in `not_int_cond_params`), maps to the shared name; otherwise appends `_point_idx`. Uses `Nemo.MPolyBuildCtx` for term-by-term reconstruction. Correctly handles the naming convention difference between `mu` (original ring: "a") and `not_int_cond_params` (jet ring: "a_0").

**Results — derivative order reduction (ALL models):**

| Model | States | Params | Obs | 1pt β | 2pt β | Max order |
|-------|--------|--------|-----|-------|-------|-----------|
| simple | 2 | 2 | 2 | [2,2] | [[2,2],[1,1]] | 2→2 |
| lotka_volterra | 2 | 3 | 1 | [5] | [[4],[3]] | 5→4 |
| forced_lv_sinusoidal | 4 | 4 | 4 | [1,3,3,1] | [[1,2,2,1],[1,2,2,1]] | 3→2 |
| harmonic | 2 | 2 | 2 | [2,2] | [[2,2],[1,1]] | 2→2 |
| seir | 4 | 3 | 2 | [6,1] | [[5,1],[4,1]] | 6→5 |
| hiv | 5 | 10 | 4 | [4,4,4,3] | [[3,3,3,3],[2,2,2,2]] | 4→3 |
| treatment | 4 | 5 | 2 | [7,1] | [[6,1],[5,1]] | 7→6 |
| crauste | 5 | 13 | 4 | [4,3,6,5] | [[3,2,4,4],[2,2,3,3]] | 6→4 |
| daisy_ex3 | 4 | 5 | 2 | [8,1] | [[6,1],[5,1]] | 8→6 |
| daisy_mamil3 | 3 | 5 | 2 | [5,3] | [[4,2],[3,2]] | 5→4 |
| fitzhugh_nagumo | 2 | 3 | 1 | [5] | [[4],[3]] | 5→4 |
| slowfast | 6 | 2 | 4 | [3,?,?,?] | [[3,...],[3,...]] | 3→3 |
| biohydrogenation | 4 | 6 | 2 | [6,3] | [[4,2],[4,2]] | 6→4 |

**13/14 models show derivative order reduction.** Only slowfast unchanged.

**Squareness:** 12/14 square. Exceptions: biohydrogenation (32×34, needs 3 points) and treatment (1-point already non-square due to unidentifiable `a`).

### Experiment 4D/4E: HC.jl Solve on Prolongation Systems (exp04d_hcjl_solve.jl, exp04e_hcjl_with_real_data.jl)

**Method:** Converted multi-point prolongation equations from Nemo → Symbolics (using `nemo_to_symbolics` with a custom var_map for the combined ring), substituted real GP interpolation values for observable derivatives, solved with HC.jl.

**Data variable mapping:** SIAN output names (y1, y2) → measured quantities → interpolant keys. For `_obs_trfn_` observables, used `evaluate_obs_trfn_template_variable` for analytical values. The SIAN output ordering doesn't match the measured_quantities ordering — must match by name, not index.

**Results:** HC.jl finds solutions for simple (1 sol), lotka_volterra (2 sols), forced_lv_sinusoidal (1 sol).

### Experiment 4F: Forced LV Production Accuracy (exp04f_forced_lv.jl)

**Method:** Ran multi-point prolongation system with real GP data for forced_lv_sinusoidal at n=31, tested multiple time point pairs.

**Results:**

| Points | Solutions | Max rel error | Parameters |
|--------|----------|---------------|------------|
| Best 1-point | 1 | **2.10** (210%) | baseline |
| t=(1.3, 8.3) | 1 | **0.36** (36%) | α=1.39 β=0.64 γ=3.47 δ=0.61 |
| t=(3.0, 6.7) | 1 | **0.62** (62%) | α=2.43 β=1.17 γ=2.24 δ=0.38 |
| t=(1.7, 6.7) | 1 | **0.87** (87%) | α=1.45 β=0.85 γ=0.40 δ=0.28 |

**5.8× improvement at best point pair.** Well-separated points work better.

### Experiment 4G: Hard Models (exp04g_hard_models.jl)

Ran multi-point prolongation (Stage 1) on 9 hard benchmark models. Results in the derivative order table above. Did NOT test accuracy — only structural properties (squareness, β values).

### Experiment 5: Option C — Template Combination + Algebraic Independence (exp05_option_c.jl)

**Method:** Took existing fully-processed template, instantiated at 2 points, combined, ran greedy Jacobian row selection at oracle values, tried HC.jl.

**Results:** Greedy selector picks equations from both points (8 from A + 6 from B for simple). System is square with full Jacobian rank. **HC.jl finds 0 solutions.**

**But then:** Newton from oracle starting values converges to ||F||=5e-17 in 3 iterations on the same system. **The root EXISTS. HC.jl fails to find it.** This is an HC.jl homotopy tracking issue, not a mathematical problem.

### CORRECTION: HC.jl failure was a STRING REPLACEMENT BUG (discovered 2026-03-23 late)

All previous "HC.jl finds 0 solutions" results for combined systems were caused by a bug in `convert_to_hc_format`'s string-based variable replacement. When variable names are substrings of each other (e.g., `x2_0` inside `x2_0_pt2`), the replacement corrupts the equation string.

**The fix:** Two-pass replacement with unique placeholders (implemented in `hcjl_diagnostic.jl`):
1. Replace variable names with unique non-printable placeholders (longest first)
2. Replace placeholders with `hmcs("...")` calls

After fixing: HC.jl works correctly on combined systems:
- simple greedy 14×14: 1 path, 1 real solution ✓
- simple overdetermined 16×14: 1 path, 1 real solution ✓
- forced_lv greedy 20×20: 1 path, 1 real solution (but same accuracy as 1-point)
- forced_lv overdetermined 24×20: 0 paths (HC.jl can't handle overdetermined)

**This means ALL previous "positive-dimensional" conclusions were WRONG.** The systems were fine; the conversion was broken.

### Discovery: Gauss-Newton on Overdetermined System (inline experiment)

**Method:** Instead of making the combined system square, ran Gauss-Newton directly on the full overdetermined system (24 eqs × 20 vars for forced_lv_sinusoidal).

**Results:**
```
Iter 1: ||F||=315.2
Iter 4: ||F||=5.37
Iter 6: ||F||=4.95  (converged — nonzero residual expected for overdetermined noisy system)
alpha=1.14 (24% err), beta=0.61 (39%), gamma=2.89 (4%), delta=0.35 (29%)
Max rel error: 39%  vs  1-point best: 210%  →  5.4× improvement
```

**This means:** We don't need HC.jl for multi-point. The overdetermined system + Gauss-Newton works directly. No squareness needed, no equation dropping, no zero-dimensionality concerns.

---

## Part 3: Understanding Squareness

### The mechanism

The prolongation loop maintains Δ = |Et| - |x_theta_vars|. Starts at Δ = -(n_params + n_ICs). Each accepted Y step: Δ += 1. The cascade adds equal eqs and vars (one X equation per new state variable), so cascade doesn't change Δ. Square when Δ = 0.

For multi-point: Δ starts at -(n_params + n_points × n_ICs). More Y candidates from multiple points, but need more steps to reach Δ=0 (deeper hole due to per-point ICs).

### Why it fails for some models

**treatment (1-point):** Δ starts at -9 (5 params + 4 ICs). Gets 8 Y steps, ends Δ=-1. The 9th Y equation doesn't increase rank. Parameter `a` is structurally unidentifiable — the Bilby benchmark pins it, reducing vars by 1 → square.

**biohydrogenation (2-point):** Δ starts at -14 (6 params + 2×4 ICs). Gets 12 Y steps, ends Δ=-2. Two outputs can't produce 14 independent equations across 2 points.

### The `algebraic_independence` function (si_equation_builder.jl:565-605)

Greedy row selector. Computes full Jacobian of all equations w.r.t. all variables at a generic random point. Iterates through equations in order; keeps each equation if it increases the row rank of the accumulated Jacobian. Returns indices of selected equations.

**What it selects FOR:** Maximal Jacobian rank at a generic point. This tests algebraic independence of the equations. It does NOT test or guarantee zero-dimensionality.

**Key limitation for multi-point:** At a GENERIC random point (from SIAN sampling), equations from two different time points with the same polynomial structure are algebraically distinct (different numerical constants from different interpolation values). So the selector correctly identifies independent equations from both points. But the resulting square system may still have homotopy tracking issues for HC.jl.

---

## Part 4: Open Questions and Ideas for Moving Forward

### HC.jl reliability question

HC.jl finds 0 solutions on combined multi-point systems that provably have isolated roots (Newton converges). This needs investigation:
- Is it a degree explosion? (The combined system may have much higher algebraic degree than the 1-point system)
- Is it a numerical precision issue in the homotopy tracking?
- Is the `convert_to_hc_format` string-based conversion introducing errors?
- Does HC.jl's start system not cover all solutions for the combined polynomial structure?

### Strategy D (HC.jl + Gauss-Newton hybrid)

The most promising practical approach:
1. HC.jl on the standard 1-point system → find algebraic branches (this already works)
2. For each HC.jl solution, use as starting point for Gauss-Newton on the multi-point overdetermined system → refine with data from multiple points
3. Score by multi-point residual

This sidesteps ALL HC.jl issues with multi-point systems. The 1-point HC.jl works fine; the multi-point refinement uses least-squares.

**Not yet tested:** Using HC.jl's 1-point solution as the starting point for multi-point GN. The oracle starting point test shows GN works; need to verify it works from the (imperfect) HC.jl starting point.

### Does the prolongation structure matter for GN?

Two approaches to building the multi-point system for GN:
- **Option B (prolongation):** Run multi-point prolongation → produces a system with structurally reduced derivative orders. The equations selected by the prolongation may be better conditioned.
- **Option C (template combination):** Just instantiate the standard template at 2 points, combine, use all equations. Simpler, but uses all derivative orders (including the noisy high-order ones).

**Not yet tested:** Whether GN on Option B's equations gives better results than GN on Option C's equations. The prolongation avoids high-order derivatives structurally; Option C includes them but GN might downweight them naturally through least-squares.

### PAL recommendation to upgrade polish step

The current "polish" step uses BFGS (generic scalar optimizer). PAL recommended Gauss-Newton or Levenberg-Marquardt (residual-structure-aware). The multi-point GN could be integrated as an upgraded polish step.

### Models to test accuracy on

Haven't yet tested Gauss-Newton accuracy on: hiv, crauste, treatment, biohydrogenation, daisy_ex3, fitzhugh_nagumo. These are the Bilby benchmark models where ODEPE struggles.

---

## Part 5: Code References

| File | Lines | What |
|------|-------|------|
| `SIAN/src/SIAN.jl` | 119-155 | Prolongation loop (the core algorithm) |
| `SIAN/src/SIAN.jl` | 267 | Groebner basis for global identifiability (NOT for system construction) |
| `SIAN/src/get_x_eq.jl` | 1-18 | X equation derivative chains |
| `SIAN/src/get_y_eq.jl` | 1-18 | Y equation derivative chains |
| `SIAN/src/util.jl` | 132-135 | `create_jet_ring` |
| `SIAN/src/util.jl` | 143-149 | `differentiate_all` (Lie derivative) |
| `SIAN/src/util.jl` | 58-66 | `jacobi_matrix` |
| `SIAN/src/util.jl` | 354-389 | `add_to_vars_in_replica` (dead code, buggy for our use) |
| `SIAN/src/sample_point.jl` | 22-56 | Random generic point sampling |
| `si_equation_builder.jl` | 565-605 | `algebraic_independence` (greedy row selector) |
| `si_equation_builder.jl` | 846-1068 | `get_polynomial_system_from_sian` (full 3-stage pipeline) |
| `si_equation_builder.jl` | 899-941 | Stage 1: prolongation |
| `si_equation_builder.jl` | 943-957 | Stage 2: extra Y equations |
| `si_equation_builder.jl` | 1018-1030 | Stage 3: algebraic independence trimming |
| `si_equation_builder.jl` | 1138-1250 | `nemo_to_symbolics` (Nemo → Symbolics conversion) |
| `si_template_integration.jl` | 23-290 | `construct_equation_system_from_si_template` (instantiation) |
| `homotopy_continuation.jl` | 559-567 | `sanitize_vars` (variable name sanitization for HC.jl) |
| `homotopy_continuation.jl` | 615-646 | `convert_to_hc_format` (Symbolics → HC.jl, string-based) |
| `homotopy_continuation.jl` | 656-683 | `solve_with_hc` (HC.jl solver wrapper) |
| `parameter_estimation.jl` | 990-1078 | `multipoint_numerical_jacobian` (existing multi-point Jacobian, similar idea) |
| `parameter_estimation.jl` | 1136-1198 | `multipoint_local_identifiability_analysis` (BoundsError, UNTESTED) |
| `experiments/multipoint/exp04_multipoint_prolongation.jl` | — | Multi-point prolongation + all helper functions |
| `experiments/multipoint/exp04f_forced_lv.jl` | — | Forced LV accuracy comparison |
| `experiments/multipoint/exp04g_hard_models.jl` | — | Hard models structural analysis |
| `experiments/multipoint/exp05_option_c.jl` | — | Option C (template combination + greedy selection) |

---

## Part 6: Detailed Trace of Squareness for Key Models

### simple (1-point prolongation trace)
```
Step  1: +Y[1][β=1] +1 X cascade → Et=2 eqs, 5 vars (Δ=-3)
Step  2: +Y[2][β=1] +1 X cascade → Et=4 eqs, 6 vars (Δ=-2)
Step  3: +Y[1][β=2] +1 X cascade → Et=6 eqs, 7 vars (Δ=-1)
Step  4: +Y[2][β=2] +1 X cascade → Et=8 eqs, 8 vars (Δ=0) ← SQUARE
```

### treatment (1-point prolongation trace)
```
Step  1: +Y[1][β=1] +1 X cascade → Δ=-8
Step  2: +Y[2][β=1] +1 X cascade → Δ=-7
Step  3: +Y[1][β=2] +2 X cascade → Δ=-6
Y[2][β=2] REJECTED
Step  4: +Y[1][β=3] +3 X cascade → Δ=-5
Step  5: +Y[1][β=4] +4 X cascade → Δ=-4
Step  6: +Y[1][β=5] +4 X cascade → Δ=-3
Step  7: +Y[1][β=6] +4 X cascade → Δ=-2
Step  8: +Y[1][β=7] +4 X cascade → Δ=-1
Y[1][β=8] REJECTED
FINAL: 31 eqs, 32 vars, Δ=-1  ← NOT SQUARE (unidentifiable `a`)
```

### crauste (1-point prolongation trace)
```
Steps 1-4: Y[1-4][β=1] → Δ goes from -17 to -14
Steps 5-8: Y[1-4][β=2] → Δ goes from -13 to -10
Steps 9-12: Y[1-4][β=3] → Δ goes from -9 to -6
Step 13: Y[1][β=4] → Δ=-5
Y[2][β=4] REJECTED
Step 14: Y[3][β=4] → Δ=-4
Step 15: Y[4][β=4] → Δ=-3
Y[1][β=5] REJECTED
Step 16: Y[3][β=5] → Δ=-2
Step 17: Y[4][β=5] → Δ=-1
Step 18: Y[3][β=6] → Δ=0  ← SQUARE
```

---

## Part 7: Summary of All Results

| What | Result | Status |
|------|--------|--------|
| SI.jl `:ME` identifiability | num_exp=1 for all models | benefit is numerical only |
| Multi-point prolongation reduces derivative orders | 13/14 models | confirmed |
| Multi-point prolongation produces square systems | 12/14 models | confirmed |
| HC.jl solves prolongation systems | 3/3 tested (simple, LV, forced_LV) | confirmed |
| Estimation accuracy improvement (prolongation + HC.jl) | 5.8× on forced_lv_sinusoidal | confirmed |
| Option C (template combination + greedy selection) | square + full rank, but HC.jl fails | HC.jl issue, not math |
| Newton confirms roots exist in Option C systems | converges to ||F||=5e-17 | confirmed |
| Gauss-Newton on overdetermined multi-point | 5.4× improvement on forced_lv_sinusoidal | confirmed |
| Hard model accuracy with GN | NOT YET TESTED | next step |
| Strategy D (HC.jl 1pt + GN multi-pt) | NOT YET TESTED | next step |
| HC.jl reliability on combined systems | FAILS despite roots existing | **FIXED: string replacement bug** |

---

## Part 8: Late Discoveries (2026-03-23 evening)

### Bug fix: `convert_to_hc_format` string replacement

Fixed in `homotopy_continuation.jl`. The bug: `replace(s, mapping...)` doesn't guarantee longest-match — `x2_0` can match inside `x2_0_pt2`. Fix: two-pass replacement with unique placeholders, sorted by key length descending. Applied to both `convert_to_hc_format` and `convert_to_hc_format_with_params`.

**ALL previous "HC.jl finds 0 solutions" results for combined multi-point systems were caused by this bug.** After fixing, HC.jl works correctly. Tests: 96/96 fast_core pass.

### Planned: Equation Selection Algorithm

Full plan in `plans/ancient-pondering-crown.md`. Three weighted rank-preserving selection strategies to compare on 7 Bilby benchmark models. Key insight from PAL: this is constrained optimization — maximize data quality subject to maintaining generic Jacobian rank.

Script: `experiments/multipoint/exp06_equation_selection.jl`

### Experiment 6 PARTIAL RESULTS (Strategy 1: low-order-first greedy)

| Model | 1pt best | 2pt Strategy 1 | Improvement |
|-------|---------|-----------------|-------------|
| simple | 0.000 | 0.000 | 1.0× (already perfect) |
| lotka_volterra | 1.116 | 19.032 | **0.1× (17× WORSE!)** |
| forced_lv_sinusoidal | — | — | timed out |

**lotka_volterra got WORSE** with the greedy low-order-first approach. The selected 25×25 system still needs max_order=5 (no structural reduction). Both HC.jl solutions have wrong-sign parameters. The greedy selector picks structural equations first (they have lower derivative order), but those don't anchor the state variables to data — leading to wrong algebraic branches.

**Key insight:** The greedy selector optimizes for low derivative order but doesn't consider which equations are needed to SELECT THE CORRECT BRANCH. Data equations (even high-order ones) serve two purposes: (1) provide numerical data, and (2) constrain the solution to the correct algebraic branch. Dropping them can send HC.jl to a wrong branch that's further from truth.

**The multi-point prolongation (Experiment 4) worked better** because it builds the system from scratch with the correct algebraic structure, not by selecting from a pre-built pool. The prolongation's cascade ensures every variable gets its structurally necessary equation.

**Performance issue:** The greedy selector compiles a new Symbolics→native function and computes a ForwardDiff Jacobian for EACH candidate equation. For a 24-equation pool with 20 variables, this is ~24 compilations + Jacobian evals → too slow. Forced_lv_sinusoidal timed out. Need: either batch the rank computation or use the SIAN-level Nemo Jacobian (which is much faster).

**CORRECTION (late 2026-03-23):** The greedy selector's results depend critically on WHERE the Jacobian is evaluated for the rank check. Experiment 6 used oracle values → terrible results. When re-run using the good combined solution (from separately solving A and B), the greedy selector picks different equations and HC.jl finds the good solution (k2=0.5006, k1=1.0004, k3=0.3020 — very close to truth).

This means the greedy selection approach CAN work, but the evaluation point for the rank check matters enormously. Using oracle values (which are NOT the actual polynomial system's roots) selects a bad equation subset. Using an approximate root (from 1-point HC.jl solutions) selects a good subset.

**New insight:** The correct workflow might be:
1. Solve each point independently with HC.jl → get 1-point solutions
2. Combine good 1-point solutions → approximate combined root
3. Use that approximate root as the evaluation point for greedy equation selection
4. Solve the selected square system with HC.jl

Also confirmed: HC.jl on overdetermined 28×25 tracked 12,658 paths and found 0 solutions. Overdetermined truly doesn't work.

Also confirmed: Newton converges from the good combined solution on the greedy system (||F||=9.5e-32 after 4 iters). The root exists.

**FURTHER CORRECTION (2026-03-24):** The greedy selection gives IDENTICAL results regardless of evaluation point (oracle vs HC solution vs random). You were right that rank is constant almost everywhere for polynomials. The different results between Experiment 6 and the manual run were due to DIFFERENT TIME INTERVALS in the data sampling (Experiment 6: [4.0, 15.0], manual run: [-0.3, 0.25]), producing different polynomial systems entirely.

The actual questions remain:
1. Does the greedy low-order-first selection produce USEFUL systems? (mixed — works for simple, produced bad solutions for lotka_volterra at [4.0, 15.0])
2. Is the "bad" lotka_volterra result from the equation selection, or from the time points / data quality?
3. Need controlled experiments with the SAME data to isolate the effect of equation selection vs time point choice.

### Experiment 7: Controlled comparison (2026-03-24)

Tested 5 greedy strategies on forced_lv_sinusoidal (n=51, noise=0, t=[0,10]):

| Strategy | Max order | best_err | vs 1-point |
|----------|-----------|----------|------------|
| 1-point best (t=3.2) | 3 | **0.89** | baseline |
| Low-order-first | 3 | 8.06 | 9× worse |
| High-order-first | 3 | 13.03 | 15× worse |
| Default A-first | 3 | 13.03 | 15× worse |
| Default B-first | 3 | 8.06 | 9× worse |

ALL greedy strategies produce the SAME max derivative order (3) — the rank constraint forces inclusion of order-3 equations regardless of preference ordering. The selection just determines which POINT's equations dominate, inheriting that point's 1-point accuracy.

**DEFINITIVE CONCLUSION:** Greedy equation selection from pre-built single-point templates CANNOT improve over the best 1-point result. The standard template equations at any single point are already algebraically determined — you can't get a better variety by mixing equations from two instantiations of the SAME template.

The multi-point improvement (5.8× in Experiment 4F) came from the PROLONGATION approach which constructs a genuinely different algebraic system with structurally lower derivative orders. The template-combination approach (Option C) is fundamentally limited.

### Full exp07 results (background task completed)

| Model | n_pts | 1pt best | Low-ord | High-ord | Default | Square? |
|-------|-------|---------|---------|----------|---------|---------|
| forced_lv_sin | 2 | 0.89 | 8.06 | 13.03 | 13.03 | yes 20/20 |
| forced_lv_sin | 3 | 0.89 | **1.10** | 8.74 | 8.74 | yes 28/28 |
| biohydrogenation | 2 | 1.18 | — | — | — | NO 43/44 |
| biohydrogenation | 3 | 1.18 | — | — | — | NO 59/63 |
| lotka_volterra | 2 | 0.51 | — | — | — | NO 24/25 |
| hiv | 2 | 0.47 | — | — | — | NO 53/56 |

Most models CAN'T reach square — the greedy selector runs out of rank-increasing equations. This is because equations from different instantiations of the same template share the same polynomial structure and are algebraically dependent at generic points. The Jacobian at a random point doesn't distinguish between equations with different numerical constants — it only sees the polynomial structure.

**This definitively rules out template-combination (Option C) as a general approach.** The PROLONGATION approach (Option B) remains the only path that produces structurally different algebraic systems at multiple points.
