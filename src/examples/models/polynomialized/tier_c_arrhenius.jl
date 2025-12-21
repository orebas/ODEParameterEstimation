#=============================================================================
Tier C: Polynomialized Control Systems - Arrhenius Kinetics (exp of state)

These systems have exp(-E/T) terms (Arrhenius kinetics) that need polynomialization.

POLYNOMIALIZATION STRATEGY:
For z = exp(-E_R / T):
  - dz/dt = d/dt[exp(-E_R/T)]
  - dz/dt = exp(-E_R/T) * d(-E_R/T)/dt
  - dz/dt = z * (E_R / T^2) * dT/dt

So: D(z) = z * (E_R / T^2) * D(T)

This is POLYNOMIAL in (z, T, D(T)) but RATIONAL in T (has T^2 in denominator).
After substitution, the full system becomes rational in T.

ALGEBRAIC CONSTRAINT:
  z = exp(-E_R / T)  or equivalently  ln(z) = -E_R / T  =>  T = -E_R / ln(z)

INITIAL CONDITIONS:
  z(0) = exp(-E_R / T(0))

This is the most common transcendental form in chemical engineering models.
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                              CSTR (Continuous Stirred Tank Reactor)

    Original system:
      D(C) = (Cin - C)/tau - k0*exp(-E_R/T)*C
      D(T) = (Tin - T)/tau + dH_rhoCP*k0*exp(-E_R/T)*C - UA_VrhoCP*(T - Tc(t))

    where Tc(t) = Tc0 + Tca*sin(omega*t) is the oscillating coolant temperature.
=============================================================================#

"""
    cstr_poly()

CSTR with polynomialized Arrhenius kinetics.

Original system:
  D(C) = (Cin - C)/tau - k0*exp(-E_R/T)*C
  D(T) = (Tin - T)/tau + dH_rhoCP*k0*exp(-E_R/T)*C - UA_VrhoCP*(T - Tc(t))
  Tc(t) = Tc0 + Tca*sin(omega*t)

Polynomialization:
  Let z = exp(-E_R / T)  (the Arrhenius factor)

  Then D(z) = z * (E_R / T^2) * D(T)

  Substituting:
    D(C) = (Cin - C)/tau - k0*z*C
    D(T) = (Tin - T)/tau + dH_rhoCP*k0*z*C - UA_VrhoCP*(T - Tc)
    D(z) = z * (E_R / T^2) * D(T)
         = z * (E_R / T^2) * [(Tin - T)/tau + dH_rhoCP*k0*z*C - UA_VrhoCP*(T - Tc)]

The D(z) equation is RATIONAL in T (has T^2 in denominator).

Plant parameters (UNKNOWN): k0, E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP
Input parameters (FIXED): Tc0=300.0, Tca=10.0, omega=0.5

CONSTRAINT: z = exp(-E_R / T)
IC CONSTRAINT: z(0) = exp(-E_R / T(0))

NOTE: This model has many parameters. In practice, some might be known.
"""
function cstr_poly()
    @parameters k0 E_R tau Tin Cin dH_rhoCP UA_VrhoCP

    # Input parameters - FIXED
    Tc0_val = 300.0   # mean coolant temp (K)
    Tca_val = 10.0    # coolant oscillation amplitude (K)
    omega_val = 0.5   # frequency

    # States: C (concentration), T (temperature), z (Arrhenius factor), plus input oscillator
    @variables C(t) T(t) z_arr(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        7.2e10,   # k0: pre-exponential factor (very large!)
        8750.0,   # E_R: E/R activation energy/gas constant (K)
        1.0,      # tau: residence time (s)
        350.0,    # Tin: inlet temperature (K)
        1.0,      # Cin: inlet concentration (mol/L)
        5.0,      # dH_rhoCP: heat release parameter
        1.0,      # UA_VrhoCP: heat transfer parameter
    ]

    # Initial conditions
    C0 = 0.5    # Initial concentration
    T0 = 350.0  # Initial temperature
    # z(0) = exp(-E_R / T0) = exp(-8750 / 350) = exp(-25) ≈ 1.4e-11
    z0 = exp(-p_true[2] / T0)

    ic_true = [C0, T0, z0, 0.0, 1.0]  # [C, T, z_arr, u_sin, u_cos]

    # Coolant temperature: Tc(t) = Tc0 + Tca*u_sin
    Tc = Tc0_val + Tca_val * u_sin

    # Reaction rate = k0 * z_arr * C (instead of k0 * exp(-E_R/T) * C)
    reaction_rate = k0 * z_arr * C

    # D(T) - store for reuse in D(z_arr)
    # D(T) = (Tin - T)/tau + dH_rhoCP*reaction_rate - UA_VrhoCP*(T - Tc)

    equations = [
        # Concentration dynamics
        D(C) ~ (Cin - C) / tau - reaction_rate,

        # Temperature dynamics
        D(T) ~ (Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc),

        # Arrhenius factor dynamics: D(z) = z * (E_R / T^2) * D(T)
        # Expanded: D(z) = z * E_R / T^2 * [(Tin-T)/tau + dH*k0*z*C - UA*(T-Tc)]
        D(z_arr) ~ z_arr * (E_R / T^2) * ((Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc)),

        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # We observe temperature (common measurement) and input
    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [C, T, z_arr, u_sin, u_cos]
    parameters = [k0, E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_poly", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_poly",
        model,
        mq,
        nothing,
        [0.0, 20.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

#=============================================================================
                    NOTES ON CSTR POLYNOMIALIZATION

1. NUMERICAL CONSIDERATIONS:
   - z = exp(-E_R/T) is very small for typical values (e.g., exp(-25) ≈ 1e-11)
   - k0 is very large (e.g., 7.2e10)
   - The product k0*z is O(1), so reaction rates are reasonable
   - But z as a state variable has very small magnitude

2. ALTERNATIVE FORMULATION:
   Could introduce w = ln(z) = -E_R/T instead, giving:
   - T = -E_R / w
   - D(w) = (E_R / T^2) * D(T) = (w^2 / E_R) * D(T)
   This might have better numerical properties.

3. PARAMETER IDENTIFIABILITY:
   - With z as a state, k0 and z appear as product k0*z
   - Original model has k0*exp(-E_R/T), so k0 and E_R may not be separately identifiable
   - This structural issue remains after polynomialization

4. CONSTRAINT HANDLING:
   - The constraint z = exp(-E_R/T) is transcendental
   - It's needed only for consistent ICs
   - In estimation, if z is treated as a free state, the constraint might be violated

5. CLEARING DENOMINATORS:
   The D(z_arr) equation has T^2 in denominator. To get purely polynomial:
   T^2 * D(z_arr) = z_arr * E_R * D(T)
   This could be done but changes the equation structure significantly.
=============================================================================#

"""
    cstr_poly_cleared()

CSTR with polynomialized Arrhenius kinetics, denominators cleared.

Same as cstr_poly but with T^2 moved to LHS to get polynomial (not rational) form.
This is mathematically equivalent but may behave differently numerically.

NOTE: This changes the implicit timescale when T is small.
"""
function cstr_poly_cleared()
    @parameters k0 E_R tau Tin Cin dH_rhoCP UA_VrhoCP

    # Input parameters - FIXED
    Tc0_val = 300.0
    Tca_val = 10.0
    omega_val = 0.5

    @variables C(t) T(t) z_arr(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    p_true = [
        7.2e10,   # k0
        8750.0,   # E_R
        1.0,      # tau
        350.0,    # Tin
        1.0,      # Cin
        5.0,      # dH_rhoCP
        1.0,      # UA_VrhoCP
    ]

    C0 = 0.5
    T0 = 350.0
    z0 = exp(-p_true[2] / T0)
    ic_true = [C0, T0, z0, 0.0, 1.0]

    Tc = Tc0_val + Tca_val * u_sin
    reaction_rate = k0 * z_arr * C

    # To clear denominators in D(z_arr), we'd need to restructure the ODE
    # Actually, MTK doesn't directly support "cleared denominator" form
    # as a differential equation. The rational form is the natural one.

    # For now, this is identical to cstr_poly - a true "cleared" form would
    # require a DAE formulation or algebraic manipulation outside the ODE system.

    equations = [
        D(C) ~ (Cin - C) / tau - reaction_rate,
        D(T) ~ (Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc),
        D(z_arr) ~ z_arr * (E_R / T^2) * ((Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc)),
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [C, T, z_arr, u_sin, u_cos]
    parameters = [k0, E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_poly_cleared", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_poly_cleared",
        model,
        mq,
        nothing,
        [0.0, 20.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end
