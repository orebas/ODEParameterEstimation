# Preserve both historical constructors. No kinetics, state set, or IC knowledge
# changes inside an observation pair.
module NativeCoefficients
include("coefficient_model.jl")
end
include("dense_common.jl")

function study_problem(spec, model_kind, observation_kind)
    base, lower, upper = if model_kind == "free"
        NativeCoefficients.coefficient_problem(spec, "original"), zeros(15), fill(1e6,15)
    elseif model_kind == "rational"
        extracted = single_condition("Sneyd_PNAS2002", spec["condition"])
        extracted.reduced, extracted.lower, extracted.upper
    else
        error("Unknown model kind: $model_kind")
    end
    measured = only(base.measured_quantities)
    rhs = S.value(measured.rhs)
    @assert S.operation(rhs) === (^) && isequal(Num(last(S.arguments(rhs))),Num(4))
    linear = Num(first(S.arguments(rhs)))
    @assert isequal(S.expand(linear^4 - measured.rhs), Num(0))
    raw = Float64.(only(spec["original_data"]["signals"])["values"])
    times = Float64.(spec["original_data"]["times"])
    all(isfinite, raw) && all(>=(0), raw) || error("Positive real fourth root requires finite nonnegative data")
    rooted = sqrt.(sqrt.(raw))
    observation_kind in ("quartic", "root") || error("Unknown observation kind")
    expression = observation_kind == "root" ? linear : Num(measured.rhs)
    observations = [measured.lhs ~ expression]
    data = OD{Union{String,Num},Vector{Float64}}(expression => (observation_kind == "root" ? rooted : raw), "t"=>times)
    pep = ParameterEstimationProblem(base.name, base.model, observations, data,
        base.recommended_time_interval, base.solver, base.p_true, base.ic, base.unident_count)
    return (; pep, base, lower, upper, linear, raw, rooted, times,
        fourth_power_roundtrip_max_error=maximum(abs.(rooted.^4 .- raw)))
end

# Re-score each returned trajectory in both physical signal units. Report-time
# ICs, not anchor-time ICs, are the ones stored in returned result states.
function score_candidate(study, result)
    pep = study.pep
    xs = pep.model.original_states
    ps = pep.model.original_parameters
    pvalues = OD(Num(p)=>Float64(result.parameters[Num(p)]) for p in ps)
    uvalues = OD(Num(x)=>Float64(result.states[Num(x)]) for x in xs)
    @assert isapprox(result.report_time, first(study.times); atol=1e-12, rtol=0)
    observation = [only(pep.measured_quantities).lhs ~ study.linear]
    data = ODEPE.sample_data(pep.model.system, observation,
        pep.recommended_time_interval, pvalues, uvalues, length(study.times);
        solver=pep.solver, abstol=1e-12, reltol=1e-12)
    @assert data["t"] == study.times
    prediction = data[Num(study.linear)]
    return (; original_y_sse=sum(abs2, prediction.^4 .- study.raw),
        root_z_sse=sum(abs2, prediction .- study.rooted),
        original_y_max_abs_error=maximum(abs.(prediction.^4 .- study.raw)),
        predicted_linear_signal_min=minimum(prediction),
        predicted_linear_signal_max=maximum(prediction))
end
