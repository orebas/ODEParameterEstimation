# G2 — CSTR_1_0 (zero-noise) under current code

Generated: 2026-05-05.

## Setup

`cstr_1_0` from bilby — zero-noise edition. Model:
- 3 states: C, Temp, r_eff
- 4 params: tau, Tin, dH_rhoCP, UA_VrhoCP
- **Only 1 observable**: y1 = 700 · Temp
- `sin(0.5·t)` forcing in `D(Temp)` equation
- `r_eff` divides by `Temp²` (severe nonlinearity)
- Time interval [0, 20], 1501 data points
- Truth: tau=0.385, Tin=0.113, dH_rhoCP=0.248, UA_VrhoCP=0.421
- IC: C=0.843, Temp=0.18, r_eff=0.856

The defining structural feature: **3 latent states, 1 observable, 4 unknowns, 1 forcing
term** — a deep observability problem.

## Result under current code

Pipeline ran for **~70 minutes CPU**, produced **606+ algebraic solutions**, then
**crashed**:

```
ERROR: LoadError: State C is missing from the SIAN re-solve output and is not directly
reconstructible. Refusing to fabricate a fallback value without polish.
```

The SIAN backsolve fallback path triggered (because C is not algebraically determined
by the observable y1 alone) and refused to fabricate a fallback for C without polish.
With `polish_solutions = false` (the bilby config), there's no recovery.

## Pool composition

Looking at solutions 580-606 in the log (the last batch before crash):

```
tau values: 0.116-0.121 (consistently ~0.117)
Tin values: 0.38-0.396 (consistently ~0.385)
dH_rhoCP: -0.005 to +0.005 (consistently ~0)
UA_VrhoCP: 0.42 (consistently)
C: 1e35 to 1e98 (WILD — 50+ orders of magnitude)
Temp: 1e40 to 1e44 (WILD)
r_eff: 1e51 to 1e63 (WILD)
```

**The pool is bimodal in a structural sense**: parameters cluster near ONE specific
combination, but states are wildly unbounded.

### The parameter swap

Notice:
- `tau` in pool ≈ 0.117, but **truth `tau` = 0.385**
- `Tin` in pool ≈ 0.385, but **truth `Tin` = 0.113**

The pool has the parameters effectively **swapped** with truth! tau_pool ≈ Tin_truth
and Tin_pool ≈ tau_truth. dH_rhoCP_pool ≈ 0 (near machine precision) vs truth = 0.248.
UA_VrhoCP roughly correct.

This isn't a clean symmetry of the ODE (the two parameters have different roles), but
the pool consistently lands in this swapped-and-collapsed configuration. The most
likely explanation: at this 1-observable underdetermination, the algebraic system has
multiple solutions corresponding to different roles of tau/Tin in shaping the trajectory,
and HC.jl is converging to the wrong one consistently. The dH_rhoCP collapsing to 0
matches the prior memo: "ODEPE collapses parameters C, dH_rhoCP, and r_eff to zero."

## Correction: structural identifiability is FINE

I initially called this a "structural observability deficit" — that was wrong.
StructuralIdentifiability.jl's `assess_local_identifiability` says:

```
OrderedDict{Any, Bool}(
    C(t)        => true,
    Temp(t)     => true,
    r_eff(t)    => true,
    sin_term(t) => true,
    cos_term(t) => true,
    Tin         => true,
    UA_VrhoCP   => true,
    dH_rhoCP    => true,
    tau         => true,
)
```

**Every state, IC, and parameter is locally structurally identifiable.** Including the
latent state C that the pipeline complained about. The system has enough information
in y1(t) = 700·Temp(t) to determine everything — in principle, with sufficient data
and computation.

Global identifiability check started running (computed IO-equations in 31s,
Wronskians in 125s) but Groebner.jl crashed mid-computation with a bounds error.
So we don't know if there's a 2-fold global symmetry, but the (tau, Tin) parameter
swap observed in the pool (tau_pool ≈ Tin_truth, Tin_pool ≈ tau_truth) hints at it.

## Real diagnosis

The pipeline's "State C is missing from the SIAN re-solve output" error is NOT a
structural identifiability problem. It's about the SPECIFIC TEMPLATE the ODEPE
pipeline uses for SIAN backsolve.

What happens:
1. ODEPE chooses a polynomial template that includes a specific subset of state
   derivatives (`good_deriv_level` per observable).
2. Solving F(x, d) = 0 returns values for *some* of the ICs and *some* of the
   parameters; OTHERS need to be back-computed by integrating the ODE.
3. For CSTR, the chosen template returns Temp's IC (since y1 = 700·Temp directly)
   and the parameters. C and r_eff need to come from a SIAN re-solve at t=0.
4. The SIAN re-solve at t=0 uses ALGEBRAIC equations only (no integration). It can
   compute Temp_0, r_eff_0 (since they're algebraic in the equations) but C is
   buried in derivatives — to get C from y1's derivatives at t=0, you need to invert
   the polynomial relations, and the specific template doesn't include the
   right-shaped equations to do so cleanly.
5. With `polish_solutions = false`, no fallback. Crash.

So the issue is **template construction + backsolve mechanism**, not structural
identifiability. With polish=ON, polish runs forward integration with the recovered
parameters and finds C numerically — and bilby's reported 2/8 success matches this:
polish recovers C for some cases but not all (because polish needs a good starting
point; on cstr the template doesn't deliver one).

This is a Class D failure The path to fix it isn't via selection logic or seed strategies; it requires
either:

1. **Different observable parameterization** — additional measurements of C or r_eff,
   or different transformation of Temp (e.g., dy1/dt as a separate observable).
2. **A pipeline that doesn't depend on SIAN backsolve for latent states** — e.g.,
   shoot directly through the ODE (which is what AMIGO2 does end-to-end via
   trajectory-based optimization).
3. **Bounds enforcement** in the polynomial solver — at least keep states in
   physically plausible ranges so the SIAN re-solve has reasonable inputs. Per the
   April memo: "exported polished pools violate nominal bounds heavily."

None of these are in scope for "fix the gate" or "seed strategy." This case
fundamentally fails at the pipeline level given polish=OFF.

## Verdict

**CSTR is firmly Class D** (catastrophic structural failure, distinct from "Class A
pool inadequate" because the issue isn't the pool's CONTENT but the pipeline's
INABILITY TO CONSTRUCT meaningful candidates given the under-observed system).

What CSTR is good for:
- A definitive example of "1 observable for N states" pathology
- A test case for any future bounds-enforcement work
- Validation that AMIGO2 has a real algorithmic advantage on under-observed systems
  (it works end-to-end without needing the SIAN advisory to recover latent states)

What CSTR is NOT good for:
- Seed-strategy R&D
- Gate-fix validation
- Any selection-side intervention

This matches the April 2026 memo's conclusion exactly: "cstr looks structurally
different from the finalist/frontier problem... next issues are observability /
latent-state treatment / bounds enforcement."

## Comparison to flex_arm and forced_lv (other "AMIGO2-only" cases)

| Case | Failure class | Pipeline behavior | What would help |
|---|---|---|---|
| flex_arm_0_1em4 | C — selection miss | Returns wild candidates as winner; truth-near in set but lost | Cluster-first gate (shipped) preserves truth-near in set |
| forced_lv_0_1em2 | A — pool inadequate | Pool best rel ≈ 31%; derivatives at noise=1e-2 are physics-floored | Different interpolator / lower-order SI template / better data |
| **cstr_1_0** | **D — structural** | Pipeline crashes with "state C missing" | Bounds enforcement / different observable / polish=ON fallback |

These are **three genuinely different failure modes** and three different fixes. None
of them is the seed-strategy work I was building. The team's existing post-polish
research (block consensus, finalists, frontier) addresses none of D directly either —
CSTR is in the "bounds + observability" bucket the April memo flagged as separate.

## What about polish=ON?

The bilby benchmark also reports `cstr_1_0` with `polish_solutions=true`. From the
prior `cstr_crauste_deep_dive`:

```
At noise=0:
  amigo2_run:       8/8 success, max rel err 0.034
  odepe_nopolish:   2/8 success, max rel err 0.041 - 1.00 (best polish=ON)
  odepe_polish:     2/8 success (similar)
  odepe_multipoint: 0/8 success, max rel err 2.05
```

So with polish=ON, ODEPE gets 2/8 right (still significantly worse than AMIGO2's 8/8),
but doesn't crash. Polish provides the trajectory-level numerical optimization that
recovers C from optimization rather than from algebraic solve.

This confirms: polish=ON is necessary for CSTR; the bilby `odepe_nopolish` configuration
exposes the fundamental structural deficit. polish=OFF is not a viable mode for
under-observed systems like CSTR.
