"""
CSTR model with adiabatic temperature rise (ΔT_ad) as a combined parameter.

This formulation addresses the structural unidentifiability of the original CSTR model
where Cin and dH_rhoCP are individually unidentifiable, but their product
ΔT_ad = Cin × dH_rhoCP (the adiabatic temperature rise) is identifiable.

We use dimensionless concentration c = C/Cin, which:
1. Eliminates Cin from the equations
2. Makes ΔT_ad appear naturally in the temperature equation
3. Results in a fully identifiable parameterization (5 parameters instead of 6)

Physical interpretation of ΔT_ad:
- The maximum temperature increase if all inlet reactant were converted
- With no heat removal (adiabatic conditions)
- A standard quantity in chemical reactor design and safety analysis
"""

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

"""
    cstr_adiabatic()

CSTR model using dimensionless concentration and adiabatic temperature rise.

Parameters (5 total, all identifiable):
- E_R: Activation energy / gas constant (K)
- tau: Residence time (s)
- Tin: Inlet temperature (K)
- Delta_T_ad: Adiabatic temperature rise = Cin × (-ΔH)/(ρCp) (K)
- UA_VrhoCP: Heat transfer coefficient parameter (1/s)

States:
- c: Dimensionless concentration C/Cin (ranges 0 to 1)
- T: Temperature (K)
- r_eff: Effective reaction rate parameter (1/s)
- u_sin, u_cos: Oscillator for coolant temperature variation

Observables:
- y1 = T (temperature measurement)
- y2 = u_sin, y3 = u_cos (known input oscillator)
"""
function cstr_adiabatic()
    # Parameters - now 5 instead of 6, all should be identifiable
    @parameters E_R tau Tin Delta_T_ad UA_VrhoCP

    # Input parameters - FIXED (known from experimental setup)
    Tc0_val = 300.0   # Mean coolant temperature (K)
    Tca_val = 10.0    # Coolant oscillation amplitude (K)
    omega_val = 0.5   # Oscillation frequency (rad/s)

    # States: c (dimensionless concentration), T (temperature), r_eff (effective rate), oscillator
    @variables c(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True parameter values
    # Original: Cin = 1.0 mol/L, dH_rhoCP = 5.0 K·L/mol
    # Combined: Delta_T_ad = Cin × dH_rhoCP = 5.0 K
    p_true = [
        8750.0,   # E_R: activation energy / gas constant (K)
        1.0,      # tau: residence time (s)
        350.0,    # Tin: inlet temperature (K)
        5.0,      # Delta_T_ad: adiabatic temperature rise (K)
        1.0,      # UA_VrhoCP: heat transfer parameter (1/s)
    ]

    # Initial conditions
    c0 = 0.5    # Dimensionless concentration (was C0/Cin = 0.5/1.0)
    T0 = 350.0  # Initial temperature (K)

    # r_eff(0) = k0 * exp(-E_R / T0)
    # With k0 = 7.2e10 and E_R = 8750, T0 = 350:
    k0_original = 7.2e10
    r_eff0 = k0_original * exp(-p_true[1] / T0)

    ic_true = [c0, T0, r_eff0, 0.0, 1.0]  # [c, T, r_eff, u_sin, u_cos]

    # Coolant temperature: Tc(t) = Tc0 + Tca * u_sin
    Tc = Tc0_val + Tca_val * u_sin

    # Reaction rate (dimensionless concentration × rate constant)
    reaction_rate = r_eff * c

    # Heat generation term: ΔT_ad × r_eff × c
    # This is the key simplification - no separate Cin or dH_rhoCP
    heat_generation = Delta_T_ad * reaction_rate

    equations = [
        # Dimensionless concentration dynamics
        # D(c) = (1 - c)/tau - r_eff × c
        # (derived from D(C) = (Cin - C)/tau - r_eff×C, dividing by Cin)
        D(c) ~ (1 - c) / tau - reaction_rate,

        # Temperature dynamics
        # D(T) = (Tin - T)/tau + ΔT_ad × r_eff × c - UA_VrhoCP × (T - Tc)
        D(T) ~ (Tin - T) / tau + heat_generation - UA_VrhoCP * (T - Tc),

        # Effective rate constant dynamics (chain rule on k0×exp(-E_R/T))
        D(r_eff) ~ r_eff * (E_R / T^2) * ((Tin - T) / tau + heat_generation - UA_VrhoCP * (T - Tc)),

        # Input oscillator (models time-varying coolant temperature)
        D(u_sin) ~ omega_val * u_cos,
        D(u_cos) ~ -omega_val * u_sin,
    ]

    # Observables: temperature and the known input oscillator
    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [c, T, r_eff, u_sin, u_cos]
    parameters = [E_R, tau, Tin, Delta_T_ad, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_adiabatic", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_adiabatic",
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
