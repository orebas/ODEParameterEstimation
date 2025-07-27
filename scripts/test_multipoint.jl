using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using OrdinaryDiffEq

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
prob = ODEProblem(model, merge(Dict(states .=> ic), Dict(params .=> p_true)), (t_vector[1], t_vector[end]))
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

# Run multipoint parameter estimation
results, unident_dict, trivial_dict, all_unidentifiable = ODEParameterEstimation.multipoint_parameter_estimation(
    pep,
    max_num_points = 2,
    interpolator = ODEParameterEstimation.aaad,
    nooutput = false
)

println("Results: ", results)
println("Success!")