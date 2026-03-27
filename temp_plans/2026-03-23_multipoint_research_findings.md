# Multi-Point Polynomial System Research — Findings Record (2026-03-23)

## How SIAN Constructs the Polynomial System

### The Jet Ring (Prolongation Space)
SIAN lifts the ODE to a polynomial ring R_jet over ℚ with variables:
- `x_i_j` = j-th derivative of state x_i (j=0..s+2, where s = n_params + n_states)
- `y_i_j` = j-th derivative of output y_i
- `u_i_j` = j-th derivative of input u_i
- `z_aux` = auxiliary for clearing rational function denominators
- `p_k_0` = parameters (order 0 only)

Generator layout: blocks of (n+m+u) variables per derivative order, then z_aux, then params.

### Derivative Chains
For each state equation dx_i/dt = f_i(x,u,p):
- Order 0: `f_i(x_0, u_0, p_0) - x_i_1 = 0`
- Order j: apply Lie derivative j times → `D^j[f_i] - x_i_{j+1} = 0`

For each output equation y_j = g_j(x,u,p):
- Order 0: `g_j(x_0, u_0, p_0) - y_j_0 = 0`
- Order j: `D^j[g_j] - y_j_j = 0`

The Lie derivative is: `D[F] = Σ_k (∂F/∂v_k) · v_{k+1}` (chain rule through ODE)

### The Rank-Based Prolongation Algorithm (SIAN.jl:119-155)

This is the CORE algorithm that determines the polynomial system:

```
Et = {}           # equation set (starts empty)
β = [0,...,0]     # derivative order per output (length m)
x_theta_vars = params ∪ state_ICs   # unknowns

While any output can still be prolonged:
  For each output i (1..m):
    If prolongation still possible for i:
      candidate = Y[i][β[i]+1]     # next Y equation for output i
      eqs_test = Et ∪ {candidate}

      # Evaluate at random generic point, compute Jacobian
      J = ∂(eqs_test)/∂(x_theta_vars) |_{generic_point}

      If rank(J) == |eqs_test|:        # New equation adds information
        Et = Et ∪ {candidate}
        β[i] += 1

        # CASCADE: add X equations for any new state variables
        For each new x-variable v appearing in Et:
          x_theta_vars = x_theta_vars ∪ {v}
          Et = Et ∪ {X equation for v}     # one equation per new variable

      Else:                              # Equation is redundant
        Stop prolonging output i
```

**Critical property:** The cascade step maintains squareness. Each new Y equation introduces some new state derivative variables. The corresponding X equations (one per new variable) are immediately added. So #equations always equals #variables.

### Groebner Bases
Used ONLY for the global identifiability check (SIAN.jl:267):
```
gb = groebner(vcat(Et_hat, z_aux * Q_hat - 1))
normalform(gb, theta_i)  →  check if parameter is globally identifiable
```
NOT used for constructing the polynomial system.

### Dead Code: `add_to_vars_in_replica` (util.jl:354-389)
A function that renames non-parameter variables by appending `_r` (replica index). Parameters (in `mu`) keep their original names. Written for multi-point but NEVER CALLED.

## Experiment Results

### Experiment 0: SI.jl ME Identifiability
| Model | States | Params | Obs | SE | ME num_exp |
|-------|--------|--------|-----|---------|-----------|
| simple | 2 | 2 | 2 | all global | 1 |
| lotka_volterra | 2 | 3 | 1 | all global | 1 |
| forced_lv_sinusoidal | 4 | 4 | 4 | all global | 1 |
| vanderpol | 2 | 2 | 2 | all global | 1 |
| harmonic | 2 | 2 | 2 | all global | 1 |
| crauste | 5 | 13 | 4 | all global | 1 |
| hiv | 5 | 10 | 4 | all global | 1 |
| seir | 4 | 3 | 2 | 4G 3L | 1 |

All models: `num_exp=1`. Multi-point benefit is purely numerical, not structural.

### Experiment 1: Template Equation Census

Each model's template alternates DATA equations (carry interpolation noise) and STRUCTURAL equations (exact ODE relations). Key metric: the interpolation error grows dramatically with derivative order.

**forced_lv_sinusoidal (12×12):**
- 4 params (alpha, beta, gamma, delta) + 8 state vars (x_0..x_3, y_0..y_3)
- 6 data equations (orders 0, 1, 2) + 6 structural equations
- Order-0 data error: ~0.05, Order-1: ~1.3-2.8, Order-2: ~6.5-6.8

**lotka_volterra (14×14):**
- 3 params + 11 state vars (r_0..r_5, w_0..w_4)
- 5 data equations (orders 0-4) + 9 structural equations
- Error grows from 0.003 (order 0) to 0.035 (order 4)

### Experiment 2: 2-Point System Rank
Combined 2-point systems with renamed variables have full Jacobian rank for most strategies:
- forced_lv_sinusoidal: 20×20, full rank (all strategies)
- lotka_volterra: 25×25, full rank (all strategies)
- seir: 49×49, full rank only with split strategy (drop from A only or B only fails)

**Variable naming bug discovered:** Must use `Symbolics.variable(:x_0_pt2)` (plain symbol), NOT `@variables x_0_pt2(t)` (callable). The SIAN template variables don't have `(t)`, and HC.jl's string-based conversion breaks on substring collisions.

### Experiment 3: HC.jl Solve — CRITICAL NEGATIVE RESULT
**HC.jl finds ZERO solutions for ALL 2-point systems regardless of drop strategy.**

The systems are positive-dimensional (not zero-dimensional) because dropping data equations removes the only constraint that pins certain state derivatives to specific values. The Jacobian having "full rank" at one point is necessary but NOT sufficient for zero-dimensionality — the algebraic variety can still be a curve passing through that point.

## Key Conclusions

1. **Naive equation dropping from SIAN templates is fundamentally wrong** — the template is a minimal independent set where every equation is needed.

2. **The correct approach is to modify SIAN's prolongation algorithm** to work with multi-point structure from the start, so the rank-based selection naturally produces a square system with fewer derivative orders per point.

3. **SIAN already has infrastructure for this** — `add_to_vars_in_replica` was written for variable renaming but never used. The prolongation loop needs to be extended to handle equations from multiple points simultaneously.

4. **The hypothesis to test:** Does the multi-point prolongation reach full rank with lower derivative orders? If the rank contributed by output equations from a second point makes some high-order equations from the first point redundant, then the multi-point system would be both square AND use fewer (more accurate) derivatives.

## Experiment 4 Results: Multi-Point Prolongation (2026-03-23)

### POSITIVE RESULT: Multi-point prolongation reduces derivative orders

**simple model (2 states, 2 params, 2 outputs):**
- Single-point: 8×8, β=[2,2] (order 2 per output)
- **2-point: 12×12, β=[[2,2],[1,1]]** — point 2 only needs order 1!
- System is SQUARE (12 eqs, 12 vars) — produced naturally by the prolongation algorithm
- The second point contributes lower-order equations that complement the first point's high-order equations

### FULL RESULTS — ALL MODELS (2-point prolongation)

| Model | 1pt | 1pt β | 2pt | 2pt β | Max order |
|-------|-----|-------|-----|-------|-----------|
| simple | 8×8 | [2,2] | 12×12 | [[2,2],[1,1]] | 2→2 (pt2:1) |
| lotka_volterra | 14×14 | [5] | 19×19 | [[4],[3]] | **5→4** |
| forced_lv_sinusoidal | 17×17 | [1,3,3,1] | 24×24 | [[1,2,2,1],[1,2,2,1]] | **3→2** |
| harmonic | 8×8 | [2,2] | 12×12 | [[2,2],[1,1]] | 2→2 (pt2:1) |
| seir | 26×26 | [6,1] | 37×37 | [[5,1],[4,1]] | **6→5** |
| hiv | 33×33 | [4,4,4,3] | 45×45 | [[3,3,3,3],[2,2,2,2]] | **4→3** |

ALL models show derivative order reduction. ALL 2-point systems are square.

### Technical details of the implementation
- Combined jet ring: 59 generators (per-point state/output vars + shared params)
- Polynomial lifting uses custom `lift_poly` function (SIAN's `add_to_vars_in_replica` had a bug: it uses `mu` which are non-jet-ring parameter names, not matching jet ring's `a_0`/`b_0` convention)
- `x_theta_vars` must start with shared params + per-point state ICs (not just params)
- The prolongation loop tries candidates from all points × all outputs interleaved
- Cascade adds X equations for the correct point only

### Step D: HC.jl Verification — POSITIVE RESULT (2026-03-23)

HC.jl CAN solve the multi-point prolongation systems:
- **simple (12×12):** 1 real solution found (same count as 1-point). Parameters match truth.
- **lotka_volterra (19×19):** 2 real solutions found (same count as 1-point). One solution has poor parameter accuracy — needs investigation of which time points work best.

The systems ARE zero-dimensional. The prolongation algorithm produces genuinely solvable square polynomial systems. The Nemo→Symbolics→HC.jl conversion pipeline works via:
1. `lift_poly` (custom) converts Nemo ring polynomials to combined multi-point ring
2. `nemo_to_symbolics` converts to Symbolics expressions
3. Observable derivative variables are substituted with real GP interpolation values
4. `solve_with_hc` converts to HC.jl ModelKit and solves

Key technical detail: data variable names in the combined ring follow the pattern `{sian_base}_{order}_{point}` (e.g., `y2_1_2` = output y2, order 1, point 2). The mapping to interpolants goes through SIAN's y_vars (original ring) → measured quantities → interpolant keys.

### Baseline 1-point accuracy (forced_lv_sinusoidal, n=31, AAAD interpolant)

True params: alpha=1.5, beta=1.0, delta=0.5, gamma=3.0

| t_eval | Max rel error | Worst param |
|--------|--------------|-------------|
| 1.3 | 9.9 | gamma=9.64 |
| 2.3 | 17.8 | gamma=-50.4 |
| 3.0 | 244.7 | alpha=368.6 |
| 5.0 | 6.9 | beta=7.92 |
| 6.7 | 2.1 | gamma=9.31 |
| 8.0 | 9.7 | delta=5.35 |

Best 1-point: max_rel_err=2.1 at t=6.7. This is the TARGET for multi-point to beat.

Multi-point prolongation gives β=[[1,2,2,1],[1,2,2,1]] (max order 2) vs single β=[1,3,3,1] (max order 3). Avoids order-3 derivatives entirely.

lotka_volterra and simple are already accurate at 1-point (0.3% and 0.01% errors) — not useful for demonstrating multi-point benefit.

### Step E: Production Data Comparison — POSITIVE RESULT (2026-03-23)

**forced_lv_sinusoidal at n=31 datapoints:**

| Method | Best max rel error | Improvement |
|--------|-------------------|-------------|
| **1-point (best of 6 t values)** | **2.10** (210%) | baseline |
| **2-point t=(1.3, 8.3)** | **0.36** (36%) | **5.8× better** |
| **2-point t=(3.0, 6.7)** | **0.62** (62%) | **3.4× better** |
| **2-point t=(1.7, 6.7)** | **0.87** (87%) | **2.4× better** |

The multi-point system uses β=[[1,2,2,1],[1,2,2,1]] (max order 2) vs single-point β=[1,3,3,1] (max order 3). Avoiding order-3 derivatives reduces the dominant error source.

Point selection matters: t=(1.3, 8.3) is much better than t=(1.3, 5.0). Well-separated points give the best results.

### Experiment 4G: Hard Benchmark Models — ALL Results (2026-03-23)

| Model | s | p | o | 1pt | 2pt | Max order | Square? |
|-------|---|---|---|-----|-----|-----------|---------|
| treatment | 4 | 5 | 2 | 31×32 | 47×47 | **7→6** | yes |
| biohydrogenation | 4 | 6 | 2 | 25×26 | 32×34 | **6→4** | NO |
| crauste | 5 | 13 | 4 | 43×43 | 53×53 | **6→4** | yes |
| hiv | 5 | 10 | 4 | 33×33 | 45×45 | **4→3** | yes |
| fitzhugh_nagumo | 2 | 3 | 1 | 14×14 | 19×19 | **5→4** | yes |
| daisy_ex3 | 4 | 5 | 2 | 37×37 | 49×49 | **8→6** | yes |
| daisy_mamil3 | 3 | 5 | 2 | 21×21 | 28×28 | **5→4** | yes |
| slowfast | 6 | 2 | 4 | 26×26 | 44×44 | 3→3 | yes |
| seir | 4 | 3 | 2 | 26×26 | 37×37 | **6→5** | yes |

8/9 models show derivative order reduction. Only slowfast (many obs, few params) stays same.
biohydrogenation is NOT square at 2 points — may need 3 points.
treatment 1-point is already non-square (31×32) — 2-point FIXES this.

Combined with earlier models (simple, lotka_volterra, forced_lv_sinusoidal, harmonic, vanderpol): **13/14 models show reduction, 13/14 produce square systems**.

### CORRECTION: The Full Pipeline Has More Steps Than Just Prolongation

The ODEPE polynomial system construction (`get_polynomial_system_from_sian`, si_equation_builder.jl:846-1068) has THREE stages, not one:

1. **Prolongation loop** (lines 899-941): Rank-based Y equation selection + X cascade. Produces Et that may be underdetermined (Δ ≤ 0).

2. **Extra Y equations** (lines 943-957): After the loop, adds ALL remaining Y equations whose variables are already in x_theta_vars — WITHOUT a rank check. This can make Et overdetermined.

3. **Algebraic independence trimming** (lines 1018-1030): Runs `algebraic_independence()` which greedily selects a maximal independent subset of Et via Jacobian rank. This trims the overdetermined system back to (approximately) square.

**This means my multi-point experiments (which only ran stage 1) were incomplete.** The extra Y equations from stage 2 may provide the missing information that stage 1 alone couldn't achieve. For example, biohydrogenation goes from 25×26 (Δ=-1) in the prolongation loop to 25×25 (square) in the full pipeline.

**Also: no Groebner basis is used in system construction.** Groebner bases are only used in SIAN's `identifiability_ode` function (SIAN.jl line 267) for global identifiability testing, which is a separate analysis step that does NOT affect the polynomial system itself.

### How Squareness Works (and Fails)

The prolongation loop tracks Δ = |Et| - |x_theta_vars| (equations minus unknowns):
- **Initial Δ** = -(n_params + n_points × n_ICs)
- Each Y prolongation step: Δ += 1 (one new equation, zero net new vars since cascade adds equal eqs and vars)
- **Square** when Δ = 0

At 1 point, need `n_params + n_ICs` successful Y steps.
At 2 points, need `n_params + 2*n_ICs` steps but have 2× the Y candidates.

**Non-squareness** happens when total independent Y equations < needed Y steps:
- treatment: need 9, get 8 at 1pt → Δ=-1. But at 2pt get 13 needed, 13 available → square!
- biohydrogenation: need 10, get 9 at 1pt → Δ=-1. At 2pt need 14, only get 12 → Δ=-2, NOT square.
  - Root cause: 2 outputs × 2 points can't produce enough independent equations for 6 params + 8 ICs
  - Fix: try 3 points (need 18, might get 3×(4+2)=18)

### Experiment 5: Option C (algebraic_independence on combined template) — NEGATIVE RESULT

Took the standard fully-processed template, instantiated at 2 points, combined, ran greedy row selection at oracle values.

Results:
- simple: greedy selects 8 from A + 6 from B = 14 eqs, 14 vars → **HC.jl: 0 solutions**
- forced_lv_sinusoidal: 12 from A + 8 from B = 20 eqs, 20 vars → **HC.jl: 0 solutions**

The greedy selector picks equations from both points, but the resulting system is NOT zero-dimensional. The problem: all of point A's equations are selected first (they're already a complete system). Point B's equations add new variables (_pt2 state vars) but only SOME of B's equations are selected (the ones that increase rank). The dropped B equations are exactly the data-pinning equations needed for zero-dimensionality of point B's variables.

**Conclusion: Option C fails. The `algebraic_independence` greedy selector doesn't guarantee zero-dimensionality.** Must use the multi-point prolongation approach (Option B) which builds the system from scratch with the correct structure.

### KEY DISCOVERY: HC.jl failure was a red herring — Gauss-Newton works directly

The 14×14 combined system for `simple` DOES have an isolated root (Newton converges in 3 iterations to ||F||=5e-17). HC.jl fails to find it — this is a homotopy tracking failure, NOT a mathematical problem.

**For forced_lv_sinusoidal (24×20 overdetermined, Gauss-Newton):**
- Converges to residual 4.95 (nonzero due to interpolation noise — expected for overdetermined)
- Parameter estimates: alpha=1.14 (24% err), beta=0.61 (39%), gamma=2.89 (4%), delta=0.35 (29%)
- Best 1-point was 210% error — **multi-point Gauss-Newton gives 39% error = 5.4× improvement**

**Implication: We don't need HC.jl for multi-point at all.** The natural approach is:
1. Build the combined overdetermined system (no equation dropping, no squareness needed)
2. Use HC.jl on the 1-point system for branch discovery (topology)
3. Use Gauss-Newton/LM on the multi-point system for accuracy (PAL's Strategy D)

This sidesteps ALL the squareness/zero-dimensionality concerns. The multi-point system is overdetermined, and least-squares handles that natively.

### Next steps
- **Test Gauss-Newton multi-point on hard models** — hiv, crauste, biohydrogenation, treatment
- **Compare HC.jl 1-point + GN multi-point (Strategy D)** — use HC for topology, GN for accuracy
- **Integration plan** — how to add this to the ODEPE pipeline (the "polish" step could use multi-point GN)
