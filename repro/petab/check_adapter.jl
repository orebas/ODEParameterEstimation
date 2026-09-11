using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, PEtab, ModelingToolkit, Symbolics, OrderedCollections, Test, TOML
const Ext = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
root = get(ENV, "ODEPE_PETAB_MODELS", "/tmp/odepe-petab-full-20260910/Benchmark-Models")
config = TOML.parsefile(joinpath(@__DIR__, "targets.toml"))
models = isempty(ARGS) ? vcat(config["main"], config["challenge"]) : ARGS
# Published estimates validate the import only. They never initialize run.jl.
@testset "Canonical PEtab semantic parity" begin
for name in models
    println("LOADING ", name); flush(stdout)
    path = joinpath(root, name, "$name.yaml")
    isfile(path) || (path = joinpath(root, name, "problem.yaml"))
    if name == "Crauste_CellSystems2017"
        @test_throws r"observed interval common to all signals" load_petab_problem(path)
        continue
    end
    @testset "$name semantic parity" begin
    problem = load_petab_problem(path)
    println("IDS ", problem.parameter_ids)
    println("DIMENSIONS ", length(unknowns(problem.algebraic.model.system)), " states; ",
        length(parameters(problem.algebraic.model.system)), " algebraic parameters; ",
        length(problem.condition_states), " experiments")
        @test isempty(problem.algebraic.p_true)
        @test isempty(problem.algebraic.ic)
        reference = collect(get_x(problem.petab))
        displaced = reference .+ 0.05 .* (problem.petab.upper_bounds .- problem.petab.lower_bounds)
        displaced = clamp.(displaced, problem.petab.lower_bounds, problem.petab.upper_bounds)
        for x in (reference, displaced)
            expected = problem.petab.simulated_values(x)
            actual = Ext._adapter_predictions(problem, x)
            @test all(isfinite, actual)
            @test actual ≈ expected rtol=1e-5 atol=1e-5
            ps = Ext._physical_parameters(problem, x)
            for (cid, states) in problem.condition_states
                expected_u0 = PEtab.get_u0(x, problem.petab; condition=cid, retmap=false)
                actual_u0 = Float64[Symbolics.value(Symbolics.substitute(problem.initial_maps[s], ps)) for s in states]
                @test actual_u0 ≈ expected_u0 rtol=1e-10 atol=1e-10
            end
        end
    end
    flush(stdout)
end
end
