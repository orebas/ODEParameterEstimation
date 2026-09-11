# Construction-only audit: no interpolation, candidate search, or refinement.
# Usage: julia --startup-file=no --compiled-modules=existing inspect_blocks.jl MODEL GROUP_SIZE CAP OUTPUT_JSON
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, PEtab, JSON, SHA, Random

const ODEPE = ODEParameterEstimation
const Ext = Base.get_extension(ODEPE, :ODEParameterEstimationPEtabExt)
const S = ODEPE.Symbolics
const MTK = ODEPE.ModelingToolkit
const HC = ODEPE.HomotopyContinuation

length(ARGS) == 4 || error("Expected MODEL GROUP_SIZE CAP OUTPUT_JSON")
name, group_text, cap_text, output = ARGS
group_size, cap = parse(Int, group_text), parse(Int, cap_text)
root = get(ENV, "ODEPE_PETAB_MODEL_ROOT", "/tmp/odepe-petab-full-20260910/Benchmark-Models")
Random.seed!(20260910)
started = time()
record = Dict{String, Any}("problem"=>name, "group_size"=>group_size,
    "max_derivative_order"=>cap, "status"=>"loading", "julia_version"=>string(VERSION),
    "environment_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "constructor_sha256"=>bytes2hex(sha256(read(joinpath(@__DIR__, "../../ext/petab/experiment_blocks.jl")))))
function checkpoint()
    record["seconds"] = time()-started
    open(output * ".tmp", "w") do io
        JSON.print(io, record)
    end
    mv(output * ".tmp", output; force=true)
end
checkpoint()
try
    problem = load_petab_problem(joinpath(root, name, name * ".yaml"))
    pep, scaling = ODEPE.rescale_pep(problem.algebraic)
    cids = collect(keys(problem.condition_states))[1:group_size]
    original = string.(MTK.unknowns(problem.petab.model_info.model.sys))
    names = Dict(string(p)=>id for (p,id) in zip(problem.parameter_symbols,problem.parameter_ids))
    state_ids = Dict{String, String}()
    for (cid, states) in problem.condition_states, (s, id) in zip(states, original)
        state_ids[string(s)] = id
        names[string(s)] = cid * "__" * id
        names[Ext._name(s) * "_0"] = cid * "__" * replace(id, "(t)"=>"") * "_anchor"
    end
    # Longest names first prevents petab_p1 matching the prefix of petab_p10.
    readable(expr) = replace(string(expr), (k=>names[k] for k in sort!(collect(keys(names)); by=length, rev=true))...)
    record["state_ids"] = state_ids
    record["parameter_ids"] = problem.parameter_ids
    record["full_state_count"] = length(problem.algebraic.model.original_states)
    record["full_estimated_parameter_count"] = length(problem.parameter_ids)
    record["conditions"] = cids
    record["ode_equations_physical"] = readable.(MTK.equations(problem.algebraic.model.system))
    record["observables_physical"] = readable.(problem.algebraic.measured_quantities)
    record["initial_preparation_physical"] = Dict(names[string(s)]=>readable(v) for (s,v) in problem.initial_maps)
    record["state_scales"] = Dict(names[string(s)]=>v for (s,v) in scaling.state_scales)
    record["parameter_scales"] = Dict(names[string(p)]=>v for (p,v) in scaling.param_scales)
    record["status"] = "constructing"
    checkpoint()
    built = Ext._experiment_frontier(problem, pep, cids; max_derivative_order=cap,
        progress = p -> begin
            record["trace"] = p.trace
            checkpoint()
            println("RANK ", last(p.trace)); flush(stdout)
        end)
    record["shared_algebraic_parameters"] = [names[string(p)] for p in built.params]
    record["blocks"] = [(; condition=b.cid, states=[state_ids[string(s)] for s in b.states],
        omitted_states=[state_ids[string(s)] for s in b.omitted_states],
        observable_count=length(b.measured), measurement_count=sum(length(s.values) for s in b.data.series))
        for b in built.blocks]
    record["status"] = "counting_polynomial_support"
    checkpoint()
    selected = built.frontier.selected
    if !isnothing(selected)
        F, xs, ds = ODEPE.convert_to_hc_format_with_params(selected.equations, selected.solve_vars, selected.data_vars)
        support, coefficients = HC.ModelKit.support_coefficients(F)
        degrees = [maximum(vec(sum(a; dims=1)); init=0) for a in support]
        terms = [size(a,2) for a in support]
        record["selected"] = (; equation_count=length(selected.equations), variable_count=length(xs),
            data_coefficient_count=length(ds), solve_variables=readable.(selected.solve_vars),
            data_variables=string.(selected.data_vars), equations=readable.(selected.equations),
            selected_pool_indices=selected.selected_equation_indices,
            dropped_pool_indices=selected.dropped_equation_indices,
            derivative_orders=[m.max_observed_order for m in selected.eq_metadata],
            degrees, monomial_counts=terms, total_monomials=sum(terms),
            total_degree_bezout_bound=string(prod(big.(degrees))),
            mixed_volume=nothing,
            note="Degrees and supports count solve variables only; observation jets are coefficients. Equations use the recorded power-of-two rescaling. Bezout is a loose upper bound, not measured path count.")
    end
    record["status"] = isnothing(selected) ? "rank_deficient_at_limit" : "complete"
catch err
    ODEPE._rethrow_if_interrupt(err)
    record["status"] = "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
end
checkpoint()
println("FINISHED ", name, " ", record["status"])
