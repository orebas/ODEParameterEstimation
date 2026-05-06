# Cross-Solution Spread Design: Separating Branches from Uncertainty

**Date**: 2026-04-01

## The Problem

The cross-solution spread CV mixes three distinct phenomena:

### Source 1: Algebraic Branches (NOT uncertainty)
The SIAN polynomial system can have multiple structurally distinct roots.
- Example: `x' = a² * x` has roots a = +√k and a = -√k
- Example: Lotka-Volterra has k1↔k2 parameter symmetries
- These exist with perfect data, are exact, and are a property of the model, not the estimation
- We KNOW about these — SIAN/HC.jl finds all branches deliberately
- **Should NOT contribute to CV**

### Source 2: Interpolation/Shooting Variation (IS uncertainty)
The same algebraic branch, evaluated at different (interpolator, shooting_point) combos, gives slightly different values because derivative estimation has small errors.
- This is the signal we actually want
- Small variation → parameter is practically identifiable
- Large variation → practically non-identifiable at this noise level
- **SHOULD be the CV**

### Source 3: Garbage Solutions (NOT uncertainty)
HC.jl sometimes returns solutions far from physical reality.
- Negative concentrations, parameters of 10⁶, etc.
- These often have large ODE trajectory error and get filtered during analysis
- But some survive if the ODE happens to not blow up
- **Should NOT contribute to CV**

## Current Behavior

`compute_cross_solution_spread` takes all solutions that passed `analyze_estimation_result` (oracle-sorted, best-per-cluster). This already does some deduplication (0.001% clustering threshold) but the clusters are formed by solution distance, not by branch identity.

Result: lotka_volterra with 280 solutions shows k2 CV = 9170% — mixing the true branch with mirror branches.

## Why This Is Hard

### You can't use truth to separate branches in production
In production, we don't know the true parameters. We can't say "keep only solutions near truth." We need an automated criterion.

### ODE trajectory error doesn't always help
A perfect mirror branch (a vs -a) produces identical ODE trajectories. The error is 0 for both. You can't filter by trajectory error.

### Clustering threshold is fragile
- Too tight (0.1%): each solution is its own cluster, no spread to measure
- Too loose (50%): branches merge, spread includes structural ambiguity
- The right threshold depends on the model and noise level

## Possible Approaches

### Approach A: Two-level clustering
1. **Coarse clustering** (e.g., 10% relative distance) to identify algebraic branches
2. **Within-cluster spread** to measure practical identifiability
3. Report: "N branches found. Within the best branch (N_best solutions): CV = X%"

**Problem**: what's the right coarse threshold? And "best branch" requires a quality metric.

### Approach B: Quality-gated spread
Only include solutions with ODE trajectory error below a threshold (e.g., 2× best error).
- Filters garbage (Source 3) automatically
- May filter wrong branches IF they have worse ODE fit
- Doesn't help for perfect mirror branches (same ODE error)

**Problem**: the threshold is arbitrary. And mirror branches survive.

### Approach C: Report both metrics separately
1. **N_distinct**: Number of distinct solution clusters (branch count)
   - 1 cluster → structurally unique solution
   - 2+ clusters → algebraic ambiguity (symmetries, mirror roots)
2. **Within-best-cluster CV**: Spread within the cluster closest to the best solution
   - This measures Source 2 only (interpolation variation)
   - Excludes Sources 1 and 3

**This might be the cleanest approach.** It separately reports structural ambiguity (how many branches) and practical identifiability (how tight is the best branch).

### Approach D: Polish-aware spread
The pipeline clusters before polishing (0.1% threshold), then polishes cluster representatives. After polishing, representatives that converge to the same point are the same branch; those that stay distinct are different branches.

We could compute spread as: within each post-polish cluster, how spread were the pre-polish members?

**Problem**: we don't currently track which pre-polish candidates belong to which post-polish cluster.

### Approach E: Just filter by error quality
Simplest approach: only include solutions with `err < threshold` in the spread.
- `threshold = 10 * best_err` or `threshold = 0.01` (absolute)
- This won't catch mirror branches but will catch garbage
- Better than nothing, easy to implement

## What I'd Recommend

**Approach C (two-level reporting)** is the most honest:

```
Practical Identifiability:
  Branch analysis: 2 distinct solution clusters found
    Cluster 1 (best): 45 solutions, best error = 0.0001
    Cluster 2: 12 solutions, best error = 0.0001 (mirror branch)

  Within-best-cluster spread (45 solutions):
    a12:  tight  (CV=0.3%)
    a21:  tight  (CV=0.3%)
    a31:  loose  (CV=140%)
    ...
```

This tells the user:
- "There are 2 algebraic branches" (structural ambiguity — not fixable by more data)
- "Within the best branch, a12/a21 are tight but a31 is loose" (practical identifiability — could improve with more/better data)

The coarse clustering threshold can be generous (e.g., 20% relative distance) because we're just trying to separate obviously different branches, not distinguish interpolation noise.

## Open Questions

1. What coarse clustering distance works across models? Maybe normalize by parameter scale?
2. Should we use ODE error to identify the "best" cluster, or just pick the cluster containing the oracle-best solution?
3. For the SEIR model where everything is loose — is that genuine non-identifiability or branch contamination?
4. Should the HTML report show all branches or just the best one's spread?
