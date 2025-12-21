#=============================================================================
Control Systems with Time-Varying (Driven) Inputs

This is the DRIVEN version of control_systems.jl where all inputs are
non-trivial, continuous, time-varying signals instead of constants.

Key difference from control_systems.jl:
- Inputs are now functions of time: u(t) = u0 + ua*sin(omega*t) etc.
- Input signal parameters (amplitude, frequency, offset) are model parameters
- All systems remain in PEP format for potential parameter estimation

INPUT SIGNAL CONVENTION:
- _0 suffix: DC offset (e.g., V0, F0)
- _a suffix: amplitude of oscillation (e.g., Va, Fa)
- omega: angular frequency of input oscillation

All inputs are continuous and smooth (no discontinuities).
=============================================================================#

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

#=============================================================================
                            TIER 1: MUST INCLUDE
             Classic control benchmarks with time-varying inputs
=============================================================================#

"""
    dc_motor_driven()

DC motor with sinusoidal voltage input: V(t) = V0 + Va*sin(omega*t)
Represents AC ripple on DC supply or deliberate AC excitation.
"""
function dc_motor_driven()
	parameters = @parameters R L Kb Kt J b V0 Va omega
	# V0: DC voltage offset, Va: AC amplitude, omega: frequency

	states = @variables omega_m(t) i(t)  # omega_m to avoid conflict with omega param

	observables = @variables y1(t)

	p_true = [
		2.0,    # R: armature resistance (Ohms)
		0.5,    # L: armature inductance (H)
		0.1,    # Kb: back-EMF constant
		0.1,    # Kt: torque constant
		0.01,   # J: rotor inertia
		0.1,    # b: viscous friction
		12.0,   # V0: DC voltage offset
		2.0,    # Va: AC voltage amplitude
		5.0,    # omega: input frequency (rad/s)
	]

	ic_true = [0.0, 0.0]

	# Time-varying voltage: V(t) = V0 + Va*sin(omega*t)
	equations = [
		D(omega_m) ~ (Kt * i - b * omega_m) / J,
		D(i) ~ ((V0 + Va * sin(omega * t)) - R * i - Kb * omega_m) / L,
	]

	measured_quantities = [y1 ~ omega_m]

	model, mq = create_ordered_ode_system("dc_motor_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"dc_motor_driven",
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

"""
    mass_spring_damper_driven()

Mass-spring-damper with ramp + sinusoidal force.
F(t) = F0*(1 - exp(-t/tau_r)) + Fa*sin(omega*t)
Represents gradual loading plus vibration excitation.
"""
function mass_spring_damper_driven()
	parameters = @parameters m c k F0 Fa omega tau_r
	# F0: steady-state force, Fa: oscillation amplitude
	# tau_r: ramp time constant, omega: frequency

	states = @variables x(t) v(t)

	observables = @variables y1(t)

	p_true = [
		1.0,    # m: mass
		0.5,    # c: damping
		4.0,    # k: spring constant
		2.0,    # F0: steady force
		1.0,    # Fa: oscillation amplitude
		3.0,    # omega: frequency
		0.5,    # tau_r: ramp time constant
	]

	ic_true = [0.0, 0.0]

	# F(t) = F0*(1 - exp(-t/tau_r)) + Fa*sin(omega*t)
	equations = [
		D(x) ~ v,
		D(v) ~ (F0 * (1 - exp(-t / tau_r)) + Fa * sin(omega * t) - c * v - k * x) / m,
	]

	measured_quantities = [y1 ~ x]

	model, mq = create_ordered_ode_system("mass_spring_damper_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"mass_spring_damper_driven",
		model,
		mq,
		nothing,
		[0.0, 15.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    cart_pole_driven()

Cart-pole with periodic forcing: F(t) = Fa*sin(omega*t)
Represents external disturbance or deliberate excitation for identification.
"""
function cart_pole_driven()
	parameters = @parameters M m l g Fa omega
	# Fa: force amplitude, omega: frequency (no DC offset - centered forcing)

	states = @variables x(t) v(t) theta(t) omega_p(t)  # omega_p for pendulum angular velocity

	observables = @variables y1(t) y2(t)

	p_true = [
		1.0,    # M: cart mass
		0.1,    # m: pendulum mass
		0.5,    # l: pendulum length
		9.81,   # g: gravity
		2.0,    # Fa: force amplitude
		1.5,    # omega: forcing frequency
	]

	# Start near upright with small perturbation
	ic_true = [0.0, 0.0, 0.1, 0.0]

	# F(t) = Fa*sin(omega*t)
	equations = [
		D(x) ~ v,
		D(v) ~ (Fa * sin(omega * t) + m * sin(theta) * (l * omega_p^2 + g * cos(theta))) / (M + m * sin(theta)^2),
		D(theta) ~ omega_p,
		D(omega_p) ~ (-Fa * sin(omega * t) * cos(theta) - m * l * omega_p^2 * cos(theta) * sin(theta) - (M + m) * g * sin(theta)) / (l * (M + m * sin(theta)^2)),
	]

	measured_quantities = [y1 ~ x, y2 ~ theta]

	model, mq = create_ordered_ode_system("cart_pole_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"cart_pole_driven",
		model,
		mq,
		nothing,
		[0.0, 10.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    tank_level_driven()

Tank with oscillating inlet flow: Qin(t) = Q0 + Qa*sin(omega*t)
Represents varying supply pressure or pump modulation.
"""
function tank_level_driven()
	parameters = @parameters A k_out Q0 Qa omega
	# Q0: mean flow, Qa: oscillation amplitude

	states = @variables h(t)

	observables = @variables y1(t)

	p_true = [
		1.0,    # A: tank area
		0.3,    # k_out: outflow coefficient
		0.4,    # Q0: mean inlet flow
		0.15,   # Qa: flow oscillation amplitude
		0.5,    # omega: frequency
	]

	ic_true = [1.0]

	# Qin(t) = Q0 + Qa*sin(omega*t)
	equations = [
		D(h) ~ ((Q0 + Qa * sin(omega * t)) - k_out * sqrt(h)) / A,
	]

	measured_quantities = [y1 ~ h]

	model, mq = create_ordered_ode_system("tank_level_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"tank_level_driven",
		model,
		mq,
		nothing,
		[0.0, 30.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

#=============================================================================
                         TIER 2: HIGHLY RECOMMENDED
=============================================================================#

"""
    cstr_driven()

CSTR with oscillating coolant temperature: Tc(t) = Tc0 + Tca*sin(omega*t)
Represents cyclic cooling or periodic disturbance.
"""
function cstr_driven()
	parameters = @parameters k0 E_R tau Tin Cin dH_rhoCP UA_VrhoCP Tc0 Tca omega
	# Tc0: mean coolant temp, Tca: oscillation amplitude

	states = @variables C(t) T(t)

	observables = @variables y1(t)

	p_true = [
		7.2e10,   # k0: pre-exponential
		8750.0,   # E_R: E/R
		1.0,      # tau: residence time
		350.0,    # Tin: inlet temperature
		1.0,      # Cin: inlet concentration
		5.0,      # dH_rhoCP: heat release
		1.0,      # UA_VrhoCP: heat transfer
		300.0,    # Tc0: mean coolant temp
		10.0,     # Tca: coolant oscillation amplitude
		0.5,      # omega: frequency
	]

	ic_true = [0.5, 350.0]

	# Tc(t) = Tc0 + Tca*sin(omega*t)
	equations = [
		D(C) ~ (Cin - C) / tau - k0 * exp(-E_R / T) * C,
		D(T) ~ (Tin - T) / tau + dH_rhoCP * k0 * exp(-E_R / T) * C - UA_VrhoCP * (T - (Tc0 + Tca * sin(omega * t))),
	]

	measured_quantities = [y1 ~ T]

	model, mq = create_ordered_ode_system("cstr_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"cstr_driven",
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

"""
    quadrotor_altitude_driven()

Quadrotor with thrust oscillating around hover: T(t) = m*g + Ta*sin(omega*t)
Represents altitude control maneuvers or disturbance rejection.
"""
function quadrotor_altitude_driven()
	parameters = @parameters m g d Ta omega
	# Ta: thrust oscillation amplitude around hover (m*g)

	states = @variables z(t) w(t)

	observables = @variables y1(t)

	p_true = [
		1.0,     # m: mass
		9.81,    # g: gravity
		0.1,     # d: drag
		2.0,     # Ta: thrust oscillation amplitude
		1.0,     # omega: frequency
	]

	ic_true = [5.0, 0.0]  # Start at 5m altitude

	# T(t) = m*g + Ta*sin(omega*t) (hover + oscillation)
	equations = [
		D(z) ~ w,
		D(w) ~ ((m * g + Ta * sin(omega * t)) - m * g - d * w) / m,  # Simplifies to Ta*sin/m - d*w/m
	]

	measured_quantities = [y1 ~ z]

	model, mq = create_ordered_ode_system("quadrotor_altitude_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"quadrotor_altitude_driven",
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

"""
    thermal_system_driven()

Room temperature with day/night heating cycle: Q(t) = Q0*(1 + Qa_rel*sin(omega*t))
Represents diurnal HVAC operation.
"""
function thermal_system_driven()
	parameters = @parameters C_th R_th Ta Q0 Qa_rel omega
	# Q0: mean heating, Qa_rel: relative amplitude (0 to 1)

	states = @variables T(t)

	observables = @variables y1(t)

	p_true = [
		1000.0,   # C_th: thermal capacitance
		0.01,     # R_th: thermal resistance
		293.0,    # Ta: ambient (20°C)
		500.0,    # Q0: mean heater power
		0.5,      # Qa_rel: 50% modulation
		0.001,    # omega: slow cycle (~100 min period)
	]

	ic_true = [288.0]  # Start at 15°C

	# Q(t) = Q0*(1 + Qa_rel*sin(omega*t))
	equations = [
		D(T) ~ (Q0 * (1 + Qa_rel * sin(omega * t)) - (T - Ta) / R_th) / C_th,
	]

	measured_quantities = [y1 ~ T]

	model, mq = create_ordered_ode_system("thermal_system_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"thermal_system_driven",
		model,
		mq,
		nothing,
		[0.0, 5000.0],  # Long time for slow thermal dynamics
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    ball_beam_driven()

Ball-beam with sinusoidal beam torque: tau(t) = tau_a*sin(omega*t)
Represents periodic actuation for system identification.
"""
function ball_beam_driven()
	parameters = @parameters m_ball R_ball J_beam g tau_a omega
	# tau_a: torque amplitude

	states = @variables r(t) rdot(t) theta(t) omega_b(t)  # omega_b for beam

	observables = @variables y1(t) y2(t)

	p_true = [
		0.1,     # m_ball
		0.02,    # R_ball
		0.5,     # J_beam
		9.81,    # g
		0.1,     # tau_a: torque amplitude
		2.0,     # omega: frequency
	]

	ic_true = [0.1, 0.0, 0.0, 0.0]

	# tau(t) = tau_a*sin(omega*t)
	equations = [
		D(r) ~ rdot,
		D(rdot) ~ (5.0 / 7.0) * g * sin(theta) - r * omega_b^2,
		D(theta) ~ omega_b,
		D(omega_b) ~ (tau_a * sin(omega * t) - m_ball * g * r * cos(theta)) / J_beam,
	]

	measured_quantities = [y1 ~ r, y2 ~ theta]

	model, mq = create_ordered_ode_system("ball_beam_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"ball_beam_driven",
		model,
		mq,
		nothing,
		[0.0, 10.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

#=============================================================================
                          TIER 3: GOOD TO INCLUDE
=============================================================================#

"""
    bicycle_model_driven()

Vehicle with sinusoidal steering: delta(t) = delta_a*sin(omega*t)
Represents lane change or slalom maneuver.
"""
function bicycle_model_driven()
	parameters = @parameters Cf Cr m_veh Iz lf lr Vx delta_a omega
	# delta_a: steering amplitude

	states = @variables vy(t) r(t)

	observables = @variables y1(t) y2(t)

	p_true = [
		80000.0,   # Cf
		80000.0,   # Cr
		1500.0,    # m_veh
		2500.0,    # Iz
		1.2,       # lf
		1.4,       # lr
		20.0,      # Vx
		0.05,      # delta_a: steering amplitude (~3 deg)
		0.5,       # omega: frequency
	]

	ic_true = [0.0, 0.0]

	# delta(t) = delta_a*sin(omega*t)
	equations = [
		D(vy) ~ (Cf * (delta_a * sin(omega * t) - (vy + lf * r) / Vx) + Cr * (-(vy - lr * r) / Vx)) / m_veh - Vx * r,
		D(r) ~ (lf * Cf * (delta_a * sin(omega * t) - (vy + lf * r) / Vx) - lr * Cr * (-(vy - lr * r) / Vx)) / Iz,
	]

	measured_quantities = [y1 ~ r, y2 ~ vy]

	model, mq = create_ordered_ode_system("bicycle_model_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"bicycle_model_driven",
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

"""
    swing_equation_driven()

Generator with fluctuating mechanical power: Pm(t) = Pm0 + Pma*sin(omega*t)
Represents load variation or renewable intermittency.
"""
function swing_equation_driven()
	parameters = @parameters H D_damp Pmax omega_s Pm0 Pma omega
	# Pm0: mean power, Pma: oscillation amplitude

	states = @variables delta(t) Delta_omega(t)

	observables = @variables y1(t)

	p_true = [
		5.0,      # H: inertia constant
		1.0,      # D_damp: damping
		1.0,      # Pmax: max sync power
		377.0,    # omega_s: sync speed (60 Hz)
		0.8,      # Pm0: mean mechanical power
		0.1,      # Pma: power oscillation amplitude
		0.5,      # omega: disturbance frequency
	]

	ic_true = [0.927, 0.0]

	# Pm(t) = Pm0 + Pma*sin(omega*t)
	equations = [
		D(delta) ~ Delta_omega,
		D(Delta_omega) ~ (omega_s / (2 * H)) * ((Pm0 + Pma * sin(omega * t)) - Pmax * sin(delta) - D_damp * Delta_omega),
	]

	measured_quantities = [y1 ~ Delta_omega]

	model, mq = create_ordered_ode_system("swing_equation_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"swing_equation_driven",
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

"""
    magnetic_levitation_driven()

Linearized maglev with AC voltage ripple: V(t) = V0 + Va*sin(omega*t)
Uses linearized model around equilibrium for numerical stability.
The nonlinear maglev is inherently unstable without feedback control.

Linearized dynamics represent deviations from equilibrium position.
"""
function magnetic_levitation_driven()
	# Linearized model: mass on a spring with electromagnetic actuation
	# x = deviation from equilibrium, v = velocity, i = current
	parameters = @parameters m_lin k_lin b_lin R_coil L ki V0 Va omega
	# k_lin: effective spring constant (from linearization)
	# b_lin: damping, ki: current-to-force gain

	states = @variables x(t) v(t) i(t)

	observables = @variables y1(t)

	p_true = [
		0.1,    # m_lin: effective mass
		50.0,   # k_lin: linearized stiffness (stabilizing)
		2.0,    # b_lin: damping coefficient
		2.0,    # R_coil: coil resistance
		0.05,   # L: inductance
		10.0,   # ki: current-to-force gain
		5.0,    # V0: DC voltage (sets equilibrium current)
		1.0,    # Va: AC amplitude
		5.0,    # omega: frequency
	]

	# Equilibrium: i0 = V0/R = 2.5A, x0 = 0
	ic_true = [0.0, 0.0, 2.5]

	# V(t) = V0 + Va*sin(omega*t)
	# Linearized force: F = ki*(i - i0) - k_lin*x - b_lin*v
	equations = [
		D(x) ~ v,
		D(v) ~ (ki * (i - V0 / R_coil) - k_lin * x - b_lin * v) / m_lin,
		D(i) ~ ((V0 + Va * sin(omega * t)) - R_coil * i) / L,
	]

	measured_quantities = [y1 ~ x]

	model, mq = create_ordered_ode_system("magnetic_levitation_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"magnetic_levitation_driven",
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

"""
    aircraft_pitch_driven()

Aircraft with sinusoidal elevator input: delta_e(t) = delta_e0 + delta_ea*sin(omega*t)
Represents pilot stick input or autopilot command.
"""
function aircraft_pitch_driven()
	parameters = @parameters M_alpha M_q M_delta_e Z_alpha V_air delta_e0 delta_ea omega
	# delta_e0: trim deflection, delta_ea: oscillation amplitude

	states = @variables theta(t) q(t) alpha(t)

	observables = @variables y1(t)

	p_true = [
		-5.0,     # M_alpha
		-2.0,     # M_q
		-10.0,    # M_delta_e
		-0.5,     # Z_alpha
		50.0,     # V_air
		0.0,      # delta_e0: trim (level flight)
		0.05,     # delta_ea: elevator amplitude
		2.0,      # omega: frequency
	]

	ic_true = [0.0, 0.0, 0.05]

	# delta_e(t) = delta_e0 + delta_ea*sin(omega*t)
	equations = [
		D(theta) ~ q,
		D(q) ~ M_alpha * alpha + M_q * q + M_delta_e * (delta_e0 + delta_ea * sin(omega * t)),
		D(alpha) ~ Z_alpha * alpha / V_air + q,
	]

	measured_quantities = [y1 ~ q]

	model, mq = create_ordered_ode_system("aircraft_pitch_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"aircraft_pitch_driven",
		model,
		mq,
		nothing,
		[0.0, 10.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

#=============================================================================
                         TIER 4: ADDITIONAL SYSTEMS
=============================================================================#

"""
    two_tank_driven()

Two-tank with oscillating inlet: Qin(t) = Q0 + Qa*sin(omega*t)
"""
function two_tank_driven()
	parameters = @parameters A1 A2 k1 k2 k12 Q0 Qa omega

	states = @variables h1(t) h2(t)

	observables = @variables y1(t) y2(t)

	p_true = [
		1.0,     # A1
		1.0,     # A2
		0.3,     # k1
		0.3,     # k2
		0.2,     # k12
		0.5,     # Q0: mean flow
		0.2,     # Qa: oscillation
		0.3,     # omega
	]

	ic_true = [1.0, 0.5]

	# Qin(t) = Q0 + Qa*sin(omega*t)
	equations = [
		D(h1) ~ ((Q0 + Qa * sin(omega * t)) - k1 * sqrt(h1) - k12 * sqrt(h1 - h2 + 0.01)) / A1,
		D(h2) ~ (k12 * sqrt(h1 - h2 + 0.01) - k2 * sqrt(h2)) / A2,
	]

	measured_quantities = [y1 ~ h1, y2 ~ h2]

	model, mq = create_ordered_ode_system("two_tank_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"two_tank_driven",
		model,
		mq,
		nothing,
		[0.0, 50.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    boost_converter_driven()

Boost converter with modulated duty cycle: d(t) = d0 + da*sin(omega*t)
Represents PWM modulation or load following.
"""
function boost_converter_driven()
	parameters = @parameters L C_cap R_load Vin d0 da omega
	# d0: mean duty, da: modulation amplitude

	states = @variables iL(t) vC(t)

	observables = @variables y1(t)

	p_true = [
		0.001,   # L
		0.001,   # C_cap
		10.0,    # R_load
		12.0,    # Vin
		0.5,     # d0: mean duty
		0.1,     # da: modulation amplitude
		100.0,   # omega: switching-related frequency
	]

	ic_true = [1.0, 24.0]

	# d(t) = d0 + da*sin(omega*t), d' = 1 - d
	equations = [
		D(iL) ~ (Vin - (1 - (d0 + da * sin(omega * t))) * vC) / L,
		D(vC) ~ ((1 - (d0 + da * sin(omega * t))) * iL - vC / R_load) / C_cap,
	]

	measured_quantities = [y1 ~ vC]

	model, mq = create_ordered_ode_system("boost_converter_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"boost_converter_driven",
		model,
		mq,
		nothing,
		[0.0, 0.5],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    flexible_arm_driven()

Flexible arm with ramp + sinusoidal torque: tau(t) = tau0*(1-exp(-t/tau_r)) + tau_a*sin(omega*t)
Represents motion command with vibration excitation.
"""
function flexible_arm_driven()
	parameters = @parameters Jm Jt bm bt k_stiff tau0 tau_a tau_r omega
	# tau0: final torque, tau_a: oscillation, tau_r: ramp time constant

	states = @variables theta_m(t) omega_m(t) theta_t(t) omega_t(t)

	observables = @variables y1(t) y2(t)

	p_true = [
		0.1,     # Jm
		0.05,    # Jt
		0.1,     # bm
		0.05,    # bt
		10.0,    # k_stiff
		0.5,     # tau0: steady torque
		0.1,     # tau_a: oscillation amplitude
		0.5,     # tau_r: ramp time constant
		5.0,     # omega: vibration frequency
	]

	ic_true = [0.0, 0.0, 0.0, 0.0]

	# tau(t) = tau0*(1-exp(-t/tau_r)) + tau_a*sin(omega*t)
	equations = [
		D(theta_m) ~ omega_m,
		D(omega_m) ~ (tau0 * (1 - exp(-t / tau_r)) + tau_a * sin(omega * t) - bm * omega_m - k_stiff * (theta_m - theta_t)) / Jm,
		D(theta_t) ~ omega_t,
		D(omega_t) ~ (-bt * omega_t - k_stiff * (theta_t - theta_m)) / Jt,
	]

	measured_quantities = [y1 ~ theta_m, y2 ~ theta_t]

	model, mq = create_ordered_ode_system("flexible_arm_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"flexible_arm_driven",
		model,
		mq,
		nothing,
		[0.0, 10.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    bilinear_system_driven()

Generic bilinear with sinusoidal input: u(t) = u0 + ua*sin(omega*t)
"""
function bilinear_system_driven()
	parameters = @parameters a11 a12 a21 a22 b1 b2 n1 n2 u0 ua omega

	states = @variables x1(t) x2(t)

	observables = @variables y1(t)

	p_true = [
		-0.5,    # a11
		0.2,     # a12
		0.1,     # a21
		-0.3,    # a22
		1.0,     # b1
		0.5,     # b2
		0.2,     # n1
		0.1,     # n2
		1.0,     # u0: mean input
		0.5,     # ua: oscillation
		2.0,     # omega
	]

	ic_true = [1.0, 0.5]

	# u(t) = u0 + ua*sin(omega*t)
	equations = [
		D(x1) ~ a11 * x1 + a12 * x2 + b1 * (u0 + ua * sin(omega * t)) + n1 * x1 * (u0 + ua * sin(omega * t)),
		D(x2) ~ a21 * x1 + a22 * x2 + b2 * (u0 + ua * sin(omega * t)) + n2 * x2 * (u0 + ua * sin(omega * t)),
	]

	measured_quantities = [y1 ~ x1]

	model, mq = create_ordered_ode_system("bilinear_system_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"bilinear_system_driven",
		model,
		mq,
		nothing,
		[0.0, 15.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end

"""
    forced_lotka_volterra_driven()

Lotka-Volterra with seasonal harvesting: u(t) = u0*(1 + ua_rel*sin(omega*t))
Represents seasonal fishing quotas or pest control cycles.
"""
function forced_lotka_volterra_driven()
	parameters = @parameters a b c d_pred u0 ua_rel omega
	# u0: mean stocking/harvest, ua_rel: relative seasonal variation

	states = @variables prey(t) predator(t)

	observables = @variables y1(t)

	p_true = [
		1.0,     # a: prey growth
		0.5,     # b: predation
		0.5,     # c: predator death
		0.25,    # d_pred: predator efficiency
		0.2,     # u0: mean input
		0.5,     # ua_rel: 50% seasonal variation
		0.5,     # omega: seasonal frequency
	]

	ic_true = [2.0, 1.0]

	# u(t) = u0*(1 + ua_rel*sin(omega*t))
	equations = [
		D(prey) ~ a * prey - b * prey * predator + u0 * (1 + ua_rel * sin(omega * t)),
		D(predator) ~ -c * predator + d_pred * prey * predator,
	]

	measured_quantities = [y1 ~ prey]

	model, mq = create_ordered_ode_system("forced_lotka_volterra_driven", states, parameters, equations, measured_quantities)

	return ParameterEstimationProblem(
		"forced_lotka_volterra_driven",
		model,
		mq,
		nothing,
		[0.0, 50.0],
		nothing,
		OrderedDict(parameters .=> p_true),
		OrderedDict(states .=> ic_true),
		0,
	)
end
