# Rebuild just SIAN's polynomial pool; do not run global SI, multiplicity, or HC.
include("common.jl")
length(ARGS) == 1 || error("Expected output JSON path")
Base.exit_on_sigint(false)
Random.seed!(20260911)
record = Dict{String,Any}("status" => "starting", "core_revision" => strip(read(`git rev-parse HEAD`, String)))
checkpoint() = write_json(only(ARGS), record)
checkpoint()
try
    extracted = single_condition("Fujita_SciSignal2010", "condition_step_01_0")
    raw = JSON.parsefile(joinpath(@__DIR__, "evidence", "fujita_201.data.json"))
    data = OD{Union{String,Num},Vector{Float64}}("t" => Float64.(raw["times"]))
    for (eq, signal) in zip(extracted.reduced.measured_quantities, raw["signals"])
        data[Num(eq.rhs)] = Float64.(signal["values"])
    end
    original = extracted.reduced
    pep = ParameterEstimationProblem(original.name, original.model, original.measured_quantities,
        data, original.recommended_time_interval, original.solver, original.p_true, original.ic, original.unident_count)
    pep, _ = ODEPE.rescale_pep(pep)
    record["status"] = "building_sian_pool"
    checkpoint()
    si_ode, _, _ = ODEPE.convert_to_si_ode(pep.model, pep.measured_quantities)
    stats = @timed ODEPE.get_polynomial_system_from_sian(si_ode,
        vcat(si_ode.parameters, si_ode.x_vars); compute_multiplicity=false)
    result = stats.value
    polys = result["full_polynomial_system"]
    ring = parent(first(polys))
    substitutions = [v for v in ODEPE.Nemo.gens(ring) if string(v) in ("reaction_5_k1_0", "EGFR_turnover_0")]
    @assert length(substitutions) == 2
    polys = [ODEPE.Nemo.evaluate(p, substitutions, [one(ring), one(ring)]) for p in polys]
    record["equations"] = string.(polys)
    record["variables"] = sort!(string.(collect(ODEPE.collect_used_nemo_variables(polys))))
    record["seconds"] = stats.time
    record["sian_timing"] = result["timing"]
    record["selected_indices"] = result["selected_equation_indices"]
    record["dropped_indices"] = result["dropped_equation_indices"]
    record["representative_fixes"] = Dict("reaction_5_k1_0"=>1, "EGFR_turnover_0"=>1)
    record["status"] = "complete"
catch err
    record["status"] = "failed"
    record["error"] = sprint(showerror, err, catch_backtrace())
finally
    checkpoint()
end
println("FINISHED ", record["status"])
record["status"] == "complete" || exit(1)
