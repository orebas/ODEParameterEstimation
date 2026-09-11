using ODEParameterEstimation, Random, Test, TOML, SHA
const ODEPE = ODEParameterEstimation
const OD = ODEPE.OrderedDict
const Num = ODEPE.Symbolics.Num
using ODEParameterEstimation.ModelingToolkit: @parameters, @variables, t_nounits as t, D_nounits as D
const OrderedDict = OD
length(ARGS) == 1 || error("Expected output TOML path")
include(joinpath(@__DIR__, "fixtures", "biohydrogenation", "model.jl"))
const BASE_REVISION = "fce879d65c6b36dc3b25de354017d8b776028c4d"
repo = normpath(joinpath(@__DIR__, "..", ".."))
source = read(Cmd(["git", "-C", repo, "show", BASE_REVISION * ":src/core/parameter_estimation.jl"]), String)
marker = findfirst("convert_to_real_or_complex_array(values)", source)
isnothing(marker) && error("Could not locate the end of the previous derivative producer")
prefix = source[1:prevind(source, first(marker))]
# The next function's opening docstring precedes the marker. Remove it.
prefix = prefix[1:prevind(prefix, first(findlast("\"\"\"", prefix)))]
legacy_source = replace(prefix, "function populate_derivatives(" => "function legacy_populate_derivatives("; count=1)
Base.include_string(ODEPE, legacy_source, "legacy_populate_derivatives.jl")
base = benchmark_problem()
model, measured = base.model.system, base.measured_quantities
raw_fields = (:states_lhs, :states_rhs, :obs_lhs, :obs_rhs)
cleared_fields = (:states_lhs_cleared, :states_rhs_cleared, :obs_lhs_cleared, :obs_rhs_cleared)
record = Dict{String,Any}("model"=>base.name, "julia_version"=>string(VERSION), "comparisons"=>Any[],
    "base_revision"=>BASE_REVISION, "legacy_source_sha256"=>bytes2hex(sha256(legacy_source)))
@testset "Biohydrogenation versus the previous derivative implementation" begin
    for levels in (6, 12)
        Random.seed!(20260911)
        old = ODEPE.legacy_populate_derivatives(model, measured, levels, Dict())
        old_rng = rand(5)
        Random.seed!(20260911)
        deferred = ODEPE.populate_derivatives(model, measured, levels, Dict(); include_cleared=false)
        deferred_rng = rand(5)
        raw_equal = all(f -> isequal(getfield(old,f), getfield(deferred,f)), raw_fields)
        @test raw_equal
        @test old_rng == deferred_rng
        @test all(f -> isempty(getfield(deferred,f)), cleared_fields)
        ODEPE.ensure_cleared_derivatives!(deferred)
        cleared_equal = all(f -> isequal(getfield(old,f), getfield(deferred,f)), cleared_fields)
        @test cleared_equal
        row = Dict{String,Any}("requested_levels"=>levels, "actual_levels"=>length(deferred.obs_lhs),
            "actual_max_observation_order"=>length(deferred.obs_lhs)-1,
            "raw_tables_identical"=>raw_equal, "cleared_tables_identical"=>cleared_equal,
            "random_stream_unchanged"=>old_rng == deferred_rng)
        if levels == 6
            ps = OD(p=>0.5 for p in base.model.original_parameters)
            ic = OD(x=>0.7 for x in base.model.original_states)
            varlist = Num[vcat(collect(keys(ps)),collect(keys(ic)))...]
            old_J, _ = ODEPE.multipoint_numerical_jacobian(model, measured, levels, 1,
                Dict(), varlist, ps, [ic], merge(ps,ic), old)
            new_J, _ = ODEPE.multipoint_numerical_jacobian(model, measured, levels, 1,
                Dict(), varlist, ps, [ic], merge(ps,ic), deferred)
            @test old_J == new_J
            row["jacobian_max_absolute_difference"] = maximum(abs, old_J-new_J)
            row["jacobian_size"] = collect(size(old_J))
        end
        push!(record["comparisons"],row)
        println(row); flush(stdout)
    end
end
record["status"] = "passed"
open(only(ARGS),"w") do io
    TOML.print(io,record; sorted=true)
end
