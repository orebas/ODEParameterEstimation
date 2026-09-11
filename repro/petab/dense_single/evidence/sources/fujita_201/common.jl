# Synthetic, single-condition experiments using the ordinary ODEPE workflow.
# PEtab supplies equations and generating values, not an optimization objective.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, PEtab, JSON, Random, SHA, Profile

const ODEPE = ODEParameterEstimation
const Ext = Base.get_extension(ODEPE, :ODEParameterEstimationPEtabExt)
const S = ODEPE.Symbolics
const MTK = ODEPE.ModelingToolkit
const Num = S.Num
const OD = ODEPE.OrderedDict

json_safe(x::AbstractFloat) = isfinite(x) ? x : string(x)
json_safe(x::Union{AbstractString, Integer, Bool, Nothing}) = x
json_safe(x::Symbol) = string(x)
json_safe(x::AbstractDict) = Dict(string(k) => json_safe(v) for (k,v) in x)
json_safe(x::NamedTuple) = Dict(string(k) => json_safe(v) for (k,v) in pairs(x))
json_safe(x::Union{AbstractArray, Tuple, Set}) = [json_safe(v) for v in x]
json_safe(x) = string(x)

function write_json(path, value)
    open(path * ".tmp", "w") do io
        JSON.print(io, json_safe(value))
    end
    mv(path * ".tmp", path; force=true)
end

"""
Extract one condition and remove only provably zero invariant states and states
with no influence on the observations. Initial values of all retained states
remain unknown to the estimator, as in the ordinary synthetic benchmarks.

# Returns
Full and reduced problems, the original bounds, and a record of the reduction.
"""
function single_condition(name, cid)
    root = get(ENV, "ODEPE_PETAB_MODEL_ROOT", "/tmp/odepe-petab-full-20260910/Benchmark-Models")
    path = joinpath(root, name, name * ".yaml")
    adapter = load_petab_problem(path)
    rows = adapter.petab.model_info.model.petab_tables[:parameters]
    parameter_rows = Dict(string(r.parameterId) => r for r in eachrow(rows))
    # These values are explicitly the synthetic data generator, not fit starts.
    nominal = Dict(p => Num(parameter_rows[id].nominalValue)
        for (p,id) in zip(adapter.parameter_symbols, adapter.parameter_ids))
    old_states = adapter.condition_states[cid]
    states = Num[Ext._new_state(Ext._name(s)) for s in MTK.unknowns(adapter.petab.model_info.model.sys)]
    rename = Dict{Num,Num}(zip(old_states, states))
    merge!(rename, Dict(p => Ext._named_parameter(id)
        for (p,id) in zip(adapter.parameter_symbols, adapter.parameter_ids)))
    rhs = Dict(Num(only(S.arguments(S.value(eq.lhs)))) => Num(eq.rhs)
        for eq in MTK.equations(adapter.algebraic.model.system))
    dynamics = Dict(rename[s] => Num(S.substitute(rhs[s], rename)) for s in old_states)
    indices = findall(s -> s.experiment_id == cid, adapter.algebraic.data_sample.series)
    measured = MTK.Equation[Ext._new_state("dense_y$i") ~ S.substitute(adapter.algebraic.measured_quantities[j].rhs, rename)
        for (i,j) in enumerate(indices)]
    initial_expr = Dict(rename[s] => Num(S.substitute(adapter.initial_maps[s], rename)) for s in old_states)
    ic = OD{Num,Float64}(rename[s] => Float64(S.value(S.substitute(adapter.initial_maps[s], nominal)))
        for s in old_states)
    truth = Dict(rename[p] => Float64(S.value(value)) for (p,value) in nominal)
    ordered_params = Num[rename[p] for p in adapter.parameter_symbols]
    measurements = adapter.petab.model_info.model.petab_tables[:measurements]
    interval = [0.0, maximum(Float64(r.time) for r in eachrow(measurements) if string(r.simulationConditionId) == cid)]
    function make_problem(label, xs, fs, obs)
        used = Set(Num(v) for e in vcat(collect(values(fs)), [Num(eq.rhs) for eq in obs]) for v in S.get_variables(e))
        ps = filter(in(used), ordered_params)
        equations = MTK.Equation[ODEPE.D(s) ~ fs[s] for s in xs]
        model, outputs = ODEPE.create_ordered_ode_system(label, xs, ps, equations, obs)
        return ParameterEstimationProblem(label, model, outputs, nothing, interval,
            ODEPE.package_wide_default_ode_solver,
            OD{Num,Float64}(p => truth[p] for p in ps), OD{Num,Float64}(s => ic[s] for s in xs), 0)
    end
    full = make_problem(name * "_" * cid * "_full", states, dynamics, measured)
    # Find the largest subset of symbolically known-zero initial states whose
    # vector field vanishes when that entire subset is zero. No nominal rate or
    # estimated initial value is used in this proof.
    zeroset = Set(s for s in states if isequal(initial_expr[s], Num(0)))
    while true
        substitutions = Dict(s => Num(0) for s in zeroset)
        next = Set(s for s in zeroset if isequal(S.simplify(S.substitute(dynamics[s], substitutions)), Num(0)))
        next == zeroset && break
        zeroset = next
    end
    zero_substitutions = Dict(s => Num(0) for s in zeroset)
    reduced_rhs = Dict(s => Num(S.substitute(f, zero_substitutions)) for (s,f) in dynamics if !(s in zeroset))
    reduced_obs = MTK.Equation[eq.lhs ~ S.substitute(eq.rhs, zero_substitutions) for eq in measured]
    local_states = Set(keys(reduced_rhs))
    required = Set(Num(v) for eq in reduced_obs for v in S.get_variables(eq.rhs) if Num(v) in local_states)
    while true
        before = length(required)
        union!(required, Set(Num(v) for s in collect(required) for v in S.get_variables(reduced_rhs[s]) if Num(v) in local_states))
        length(required) == before && break
    end
    retained = filter(in(required), states)
    reduced = make_problem(name * "_" * cid * "_dense", retained,
        Dict(s => reduced_rhs[s] for s in retained), reduced_obs)
    ps = reduced.model.original_parameters
    # PEtab rate/observable bounds are retained. ICs use nonnegative bounds with
    # the largest published concentration/parameter upper bound; no truth-tight box.
    ic_upper = maximum(Float64(r.upperBound) for r in eachrow(rows) if r.estimate == 1)
    lower = vcat(zeros(length(retained)), [Float64(parameter_rows[string(p)].lowerBound) for p in ps])
    upper = vcat(fill(ic_upper, length(retained)), [Float64(parameter_rows[string(p)].upperBound) for p in ps])
    record = (; condition=cid, full_states=string.(states), retained_states=string.(retained),
        zero_invariant_states=string.(filter(in(zeroset), states)),
        unobserved_states=string.(filter(s -> !(s in required) && !(s in zeroset), states)),
        parameters=string.(ps), equations=string.(MTK.equations(reduced.model.system)),
        observations=string.(reduced.measured_quantities), generating_parameters=reduced.p_true,
        generating_initial_states=reduced.ic, original_initial_formulas=initial_expr,
        time_interval=interval, bounds_order=vcat(string.(retained), string.(ps)), lower_bounds=lower, upper_bounds=upper,
        truth_use="Published nominal values generate synthetic data only; retained ICs are estimated freely, including known zeros.")
    return (; full, reduced, lower, upper, record)
end

function sample_dense(pep, n)
    data = ODEPE.sample_data(pep.model.system, pep.measured_quantities,
        pep.recommended_time_interval, pep.p_true, pep.ic, n;
        solver=pep.solver, abstol=1e-12, reltol=1e-12)
    return ParameterEstimationProblem(pep.name, pep.model, pep.measured_quantities, data,
        pep.recommended_time_interval, pep.solver, pep.p_true, pep.ic, pep.unident_count)
end
