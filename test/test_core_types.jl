using ODEParameterEstimation
using Test
using ModelingToolkit
using OrderedCollections
using Symbolics

@testset "Core Types" begin
    @testset "OrderedODESystem" begin
        # Create a simple test ODE system
        @parameters a b
        @variables t x1(t) x2(t)
        D = Differential(t)
        
        eqs = [
            D(x1) ~ -a * x2,
            D(x2) ~ b * x1
        ]
        states = [x1, x2]
        params = [a, b]
        
        @named model = ODESystem(eqs, t, states, params)
        
        # Create OrderedODESystem
        ordered_sys = ODEParameterEstimation.OrderedODESystem(model, params, states)
        
        # Test type and property access
        @test typeof(ordered_sys) == ODEParameterEstimation.OrderedODESystem
        @test ordered_sys.system === model
        @test ordered_sys.original_parameters == params
        @test ordered_sys.original_states == states
    end
    
    @testset "ParameterEstimationProblem" begin
        # Create a simple test ODE system
        @parameters a b
        @variables t x1(t) x2(t) y1(t)
        D = Differential(t)
        
        eqs = [
            D(x1) ~ -a * x2,
            D(x2) ~ b * x1
        ]
        states = [x1, x2]
        params = [a, b]
        measured_quantities = [y1 ~ x1]
        
        @named model = ODESystem(eqs, t, states, params)
        ordered_sys = ODEParameterEstimation.OrderedODESystem(model, params, states)
        
        # Basic PEP with no data
        pep = ODEParameterEstimation.ParameterEstimationProblem(
            "TestModel",
            ordered_sys,
            measured_quantities,
            nothing,
            nothing,
            ODEParameterEstimation.package_wide_default_ode_solver,
            [0.5, 1.0],  # p_true
            [1.0, 2.0],  # ic
            0            # unident_count
        )
        
        # Check properties
        @test pep.name == "TestModel"
        @test pep.model === ordered_sys
        @test pep.measured_quantities == measured_quantities
        @test isnothing(pep.data_sample)
        @test isnothing(pep.recommended_time_interval)
        @test isequal(pep.p_true, [0.5, 1.0])
        @test isequal(pep.ic, [1.0, 2.0])
        @test pep.unident_count == 0
        
        # PEP with data sample
        data_dict = OrderedDict(
            "t" => [0.0, 0.1, 0.2],
            x1 => [1.0, 1.1, 1.2]
        )
        
        pep2 = ODEParameterEstimation.ParameterEstimationProblem(
            "TestModel2",
            ordered_sys,
            measured_quantities,
            data_dict,
            [-0.5, 0.5],
            ODEParameterEstimation.package_wide_default_ode_solver,
            [0.5, 1.0],
            [1.0, 2.0],
            0
        )
        
        @test pep2.name == "TestModel2"
        @test pep2.data_sample === data_dict
        @test pep2.recommended_time_interval == [-0.5, 0.5]
    end
    
    @testset "DerivativeData" begin
        # Create test data
        states_lhs = [[Symbolics.wrap(Symbol("x1"))] ]
        states_rhs = [[Symbolics.wrap(Symbol("y1"))] ]
        obs_lhs = [[Symbolics.wrap(Symbol("obs1"))] ]
        obs_rhs = [[Symbolics.wrap(Symbol("val1"))] ]
        all_unident = Set([Symbolics.wrap(Symbol("param1"))])
        
        # Create DerivativeData object
        dd = ODEParameterEstimation.DerivativeData(
            states_lhs, states_rhs, obs_lhs, obs_rhs,
            states_lhs, states_rhs, obs_lhs, obs_rhs,
            all_unident
        )
        
        # Check properties
        @test dd.states_lhs_cleared === states_lhs
        @test dd.states_rhs_cleared === states_rhs
        @test dd.obs_lhs_cleared === obs_lhs
        @test dd.obs_rhs_cleared === obs_rhs
        @test dd.states_lhs === states_lhs
        @test dd.states_rhs === states_rhs
        @test dd.obs_lhs === obs_lhs
        @test dd.obs_rhs === obs_rhs
        @test dd.all_unidentifiable === all_unident
    end
    
    @testset "ParameterEstimationResult" begin
        # Create test data
        @parameters a b
        @variables t x1(t) x2(t)
        
        params_dict = OrderedDict([a => 0.5, b => 1.0])
        states_dict = OrderedDict([x1 => 1.0, x2 => 2.0])
        
        # Create result object
        result = ODEParameterEstimation.ParameterEstimationResult(
            params_dict,
            states_dict,
            0.0,            # at_time
            1e-5,           # err
            :Success,       # return_code
            10,             # datasize
            nothing,        # report_time
            Dict(b => 1.0), # unident_dict
            Set([b]),       # all_unidentifiable
            nothing         # solution
        )
        
        # Check properties
        @test result.parameters === params_dict
        @test result.states === states_dict
        @test result.at_time == 0.0
        @test result.err == 1e-5
        @test result.return_code == :Success
        @test result.datasize == 10
        @test isnothing(result.report_time)
        @test haskey(result.unident_dict, b)
        @test b in result.all_unidentifiable
        @test isnothing(result.solution)
    end
    
    @testset "Constants" begin
        # Test that constants are defined and have expected types
        @test typeof(ODEParameterEstimation.CLUSTERING_THRESHOLD) <: AbstractFloat
        @test typeof(ODEParameterEstimation.MAX_ERROR_THRESHOLD) <: AbstractFloat
        @test typeof(ODEParameterEstimation.IMAG_THRESHOLD) <: AbstractFloat
        @test typeof(ODEParameterEstimation.MAX_SOLUTIONS) <: Integer
    end
end