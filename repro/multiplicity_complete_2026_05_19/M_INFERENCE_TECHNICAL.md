# Auto-computing algebraic multiplicity M — technical deep dive

Audience: anyone (human or LLM) helping us figure out the cleanest path
to compute algebraic multiplicity M automatically inside ODEPE without
duplicating the heavy algebraic machinery that SIAN-Julia and
StructuralIdentifiability.jl already perform. Includes a survey of all
three codebases and a recommendation.

Companion to `M_INFERENCE_INVESTIGATION.md` (PEB
`results/wallaby_analysis/multiplicity/`) — cluster's same-day notes —
and `MULTIPLICITY_COMPLETE.md` in this directory.

---

## 1. Definition of M

Let `(θ*, x*)` be the truth parameter and IC tuple for an ODE PEP, and
let `y*(t) = h(x*(t); θ*)` be the truth observation trajectory. The
**algebraic multiplicity M** is:

> **M = the number of distinct `(θ, x_0)` tuples in the identifiable
> subspace that produce the same observation trajectory `y*(t)` as
> `(θ*, x*_0)`.**

Equivalently (operationally): if we substitute the truth observation
into the polynomial system that SIAN constructs (call it `Et`) and
solve the resulting zero-dim system over (state, parameter) space,
M is the number of distinct complex solutions, counted modulo
the continuous unidentifiable axes that SI flags `:nonidentifiable`
(these get plugged at a representative value via
`representative_completion_value` in
`src/core/parameter_estimation_helpers.jl:380` — 1.0 for parameters,
0.0 for states).

Reference for the catalog: this session's
`MULTIPLICITY_COMPLETE.md` derived M empirically for the 23 wallaby
benchmark systems. **19 have M = 1**; **4 have M = 2**
(daisy_mamil4, seir, slow_fast, biohydrogenation, the last one in its
identifiable subspace after plugging x7). The 4 catalog values were
verified against branch transformations and the cluster's
cd10-distinct-row analysis.

For "physical M" (multiplicity restricted to user-provided bounds
`[opt_lb, opt_ub]`): same definition, but discard algebraic roots
outside the bound region. By this stricter notion only daisy_mamil4
and seir have M = 2; slow_fast and biohydrogenation have an OOB
algebraic alter-ego.

This document focuses on **algebraic M** (the catalog values); a
post-processing filter against bounds is a separate concern.

---

## 2. What SI.jl computes (and doesn't)

Source: `~/rsync-readonly-PEB/environments/StructuralIdentifiability.jl/`

### The call graph for `assess_identifiability(ode)`

```
assess_identifiability  →  _assess_identifiability
                              ├─  _assess_local_identifiability   →  bool per param
                              └─  assess_global_identifiability   →  bool per param
                                     └─  check_identifiability
                                           └─  initial_identifiable_functions
                                                 ├─  _find_ioequations  →  Dict{leader, poly}
                                                 ├─  wronskian
                                                 └─  extract_identifiable_functions_raw
                                                       →  list of identifiable rational functions
```

The output is a Dict{var → {:globally, :locally, :nonidentifiable}} —
**no M is computed anywhere**.

### What about `primality_check.jl`?

`check_primality_zerodim(J)` at lines 3-29 already calls
`length(Groebner.quotient_basis(J))` and assigns it to `dim`. **But
this is the wrong ideal for M.** Looking at how `J` is constructed in
`check_primality(polys, extra_relations)` (lines 41-55):

- `leaders = collect(keys(polys))` — these are the leaders of the
  io-equations (derivatives of observations).
- `eval_point = [v in leaders ? v : ring(rand(1:100)) for v in gens(ring)]`
  — **substitutes random values for everything except leaders**.
- `zerodim_ideal = map(p -> parent_ring_change(evaluate(p, eval_point), Rspec), all_polys)`
  — projects to the leader ring.

So `dim` here counts **leader-tuples consistent with random parameters**,
not the other way around. For an ODE PEP with parameters fixed, the IO
equations overdetermine the leader trajectory — generically `dim = 1`
(one leader tuple). This is not M.

Cluster verified empirically on canonical DAISY MAMIL-4:
- `check_primality(io_projections)` returned `true` with `dim = 1`
- but `assess_identifiability(ode)` reported 6 `:locally` vars,
  confirming M > 1.

### What SI.jl does expose (as building blocks)

- `find_ioequations(ode)` — returns the IO-equations Dict {leader → poly}.
- `find_identifiable_functions(ode)` — returns generators of the
  identifiable subfield (rational functions of params).
- `reparametrize_global(ode)` — re-parameterizes the ODE so all
  remaining parameters are globally identifiable.

The extension degree `[K(all_vars) : K(identifiable_subfield)]` equals
M. SI.jl computes the GENERATORS of the subfield but **not the
extension degree**. Computing the extension degree from generators
requires another Groebner basis call — same kind of work SIAN already
does in its own pipeline.

**Conclusion on SI.jl:** the wrong primality_check ideal aside, M is
not computed in the current call graph. A patch would be "add new
computation", not "expose what's there". Larger PR than expected.

---

## 3. What SIAN-Julia computes (and almost exposes)

Source: `~/rsync-readonly-PEB/environments/SIAN-Julia/src/SIAN.jl`

### The relevant code path

The main function is `identifiability_ode(ode, params_to_assess; p=0.99, ...)`
at lines 47-304. It does:

1. **Build `Et`** (lines 111-156): the polynomial system whose roots
   in `(state, parameter)` space ARE the algebraic solution branches.
   Built by iterative prolongation of the Y-equations with rank checks.
2. **Sample random point** (lines 209-218): sample `y_hat, u_hat,
   theta_hat` at random with `D2` (degrees-of-freedom-based bound)
   ensuring genericity with probability `p`.
3. **Substitute leaders** (line 221):
   ```julia
   Et_hat = [evaluate(e, vcat(y_hat[1], u_hat[1]), vcat(y_hat[2], u_hat[2])) for e in Et]
   ```
   `Et_hat` is now a polynomial system in `(states, parameters)` only —
   leaders are gone. **This is the right ideal for M.**
4. **Build saturated ring** (lines 226-262): collect remaining vars,
   pick variable ordering (parameters listed last in degrevlex →
   eliminated last during GB), build polynomial ring.
5. **Compute Groebner basis** (line 267):
   ```julia
   gb = groebner(vcat(Et_hat, parent_ring_change(z_aux * Q_hat, Rjet_new) - 1))
   ```
   The `z_aux*Q_hat - 1` is Rabinowitsch's trick — saturates at `Q_hat != 0`.
   The ideal is now `<Et_hat, z_aux*Q_hat - 1>` over the
   `(states, z_aux, parameters)` ring.
6. **Test global identifiability per parameter** (lines 272-291):
   for each locally-identifiable param `θ_i`, compute
   `Groebner.normalform(gb, θ_i)`. If equal to `θ_i_hat` (the random
   value), then `θ_i` is globally identifiable (1 root). Otherwise
   locally (multiple roots).

### Where M lives

**`length(Groebner.quotient_basis(gb))` is exactly M.**

The quotient basis dim of a zero-dim ideal equals the number of points
in V(I) counted with multiplicity. Since:
- `<Et_hat>` describes (state, param) tuples consistent with the
  random observation
- `z_aux*Q_hat - 1` forces `z_aux = 1/Q_hat` (deterministic given Q_hat)
- ergo `z_aux` contributes 1 to the count
- and for fixed (state, param) consistent with the data, the state
  trajectory through time is determined by the ODE — so projecting
  out states doesn't change the count generically

`length(quotient_basis(gb))` IS M with probability `p` (same probability
guarantee SIAN already provides for the global-vs-local distinction).

### What SIAN does NOT do

- Never calls `length(quotient_basis(gb))`. The `gb` is only used via
  `Groebner.normalform(gb, θ_i^...)` to test global ID per parameter.
- `deg_variety` at line 211 is the **Bezout upper bound** (product of
  total degrees of polys in `Et`) — used to compute the sampling
  bound `D2`. It's an overestimate of M, not M.

### Anatomy of the right patch

Add `length(Groebner.quotient_basis(gb))` immediately after line 267 and
expose it via the `result` Dict. Roughly:

```julia
# Around line 267 of SIAN.jl
gb = groebner(vcat(Et_hat, parent_ring_change(z_aux * Q_hat, Rjet_new) - 1))

# NEW: 1 line — compute M
algebraic_multiplicity = length(Groebner.quotient_basis(gb))

...
# Around line 292, in the result Dict
result = Dict(
    "globally" => ...,
    "locally_not_globally" => ...,
    "nonidentifiable" => ...,
    "algebraic_multiplicity" => algebraic_multiplicity,  # NEW
)
```

Patch size: ~3 lines + 2-3 tests (the 4 mult-2 wallaby systems should
return M=2; the 19 mult-1 systems should return M=1). Then a doc update
flagging the new return field.

The downside: we'd be adding a return field to an upstream package and
waiting for review/merge/release.

---

## 4. What ODEPE already has

Source: `/home/orebas/.julia/dev/ODEParameterEstimation/src/core/si_equation_builder.jl`

### The function `get_polynomial_system_from_sian` (line 859)

ODEPE **re-implements SIAN's `Et` construction faithfully** inside
ODEPE — see si_equation_builder.jl:859-1052. This is essentially a
copy of SIAN.jl:111-156 (the prolongation loop) plus some extras
(filters phantom variables; runs an algebraic-independence reduction).

At line 984 ODEPE computes:
```julia
Et_eval_base = [Nemo.evaluate(e, vcat(u_hat[1], y_hat[1]), vcat(u_hat[2], y_hat[2])) for e in Et]
```

**This is `Et_hat`.** Same substitution SIAN does at SIAN.jl:221.

ODEPE then drops the Groebner step entirely. It uses `Et_hat` only for
local-identifiability Jacobian-rank checks (lines 987-996) and then
converts the polynomial system back to Symbolics for downstream use.

### What this means

**ODEPE already has every input needed to compute M, without touching
SIAN-Julia or SI.jl.** Specifically at line 984:

- `Et_hat` (= `Et_eval_base`) — polynomial system in (states, params)
- `Q` (from line 861's `SIAN.get_equations`) — used to build `Q_hat`
- `u_hat` (from sampling) — needed to evaluate `Q` → `Q_hat`
- `z_aux` (already declared in the ring via `gens_Rjet`) — saturation aux

So ODEPE can add ~10 lines at the end of `get_polynomial_system_from_sian`
to compute M itself:

```julia
# Compute algebraic multiplicity M = dim of zero-dim ideal in
# (state, parameter) space, after saturating at Q != 0.
# Same approach SIAN-Julia uses internally; we just expose the count.
Q_hat = Nemo.evaluate(Q, u_hat[1], u_hat[2])
z_aux = gens_Rjet[end - length(mu)]  # already in the ring
# Choose elimination ordering so params are last
ring_for_gb = ...  # may need to rebuild ring with degrevlex + correct var order
Et_hat_new = [SIAN.parent_ring_change(e, ring_for_gb) for e in Et_eval_base]
z_aux_Q_minus_1 = SIAN.parent_ring_change(z_aux * Q_hat, ring_for_gb) - 1
gb = Groebner.groebner(vcat(Et_hat_new, z_aux_Q_minus_1))
algebraic_multiplicity = length(Groebner.quotient_basis(gb))
```

ODEPE already depends on Groebner.jl transitively (via SIAN). No new
deps. No upstream PR needed.

### Risk

The Groebner basis computation can be expensive — but **SIAN does this
exact computation** in `identifiability_ode`, which we're skipping in
favor of our own polynomial-extraction. By reusing the SIAN ring
structure and ordering, we'd be doing a comparable amount of work to
what we'd be saving by not calling `identifiability_ode` separately.

Net: probably zero or negative additional wall time per cell when M
is computed at the same time as the SI template.

The Groebner crash on bicycle_model from my earlier session (over-
parameterized translation) is a different beast — the wallaby cells
declare a smaller parameter set, and the actual SIAN `Et` for those
cells has been running successfully in production (per stderr logs).
So this approach should be Groebner-bug-clean.

---

## 5. SI gate (the easy 19/23)

Independent of which Groebner-based path we take for M > 1, the SI
gate handles the easy cases:

```
if count(:locally entries in assess_identifiability(ode)) == 0:
    M = 1   # fully automated, no further computation needed
else:
    M > 1   # SI proves this; need Groebner to give the value
```

This gate fires correctly for all 19 mult-1 wallaby systems (per
cluster's `m_inference_validation.md`). It's already fully automated.

The remaining work is the M > 1 path — i.e., computing the actual M
value for the 4 (or more, on other benchmarks) systems where SI defers.

---

## 6. Four paths, ranked

### Path A: SIAN-Julia upstream patch (~3 lines + tests + docs)

Expose `length(Groebner.quotient_basis(gb))` from `SIAN.jl:267` in the
return Dict. Pogudin (the author) needs to review and merge.

- Pro: cleanest. Cost is on the right side of the abstraction (the
  package that already does the computation).
- Pro: makes M available to all SIAN users, not just ODEPE.
- Con: external coordination + release cycle.
- Risk: low. The math is sound.

### Path B: SI.jl new function

Add `assess_algebraic_multiplicity(ode)` that builds the parameter-space
ideal (dual of `check_primality`'s leader-space ideal) and counts its
quotient dim. Same author as SIAN, larger patch (new code, not just
exposing).

- Pro: more aligned with SI.jl's current API surface.
- Con: bigger PR. More review burden.
- Risk: similar.

### Path C: ODEPE-internal, harvest from `get_polynomial_system_from_sian` (~10 lines, zero upstream)

Add the Groebner basis step at the end of ODEPE's existing
`get_polynomial_system_from_sian`, using `Et_hat` and `Q` that are
already available there.

- Pro: ships in ODEPE today, no external coordination.
- Pro: re-uses SIAN-faithful `Et` construction that ODEPE already does.
- Pro: same Groebner backend SIAN uses (already a transitive dep).
- Con: cost lives in ODEPE rather than upstream — other SIAN users
  don't benefit.
- Con: if SIAN later changes its internals, we'd need to track.
- Risk: low. The ring construction needs care (elimination ordering
  for parameters; the Rabinowitsch saturation needs the z_aux variable
  correctly placed). All of this is already correctly done in SIAN.jl
  lines 226-267 — we'd be copying that code into ODEPE.

### Path D: HC.jl from scratch

Build the polynomial system from `find_ioequations` output, call
HomotopyContinuation.solve, count distinct complex roots at cd10.

- Pro: no Groebner. HC.jl handles the numerics differently.
- Con: have to reconstruct the right ideal correctly. Risks subtle
  bugs that Path C avoids by reusing SIAN's already-correct system.
- Pro: HC's numerical dedup is more forgiving than Groebner's exact
  approach in some edge cases.

### Recommendation

**Path C** is the fastest to ship and lowest risk. ~10 lines, no
upstream coordination, reuses code that's already running correctly
in ODEPE.

**Path A in parallel** as a longer-term cleanup. If/when SIAN-Julia
exposes `length(quotient_basis(gb))`, ODEPE can drop its Path C
inline computation and call SIAN's exposed field instead.

Path B and D are alternatives if A and C run into issues. Not
recommended as first choice.

---

## 7. Concrete test fixtures

For any of the four paths, the validation test is the same:

| System | Expected M |
|---|---|
| lotka_volterra | 1 |
| daisy_mamil3 | 1 |
| harmonic_oscillator | 1 |
| brusselator | 1 |
| (18 other M=1 systems) | 1 |
| daisy_mamil4 | **2** |
| seir | **2** |
| slow_fast | **2** |
| biohydrogenation | **2** (≥ 2 in id-subspace after plugging x7) |

The @ODEmodel forms for all 23 are in
`repro/multiplicity_complete_2026_05_19/run_sian_all_23.jl` — they
work today with current SI.jl and SIAN-Julia versions.

A simple pass criterion: `compute_M(ode)` returns the expected integer
for at least 22 / 23 systems (allowing for one edge case like
biohydrogenation where the answer depends on whether x7 is plugged at
0.0 vs left free).

---

## 8. Open questions for review

1. **Does `length(quotient_basis(gb))` exactly equal M, or only with
   probability p?** Same probabilistic guarantee as SIAN's
   global-identifiability test — the random sample at `D2`-sized
   parameters is generic with probability ≥ p. The exact-vs-probabilistic
   distinction matters for the paper claim ("we compute M exactly via
   ...") — we should state it the same way SIAN states its global ID
   guarantee.

2. **What about multi-cell averaging?** Does `M` depend on the random
   sample point? Theoretically yes (with small failure probability);
   practically the sample sizes used by SIAN (D2-based) make this
   probability tiny. The cluster's `m_inference_pipeline.py` empirical
   validator (which we shouldn't rely on as the algorithm, only as a
   sanity check) uses median-across-cells to smooth noise.

3. **Is M sensitive to the choice of leader ordering, eval point, etc.?**
   For a generic ODE PEP, no — the quotient_basis dim is invariant of
   the GB term ordering (it's an algebraic invariant of the ideal).
   Sensitivity to the random eval point is the same as for SIAN's
   global ID test. Both are well-understood.

4. **Bound-aware "physical M"** (the user's question about why slow_fast
   and biohydrogenation behave differently from daisy_mamil4 and seir):
   compute algebraic M first via any of the paths above, then
   post-filter against `[opt_lb, opt_ub]` to get physical M. This is
   a separate post-processing step, not a different definition.

5. **What if the user provides only some `:nonidentifiable` plug-ins
   and not others?** For example, a user fixes one continuously-
   unidentifiable parameter but leaves another free. Then M is
   measured in the **partially reduced** subspace. The plug-in
   mechanism via `representative_completion_value` should handle this
   correctly today — but worth testing.

---

## 9. File pointers for follow-up

- `~/rsync-readonly-PEB/environments/SIAN-Julia/src/SIAN.jl:111-267` —
  the Et construction + gb computation
- `~/rsync-readonly-PEB/environments/StructuralIdentifiability.jl/src/primality_check.jl:3-29` —
  check_primality_zerodim (wrong ideal but right machinery)
- `~/rsync-readonly-PEB/environments/StructuralIdentifiability.jl/src/StructuralIdentifiability.jl:110-195` —
  assess_identifiability entry point
- `~/rsync-readonly-PEB/environments/StructuralIdentifiability.jl/src/global_identifiability.jl:251-308` —
  assess_global_identifiability
- `/home/orebas/.julia/dev/ODEParameterEstimation/src/core/si_equation_builder.jl:859-1052` —
  ODEPE's get_polynomial_system_from_sian (where Path C would go)
- `/home/orebas/.julia/dev/ODEParameterEstimation/src/core/parameter_estimation_helpers.jl:380` —
  representative_completion_value
- `~/rsync-readonly-PEB/results/wallaby_analysis/multiplicity/M_INFERENCE_INVESTIGATION.md` —
  cluster's complementary investigation
- `~/rsync-readonly-PEB/results/wallaby_analysis/multiplicity/m_inference_validation.md` —
  cluster's empirical validator
- `repro/multiplicity_complete_2026_05_19/MULTIPLICITY_COMPLETE.md` —
  the M=2 catalog and branch transformations
- `repro/multiplicity_complete_2026_05_19/run_sian_all_23.jl` —
  reproducible @ODEmodel forms for test fixtures
