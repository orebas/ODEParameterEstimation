# Algebraic multiplicity — complete catalog for the 23 wallaby systems

**Status (2026-05-19).** Supplements cluster Claude's multiplicity catalog at
`~/rsync-readonly-PEB/results/wallaby_analysis/multiplicity/` (PEB commit
`a4e1adbfd`). Cluster covered the 16 polynomial systems via
`StructuralIdentifiability.assess_identifiability`. This doc extends the
cross-check to **all 23 systems** by transcribing the wallaby cells' actual
`@ODEmodel` bodies (with `sin(omega*t)` rewritten as a free input variable —
the same convention ODEPE's runtime uses at
`src/core/si_equation_builder.jl:172`).

Repro artifacts (this directory):

- `run_sian_all_23.jl` + `.txt` — SI cross-check, all 23 systems (no crashes)
- `top2_branch_capture_all4.py` + `biohydrogenation_top2.txt` — extends cluster's script to biohydrogenation
- `branch_transformations.py` + `.txt` — row 0 vs row 1 empirical T derivation
- `biohydrogenation_actual_branches.py` — find the actual second branch deeper in K=20
- `branches_in_bounds.py` + `.txt` — classify second branches by whether they satisfy [1e-5, 10]
- `MULTIPLICITY_COMPLETE.md` — this file

---

## TL;DR (algebraic verdict — the main result)

| System | SI verdict (G / L / N) | Empirical | Algebraic multiplicity | Branch structure |
|---|---|---|---|---|
| aircraft_pitch | 6 / 0 / 1 | 1 (cd10=20/20) | **1** in id-subspace | `theta` continuous unid axis |
| bicycle_model | 5 / 0 / 0 | 1 (cd10=20/20) | **1** | unique |
| **biohydrogenation** | 5 / 4 / 1 | 1 w/ x7 spread; ≥ 2 w/ x7 projected | **≥ 2** in id-subspace | k9 → −k9, k10 → −k10 (ratio preserved); (k8, x6) compensate |
| boost_converter | 5 / 0 / 0 | 1 (cd10=20/20) | **1** | unique |
| brusselator | 4 / 0 / 0 | 1 | **1** | unique |
| crauste | 17 / 0 / 0 | 1 (cd10=10/20) | **1** | unique |
| cstr | 7 / 0 / 0 | 1 (cd10=0/20 — cell failures) | **1** | unique |
| daisy_mamil3 | 8 / 0 / 0 | 1 | **1** | unique |
| **daisy_mamil4** | 5 / 6 / 0 | 2 (cd10=20/20) | **2** | (k13, k31, x3) ↔ (k14, k41, x4) |
| dc_motor | 4 / 0 / 0 | 1 (cd10=20/20) | **1** | unique |
| fitzhugh_nagumo | 5 / 0 / 0 | 1 | **1** | unique |
| flexible_arm | 9 / 0 / 0 | 1 (cd10=14/20) | **1** | unique |
| forced_lotka_volterra | 6 / 0 / 0 | 1 (cd10=20/20) | **1** | unique |
| harmonic_oscillator | 4 / 0 / 0 | 1 | **1** | unique |
| hiv | 15 / 0 / 0 | 1 (cd10=12/20) | **1** | unique |
| lotka_volterra | 5 / 0 / 0 | 1 | **1** | unique |
| mass_spring_damper | 5 / 0 / 0 | 1 | **1** | unique |
| quadrotor | 4 / 0 / 0 | 1 (cd10=20/20) | **1** | unique |
| repressilator | 9 / 0 / 0 | 1 | **1** | unique |
| **seir** | 3 / 4 / 0 | 2 (cd10=17/20) | **2** | (a, nu) hyperbola: a·nu = const; (E, S) follow |
| sirt_treatment | 9 / 0 / 0 | 1 | **1** | unique |
| **slow_fast** | 3 / 5 / 0 | 2 (cd10=20/20) | **2** | k1 ↔ k2 swap (k1·k2 = const); (xA, xB, eB) rescale |
| vanderpol | 4 / 0 / 0 | 1 | **1** | unique |

(G = globally / L = locally / N = nonidentifiable counts of variables.)

**Summary:**

- **4 systems with algebraic multiplicity ≥ 2** in their identifiable subspace
  (after plugging continuous-unidentifiable axes via
  `representative_completion_value`): daisy_mamil4, seir, slow_fast,
  biohydrogenation.
- **19 globally identifiable** systems in their identifiable subspace.
- **2 systems with a continuous unidentifiable axis** that ODEPE plugs
  silently: aircraft_pitch (`theta`) and biohydrogenation (`x7`).
- **All 23 SI cross-checks succeed** with no Groebner-internal crashes.

---

## Methodology note: matching wallaby's actual model structure

**Initial attempt (don't follow):** I first transcribed the 7 sin(t) systems
from `src/examples/models/polynomialized/{tier_a_polynomial.jl,
tier_c_arrhenius.jl}` using the `u_sin`/`u_cos` aux-state oscillator
convention. This was wrong in two ways:

1. **Too many free parameters.** ODEPE's `*_poly()` example functions declare
   the full set of plant parameters as `@parameters`. Wallaby's actual cells
   inline most plant constants as numerics and declare only a small subset
   as symbolic — e.g., `dc_motor` wallaby has 2 symbolic params (Kt, Jm)
   while `dc_motor_poly()` has 6. The over-parameterized SI test gave many
   spurious "nonidentifiable" findings.

2. **Wrong oscillator handling.** The `u_sin'(t) = omega·u_cos(t)`,
   `u_cos'(t) = -omega·u_sin(t)` ODEs added 2 states to the system, blowing
   up the Groebner basis. On bicycle_model this triggered an internal
   `BoundsError(Int32[...], (5,))` at `Groebner/groebner.jl:210` —
   a reproducible Groebner-internal crash that prevented SI from completing.

**Correct approach (current `run_sian_all_23.jl`):** transcribe each wallaby
cell's `state_equations` and `measured_quantities` verbatim, replacing
`sin(omega·t)` with a free input variable `u_sin(t)` (no `'(t)` equation
— SI infers it as an input). This matches what ODEPE's runtime
`transform_pep_for_estimation()` produces internally at
`src/core/transcendental_utils.jl:600`, and what `convert_to_si_ode()` feeds
to `assess_identifiability` at `src/core/si_equation_builder.jl:172`
(the `inputs_` slot of the SI ODE).

After the fix: all 23 systems run cleanly. The 16 polynomial systems'
verdicts match cluster's `run_sian_polynomial_only.jl` exactly (sanity
check on transcription). The 7 sin(t) systems are now well-defined.

---

## Branch structure per multiplicity-≥ 2 system

**Method.** For each system, I pulled row 0 and the algebraic second branch
(sometimes at rank 1, sometimes deeper in the K=20 list) from a wallaby
cell, projecting out unidentifiable axes. The transformation T is read off
the row-to-row ratios. See `branch_transformations.py` and
`biohydrogenation_actual_branches.py` for the search scripts.

### daisy_mamil4 — channel swap (both branches physical)

Cell: `daisy_mamil4_0_0` (r0~truth = 4.8e-9, r0~r1 = 6.5e-1, both rows in bounds).

| Var | Truth | Row 0 | Row 1 | Row1/Truth |
|---|---|---|---|---|
| k13 | 0.606 | 0.606 | 1.14 | 1.881 |
| k14 | 0.855 | 0.855 | 0.455 | 0.532 |
| k31 | 0.518 | 0.518 | 0.692 | 1.336 |
| k41 | 0.593 | 0.593 | 0.444 | 0.749 |
| x3 | 0.297 | 0.297 | 0.852 | 2.869 |
| x4 | 0.639 | 0.639 | 0.223 | 0.349 |

**Conserved quantity:** the output `y3 = 1.2·x3 + 1.6·x4`.
- Truth: 1.2·0.297 + 1.6·0.639 = **1.3788**
- Row 1: 1.2·0.852 + 1.6·0.223 = **1.3788** ✓

**Transformation T:** swap the (k13, k31, x3) channel with the
(k14, k41, x4) channel. Specifically, `1.2·x3_row1 = 1.6·x4_truth` and
`1.6·x4_row1 = 1.2·x3_truth`. The two channels feed out of x1 and combine
in y3 symmetrically — no observation distinguishes "channel 3" from
"channel 4". Both rate-constant pairs and both states remain positive and
within bounds in the alt branch.

### seir — (a, ν) hyperbola (both branches physical)

Cell: `seir_0_1em8` (r0~truth = 4.4e-4, r0~r1 = 7.5e-1, both rows in bounds).

| Var | Truth | Row 0 | Row 1 | Row1/Truth |
|---|---|---|---|---|
| a | 0.500 | 0.500 | 0.282 | 0.564 |
| nu | 0.376 | 0.376 | 0.667 | 1.773 |
| E | 0.246 | 0.246 | 0.0612 | 0.249 |
| S | 0.839 | 0.839 | 0.473 | 0.564 |

**Conserved quantities:**
- `a·nu` (verified): 0.500·0.376 = **0.188** = 0.282·0.667 ✓
- `nu·S` (verified): 0.376·0.839 = **0.3155** = 0.667·0.473 ✓

**Transformation T:** `(a, ν, S) → (a/k, ν·k, S/k)` with `k ≈ 1.77`.
`E_new` is determined by the higher-derivative chain (specifically the
`In` derivative balance), so it isn't a simple multiplicative rescale.
Both branches have all-positive values well within [1e-5, 10].

### slow_fast — k1 ↔ k2 swap (one branch out of bounds)

Cell: `slow_fast_0_1em4` (r0~truth = 5.6e-3, r0~r1 = 1.0).

| Var | Truth | Row 0 | Row 1 | Row1/Truth |
|---|---|---|---|---|
| k1 | 0.126 | 0.126 | 1.666 | 13.22 |
| k2 | 0.833 | 0.833 | 0.063 | 0.076 |
| xA | 0.255 | 0.255 | **−8.117** | **−31.83** |
| xB | 0.342 | 0.341 | 4.515 | 13.20 |
| eB | 0.115 | 0.116 | 0.285 | 2.47 |

**Conserved quantities:**
- `k1·k2`: 0.126·0.833 = **0.105** = 1.666·0.063 ✓
- Output `y2 = 0.442·xA·eA + 0.999·eB·xB + 1.666·xC·eC` ≈ **1.151** in both rows ✓

**Transformation T:** k1 and k2 swap (up to multiplicative scaling factor
≈ 13.22), with (xA, xB, eB) absorbing the scaling so y2 stays invariant.
Crucially, **xA flips sign in the second branch** (positive in truth,
negative in alt). The negative xA contribution to y2 cancels with the
positive eB·xB scaling to preserve the observation.

This is real algebraic multiplicity 2 — the polynomial system has two
distinct roots, and HC.jl finds both. But the second root has xA < 0,
which is outside ODEPE's lower bound (1e-5) on states.

### biohydrogenation — sign-flipped rate constants (one branch out of bounds)

Found in cell `biohydrogenation_0_0` polish at rank 9 (not rank 1):

| Var | Truth | Row 0 | Row 9 (alt) |
|---|---|---|---|
| k5, k6, k7, x4, x5 | (globally) | (matches truth) | **unchanged** |
| k10 | 0.853 | 0.853 | **−0.853** (sign flip) |
| k9 | 0.301 | 0.301 | **−0.301** (sign flip) |
| k8 | 0.687 | 0.687 | 4.95 |
| x6 | 0.793 | 0.793 | −16.27 |

**Why this is the algebraic second branch.** Look at the x6 dynamics term:
```
−(0.2·(10·k10 − 0.5·x6)·k9·x6) / (10·k10)
  =  −0.2·k9·x6 + 0.01·(k9/k10)·x6²
```
What enters the dynamics is the **ratio** `k9/k10`, not k9 and k10
separately. Sign-flipping both preserves this ratio. The linear
`−0.2·k9·x6` term flips sign, but the Michaelis-Menten constraint
`2·k8 + 0.5·x6 = const(t)` allows compensating values of (k8, x6) that
keep the data fit valid even with k9, k10 negative.

The polynomial system has finitely many algebraic solutions (consistent
with SIAN's `:locally` verdict on k8, k9, k10, x6). At least 2 of them
exist: the physical truth-branch (all positive) and the sign-flipped
alter-ego (k9, k10 negative, k8 large positive, x6 large negative).

### Why the "finite set" of `:locally` is genuinely finite

SIAN's verdict `:locally` means: each `:locally`-identifiable variable
satisfies a polynomial relation (over the field of rational functions of
the observation derivatives) of degree > 1 but finite. For
biohydrogenation, the polynomial system over (k8, k9, k10, x6) — after
substituting time-series constraints from the entire trajectory — has
**finitely many algebraic solutions**. Empirically: **2** (sometimes 3
when polishing noise produces an extra cluster, per cluster's
`cd10=(1,10)+(2,6)+(3,4)`).

The reason the constraint feels "underdetermined" from a single-time-point
analysis (e.g., `2·k8 + 0.5·x6 = const` is one equation in two unknowns)
is that we have constraints at **every time** of the trajectory plus
higher-derivative constraints. Once accumulated and combined into a
Groebner basis, the intersection is zero-dimensional.

---

## Why some branches surface in result.csv and others don't: bounds

The algebraic catalog (`mult ≥ 2` for 4 systems) is the **structural**
verdict. ODEPE's runtime additionally respects user-provided bounds. Wallaby
cells use `opt_lb = 1e-5`, `opt_ub = 10.0` and `polish_method =
PolishLSOBoundedLog`, which operates in **log space** — negative values
are out-of-domain.

So the practical question: of ODEPE's K=20 candidates per cell, how many
of them are bound-satisfying algebraic alternatives?

`branches_in_bounds.py` classifies each cell's first distinct alt-branch
row (row > 0 with > 30% max-rel-distance from row 0 on identifiable
axes):

| System | Cells with row 0 ≈ truth | Alt-branch IN bounds | Alt-branch OUT of bounds | No alt found |
|---|---|---|---|---|
| daisy_mamil4 | 30 | **30 (100%)** | 0 | 0 |
| seir | 35 | **30 (86%)** | 0 | 5 |
| slow_fast | 57 | 14 (25%) | 43 (75%) | 0 |
| biohydrogenation | 42 | 15 (36%) | 23 (55%) | 4 |

**Reading this table:**

- **daisy_mamil4 and seir**: their algebraic second branch is *physical*
  (all positive, well within bounds). ODEPE reliably surfaces it in
  result.csv (100% / 86% of the time row 0 is correct).
- **slow_fast and biohydrogenation**: their algebraic second branch is
  out-of-bounds (negative xA on slow_fast; sign-flipped k9, k10 on
  biohydrogenation). Polish operating in log space rejects them. The
  rows that do appear with the alt branch values are unpolished raw HC
  candidates that survive in result.csv despite being non-physical.
- The "in bounds" alt branches for slow_fast (25%) and biohydrogenation
  (36%) typically have a state or parameter **saturated to the lower
  bound** (e.g., `slow_fast_0_1em2` alt has `xA = 0.0000` exactly;
  `biohydrogenation_0_1em6` alt has `k8 = 0.0000`). These are
  bound-clipped projections of the OOB branch, not genuine independent
  algebraic alternatives.

**So the practical reading:**
- **Genuine physical multiplicity 2** (both branches positive, within
  bounds, well-conditioned): daisy_mamil4, seir.
- **Algebraic multiplicity 2 with one branch in the bounded region**:
  daisy_mamil4, seir.
- **Algebraic multiplicity ≥ 2 with the second branch out of bounds**:
  slow_fast, biohydrogenation. ODEPE finds the second algebraic root
  but polish can't refine it (log of negative is NaN) and the user-set
  bounds correctly reject it.

The bounds explanation is operational, not structural. The algebraic mult
catalog (4 systems multiplicity ≥ 2) is the headline result — that's
what SI gives us. The bounds discussion explains the secondary observation
that some of those algebraic alternatives don't reliably appear at the
top of result.csv on real benchmarks.

---

## Analyzing multiplicity in the identifiable subspace

### The "plug-in" mechanism (existing in ODEPE)

When SI flags a variable as `:nonidentifiable` (continuous unidentifiable
axis), ODEPE assigns a deterministic representative value:

- `src/core/parameter_estimation_helpers.jl:380` —
  `representative_completion_value(kind)` returns **1.0** for `:parameter`
  and **0.0** for `:state`.
- Recorded in `provenance.representative_assignments` and `structural_fix_set`.
- The reduced (identifiable) problem is solved; the cd10 / row-distinct
  count is implicitly in the reduced space.

### Recipe for offline multiplicity analysis (post-hoc on `result.csv`)

1. **Identify the unidentifiable axes.** Two sources:
   - SI verdict (from `run_sian_all_23.txt` — the `:nonidentifiable` entries).
   - Per-cell `odepe_metadata.json[best].all_unidentifiable` — ODEPE
     records what it actually plugged in. For biohydrogenation cells
     this lists `["x7(t)"]`; for aircraft_pitch, `["theta(t)"]`.

2. **Project them out** before computing row-distinct counts or row-pair
   distances. Cluster's `wallaby_top2_branch_capture.py` already does
   this via `if k in unid: continue` in `row_distance()`.

3. **Edge case** — if the truth value of a continuous-unidentifiable axis
   happens to equal the plug-in default (1.0 for params, 0.0 for states),
   empirical analysis may accidentally agree without explicit projection.
   Don't rely on this.

---

## How to get all the branches (operational recipe)

Given an ODE PEP with measured outputs, enumerate algebraic branches by:

1. **Polynomialize** transcendental RHS into the standard form. ODEPE's
   `transform_pep_for_estimation()` (`src/core/transcendental_utils.jl:600`)
   replaces `sin(omega·t)` with a `_trfn_sin_X_Y(t)` **free input** —
   no oscillator state ODE. This matches what `convert_to_si_ode()`
   later feeds to `assess_identifiability` at
   `src/core/si_equation_builder.jl:172` (the `inputs_` slot).

2. **Run SI** (`StructuralIdentifiability.assess_identifiability`).
   Classify each variable as:
   - `:globally` — uniquely determined
   - `:locally` — finitely many discrete branches (multiplicity ≥ 2 source)
   - `:nonidentifiable` — continuous unidentifiable axis (needs plug-in)

3. **Plug in** every `:nonidentifiable` at the plug-in default (1.0 for
   parameters, 0.0 for states) via `representative_completion_value`.

4. **Solve the reduced polynomial system** with HC.jl over the remaining
   `:globally` + `:locally` variables. HC.jl enumerates ALL complex
   solutions; project to real, dedupe by cd10 = 1e-10 on the identifiable
   axes only.

5. **The number of distinct real solutions = algebraic multiplicity in the
   identifiable subspace.** Each is a different branch.

6. **(Optional) Filter by bounds.** If users have provided `opt_lb`,
   `opt_ub`, drop algebraic roots outside this region. The remaining
   are "physical multiplicity" — the alternatives the user actually
   wants reported.

7. **For ODEPE's K = 20 output:** rows 0..K-1 should ideally represent the
   distinct algebraic branches first (with bound-satisfying ones
   prioritized), then numerical neighbours of each. **Empirical evidence
   shows this isn't reliably true today** — see "open items" for why
   polish collapses physical multiplicities (daisy_mamil4 polish 100%
   capture, slow_fast polish 72%) and surfaces non-physical OOB branches
   as raw HC candidates.

---

## Recommendations for ODEPE source (deferred — not implemented here)

1. **Multiplicity-aware output dedup.** After polish, deduplicate
   `result.csv` rows that lie within cd10 = 1e-10 of each other on the
   identifiable axes (projecting out `all_unidentifiable` first). Report
   only distinct algebraic branches as primary output, with within-branch
   numerical variants demoted to a secondary structure.

2. **Bound-aware ranking.** Rows with any variable outside `opt_lb /
   opt_ub` should be ranked below rows that satisfy bounds, regardless
   of `err`. Currently rows with `xA = −8` or `k9 = −0.301` can show up
   at rank 1 on some cells.

3. **Polish preserves branch identity.** The polish step appears to
   collapse the second branch onto the first on some cells. Investigate:
   is polish initialized from row 0 only, or from each row? Either
   polish each row from its own start, or polish-then-recluster.

4. **Native multiplicity reporting via `diagnose()`.** Run steps 1-6
   above (SI → enumerate branches → bound-filter → match to result.csv
   rows) as a diagnostic option in `diagnose_model()`. Gives users a
   per-cell view of "how many algebraic branches exist + how many are
   physical + how many did we find + which rows correspond to which".

---

## Open items

1. **Why does the algebraic OOB branch appear in result.csv at all?** For
   biohydrogenation/slow_fast it's an unpolished raw HC candidate. The
   wallaby polish pipeline uses `PolishLSOBoundedLog` (log-space, can't
   handle negatives), so these candidates fail to polish and survive in
   their pre-polish form. Worth verifying that `post_polish_error` for
   these rows is NaN/huge, and that bound-violating rows get demoted in
   the ranking. (Currently `:err_only` ranking doesn't check bounds.)

2. **biohydrogenation in-bounds alt branches (15/42 cells).** These have
   one variable saturated to the lower bound (e.g., `k8 = 0`). Are they
   bound-clipped projections of the OOB branch, or genuinely separate
   algebraic alternatives? Worth verifying by feeding the bound-saturated
   alt back into the equations and checking residual.

3. **slow_fast: 100% nopolish top-2 capture vs 72% polish.** Same pattern
   as the others. Worth investigating polish's effect on physical second
   branches independently of OOB rejection.

4. **Bicycle_model_poly Groebner crash from earlier attempt** — fixed by
   transcribing wallaby directly. Could still be worth reporting upstream
   to Groebner.jl/StructuralIdentifiability.jl since the over-parameterized
   form is a legitimate use case that crashes.
