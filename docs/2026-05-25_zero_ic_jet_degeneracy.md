# Zero-IC Jet Degeneracy: why `seir` branch completion fails at t0

Date: 2026-05-25

Status: **resolved diagnosis.** This explains the open `seir` puzzle in
[`2026-05-25_branch_completion_hc_debugging.md`](2026-05-25_branch_completion_hc_debugging.md)
and generalizes it. The failure is not an HC bug, not a template bug, and not a
branch-completion plumbing bug. It is a **degenerate evaluation point**: the true
initial condition `In(0) = 0` is a critical point of the identifiability map.

This matters in practice because zero initial conditions are common in real
models (epidemic compartments seeded at zero, pharmacokinetic compartments that
start empty, chemical products that start at zero concentration). The same
phenomenon was already seen on ERK (see "Prior instance" below), so treat this
as a recurring failure mode, not a one-off.

## TL;DR

- `seir` observes `y1 = In`, `y2 = N`, with true IC `In(0) = 0`.
- The only place `S` and `b` enter the dynamics is the bilinear term
  `b·S·In/N`. At `In = 0` that term — and its low-order derivatives — are
  suppressed. So the **local observable jet at t0 carries almost no information
  about `S` and `b`.**
- The polynomial system that branch completion instantiates from the t0 jet is
  therefore rank-deficient: `cond(J) = 4.4e17`, `mixed_volume = 0`, and it is
  satisfied by the **true** parameters *and* by both spurious "branches"
  simultaneously.
- The two "excellent candidates" (err ≈ 2e-14) are **solver-root artifacts**,
  not algebraic siblings. They are far from truth in parameter space and drift
  2–4% off the true `In(t)` trajectory at the tail. `err ≈ 2e-14` is the *local*
  algebraic residual, not a global trajectory fit.
- Generic algebraic multiplicity (`compute_algebraic_multiplicity` → `seir`
  `M = 2`) is a count at a *generic* point. Branch completion at t0 solves the
  *degenerate* instance, which is a different (ill-posed) problem.

## Ground truth vs. the two "branches"

True model (`src/examples/models/biological_systems.jl:7`):

```text
params: a = 0.2,  b = 0.4,  nu = 0.15
ICs:    S = 990,  E = 10,   In = 0,  N = 1000
obs:    y1 = In,  y2 = N            (N is constant -> effectively only In is seen)
eqs:    S' = -b S In/N
        E' =  b S In/N - nu E
        In'=  nu E - a In
        N' =  0
```

| | a | b | nu | S(0) | E(0) | In(0) | max&#124;In−In_true&#124; on [0,60] |
|---|---|---|---|---|---|---|---|
| **TRUE**          | 0.20 | 0.40 | 0.15 | 990 | 10.0 | 0  | 0 (reference) |
| Branch 1 (anchor) | 0.083 | 0.460 | 0.267 | 420 | 5.62 | ~0 | 1.80 (~2.7% at t=60) |
| Branch 2          | 0.068 | 0.489 | 0.282 | 352 | 5.32 | ~0 | 2.65 (~3.9% at t=60) |

Neither branch is close to truth. Both fit the early trajectory and the order-6
t0 jet essentially exactly, then diverge at the tail.

## The mechanism: `In(0)=0` is a critical point of the identifiability map

`S` and `b` only influence the observed `In(t)` through the bilinear coupling
`b·S·In/N`. Near t0, `In ≈ 0`, so:

- `S'(0) = -b·S·In/N ≈ 0` (the susceptible pool barely moves),
- in the algebraic system the products `S_k·b_0` are multiplied by `In_j`
  coefficients that are ~`1.3e-13` at t0,
- so the Jacobian directions that distinguish `(S, b)` collapse.

This is precisely a rank-deficient point of the map from parameters to the local
observable jet — a critical point, in the sense the term is used for
identifiability. Away from t0 (where `In(t) > 0`) the coupling is active and the
jet becomes informative; the degeneracy is **specific to the evaluation time**,
not global.

## Evidence (all reproduced; see `repro/seir_zero_ic_degeneracy_2026_05_25/`)

**1. The instantiated t0 system is toric-degenerate, and cascade is not enough.**
`cascade_mixed_volume_probe.jl` reconstructs the exact 26×26 system from the
debug dump:

```text
full 26x26 :  mixed_volume = 0    solve_with_hc real roots = 0
```

`mixed_volume = 0` because four equations are pure monomials `N_1, N_2, N_3, N_4`
(the conserved population's derivatives, all = 0). A single-monomial Newton
polytope is a point, which zeroes the mixed volume; polyhedral homotopy only
counts torus `(C*)^n` roots, and the true root sits on coordinate hyperplanes
(`N_k = 0`, `In_0 ≈ 0`). Cascade-eliminating the 11 single-variable equations
removes the monomials:

```text
reduced 15x15:  mixed_volume = 6   solve_with_hc real roots = 0   (still none)
cond(Jacobian at anchor) = 4.4e17  (sigma_min = 1.4e-14 < machine eps)
Newton-from-anchor       = rejected, moves 518 away
```

So cascade preprocessing fixes the `mixed_volume = 0` symptom but the root is
still numerically singular. The degeneracy is intrinsic to the t0 evaluation.

**2. Truth, anchor, and branch-2 are all roots of the same system.**
`three_roots_check.jl` evaluates the same t0 system at each candidate:

```text
TRUTH     ‖F‖ = 1.8e-9
ANCHOR    ‖F‖ = 2.3e-13
BRANCH-2  ‖F‖ = 1.3e-9
```

The SI-template equations are consequences of the ODE, so any trajectory —
including truth — satisfies them. The system genuinely admits ≥3 real solutions
and cannot separate them. This is the cleanest statement of "degenerate."

**3. The branches are not observationally equivalent to truth.**
`trajectory_check.jl` integrates all three and compares `In(t)`: the branches
match early but diverge 2–4% at the tail. A *genuine* algebraic sibling would
match to ~0% everywhere. These do not — they are local-jet artifacts.

## Why this comes up in practice

Zero initial conditions are not exotic. The dangerous combination is:

1. a state starts at (or near) **zero**, **and**
2. that state is **observed** (it is, or dominates, an observable), **and**
3. it enters other equations **multiplicatively** (mass-action / bilinear), so
   its coupling vanishes at zero, **and**
4. observation is **limited** (the states that would otherwise pin the
   parameters are not separately seen), **and**
5. derivatives are evaluated **at/near** that zero point (t0 shooting).

When all hold, the local jet is rank-deficient: the solver returns
confident-looking roots (tiny local residual) that are far from truth, and
fit-based ranking cannot detect it.

Real settings where (1)–(3) routinely hold:

- **Epidemiology / compartmental models**: infected/exposed compartments seeded
  at zero; the observed incidence couples bilinearly (`β S I`).
- **Pharmacokinetics**: drug concentration is zero before dosing; many
  compartments start empty.
- **Chemical kinetics**: product/intermediate concentrations start at zero;
  mass-action coupling.

### Prior instance: ERK

This is the same disease documented for ERK (see auto-memory and
`temp_plans/erk_deep_dive/`): *"t=0 degenerate: 0 solutions even with perfect
data (4 ICs = 0 makes system singular)"* and *"shifting eval point to t=5h makes
AAAD machine-precision accurate."* ERK has four zero ICs; `seir` has one
observed zero IC. Both fail at t0 for the same reason and both improve away from
t0. Two documented instances ⇒ recurring.

### Relationship to the open column-scaling investigation

`CLAUDE.md` records Jacobian condition numbers of `1e6`–`1e10` on
`biohydrogenation` / `daisy_mamil4` driving recovery error. The `seir`-at-t0
`cond(J) = 4.4e17` is the same family, taken to the extreme by the zero IC. The
coefficient spread alone (`1.3e-13` from `In_0` next to `1000` from `N_0`) is a
16-order-of-magnitude range in one matrix. Variable/equation scaling would help
the *conditioning*, but it cannot manufacture information that the zero-IC jet
does not contain.

## Detection and mitigation

Cheap signals that the instance is degenerate, in rough order of cost:

- an **observed state's value is ~0 at the chosen shooting point** (the most
  direct, model-aware signal),
- `mixed_volume(hc_system) == 0` while `paths_to_track(...) > 0`,
- `cond(J)` at a candidate above a threshold (e.g. `> 1e12`),
- HC reports only singular / non-real roots for a system with a verifiable real
  anchor.

Mitigations:

1. **Evaluate derivatives away from the degenerate point.** Pick shooting /
   branch-completion evaluation times where observed states are non-degenerate
   (`In(t*) > 0`). This is the general fix and matches the ERK "shift eval
   point" result. The algebraic siblings are global (same parameters at every
   time), so solving at `t*` and backsolving to t0 is valid.
2. **Cascade-eliminate single-variable equations before HC** regardless — good
   hygiene; removes the `mixed_volume = 0` pathology and improves conditioning
   (necessary but not sufficient).
3. **Guard branch completion**: when the instance is degenerate, skip completion
   (or shift `t*`) instead of returning solver-root artifacts. Returning a
   confident-looking degenerate result is worse than returning nothing.
4. **Report practical non-identifiability** at the degenerate point rather than
   a point estimate.

## Implications for branch completion and the Quoll Branch Suite

- **Do not validate or tune branch completion on `seir`-at-t0.** It exercises
  the degenerate instance, not the algebraic-completion mechanism. The two
  "excellent candidates" are exactly what `branch_hunt_results.md` warns about:
  *"solver roots alone are not branch evidence."*
- **Use the constructed clean cases** for validation:
  `latent_subpopulation_branch` (M=6) and `receptor_subtype_binding_branch`
  (M=2). These use strictly-positive ICs and get multiplicity from a clean
  permutation symmetry of an aggregate observation, with an observed control
  that breaks the symmetry to M=1. They are well-conditioned everywhere, so HC
  genuinely recovers all siblings.
- **`seir` belongs in the caveat bucket** (with `slow_fast`, `biohydrogenation`)
  in the Quoll Branch Suite analysis, not the clean-branch bucket. Its `M=2`
  catalog entry is a *generic* count and should be re-checked at a
  non-degenerate evaluation time before being treated as recovered-branch
  evidence.

## Reproduction

```bash
cd repro/seir_zero_ic_degeneracy_2026_05_25
julia --startup-file=no trajectory_check.jl        # branches drift 2-4% from true In(t)
julia --startup-file=no three_roots_check.jl        # truth + anchor + branch-2 all roots
julia --startup-file=no cascade_mixed_volume_probe.jl   # mixed_volume 0 -> 6, still 0 real roots, cond 4e17
```

All three scripts are self-contained (they embed the dumped system / candidate
values and do not depend on `/tmp`).
