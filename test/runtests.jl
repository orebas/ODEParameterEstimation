using ODEParameterEstimation
using Test
using ModelingToolkit
using HomotopyContinuation
using DifferentialEquations
using OrderedCollections
#using ParameterEstimation



struct ParameterEstimationProblem
	Name::Any
	model::Any
	measured_quantities::Any
	data_sample::Any
	solver::Any
	p_true::Any
	ic::Any
	unident_count::Any
end

function fillPEP(pe::ParameterEstimationProblem; datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())
	return ParameterEstimationProblem(
		pe.Name,
		complete(pe.model),
		pe.measured_quantities,
		sample_data(pe.model, pe.measured_quantities, time_interval, pe.p_true, pe.ic, datasize, solver = solver),
		solver,
		pe.p_true,
		pe.ic,
		pe.unident_count)

	return pe
end


function biohydrogenation()
	@parameters k5 k6 k7 k8 k9 k10
	@variables t x4(t) x5(t) x6(t) x7(t) y1(t) y2(t)
	D = Differential(t)
	states = [x4, x5, x6, x7]
	parameters = [k5, k6, k7, k8, k9, k10]

	@named model = ODESystem([
			D(x4) ~ -k5 * x4 / (k6 + x4),
			D(x5) ~ k5 * x4 / (k6 + x4) - k7 * x5 / (k8 + x5 + x6),
			D(x6) ~ k7 * x5 / (k8 + x5 + x6) - k9 * x6 * (k10 - x6) / k10,
			D(x7) ~ k9 * x6 * (k10 - x6) / k10,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x4,
		y2 ~ x5,
	]

	ic = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.143, 0.286, 0.429, 0.571, 0.714, 0.857]
	return ParameterEstimationProblem("BioHydrogenation",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 1)
end

function crauste()
	@parameters mu_N mu_EE mu_LE mu_LL mu_M mu_P mu_PE mu_PL delta_NE delta_EL delta_LM rho_E rho_P
	@variables t N(t) E(t) S(t) M(t) P(t) y1(t) y2(t) y3(t) y4(t)
	D = Differential(t)
	states = [N, E, S, M, P]
	parameters = [
		mu_N,
		mu_EE,
		mu_LE,
		mu_LL,
		mu_M,
		mu_P,
		mu_PE,
		mu_PL,
		delta_NE,
		delta_EL,
		delta_LM,
		rho_E,
		rho_P,
	]
	@named model = ODESystem(
		[
			D(N) ~ -N * mu_N - N * P * delta_NE,
			D(E) ~ N * P * delta_NE - E^2 * mu_EE -
				   E * delta_EL + E * P * rho_E,
			D(S) ~ S * delta_EL - S * delta_LM - S^2 * mu_LL -
				   E * S * mu_LE,
			D(M) ~ S * delta_LM - mu_M * M,
			D(P) ~ P^2 * rho_P - P * mu_P - E * P * mu_PE -
				   S * P * mu_PL,
		], t, states, parameters)
	measured_quantities = [y1 ~ N, y2 ~ E, y3 ~ S + M, y4 ~ P]

	ic = [0.167, 0.333, 0.5, 0.667, 0.833]
	p_true = [
		0.071,
		0.143,
		0.214,
		0.286,
		0.357,
		0.429,
		0.5,
		0.571,
		0.643,
		0.714,
		0.786,
		0.857,
		0.929,
	] # True Parameters

	return ParameterEstimationProblem("Crauste",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function daisy_ex3()
	@parameters p1 p3 p4 p6 p7
	@variables t x1(t) x2(t) x3(t) u0(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3, u0]
	parameters = [p1, p3, p4, p6, p7]
	@named model = ODESystem([
			D(x1) ~ -1.0 * p1 * x1 + x2 + u0,
			D(x2) ~ p3 * x1 - p4 * x2 + x3,
			D(x3) ~ p6 * x1 - p7 * x3,
			D(u0) ~ 1.0,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ u0,
	]

	ic = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833] # True Parameters


	return ParameterEstimationProblem("DAISY_ex3",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end



function daisy_ex3_v2()
	@parameters p1 p3 p4 p6 p7
	@variables t x1(t) x2(t) x3(t) u0(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3, u0]
	parameters = [p1, p3, p4, p6, p7]
	@named model = ODESystem([
			D(x1) ~ -1.0 * p1 * x1 + x2 + u0,
			D(x2) ~ p3 * x1 - p4 * x2 + x3,
			D(x3) ~ p6 * x1 - p7 * x3,
			D(u0) ~ 1.0,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ u0,
	]

	ic = [1.0, 2.0, 1.0, 1.0]
	p_true = [0.2, 0.3, 0.5, 0.6, -0.2] # True Parameters



	return ParameterEstimationProblem("DAISY_ex3_v2",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end



function daisy_ex3_v3()
	@parameters p1 p3 p4 p6 p7 pd
	@variables t x1(t) x2(t) x3(t) u0(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3, u0]
	parameters = [p1, p3, p4, p6, p7, pd]
	@named model = ODESystem([
			D(x1) ~ x2 + u0 - p1 * x1,
			D(x2) ~ p3 * x1 - p4 * x2 + x3,
			D(x3) ~ p6 * x1 - p7 * x3,
			D(u0) ~ pd,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ u0,
	]

	ic = [1.0, 2.0, 1.0, 1.0]
	p_true = [0.2, 0.3, 0.5, 0.6, -0.2, 1.0] # True Parameters

	return ParameterEstimationProblem("DAISY_ex3_v3",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end



function daisy_ex3_v4()
	@parameters p1 p3 p4 p6 p7 pd
	@variables t x1(t) x2(t) x3(t) u0(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3, u0]
	parameters = [p1, p3, p4, p6, p7, pd]
	@named model = ODESystem([
			D(x1) ~ x2 + u0 - p1 * x1,
			D(x2) ~ p3 * x1 - p4 * x2 + x3,
			D(x3) ~ p6 * x1 - p7 * x3,
			D(u0) ~ pd,
		], t, states, parameters)
	measured_quantities = [y1 ~ x1 + x3, y2 ~ x2]


	ic = [1.0, 2.0, 1.0, 1.0]
	p_true = [0.2, 0.3, 0.5, 0.6, -0.2, 1.0] # True Parameters

	return ParameterEstimationProblem("DAISY_ex3_v4",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end






function daisy_mamil3(datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())
	@parameters a12 a13 a21 a31 a01
	@variables t x1(t) x2(t) x3(t) y1(t) y2(t)
	D = Differential(t)

	ic = [0.25, 0.5, 0.75]
	sampling_times = range(time_interval[1], time_interval[2], length = datasize)
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833] # True Parameters

	states = [x1, x2, x3]
	parameters = [a12, a13, a21, a31, a01]
	@named model = ODESystem([D(x1) ~ -(a21 + a31 + a01) * x1 + a12 * x2 + a13 * x3,
			D(x2) ~ a21 * x1 - a12 * x2,
			D(x3) ~ a31 * x1 - a13 * x3],
		t, states, parameters)
	measured_quantities = [y1 ~ x1, y2 ~ x2]


	return ParameterEstimationProblem("DAISY_mamil3",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function daisy_mamil4(datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())
	@parameters k01, k12, k13, k14, k21, k31, k41
	@variables t x1(t) x2(t) x3(t) x4(t) y1(t) y2(t) y3(t)
	D = Differential(t)

	ic = [0.2, 0.4, 0.6, 0.8]
	sampling_times = range(time_interval[1], time_interval[2], length = datasize)
	p_true = [0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875] # True Parameters

	states = [x1, x2, x3, x4]
	parameters = [k01, k12, k13, k14, k21, k31, k41]
	@named model = ODESystem([
			D(x1) ~ -k01 * x1 + k12 * x2 + k13 * x3 + k14 * x4 - k21 * x1 - k31 * x1 -
					k41 * x1,
			D(x2) ~ -k12 * x2 + k21 * x1,
			D(x3) ~ -k13 * x3 + k31 * x1,
			D(x4) ~ -k14 * x4 + k41 * x1],
		t, states, parameters)
	measured_quantities = [y1 ~ x1, y2 ~ x2, y3 ~ x3 + x4]


	return ParameterEstimationProblem("DAISY_mamil4",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function fitzhugh_nagumo()
	@parameters g a b
	@variables t V(t) R(t) y1(t) y2(t)
	D = Differential(t)
	states = [V, R]
	parameters = [g, a, b]

	ic = [0.333, 0.67]
	#sampling_times = range(time_interval[1], time_interval[2], length = datasize)
	p_true = [0.25, 0.5, 0.75] # True Parameters
	measured_quantities = [y1 ~ V]

	@named model = ODESystem([
			D(V) ~ g * (V - V^3 / 3 + R),
			D(R) ~ 1 / g * (V - a + b * R),
		], t, states, parameters)

	return ParameterEstimationProblem("fitzhugh-nagumo",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function hiv_local()
	@parameters b c d k1 k2 mu1 mu2 q1 q2 s
	@variables t x1(t) x2(t) x3(t) x4(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3, x4]
	parameters = [b, c, d, k1, k2, mu1, mu2, q1, q2, s]

	@named model = ODESystem([
			D(x1) ~ -b * x1 * x4 - d * x1 + s,
			D(x2) ~ b * q1 * x1 * x4 - k1 * x2 - mu1 * x2,
			D(x3) ~ b * q2 * x1 * x4 + k1 * x2 - mu2 * x3,
			D(x4) ~ -c * x4 + k2 * x3,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x4,
	]

	ic = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.091, 0.182, 0.273, 0.364, 0.455, 0.545, 0.636, 0.727, 0.818, 0.909]
	time_interval = [-0.5, 0.5]
	datasize = 20

	return ParameterEstimationProblem("hiv_local",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 7)
end

function hiv()
	@parameters lm d beta a k u c q b h
	@variables t x(t) y(t) v(t) w(t) z(t) y1(t) y2(t) y3(t) y4(t)
	D = Differential(t)
	states = [x, y, v, w, z]
	parameters = [lm, d, beta, a, k, u, c, q, b, h]

	@named model = ODESystem([
			D(x) ~ lm - d * x - beta * x * v,
			D(y) ~ beta * x * v - a * y,
			D(v) ~ k * y - u * v,
			D(w) ~ c * x * y * w - c * q * y * w - b * w,
			D(z) ~ c * q * y * w - h * z,
		], t, states, parameters)
	measured_quantities = [y1 ~ w, y2 ~ z, y3 ~ x, y4 ~ y + v]

	ic = [0.167, 0.333, 0.5, 0.667, 0.833]
	p_true = [0.091, 0.181, 0.273, 0.364, 0.455, 0.545, 0.636, 0.727, 0.818, 0.909]


	return ParameterEstimationProblem("hiv",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function lotka_volterra()
	@parameters k1 k2 k3
	@variables t r(t) w(t) y1(t)
	D = Differential(t)
	ic = [0.333, 0.667]
	p_true = [0.25, 0.5, 0.75] # True Parameters
	measured_quantities = [y1 ~ r]
	states = [r, w]
	parameters = [k1, k2, k3]

	@named model = ODESystem([
			D(r) ~ k1 * r - k2 * r * w,
			D(w) ~ k2 * r * w - k3 * w], t,
		states, parameters)

	return ParameterEstimationProblem("Lotka_Volterra", model, measured_quantities,
		:nothing, :nothing, p_true, ic, 0)
end

function seir()
	@parameters a b nu
	@variables t S(t) E(t) In(t) N(t) y1(t) y2(t)
	D = Differential(t)
	states = [S, E, In, N]
	parameters = [a, b, nu]

	@named model = ODESystem([
			D(S) ~ -b * S * In / N,
			D(E) ~ b * S * In / N - nu * E,
			D(In) ~ nu * E - a * In,
			D(N) ~ 0,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ In,
		y2 ~ N,
	]

	ic = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.25, 0.5, 0.75]

	return ParameterEstimationProblem("SEIR",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function simple()
	@parameters a b
	@variables t x1(t) x2(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2]
	parameters = [a, b]

	@named model = ODESystem([
			D(x1) ~ -a * x2,
			D(x2) ~ b * x1,  #edited from 1/b
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x2]

	ic = [0.333, 0.667]
	p_true = [0.4, 0.8]

	return ParameterEstimationProblem("simple",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function sirsforced()
	@parameters b0 b1 g M mu nu
	@variables t i(t) r(t) s(t) x1(t) x2(t) y1(t) y2(t)
	D = Differential(t)
	states = [i, r, s, x1, x2]
	parameters = [b0, b1, g, M, mu, nu]

	@named model = ODESystem([
			D(i) ~ b0 * (1.0 + b1 * x1) * i * s - (nu + mu) * i,
			D(r) ~ nu * i - (mu + g) * r,
			D(s) ~ mu - mu * s - b0 * (1.0 + b1 * x1) * i * s + g * r,
			D(x1) ~ -M * x2,
			D(x2) ~ M * x1,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ i,
		y2 ~ r,
	]

	ic = [0.167, 0.333, 0.5, 0.667, 0.833]
	p_true = [0.143, 0.286, 0.429, 0.571, 0.714, 0.857]

	return ParameterEstimationProblem("sirsforced",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 3)
end

function slowfast()  # TODO(orebas):in the old code it was CVODE_BDF.  should we go back to that?
	#solver = CVODE_BDF()
	@parameters k1 k2 eB
	@variables t xA(t) xB(t) xC(t) eA(t) eC(t) y1(t) y2(t) y3(t) y4(t) #eA(t) eC(t)
	D = Differential(t)
	states = [xA, xB, xC, eA, eC]
	parameters = [k1, k2, eB]
	@named model = ODESystem([
			D(xA) ~ -k1 * xA,
			D(xB) ~ k1 * xA - k2 * xB,
			D(xC) ~ k2 * xB,
			D(eA) ~ 0,
			D(eC) ~ 0,
		], t, states, parameters)

	measured_quantities = [y1 ~ xC, y2 ~ eA * xA + eB * xB + eC * xC, y3 ~ eA, y4 ~ eC]
	ic = [0.166, 0.333, 0.5, 0.666, 0.833]
	p_true = [0.25, 0.5, 0.75] # True Parameters

	return ParameterEstimationProblem("slowfast",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end


function substr_test()
	@parameters a b beta
	@variables t x1(t) x2(t) x3(t) y1(t) y2(t) y3(t)
	D = Differential(t)
	states = [x1, x2, x3]
	parameters = [a, b, beta]

	@named model = ODESystem([
			D(x1) ~ -a * x2,
			D(x2) ~ b * (x1),
			D(x3) ~ a * b * beta * b * a * x3,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x2,
		y3 ~ x3,
	]

	ic = [2.0, 3.0, 4.0]
	p_true = [0.1, 0.2, 0.3]

	return ParameterEstimationProblem("substr_test",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end


function global_unident_test()
	@parameters a b c d
	@variables t x1(t) x2(t) x3(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3]
	parameters = [a, b, c, d]

	@named model = ODESystem([
			D(x1) ~ -a * x1,
			D(x2) ~ (b + c) * (x1),
			D(x3) ~ d * x1,
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x2,
	]

	ic = [2.0, 3.0, 4.0]
	p_true = [0.1, 0.2, 0.3, 0.4]

	return ParameterEstimationProblem("global_unident_test",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 4)

end


function sum_test()
	@parameters a b c d
	@variables t x1(t) x2(t) x3(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2, x3]
	parameters = [a, b, c]

	@named model = ODESystem([
			D(x1) ~ -a * x1,
			D(x2) ~ b * (x2),
			D(x3) ~ c * (x1 + x2),
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x3,
	]

	ic = [2.0, 3.0, 4.0]
	p_true = [0.1, 0.2, 0.3]

	return ParameterEstimationProblem("sum_test",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 3)

end





function treatment(datasize = 21, time_interval = [-0.5, 0.5], solver = Vern9())  #note the solver.  Vern9 apparently can't handle mass matrices
	@parameters a b d g nu
	@variables t In(t) N(t) S(t) Tr(t) y1(t) y2(t)
	D = Differential(t)
	states = [In, N, S, Tr]
	parameters = [a, b, d, g, nu]

	@named model = ODESystem([D(In) ~ b * S * In / N + d * b * S * Tr / N - (a + g) * In,
			D(N) ~ 0,
			D(S) ~ -b * S * In / N - d * b * S * Tr / N,
			D(Tr) ~ g * In - nu * Tr], t, states, parameters)
	measured_quantities = [
		y1 ~ Tr,
		y2 ~ N,
	]

	ic = [0.2, 0.4, 0.6, 0.8]
	p_true = [0.167, 0.333, 0.5, 0.667, 0.833]

	return ParameterEstimationProblem("treatment",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 6)
end

function vanderpol()
	@parameters a b
	@variables t x1(t) x2(t) y1(t) y2(t)
	D = Differential(t)
	states = [x1, x2]
	parameters = [a, b]

	@named model = ODESystem([
			D(x1) ~ a * x2,
			D(x2) ~ -(x1) - b * (x1^2 - 1) * (x2),
		], t, states, parameters)
	measured_quantities = [
		y1 ~ x1,
		y2 ~ x2,
	]

	ic = [0.333, 0.667]
	p_true = [0.4, 0.8]

	return ParameterEstimationProblem("vanderpol",
		model, measured_quantities, :nothing, :nothing, p_true, ic, 0)
end

function analyze_parameter_estimation_problem(PEP::ParameterEstimationProblem; test_mode = false, showplot = true, run_ode_pe = true)

	#interpolators = Dict(
	#	"AAA" => ParameterEstimation.aaad,
	#"FHD3" => ParameterEstimation.fhdn(3),
	#"FHD6" => ParameterEstimation.fhdn(6),
	#"FHD8" => ParameterEstimation.fhdn(8),
	#"Fourier" => ParameterEstimation.FourierInterp,
	#)
	datasize = 21 #TODO(Orebas) magic number

	#stepsize = max(1, datasize ÷ 8)
	#for i in range(1, (datasize - 2), step = stepsize)
	#	interpolators["RatOld($i)"] = ParameterEstimation.SimpleRationalInterpOld(i)
	#end

	#@time res = ParameterEstimation.estimate(PEP.model, PEP.measured_quantities,
	#	PEP.data_sample,
	#	solver = PEP.solver, disable_output = false, interpolators = interpolators)
	#all_params = vcat(PEP.ic, PEP.p_true)
	#println("TYPERES: ", typeof(res))
	#println(res)

	#println(res)
	besterror = 1e30
	all_params = vcat(PEP.ic, PEP.p_true)

	if (run_ode_pe)
		res3 = ODEPEtestwrapper(PEP.model, PEP.measured_quantities,
			PEP.data_sample,
			PEP.solver)
		display("res3")
		display(res3)
		besterror = 1e30
		res3 = sort(res3, by = x -> x.err)
		display("How close are we?")
		println("Actual values:")
		display(all_params)

		for each in res3

			estimates = vcat(collect(values(each.states)), collect(values(each.parameters)))
			if (each.err < 100)  #TODO: magic number

				display(estimates)
				println("Error: ", each.err)
			end

			errorvec = abs.((estimates .- all_params) ./ (all_params))
			if (PEP.unident_count > 0)
				sort!(errorvec)
				for i in 1:PEP.unident_count
					pop!(errorvec)
				end
			end
			besterror = min(besterror, maximum(errorvec))
		end

		if (test_mode)
			@test besterror < 1e-1
		end
		println("For model ", PEP.Name, ": The ODEPE  max abs rel. err: ", besterror)
	end
end

function varied_estimation_main()
	print("testing")
	datasize = 21
	solver = Vern9()
	#solver = Rodas4P()
	time_interval = [-0.5, 0.5]
	for PEP in [
		global_unident_test(),
		vanderpol(),
		simple(),
		substr_test(),
		slowfast(),
		daisy_ex3_v4(),
		fitzhugh_nagumo(),
		lotka_volterra(),
		vanderpol(),
		daisy_mamil3(),
		sum_test(),   
		hiv(),
		seir(),
		daisy_mamil4(),
		crauste(),  
		daisy_ex3_v3(),
		daisy_ex3_v2(),
		treatment(),  
		daisy_ex3(),
		hiv_local(), #no solutions found in old version?  check?
		biohydrogenation(),  #broken, debug
		sirsforced(),
	]
		analyze_parameter_estimation_problem(fillPEP(PEP), test_mode = true, showplot = false)
	end
end

varied_estimation_main()
# Write your tests here.
