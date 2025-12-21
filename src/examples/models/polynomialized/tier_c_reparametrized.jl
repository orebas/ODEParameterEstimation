#=============================================================================
Tier C: REPARAMETRIZED CSTR - Using k0*exp(-E_R/T) as a State Variable

MOTIVATION:
In the original CSTR model, k0 and exp(-E_R/T) always appear as a product.
This means k0 is not separately identifiable from the Arrhenius factor.

REPARAMETRIZATION:
Instead of having:
  - z_arr = exp(-E_R/T) as state
  - k0 as parameter

We define:
  - r_eff = k0 * exp(-E_R/T) as state (the effective rate constant)
  - k0 is eliminated (absorbed into initial condition r_eff(0))

This reduces parameters from 7 to 6:
  Original: k0, E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP
  Reparametrized: E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP

DYNAMICS:
  r_eff = k0 * exp(-E_R/T)
  D(r_eff) = k0 * exp(-E_R/T) * (E_R/T²) * D(T)
           = r_eff * (E_R/T²) * D(T)

The E_R parameter still appears in the D(r_eff) equation, but k0 is gone.

PHYSICAL INTERPRETATION:
  - r_eff: The actual reaction rate constant at temperature T (units: 1/time)
  - r_eff(0) = k0 * exp(-E_R/T(0)) encodes the original k0 value
  - E_R: Activation energy / gas constant (units: K)

NUMERICAL BENEFITS:
  - Original: z_arr ≈ 1e-11 (very small), k0 ≈ 7e10 (very large), product ≈ O(1)
  - Reparametrized: r_eff ≈ O(1) directly (much better numerics!)
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

"""
    cstr_reparametrized()

CSTR with k0*exp(-E_R/T) as a single state variable.

This reparametrization:
1. Eliminates k0 as a parameter (absorbed into IC)
2. Keeps E_R as a parameter (still appears in dynamics)
3. Uses r_eff = k0*exp(-E_R/T) with better numerical scale

Original parameters (7): k0, E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP
Reparametrized (6): E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP

True values:
  - E_R = 8750.0 K (activation energy / R)
  - tau = 1.0 s (residence time)
  - Tin = 350.0 K (inlet temperature)
  - Cin = 1.0 mol/L (inlet concentration)
  - dH_rhoCP = 5.0 (heat release parameter)
  - UA_VrhoCP = 1.0 (heat transfer parameter)

Initial condition for r_eff:
  r_eff(0) = k0 * exp(-E_R/T(0)) = 7.2e10 * exp(-8750/350) = 7.2e10 * 1.389e-11 ≈ 1.0
"""
function cstr_reparametrized()
    # Reparametrized parameters - k0 is eliminated
    @parameters E_R tau Tin Cin dH_rhoCP UA_VrhoCP

    # Input parameters - FIXED
    Tc0_val = 300.0   # mean coolant temp (K)
    Tca_val = 10.0    # coolant oscillation amplitude (K)
    omega_val = 0.5   # frequency

    # States: C (concentration), T (temperature), r_eff (effective rate constant), plus input oscillator
    @variables C(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True parameter values (6 params instead of 7)
    p_true = [
        8750.0,   # E_R: activation energy / gas constant (K)
        1.0,      # tau: residence time (s)
        350.0,    # Tin: inlet temperature (K)
        1.0,      # Cin: inlet concentration (mol/L)
        5.0,      # dH_rhoCP: heat release parameter
        1.0,      # UA_VrhoCP: heat transfer parameter
    ]

    # Initial conditions
    C0 = 0.5    # Initial concentration
    T0 = 350.0  # Initial temperature

    # r_eff(0) = k0 * exp(-E_R / T0)
    # With k0 = 7.2e10 and E_R = 8750, T0 = 350:
    # r_eff(0) = 7.2e10 * exp(-8750/350) = 7.2e10 * exp(-25) ≈ 7.2e10 * 1.389e-11 ≈ 1.0
    k0_original = 7.2e10  # This is now encoded in the IC, not a parameter
    r_eff0 = k0_original * exp(-p_true[1] / T0)

    ic_true = [C0, T0, r_eff0, 0.0, 1.0]  # [C, T, r_eff, u_sin, u_cos]

    # Coolant temperature: Tc(t) = Tc0 + Tca*u_sin
    Tc = Tc0_val + Tca_val * u_sin

    # Reaction rate = r_eff * C (instead of k0 * exp(-E_R/T) * C)
    # This is much simpler!
    reaction_rate = r_eff * C

    equations = [
        # Concentration dynamics: D(C) = (Cin - C)/tau - r_eff*C
        D(C) ~ (Cin - C) / tau - reaction_rate,

        # Temperature dynamics: D(T) = (Tin - T)/tau + dH_rhoCP*r_eff*C - UA_VrhoCP*(T - Tc)
        D(T) ~ (Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc),

        # Effective rate constant dynamics: D(r_eff) = r_eff * (E_R / T^2) * D(T)
        # Note: This still has T^2 in denominator (rational), and E_R appears here
        D(r_eff) ~ r_eff * (E_R / T^2) * ((Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc)),

        # Input oscillator
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # We observe temperature (common measurement) and input
    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [C, T, r_eff, u_sin, u_cos]
    parameters = [E_R, tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_reparametrized", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_reparametrized",
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
                    ALTERNATIVE: EVEN SIMPLER REPARAMETRIZATION

If we also want to eliminate E_R, we need to think about what combinations
are actually identifiable.

One approach: Fix E_R at a known value (activation energies are often
tabulated in chemistry literature), then estimate the remaining 5 params.

Another approach: Use a reference rate at a reference temperature.
=============================================================================#

"""
    cstr_fixed_activation()

CSTR with fixed activation energy E_R (known from chemistry tables).

This further reduces parameters to 5 by fixing E_R at its known value.
Only tau, Tin, Cin, dH_rhoCP, UA_VrhoCP are estimated.

Physical justification: Activation energies are fundamental chemical
properties that can be determined from separate experiments or looked
up in thermodynamic tables.
"""
function cstr_fixed_activation()
    # Parameters to estimate (5 instead of 7)
    @parameters tau Tin Cin dH_rhoCP UA_VrhoCP

    # FIXED activation energy - known from chemistry
    E_R_val = 8750.0  # E/R in Kelvin

    # Input parameters - FIXED
    Tc0_val = 300.0
    Tca_val = 10.0
    omega_val = 0.5

    @variables C(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True parameter values (5 params)
    p_true = [
        1.0,      # tau
        350.0,    # Tin
        1.0,      # Cin
        5.0,      # dH_rhoCP
        1.0,      # UA_VrhoCP
    ]

    C0 = 0.5
    T0 = 350.0
    k0_original = 7.2e10
    r_eff0 = k0_original * exp(-E_R_val / T0)

    ic_true = [C0, T0, r_eff0, 0.0, 1.0]

    Tc = Tc0_val + Tca_val * u_sin
    reaction_rate = r_eff * C

    equations = [
        D(C) ~ (Cin - C) / tau - reaction_rate,
        D(T) ~ (Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc),
        # E_R is now a fixed value, not a parameter
        D(r_eff) ~ r_eff * (E_R_val / T^2) * ((Tin - T) / tau + dH_rhoCP * reaction_rate - UA_VrhoCP * (T - Tc)),
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [C, T, r_eff, u_sin, u_cos]
    parameters = [tau, Tin, Cin, dH_rhoCP, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_fixed_activation", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_fixed_activation",
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
                    COMPARISON OF APPROACHES

| Model                 | Params | States | Notes                        |
|-----------------------|--------|--------|------------------------------|
| cstr_poly (original)  | 7      | 5      | k0=7.2e10, z≈1e-11          |
| cstr_reparametrized   | 6      | 5      | r_eff≈1.0, k0 in IC          |
| cstr_fixed_activation | 5      | 5      | E_R fixed, simplest          |

Key insight: The product k0*exp(-E_R/T) appears in ALL reaction terms.
By making this product a state variable, we:
1. Eliminate k0 as a parameter
2. Improve numerical conditioning (r_eff ≈ 1 instead of z ≈ 1e-11)
3. Reduce the parameter estimation problem complexity

If E_R can also be fixed (from chemistry knowledge), we get an even
simpler system with only 5 parameters.
=============================================================================#
