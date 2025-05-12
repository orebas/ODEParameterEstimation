using ODEParameterEstimation
using ModelingToolkit
using OrdinaryDiffEq
using OrderedCollections

println("Creating a simple test model...")

@parameters k1 k2 k3
@variables t r(t) w(t) y1(t)
D = Differential(t)

eqs = [
    D(r) ~ k1 * r - k2 * r * w,
    D(w) ~ k2 * r * w - k3 * w
]
states = [r, w]
params = [k1, k2, k3]
measured_quantities = [y1 ~ r]

@named model = ODESystem(eqs, t, states, params)
model = complete(model)
ordered_system = ODEParameterEstimation.OrderedODESystem(model, params, states)

ic = [0.333, 0.667]
p_true = [0.25, 0.5, 0.75]

# Create sample data
t_vector = collect(range(0.0, 1.0, length=21))
prob = ODEProblem(model, ic, (t_vector[1], t_vector[end]), p_true)
sol = solve(prob, Tsit5(), saveat=t_vector)

data_sample = OrderedDict(
    "t" => t_vector,
    r => sol[r, :]
)

# Create parameter estimation problem
println("Creating parameter estimation problem...")
pep = ODEParameterEstimation.ParameterEstimationProblem(
    "Test Lotka-Volterra",
    ordered_system,
    measured_quantities,
    data_sample,
    nothing,
    Tsit5(),
    p_true,
    ic,
    0
)

# Try to run with just a single point for speed
println("Running parameter estimation...")
@time results, unident_dict, trivial_dict, all_unidentifiable = ODEParameterEstimation.multipoint_parameter_estimation(
    pep, 
    max_num_points = 1,
    interpolator = ODEParameterEstimation.aaad
)

println("Num results: $(length(results))")
println("Completed successfully!")