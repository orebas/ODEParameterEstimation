#=============================================================================
Tier A: REPARAMETRIZED Versions - Using Identifiable Combinations as Parameters

These systems demonstrate the power of algebraic identifiability analysis.
Instead of fixing parameters (which requires prior knowledge), we
REPARAMETRIZE the model using the structurally identifiable combinations
that StructuralIdentifiability.jl discovers.

MOTIVATION:
When the algebraic analysis finds that only certain parameter combinations
(like J/b, Kt/b) are identifiable, an optimizer would struggle to find
unique solutions (infinite solutions along a manifold). But by making
these COMBINATIONS the parameters themselves, we get a uniquely
identifiable system.

This showcases the power of algebraic methods: they don't just detect
unidentifiability, they tell us WHAT IS identifiable, which we can use
to reformulate the estimation problem.
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                          1. DC MOTOR (REPARAMETRIZED)

Original system had parameters: R, L, Kb, Kt, J, b (6 params)
With R, L, Kb fixed, remaining params: Kt, J, b (3 params)

StructuralIdentifiability.jl found:
  - Unidentifiable individually: {Kt, J, b}
  - Identifiable combinations: J/b (= tau_m), Kt/b (= kappa)

REPARAMETRIZATION:
  Define: tau_m = J/b  (mechanical time constant, units: seconds)
          kappa = Kt/b (torque-to-damping ratio, units: N·m/A / N·m·s = A⁻¹)

Original equation:
  D(omega_m) = (Kt/J)*i - (b/J)*omega_m

Reparametrized:
  D(omega_m) = (kappa/tau_m)*i - (1/tau_m)*omega_m
             = (kappa*i - omega_m)/tau_m

This is NOW IDENTIFIABLE with only 2 parameters!

PHYSICAL INTERPRETATION:
  - tau_m: Mechanical time constant - how fast the motor responds
  - kappa: Sensitivity of torque to current (normalized by damping)
=============================================================================#

"""
    dc_motor_reparametrized()

DC motor reparametrized using structurally identifiable combinations.

Instead of trying to estimate individual parameters Kt, J, b (which are
not individually identifiable), we estimate the combinations that ARE
identifiable:
  - tau_m = J/b (mechanical time constant)
  - kappa = Kt/b (torque-to-damping ratio)

This demonstrates the power of algebraic parameter estimation: the
analysis tells us not just WHAT is unidentifiable, but WHAT COMBINATIONS
are identifiable, allowing us to reformulate the problem.

True values (from original Kt=0.1, J=0.01, b=0.1):
  - tau_m = J/b = 0.01/0.1 = 0.1 s
  - kappa = Kt/b = 0.1/0.1 = 1.0 A⁻¹
"""
function dc_motor_reparametrized()
    # REPARAMETRIZED parameters - these are the identifiable combinations
    @parameters tau_m kappa

    # FIXED electrical parameters (known from measurement/datasheet)
    R_val = 2.0     # armature resistance (Ohms) - measured
    L_val = 0.5     # armature inductance (H) - measured
    Kb_val = 0.1    # back-EMF constant (V·s/rad) - from datasheet

    # Input parameters - FIXED
    V0_val = 12.0   # DC voltage offset
    Va_val = 2.0    # AC voltage amplitude
    omega_val = 5.0 # Input frequency (rad/s)

    # States
    @variables omega_m(t) i(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True values for REPARAMETRIZED parameters
    # Original: Kt=0.1, J=0.01, b=0.1
    # tau_m = J/b = 0.01/0.1 = 0.1
    # kappa = Kt/b = 0.1/0.1 = 1.0
    p_true = [
        0.1,    # tau_m: mechanical time constant (J/b)
        1.0,    # kappa: torque-to-damping ratio (Kt/b)
    ]

    ic_true = [0.0, 0.0, 0.0, 1.0]  # [omega_m, i, u_sin, u_cos]

    V_input = V0_val + Va_val * u_sin

    equations = [
        # Reparametrized mechanical equation:
        # Original: D(omega_m) = (Kt/J)*i - (b/J)*omega_m
        # With tau_m = J/b and kappa = Kt/b:
        #   Kt/J = (Kt/b)/(J/b) = kappa/tau_m
        #   b/J = 1/tau_m
        # Result: D(omega_m) = (kappa*i - omega_m)/tau_m
        D(omega_m) ~ (kappa * i - omega_m) / tau_m,

        # Electrical equation (unchanged - uses fixed R, L, Kb)
        D(i) ~ (V_input - R_val * i - Kb_val * omega_m) / L_val,

        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ omega_m, y2 ~ u_sin, y3 ~ u_cos]

    states = [omega_m, i, u_sin, u_cos]
    parameters = [tau_m, kappa]

    model, mq = create_ordered_ode_system("dc_motor_reparametrized", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "dc_motor_reparametrized",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end


#=============================================================================
                    2. MAGNETIC LEVITATION (REPARAMETRIZED)

Original system had parameters: R_coil, L, ki, m_lin, k_lin, b_lin (6 params)
With R_coil, L, ki fixed, remaining params: m_lin, k_lin, b_lin (3 params)

The mechanical equation:
  D(v) = (ki*(i-i_eq) - k_lin*x - b_lin*v) / m_lin

StructuralIdentifiability analysis would find identifiable combinations.
Let's use physical ratios:
  - omega_n^2 = k_lin/m_lin (natural frequency squared)
  - zeta_omega = b_lin/(2*m_lin) = damping ratio * natural frequency
  - gain = ki/m_lin (force-to-mass ratio for current perturbation)

Reparametrization:
  D(v) = gain*(i-i_eq) - omega_n^2*x - 2*zeta_omega*v

NOTE: This has 3 parameters but they are combinations of 3 originals.
We'll use a simpler 2-parameter version for demonstration.

SIMPLER VERSION:
If we observe both x AND v (position and velocity), we can identify more.
Let's use:
  - omega_n2 = k_lin/m_lin (stiffness-to-mass ratio)
  - damping_ratio = b_lin/m_lin (damping-to-mass ratio)
And fix ki/m_lin = ki_val/m_lin_val (from calibration) to reduce to 2 params.

Actually, let's do a cleaner version: fix ki and just estimate the
mechanical ratios.
=============================================================================#

"""
    magnetic_levitation_reparametrized()

Magnetic levitation reparametrized using identifiable combinations.

The mechanical dynamics D(v) = (ki*i' - k_lin*x - b_lin*v)/m_lin
only allow identification of ratios with m_lin.

Reparametrized parameters:
  - omega_n_sq = k_lin/m_lin (stiffness-to-mass ratio, rad²/s²)
  - damping_coeff = b_lin/m_lin (damping-to-mass ratio, 1/s)

The ki*i'/m_lin term is handled by fixing ki and using a gain parameter.

True values (from original m_lin=0.1, k_lin=50.0, b_lin=2.0):
  - omega_n_sq = k_lin/m_lin = 50.0/0.1 = 500.0 rad²/s²
  - damping_coeff = b_lin/m_lin = 2.0/0.1 = 20.0 s⁻¹
  - gain = ki/m_lin = 10.0/0.1 = 100.0 (force per amp per unit mass)
"""
function magnetic_levitation_reparametrized()
    # REPARAMETRIZED parameters
    @parameters omega_n_sq damping_coeff gain

    # FIXED electrical parameters (measured)
    R_coil_val = 2.0   # coil resistance (Ohms)
    L_val = 0.05       # inductance (H)

    # Input parameters - FIXED
    V0_val = 5.0
    Va_val = 1.0
    omega_val = 5.0

    @variables x(t) v(t) i(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True values for REPARAMETRIZED parameters
    # Original: m_lin=0.1, k_lin=50.0, b_lin=2.0, ki=10.0
    # omega_n_sq = k_lin/m_lin = 50.0/0.1 = 500.0
    # damping_coeff = b_lin/m_lin = 2.0/0.1 = 20.0
    # gain = ki/m_lin = 10.0/0.1 = 100.0
    p_true = [
        500.0,    # omega_n_sq: stiffness/mass ratio
        20.0,     # damping_coeff: damping/mass ratio
        100.0,    # gain: ki/m_lin
    ]

    i_eq = V0_val / R_coil_val
    ic_true = [0.0, 0.0, i_eq, 0.0, 1.0]

    V_input = V0_val + Va_val * u_sin

    equations = [
        D(x) ~ v,
        # Original: D(v) = (ki*(i-i_eq) - k_lin*x - b_lin*v) / m_lin
        # Reparametrized: D(v) = gain*(i-i_eq) - omega_n_sq*x - damping_coeff*v
        D(v) ~ gain * (i - i_eq) - omega_n_sq * x - damping_coeff * v,
        D(i) ~ (V_input - R_coil_val * i) / L_val,
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ x, y2 ~ u_sin, y3 ~ u_cos]

    states = [x, v, i, u_sin, u_cos]
    parameters = [omega_n_sq, damping_coeff, gain]

    model, mq = create_ordered_ode_system("magnetic_levitation_reparametrized", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "magnetic_levitation_reparametrized",
        model,
        mq,
        nothing,
        [0.0, 5.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end


#=============================================================================
                    SUMMARY: REPARAMETRIZATION APPROACH

The key insight from algebraic identifiability analysis:

1. PROBLEM: Many physical systems have more parameters than can be uniquely
   identified from the available observations.

2. TRADITIONAL APPROACH: Fix some parameters using prior knowledge.
   - Requires accurate prior information
   - May not be possible for some parameters

3. ALGEBRAIC APPROACH: Reparametrize using identifiable combinations.
   - No prior knowledge needed
   - The combinations ARE the meaningful quantities
   - Often have physical interpretation (time constants, ratios)

4. ADVANTAGE OVER OPTIMIZERS:
   - Optimizers would find infinite solutions along a manifold
   - Algebraic methods find EXACTLY the identifiable combinations
   - Reparametrization gives a well-posed unique problem

Example: DC Motor
- Original: Kt, J, b (3 params, infinite solutions)
- Reparametrized: tau_m = J/b, kappa = Kt/b (2 params, unique solution)
- Physical meaning: tau_m is mechanical time constant, kappa is gain

This demonstrates why algebraic identifiability analysis is more than
just a "pass/fail" test - it tells us HOW to fix the problem!
=============================================================================#
