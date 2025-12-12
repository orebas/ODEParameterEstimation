"""
CSTR model with adiabatic temperature rise (ΔT_ad) and FIXED inlet temperature.

This formulation:
1. Uses ΔT_ad = Cin × dH_rhoCP as a combined parameter (identifiable)
2. Fixes Tin as a known/measured input (standard experimental practice)
3. Results in 4 unknown parameters instead of 5

Fixing Tin is justified because:
- Inlet temperature is typically a controlled/measured quantity in experiments
- Removing it from estimation improves numerical conditioning
- This is standard practice in experiment-based parameter estimation
"""

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

"""
    cstr_adiabatic_fixed_tin()

CSTR model with dimensionless concentration, adiabatic temperature rise,
and fixed inlet temperature.

Parameters (4 total):
- E_R: Activation energy / gas constant (K)
- tau: Residence time (s)
- Delta_T_ad: Adiabatic temperature rise = Cin × (-ΔH)/(ρCp) (K)
- UA_VrhoCP: Heat transfer coefficient parameter (1/s)

Fixed constants:
- Tin = 350.0 K (inlet temperature - measured/controlled input)
- Tc0 = 300.0 K (mean coolant temperature)
- Tca = 10.0 K (coolant oscillation amplitude)
- omega = 0.5 rad/s (oscillation frequency)

States:
- c: Dimensionless concentration C/Cin (ranges 0 to 1)
- T: Temperature (K)
- r_eff: Effective reaction rate parameter (1/s)
- u_sin, u_cos: Oscillator for coolant temperature variation

Observables:
- y1 = T (temperature measurement)
- y2 = u_sin, y3 = u_cos (known input oscillator)
"""
function cstr_adiabatic_fixed_tin()
    # Parameters - now 4 (Tin is fixed as literal 350.0 in equations)
    @parameters E_R tau Delta_T_ad UA_VrhoCP

    # States
    @variables c(t) T(t) r_eff(t) u_sin(t) u_cos(t)
    @variables y1(t) y2(t) y3(t)

    # True parameter values (4 parameters)
    p_true = [
        8750.0,   # E_R: activation energy / gas constant (K)
        1.0,      # tau: residence time (s)
        5.0,      # Delta_T_ad: adiabatic temperature rise (K)
        1.0,      # UA_VrhoCP: heat transfer parameter (1/s)
    ]

    # Initial conditions
    ic_true = [0.5, 350.0, 7.2e10 * exp(-8750.0 / 350.0), 0.0, 1.0]

    # All constants hardcoded directly in equations:
    # Tin = 350.0, Tc0 = 300.0, Tca = 10.0, omega = 0.5

    equations = [
        # Dimensionless concentration dynamics
        D(c) ~ (1 - c) / tau - r_eff * c,

        # Temperature dynamics: Tin=350, Tc = 300 + 10*u_sin
        D(T) ~ (350.0 - T) / tau + Delta_T_ad * r_eff * c - UA_VrhoCP * (T - (300.0 + 10.0 * u_sin)),

        # Effective rate constant dynamics
        D(r_eff) ~ r_eff * (E_R / T^2) * ((350.0 - T) / tau + Delta_T_ad * r_eff * c - UA_VrhoCP * (T - (300.0 + 10.0 * u_sin))),

        # Input oscillator: omega = 0.5
        D(u_sin) ~ 0.5 * u_cos,
        D(u_cos) ~ -0.5 * u_sin,
    ]

    # Observables: temperature and the known input oscillator
    measured_quantities = [y1 ~ T, y2 ~ u_sin, y3 ~ u_cos]

    states = [c, T, r_eff, u_sin, u_cos]
    parameters = [E_R, tau, Delta_T_ad, UA_VrhoCP]

    model, mq = create_ordered_ode_system("cstr_adiabatic_fixed_tin", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "cstr_adiabatic_fixed_tin",
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
