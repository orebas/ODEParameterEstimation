# Analysis: Marsh et al. 2022 — "Algebra, Geometry and Topology of ERK Kinetics"

**Paper**: Marsh, Dufresne, Byrne, Harrington. *Bull. Math. Biol.* 84(12), 2022.
**Based on**: Yeung et al. *Current Biology* 30(6), 2020.
**arXiv**: [2112.00688](https://arxiv.org/abs/2112.00688)
**PMC**: [PMC9588486](https://pmc.ncbi.nlm.nih.gov/articles/PMC9588486/)
**Yeung PMC**: [PMC7085240](https://pmc.ncbi.nlm.nih.gov/articles/PMC7085240/)

---

## 1. The Model — Same as Ours

Full ERK model (Eqs 1a-1f):
```
dS0/dt = -kf1·E·S0 + kr1·C1
dC1/dt =  kf1·E·S0 - (kr1+kc1)·C1
dC2/dt =  kc1·C1 - (kr2+kc2)·C2 + kf2·E·S1
dS1/dt = -kf2·E·S1 + kr2·C2
dS2/dt =  kc2·C2
dE/dt  = -kf1·E·S0 + kr1·C1 - kf2·E·S1 + (kr2+kc2)·C2
```

Conservation laws:
- Stot = S0 + S1 + S2 + C1 + C2 = 5.0 μM
- Etot = E + C1 + C2 = 0.65 μM (paper uses 0.67, minor difference)

Initial conditions: S0(0)=Stot=5, E(0)=Etot=0.65, all others=0.

**EXACTLY our model.**

---

## 2. Key Result: Full Model NOT Practically Identifiable

The paper's central finding on parameter estimation:

> "The Full and Rational ERK models are **not practically identifiable** — confidence
> regions are unbounded in parameter space."

SIAN confirms the model is **generically structurally identifiable** — meaning at generic
parameter values, there are finitely many solutions. We confirmed this: exactly **2 solutions**
(true + kc1↔kc2 mirror).

**But structural ≠ practical identifiability.** Structural says "finitely many solutions exist."
Practical says "can you actually FIND them from noisy data." The answer for the full 6-param
model is NO — the condition number of 6.5×10^18 means any data noise > 10^{-18} corrupts
the solution.

### Consistency Check
- Paper says: "not practically identifiable" → confidence regions unbounded
- Our finding: cond(∂R/∂x) = 6.5×10^18 at t=5.71
- These are **completely consistent**. The enormous condition number IS the quantitative
  manifestation of non-practical-identifiability.

---

## 3. The Reduction: Linear ERK Model (3 Parameters)

Under quasi-steady-state approximation (QSSA) when kM >> [substrate]:

```
dS0/dt = -κ1·S0
dS1/dt = -κ2·S1 + (1-π)·κ1·S0
dS2/dt =  π·κ1·S0 + κ2·S1
```

Reduced parameters:
- **κ1 = Etot·kc1·kf1 / (kc1+kr1)** = Etot·kcat1/KM1 (first phosphorylation efficiency)
- **κ2 = Etot·kc2·kf2 / (kc2+kr2)** = Etot·kcat2/KM2 (second phosphorylation efficiency)
- **π = kc2 / (kc2+kr2)** (processivity: probability both phosphorylations in one encounter)

**This model IS structurally AND practically identifiable** (Theorem 1 in Marsh et al.).

Analytical solutions exist:
```
S0(t) = Stot·exp(-κ1·t)
S1(t) = Stot·κ1(1-π)/(κ1-κ2)·(exp(-κ2·t) - exp(-κ1·t))
S2(t) = Stot - S0(t) - S1(t)
```

---

## 4. Our Parameters vs Experimental Wild-Type

### Our benchmark parameters:
| Rate constant | Our value | Meaning |
|--------------|-----------|---------|
| kf1 | 11.5 | Forward binding, step 1 |
| kr1 | 300.0 | Reverse binding, step 1 |
| kc1 | 12.45 | Catalytic rate, step 1 |
| kf2 | 11.15 | Forward binding, step 2 |
| kr2 | 4.864 | Reverse binding, step 2 |
| kc2 | 428.13 | Catalytic rate, step 2 |

### Derived Michaelis constants:
| Constant | Our value | Paper reports |
|----------|-----------|---------------|
| KM1 = (kc1+kr1)/kf1 | 27.17 μM | ≈ 25 μM |
| KM2 = (kc2+kr2)/kf2 | 38.83 μM | ≈ 25 μM |

### Derived reduced parameters:
| Parameter | Our model | WT experimental (Yeung 2020) | Match? |
|-----------|-----------|------------------------------|--------|
| κ1 | **0.298** min⁻¹ | **0.29** min⁻¹ | ✅ YES |
| κ2 | **7.164** min⁻¹ | **0.19** min⁻¹ | ❌ NO (37× too high!) |
| π | **0.989** | **0.30** | ❌ NO (nearly processive vs 30%) |

### Analysis:
- **κ1 matches perfectly** — first phosphorylation efficiency is realistic.
- **κ2 is 37× too high** — second phosphorylation is absurdly fast in our model.
  This is because kc2=428.13 is enormous while kr2=4.864 is tiny.
- **π≈0.989** means our model is ~99% processive (almost every encounter gives dual
  phosphorylation). Real WT is only ~30% processive.

**Our benchmark parameter values represent an extremely non-physiological regime** for
the second phosphorylation step. The massive kc2/kr2 ratio (88:1) makes C2 an extremely
transient intermediate, which probably contributes to the stiffness and ill-conditioning.

### QSSA validity:
The QSSA requires KM >> S_tot. For our model:
- KM1 = 27.17 vs S0(0) = 5.0 → ratio 5.4:1 → borderline OK
- KM2 = 38.83 vs S1(peak) < 1.0 → ratio >> 1 → good

So QSSA is actually a decent approximation for our parameter values, despite them being
non-physiological.

---

## 5. Experimental Observables

**Critical difference**: The paper measures:
- y0 = S0 + C1 (substrate + enzyme-substrate complex)
- y1 = S1 + C2
- y2 = S2

NOT S0, S1, S2 directly. Under QSSA, C1 and C2 are small:
- C1 ≈ (E_tot/KM1)·S0 ≈ (0.65/27.17)·S0 ≈ 0.024·S0
- C2 ≈ (E_tot/KM2)·S1 ≈ (0.65/38.83)·S1 ≈ 0.017·S1

So y0 ≈ 1.024·S0, y1 ≈ 1.017·S1, y2 = S2. The complex corrections are ~2%.

In our model with kc2=428, C2 at its peak is about 7×10⁻⁴ μM — negligible.
So the observable distinction barely matters for our parameter regime.

---

## 6. Implications for ODEParameterEstimation.jl

### A. The ERK benchmark is a "trick question"

The full 6-parameter ERK model is **generically structurally identifiable but not practically
identifiable**. This means:
- SIAN correctly reports "identifiable" (algebraic notion)
- HC.jl correctly finds 2 solutions (structural identifiability confirmed)
- But **NO numerical method** can reliably recover the 6 individual rate constants from
  noisy observable data. The condition number of 6.5×10^18 makes this impossible.

AAAD interpolation "works" because it gives 15+ digits of accuracy — essentially providing
perfect data. This is an artifact of having perfect synthetic data; it would never work with
real experimental data (which has ~5-10% noise).

### B. What should the package do?

**Option 1: Report the reduced parameters instead**
When identifiability analysis reveals "structurally identifiable but ill-conditioned,"
reparameterize to the identifiable combinations:
- κ1 = Etot·kf1·kc1/(kc1+kr1)
- κ2 = Etot·kf2·kc2/(kc2+kr2)
- π = kc2/(kc2+kr2)

This is NOT automatic — it requires model-specific algebraic knowledge.

**Option 2: Use the Pareto fallback with κ-space objective**
Instead of solving the polynomial system for 6 params, minimize the ODE residual
in κ-space (3 params). This is a well-conditioned 3-parameter optimization problem.

**Option 3: Accept the limitation**
Document that the full ERK model is a known ill-conditioned benchmark.
Demonstrate that the algebraic solver works with perfect data (AAAD) and
report that practical identifiability is limited.

**Option 4: Add a practical identifiability check**
After SIAN reports "structurally identifiable," compute the Jacobian condition
number at representative points. If cond > threshold (e.g., 10^10), warn the user
that parameters may not be practically identifiable and suggest using the Pareto
fallback or model reduction.

### C. For the benchmark suite

The ERK model should probably be replaced or supplemented with:
1. **Linear ERK** (κ1, κ2, π) — a well-conditioned, identifiable 3-param model
2. **Full ERK with AAAD** — demonstrates that the algebraic approach works with
   sufficient data accuracy (a positive result!)
3. **Full ERK with GP** — demonstrates the practical identifiability limitation
   (a known-failure case)

---

## 7. The Bigger Picture: Structural vs Practical Identifiability

The ERK model perfectly illustrates the gap between two concepts:

| Concept | Question | Method | ERK result |
|---------|----------|--------|------------|
| **Structural identifiability** | Are there finitely many parameter sets producing the same output? | SIAN (diff algebra) | YES — exactly 2 |
| **Practical identifiability** | Can we actually estimate parameters from realistic data? | FIM / condition number | NO — cond = 6.5×10^18 |

This gap exists because:
1. The 6 rate constants combine into only 3 independent "kinetic efficiency" quantities
2. Different combinations of (kf, kr, kc) can produce identical (κ, π) values
3. The data only constrains κ and π well; the individual rates are underdetermined
4. Algebraically there's a unique solution, but the sensitivity basin is vanishingly small

**The paper's model reduction is essentially finding the maximal identifiable submodel.**

---

## 8. References

- Marsh, Dufresne, Byrne, Harrington (2022). "Algebra, Geometry and Topology of ERK
  Kinetics." *Bull. Math. Biol.* 84(12). [DOI:10.1007/s11538-022-01088-2]
- Yeung et al. (2020). "Inference of Multisite Phosphorylation Rate Constants and Their
  Modulation by Pathogenic Mutations." *Current Biology* 30(6):1098-1104.
  [DOI:10.1016/j.cub.2019.12.052]
- Hong, Ovchinnikov, Pogudin, Yap (2020). SIAN — Structural Identifiability Analyzer.
