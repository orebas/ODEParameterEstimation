# Model Selection for IEEE TAC Paper — ODEParameterEstimation.jl
## Date: 2026-02-10

**Paper context**: Comparing ODEParameterEstimation.jl (structural identifiability + homotopy continuation) against AMIGO2, SciML, and other optimization-based estimators.

**Key methodological advantages to demonstrate**:
- Finds ALL solutions, not just one local optimum
- Integrated structural identifiability analysis
- Provably correct for polynomial systems
- Works on nontrivially forced systems (sinusoidal inputs)

---

## 1. COMPLETE MODEL INVENTORY

### 1.1 Simple / Pedagogical Models

| Model | States | Params | Obs | Dynamics | Observability | Status |
|-------|--------|--------|-----|----------|---------------|--------|
| `onevar_exp` | 1 | 1 | 1 | Linear decay | Full | SUCCESS |
| `simple` | 2 | 2 | 2 | Linear coupled | Full | SUCCESS |
| `simple_linear_combination` | 2 | 2 | 2 | Linear coupled | Linear combo obs | untested |
| `onesp_cubed` | 1 | 1 | 1 | Linear decay | Cubic obs (y=x^3) | untested |
| `threesp_cubed` | 3 | 3 | 3 | Linear coupled | Cubic obs (all y=x^3) | untested |
| `harmonic` | 2 | 2 | 2 | Harmonic oscillator | Full | SUCCESS |

### 1.2 Classical Dynamical Systems

| Model | States | Params | Obs | Dynamics | Observability | Status |
|-------|--------|--------|-----|----------|---------------|--------|
| `lotka_volterra` | 2 | 3 | 1 | Bilinear predator-prey | Partial (prey only) | SUCCESS* |
| `lv_periodic` | 2 | 4 | 2 | Standard LV | Full | SUCCESS |
| `vanderpol` | 2 | 2 | 2 | Cubic nonlinearity, limit cycle | Full | SUCCESS |
| `brusselator` | 2 | 2 | 2 | Quadratic autocatalysis | Full | SUCCESS |
| `fitzhugh_nagumo` | 2 | 3 | 1 | Cubic + recovery | Partial (voltage only) | SUCCESS* |
| `allee_competition` | 2 | 8 | 2 | Allee + competition | Full | HARD |

### 1.3 Biological / Epidemiological Systems

| Model | States | Params | Obs | Dynamics | Observability | Status |
|-------|--------|--------|-----|----------|---------------|--------|
| `seir` | 4 | 3 | 2 | Mass-action epidem. | Partial + conservation | SUCCESS |
| `treatment` | 4 | 5 | 2 | SEIR + intervention | Partial + conservation | SUCCESS |
| `biohydrogenation` | 4 | 6 | 2 | Michaelis-Menten cascade | Partial (2/4 states) | SUCCESS |
| `repressilator` | 6 | 3 | 3 | Hill-type cyclic inhibition | Partial (proteins only) | SUCCESS |
| `hiv` | 5 | 10 | 4 | Complex immune dynamics | Composite obs (y+v) | SUCCESS |
| `crauste_corrected` | 5 | 13 | 4 | Microbial ecosystem | Composite obs (s+m) | SUCCESS |
| `sirsforced` | 5 | 6 | 2 | SIRS + periodic forcing | Partial (I,R only) | SUCCESS |
| `slowfast` | 6 | 2 | 4 | Chemical cascade, stiff | Nonlinear combo obs | SUCCESS |

### 1.4 Pharmacokinetics / Compartmental

| Model | States | Params | Obs | Dynamics | Observability | Status |
|-------|--------|--------|-----|----------|---------------|--------|
| `daisy_ex3` | 4 | 5 | 2 | Linear + ramp input | State + input obs | untested |
| `daisy_mamil3` | 3 | 5 | 2 | 3-compartment mammillary | Partial (2/3) | SUCCESS* |
| `daisy_mamil4` | 4 | 7 | 3 | 4-compartment mammillary | Composite obs (x3+x4) | SUCCESS |
| `two_compartment_pk` | 2 | 5 | 1 | Central/peripheral PK | Partial (central only) | untested |

### 1.5 Control Systems (originals — many have transcendental terms)

| Model | States | Params | Obs | Dynamics | Observability | Has sin/cos/exp | Status |
|-------|--------|--------|-----|----------|---------------|-----------------|--------|
| `dc_motor` | 2 | 7 | 1 | Electromechanical | Partial | No (const V) | untested |
| `mass_spring_damper` | 2 | 4 | 1 | 2nd-order mechanical | Partial | No | untested |
| `cart_pole` | 4 | 5 | 2 | Underactuated, nonlinear | Partial | Yes (sin/cos) | **FAILS** |
| `tank_level` | 1 | 3 | 1 | sqrt outflow | Full | Yes (sqrt) | untested |
| `cstr` | 2 | 8 | 1 | Arrhenius kinetics | Partial | Yes (exp) | **FAILS** |
| `quadrotor_altitude` | 2 | 4 | 1 | 1D altitude | Partial | No | SUCCESS |
| `thermal_system` | 1 | 4 | 1 | Lumped thermal | Full | No | SUCCESS |
| `ball_beam` | 4 | 5 | 2 | Underactuated | Partial | Yes (sin/cos) | **FAILS** |
| `bicycle_model` | 2 | 8 | 2 | Vehicle lateral | Full | No (const delta) | untested |
| `swing_equation` | 2 | 5 | 1 | Power-angle | Partial | Yes (sin) | **FAILS** |
| `magnetic_levitation` | 3 | 6 | 1 | Nonlinear 1/z^2 | Partial | No | **FAILS** |
| `aircraft_pitch` | 3 | 6 | 1 | Aerospace stability | Partial (q only) | No | SUCCESS |
| `two_tank` | 2 | 6 | 2 | Coupled sqrt outflow | Full | Yes (sqrt) | **FAILS** |
| `boost_converter` | 2 | 5 | 1 | DC-DC power elec. | Partial | No | **FAILS** |
| `flexible_arm` | 4 | 6 | 2 | 2-DOF vibration | Partial | No | SUCCESS |
| `bilinear_system` | 2 | 9 | 1 | Generic bilinear | Partial | No | SUCCESS* |
| `forced_lotka_volterra` | 2 | 5 | 1 | LV + stocking | Partial | No | SUCCESS |

### 1.6 Control Systems — Sinusoidal Input Variants (auto-transcendental)

| Model | States | Params | Obs | Forcing | Status |
|-------|--------|--------|-----|---------|--------|
| `dc_motor_sinusoidal` | 2 | 3 | 1 | V=12+2sin(5t) | SUCCESS |
| `quadrotor_sinusoidal` | 2 | 2 | 1 | T=2sin(t) | SUCCESS |
| `forced_lv_sinusoidal` | 2 | 4 | 2 | -0.3sin(2t) harvesting | SUCCESS |
| `magnetic_levitation_sinusoidal` | 3 | 3 | 1 | V=5+sin(5t) | SUCCESS |
| `aircraft_pitch_sinusoidal` | 3 | 4 | 1 | delta_e=0.05sin(2t) | SUCCESS |
| `bicycle_model_sinusoidal` | 2 | 4 | 2 | delta=0.05sin(0.5t) | untested |
| `boost_converter_sinusoidal` | 2 | 3 | 2 | d=0.5+0.1sin(100t) | SUCCESS |
| `bilinear_system_sinusoidal` | 2 | 8 | 2 | u=1+0.5sin(2t) | untested |

### 1.7 Control Systems — Identifiable / Polynomialized Variants

| Model | States | Params | Obs | Transform | Status |
|-------|--------|--------|-----|-----------|--------|
| `dc_motor_identifiable` | 4 | 3 | 3 | Oscillator states for sin | SUCCESS |
| `quadrotor_altitude_identifiable` | 4 | 2 | 3 | Oscillator states | SUCCESS |
| `magnetic_levitation_identifiable` | 5 | 3 | 3 | Oscillator states | SUCCESS |
| `aircraft_pitch_identifiable` | 5 | 4 | 3 | Oscillator states | untested |
| `bicycle_model_identifiable` | 4 | 4 | 4 | Oscillator states | untested |
| `boost_converter_identifiable` | 4 | 3 | 4 | Oscillator states | SUCCESS |
| `bilinear_system_identifiable` | 4 | 8 | 4 | Oscillator states | SUCCESS |
| `forced_lotka_volterra_identifiable` | 4 | 4 | 4 | Oscillator states | untested |
| `tank_level_poly` | 3 | 2 | 3 | z=sqrt(h) transformation | SUCCESS |
| `two_tank_poly` | 5 | 5 | 4 | z=sqrt(h) transformation | SUCCESS |
| `cstr_reparametrized` | 5 | 6 | 3 | r_eff = k0*exp(-E/T) | SUCCESS |
| `cstr_fixed_activation` | 5 | 5 | 3 | E_R fixed | SUCCESS |

### 1.8 Linear Comparison Variants

| Model | States | Params | Obs | Relationship | Status |
|-------|--------|--------|-----|--------------|--------|
| `cart_pole_linear` | 4 | 5 | 2 | Linearized cart_pole | untested |
| `maglev_linear` | 3 | 5 | 1 | Linearized magnetic_levitation | untested |

### 1.9 Test / Debug Models (NOT for paper)

| Model | Purpose |
|-------|---------|
| `substr_test` | Tests substitution logic |
| `global_unident_test` | Tests unidentifiability detection (b+c inseparable) |
| `sum_test` | Tests partial observability |
| `trivial_unident` | Simplest unidentifiable system (a+b) |
| `biohydrogenation_debug` | Debug variant with different params |
| `hiv_old_wrong` | Deprecated incorrect HIV model |
| `crauste` | Original (wrong equations) |
| `crauste_revised` | Over-parametrized (16 params, 3 zero) |

---

## 2. VARIANT FAMILY ANALYSIS

For each family, **recommended variant for the paper** is marked with arrow.

### DC Motor (electromechanical)
- `dc_motor` — 2 states, 7 params, no forcing. Over-parametrized.
- `dc_motor_identifiable` — 4 states (2+oscillator), 3 params. Artificial oscillator states.
- **--> `dc_motor_sinusoidal`** — 2 states, 3 params, V=12+2sin(5t). Natural formulation, interesting forced dynamics, electrical params fixed at known values.

### Quadrotor Altitude (UAV)
- `quadrotor_altitude` — 2 states, 4 params, constant thrust. Too simple.
- `quadrotor_altitude_identifiable` — 4 states, 2 params. Artificial oscillator states.
- **--> `quadrotor_sinusoidal`** — 2 states, 2 params, oscillating thrust. Natural, minimal, modern application.

### Magnetic Levitation
- `magnetic_levitation` — 3 states, 6 params, nonlinear (1/z^2). **FAILS**. Over-parametrized.
- `magnetic_levitation_identifiable` — 5 states, 3 params. Artificial oscillator states.
- **--> `magnetic_levitation_sinusoidal`** — 3 states, 3 params. Natural notation, confirmed working.
- `maglev_linear` — 3 states, 5 params. Perturbation model, less interesting.

### Aircraft Pitch (aerospace)
- `aircraft_pitch` — 3 states, 6 params, constant elevator. Over-parametrized.
- `aircraft_pitch_identifiable` — 5 states, 4 params. Artificial oscillator states.
- **--> `aircraft_pitch_sinusoidal`** — 3 states, 4 params, oscillating elevator. Natural formulation.

### Bicycle Model (vehicle dynamics)
- `bicycle_model` — 2 states, 8 params, constant steering. Over-parametrized.
- `bicycle_model_identifiable` — 4 states, 4 params. Artificial oscillator states.
- **--> `bicycle_model_sinusoidal`** — 2 states, 4 params, sinusoidal steering. Natural formulation, autonomous vehicles.

### Boost Converter (power electronics)
- `boost_converter` — 2 states, 5 params, constant duty. **FAILS**.
- `boost_converter_identifiable` — 4 states, 3 params.
- **--> `boost_converter_sinusoidal`** — 2 states, 3 params, modulated duty cycle. Natural formulation.

### Bilinear System (generic)
- `bilinear_system` — 2 states, 9 params, constant input. Over-parametrized, generic.
- `bilinear_system_identifiable` — 4 states, 8 params.
- `bilinear_system_sinusoidal` — 2 states, 8 params.
- **--> SKIP entirely.** Generic system with no physical motivation. 8 params is large for a generic example. Not compelling for IEEE TAC.

### Forced Lotka-Volterra (ecology)
- `forced_lotka_volterra` — 2 states, 5 params, constant stocking. Similar to basic LV.
- `forced_lotka_volterra_identifiable` — 4 states, 4 params.
- **--> `forced_lv_sinusoidal`** — 2 states, 4 params, seasonal forcing. Ecologically meaningful (seasonal harvesting). Both states observed.
- Note: basic `lotka_volterra` (partial obs) is different enough to include separately.

### Cart-Pole (underactuated)
- `cart_pole` — 4 states, 5 params, sin/cos in dynamics. **FAILS**. Iconic but broken.
- `cart_pole_linear` — 4 states, 5 params. Linearized. Less interesting.
- **--> `cart_pole` if fixed.** Flag for fixing. Otherwise skip both.

### Tank Level (process control)
- `tank_level` — 1 state, 3 params, sqrt dynamics. Untested.
- **--> `tank_level_poly`** — 3 states, 2 params. Polynomialized, confirmed working. Shows sqrt-to-polynomial transformation.

### Two-Tank (multivariable process)
- `two_tank` — 2 states, 6 params, coupled sqrt. **FAILS**.
- **--> `two_tank_poly`** — 5 states, 5 params. Polynomialized, confirmed working.

### CSTR (chemical reactor)
- `cstr` — 2 states, 8 params, Arrhenius exp(). **FAILS**. Fundamental system.
- `cstr_reparametrized` — 5 states, 6 params. Encodes k0 via IC.
- **--> `cstr_fixed_activation`** — 5 states, 5 params. E_R known from chemistry, fewer params, confirmed working.
- Alternative: if the paper discusses reparametrization, include `cstr_reparametrized`.

### Crauste (microbial ecosystem)
- `crauste` — 5 states, 13 params. **Wrong equations.**
- **--> `crauste_corrected`** — 5 states, 13 params. Confirmed working.
- `crauste_revised` — 5 states, 16 params. Over-parametrized (3 params are zero).

### HIV (immunology)
- **--> `hiv`** — 5 states, 10 params. Confirmed working. The correct formulation.
- `hiv_old_wrong` — Deprecated.

### Lotka-Volterra family
- **--> `lotka_volterra`** — 2 states, 3 params, **only prey observed**. Classic partial observability challenge.
- `lv_periodic` — 2 states, 4 params, both observed. Less challenging.
- `forced_lv_sinusoidal` — 2 states, 4 params, seasonal forcing. **Also include** (different enough: forced + full obs).

---

## 3. RANKING CRITERIA

Weighted criteria for IEEE TAC paper model selection:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Recognition** | 25% | Is the model well-known in the control/systems community? Will TAC reviewers recognize it? |
| **Domain relevance** | 20% | Is the application domain important (control, bio, pharma, power)? Does it appeal to TAC audience? |
| **Mathematical diversity** | 20% | Does it add a new nonlinearity type, observation structure, or system property to the set? |
| **Challenge level** | 15% | Does it test the method's limits (many params, partial obs, nonlinear obs, multiple solutions)? |
| **Confirmed working** | 10% | Does it have confirmed SUCCESS in logs? |
| **Uniqueness** | 10% | Is it the only representative of its domain/structure, or is it redundant with others? |

---

## 4. RECOMMENDED PRIMARY SELECTION (20 models)

Organized by paper section.

### Section A: Baseline / Validation Models (3 models)
*Purpose: Establish that the method works correctly on well-understood systems*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 1 | `harmonic` | 2 | 2 | 2 | Simplest oscillator, exact analytic solution known, sanity check |
| 2 | `lotka_volterra` | 2 | 3 | 1 | Classic benchmark, partial observability (1 of 2 states), bilinear |
| 3 | `vanderpol` | 2 | 2 | 2 | Classic nonlinear oscillator, cubic dynamics, limit cycle |

### Section B: Chemical / Process Engineering (3 models)
*Purpose: Core TAC audience, nonlinear process dynamics*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 4 | `brusselator` | 2 | 2 | 2 | Chemical kinetics, quadratic autocatalysis, oscillatory |
| 5 | `cstr_fixed_activation` | 5 | 5 | 3 | Fundamental process control benchmark, Arrhenius (reparametrized), MIMO |
| 6 | `biohydrogenation` | 4 | 6 | 2 | Michaelis-Menten cascade, partial obs (2/4), enzyme kinetics |

### Section C: Mechanical / Aerospace / Vehicle Control (4 models)
*Purpose: Direct TAC audience appeal, classical and modern control applications*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 7 | `mass_spring_damper` | 2 | 4 | 1 | Canonical 2nd-order system, only displacement measured |
| 8 | `dc_motor_sinusoidal` | 2 | 3 | 1 | Fundamental electromechanical, sinusoidal voltage input |
| 9 | `flexible_arm` | 4 | 6 | 2 | Multi-DOF vibration, non-collocated sensing |
| 10 | `aircraft_pitch_sinusoidal` | 3 | 4 | 1 | Aerospace stability derivatives, sinusoidal elevator excitation |

### Section D: Modern Control Applications (3 models)
*Purpose: Trending topics — autonomous vehicles, UAVs, power electronics, smart grid*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 11 | `bicycle_model_sinusoidal` | 2 | 4 | 2 | Autonomous vehicle lateral dynamics, cornering stiffness estimation |
| 12 | `quadrotor_sinusoidal` | 2 | 2 | 1 | UAV altitude control, minimal (2 params), modern robotics |
| 13 | `boost_converter_sinusoidal` | 2 | 3 | 2 | Power electronics, fast dynamics, renewable energy |

### Section E: Biological / Epidemiological Systems (4 models)
*Purpose: Cross-disciplinary impact, complex dynamics, partial observability*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 14 | `seir` | 4 | 3 | 2 | Epidemiology benchmark, conservation law, mass-action |
| 15 | `fitzhugh_nagumo` | 2 | 3 | 1 | Neuroscience, excitable dynamics, only voltage observed |
| 16 | `repressilator` | 6 | 3 | 3 | Synthetic biology, Hill function, 6 states, cyclic topology |
| 17 | `hiv` | 5 | 10 | 4 | Largest parameter space (10), composite observation, immunology |

### Section F: Pharmacokinetics / Compartmental (2 models)
*Purpose: Important application domain, benchmark identifiability problems*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 18 | `daisy_mamil4` | 4 | 7 | 3 | DAISY benchmark, 4-compartment PK, composite obs (x3+x4) |
| 19 | `two_compartment_pk` | 2 | 5 | 1 | Standard PK model, drug distribution, single output |

### Section G: Challenging Large-Scale Systems (1 model)
*Purpose: Stress-test the method on high-dimensional problems*

| # | Model | S | P | O | Why |
|---|-------|---|---|---|-----|
| 20 | `crauste_corrected` | 5 | 13 | 4 | Largest identifiable param space (13), composite obs, microbial ecosystem |

---

## 5. EXTENDED LIST (up to 25, if space permits)

These are strong secondary choices:

| # | Model | S | P | O | Why include |
|---|-------|---|---|---|-------------|
| 21 | `forced_lv_sinusoidal` | 2 | 4 | 2 | Seasonal ecological forcing, different from basic LV |
| 22 | `treatment` | 4 | 5 | 2 | SEIR + intervention, policy-relevant, more complex than SEIR |
| 23 | `sirsforced` | 5 | 6 | 2 | Periodic epidemic forcing (seasonality), HARD model category |
| 24 | `slowfast` | 6 | 2 | 4 | Stiff timescale separation, stress-tests numerical methods |
| 25 | `magnetic_levitation_sinusoidal` | 3 | 3 | 1 | Unstable system (maglev), inherent instability challenge |

---

## 6. FIX-BEFORE-PAPER LIST

These are important models currently failing that would significantly strengthen the paper if fixed:

| Model | S | P | O | Why important | Failure notes |
|-------|---|---|---|---------------|---------------|
| `cart_pole` | 4 | 5 | 2 | **THE** iconic underactuated benchmark in controls; sin/cos in dynamics | Excluded from test runs |
| `swing_equation` | 2 | 5 | 1 | Power systems/grid stability; sin(delta) term; very TAC-relevant | Excluded from test runs |
| `cstr` | 2 | 8 | 1 | The original CSTR with Arrhenius; more natural than reparametrized | Excluded, exp(-E/T) handling |
| `magnetic_levitation` | 3 | 6 | 1 | Nonlinear maglev (1/z^2 force); inherently unstable; impressive demo | Excluded from test runs |
| `ball_beam` | 4 | 5 | 2 | Classic control lab benchmark; underactuated; sin/cos dynamics | Excluded from test runs |

**Priority**: cart_pole and swing_equation would have the most impact with TAC reviewers.

---

## 7. SUGGESTED MODELS TO ADD

Models **not currently in the repository** that would strengthen the paper:

### High priority (TAC audience):
1. **Inverted pendulum on a cart (with friction)** — If cart_pole can't be fixed, a simplified version without sin/cos (small-angle) with added friction terms would be valuable
2. **DC-DC Buck converter** — Complement the boost converter; equally important in power electronics
3. **PID-controlled plant** — Show parameter estimation of a closed-loop system (very TAC-relevant)

### Medium priority (breadth):
4. **Goodwin oscillator** — Circadian rhythm model; 3 states, Hill functions; important in systems biology
5. **Michaelis-Menten enzyme kinetics** — Simpler than biohydrogenation; 2 states, 2 params; classic
6. **Lorenz system (chaotic)** — Would demonstrate robustness on sensitive dynamics; iconic
7. **SIR model (without forcing)** — Simpler than SEIR; TAC reviewers may know it better

### Lower priority (nice-to-have):
8. **Hodgkin-Huxley** — Full neuroscience model; 4 states, many params; impressive if it works
9. **Three-tank system** — Extends two-tank; common control lab setup
10. **Heat exchanger** — Counter-current dynamics; relevant to process control

---

## 8. PROPOSED PAPER ORGANIZATION

### Table layout for numerical results

For each model, report:

| Column | Description |
|--------|-------------|
| Model name | Standard reference name |
| n_x | Number of states |
| n_p | Number of parameters (to estimate) |
| n_y | Number of measured outputs |
| Identifiability | All/partial/none (from SI analysis) |
| # Solutions (HC) | Number of real solutions found by homotopy continuation |
| HC error | Best solution error (relative L2) |
| AMIGO2 error | Comparison estimator error |
| SciML error | Comparison estimator error |
| HC time | Wall-clock time |

### Suggested figure types

1. **Bar chart**: Error comparison (HC vs AMIGO2 vs SciML) across all 20 models
2. **Scatter plot**: Problem size (states x params) vs. estimation error
3. **Box plots**: Distribution of errors across noise levels for selected models
4. **Solution landscape**: For 2-3 models, show ALL solutions found by HC vs. the single solution found by optimizers (demonstrates the "find all solutions" advantage)
5. **Identifiability table**: Show which parameters are globally/locally/non-identifiable for each model

### Narrative arc

1. **Baseline validation** (harmonic, LV, VdP): "Our method correctly solves well-understood problems"
2. **Control systems** (DC motor, CSTR, flexible arm, etc.): "Core TAC-relevant applications"
3. **Scaling** (small to large): "Performance degrades gracefully from 2-param to 13-param systems"
4. **Partial observability**: "Method handles challenging observation structures"
5. **Comparison advantage**: "HC finds all solutions; optimizers find only local optima" (use models with known multiple solutions)

---

## 9. SUMMARY STATISTICS OF RECOMMENDED SET

**Primary 20 models**:
- States range: 1-6 (median 2.5)
- Parameters range: 2-13 (median 4)
- Observations range: 1-4 (median 2)
- Domains: Control (7), Biology/Epi (4), Chemical (3), Classical (3), PK (2), Aerospace (1)
- Partial observability: 12 of 20 models
- Nonlinearity types: Linear (1), bilinear (2), polynomial/cubic (3), rational/MM/Hill (3), forced (5), general nonlinear (6)
- Confirmed SUCCESS: 16 of 20
- Untested but expected to work: 4 (mass_spring_damper, two_compartment_pk, bicycle_model_sinusoidal, one other)

**If extended to 25**: Adds forced ecology, intervention epidemiology, stiff chemistry, periodic epidemics, and unstable maglev.

---

## 10. FULL RANKING (all non-test/debug models, most to least important for paper)

| Rank | Model | Score | Rationale |
|------|-------|-------|-----------|
| 1 | `lotka_volterra` | 95 | Universally known, partial obs, bilinear, perfect baseline |
| 2 | `hiv` | 93 | Largest param space, composite obs, immunology, impressive |
| 3 | `vanderpol` | 91 | Iconic nonlinear dynamics, limit cycle, full obs benchmark |
| 4 | `cstr_fixed_activation` | 90 | Fundamental process control, Arrhenius reparametrized |
| 5 | `seir` | 89 | Epidemiology benchmark, conservation law, mass-action |
| 6 | `dc_motor_sinusoidal` | 88 | Fundamental control, forced excitation, TAC core |
| 7 | `repressilator` | 87 | Largest state space (6), synthetic biology, Hill function |
| 8 | `biohydrogenation` | 86 | Michaelis-Menten, cascade, partial obs, biochemistry |
| 9 | `fitzhugh_nagumo` | 85 | Neuroscience, excitable, partial obs, cross-disciplinary |
| 10 | `flexible_arm` | 84 | Multi-DOF vibration, non-collocated, robotics |
| 11 | `aircraft_pitch_sinusoidal` | 83 | Aerospace, stability derivatives, forced excitation |
| 12 | `brusselator` | 82 | Chemical oscillator, quadratic autocatalysis |
| 13 | `crauste_corrected` | 81 | 13 params stress test, microbial ecosystem |
| 14 | `bicycle_model_sinusoidal` | 80 | Autonomous vehicles, trending topic |
| 15 | `harmonic` | 79 | Simplest baseline, sanity check, exact solution |
| 16 | `mass_spring_damper` | 78 | Canonical mechanical, every controls student knows it |
| 17 | `quadrotor_sinusoidal` | 77 | UAV, modern robotics, minimal params |
| 18 | `daisy_mamil4` | 76 | PK benchmark, compartmental, composite obs |
| 19 | `boost_converter_sinusoidal` | 75 | Power electronics, renewable energy |
| 20 | `two_compartment_pk` | 74 | Standard PK, drug distribution |
| 21 | `forced_lv_sinusoidal` | 73 | Seasonal ecology, different from basic LV |
| 22 | `treatment` | 72 | SEIR + intervention, policy-relevant |
| 23 | `sirsforced` | 71 | Seasonal epidemics, periodic forcing |
| 24 | `slowfast` | 70 | Stiff timescales, numerical stress test |
| 25 | `magnetic_levitation_sinusoidal` | 69 | Unstable system, inherently interesting |
| 26 | `allee_competition` | 67 | Ecology, Allee effect, 8 params, HARD model |
| 27 | `lv_periodic` | 65 | Standard LV, but redundant with lotka_volterra |
| 28 | `tank_level_poly` | 63 | Process control, but very simple (1 state equiv) |
| 29 | `two_tank_poly` | 61 | Multivariable process, but large after transform (5 states) |
| 30 | `daisy_mamil3` | 59 | PK benchmark, but similar to mamil4 |
| 31 | `thermal_system` | 57 | HVAC, but trivial (1 state, linear-ish) |
| 32 | `daisy_ex3` | 55 | DAISY benchmark, but ramp input is unusual |
| 33 | `quadrotor_altitude` | 53 | Simpler quadrotor, redundant with sinusoidal |
| 34 | `dc_motor` | 51 | Over-parametrized (7 params), prefer sinusoidal |
| 35 | `simple_linear_combination` | 49 | Tests linear combo obs, but not physically motivated |
| 36 | `forced_lotka_volterra` | 47 | Redundant with sinusoidal variant |
| 37 | `onesp_cubed` | 45 | Cubic obs demo, but trivial (1 state) |
| 38 | `threesp_cubed` | 43 | Cubic obs, but artificial |
| 39 | `aircraft_pitch` | 41 | Over-parametrized (6 params), prefer sinusoidal |
| 40 | `simple` | 39 | Too simple for paper |
| 41 | `onevar_exp` | 37 | Trivial (1 state, 1 param) |
| 42 | `bicycle_model` | 35 | Over-parametrized (8 params), prefer sinusoidal |
| 43 | `magnetic_levitation` | 33 | FAILS, over-parametrized |
| 44 | `bilinear_system` | 31 | Generic, no physical motivation |
| 45 | `boost_converter` | 29 | FAILS, prefer sinusoidal |
| 46 | `cstr_reparametrized` | 27 | Redundant with fixed_activation |
| 47 | `bilinear_system_sinusoidal` | 25 | Generic, 8 params |
| 48 | `bilinear_system_identifiable` | 23 | Artificial oscillator states |

---

## 11. MODELS CURRENTLY EXCLUDED FROM RUNS (for reference)

From `run_examples.jl`, these are explicitly excluded:
```
:magnetic_levitation, :cstr, :swing_equation, :two_tank, :ball_beam,
:crauste_revised, :cart_pole, :boost_converter, :crauste
```

Of these, **cart_pole** and **swing_equation** would be most impactful if fixed for the paper.
