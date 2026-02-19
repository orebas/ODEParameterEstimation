# Verdière (Hindmarsh-Rose) and Candidate New Systems
## Date: 2026-02-17

**Context**: Colleague found Verdière & Jauberthie (ECC 2020) — "Parameter estimation
procedure based on input-output integro-differential polynomials. Application to the
Hindmarsh-Rose model." Question: should we add it to our benchmark?

**Source**: `~/tmp/verdiere/verdiere_fixed.jl` (corrected script; original had a bug
misreading `d*x1^2` as `(dx1)^2`)

---

## 1. HINDMARSH-ROSE MODEL (Eq. 3 from Verdière)

```
ẋ₁ = x₂ + a·x₁² − x₁³ − x₃ + I(t)
ẋ₂ = 1 − d·x₁² − x₂
ẋ₃ = ε(b·(x₁ − c_x₁) − x₃)
```

| Property | Value |
|----------|-------|
| States | 3 (+1 constant input I) |
| Parameters | 4: a, b, d, ε |
| Outputs | 1 (x₁ = membrane potential) |
| Paper values | a=3, b=4, d=5, ε=0.12, I=3.25 |
| Nonlinearity | Cubic (x₁³), quadratic (x₁²) |
| Special feature | Hopf bifurcation at ε_c ≈ 0.126; slow-fast dynamics |
| Domain | Computational neuroscience |

### Overlap with existing systems

| Existing system | Overlap | Key difference |
|-----------------|---------|----------------|
| `fitzhugh_nagumo` | **HIGH** — same domain (neuroscience), same heritage (Hodgkin-Huxley simplification), cubic nonlinearity, excitable dynamics | HR has 3 states (bursting), FHN has 2 (spiking only) |
| `vanderpol` | MEDIUM — nonlinear oscillator, cubic/quadratic terms | VdP is limit-cycle; HR has richer bifurcation structure |
| `slowfast` | MEDIUM — timescale separation | Different dynamics (chemical cascade vs neuron) |

### Assessment

**Pros**:
- Comes from a published parameter estimation paper (citable comparison)
- Hopf bifurcation makes it a challenging/interesting test (parameter sensitivity)
- Constant input modeled as D(I)=0 — pattern we already support
- c_x₁ (equilibrium coordinate) adds identifiability subtlety

**Cons**:
- High overlap with `fitzhugh_nagumo` (same domain, similar structure)
- Does not fill any gap in our current system coverage
- Moderate complexity (4 params) — nothing we don't already test at that scale

**Verdict**: Nice to have, but not a priority addition. Would be redundant unless we
specifically want a "neuroscience pair" (FHN vs HR) to show the method handles
models of increasing complexity within a domain.

---

## 2. HIGHER-PRIORITY SYSTEMS TO ADD INSTEAD

These fill genuine gaps in the benchmark. Cross-referenced with Section 7 of
`2026-02-10_paper_model_selection.md`.

### 2a. Lorenz System (chaotic dynamics) — **HIGH PRIORITY**

```
ẋ = σ(y − x)
ẏ = x(ρ − z) − y
ż = xy − βz
```

| Property | Value |
|----------|-------|
| States | 3 |
| Parameters | 3: σ, ρ, β |
| Standard values | σ=10, ρ=28, β=8/3 |
| Outputs | 1-2 (e.g., x only) |
| Gap filled | **Chaotic dynamics** — no current system has sensitive dependence on ICs |

- Iconic system; every reviewer knows it
- Chaotic sensitivity makes parameter estimation qualitatively different from
  everything else in the benchmark
- Tests whether algebraic method degrades gracefully in chaotic regime
- Polynomial (quadratic) so compatible with our homotopy continuation framework
- Note: may need careful time interval selection (short windows where trajectories
  haven't diverged)

### 2b. Goodwin Oscillator (rational/Hill nonlinearity) — **HIGH PRIORITY**

```
ẋ₁ = α/(K^n + x₃^n) − β·x₁
ẋ₂ = k₁·x₁ − k₂·x₂
ẋ₃ = k₃·x₂ − k₄·x₃
```

| Property | Value |
|----------|-------|
| States | 3 |
| Parameters | 5-7 (α, β, k₁-k₄, K, n) |
| Outputs | 1-2 |
| Gap filled | **Hill function / rational nonlinearity** in a minimal system |

- Circadian rhythm model — biologically important
- Hill function K^n/(K^n + x^n) is the dominant nonlinearity in gene regulation
- Repressilator already has Hill functions but is large (6 states); Goodwin is
  the minimal version (3 states)
- Needs polynomialization for our framework (multiply through by denominator)
- Well-studied identifiability properties

### 2c. Robertson Chemical Kinetics (extreme stiffness) — **MEDIUM PRIORITY**

```
ẏ₁ = −k₁·y₁ + k₃·y₂·y₃
ẏ₂ = k₁·y₁ − k₂·y₂² − k₃·y₂·y₃
ẏ₃ = k₂·y₂²
```

| Property | Value |
|----------|-------|
| States | 3 |
| Parameters | 3: k₁=0.04, k₂=3e7, k₃=1e4 |
| Outputs | 2-3 |
| Gap filled | **Extreme stiffness** (rate constants span 9 orders of magnitude) |

- THE classic stiff ODE test problem
- Parameters at vastly different scales stress-tests both solvers and estimators
- Polynomial (quadratic), so compatible with our framework
- Conservation law: y₁ + y₂ + y₃ = 1
- Challenge: parameter magnitudes span [0.04, 3e7] — our uniform [0.1, 0.9]
  sampling won't work; needs custom parameter ranges

### 2d. Simple Michaelis-Menten (enzyme kinetics) — **MEDIUM PRIORITY**

```
ẋ₁ = −Vmax·x₁/(Km + x₁)    (substrate)
ẋ₂ = Vmax·x₁/(Km + x₁)     (product)
```

| Property | Value |
|----------|-------|
| States | 2 |
| Parameters | 2: Vmax, Km |
| Outputs | 1 (substrate or product) |
| Gap filled | Simplest rational nonlinearity; pharma/biochem fundamental |

- Simpler than biohydrogenation (which has MM kinetics inside a 4-state cascade)
- Could serve as a "baseline rational system" before the harder biohydrogenation
- Extremely well-known — every biochemistry student learns this
- Needs polynomialization: multiply by (Km + x₁)
- Note: biohydrogenation already partially covers this gap; this might be too simple

---

## 3. RECOMMENDATION SUMMARY

| System | Priority | Gap filled | Action |
|--------|----------|------------|--------|
| Lorenz | **HIGH** | Chaotic dynamics | Add to examples |
| Goodwin oscillator | **HIGH** | Minimal Hill/rational model | Add to examples |
| Robertson | MEDIUM | Extreme stiffness | Add if parameter scaling can be handled |
| Hindmarsh-Rose | LOW | (Overlap with FHN) | Add only if expanding neuroscience coverage |
| Michaelis-Menten | LOW | (Overlap with biohydrogenation) | Add only as pedagogical baseline |

If adding only **one** new system: **Lorenz** (fills the biggest gap — chaotic dynamics —
and every reviewer will recognize it).

If adding **two**: Lorenz + Goodwin oscillator.

If adding **three or more**: Lorenz + Goodwin + Robertson, then consider HR.

---

## 4. NOTES ON VERDIÈRE SCRIPT

The original `~/tmp/verdiere/verdiere.jl` had a bug: equation 2 was written as
`D(x2) ~ 1 - (ẋ₁)² - x2` instead of `D(x2) ~ 1 - d*x1^2 - x2`. The author
misread the parameter `d` multiplying `x₁²` as the derivative `dx₁` squared.
Fixed version: `~/tmp/verdiere/verdiere_fixed.jl`.

Also note: c_x₁ in equation 3 is not a free parameter — it's the x₁-coordinate of
the leftmost equilibrium of the 2D subsystem when I=0, x₃=0. For a=3, d=5:
c_x₁ = (-1-√5)/2 ≈ -1.618. The script was also missing an `OrderedCollections`
import and had an undefined `solver` variable (fixed to `Tsit5()`).
