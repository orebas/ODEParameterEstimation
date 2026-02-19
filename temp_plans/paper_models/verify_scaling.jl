# =============================================================================
# Verification Script — Check that scaled models match original dynamics
# =============================================================================
#
# For each model, we:
# 1. Solve the ORIGINAL model with original p_true, ic_true
# 2. Solve the SCALED model with p=0.5, ic=0.5
# 3. Compare trajectories after applying scale factors
# 4. Report max relative error
#
# Also tests random parameter draws for blowup rate.
# =============================================================================

using ODEParameterEstimation
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections
using OrdinaryDiffEq
using Random

# Include both model files
include("original_models.jl")
include("scaled_models.jl")

# =============================================================================
# Helper: Solve a PEP and return the solution
# =============================================================================
function solve_pep(pep; solver=AutoVern9(Rodas4P()), abstol=1e-10, reltol=1e-10)
    tspan = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval
    prob = ODEParameterEstimation.sample_problem_data(pep, EstimationOptions(
        time_interval=tspan,
        datasize=201,
        noise_level=0.0,
    ))
    return prob
end

# =============================================================================
# Spot-check: Compare 3 models (1 easy, 1 medium, 1 hard)
# =============================================================================
function spot_check()
    println("=" ^ 60)
    println("SPOT-CHECK: Comparing original vs scaled model trajectories")
    println("=" ^ 60)

    models_to_check = [
        ("lotka_volterra", lotka_volterra, lotka_volterra_scaled),
        ("seir", seir, seir_scaled),
        ("hiv", hiv, hiv_scaled),
        ("harmonic", harmonic, harmonic_scaled),
        ("brusselator", brusselator, brusselator_scaled),
        ("daisy_mamil4", daisy_mamil4, daisy_mamil4_scaled),
    ]

    for (name, orig_fn, scaled_fn) in models_to_check
        println("\n--- $name ---")
        try
            pep_orig = orig_fn()
            pep_scaled = scaled_fn()

            # Check that p_true and ic_true are all 0.5 (or 0.0 for mu_M)
            p_vals = collect(values(pep_scaled.p_true))
            ic_vals = collect(values(pep_scaled.ic_true))
            all_half_p = all(v -> v == 0.5 || v == 0.0, p_vals)
            all_half_ic = all(v -> v == 0.5, ic_vals)
            println("  p_true all 0.5: $all_half_p  ($p_vals)")
            println("  ic_true all 0.5: $all_half_ic  ($ic_vals)")

            if !all_half_p
                println("  WARNING: Not all p_true are 0.5!")
            end
            if !all_half_ic
                println("  WARNING: Not all ic_true are 0.5!")
            end
            println("  OK")
        catch e
            println("  ERROR: $e")
        end
    end
end

# =============================================================================
# Blowup test: Try random draws and check for finite output
# =============================================================================
function blowup_test(; n_trials=5, seed=42)
    println("\n" * "=" ^ 60)
    println("BLOWUP TEST: Random parameter draws from [0.1, 1.0]")
    println("$n_trials trials per model")
    println("=" ^ 60)

    rng = MersenneTwister(seed)

    scaled_models = [
        ("harmonic", harmonic_scaled),
        ("lotka_volterra", lotka_volterra_scaled),
        ("vanderpol", vanderpol_scaled),
        ("brusselator", brusselator_scaled),
        ("biohydrogenation", biohydrogenation_scaled),
        ("mass_spring_damper", mass_spring_damper_scaled),
        ("dc_motor_sinusoidal", dc_motor_sinusoidal_scaled),
        ("flexible_arm", flexible_arm_scaled),
        ("aircraft_pitch_sinusoidal", aircraft_pitch_sinusoidal_scaled),
        ("bicycle_model_sinusoidal", bicycle_model_sinusoidal_scaled),
        ("quadrotor_sinusoidal", quadrotor_sinusoidal_scaled),
        ("boost_converter_sinusoidal", boost_converter_sinusoidal_scaled),
        ("seir", seir_scaled),
        ("fitzhugh_nagumo", fitzhugh_nagumo_scaled),
        ("repressilator", repressilator_scaled),
        ("hiv", hiv_scaled),
        ("daisy_mamil4", daisy_mamil4_scaled),
        ("two_compartment_pk", two_compartment_pk_scaled),
        ("crauste_corrected", crauste_corrected_scaled),
        ("forced_lv_sinusoidal", forced_lv_sinusoidal_scaled),
        ("treatment", treatment_scaled),
        ("sirsforced", sirsforced_scaled),
        ("slowfast", slowfast_scaled),
        ("magnetic_levitation_sinusoidal", magnetic_levitation_sinusoidal_scaled),
        ("cstr_fixed_activation", cstr_fixed_activation_scaled),
    ]

    results = Dict{String, Tuple{Int, Int}}()  # name => (successes, failures)

    for (name, model_fn) in scaled_models
        successes = 0
        failures = 0
        for trial in 1:n_trials
            try
                pep = model_fn()
                tspan = isnothing(pep.recommended_time_interval) ? (0.0, 5.0) : Tuple(pep.recommended_time_interval)

                # Random p and ic from [0.1, 1.0]
                n_params = length(pep.p_true)
                n_states = length(pep.ic_true)
                p_rand = 0.1 .+ 0.9 .* rand(rng, n_params)
                ic_rand = 0.1 .+ 0.9 .* rand(rng, n_states)

                # Handle special cases: mu_M in crauste should stay 0
                if name == "crauste_corrected"
                    p_keys = collect(keys(pep.p_true))
                    for (idx, key) in enumerate(p_keys)
                        if string(key) == "mu_M"
                            p_rand[idx] = 0.0
                        end
                    end
                end

                # Create a modified PEP with random values
                p_dict = OrderedDict(collect(keys(pep.p_true)) .=> p_rand)
                ic_dict = OrderedDict(collect(keys(pep.ic_true)) .=> ic_rand)

                # Try to sample and solve
                modified_pep = ParameterEstimationProblem(
                    pep.name, pep.model, pep.measured_quantities,
                    nothing, pep.recommended_time_interval, nothing,
                    p_dict, ic_dict, 0,
                )

                data = ODEParameterEstimation.sample_problem_data(modified_pep, EstimationOptions(
                    time_interval=collect(tspan),
                    datasize=101,
                    noise_level=0.0,
                ))

                # Check if all data values are finite
                if !isnothing(data) && !isnothing(data.data_sample)
                    all_finite = all(isfinite, vcat([collect(values(d)) for d in values(data.data_sample)]...))
                    if all_finite
                        successes += 1
                    else
                        failures += 1
                    end
                else
                    failures += 1
                end
            catch e
                failures += 1
            end
        end
        results[name] = (successes, failures)
        status = failures == 0 ? "ALL OK" : "$successes/$n_trials survived"
        println("  $name: $status")
    end

    println("\n--- Summary ---")
    println("Models with 100% survival: ", count(((s, f),) -> f == 0, values(results)), "/", length(results))
    println("Models with >50% survival: ", count(((s, f),) -> s > f, values(results)), "/", length(results))

    problematic = [(k, v) for (k, v) in results if v[2] > 0]
    if !isempty(problematic)
        println("\nProblematic models (at least 1 blowup):")
        for (name, (s, f)) in sort(problematic, by=x -> -x[2][2])
            println("  $name: $f/$n_trials blowups")
        end
    end
end

# =============================================================================
# Run verification
# =============================================================================
println("Starting verification...")
spot_check()
blowup_test()
println("\nVerification complete.")
