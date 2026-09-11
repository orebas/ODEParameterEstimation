using ODEParameterEstimation, ModelingToolkit, Symbolics, OrderedCollections, Test
using ModelingToolkit: t_nounits as t, D_nounits as D

@testset "Deferred cleared derivatives preserve the differential equations" begin
    @parameters a b c
    @variables x(t) y(t)
    model, measured = create_ordered_ode_system("deferred_rational", [x], [a, b, c],
        [D(x) ~ a*x/(b+x)], [y ~ x/(c+x)])
    ODEPE = ODEParameterEstimation
    cleared_fields = (:states_lhs_cleared, :states_rhs_cleared, :obs_lhs_cleared, :obs_rhs_cleared)
    raw_fields = (:states_lhs, :states_rhs, :obs_lhs, :obs_rhs)
    dd = ODEPE.populate_derivatives(model.system, measured, 4, Dict(); include_cleared=false)
    raw_snapshot = deepcopy(dd)
    @test all(f -> isempty(getfield(dd, f)), cleared_fields)
    @test all(f -> length(getfield(dd, f)) == 4, raw_fields)

    # Independent product-rule identities, including the terms that would
    # change if we cleared derivatives of the rational equation instead.
    expected_states = [
        (b+x)*D(x) - a*x,
        (b+x)*D(D(x)) + D(x)^2 - a*D(x),
        (b+x)*D(D(D(x))) + 3D(x)*D(D(x)) - a*D(D(x)),
    ]
    expected_observations = [
        (c+x)*y - x,
        (c+x)*D(y) + y*D(x) - D(x),
        (c+x)*D(D(y)) + 2D(y)*D(x) + y*D(D(x)) - D(D(x)),
    ]
    @test ODEPE.ensure_cleared_derivatives!(dd, 0) === dd
    base_rows = map(f -> first(getfield(dd, f)), cleared_fields)
    @test all(f -> length(getfield(dd, f)) == 1, cleared_fields)
    ODEPE.ensure_cleared_derivatives!(dd, 2)
    for i in 1:3
        state_residual = only(dd.states_lhs_cleared[i] - dd.states_rhs_cleared[i])
        obs_residual = only(dd.obs_lhs_cleared[i] - dd.obs_rhs_cleared[i])
        @test iszero(Symbolics.simplify(state_residual - expected_states[i]; expand=true))
        @test iszero(Symbolics.simplify(obs_residual - expected_observations[i]; expand=true))
    end
    @test all(f -> length(getfield(dd, f)) == 3, cleared_fields)
    ODEPE.ensure_cleared_derivatives!(dd, 1)
    @test all(f -> length(getfield(dd, f)) == 3, cleared_fields)
    @test all(first(getfield(dd, f)) === row for (f, row) in zip(cleared_fields, base_rows))
    @test all(f -> isequal(getfield(dd, f), getfield(raw_snapshot, f)), raw_fields)
    @test_throws ArgumentError ODEPE.ensure_cleared_derivatives!(dd, -1)
    @test_throws ArgumentError ODEPE.ensure_cleared_derivatives!(dd, 4)

    # The existing default still supplies the complete cleared tables.
    eager = ODEPE.populate_derivatives(model.system, measured, 4, Dict())
    ODEPE.ensure_cleared_derivatives!(dd)
    @test all(f -> isequal(getfield(dd, f), getfield(eager, f)), (raw_fields..., cleared_fields...))

    # Parameter fixing must happen before either representation is constructed.
    fixed = ODEPE.populate_derivatives(model.system, measured, 3, Dict(b=>2.0); include_cleared=false)
    ODEPE.ensure_cleared_derivatives!(fixed, 0)
    @test iszero(Symbolics.simplify(only(fixed.states_lhs_cleared[1] - fixed.states_rhs_cleared[1]) -
        ((2+x)*D(x) - a*x); expand=true))

    # An exact observation-map Jacobian checks the actual numerical consumer.
    av, bv, cv, xv = 2.0, 3.0, 5.0, 7.0
    params = OrderedDict(a=>av, b=>bv, c=>cv)
    ic = OrderedDict(x=>xv)
    J, rank_dd = ODEPE.multipoint_numerical_jacobian(model.system, measured, 2, 1,
        Dict(), Num[a, b, c, x], params, [ic], merge(params, ic))
    dy = cv*av*xv/((cv+xv)^2*(bv+xv))
    exact_J = [0 0 -xv/(cv+xv)^2 cv/(cv+xv)^2;
        dy/av -dy/(bv+xv) dy*(1/cv-2/(cv+xv)) dy*(1/xv-2/(cv+xv)-1/(bv+xv))]
    @test J ≈ exact_J rtol=1e-12 atol=1e-14
    @test all(f -> isempty(getfield(rank_dd, f)), cleared_fields)
    support = ODEPE.ensure_si_template_dd_support(model, measured, rank_dd, Dict(1=>3))
    @test length(support.obs_lhs) == 4
    @test all(f -> isempty(getfield(support, f)), cleared_fields)
end
