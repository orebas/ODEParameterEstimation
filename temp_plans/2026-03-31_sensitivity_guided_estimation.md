# Sensitivity-Guided Parameter Estimation: Research Notes

**Date**: 2026-03-31
**Model**: daisy_mamil3 instance 7 (noise 1e-4) from bilby benchmark
**Context**: Following deep dive into IFT validation and Jacobian geometry

## The Problem We're Trying to Solve

The current pipeline produces hundreds of HC solutions across (interpolator × shooting_point × SP/MP) combinations. These are clustered, polished, and ranked by ODE error. But we have no principled way to:

1. **Predict which solutions are reliable** before the expensive polish step
2. **Understand why some parameters are wrong** when they are
3. **Combine information** from different solutions or shooting points
4. **Report meaningful confidence** (GP-UQ doesn't depend on actual data)

## What We Learned from daisy_mamil3

### The Setup

- 3 states: x1 (observed via y1=0.5·x1), x2 (observed via y2=x2), x3 (**latent**)
- 5 parameters: a12, a13, a21, a31, a01
- The ODE couples x3 to x1 via: dx3/dt = (-0.999·a13·x3 + 0.667·a31·x1) / 1.5
- SIAN produces a 21×21 polynomial system at each shooting point (SP)

### The SVD of Jx at the True Solution (SP, t=0.76)

```
Singular values of Jx (21×21):
  σ₁  = 3.96    (strongest direction)
  σ₂  = 3.80
  ...
  σ₁₉ = 0.012
  σ₂₀ = 0.0034
  σ₂₁ = 7.5e-4  (weakest, but still OK)

κ(Jx) = 5,280 — well-conditioned!
```

The SP system is fine — all 21 singular values are bounded away from zero. IFT works perfectly: nonlinearity = 0.049.

### The SVD of Jx at the True Solution (MP, 2-point, t=[4.99, 15.0])

```
Singular values of Jx (22×22):
  σ₁  = 3.96
  σ₂  = 3.80
  ...
  σ₂₀ = 0.0034
  σ₂₁ = 7.5e-4
  σ₂₂ = 2.6e-10  ← near-null!

κ(Jx) = 1.53e10 — terrible!
```

The MP system has one singular value that collapsed to ~0. This is the direction:

```
v₂₂ = -0.952·a31 - 0.260·a13 - 0.147·a01 - 0.063·x3₀ - 0.017·x3₀_pt2
```

**In words**: the MP polynomial system cannot distinguish solutions that move along the combination `0.95·a31 + 0.26·a13 + 0.15·a01 + 0.06·x3`. At the linearization point, infinitely many solutions look equally valid along this line.

### Why This Happens

The equations contain bilinear terms like `a13·x3` and `a31·x1`. The Jacobian column for a13 is proportional to x3 (because ∂(a13·x3)/∂a13 = x3). When x3 is small (0.15 at truth), this column is small, making it nearly parallel to other columns.

At the HC solution, x3 is larger (0.22) and a13 is larger (1.19), so the bilinear terms are better balanced and the near-null direction opens up.

### The Key Observation

The HC solver finds a solution where a31=2.77 (true: 0.84), a13=1.19 (true: 0.70), a01=0.95 (true: 0.79). These are **wrong** — but the ODE trajectory with these wrong parameters happens to fit the data well because the a31/a13/a01/x3 combination compensates.

**This is practical non-identifiability at a single time point** — even though the model is structurally identifiable (SIAN confirms this).

## Concrete Approaches

### Approach 1: Sensitivity-Based Confidence Score

**What**: For each parameter in each HC solution, compute a "reliability score" based on how much the IFT predicts that parameter would shift under data perturbation.

**Concretely for daisy_mamil3 at one shooting point**:

For the HC solution at t=0.76 (SP system, 21×21):

| Parameter | ‖S[i,:]‖ (row norm) | |S[i,:]·Δd| (predicted shift) | Actual Δx | Classification |
|-----------|---------------------|-------------------------------|-----------|----------------|
| a12 | 1,090 | 0.080 | 0.080 | Tight — small predicted shift, IFT accurate |
| a21 | 920 | 0.070 | 0.070 | Tight |
| a01 | 860 | 0.058 | 0.058 | Moderate — S row is large but Δd is small |
| a13 | 810 | 0.049 | 0.049 | Moderate |
| a31 | 720 | 0.010 | 0.010 | Moderate |

In the SP system, ALL parameters are "tight" (predicted shift < 10% of true value). The sensitivity rows are moderate (100-1000) but Δd is small enough that the products stay manageable.

For the MP system at t=[4.99, 15.0] (22×22):

| Parameter | ‖S[i,:]‖ (row norm) | |S[i,:]·Δd| (predicted shift) | Actual Δx | Classification |
|-----------|---------------------|-------------------------------|-----------|----------------|
| a12 | 0.5 | 3.5e-4 | 3.5e-4 | Tight |
| a21 | 0.6 | 4.1e-4 | 4.1e-4 | Tight |
| a31 | 3.6e9 | 2.1e4 | 1.93 | **LOOSE** — S predicts catastrophe |
| a13 | 9.7e8 | 5.9e3 | 0.49 | **LOOSE** |
| a01 | 5.5e8 | 3.3e3 | 0.16 | **LOOSE** |

**The reliability score is**: "for this solution at this point, a12 and a21 are trustworthy (predicted shift 3-4e-4), but a31/a13/a01 are unreliable (predicted shift >> actual, IFT breaks down)."

**What this buys us**: Before polishing, we know which parameters to trust and which to be skeptical about. The polish optimizer could use tighter bounds for tight parameters and wider bounds for loose ones.

### Approach 2: Cross-Point Stacking

**What**: Instead of using Jx at a single shooting point, stack Jacobians from multiple shooting points into a combined system.

**Why this could help**: The near-null direction for x3-coupled parameters might disappear when we combine information from multiple time points — because x3 has different values at different times, the bilinear terms `a13·x3(t)` contribute different column patterns.

**Concretely**: At t=0.76, x3≈0.15 (small, causing near-null). At t=5.0, x3≈0.076. At t=15.0, x3≈0.014. Actually, x3 is *decreasing* — it's always small in this model.

This means **stacking doesn't help for daisy_mamil3** because x3 is small everywhere. The near-null direction is a property of the parameter-state coupling geometry, not a bad choice of time point.

For other models (like crauste where P(t) varies from 0.78 to near-0 to recovery), stacking across points where the latent state takes different magnitudes WOULD help.

**Lesson**: Cross-point stacking helps when the latent state's value varies significantly across the time interval. It doesn't help when the latent state is uniformly small.

### Approach 3: Soft-Constrained Hybrid Polish

**What**: The current polish step optimizes ALL parameters equally against the ODE trajectory. Instead, use the sensitivity analysis to set per-parameter constraints:

```julia
# Current polish: all parameters have same bounds
lb = 1e-5 * ones(n_params)
ub = 10.0 * ones(n_params)

# Proposed: sensitivity-informed bounds
for i in 1:n_params
    if is_tight(i)
        # Trust the algebraic solution — tight bounds around HC estimate
        lb[i] = max(1e-5, x_hc[i] * 0.9)
        ub[i] = x_hc[i] * 1.1
    else
        # Don't trust the algebraic solution — wide bounds
        lb[i] = 1e-5
        ub[i] = 10.0
    end
end
```

**For daisy_mamil3 (SP solution at t=0.76, noise 1e-4)**:

All parameters are tight in SP. The polish with uniform bounds takes 1200s and achieves 11% max error.

With sensitivity-informed bounds:
- a12: HC=0.440 → bounds [0.396, 0.484] (tight, ±10%)
- a21: HC=0.297 → bounds [0.267, 0.327]
- a31: HC=0.829 → bounds [0.746, 0.912]
- a13: HC=0.651 → bounds [0.586, 0.716]
- a01: HC=0.848 → bounds [0.763, 0.933]

The optimizer has a much smaller search space, so polish should converge faster and avoid wandering into parameter regions where the ODE is stiff or blows up.

**For the MP solution**: a31/a13/a01 would get WIDE bounds because they're loose, while a12/a21 would be tight. The optimizer would essentially be doing profile-likelihood optimization over the loose parameters.

### Approach 4: Consensus Voting

**What**: Across all N solutions (from different interpolators/points), compute the empirical spread of each parameter.

**For daisy_mamil3** (hypothetical with 50 HC solutions):

| Parameter | Median | IQR | CV | Matches sensitivity classification? |
|-----------|--------|-----|----|------------------------------------|
| a12 | 0.518 | [0.515, 0.521] | 0.6% | Yes — tight |
| a21 | 0.365 | [0.363, 0.368] | 0.7% | Yes — tight |
| a31 | 0.85 | [0.10, 2.80] | 140% | Yes — **loose** |
| a13 | 0.72 | [0.50, 1.40] | 65% | Yes — loose |
| a01 | 0.80 | [0.60, 1.20] | 35% | Yes — moderate |

**What this buys**: Empirical validation of the sensitivity classification. If the cross-solution spread is small, the parameter is practically identifiable at this noise level. If spread is large, it's practically non-identifiable.

**The insight**: We don't need GP-UQ at all. The cross-solution spread IS the uncertainty quantification. The sensitivity matrix tells us WHY the spread exists (which data errors drive it), and the SVD tells us which parameters are coupled in the spread.

### Approach 5: Variable Projection for the Loose Block

**What**: A two-level optimization where the tight parameters are determined algebraically (inner problem) and the loose parameters are optimized against the trajectory (outer problem).

**Sketch for daisy_mamil3**:

```
Outer optimization over loose params θ_loose = (a31, a13, a01):
    For each candidate θ_loose:
        1. Substitute into the polynomial system F(x, d; θ_loose) = 0
        2. Solve the REDUCED system for tight params + state derivatives
           (this is now a 18×18 system with better conditioning)
        3. Run forward ODE with (θ_tight, θ_loose)
        4. Return trajectory error as the objective
    Minimize trajectory error over θ_loose
```

This separates the "algebraically easy" part (tight parameters) from the "optimization-hard" part (loose parameters). The inner algebraic solve is fast (just HC on a smaller, better-conditioned system). The outer optimization only searches in 3D instead of 8D.

**This is "variable projection" (Golub & Pereyra, 1973)** — a well-studied technique for separable nonlinear least squares problems.

**Challenge**: Requires symbolic manipulation to substitute and reduce the polynomial system, which is nontrivial with our SIAN template.

## Summary: What I'd Try First

1. **Compute cross-solution spread** (trivially implementable — just statistics on the existing solution pool). This IS the UQ, no GP needed.

2. **Use sensitivity classification to set polish bounds** (modify `_build_polish_context` to accept per-parameter bounds from the SVD analysis). This should improve polish convergence for models with loose parameters.

3. **Report per-parameter practical reliability** in the diagnostic HTML: "a12: practically identifiable (CV=0.6% across 50 solutions)" vs "a31: practically non-identifiable at noise=1e-4 (CV=140%)".

These three require no new algorithms — just using existing information more intelligently.
