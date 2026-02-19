# Scaling Report — 25 Paper Models

## Methodology

For each parameter `p` with original true value `v > 0`:
- Scale factor: `s_p = 2 * v`
- Scaled true value: `p_scaled = 0.5`
- Relationship: `p_original = s_p * p_scaled`

For zero ICs: perturbed to a small physically reasonable nonzero value, then scaled.
For negative values: `s = 2 * v` (negative scale factor), so `p_scaled = 0.5` still works.

---

## Model 1: Harmonic Oscillator

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| a | 1.0 | 2.0 | 0.5 |
| b | 1.0 | 2.0 | 0.5 |
| x1(0) | 1.0 | 2.0 | 0.5 |
| x2(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: x2(0) perturbed from 0 to 0.5 (gives initial velocity). Dynamics are simple harmonic oscillation.

---

## Model 2: Lotka-Volterra

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| k1 | 1.0 | 2.0 | 0.5 |
| k2 | 0.5 | 1.0 | 0.5 |
| k3 | 0.3 | 0.6 | 0.5 |
| r(0) | 2.0 | 4.0 | 0.5 |
| w(0) | 1.0 | 2.0 | 0.5 |

**Notes**: Clean scaling. Only prey (r) is observed. Classic partial observability.

---

## Model 3: Van der Pol Oscillator

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| a | 1.0 | 2.0 | 0.5 |
| b | 1.0 | 2.0 | 0.5 |
| x1(0) | 2.0 | 4.0 | 0.5 |
| x2(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: x2(0) perturbed from 0 to 0.5. The cubic nonlinearity (x1^2) creates large coefficients after scaling (32.0).

---

## Model 4: Brusselator

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| a | 1.0 | 2.0 | 0.5 |
| b | 3.0 | 6.0 | 0.5 |
| X(0) | 1.0 | 2.0 | 0.5 |
| Y(0) | 1.0 | 2.0 | 0.5 |

**Notes**: The constant term 1.0 in D(X) becomes 0.5 after dividing by s_X. Quadratic autocatalytic term X^2*Y picks up factor s_a*s_X^2*s_Y/s_X = 16.0.

---

## Model 5: CSTR with Fixed Activation Energy

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| tau | 1.0 | 2.0 | 0.5 |
| Tin | 350.0 | 700.0 | 0.5 |
| Cin | 1.0 | 2.0 | 0.5 |
| dH_rhoCP | 5.0 | 10.0 | 0.5 |
| UA_VrhoCP | 1.0 | 2.0 | 0.5 |
| C(0) | 0.5 | 1.0 | 0.5 |
| T(0) | 350.0 | 700.0 | 0.5 |
| r_eff(0) | ~1.0 | ~2.0 | 0.5 |
| u_sin(0) | 0.0→0.5 | 1.0 | 0.5 |
| u_cos(0) | 1.0 | 2.0 | 0.5 |

**Notes**: Very large scale factors due to temperature (700.0). The r_eff equation involves E_R/T^2 which creates extreme sensitivity. Oscillator states added for sinusoidal coolant temperature. The scale factors are kept symbolic in the equations for readability.

**Potential issues**: Large coefficient ratios (700:1) may cause numerical sensitivity. Random draws may produce unrealistic temperature ratios.

---

## Model 6: Biohydrogenation

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| k5 | 0.5 | 1.0 | 0.5 |
| k6 | 2.0 | 4.0 | 0.5 |
| k7 | 0.3 | 0.6 | 0.5 |
| k8 | 1.0 | 2.0 | 0.5 |
| k9 | 0.2 | 0.4 | 0.5 |
| k10 | 5.0 | 10.0 | 0.5 |
| x4(0) | 4.0 | 8.0 | 0.5 |
| x5(0) | 0.0→0.25 | 0.5 | 0.5 |
| x6(0) | 0.0→0.25 | 0.5 | 0.5 |
| x7(0) | 0.0→0.25 | 0.5 | 0.5 |

**Notes**: Three zero ICs (intermediates) perturbed to 0.25. Michaelis-Menten kinetics preserved through scaling — the rational forms k*x/(K+x) remain rational with different coefficients.

---

## Model 7: Mass-Spring-Damper

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| m | 1.0 | 2.0 | 0.5 |
| c | 0.5 | 1.0 | 0.5 |
| k | 4.0 | 8.0 | 0.5 |
| F | 1.0 | 2.0 | 0.5 |
| x(0) | 0.5 | 1.0 | 0.5 |
| v(0) | 0.0→0.25 | 0.5 | 0.5 |

**Notes**: Velocity IC perturbed from rest. Spring constant creates large scale factor (8.0).

---

## Model 8: DC Motor (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| Kt | 0.1 | 0.2 | 0.5 |
| J | 0.01 | 0.02 | 0.5 |
| b | 0.1 | 0.2 | 0.5 |
| omega_m(0) | 0.0→0.5 | 1.0 | 0.5 |
| i(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: Both ICs perturbed from rest. Small J (inertia) creates fast dynamics with large effective coefficients (10.0 factor). External sinusoidal voltage V(t)=12+2sin(5t) is unchanged — it's the known input.

---

## Model 9: Flexible Arm

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| Jm | 0.1 | 0.2 | 0.5 |
| Jt | 0.05 | 0.1 | 0.5 |
| bm | 0.1 | 0.2 | 0.5 |
| bt | 0.05 | 0.1 | 0.5 |
| k | 10.0 | 20.0 | 0.5 |
| tau | 0.5 | 1.0 | 0.5 |
| theta_m(0) | 0.0→0.25 | 0.5 | 0.5 |
| omega_m(0) | 0.0→0.25 | 0.5 | 0.5 |
| theta_t(0) | 0.0→0.25 | 0.5 | 0.5 |
| omega_t(0) | 0.0→0.25 | 0.5 | 0.5 |

**Notes**: ALL four ICs are zero (starts at rest). Perturbed to 0.25. Large stiffness (k=10→s=20) creates stiff dynamics. The k*(theta_m-theta_t) coupling term is key — with independent scaling of angles, it remains correct.

---

## Model 10: Aircraft Pitch (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| M_alpha | -5.0 | -10.0 | 0.5 |
| M_q | -2.0 | -4.0 | 0.5 |
| M_delta_e | -10.0 | -20.0 | 0.5 |
| Z_alpha | -0.5 | -1.0 | 0.5 |
| theta(0) | 0.0→0.025 | 0.05 | 0.5 |
| q(0) | 0.0→0.025 | 0.05 | 0.5 |
| alpha(0) | 0.05 | 0.1 | 0.5 |

**Special handling — negative parameters**: All four parameters are negative (aerodynamic stability derivatives are negative by convention). We use negative scale factors: s = 2*v where v < 0. This means s_p * p_scaled = negative value at p_scaled = 0.5. The external harness draws positive p_scaled values from [0.1, 1.0], so the sign flip happens through the scale factor in the equation, and estimated parameters are positive.

**Notes**: theta and q ICs perturbed from 0 to 0.025 rad (small angles).

---

## Model 11: Bicycle Model (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| Cf | 80000.0 | 160000.0 | 0.5 |
| Cr | 80000.0 | 160000.0 | 0.5 |
| m_veh | 1500.0 | 3000.0 | 0.5 |
| Iz | 2500.0 | 5000.0 | 0.5 |
| vy(0) | 0.0→0.25 | 0.5 | 0.5 |
| r(0) | 0.0→0.05 | 0.1 | 0.5 |

**Notes**: Extremely large scale factors (160000) due to tire cornering stiffness. Both ICs zero (vehicle moving straight). vy perturbed to 0.25 m/s, r to 0.05 rad/s. The large numerical coefficients may cause issues with symbolic processing.

**Potential issues**: The ratio Cf/m_veh matters physically (~53 in original, preserved in scaling). Random draws may produce unrealistic ratios.

---

## Model 12: Quadrotor (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| m | 1.0 | 2.0 | 0.5 |
| d | 0.1 | 0.2 | 0.5 |
| z(0) | 5.0 | 10.0 | 0.5 |
| w(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: z(0) is altitude — naturally large. w(0) perturbed from rest. Clean scaling with moderate factors.

---

## Model 13: Boost Converter (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| L | 0.001 | 0.002 | 0.5 |
| C_cap | 0.001 | 0.002 | 0.5 |
| R_load | 10.0 | 20.0 | 0.5 |
| iL(0) | 1.0 | 2.0 | 0.5 |
| vC(0) | 24.0 | 48.0 | 0.5 |

**Notes**: Very small L and C (millihenry, millifarad) create very fast dynamics (omega=100 rad/s). Scale factors span 0.002 to 48.0. The d_complement=0.5-0.1*sin(100t) is the known PWM duty cycle.

**Potential issues**: Fast switching dynamics (T=0.5s observation window) combined with random parameter draws may cause stiffness.

---

## Model 14: SEIR

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| a | 0.2 | 0.4 | 0.5 |
| b | 0.4 | 0.8 | 0.5 |
| nu | 0.15 | 0.3 | 0.5 |
| S(0) | 990.0 | 1980.0 | 0.5 |
| E(0) | 10.0 | 20.0 | 0.5 |
| In(0) | 0.0→5.0 | 10.0 | 0.5 |
| N(0) | 1000.0 | 2000.0 | 0.5 |

**Notes**: In(0) perturbed to 5.0 (small initial infection). Conservation law S+E+In=N is broken by independent scaling (different scale factors). This is intentional — the randomized harness doesn't preserve conservation laws.

---

## Model 15: FitzHugh-Nagumo

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| g | 3.0 | 6.0 | 0.5 |
| a | 0.2 | 0.4 | 0.5 |
| b | 0.2 | 0.4 | 0.5 |
| V(0) | -1.0 | -2.0 | 0.5 |
| R(0) | 0.0→0.25 | 0.5 | 0.5 |

**Special handling — negative IC**: V(0)=-1.0, so s_V = 2*(-1) = -2.0. Then V_orig = -2.0 * V_scaled, and V_scaled = 0.5 gives V_orig = -1.0 (correct). Random V_scaled in [0.1, 1.0] gives V_orig in [-0.2, -2.0].

**Notes**: Very fast timescale (0.03s for action potential). Cubic V^3 term creates large coefficients.

---

## Model 16: Repressilator

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| beta | 2.0 | 4.0 | 0.5 |
| n | 2.0 | 4.0 | 0.5 |
| alpha | 1.0 | 2.0 | 0.5 |
| m1(0) | 0.0→0.25 | 0.5 | 0.5 |
| m2(0) | 0.0→0.25 | 0.5 | 0.5 |
| m3(0) | 0.0→0.25 | 0.5 | 0.5 |
| p1(0) | 2.0 | 4.0 | 0.5 |
| p2(0) | 1.0 | 2.0 | 0.5 |
| p3(0) | 3.0 | 6.0 | 0.5 |

**Notes**: Three zero mRNA ICs perturbed to 0.25. Protein ICs have different scales (2, 1, 3) — asymmetric initial condition. The Hill-type repression 1/(1+p*n) remains rational after scaling with modified coefficients.

---

## Model 17: HIV

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| lm | 1.0 | 2.0 | 0.5 |
| d | 0.01 | 0.02 | 0.5 |
| beta | 2e-5 | 4e-5 | 0.5 |
| a | 0.5 | 1.0 | 0.5 |
| k | 50.0 | 100.0 | 0.5 |
| u | 3.0 | 6.0 | 0.5 |
| c | 0.05 | 0.1 | 0.5 |
| q | 0.1 | 0.2 | 0.5 |
| b | 0.002 | 0.004 | 0.5 |
| h | 0.1 | 0.2 | 0.5 |
| x(0) | 1000.0 | 2000.0 | 0.5 |
| y(0) | 1.0 | 2.0 | 0.5 |
| v(0) | 1e-3 | 0.002 | 0.5 |
| w(0) | 1.0 | 2.0 | 0.5 |
| z(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: Extreme parameter range: scale factors span 4e-5 to 100.0 (ratio ~2.5 million). IC scale factors span 0.002 to 2000.0 (ratio 1 million). Composite observation y4 = y + v mixes two states with very different scales. z(0) perturbed from 0 to 0.5.

**Potential issues**: The wide range of scale factors means random draws may produce biologically nonsensical parameter combinations. Blowup risk is moderate.

---

## Model 18: DAISY Mamillary 4-Compartment

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| k01 | 0.125 | 0.25 | 0.5 |
| k12 | 0.25 | 0.5 | 0.5 |
| k13 | 0.375 | 0.75 | 0.5 |
| k14 | 0.5 | 1.0 | 0.5 |
| k21 | 0.625 | 1.25 | 0.5 |
| k31 | 0.75 | 1.5 | 0.5 |
| k41 | 0.875 | 1.75 | 0.5 |
| x1(0) | 0.2 | 0.4 | 0.5 |
| x2(0) | 0.4 | 0.8 | 0.5 |
| x3(0) | 0.6 | 1.2 | 0.5 |
| x4(0) | 0.8 | 1.6 | 0.5 |

**Notes**: Already close to 0.5! Scale factors are all moderate (0.25 to 1.75). Very clean scaling. Linear dynamics ensure no blowup risk.

---

## Model 19: Two-Compartment PK

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| k12 | 0.5 | 1.0 | 0.5 |
| k21 | 0.25 | 0.5 | 0.5 |
| ke | 0.15 | 0.3 | 0.5 |
| V1 | 1.0 | 2.0 | 0.5 |
| V2 | 2.0 | 4.0 | 0.5 |
| C1(0) | 10.0 | 20.0 | 0.5 |
| C2(0) | 0.0→0.5 | 1.0 | 0.5 |

**Notes**: C2(0) perturbed from 0 (no drug in peripheral compartment initially). The V2/V1 volume ratio appears in equations and is preserved through scaling.

---

## Model 20: Crauste Corrected

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| mu_N | 0.75 | 1.5 | 0.5 |
| mu_EE | 2.16e-5 | 4.32e-5 | 0.5 |
| mu_LE | 3.6e-8 | 7.2e-8 | 0.5 |
| mu_LL | 7.5e-6 | 1.5e-5 | 0.5 |
| mu_M | 0.0 | — | **0.0** |
| mu_P | 0.055 | 0.11 | 0.5 |
| mu_PE | 1.8e-7 | 3.6e-7 | 0.5 |
| mu_PL | 1.8e-5 | 3.6e-5 | 0.5 |
| delta_NE | 0.009 | 0.018 | 0.5 |
| delta_EL | 0.59 | 1.18 | 0.5 |
| delta_LM | 0.025 | 0.05 | 0.5 |
| rho_E | 0.64 | 1.28 | 0.5 |
| rho_P | 0.15 | 0.3 | 0.5 |
| N(0) | 8090.0 | 16180.0 | 0.5 |
| E(0) | 0.0→5.0 | 10.0 | 0.5 |
| L(0) | 0.0→5.0 | 10.0 | 0.5 |
| M(0) | 0.0→5.0 | 10.0 | 0.5 |
| P(0) | 1.0 | 2.0 | 0.5 |

**Special handling — zero parameter**: mu_M = 0. Kept as parameter with true value 0.0 (not 0.5). The mu_M*M term in D(M) equation will always be zero regardless of M. Hardcoding as 0 would change the model structure.

**Notes**: Extreme range: parameter scale factors span 7.2e-8 to 1.5, IC scales span 2.0 to 16180.0. The three zero ICs (E, L, M) are immune cell populations that start at zero (naïve immune system). Perturbed to 5.0.

---

## Model 21: Forced LV Sinusoidal

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| alpha | 1.5 | 3.0 | 0.5 |
| beta | 1.0 | 2.0 | 0.5 |
| delta | 0.5 | 1.0 | 0.5 |
| gamma | 3.0 | 6.0 | 0.5 |
| x(0) | 1.0 | 2.0 | 0.5 |
| y(0) | 1.0 | 2.0 | 0.5 |

**Notes**: Clean scaling. Sinusoidal harvesting term -0.3*sin(2t) is external forcing (unchanged). Both populations observed.

---

## Model 22: Treatment

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| a | 0.1 | 0.2 | 0.5 |
| b | 0.8 | 1.6 | 0.5 |
| d | 2.0 | 4.0 | 0.5 |
| g | 0.3 | 0.6 | 0.5 |
| nu | 0.1 | 0.2 | 0.5 |
| In(0) | 50.0 | 100.0 | 0.5 |
| N(0) | 1000.0 | 2000.0 | 0.5 |
| S(0) | 950.0 | 1900.0 | 0.5 |
| Tr(0) | 0.0→5.0 | 10.0 | 0.5 |

**Notes**: Tr(0) perturbed (initial treatment population). Conservation law N=In+S+Tr broken by scaling.

---

## Model 23: SIRS Forced

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| b0 | 0.143 | 0.286 | 0.5 |
| b1 | 0.286 | 0.572 | 0.5 |
| g | 0.429 | 0.858 | 0.5 |
| M | 0.571 | 1.142 | 0.5 |
| mu | 0.714 | 1.428 | 0.5 |
| nu | 0.857 | 1.714 | 0.5 |
| i(0) | 0.167 | 0.334 | 0.5 |
| r(0) | 0.333 | 0.666 | 0.5 |
| s(0) | 0.5 | 1.0 | 0.5 |
| x1(0) | 0.667 | 1.334 | 0.5 |
| x2(0) | 0.833 | 1.666 | 0.5 |

**Notes**: Already very close to 0.5! All scale factors are between 0.286 and 1.714. The x1, x2 states encode the oscillator for periodic forcing. s(0)=0.5 exactly, no scaling needed!

---

## Model 24: Slow-Fast

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| k1 | 0.25 | 0.5 | 0.5 |
| k2 | 0.5 | 1.0 | 0.5 |
| xA(0) | 0.166 | 0.332 | 0.5 |
| xB(0) | 0.333 | 0.666 | 0.5 |
| xC(0) | 0.5 | 1.0 | 0.5 |
| eA(0) | 0.666 | 1.332 | 0.5 |
| eC(0) | 0.833 | 1.666 | 0.5 |
| eB(0) | 0.75 | 1.5 | 0.5 |

**Notes**: Already very close to 0.5! Three constant states (eA, eC, eB) with D=0. They just hold their initial value. The nonlinear observation y2 = eA*xA + eB*xB + eC*xC requires proper scaling with product of state scale factors.

---

## Model 25: Magnetic Levitation (Sinusoidal)

| Quantity | Original | Scale Factor | Scaled True |
|----------|----------|-------------|-------------|
| m_lin | 0.1 | 0.2 | 0.5 |
| k_lin | 50.0 | 100.0 | 0.5 |
| b_lin | 2.0 | 4.0 | 0.5 |
| x(0) | 0.0→0.005 | 0.01 | 0.5 |
| v(0) | 0.0→0.025 | 0.05 | 0.5 |
| i(0) | 2.5 | 5.0 | 0.5 |

**Notes**: Two zero ICs (position and velocity) perturbed to small values near equilibrium. The current IC i(0) = V0/R_coil = 5.0/2.0 = 2.5 is the equilibrium current. The linearized force model ki*(i-i_eq) means perturbations from equilibrium matter, not absolute values. The system is inherently unstable (maglev needs active control).

**Potential issues**: Small position scale (0.01) means the ball is near the magnet. Random i draws may push the system far from equilibrium, causing divergence.
