using ODEParameterEstimation
using OrderedCollections

opts = EstimationOptions(
    datasize = 21, noise_level = 0.0, shooting_points = 0, nooutput = true,
    diagnostics = false, flow = FlowStandard, use_si_template = true,
    use_parameter_homotopy = false, interpolator = InterpolatorAAAD,
    save_system = false, polish_solver_solutions = false, polish_solutions = false,
)

pep = ODEParameterEstimation.sum_test()
sampled = ODEParameterEstimation.sample_problem_data(pep, opts)
raw_results, analysis, uq = ODEParameterEstimation.analyze_parameter_estimation_problem(sampled, opts)

truth = pep.p_true
ic = pep.ic
pool = analysis[1]

println("======== sum_test pool diagnostic ========")
println("truth params : ", join(["$(k)=$(v)" for (k,v) in truth], ", "))
println("truth ICs    : ", join(["$(k)=$(v)" for (k,v) in ic], ", "))
println("analysis[2] (reported besterror) = ", analysis[2])
println("pool size = ", length(pool))
println("algebraic_multiplicity opt = ", opts.algebraic_multiplicity)
println()

function oracle_err(r)
    unid = Set(string.(collect(r.all_unidentifiable)))
    errs = Float64[]
    for (p, tv) in truth
        string(p) in unid && continue
        haskey(r.parameters, p) || continue
        push!(errs, abs(Float64(r.parameters[p]) - Float64(tv)) / max(abs(Float64(tv)), 1e-6))
    end
    return isempty(errs) ? Inf : maximum(errs)
end

for (i, r) in enumerate(pool)
    ps = join(["$(k)=$(round(Float64(v), sigdigits = 5))" for (k, v) in r.parameters], ", ")
    ss = join(["$(k)=$(round(Float64(v), sigdigits = 5))" for (k, v) in r.states], ", ")
    unid = Set(string.(collect(r.all_unidentifiable)))
    prov = hasproperty(r, :provenance) ? r.provenance : nothing
    ptag = prov === nothing ? "?" : string(prov.primary_method, "/", prov.source_type, prov.polish_applied ? "/polished" : "")
    println("[$i] SSEerr=$(round(r.err, sigdigits = 4))  oracle_max_perr(a,b)=$(round(oracle_err(r), sigdigits = 5))  unid=$(unid)  prov=$ptag")
    println("      params: $ps")
    println("      states: $ss")
end
println()
best = first(pool)
println("SELECTED best = pool[1]: oracle_max_perr = ", round(oracle_err(best), sigdigits = 5))
println("pool-min oracle_max_perr = ", round(minimum(oracle_err(r) for r in pool), sigdigits = 5),
        "  at index ", argmin([oracle_err(r) for r in pool]))
