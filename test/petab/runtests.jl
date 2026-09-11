using Test, PEtab, ODEParameterEstimation, ModelingToolkit, Symbolics, OrderedCollections, Random
const Ext = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
const fixture = joinpath(@__DIR__, "fixtures", "decay", "problem.yaml")

@testset "Optional PEtab adapter contracts" begin
    problem = load_petab_problem(fixture)
    @test length(problem.condition_states) == 2
    @test length(problem.algebraic.model.original_parameters) == 1
    @test length(problem.algebraic.model.original_states) == 4
    @test sum(length(s.values) for s in problem.algebraic.data_sample.series) == 13
    @test isempty(problem.algebraic.p_true)
    @test isempty(problem.algebraic.ic)
    @test problem.condition_time_offsets == OrderedDict("A"=>0.5, "B"=>0.5)

    x = collect(PEtab.get_x(problem.petab))
    for values in (x, x .+ 0.02)
        actual = Ext._adapter_predictions(problem, values)
        expected = problem.petab.simulated_values(values)
        @test actual ≈ expected rtol=1e-6 atol=1e-8
    end
    @test_throws ArgumentError load_petab_problem(fixture; initial_time=-1)
    @test_throws ArgumentError estimate_petab_problem(problem;
        options=EstimationOptions(compute_uncertainty=true))
    @test_throws ArgumentError Ext._formula("run(`echo unsafe`)", Dict{String, Num}())

    # Analytical states at the algebraic epoch (physical t=0.5), independent of
    # the adapter's ODE solver. Recover shared k and both original preparations.
    physical = Ext._physical_parameters(problem, x)
    kinetic = only(problem.algebraic.model.original_parameters)
    state_values = OrderedDict{Num, Float64}()
    original = problem.petab.model_info.model
    for (cid, states) in problem.condition_states
        initial = cid == "A" ? 2.0 : 4.0
        for (source, state) in zip(unknowns(original.sys), states)
            state_values[state] = Ext._name(source) == "X" ? initial*exp(-0.4*0.5) : initial*(1-exp(-0.4*0.5))
        end
    end
    candidate = (; parameters=OrderedDict(kinetic=>0.4), states=state_values)
    recovered, preparation_residual = Ext._candidate_vector(problem, candidate, x .+ 0.01)
    recovered_by_name = Dict(zip(problem.parameter_ids, recovered))
    @test recovered_by_name["initial_A"] ≈ 2.0 atol=1e-8
    @test recovered_by_name["initial_B"] ≈ 4.0 atol=1e-8
    @test recovered_by_name["k"] ≈ log10(0.4) atol=1e-10
    @test preparation_residual < 1e-8

    # Changing all published estimated nominal values must not change algebraic
    # equations, symbolic preparation, or the generated bounded random start.
    mktempdir() do dir
        for name in readdir(dirname(fixture))
            cp(joinpath(dirname(fixture), name), joinpath(dir, name))
        end
        path = joinpath(dir, "parameters.tsv")
        lines = readlines(path)
        for i in 2:length(lines)
            columns = split(lines[i], '\t')
            if last(columns) == "1"
                columns[5] = string((parse(Float64, columns[3]) + parse(Float64, columns[4])) / 2)
                lines[i] = join(columns, '\t')
            end
        end
        write(path, join(lines, '\n') * "\n")
        changed = load_petab_problem(joinpath(dir, "problem.yaml"))
        @test isequal(equations(problem.algebraic.model.system), equations(changed.algebraic.model.system))
        @test isequal(problem.initial_maps, changed.initial_maps)
        a = get_startguesses(MersenneTwister(11), problem.petab, 1; sample_prior=false, allow_inf=true)
        b = get_startguesses(MersenneTwister(11), changed.petab, 1; sample_prior=false, allow_inf=true)
        @test collect(a) == collect(b)
    end
end

@testset "Observable parameters inside noise formulas" begin
    mktempdir() do dir
        paths = String[]
        for mapped in (false, true)
            local_dir = joinpath(dir, string(mapped))
            mkpath(local_dir)
            for name in readdir(dirname(fixture))
                cp(joinpath(dirname(fixture), name), joinpath(local_dir, name))
            end
            open(joinpath(local_dir, "parameters.tsv"), "a") do io
                println(io, "gain\tlin\t0.1\t10\t2\t1")
            end
            gain = mapped ? "observableParameter1_obs_x" : "gain"
            write(joinpath(local_dir, "observables.tsv"),
                "observableId\tobservableFormula\tnoiseFormula\tnoiseDistribution\tobservableTransformation\n" *
                "obs_x\t$gain*X\tnoise_x + $gain*X/100\tnormal\tlog10\n" *
                "obs_y\tY\tnoise_y\tnormal\tlin\n")
            if mapped
                measurements = readlines(joinpath(local_dir, "measurements.tsv"))
                measurements[1] *= "\tobservableParameters"
                for i in 2:length(measurements)
                    measurements[i] *= startswith(measurements[i], "obs_x\t") ? "\tgain" : "\t"
                end
                write(joinpath(local_dir, "measurements.tsv"), join(measurements, '\n') * "\n")
            end
            push!(paths, joinpath(local_dir, "problem.yaml"))
        end
        explicit, mapped = load_petab_problem.(paths)
        @test explicit.parameter_ids == mapped.parameter_ids
        x = collect(get_x(explicit.petab))
        @test explicit.petab.simulated_values(x) ≈ mapped.petab.simulated_values(x)
        @test explicit.petab.nllh(x) ≈ mapped.petab.nllh(x)
        @test explicit.petab.grad(x) ≈ mapped.petab.grad(x)
        delta = 1e-5
        fd = [(mapped.petab.nllh(x + delta * (1:length(x) .== i)) -
               mapped.petab.nllh(x - delta * (1:length(x) .== i))) / (2delta) for i in eachindex(x)]
        @test mapped.petab.grad(x) ≈ fd rtol=1e-4 atol=1e-4
    end
end

@testset "Condition-dependent SBML preparation and input compatibility" begin
    for constant in (true, false)
        mktempdir() do dir
            for name in readdir(dirname(fixture))
                cp(joinpath(dirname(fixture), name), joinpath(dir, name))
            end
            xml_path = joinpath(dir, "model.xml")
            xml = read(xml_path, String)
            xml = replace(xml, "</listOfParameters>" => """
                <parameter id="rate_multiplier" value="0.01" constant="$constant"/>
                <parameter id="effective_rate" value="0.01" constant="true"/>
                </listOfParameters>
                <listOfInitialAssignments><initialAssignment symbol="effective_rate">
                <math xmlns="http://www.w3.org/1998/Math/MathML"><apply><times/><ci>k</ci><ci>rate_multiplier</ci></apply></math>
                </initialAssignment></listOfInitialAssignments>
                """)
            xml = replace(xml, "<ci>cell</ci><ci>k</ci><ci>X</ci>" => "<ci>cell</ci><ci>effective_rate</ci><ci>X</ci>")
            write(xml_path, xml)
            write(joinpath(dir, "conditions.tsv"), "conditionId\tX\tY\trate_multiplier\nA\tinitial_A\t0\t2\nB\tinitial_B\t0\t3\n")
            problem = load_petab_problem(joinpath(dir, "problem.yaml"))
            x = collect(get_x(problem.petab))
            rows = problem.petab.model_info.model.petab_tables[:measurements]
            for values in (x, x .+ 0.03)
                actual = problem.petab.simulated_values(values)
                named = Dict(zip(problem.parameter_ids, values))
                expected = Float64[]
                for row in eachrow(rows)
                    cid = string(row.simulationConditionId)
                    initial = named["initial_" * cid]
                    rate = 10.0^named["k"] * (cid == "A" ? 2 : 3)
                    remaining = initial * exp(-rate * row.time)
                    push!(expected, row.observableId == "obs_x" ? 2 * remaining : initial - remaining)
                end
                @test actual ≈ expected rtol=1e-6 atol=1e-8
                @test Ext._adapter_predictions(problem, values) ≈ expected rtol=1e-6 atol=1e-8
            end
            # Condition formulas must retain their derivatives after rebuilding
            # PEtab's index caches, not merely match the value at one vector.
            delta = 1e-5
            fd = [(problem.petab.nllh(x + delta * (1:length(x) .== i)) -
                   problem.petab.nllh(x - delta * (1:length(x) .== i))) / (2delta)
                  for i in eachindex(x)]
            @test problem.petab.grad(x) ≈ fd rtol=1e-4 atol=1e-4
            @test read(xml_path, String) == xml
        end
    end
end
