using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections

# Import constants from ODEParameterEstimation
const D = ODEParameterEstimation.D
const t = ODEParameterEstimation.t

# Define a minimal Lotka-Volterra test case
function test_lotka_volterra()
    @parameters k1 k2 k3 
    @variables t r(t) w(t) y1(t)
    
    # Define the Lotka-Volterra system
    states = [r, w]
    parameters = [k1, k2, k3]
    derivatives = [
        D(r) ~ k1 * r - k2 * r * w,
        D(w) ~ k2 * r * w - k3 * w
    ]
    
    # Define measurement
    observed = [y1 ~ r]
    
    # Create the system
    model, mq = create_ordered_ode_system("lotka-volterra_minimal", states, parameters, derivatives, observed)
    
    # Define true parameters and initial conditions
    p_true = OrderedDict(parameters .=> [0.5, 0.5, 0.5])
    ic = OrderedDict(states .=> [1.0, 1.0])
    
    # Create parameter estimation problem
    pep = ParameterEstimationProblem(
        "lotka-volterra_minimal",
        model, 
        mq,
        nothing, 
        [0.0, 1.0],
        package_wide_default_ode_solver,
        p_true,
        ic,
        0
    )
    
    # Sample some data
    sampled_pep = sample_problem_data(pep, datasize=21, noise_level=0.0)
    
    # Try to estimate the parameters
    result = analyze_parameter_estimation_problem(sampled_pep, nooutput=false)
    
    return result
end

# Run the test
result = test_lotka_volterra()
println("Test completed successfully!")