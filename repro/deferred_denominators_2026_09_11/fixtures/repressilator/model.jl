# Equations, scales, and generating values extracted unchanged from the retained benchmark.
function benchmark_problem()
    name = "repressilator"
    parameters = @parameters beta n alpha 
    states = @variables  m1(t) m2(t) m3(t) p1(t) p2(t) p3(t)
    observables = @variables  y1(t) y2(t) y3(t)
    state_equations = [
        D(m1) ~ -m1 + (4.0*beta) / (0.5*(1 + 24.0*n*p3)),
        D(m2) ~ -m2 + (4.0*beta) / (0.5*(1 + 16.0*n*p1)),
        D(m3) ~ -m3 + (4.0*beta) / (0.5*(1 + 8.0*n*p2)),
        D(p1) ~ -2.0*alpha*(-0.125*m1 + p1),
        D(p2) ~ -2.0*alpha*(-0.25*m2 + p2),
        D(p3) ~ -2.0*alpha*(p3 - 0.08333333333333333*m3),
    ]
    measured_quantities = [
        y1 ~ 4.0*p1,
        y2 ~ 2.0*p2,
        y3 ~ 6.0*p3,
    ]
    ic = [0.746, 0.555, 0.426, 0.155, 0.658, 0.463]
    p_true = [0.592, 0.199, 0.778]

    time_interval = [0.0, 24.0]
    datasize = 1501

    model, mq = create_ordered_ode_system(
        name,
        states,
        parameters,
        state_equations,
        measured_quantities
    )

    return ParameterEstimationProblem(name, model, mq, nothing, time_interval,
        package_wide_default_ode_solver, OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic), 0)
end
