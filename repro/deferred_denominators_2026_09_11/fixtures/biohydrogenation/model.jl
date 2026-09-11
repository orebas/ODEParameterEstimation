# Equations, scales, and generating values extracted unchanged from the retained benchmark.
function benchmark_problem()
    name = "biohydrogenation"
    parameters = @parameters k5 k6 k7 k8 k9 k10 
    states = @variables  x4(t) x5(t) x6(t) x7(t)
    observables = @variables  y1(t) y2(t)
    state_equations = [
        D(x4) ~ (-8.0*k5*x4) / (8.0*(4.0*k6 + 8.0*x4)),
        D(x5) ~ ((-0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5) + (8.0*k5*x4) / (4.0*k6 + 8.0*x4)) / 0.5,
        D(x6) ~ ((-0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (10.0*k10) + (0.3*k7*x5) / (2.0*k8 + 0.5*x6 + 0.5*x5)) / 0.5,
        D(x7) ~ (0.2*(10.0*k10 - 0.5*x6)*k9*x6) / (5.0*k10),
    ]
    measured_quantities = [
        y1 ~ 8.0*x4,
        y2 ~ 0.5*x5,
    ]
    ic = [0.835, 0.341, 0.368, 0.401]
    p_true = [0.471, 0.287, 0.126, 0.806, 0.893, 0.741]

    time_interval = [0.0, 10.0]
    datasize = 750

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
