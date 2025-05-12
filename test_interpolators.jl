using ODEParameterEstimation
using ModelingToolkit
using OrderedCollections
using Plots

# Define a simple test function
function test_interpolators()
    # Create some sample data
    xs = collect(range(0, 2π, 100))
    ys = sin.(xs)
    
    # Test working interpolators
    interpolators = Dict(
        "AAA" => aaad,
        "GPR" => aaad_gpr_pivot
    )
    
    # Plot the results
    p1 = plot(xs, ys, label="Original data", lw=2, title="Interpolation Comparison")
    p2 = plot(xs, cos.(xs), label="True derivative", lw=2, title="Derivative Comparison")
    
    # Test all interpolators
    for (name, interp_func) in interpolators
        # Create interpolator
        interp = interp_func(xs, ys)
        
        # Test at a few points
        test_points = collect(range(0, 2π, 200))
        interp_values = [interp(x) for x in test_points]
        
        # Plot interpolated values
        plot!(p1, test_points, interp_values, label=name)
        
        # Test derivatives
        deriv_values = [nth_deriv_at(interp, 1, x) for x in test_points]
        expected_deriv = cos.(test_points)
        
        # Plot derivatives
        plot!(p2, test_points, deriv_values, label="$name deriv")
        
        # Calculate error
        deriv_error = maximum(abs.(deriv_values - expected_deriv))
        println("$name derivative max error: $deriv_error")
    end
    
    # Save the plots
    plot_layout = plot(p1, p2, layout=(2,1), size=(800, 600))
    savefig(plot_layout, "interpolator_comparison.png")
    println("Plot saved to interpolator_comparison.png")
    
    return true
end

# Run the test
test_interpolators()