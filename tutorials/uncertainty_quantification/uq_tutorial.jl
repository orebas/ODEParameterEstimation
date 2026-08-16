# =============================================================================
# Uncertainty Quantification Tutorial for ODEParameterEstimation.jl
# =============================================================================
#
# This tutorial demonstrates how to:
# 1. Run parameter estimation with uncertainty quantification (UQ) enabled
# 2. Interpret the UQ results (standard deviations, covariance, correlations)
# 3. Visualize uncertainty in observables, derivatives, and parameters
# 4. Understand how noise affects parameter uncertainty
#
# Author: ODEParameterEstimation.jl
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

# Set random seed for reproducibility
Random.seed!(42)

# =============================================================================
# Part 1: Color Scheme and Plot Styling
# =============================================================================
# Using a colorblind-friendly palette

const COLORS = (
    data = colorant"#0077BB",        # Blue - data points
    gp_mean = colorant"#009988",     # Teal - GP mean
    gp_band = colorant"#009988",     # Teal - GP uncertainty band
    true_sol = colorant"#CC3311",    # Red - true solution
    param1 = colorant"#EE7733",      # Orange - parameter 1
    param2 = colorant"#0077BB",      # Blue - parameter 2
    param3 = colorant"#009988",      # Teal - parameter 3
)

function setup_makie_theme!()
    set_theme!(Theme(
        fontsize = 14,
        Axis = (
            xlabelsize = 14,
            ylabelsize = 14,
            titlesize = 16,
            xgridvisible = true,
            ygridvisible = true,
            xgridstyle = :dash,
            ygridstyle = :dash,
            xgridwidth = 0.5,
            ygridwidth = 0.5,
        ),
        Legend = (
            framevisible = true,
            labelsize = 11,
        ),
    ))
end

setup_makie_theme!()

tutorial_base_name(value) = replace(string(value), r"\(.*\)" => "")

# =============================================================================
# Part 2: Define the Problem
# =============================================================================
# We'll use the built-in `simple()` model which is a simple ODE system

println("=" ^ 80)
println("UNCERTAINTY QUANTIFICATION TUTORIAL")
println("=" ^ 80)

println("\n📚 Loading the Simple Model...")
pep = simple()
println("   Model name: $(pep.name)")
println("   True parameters: ")
for (k, v) in pep.p_true
    println("      $k = $v")
end
println("   Initial conditions: ")
for (k, v) in pep.ic
    println("      $k = $v")
end

# Get time interval
time_interval = isnothing(pep.recommended_time_interval) ? [-0.5, 0.5] : pep.recommended_time_interval
println("   Time interval: $time_interval")

# =============================================================================
# Part 3: Generate Synthetic Data with Noise
# =============================================================================

println("\n📊 Generating Synthetic Data...")

# Noise level (relative noise)
noise_level = 0.05  # 5% noise

# Estimation options with UQ enabled
opts = EstimationOptions(
    datasize = 51,                    # Number of data points
    noise_level = noise_level,        # 5% relative noise
    time_interval = time_interval,
    flow = FlowDirectOpt,             # Use direct optimization (faster)
    interpolators = InterpolatorMethod[InterpolatorAGPUQ],
    compute_uncertainty = true,       # Enable uncertainty quantification!
    nooutput = true,                  # Suppress verbose output
)

# Sample the problem
pep_sampled = sample_problem_data(pep, opts)

println("   Data points: $(opts.datasize)")
println("   Noise level: $(noise_level * 100)%")
println("   Time span: $(time_interval)")

# =============================================================================
# Part 4: Run Parameter Estimation with UQ
# =============================================================================

println("\n🔬 Running Parameter Estimation with UQ...")
println("   (This may take a moment for first compilation...)")

@time result = analyze_parameter_estimation_problem(pep_sampled, opts)

# Unpack results
results_tuple, analysis_results, uq_result = result

println("\n✅ Parameter Estimation Complete!")

# =============================================================================
# Part 5: Interpret and Display UQ Results
# =============================================================================

println("\n" * "=" ^ 80)
println("RESULTS SUMMARY")
println("=" ^ 80)

if uq_result isa UncertaintyReport
    println("\n📈 Parameter Estimates with Uncertainty:")
    println("-" ^ 60)
    println(@sprintf("%-15s | %12s | %12s | %12s", "Parameter", "Estimate", "Std Dev", "95% CI Half"))
    println("-" ^ 60)

    # Build estimates dict from analysis_results (best solution)
    # analysis_results is a tuple: (Vector{ParameterEstimationResult}, Float64...)
    # So we need analysis_results[1][1] to get the first ParameterEstimationResult
    # NOTE: UQ param_labels contains BOTH states (initial conditions) AND parameters
    estimates = Dict{Symbol, Float64}()

    if length(analysis_results) >= 1 && isa(analysis_results[1], Vector) && length(analysis_results[1]) >= 1
        first_result = analysis_results[1][1]

        # Helper function to convert key to Symbol (handles Num and other types)
        function key_to_symbol(k)
            key_str = string(k)
            # Handle keys like "x1(t)" -> "x1"
            if occursin("(", key_str)
                key_str = split(key_str, "(")[1]
            end
            return Symbol(key_str)
        end

        # Extract STATES (initial conditions) - these are included in UQ param_labels
        if hasfield(typeof(first_result), :states)
            for (k, v) in first_result.states
                estimates[key_to_symbol(k)] = Float64(real(v))
            end
        end

        # Extract PARAMETERS
        if hasfield(typeof(first_result), :parameters)
            for (k, v) in first_result.parameters
                estimates[key_to_symbol(k)] = Float64(real(v))
            end
        end
    end

    # Iterate through the exact selected-estimator coordinates in the UQ report.
    for (i, name) in enumerate(uq_result.param_labels)
        std_val = uq_result.param_std[i]
        ci_half = 1.96 * std_val
        estimate_val = uq_result.estimate_values[i]

        println(@sprintf("%-15s | %12.6f | %12.6f | %12.6f",
                        string(name), estimate_val, std_val, ci_half))
    end
    println("-" ^ 60)
    println("Estimates from best solution; uncertainties from GP-based UQ analysis")

    # Correlation matrix
    println("\n📊 Parameter Correlation Matrix:")
    cov_mat = uq_result.param_covariance
    n = size(cov_mat, 1)
    stds = sqrt.(max.(diag(cov_mat), 0.0))

    # Print header
    print("              ")
    for name in uq_result.param_labels
        print(@sprintf("%12s", string(name)[1:min(12, length(string(name)))]))
    end
    println()

    # Print correlation matrix
    for i in 1:n
        print(@sprintf("%-12s ", string(uq_result.param_labels[i])[1:min(12, length(string(uq_result.param_labels[i])))]))
        for j in 1:n
            if stds[i] > 0 && stds[j] > 0
                corr = cov_mat[i, j] / (stds[i] * stds[j])
                print(@sprintf("%12.4f", corr))
            else
                print(@sprintf("%12s", "N/A"))
            end
        end
        println()
    end

    println("\n💡 Interpretation:")
    println("   - Standard deviations indicate parameter uncertainty")
    println("   - 95% CI: estimate ± 1.96 × std_dev")
    println("   - Correlations near ±1 suggest parameters are hard to identify independently")
else
    println("\n⚠️  UQ computation did not succeed")
    if uq_result isa UQUnavailable
        println("   Message: $(uq_result.message)")
    end
end

# =============================================================================
# Part 6: Visualizations
# =============================================================================

println("\n🎨 Generating Visualizations...")

# Create figures directory if it doesn't exist
figures_dir = joinpath(@__DIR__, "figures")
mkpath(figures_dir)

# -----------------------------------------------------------------------------
# Figure 1: GP Fit with Uncertainty Bands
# -----------------------------------------------------------------------------

function plot_gp_fit_with_bands(pep_sampled, uq_result; save_path=nothing)
    if !(uq_result isa UncertaintyReport)
        @warn "UQ result not available, skipping GP fit plot"
        return nothing
    end

    fig = Figure(size = (800, 500))
    ax = Axis(fig[1, 1],
        xlabel = "Time (t)",
        ylabel = "Observable Value",
        title = "GP Interpolation with Uncertainty Bands"
    )

    # Get time and data
    ts = pep_sampled.data_sample["t"]
    obs_keys = filter(k -> k != "t", collect(keys(pep_sampled.data_sample)))

    if isempty(obs_keys)
        @warn "No observables found in data_sample"
        return fig
    end

    obs_key = first(obs_keys)
    ys = pep_sampled.data_sample[obs_key]

    # Reports intentionally do not retain heavyweight interpolator objects.
    # Refit the same explicit AGPUQ recipe for this visualization only.
    interp = agp_gpr_uq(Float64.(ts), Float64.(ys))

    # Create fine grid for smooth curves
    t_fine = range(minimum(ts), maximum(ts), length=200)

    # Get GP predictions with uncertainty
    μ_vals = Float64[]
    σ_vals = Float64[]

    for t in t_fine
        push!(μ_vals, interp.mean_function(t))
        push!(σ_vals, interp.std_function(t))
    end

    # Plot uncertainty band (95% CI = ±1.96σ)
    band!(ax, t_fine, μ_vals .- 1.96 .* σ_vals, μ_vals .+ 1.96 .* σ_vals,
          color = (COLORS.gp_band, 0.3),
          label = "95% Credible Interval")

    # Plot GP mean
    lines!(ax, t_fine, μ_vals,
           color = COLORS.gp_mean, linewidth = 2.5,
           label = "GP Posterior Mean")

    # Plot noisy data points
    scatter!(ax, ts, ys,
             color = COLORS.data, markersize = 8,
             label = "Noisy Observations")

    # Add legend
    axislegend(ax, position = :rt)

    if !isnothing(save_path)
        save(save_path, fig, px_per_unit = 2)
        println("   Saved: $save_path")
    end

    return fig
end

# -----------------------------------------------------------------------------
# Figure 2: Derivative Uncertainty (requires access to derivative covariances)
# -----------------------------------------------------------------------------

function plot_derivative_uncertainty(pep_sampled, uq_result; save_path=nothing)
    if !(uq_result isa UncertaintyReport)
        @warn "UQ result not available, skipping derivative plot"
        return nothing
    end

    fig = Figure(size = (800, 700))

    # Get time and data
    ts = pep_sampled.data_sample["t"]
    obs_keys = filter(k -> k != "t", collect(keys(pep_sampled.data_sample)))

    if isempty(obs_keys)
        @warn "No observables found"
        return fig
    end

    obs_key = first(obs_keys)

    # Refit the configured AGPUQ recipe for a time-resolved diagnostic plot.
    interp = agp_gpr_uq(Float64.(ts), Float64.(pep_sampled.data_sample[obs_key]))

    # Create fine grid (avoid boundaries where uncertainty is higher)
    t_min, t_max = extrema(ts)
    margin = 0.05 * (t_max - t_min)
    t_fine = range(t_min + margin, t_max - margin, length=100)

    # Top panel: Observable value
    ax1 = Axis(fig[1, 1],
        ylabel = "y(t)",
        title = "Observable and Derivative Uncertainty",
        xticklabelsvisible = false
    )

    # Bottom panel: First derivative
    ax2 = Axis(fig[2, 1],
        xlabel = "Time (t)",
        ylabel = "dy/dt"
    )

    # Compute mean and covariance at each time point
    μ_y = Float64[]
    σ_y = Float64[]
    μ_dy = Float64[]
    σ_dy = Float64[]

    for t in t_fine
        # joint_derivative_covariance returns (μ, Σ) for [f, f', f'']
        μ, Σ = joint_derivative_covariance(interp, t, 1)
        push!(μ_y, μ[1])
        push!(σ_y, sqrt(max(Σ[1, 1], 0.0)))
        push!(μ_dy, μ[2])
        push!(σ_dy, sqrt(max(Σ[2, 2], 0.0)))
    end

    # Plot observable
    band!(ax1, t_fine, μ_y .- 1.96 .* σ_y, μ_y .+ 1.96 .* σ_y,
          color = (COLORS.gp_band, 0.3))
    lines!(ax1, t_fine, μ_y, color = COLORS.gp_mean, linewidth = 2)

    # Plot derivative
    band!(ax2, t_fine, μ_dy .- 1.96 .* σ_dy, μ_dy .+ 1.96 .* σ_dy,
          color = (COLORS.param1, 0.3))
    lines!(ax2, t_fine, μ_dy, color = COLORS.param1, linewidth = 2)

    # Add annotation about derivative uncertainty being larger
    avg_y_cv = mean(σ_y) / mean(abs.(μ_y))
    avg_dy_cv = mean(σ_dy) / mean(abs.(μ_dy) .+ 1e-10)

    Label(fig[3, 1],
          "Note: Derivative uncertainty (CV=$(round(avg_dy_cv*100, digits=1))%) is typically larger than value uncertainty (CV=$(round(avg_y_cv*100, digits=1))%)",
          fontsize = 11, color = :gray60)

    rowgap!(fig.layout, 1, 5)

    if !isnothing(save_path)
        save(save_path, fig, px_per_unit = 2)
        println("   Saved: $save_path")
    end

    return fig
end

# -----------------------------------------------------------------------------
# Figure 3: Parameter Confidence Intervals (Forest Plot)
# -----------------------------------------------------------------------------

function plot_parameter_ci(uq_result, true_params, estimates; save_path=nothing)
    if !(uq_result isa UncertaintyReport)
        @warn "UQ result not available, skipping parameter CI plot"
        return nothing
    end

    n_params = length(uq_result.param_labels)

    fig = Figure(size = (700, 100 + n_params * 60))
    ax = Axis(fig[1, 1],
        xlabel = "Parameter Value",
        ylabel = "",
        title = "Parameter Estimates with 95% Confidence Intervals",
        yticks = (1:n_params, string.(uq_result.param_labels))
    )

    # Colors for different parameter types
    colors = [COLORS.param1, COLORS.param2, COLORS.param3]

    for (i, name) in enumerate(uq_result.param_labels)
        std_val = uq_result.param_std[i]
        ci_half = 1.96 * std_val

        # Get true value if available
        true_val = nothing
        for (k, v) in true_params
            if tutorial_base_name(k) == tutorial_base_name(name)
                true_val = v
                break
            end
        end

        # Get actual estimate from passed-in estimates dictionary
        estimate = get(estimates, name, NaN)

        # Skip if we don't have an estimate
        if isnan(estimate)
            @warn "No estimate found for parameter $name"
            continue
        end

        # Plot error bar (CI)
        col = colors[mod1(i, length(colors))]

        # Error bar
        rangebars!(ax, [i], [estimate - ci_half], [estimate + ci_half],
                   direction = :x, color = col, linewidth = 3)

        # Point estimate
        scatter!(ax, [estimate], [i], color = col, markersize = 12)

        # True value (if known)
        if !isnothing(true_val)
            scatter!(ax, [true_val], [i], color = COLORS.true_sol,
                    marker = :star5, markersize = 16)
        end
    end

    # Add legend manually
    elem1 = [PolyElement(color = COLORS.param1)]
    elem2 = [MarkerElement(color = COLORS.true_sol, marker = :star5, markersize = 15)]
    Legend(fig[1, 2], [elem1, elem2], ["Estimate ± 95% CI", "True Value"])

    if !isnothing(save_path)
        save(save_path, fig, px_per_unit = 2)
        println("   Saved: $save_path")
    end

    return fig
end

# -----------------------------------------------------------------------------
# Figure 4: Covariance Ellipse (2D Parameter Space)
# -----------------------------------------------------------------------------

function plot_covariance_ellipse(uq_result, true_params, estimates; save_path=nothing, param_indices=(1, 2))
    if !(uq_result isa UncertaintyReport)
        @warn "UQ result not available, skipping covariance ellipse plot"
        return nothing
    end

    n_params = length(uq_result.param_labels)
    if n_params < 2
        @warn "Need at least 2 parameters for covariance ellipse"
        return nothing
    end

    i, j = param_indices

    fig = Figure(size = (600, 550))

    param_name_i = uq_result.param_labels[i]
    param_name_j = uq_result.param_labels[j]

    ax = Axis(fig[1, 1],
        xlabel = string(param_name_i),
        ylabel = string(param_name_j),
        title = "Joint Parameter Uncertainty (95% Confidence Ellipse)"
    )

    # Extract 2x2 submatrix of covariance
    cov_sub = uq_result.param_covariance[[i, j], [i, j]]

    # Get true values
    true_i = nothing
    true_j = nothing
    for (k, v) in true_params
        if tutorial_base_name(k) == tutorial_base_name(param_name_i)
            true_i = v
        end
        if tutorial_base_name(k) == tutorial_base_name(param_name_j)
            true_j = v
        end
    end

    # Get actual estimates from passed-in estimates dictionary
    est_i = get(estimates, param_name_i, isnothing(true_i) ? 0.0 : true_i)
    est_j = get(estimates, param_name_j, isnothing(true_j) ? 0.0 : true_j)

    # Generate ellipse points
    # For 95% CI, use χ² with 2 df at 0.95 quantile ≈ 5.991
    chi2_val = 5.991

    # Eigendecomposition of covariance
    eigenvalues, eigenvectors = eigen(Symmetric(cov_sub))

    # Ellipse radii (scaled by sqrt(chi2_val))
    radii = sqrt.(max.(eigenvalues, 0.0) .* chi2_val)

    # Generate ellipse
    θ = range(0, 2π, length=100)
    ellipse_unit = hcat(cos.(θ), sin.(θ))

    # Transform ellipse
    scale_mat = Diagonal(radii)
    ellipse_transformed = (eigenvectors * scale_mat * ellipse_unit')'

    # Translate to estimate
    ellipse_x = ellipse_transformed[:, 1] .+ est_i
    ellipse_y = ellipse_transformed[:, 2] .+ est_j

    # Plot ellipse
    poly!(ax, Point2f.(ellipse_x, ellipse_y),
          color = (COLORS.gp_band, 0.3),
          strokecolor = COLORS.gp_mean,
          strokewidth = 2)

    # Plot estimate
    scatter!(ax, [est_i], [est_j],
             color = COLORS.gp_mean, markersize = 12,
             label = "Estimate")

    # Plot true value
    if !isnothing(true_i) && !isnothing(true_j)
        scatter!(ax, [true_i], [true_j],
                 color = COLORS.true_sol, marker = :star5, markersize = 16,
                 label = "True Value")
    end

    axislegend(ax, position = :rt)

    # Add correlation annotation
    corr = cov_sub[1, 2] / sqrt(cov_sub[1, 1] * cov_sub[2, 2])
    Label(fig[2, 1], "Correlation: $(round(corr, digits=3))",
          fontsize = 12, color = :gray60)

    if !isnothing(save_path)
        save(save_path, fig, px_per_unit = 2)
        println("   Saved: $save_path")
    end

    return fig
end

# -----------------------------------------------------------------------------
# Figure 5: Noise Sensitivity Study
# -----------------------------------------------------------------------------

function plot_noise_sensitivity(pep; save_path=nothing)
    println("   Running noise sensitivity study...")

    noise_levels = [0.001, 0.005, 0.01, 0.02, 0.05, 0.1]

    # Store results
    param_stds_by_noise = Dict{Float64, Vector{Float64}}()
    param_names = String[]

    for nl in noise_levels
        print("      Testing noise level $(nl*100)%... ")

        opts_temp = EstimationOptions(
            datasize = 51,
            noise_level = nl,
            time_interval = time_interval,
            flow = FlowDirectOpt,
            interpolators = InterpolatorMethod[InterpolatorAGPUQ],
            compute_uncertainty = true,
            nooutput = true,
        )

        pep_temp = sample_problem_data(pep, opts_temp)

        try
            _, _, uq_temp = analyze_parameter_estimation_problem(pep_temp, opts_temp)

            if uq_temp isa UncertaintyReport
                param_stds_by_noise[nl] = copy(uq_temp.param_std)
                if isempty(param_names)
                    param_names = copy(uq_temp.param_labels)
                end
                println("✓")
            else
                println("UQ failed")
            end
        catch e
            println("Error: $e")
        end
    end

    if isempty(param_stds_by_noise)
        @warn "No successful UQ runs for noise sensitivity"
        return nothing
    end

    # Create plot
    fig = Figure(size = (700, 500))
    ax = Axis(fig[1, 1],
        xlabel = "Noise Level (%)",
        ylabel = "Parameter Std. Dev.",
        title = "Parameter Uncertainty vs. Measurement Noise",
        xscale = log10,
        yscale = log10
    )

    colors = [COLORS.param1, COLORS.param2, COLORS.param3]

    sorted_noise = sort(collect(keys(param_stds_by_noise)))

    for (pi, pname) in enumerate(param_names)
        noise_vals = Float64[]
        std_vals = Float64[]

        for nl in sorted_noise
            if haskey(param_stds_by_noise, nl) && length(param_stds_by_noise[nl]) >= pi
                push!(noise_vals, nl * 100)  # Convert to percentage
                push!(std_vals, param_stds_by_noise[nl][pi])
            end
        end

        if !isempty(noise_vals)
            col = colors[mod1(pi, length(colors))]
            scatterlines!(ax, noise_vals, std_vals,
                         color = col, markersize = 10, linewidth = 2,
                         label = string(pname))
        end
    end

    axislegend(ax, position = :lt)

    # Add expected scaling note
    Label(fig[2, 1],
          "Note: For linear systems, σ_θ ∝ noise level (slope ≈ 1 on log-log scale)",
          fontsize = 11, color = :gray60)

    if !isnothing(save_path)
        save(save_path, fig, px_per_unit = 2)
        println("   Saved: $save_path")
    end

    return fig
end

# =============================================================================
# Part 7: Generate All Figures
# =============================================================================

# Figure 1: GP Fit with Bands
fig1 = plot_gp_fit_with_bands(pep_sampled, uq_result,
    save_path = joinpath(figures_dir, "01_gp_fit_with_bands.pdf"))

# Figure 2: Derivative Uncertainty
fig2 = plot_derivative_uncertainty(pep_sampled, uq_result,
    save_path = joinpath(figures_dir, "02_derivative_uncertainty.pdf"))

# Figure 3: Parameter CIs
true_params = merge(pep.p_true, pep.ic)

# Build estimates dict from analysis_results (best solution) for plotting
# analysis_results[1] is a Vector of results, so we need analysis_results[1][1]
# The report center is guaranteed to match the returned rank-one estimator.
estimates = uq_result isa UncertaintyReport ?
    Dict(uq_result.param_labels .=> uq_result.estimate_values) : Dict{String, Float64}()

fig3 = plot_parameter_ci(uq_result, true_params, estimates,
    save_path = joinpath(figures_dir, "03_parameter_confidence.pdf"))

# Figure 4: Covariance Ellipse (if we have at least 2 params)
if uq_result isa UncertaintyReport && length(uq_result.param_labels) >= 2
    fig4 = plot_covariance_ellipse(uq_result, true_params, estimates,
        save_path = joinpath(figures_dir, "04_covariance_ellipse.pdf"))
end

# Figure 5: Noise Sensitivity (takes time, comment out for quick runs)
fig5 = plot_noise_sensitivity(pep,
    save_path = joinpath(figures_dir, "05_noise_sensitivity.pdf"))

# =============================================================================
# Part 8: Summary
# =============================================================================

println("\n" * "=" ^ 80)
println("TUTORIAL COMPLETE")
println("=" ^ 80)
println("\n📁 Generated figures saved to: $figures_dir")
println("\n📖 Key takeaways:")
println("   1. UQ propagates GP uncertainty through to parameter estimates")
println("   2. Derivative uncertainty is typically larger than value uncertainty")
println("   3. Parameter correlations reveal identifiability structure")
println("   4. Higher noise → larger parameter uncertainty (as expected)")
println("\n🔗 For more details, see the README.md in this directory")
println("=" ^ 80)
