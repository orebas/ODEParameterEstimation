"""
Quick test to verify the CSTR adiabatic model simulates correctly.
Run this before the full parameter estimation to catch any model errors.
"""

using ODEParameterEstimation
using OrdinaryDiffEq
using Plots

include("cstr_adiabatic_model.jl")

function test_cstr_adiabatic_simulation()
    println("Creating CSTR adiabatic model...")
    pep = cstr_adiabatic()

    println("\nModel: $(pep.name)")
    println("Parameters: $(collect(keys(pep.p_true)))")
    println("True values: $(collect(values(pep.p_true)))")
    println("\nStates: $(collect(keys(pep.ic)))")
    println("Initial conditions: $(collect(values(pep.ic)))")
    println("\nTime interval: $(pep.recommended_time_interval)")

    # Try to simulate the model
    println("\nAttempting simulation...")

    try
        # Sample data to verify the model works
        opts = EstimationOptions(datasize = 101, noise_level = 0.0)
        sampled = sample_problem_data(pep, opts)

        println("Simulation successful!")

        # The sampled result has data_sample field
        if !isnothing(sampled.data_sample)
            println("Data sample available with $(length(sampled.data_sample)) measurements")
        end

        println("\nModel is ready for parameter estimation!")
        return true
    catch e
        println("Simulation failed!")
        showerror(stdout, e, catch_backtrace())
        return false
    end
end

using Statistics

if abspath(PROGRAM_FILE) == @__FILE__
    success = test_cstr_adiabatic_simulation()
    exit(success ? 0 : 1)
end
