# The `receptor_subtype_binding_branch` system — complete reference

The single, consolidated reference for the receptor benchmark system: the physical model, every
variable, the actual polynomial systems we solve, and the full arc of what we learned debugging it
(solution count → blind spot → column scaling → the rank-trim → the 87-min cost → the
parameter-homotopy collapse → its resolution as a high-order-derivative problem). Supersedes the
scattered notes; pointers to all repro scripts and the two PAL consults are in §9.

Source of the model: `src/examples/models/branch_stress_systems.jl:80`.

---

## 1. TL;DR

- **What it is.** A ligand reversibly binding **two receptor subtypes** (a, b), observed only through
  *free ligand* and *total bound*. It is a deliberate **branch-stress** benchmark.
- **The physical/structural crux (real, not numerical).** Because you observe `y1=L` and
  `y2 = Ca+Cb` (the *sum*, never `Ca`,`Cb` separately) and the two subtypes have identical form, the
  data is **exactly invariant under relabeling a↔b**. So "which subtype is a vs b" is structurally
  unobservable → **algebraic multiplicity M = 2** (truth + its swap-sibling are both valid). 18 generic
  finite solutions total.
- **Recovery works.** With **column scaling** (default-on) the pipeline recovers both branches
  (truth+swap) at noise 0; **branch_completion** (default-on) reconstructs siblings. Both shipped to
  `main` (commits 1fe5062 + acd2419), regression 446/446.
- **The hard parts are speed + the parameter-homotopy collapse, and both trace to ONE choice:** the
  SIAN rank-trim drops the high-order linear data-pins (`L_k=y1_k`, `Ca_8+Cb_8=y2_8`) because the
  high-order observable derivatives are unreliable. That is *correct for accuracy*, but it leaves the
  highest jets determined indirectly → ill-conditioned → 6402 (vs 297) polyhedral paths, 16 spurious
  roots, and a parameter-homotopy that collapses on a singular nuisance direction. **Not a physical
  bifurcation; recovery is unaffected.**

---

## 2. The model (ODE)

States `L, Ca, Cb`; parameters `R1tot, R2tot, kon1, kon2, koff1, koff2`; observables `y1, y2`.

```
dL/dt  = −kon1·L·(R1tot − Ca) + koff1·Ca  −  kon2·L·(R2tot − Cb) + koff2·Cb
dCa/dt =  kon1·L·(R1tot − Ca) − koff1·Ca
dCb/dt =  kon2·L·(R2tot − Cb) − koff2·Cb

y1 = L
y2 = Ca + Cb
```

Truth (the values to recover):

| quantity | symbol | value |
|---|---|---|
| total receptor subtype a | `R1tot` | 1.10 |
| total receptor subtype b | `R2tot` | 0.70 |
| on-rate subtype a | `kon1` | 0.80 |
| on-rate subtype b | `kon2` | 1.30 |
| off-rate subtype a | `koff1` | 0.40 |
| off-rate subtype b | `koff2` | 0.60 |
| IC free ligand | `L(0)` | 2.00 |
| IC complex a | `Ca(0)` | 0.10 |
| IC complex b | `Cb(0)` | 0.20 |

Time interval `[0, 8]`. **`sample_problem_data` normalizes time to `[−0.5, 0.5]`**
(`t_norm = (t_real − 4)/8`, i.e. `t_real = 4 + 8·t_norm`) for interpolation conditioning — so all the
"t≈−0.3" discussion below is *normalized* time; the binding transient at `t_norm≈−0.32` is real time
`t_real≈1.44`.

---

## 3. Physical meaning + all variables

A single ligand species `L` binds reversibly to two **distinct receptor subtypes**, forming complexes
`Ca` (with subtype a) and `Cb` (with subtype b). Standard reversible mass-action:

- `Ca` grows by association `kon1·[L]·[free a]` where free subtype-a receptor = `R1tot − Ca`, and
  shrinks by dissociation `koff1·Ca`. Likewise `Cb` with `kon2, koff2, R2tot`.
- `dL/dt` is minus the sum of the two binding fluxes (ligand consumed on binding, released on
  unbinding). Consequently **total ligand `L + Ca + Cb` is conserved** (here = 2.3); the system
  relaxes monotonically to binding equilibrium — there is **no dynamical bifurcation**.

Variables:
- **States:** `L` free ligand; `Ca`, `Cb` ligand–receptor complexes for subtypes a, b.
- **Parameters:** `R1tot, R2tot` total receptor amounts (free + bound); `kon1, kon2` association rate
  constants; `koff1, koff2` dissociation rate constants.
- **Observables:** `y1 = L` (free ligand — directly measurable); `y2 = Ca + Cb` (*total* bound ligand —
  measurable as total occupancy, but **does not resolve which subtype**).

### The M=2 swap symmetry (the whole point)

The involution `a↔b`: `(Ca,Cb,R1tot,R2tot,kon1,kon2,koff1,koff2) ↦ (Cb,Ca,R2tot,R1tot,kon2,kon1,koff2,koff1)`
leaves the ODE and both observables **exactly invariant** (`y1=L` untouched; `y2=Ca+Cb=Cb+Ca`). So two
parameter sets — the truth and its a↔b swap — produce *identical* `(y1,y2)` for all time. The subtype
labels are **structurally unidentifiable**. This is a genuine identifiability degeneracy (a discrete
label symmetry), and it is why the recovery problem has **M=2** physically-meaningful branches. The
"swap" sibling of truth is `[R1tot,R2tot,kon1,kon2,koff1,koff2] = [0.70,1.10,1.30,0.80,0.60,0.40]`.

---

## 4. From ODE to polynomial system (the recovery setup)

The estimator builds, via StructuralIdentifiability/SIAN, a square polynomial system `F(x; p) = 0`:
- **`x` = solve variables (32):** the 6 parameters + the **state jets** (time-derivatives of the states
  at a shooting point): `L_0…L_7` (8), `Ca_0…Ca_8` (9), `Cb_0…Cb_8` (9). `X_k` denotes the k-th
  derivative of state `X`; `X_0` is the state value (so `Ca_0` is an occupancy, must be ≥0 physically).
- **`p` = data variables (parameters of the HC system):** the **observed-derivative jets**
  `y1_k = d^k y1/dt^k`, `y2_k = d^k y2/dt^k`, obtained by differentiating an interpolant of the sampled
  data at the shooting time. Defined up to order ~10, but **only 9 actually appear** in the trimmed
  system (see §5): `y1_0` and `y2_0…y2_7`.

To solve at multiple shooting points, the pipeline does (1) a **fresh polyhedral solve** at point 1
(start-system → target *with* the γ-trick) to get all solutions, then (2) a **parameter homotopy**
tracking those solutions as `p` moves point→point. Shooting points (default, 3): `t_norm = −0.5,
−0.32, 0.5` (real `0, 1.44, 8`).

---

## 5. The actual polynomial systems

SIAN emits **40** equations (the "Et"); the rank-trim (`algebraic_independence`, greedy maximal-rank
selection in SIAN's order) keeps **32** (a square system) and drops **8**. Here is the actual trimmed
32-equation system (verbatim; `X_k` = jet, `koff1_0` etc. = the baked parameters, `Differential(t,k)(y2(t))`
= the data `y2_k`):

**Order-0 pins + order-0/1 dynamics (readable):**
```
eq[1]:  −Ca_0 − Cb_0 + y2(t)                                   # y2 pin:  Ca_0 + Cb_0 = y2_0
eq[4]:  −L_0 + y1(t)                                           # y1 pin:  L_0 = y1_0   (the ONLY surviving y1 pin)
eq[3]:  Ca_1 + Ca_0·koff1 + Ca_0·L_0·kon1 − L_0·R1tot·kon1      # dCa/dt:  Ca_1 = kon1·L·(R1tot−Ca) − koff1·Ca
eq[2]:  Cb_1 + Cb_0·koff2 + Cb_0·L_0·kon2 − L_0·R2tot·kon2      # dCb/dt
eq[5]:  L_1 − Ca_0·koff1 − Cb_0·koff2 − Ca_0·L_0·kon1 − Cb_0·L_0·kon2 + L_0·R1tot·kon1 + L_0·R2tot·kon2   # dL/dt
eq[6]:  −Ca_1 − Cb_1 + Differential(t,1)(y2(t))                # y2 pin order 1: Ca_1 + Cb_1 = y2_1
```

**The pattern (orders 2–8).** Each order `k` contributes: a **y2-pin** `Ca_k + Cb_k = y2_k`
(eqs 1, 6, 9, 13, 17, 21, 25, 29 — orders 0..7), and the **prolonged dynamics** for `Ca_{k+1}`,
`Cb_{k+1}`, `L_{k+1}` (Faà-di-Bruno / Leibniz expansions of the RHS, with binomial coefficients). The
top of the tower:
```
eq[30]: Ca_8 + Ca_7·koff1 + Ca_0·L_7·kon1 + 7·Ca_1·L_6·kon1 + 21·Ca_2·L_5·kon1 + … − L_7·R1tot·kon1
eq[31]: Cb_8 + Cb_7·koff2 + Cb_0·L_7·kon2 + 7·Cb_1·L_6·kon2 + 21·Cb_2·L_5·kon2 + … − L_7·R2tot·kon2
eq[32]: L_7 − Ca_6·koff1 − Cb_6·koff2 − … (the 7th prolongation of dL/dt)
```
All dynamics equations are degree 3 (the bilinear `kon·L·R`/`kon·L·C` terms, prolonged); the pins are
degree 1 (linear).

**The 8 DROPPED equations** (`Et[33..40]`), all degree-1 data-pins:
```
Ca_8 + Cb_8 = y2_8          (the order-8 y2 pin)
L_1 = y1_1,  L_2 = y1_2,  …,  L_7 = y1_7   (the order-1..7 y1 pins)
```
So the trimmed system **uses `y1` data only at order 0** (`L_0=y1_0`) and **`y2` data at orders 0–7**;
it uses **none** of `y1_1…y1_7` and **not** `y2_8`. See §6 for why, and why it matters.

**Solution structure:** generic finite count **18** (certified); `mixed_volume` = **6402** is a loose
BKK *path* bound (most paths diverge to infinity). The 18 = truth + swap + 16 spurious (the spurious
ones are admitted by the trim; see §6). M = 2.

---

## 6. What we learned (the full arc)

### 6.1 The t≈−0.3 blind spot — a column-scaling pathology, fixed
At the binding transient, truth is an *exact* root (residual ~1e−11) but its coordinates span ~**1e7**
(high-order jets explode ~10×/order). Unscaled polyhedral tracking can't reach it (0/8 seeds). **Not**
geometry, **not** fixable by precision/steps/reconditioning. **Fixed by data-driven column scaling**
`x = D·x̂` (per-derivative-order rescaling; mixed_volume invariant): 6/6 seeds recover truth+swap.
Shipped as `use_column_scaling=true` (default-on). It is a solver-*reach* aid — it provably cannot
help noise amplification or fix parameter-homotopy tracking (those are scale-invariant).

### 6.2 The rank-trim drops the high-order data-pins — and it's *right*
The trim keeps the 32 dynamics+`y2`-pins (in SIAN's emitted order) and drops the 8 high-order pins
(`y1_1..y1_7`, `y2_8`). Consequences: vs an alternative that *keeps* the pins, the trimmed system has
**6402 vs 297** BKK paths and **~500× worse** conditioning, and it admits **16 spurious roots**.
**But dropping them is the correct accuracy choice:** the high-order observable derivatives
(`y1_7`, `y2_8`, …) estimated from an interpolant are **unreliable** (interpolation/noise error
amplifies catastrophically with order). The trim refuses to inject that bad data — that is the
"prefer lower-order derivatives" design bias, and it is wise. (See §6.5: keeping the pins is a trap.)

### 6.3 The 87-minute cost — the main solve, run 28× (measured by `profile_phases`)
"Equation construction + Solving" = **99.5%** of wall time; Result processing (all backsolves) = 1.77s;
`[RESOLVE]` ≈ 14s. The 87 min = **28 fresh 6402-path polyhedral solves = 9 interpolators
(the default `opts.interpolators` list, run because `auto_filter_interpolators=false`) × ~3 fresh
solves each** (the parameter homotopy collapses, so a fresh fallback fires per shooting point). The
backsolve and the SIAN-rebuild are *not* the cost (an earlier draft's "backsolve filter / SIAN cache
is the speed lever" was **disproven** — both save ~nothing). Speed levers, in order: **fewer
interpolators (×9, trivial)**, then **fix the homotopy collapse (×3, hard)**.

### 6.4 The parameter-homotopy collapse — what it precisely is
Tracking point1→point2 lands **4 of 16**; point2→point3 lands 2 of 17. HC's `ParameterHomotopy` is a
**straight real segment** `H(x,t)=F(x; t·p_start+(1−t)·p_target)` with **no γ-trick** (confirmed in
`HomotopyContinuation/.../parameter_homotopy.jl`); the γ-trick is only in the start-system homotopy.
Dissecting the 12 lost paths (`stall_jacobian.jl`):

- `max_steps = 10000`; 50× more steps / extended precision / conservative tracking recover **zero** →
  not a budget or precision problem.
- At each stall: **‖F‖ ≈ 1e−10 (on the variety), but ∂F/∂x is rank-deficient — rank 28–29 of 32,
  σ_min ≈ 1e−9, cond ≈ 1e13–1e16.** The path reaches a **genuine singular solution**; the implicit
  function theorem fails (no invertible Jacobian) → Newton can't correct → step→0 → `terminated_max_steps`.
  Extended precision not helping confirms the singularity is **genuine**, not Float64 ill-conditioning.
- **The null direction is the order-8 jets `Ca_8 + Cb_8`** (null vector ≈ 0.68·Ca_8 + 0.68·Cb_8, with
  only ~2–5% parameter components) — i.e. **exactly the `Ca_8+Cb_8 = y2_8` combination the trim dropped.**
  The stalled solutions are **spurious** (negative `Ca_0`), not truth/swap, and **not** on the swap
  locus (`Ca_0 ≠ Cb_0`). The collapse is **broad** (`locality_and_swap.jl`: tracking from t=0.5 is fine
  to t=0.3 (13/17) but craters by t=0.2 and stays cratered to −0.5), worsening as the jets grow.

### 6.5 The resolution — it's the high-order-derivative problem in disguise
Putting 6.2–6.4 together: the trim correctly won't pin `Ca_8+Cb_8` from the (unreliable) `y2_8` data, so
that combination is determined only **indirectly** through the ill-conditioned high-order dynamics →
the Jacobian goes rank-deficient there → spurious near-singular branches → the straight-line parameter
homotopy stalls on them. **The ill-determined direction is a nuisance jet (`Ca_8+Cb_8`), ~98% decoupled
from the parameters — so recovery of the parameters/ICs is unaffected** (the fresh γ-solve + singular
endgame resolves the near-singular solutions). So:

- **It is not a physical/dynamical bifurcation.** The receptor dynamics are smooth/monostable. The
  singularity lives in the algebraic *recovery* problem, on *spurious* branches manufactured by the trim.
- **Pin-keeping is a trap.** Re-adding `Ca_8+Cb_8=y2_8` would remove the singularity but inject the
  garbage 8th-derivative datum → recover a garbage `Ca_8`. Bad trade.
- **The principled speed fix is to need lower orders:** `use_multipoint` spreads information across
  shooting points, lowering the max derivative order per point → better-determined jets → the
  nuisance singularity shrinks → the homotopy can plausibly track. The wallaby config uses multipoint;
  cross-noise validation under it was launched but is impractically slow on this system (see §7).

---

## 7. Shipped vs open

- **Shipped (main, acd2419, regression 446/446):** `use_column_scaling = true`, `branch_completion = true`,
  the branch-aware ranking/instantiation refactor. Receptor recovers **truth+swap 2/2 at noise 0** end-to-end.
- **Open:** cross-noise validation under the *literal* wallaby config (20 shooting points, multipoint
  `max_pairs=15`, 9 interpolators, polish). It was launched (4 noise levels) but is **pathologically
  slow on receptor** — ~17 h in, still solving multipoint systems with `mixed_volume` 35k–50k — the
  compounded cost of everything in §6. A lighter sweep (fewer points, multipoint off/reduced) would
  answer the cross-noise recovery question in ~hours instead of days.

---

## 8. One-line summary of each finding

| finding | verdict |
|---|---|
| 18 generic finite solutions; M=2 from a↔b swap | physical, structural |
| t≈−0.3 blind spot | column-scaling pathology; fixed (shipped) |
| 6402 vs 297 paths, ~500× cond, 16 spurious | caused by the trim dropping high-order pins |
| trim dropping the pins | **correct** (avoids unreliable high-order derivative data) |
| 87-min cost | 9 interpolators × 3 homotopy-collapse fresh solves (not backsolve/resolve) |
| parameter-homotopy collapse | paths hit genuine rank-deficient singular *spurious* solutions; null dir = `Ca_8+Cb_8` |
| is it a physical bifurcation? | **no** — identifiability/formulation feature; recovery unaffected |
| fix the homotopy speed | multipoint (lower order); **not** pin-keeping |

---

## 9. Reproduce / artifacts

Model: `src/examples/models/branch_stress_systems.jl:80`. All diagnostics
(`julia --startup-file=no <script>`):
- `repro/receptor_solution_count_2026_05_26/REPORT.md` — solution count + blind spot (Exp A–K) + PAL consult #1.
- `docs/2026-05-27_column_scaling_and_backsolve_resolve.md` — column scaling + the corrected cost diagnosis.
- `repro/receptor_breakdown_2026_05_27/` (this session):
  - `receptor_profiled.jl` — `profile_phases` (the 99.5% phase).
  - `homotopy_solve_count.jl` — the homotopy collapse (16→4, 17→2) + 5 solves/interpolator.
  - `homotopy_path_diag.jl` — per-path codes/steps; option probes (steps/precision don't help).
  - `stall_jacobian.jl` — the rank-deficiency dissection (σ_min, cond, rank at each stall).
  - `locality_and_swap.jl` — locality sweep + the `Ca_8+Cb_8` null direction (refutes swap-locus).
  - `complex_detour_test.jl` — `pr.t` stall localization + complex-midpoint (partial recovery).
  - `extract_Et_order.jl` / `y1_usage.jl` / `Lk_usage.jl` — the SIAN Et order + which data is used.
  - `resolve_timing.jl` / `bounds_compare.jl` — resolve cost + opt-bounds clamp (no effect).
- PAL consult #2 (2026-05-28): gpt-5.5 + gemini-3.1-pro on the homotopy collapse (both confirmed a
  genuine singularity; recommended complex-arc / generic-complex-seed; gpt-5.5 flagged spurious-branch
  + endpoint-singularity nuance — borne out by the stall dissection).
