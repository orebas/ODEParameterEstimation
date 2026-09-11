# Equations, scales, and generating values extracted unchanged from the retained benchmark.
function benchmark_problem()
    parameters = @parameters g a b
    states = @variables VV(t) R(t) 
    observables = @variables y1(t)
    p_true = [0.701, 0.66, 0.874]
    ic = [0.896, 0.461]

    equations =             [
                                 D(VV) ~ g * (VV - VV^3 / 3 + R),
                                 D(R) ~ 1 / g * (VV - a + b * R),
                            ]


    measured_quantities = [
            y1 ~ VV,
    ]

    model, mq = create_ordered_ode_system("fitzhugh_nagumo", states, parameters, equations, measured_quantities)

    PEP = ParameterEstimationProblem(
        "fitzhugh_nagumo",
        model,
        mq,
        nothing,
        [-1.0, 1.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic),
        0,
    )

    return PEP
end
