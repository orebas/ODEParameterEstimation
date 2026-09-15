using ODEParameterEstimation, ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
const ODEPE = ODEParameterEstimation
const S = ODEPE.Symbolics
const OD = ODEPE.OrderedDict

"""Construct the native six-state, nine-independent-rate research problem."""
function coefficient_problem(spec, scenario)
    scenario in ("original", "moderate") || error("Unknown coefficient scenario")
    states = @variables IPR_A(t) IPR_I1(t) IPR_I2(t) IPR_O(t) IPR_R(t) IPR_S(t)
    parameters = @parameters phi1 phi2 phi3 phi4 phi5 phi6 phi7 phi8 phi9
    observables = @variables dense_y1(t)
    @assert string.(states) == spec["state_names"] .* "(t)"
    @assert string.(parameters) == spec["rate_names"]
    equations = [D(state) ~ sum(
        (parse(Int,term["numerator"]) // parse(Int,term["denominator"])) *
        states[Int(term["state_index"])] * parameters[Int(term["rate_index"])]
        for term in terms)
        for (state,terms) in zip(states,spec["ode_terms"])]
    observed = [only(observables) ~ ((9//10)*IPR_A+(1//10)*IPR_O)^4]
    name = "Sneyd_free_coefficients_" * scenario
    model, measured = create_ordered_ode_system(name,states,parameters,equations,observed)
    interval = scenario == "original" ? Float64.(spec["original_interval"]) : [0.0,10.0]
    truth = Float64.(spec[scenario*"_rates"])
    return ParameterEstimationProblem(name, model, measured, nothing, interval,
        ODEPE.package_wide_default_ode_solver,
        OD(parameters .=> truth), OD(states .=> Float64.(spec["initial_values"])), 0)
end
