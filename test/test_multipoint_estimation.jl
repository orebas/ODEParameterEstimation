using ODEParameterEstimation
using Test
using ModelingToolkit
using OrderedCollections
using OrdinaryDiffEq

@testset "Multipoint Estimation" begin
    @testset "setup_parameter_estimation" begin
        # Create a simple test problem
        @parameters a b
        @variables t x1(t) x2(t) y1(t) y2(t)
        D = Differential(t)
        
        eqs = [
            D(x1) ~ -a * x2,
            D(x2) ~ b * x1
        ]
        states = [x1, x2]
        params = [a, b]
        measured_quantities = [y1 ~ x1, y2 ~ x2]
        
        @named model = ODESystem(eqs, t, states, params)
        model = complete(model)
        ordered_system = ODEParameterEstimation.OrderedODESystem(model, params, states)
        
        ic = [1.0, 0.5]
        p_true = [2.0, 1.0]
        
        # Create data sample
        t_vector = collect(range(0.0, 1.0, length=21))
        prob = ODEProblem(model, ic, (t_vector[1], t_vector[end]), p_true)
        sol = solve(prob, Tsit5(), saveat=t_vector)
        
        data_sample = OrderedDict(
            "t" => t_vector,
            x1 => sol[x1, :],
            x2 => sol[x2, :]
        )
        
        # Create ParameterEstimationProblem
        pep = ODEParameterEstimation.ParameterEstimationProblem(
            "Test",
            ordered_system,
            measured_quantities,
            data_sample,
            nothing,
            Tsit5(),
            p_true,
            ic,
            0
        )
        
        # Test setup_parameter_estimation function
        setup_data = ODEParameterEstimation.setup_parameter_estimation(
            pep,
            max_num_points = 2,
            point_hint = 0.5,
            nooutput = true,
            interpolator = ODEParameterEstimation.aaad
        )
        
        # Basic validity checks
        @test setup_data.states == states
        @test setup_data.params == params
        @test setup_data.t_vector == t_vector
        @test !isnothing(setup_data.interpolants)
        @test !isnothing(setup_data.good_deriv_level)
        @test !isnothing(setup_data.good_udict)
        @test !isnothing(setup_data.good_varlist)
        @test !isnothing(setup_data.good_DD)
        @test !isempty(setup_data.time_index_set)
    end
    
    # More tests will be added for the other functions
end