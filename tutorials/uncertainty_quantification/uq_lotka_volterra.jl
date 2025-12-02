# =============================================================================
# UQ Tutorial: Lotka-Volterra (Predator-Prey)
# =============================================================================
#
# This advanced tutorial demonstrates Uncertainty Quantification (UQ) on a 
# nonlinear system with PARTIAL OBSERVABILITY.
#
# System: Lotka-Volterra
#   dr/dt = k1*r - k2*r*w   (Prey)
#   dw/dt = k2*r*w - k3*w   (Predator)
#
# Measurement:
#   y1 = r  (We only see the Prey!)
#
# We will try to estimate k1, k2, k3 AND the hidden predator population w(0)
# just from observing the prey population.
#
# =============================================================================

using ODEParameterEstimation
using CairoMakie
using Colors
using ColorSchemes
using Random
using LinearAlgebra
using Printf
using Statistics
using Distributions
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrderedCollections

# Set random seed for reproducibility
Random.seed!(123)

# =============================================================================
# Part 1: Color Scheme and Plot Styling
# =============================================================================

const COLORS = (
    data = colorant"#0077BB",        # Blue - data points
    gp_mean = colorant"#009988",     # Teal - GP mean
    gp_band = colorant"#009988",     # Teal - GP uncertainty band
    true_sol = colorant"#CC3311",    # Red - true solution
    param1 = colorant"#EE7733",      # Orange
    param2 = colorant"#0077BB",      # Blue
    param3 = colorant"#009988",      # Teal
    param4 = colorant"#33BBEE",      # Cyan
    param5 = colorant"#EE3377",      # Magenta
)

function setup_makie_theme!()
    set_theme!(Theme(
        fontsize = 14,
        Axis = (
            xlabelsize = 14, ylabelsize = 14, titlesize = 16,
            xgridvisible = true, ygridvisible = true,
            xgridstyle = :dash, ygridstyle = :dash,
            xgridwidth = 0.5, ygridwidth = 0.5,
        ),
        Legend = (framevisible = true, labelsize = 11),
    ))
end

setup_makie_theme!()

# =============================================================================
# Part 2: Define the Problem
# =============================================================================

println("=" ^ 80)
println("UQ TUTORIAL: LOTKA-VOLTERRA (Full State Estimation)")
println("=" ^ 80)

println("\n📚 Loading the Lotka-Volterra Model...")
# We need to redefine the model to observe BOTH states
function lotka_volterra_full()
    parameters = @parameters k1 k2 k3
    states = @variables r(t) w(t)
    observables = @variables y1(t) y2(t)
    p_true = [1.0, 0.5, 0.3]
    ic_true = [2.0, 1.0]

    equations = [
        D(r) ~ k1 * r - k2 * r * w,
        D(w) ~ k2 * r * w - k3 * w,
    ]
    # OBSERVE BOTH STATES
    measured_quantities = [y1 ~ r, y2 ~ w]

    model, mq = create_ordered_ode_system("Lotka_Volterra_Full", states, parameters, equations, measured_quantities)

    return ParameterEstimationProblem(
        "lotka_volterra_full",
        model,
        mq,
        nothing,
        [0.0, 10.0],
        nothing,
        OrderedDict(parameters .=> p_true),
        OrderedDict(states .=> ic_true),
        0,
    )
end

pep = lotka_volterra_full()
println("   Model name: $(pep.name)")
println("   True parameters: ")
for (k, v) in pep.p_true; println("      $k = $v"); end
println("   Initial conditions: ")
for (k, v) in pep.ic; println("      $k = $v"); end

# Use a shorter time interval to capture just the first peak/valley clearly
# The full cycle is ~6-7 units. Let's observe 0 to 10.
time_interval = [0.0, 10.0]
println("   Time interval: $time_interval")

# =============================================================================
# Part 3: Generate Synthetic Data
# =============================================================================

println("\n📊 Generating Synthetic Data (Observing Both Populations)...")

# Noise level 
noise_level = 0.05  # 5% noise

opts = EstimationOptions(
    datasize = 41,                    # 41 points over 10s = 0.25s sampling
    noise_level = noise_level,
    time_interval = time_interval,
    flow = FlowDirectOpt,
    compute_uncertainty = true,
    nooutput = true,
)

pep_sampled = sample_problem_data(pep, opts)

println("   Data points: $(opts.datasize)")
println("   Noise level: $(noise_level * 100)%")

# =============================================================================
# Part 4: Run Parameter Estimation with UQ
# =============================================================================

println("\n🔬 Running Parameter Estimation with UQ...")
println("   (Attempting to recover hidden predator dynamics...)")

@time result = analyze_parameter_estimation_problem(pep_sampled, opts)
results_tuple, analysis_results, uq_result = result

println("\n✅ Parameter Estimation Complete!")

# =============================================================================
# Part 5: Interpret Results
# =============================================================================

println("\n" * "=" ^ 80)
println("RESULTS SUMMARY")
println("=" ^ 80)

if !isnothing(uq_result) && uq_result.success
    println("\n📈 Parameter Estimates with Uncertainty:")
    println("-" ^ 70)
    println(@sprintf("%-15s | %12s | %12s | %12s", "Parameter", "Estimate", "Std Dev", "95% CI Half"))
    println("-" ^ 70)

    # Extract estimates from best result
    estimates = Dict{Symbol, Float64}()
    if length(analysis_results) >= 1 && isa(analysis_results[1], Vector) && length(analysis_results[1]) >= 1
        first_result = analysis_results[1][1]
        
        function key_to_sym(k)
            k_str = split(string(k), "(")[1]
            return Symbol(k_str)
        end

        if hasfield(typeof(first_result), :states)
            for (k, v) in first_result.states; estimates[key_to_sym(k)] = Float64(real(v)); end
        end
        if hasfield(typeof(first_result), :parameters)
            for (k, v) in first_result.parameters; estimates[key_to_sym(k)] = Float64(real(v)); end
        end
    end

    for (i, name) in enumerate(uq_result.param_names)
        std_val = uq_result.param_std[i]
        ci_half = 1.96 * std_val
        est_val = get(estimates, name, NaN)
        
        # Mark if this is a hidden state or parameter related to hidden state
        marker = ""
        if string(name) == "w" || string(name) == "k3"
            marker = "(hidden)"
        end

        println(@sprintf("%-15s | %12.6f | %12.6f | %12.6f %s", 
                string(name), est_val, std_val, ci_half, marker))
    end
    println("-" ^ 70)

    println("\n📊 Parameter Correlation Matrix:")
    cov_mat = uq_result.param_covariance
    n = size(cov_mat, 1)
    stds = sqrt.(max.(diag(cov_mat), 0.0))
    
    print("      ")
    for name in uq_result.param_names
        print(@sprintf("%7s", string(name)[1:min(7, length(string(name)))]))
    end
    println()

    for i in 1:n
        print(@sprintf("%-6s", string(uq_result.param_names[i])[1:min(6, length(string(uq_result.param_names[i])))]) )
        for j in 1:n
            if stds[i] > 0 && stds[j] > 0
                corr = cov_mat[i, j] / (stds[i] * stds[j])
                print(@sprintf("%7.2f", corr))
            else
                print(@sprintf("%7s", "N/A"))
            end
        end
        println()
    end

else
    println("\n⚠️  UQ computation did not succeed: $(uq_result.message)")
end

# =============================================================================
# Part 6: Visualizations
# =============================================================================

println("\n🎨 Generating Visualizations...")
figures_dir = joinpath(@__DIR__, "figures_lv")
mkpath(figures_dir)

# --- Figure 1: GP Fit (Prey) ---
function plot_gp_fit(pep_sampled, uq_result; save_path)
    fig = Figure(size = (1000, 500))
    
    # Get keys dynamically
    obs_keys = collect(keys(pep_sampled.data_sample))
    # Filter out "t"
    obs_keys = filter(k -> string(k) != "t", obs_keys)
    
    # Sort keys to ensure y1 is first, y2 second (assuming naming convention or order)
    # Usually they are sorted by creation, but let's be safe.
    # Actually, let's just take the first two.
    
    if length(obs_keys) < 2
         @warn "Expected 2 observables, found $(length(obs_keys))"
         return fig
    end
    
    key1 = obs_keys[1] # Should be y1 ~ r
    key2 = obs_keys[2] # Should be y2 ~ w
    
    # Subplots
    ax1 = Axis(fig[1, 1], xlabel = "Time", ylabel = "Prey (r)", title = "Prey Dynamics")
    ax2 = Axis(fig[1, 2], xlabel = "Time", ylabel = "Predator (w)", title = "Predator Dynamics")
    
    ts = pep_sampled.data_sample["t"]
    
    # Helper to plot one observable
    function plot_obs!(ax, key, interp_idx)
        ys = pep_sampled.data_sample[key]
        
        # Get interpolator
        # uq_result.interpolators is an OrderedDict. 
        # We hope the order matches the keys. 
        # Let's find the interpolator that corresponds to this key.
        # The keys in uq_result.interpolators should match the observation keys.
        if !haskey(uq_result.interpolators, key)
            # Try string matching
            found = false
            for (k, v) in uq_result.interpolators
                if string(k) == string(key)
                    interp = v
                    found = true
                    break
                end
            end
             # Fallback if not found by key match (simpler lookup)
            if !found
                 interp = collect(values(uq_result.interpolators))[interp_idx]
            end
        else
            interp = uq_result.interpolators[key]
        end

        t_fine = range(minimum(ts), maximum(ts), length=200)
        μ = [interp.mean_function(t) for t in t_fine]
        σ = [interp.std_function(t) for t in t_fine]

        band!(ax, t_fine, μ .- 1.96 .* σ, μ .+ 1.96 .* σ, color = (COLORS.gp_band, 0.3), label="95% CI")
        lines!(ax, t_fine, μ, color = COLORS.gp_mean, linewidth = 2.5, label="GP Mean")
        scatter!(ax, ts, ys, color = COLORS.data, label="Data")
    end

    plot_obs!(ax1, key1, 1)
    plot_obs!(ax2, key2, 2)
    
    Legend(fig[1, 3], ax1)
    
    save(save_path, fig)
    return fig
end

# --- Figure 2: Parameter CIs ---
function plot_param_ci(uq_result, estimates, true_params; save_path)
    n_params = length(uq_result.param_names)
    fig = Figure(size = (700, 100 + n_params * 60))
    ax = Axis(fig[1, 1], title = "Parameter Estimates (Prey observed only)", 
              yticks = (1:n_params, string.(uq_result.param_names)))
    
    colors = [COLORS.param1, COLORS.param2, COLORS.param3, COLORS.param4, COLORS.param5]
    
    for (i, name) in enumerate(uq_result.param_names)
        est = get(estimates, name, NaN)
        std_val = uq_result.param_std[i]
        
        # Find true value
        true_val = nothing
        for (k, v) in true_params
            if string(k) == string(name) || occursin(string(name), string(k))
                true_val = v; break
            end
        end
        
        col = colors[mod1(i, length(colors))]
        rangebars!(ax, [i], [est - 1.96*std_val], [est + 1.96*std_val], 
                   direction=:x, color=col, linewidth=3)
        scatter!(ax, [est], [i], color=col, markersize=12)
        if !isnothing(true_val)
            scatter!(ax, [true_val], [i], color=COLORS.true_sol, marker=:star5, markersize=16)
        end
    end
    
    save(save_path, fig)
    return fig
end

if !isnothing(uq_result) && uq_result.success
    # Fig 1
    plot_gp_fit(pep_sampled, uq_result, save_path=joinpath(figures_dir, "01_lv_fit.pdf"))
    
    # Fig 2
    true_params_all = merge(pep.p_true, pep.ic)
    plot_param_ci(uq_result, estimates, true_params_all, save_path=joinpath(figures_dir, "02_lv_ci.pdf"))
    
    println("\nFigures saved to $figures_dir")
end

