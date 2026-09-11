using Test, PEtab, ODEParameterEstimation, ModelingToolkit, Symbolics, OrderedCollections, Random
using ModelingToolkit: t_nounits as t, D_nounits as D
const Ext = Base.get_extension(ODEParameterEstimation, :ODEParameterEstimationPEtabExt)
const fixture = joinpath(@__DIR__, "fixtures", "decay", "problem.yaml")

# A controlled curve family isolates block/anchor/scoring plumbing from GP
# hyperparameter fitting. Fit its two coefficients to actual endpoint data.
struct FixtureExponential <: ODEParameterEstimation.AbstractInterpolator
    offset::Float64
    amplitude::Float64
end
(f::FixtureExponential)(time) = f.offset + f.amplitude * exp(-0.4*time)
function fixture_exponential(times, values)
    amplitude = (last(values)-first(values))/(exp(-0.4*last(times))-exp(-0.4*first(times)))
    return FixtureExponential(first(values)-amplitude*exp(-0.4*first(times)), amplitude)
end

@testset "Bounded experiment pools combine information before fixing" begin
    @parameters a b
    @variables x(t) z(t) y1(t) y2(t)
    model, measured = create_ordered_ode_system("joint_decay", [x, z], [a, b],
        [D(x) ~ -(a+b)*x, D(z) ~ -(a-b)*z], [y1 ~ x, y2 ~ z])
    data = ObservationData([
        ObservationSeries("y1", "A", x, [0.0, 0.5, 1.0], exp.(-3 .* [0.0, 0.5, 1.0])),
        ObservationSeries("y2", "B", z, [0.0, 0.3, 1.0], 2exp.(-[0.0, 0.3, 1.0]))])
    pep = ParameterEstimationProblem("joint_decay", model, measured, data,
        [0.0, 1.0], package_wide_default_ode_solver,
        OrderedDict{Num, Float64}(), OrderedDict{Num, Float64}(), 0)
    problem = Ext.PEtabAlgebraicProblem("", nothing, pep, ["a", "b"], [a, b], [:lin, :lin],
        OrderedDict(x=>Num(1), z=>Num(2)), OrderedDict("A"=>[x], "B"=>[z]), Num[],
        OrderedDict("A"=>0.0, "B"=>0.0), String[])
    single = Ext._experiment_frontier(problem, pep, ["A"]; max_derivative_order=2)
    @test isnothing(single.frontier.selected)
    @test last(single.trace).rank == 2
    @test last(single.trace).variable_count == 3
    joint = Ext._experiment_frontier(problem, pep, ["A", "B"]; max_derivative_order=10)
    @test !isnothing(joint.frontier.selected)
    @test last(joint.trace).derivative_order == 1
    @test last(joint.trace).rank == last(joint.trace).variable_count == 4
    @test Set(joint.params) == Set([a, b])
    selected = joint.frontier.selected
    # Exact independent jets: x(0.5), x'(0.5), z(0.4), z'(0.4).
    values = Float64[]
    for dv in selected.data_vars
        bi, _, order = joint.data_map[Num(dv)]
        push!(values, bi == 1 ? (-3.0)^order*exp(-1.5) : (-1.0)^order*2exp(-0.4))
    end
    sols = ODEParameterEstimation.solve_with_hc_parameterized(selected.equations,
        selected.solve_vars, selected.data_vars, [values]; options=Dict(:gamma_seed=>42))
    @test length(only(sols)) == 1
    recovered = Dict(zip(Num.(selected.solve_vars), only(only(sols))))
    @test recovered[a] ≈ 2 atol=1e-8
    @test recovered[b] ≈ 1 atol=1e-8
    @test all(haskey(recovered, v) for block in joint.blocks for v in Base.values(block.flat))
    @test_throws ArgumentError Ext._experiment_groups(problem, [["A", "A"]])
    @test_throws ArgumentError Ext._experiment_groups(problem, [["missing"]])
    @test_throws ArgumentError Ext._experiment_groups(problem, [fill("A", 7)])

    # Two rational observables of the same ratio do not supply two independent
    # constraints. Clearing denominators and probing arbitrary data would give
    # spurious rank here; the selector must differentiate the rational map.
    ratio = x/(a+x)
    rational_model, rational_measured = create_ordered_ode_system("ratio", [x], [a],
        [D(x) ~ 0], [y1 ~ ratio, y2 ~ ratio^2])
    rational_data = ObservationData([
        ObservationSeries("y1", "A", ratio, [0.0, 1.0], [0.5, 0.5]),
        ObservationSeries("y2", "A", ratio^2, [0.0, 1.0], [0.25, 0.25])])
    rational_pep = ParameterEstimationProblem("ratio", rational_model, rational_measured, rational_data,
        [0.0, 1.0], package_wide_default_ode_solver,
        OrderedDict{Num, Float64}(), OrderedDict{Num, Float64}(), 0)
    rational_problem = Ext.PEtabAlgebraicProblem("", nothing, rational_pep, ["a"], [a], [:lin],
        OrderedDict(x=>Num(1)), OrderedDict("A"=>[x]), Num[], OrderedDict("A"=>0.0), String[])
    events = NamedTuple[]
    deficient = Ext._experiment_frontier(rational_problem, rational_pep, ["A"];
        max_derivative_order=1, progress=event -> push!(events, event))
    @test isnothing(deficient.frontier.selected)
    @test last(deficient.trace).rank == 1
    @test last(deficient.trace).variable_count == 2
    @test all(event -> event.stage == :experiment_rank, events)
    @test [event.trace[end].derivative_order for event in events] == [0, 1]
end

@testset "Rational experiment pools clear only at a feasible depth" begin
    @parameters a
    @variables x(t) y1(t) y2(t)
    ratio = x/(1+x)
    model, measured = create_ordered_ode_system("saturating_decay", [x], [a],
        [D(x) ~ -a*x/(1+x)], [y1 ~ ratio, y2 ~ ratio^2])
    data = ObservationData([
        ObservationSeries("y1", "A", ratio, [0.0, 1.0], [2/3, 1/2]),
        ObservationSeries("y2", "A", ratio^2, [0.0, 1.0], [4/9, 1/4])])
    pep = ParameterEstimationProblem("saturating_decay", model, measured, data,
        [0.0, 1.0], package_wide_default_ode_solver,
        OrderedDict{Num, Float64}(), OrderedDict{Num, Float64}(), 0)
    problem = Ext.PEtabAlgebraicProblem("", nothing, pep, ["a"], [a], [:lin],
        OrderedDict(x=>Num(2)), OrderedDict("A"=>[x]), Num[], OrderedDict("A"=>0.0), String[])
    events = NamedTuple[]
    built = Ext._experiment_frontier(problem, pep, ["A"]; max_derivative_order=4,
        progress=event -> push!(events, event))
    @test [event.stage for event in events] ==
        [:experiment_rank, :experiment_polynomialization, :experiment_rank]
    @test events[2].derivative_order == 1
    @test events[2].equation_count == 4
    @test [row.rank for row in built.trace] == [1, 2]
    @test last(built.trace).derivative_order == 1

    # Compare with the old eager pool, including support-based basis choices.
    ODEPE = ODEParameterEstimation
    equations = Num[]
    metadata = ODEPE.NoiseEqMeta[]
    for (i, (dv, (bi, _, order))) in enumerate(built.data_map)
        eq = ODEPE.clear_denoms(built.jets[i] ~ dv)
        polynomial = Num(eq.lhs - eq.rhs)
        push!(equations, polynomial)
        push!(metadata, (point=bi, source_index=i, max_observed_order=order,
            support_score=Float64(length(Symbolics.get_variables(polynomial))) + 1e-3*length(string(polynomial))))
    end
    variables = vcat(built.params, collect(values(only(built.blocks).flat)))
    eager_pool = (; symbolic_equations=equations, instantiated_equations=built.jets,
        instantiated_vars=variables, metadata, template_DD=nothing,
        full_equation_count=length(equations), n_points=1)
    eager = ODEPE._noise_select_pool(pep, eager_pool; compute_mixed_volume=false,
        candidate_limit=8, beam_width=4)
    @test built.frontier.frontier == eager.frontier
    @test built.frontier.selected.selected_equation_indices == eager.selected.selected_equation_indices
    @test built.frontier.selected.eq_metadata == eager.selected.eq_metadata
    @test isequal(built.frontier.selected.equations, eager.selected.equations)
    @test isequal(built.frontier.selected.solve_vars, eager.selected.solve_vars)
    @test isequal(built.frontier.selected.data_vars, eager.selected.data_vars)

    # Exact jets at x=2, a=3; the data fixtures above are not used for this check.
    selected = built.frontier.selected
    exact_jets = Dict((1,1,0)=>2/3, (1,2,0)=>4/9, (1,1,1)=>-2/9, (1,2,1)=>-8/27)
    observed = [exact_jets[built.data_map[Num(dv)]] for dv in selected.data_vars]
    x0 = only(values(only(built.blocks).flat))
    truth = Dict(a=>3.0, x0=>2.0)
    @test isnothing(Ext._experiment_root_error(built, selected, truth, observed))
    @test !isnothing(Ext._experiment_root_error(built, selected, Dict(a=>3.0, x0=>-1.0), observed))
    @test !isnothing(Ext._experiment_root_error(built, selected, Dict(a=>4.0, x0=>2.0), observed))
    substituted = merge(truth, Dict(Num(dv)=>value for (dv,value) in zip(selected.data_vars, observed)))
    @test all(eq -> abs(Float64(Symbolics.value(Symbolics.substitute(eq, substituted)))) < 1e-10,
        selected.equations)
end

@testset "Experiment candidates retain the full PEtab objective" begin
    problem = load_petab_problem(fixture)
    start = Float64.(PEtab.get_x(problem.petab)) .+ 0.01
    options = EstimationOptions(interpolator=InterpolatorCustom,
        custom_interpolator=fixture_exponential, shooting_points=1, compute_uncertainty=false)
    calls = Ref(0)
    callback = (p, x, seconds) -> begin
        @test p === problem.petab
        @test length(x) == length(start)
        calls[] += 1
        (; xmin=x, fmin=p.nllh(x), converged=:unchanged_test_seed)
    end
    result = estimate_petab_problem(problem; options, x0=start,
        experiment_groups=[["A", "B"]], max_derivative_order=1, polish=callback)
    @test result.status == :success
    @test !isempty(result.candidates)
    @test calls[] == 1
    @test !isnothing(result.refined)
    for candidate in result.candidates
        @test candidate.nllh ≈ problem.petab.nllh(candidate.x)
        @test Set(keys(candidate.state_times)) == Set(["A", "B"])
        @test all(>(0.5), values(candidate.state_times))
        @test candidate.provenance["source_type"] == "multi_experiment"
        @test isempty(candidate.provenance["structural_fix_set"])
    end
end

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

    # A subset seed must not invent preparations for experiments it never fit.
    subset_states = OrderedDict(s=>state_values[s] for s in problem.condition_states["A"])
    subset = (; parameters=candidate.parameters, states=subset_states,
        state_times=OrderedDict("A"=>0.5))
    subset_vector, subset_residual = Ext._candidate_vector(problem, subset, x .+ 0.01)
    subset_by_name = Dict(zip(problem.parameter_ids, subset_vector))
    @test subset_by_name["initial_A"] ≈ 2.0 atol=1e-8
    @test subset_by_name["initial_B"] == (x .+ 0.01)[findfirst(==("initial_B"), problem.parameter_ids)]
    @test subset_by_name["k"] ≈ log10(0.4) atol=1e-10
    @test subset_residual < 1e-8
    @test isfinite(problem.petab.nllh(subset_vector))

    # Y depends on X, but X does not depend on Y. Observing only X can safely
    # omit Y's local state; the original full likelihood still observes Y.
    xi = findfirst(s -> s.experiment_id == "A" && s.observable_id == "obs_x",
        problem.algebraic.data_sample.series)
    x_data = ObservationData(problem.algebraic.data_sample.series[[xi]])
    x_pep = ParameterEstimationProblem("only_x", problem.algebraic.model,
        problem.algebraic.measured_quantities[[xi]], x_data, [0.0, 3.0],
        problem.algebraic.solver, OrderedDict{Num, Float64}(), OrderedDict{Num, Float64}(), 0)
    block = only(Ext._experiment_blocks(problem, x_pep, ["A"]))
    @test length(block.states) == length(block.omitted_states) == 1
    x_candidate = (; parameters=candidate.parameters,
        states=OrderedDict(s=>state_values[s] for s in block.states), state_times=OrderedDict("A"=>0.5))
    x_vector, _ = Ext._candidate_vector(problem, x_candidate, x .+ 0.01)
    @test x_vector ≈ subset_vector atol=1e-8

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
