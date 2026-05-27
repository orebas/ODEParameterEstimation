# Is the backsolve genuinely failing for receptor's PHYSICAL solution, or only for spurious roots?
# Take truth params + true ICs, integrate FORWARD t0 -> t_s to get exact physical states at t_s,
# then backsolve t_s -> t0 with a strong stiff/auto solver and measure:
#   * IC recovery error from EXACT physical states  (tests backward numerical stability of the solver)
#   * IC error from a tiny (1e-6 rel) perturbation   (tests backward sensitivity / amplification)
# Also backsolve a deliberately NON-PHYSICAL start (negative occupancy) to confirm spurious roots blow up.
# If truth backsolves fine but non-physical blows to ~1e9, then [RESOLVE] fires on garbage candidates,
# not because receptor's physical backsolve is impossible.
using ODEParameterEstimation, OrdinaryDiffEq, ModelingToolkit, Printf, LinearAlgebra
const OPE = ODEParameterEstimation

function main()
	pep = OPE.receptor_subtype_binding_branch()
	spep = sample_problem_data(pep, EstimationOptions(datasize = 101, noise_level = 0.0, nooutput = true))
	sys = spep.model isa OPE.OrderedODESystem ? spep.model.system : spep.model
	csys = ModelingToolkit.complete(sys)
	states = ModelingToolkit.unknowns(csys); params = ModelingToolkit.parameters(csys)
	p_map = Dict(p => Float64(spep.p_true[p]) for p in params)
	u0_true = Dict(s => Float64(spep.ic[s]) for s in states)
	tv = spep.data_sample["t"]; t0 = Float64(first(tv))
	solver = AutoVern9(Rodas5P())
	@printf("receptor: t0=%.2f, states=%s, true IC=%s\n", t0, string(states), string([u0_true[s] for s in states])); flush(stdout)

	for ts in [-0.4, -0.2, 0.0, 0.2, 0.4]
		# forward t0 -> ts (exact physical states at ts)
		solF = solve(ODEProblem(csys, merge(u0_true, p_map), (t0, ts)), solver; abstol=1e-13, reltol=1e-13)
		xts = Dict(s => solF(ts; idxs = s) for s in states)
		maxx = maximum(abs(xts[s]) for s in states)
		# backsolve ts -> t0 from EXACT physical states
		solB = solve(ODEProblem(csys, merge(Dict(s=>xts[s] for s in states), p_map), (ts, t0)), solver; abstol=1e-13, reltol=1e-13)
		err_exact = maximum(abs(solB(t0; idxs=s) - u0_true[s]) for s in states)
		# backsolve from a 1e-6-relatively-perturbed start
		δ = 1e-6
		xpert = Dict(s => xts[s]*(1+δ) for s in states)
		solP = solve(ODEProblem(csys, merge(xpert, p_map), (ts, t0)), solver; abstol=1e-13, reltol=1e-13)
		err_pert = maximum(abs(solP(t0; idxs=s) - u0_true[s]) for s in states)
		@printf("t_s=%+.2f (Δ=%.2f) | maxstate@ts=%.2e | backsolve-from-EXACT IC-err=%.2e | from δ=1e-6 IC-err=%.2e (amp≈%.1e)\n",
			ts, ts-t0, maxx, err_exact, err_pert, err_pert/δ/max(maxx,1)); flush(stdout)
	end

	# Non-physical start (mimic a spurious root: flip a complex's sign / inflate) backsolved from t_s=0.4
	ts = 0.4
	solF = solve(ODEProblem(csys, merge(u0_true, p_map), (t0, ts)), solver; abstol=1e-13, reltol=1e-13)
	xts = Dict(s => solF(ts; idxs=s) for s in states)
	bad = Dict(s => (occursin("C", string(s)) ? -5.0*abs(xts[s]) - 1.0 : xts[s]) for s in states)  # negative occupancies
	try
		solBad = solve(ODEProblem(csys, merge(bad, p_map), (ts, t0)), solver; abstol=1e-13, reltol=1e-13)
		@printf("NON-PHYSICAL start @t_s=0.4 (neg occupancies): backsolved IC = %s\n",
			string([ (s=>round(solBad(t0; idxs=s), sigdigits=3)) for s in states])); flush(stdout)
	catch e
		@printf("NON-PHYSICAL start @t_s=0.4: backsolve THREW %s (diverged)\n", sprint(showerror,e)[1:min(80,end)]); flush(stdout)
	end
	println("done")
end

main()
