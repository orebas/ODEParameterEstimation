#!/usr/bin/env julia
#=
Pole Deflation Prototype for AAA Boundary Derivatives
=====================================================
Tests whether subtracting spurious pole contributions from AAA rational interpolants
can fix catastrophic derivative errors at boundary points of stiff ODE systems.

ERK model: 6 states, 6 params, 3 observables (S0, S1, S2)
Known issue: AAA places near-real poles ~1e-7 from t=0, causing 13,500× derivative errors.
=#

using ODEParameterEstimation, ModelingToolkit, DifferentialEquations
using OrderedCollections, LinearAlgebra, Printf

const BaryRational = ODEParameterEstimation.BaryRational
const TaylorDiff = ODEParameterEstimation.TaylorDiff

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: ERK model setup and data generation
# ─────────────────────────────────────────────────────────────────────────────

println("="^80)
println("  POLE DEFLATION PROTOTYPE — ERK Model")
println("="^80)
println()

@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t)
D = Differential(t)

states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1 * E * S0 + kr1 * C1,
    D(C1) ~ kf1 * E * S0 - (kr1 + kc1) * C1,
    D(C2) ~ kc1 * C1 - (kr2 + kc2) * C2 + kf2 * E * S1,
    D(S1) ~ -kf2 * E * S1 + kr2 * C2,
    D(S2) ~ kc2 * C2,
    D(E) ~ -kf1 * E * S0 + kr1 * C1 - kf2 * E * S1 + (kr2 + kc2) * C2,
]

ic = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]
time_interval = (0.0, 20.0)
N_data = 2001

# Solve ODE with high accuracy for ground truth
@named erk_sys = ODESystem(eqs, t, states, parameters)
erk_simplified = structural_simplify(erk_sys)

prob = ODEProblem(erk_simplified,
    Dict(states .=> ic),
    time_interval,
    Dict(parameters .=> p_true))
sol = solve(prob, AutoVern9(Rodas4P()), abstol = 1e-14, reltol = 1e-14,
    saveat = range(0.0, 20.0, length = N_data))

t_data = collect(Float64, sol.t)
obs_names = ["S0", "S1", "S2"]
obs_states = [S0, S1, S2]
obs_data = [collect(Float64, sol[s]) for s in obs_states]

println("Data generated: $(N_data) points on [0, 20]")
println("Grid spacing h = $(t_data[2] - t_data[1])")
println()

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Ground truth derivatives
# ─────────────────────────────────────────────────────────────────────────────

# Analytical derivatives at t=0 from ODE RHS + known ICs
# S0'(0) = -kf1*E(0)*S0(0) + kr1*C1(0) = -11.5*0.65*5.0 + 300.0*0.0 = -37.375
# S1'(0) = -kf2*E(0)*S1(0) + kr2*C2(0) = -11.15*0.65*0.0 + 4.864*0.0 = 0.0
# S2'(0) = kc2*C2(0) = 428.13*0.0 = 0.0

ground_truth_d0 = Dict("S0" => 5.0, "S1" => 0.0, "S2" => 0.0)
ground_truth_d1_t0 = Dict("S0" => -37.375, "S1" => 0.0, "S2" => 0.0)

# Use dense ODE output for values and derivatives at t=10 and t=20
# Use symbolic indexing (idxs=var) to avoid state ordering issues after structural_simplify
ground_truth_d0_t10 = Dict{String, Float64}()
ground_truth_d0_t20 = Dict{String, Float64}()
ground_truth_d1_t10 = Dict{String, Float64}()
ground_truth_d1_t20 = Dict{String, Float64}()

for (i, (name, state)) in enumerate(zip(obs_names, obs_states))
    # Values via symbolic indexing
    ground_truth_d0_t10[name] = sol(10.0; idxs = state)
    ground_truth_d0_t20[name] = sol(20.0; idxs = state)
    # Derivatives via Val{1} with symbolic indexing
    ground_truth_d1_t10[name] = sol(10.0, Val{1}; idxs = state)
    ground_truth_d1_t20[name] = sol(20.0, Val{1}; idxs = state)
end

println("Ground truth derivatives at t=0:")
for name in obs_names
    @printf("  %s'(0) = %.6f\n", name, ground_truth_d1_t0[name])
end
println()

println("Ground truth derivatives at t=10:")
for name in obs_names
    @printf("  %s'(10) = %.6f\n", name, ground_truth_d1_t10[name])
end
println()

println("Ground truth derivatives at t=20:")
for name in obs_names
    @printf("  %s'(20) = %.6f\n", name, ground_truth_d1_t20[name])
end
println()

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Build interpolants
# ─────────────────────────────────────────────────────────────────────────────

println("Building interpolants...")

aaa_interps = Dict{String, ODEParameterEstimation.AAADapprox}()
fhd_interps = Dict{String, ODEParameterEstimation.FHDapprox}()

for (i, name) in enumerate(obs_names)
    aaa_interps[name] = ODEParameterEstimation.aaad(t_data, obs_data[i])
    # Build FHD directly — the package fhd() wrapper passes unsupported `verbose` kwarg
    fhd_internal = BaryRational.FHInterp(t_data, obs_data[i]; order = 5)
    fhd_interps[name] = ODEParameterEstimation.FHDapprox(fhd_internal)
end

println("  AAA and FHD5 interpolants built for S0, S1, S2")
println()

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Pole extraction and classification
# ─────────────────────────────────────────────────────────────────────────────

println("="^80)
println("  POLE ANALYSIS")
println("="^80)
println()

# Store pole info for each observable
pole_info = Dict{String, NamedTuple}()

for name in obs_names
    interp = aaa_interps[name]
    poles, residues, zeros = BaryRational.prz(interp.internalAAA)

    # Classify poles
    near_real = abs.(imag.(poles)) .< 1e-6
    dist_from_0 = abs.(real.(poles))
    dist_from_20 = abs.(real.(poles) .- 20.0)

    # Sort by distance from t=0
    sort_idx = sortperm(dist_from_0)

    println("--- $name: $(length(poles)) poles total, $(sum(near_real)) near-real ---")
    println(@sprintf("  %-4s  %-22s  %-22s  %-14s  %-10s  %-10s",
        "#", "Real(pole)", "Imag(pole)", "|Residue|", "Dist(0)", "Near-real?"))

    n_show = min(15, length(poles))
    for j in 1:n_show
        idx = sort_idx[j]
        p = poles[idx]
        r = residues[idx]
        nr = near_real[idx] ? "YES" : "no"
        @printf("  %-4d  %+22.14e  %+22.14e  %14.6e  %10.6e  %-10s\n",
            idx, real(p), imag(p), abs(r), dist_from_0[idx], nr)
    end
    if length(poles) > n_show
        println("  ... ($(length(poles) - n_show) more poles not shown)")
    end
    println()

    pole_info[name] = (poles = poles, residues = residues, zeros = zeros, near_real = near_real)
end

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Deflation strategies
# ─────────────────────────────────────────────────────────────────────────────

"""
    classify_dangerous_poles(poles, residues, eval_t; danger_radius=1.0, imag_tol=1e-6)

Classify poles as dangerous for derivative evaluation at a given point.
Returns indices of dangerous near-real poles, sorted by distance from eval_t.
"""
function classify_dangerous_poles(poles, residues, eval_t; danger_radius = 1.0, imag_tol = 1e-6)
    dangerous = Int[]
    for i in eachindex(poles)
        p = poles[i]
        if abs(imag(p)) < imag_tol && abs(real(p) - eval_t) < danger_radius
            push!(dangerous, i)
        end
    end
    # Sort by distance from eval_t
    sort!(dangerous, by = i -> abs(real(poles[i]) - eval_t))
    return dangerous
end

"""
    deflate_nearest(interp, poles, residues, eval_t; danger_radius=1.0)

Strategy (a): Subtract the single nearest dangerous pole contribution.
Returns deflated function value and the correction applied.
"""
function deflate_nearest_deriv(interp, poles, residues, eval_t; danger_radius = 1.0)
    dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = danger_radius)
    if isempty(dangerous)
        raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(1))
        return raw, 0.0, 0
    end

    # Take only the nearest
    idx = dangerous[1]
    p_near = real(poles[idx])
    R_near = real(residues[idx])

    # Deflated function: subtract the pole contribution
    deflated(z) = interp(z) - R_near / (z - p_near)
    deriv = TaylorDiff.derivative(deflated, eval_t, Val(1))

    return deriv, R_near, 1
end

"""
    deflate_all_spurious_deriv(interp, poles, residues, eval_t; threshold, danger_radius=1.0)

Strategy (b): Subtract all near-real poles with |residue| < threshold within danger_radius.
Re-differentiates the deflated function with TaylorDiff.
"""
function deflate_all_spurious_deriv(interp, poles, residues, eval_t;
    threshold = 1e-4, danger_radius = 1.0)
    dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = danger_radius)
    if isempty(dangerous)
        raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(1))
        return raw, 0, Int[]
    end

    # Filter by residue threshold
    spurious_idx = [i for i in dangerous if abs(residues[i]) < threshold]
    if isempty(spurious_idx)
        raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(1))
        return raw, 0, Int[]
    end

    # Build list of near-real poles to subtract (use real parts)
    poles_to_subtract = [(real(poles[i]), real(residues[i])) for i in spurious_idx]

    function deflated(z)
        val = interp(z)
        for (p, R) in poles_to_subtract
            val -= R / (z - p)
        end
        return val
    end

    deriv = TaylorDiff.derivative(deflated, eval_t, Val(1))
    return deriv, length(spurious_idx), spurious_idx
end

"""
    deflate_all_dangerous_deriv(interp, poles, residues, eval_t; danger_radius=1.0)

Strategy (b-all): Subtract ALL near-real dangerous poles (regardless of residue magnitude).
"""
function deflate_all_dangerous_deriv(interp, poles, residues, eval_t; danger_radius = 1.0)
    dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = danger_radius)
    if isempty(dangerous)
        raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(1))
        return raw, 0, Int[]
    end

    poles_to_subtract = [(real(poles[i]), real(residues[i])) for i in dangerous]

    function deflated(z)
        val = interp(z)
        for (p, R) in poles_to_subtract
            val -= R / (z - p)
        end
        return val
    end

    deriv = TaylorDiff.derivative(deflated, eval_t, Val(1))
    return deriv, length(dangerous), dangerous
end

"""
    analytical_correction_deriv(interp, poles, residues, eval_t; danger_radius=1.0, n=1)

Strategy (c): Don't re-differentiate. Compute raw derivative with TaylorDiff,
then subtract the analytically-known pole derivative contribution.

For a pole at p with residue R, the n-th derivative contribution is:
  (-1)^n * n! * R / (t - p)^(n+1)
"""
function analytical_correction_deriv(interp, poles, residues, eval_t;
    danger_radius = 1.0, n = 1)
    raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(n))

    dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = danger_radius)
    if isempty(dangerous)
        return raw, 0.0, 0
    end

    correction = 0.0
    for idx in dangerous
        p = real(poles[idx])
        R = real(residues[idx])
        # n-th derivative of R/(z-p) is (-1)^n * n! * R / (z-p)^(n+1)
        correction += (-1)^n * factorial(n) * R / (eval_t - p)^(n + 1)
    end

    corrected = raw - correction
    return corrected, correction, length(dangerous)
end

"""
    analytical_correction_nearest_deriv(interp, poles, residues, eval_t; danger_radius=1.0, n=1)

Strategy (c-nearest): Analytical correction for just the single nearest dangerous pole.
"""
function analytical_correction_nearest_deriv(interp, poles, residues, eval_t;
    danger_radius = 1.0, n = 1)
    raw = TaylorDiff.derivative(z -> interp(z), eval_t, Val(n))

    dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = danger_radius)
    if isempty(dangerous)
        return raw, 0.0, 0
    end

    idx = dangerous[1]
    p = real(poles[idx])
    R = real(residues[idx])
    correction = (-1)^n * factorial(n) * R / (eval_t - p)^(n + 1)

    corrected = raw - correction
    return corrected, correction, 1
end

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Fornberg finite difference weights
# ─────────────────────────────────────────────────────────────────────────────

"""
    fornberg_weights(z, x, m)

Compute finite difference weights for derivatives at point z using nodes x.
Algorithm from Fornberg (1988), "Generation of Finite Difference Formulas on
Arbitrarily Spaced Grids."

Returns matrix C where C[k+1, j] is the weight for node j for the k-th derivative.
"""
function fornberg_weights(z::Real, x::AbstractVector, m::Int)
    n = length(x) - 1  # Number of points minus 1
    C = zeros(m + 1, n + 1)
    c1 = 1.0
    c4 = x[1] - z
    C[1, 1] = 1.0

    for i in 1:n
        mn = min(i, m)
        c2 = 1.0
        c5 = c4
        c4 = x[i+1] - z
        for j in 0:i-1
            c3 = x[i+1] - x[j+1]
            c2 = c2 * c3
            if j == i - 1
                for k in mn:-1:1
                    C[k+1, i+1] = c1 * (k * C[k, i] - c5 * C[k+1, i]) / c2
                end
                C[1, i+1] = -c1 * c5 * C[1, i] / c2
            end
            for k in mn:-1:1
                C[k+1, j+1] = (c4 * C[k+1, j+1] - k * C[k, j+1]) / c3
            end
            C[1, j+1] = c4 * C[1, j+1] / c3
        end
        c1 = c2
    end
    return C
end

"""
    fornberg_deriv(t_data, obs_data, eval_t, deriv_order, n_points; side=:auto)

Compute derivative using Fornberg FD weights.
Uses one-sided stencil at boundaries, centered at interior.
"""
function fornberg_deriv(t_data, obs_data, eval_t, deriv_order, n_points; side = :auto)
    N = length(t_data)

    if side == :auto
        # Determine which side based on proximity to boundaries
        if eval_t <= t_data[1] + (t_data[end] - t_data[1]) * 0.1
            side = :right  # near left boundary, use right-sided stencil
        elseif eval_t >= t_data[end] - (t_data[end] - t_data[1]) * 0.1
            side = :left   # near right boundary, use left-sided stencil
        else
            side = :centered
        end
    end

    if side == :right
        # Use first n_points
        idx = 1:min(n_points, N)
    elseif side == :left
        # Use last n_points
        idx = max(1, N - n_points + 1):N
    else
        # Centered: find closest point and expand
        center = argmin(abs.(t_data .- eval_t))
        half = n_points ÷ 2
        start = max(1, center - half)
        stop = min(N, start + n_points - 1)
        start = max(1, stop - n_points + 1)
        idx = start:stop
    end

    x_stencil = t_data[idx]
    y_stencil = obs_data[idx]

    weights = fornberg_weights(eval_t, x_stencil, deriv_order)
    # The derivative weights are in row (deriv_order + 1)
    return dot(weights[deriv_order+1, :], y_stencil)
end

# ─────────────────────────────────────────────────────────────────────────────
# Step 7: Comprehensive benchmarking
# ─────────────────────────────────────────────────────────────────────────────

"""
    compute_error_str(value, truth)

Format the relative error or absolute error neatly.
"""
function compute_error_str(value, truth)
    if abs(truth) < 1e-12
        # Use absolute error for near-zero truth
        err = abs(value - truth)
        if err < 1e-10
            return @sprintf("%12.2e (abs)", err)
        else
            return @sprintf("%12.4f (abs)", err)
        end
    else
        rel = abs(value - truth) / abs(truth)
        if rel > 10.0
            return @sprintf("%10.0f×", rel)
        elseif rel > 1.0
            return @sprintf("%12.1f×", rel)
        else
            return @sprintf("%11.2f%%", rel * 100)
        end
    end
end

function run_benchmark(eval_t::Float64, label::String)
    println()
    println("="^80)
    @printf("  BENCHMARK at t = %.1f  (%s)\n", eval_t, label)
    println("="^80)

    for (obs_idx, name) in enumerate(obs_names)
        println()
        println("--- $name at t=$eval_t ---")

        # Ground truth (using precomputed symbolic-indexed values)
        if eval_t == 0.0
            gt_d0 = ground_truth_d0[name]
            gt_d1 = ground_truth_d1_t0[name]
        elseif eval_t == 10.0
            gt_d0 = ground_truth_d0_t10[name]
            gt_d1 = ground_truth_d1_t10[name]
        else
            gt_d0 = ground_truth_d0_t20[name]
            gt_d1 = ground_truth_d1_t20[name]
        end

        interp = aaa_interps[name]
        fhd_interp = fhd_interps[name]
        poles = pole_info[name].poles
        residues = pole_info[name].residues

        # Collect results: (method_name, d0_value, d1_value)
        results = Tuple{String, Float64, Float64}[]

        # Helper: build a deflated function for a given set of pole indices
        function make_deflated_func(interp_fn, poles_vec, residues_vec, idx_list)
            poles_to_sub = [(real(poles_vec[i]), real(residues_vec[i])) for i in idx_list]
            function deflated(z)
                val = interp_fn(z)
                for (p, R) in poles_to_sub
                    val -= R / (z - p)
                end
                return val
            end
            return deflated
        end

        # Collect results: (method_name, d0, d1, d2)
        results = Tuple{String, Float64, Float64, Float64}[]

        # Ground truth d2 (only at t=0 where we can compute analytically)
        # For other points, use ODE solver's Val{2} or just report NaN
        gt_d2 = NaN  # placeholder; computed below for t=0 only

        # Ground truth
        push!(results, ("GROUND TRUTH", gt_d0, gt_d1, gt_d2))

        # Raw AAAD
        raw_d0 = interp(eval_t)
        raw_d1 = TaylorDiff.derivative(z -> interp(z), eval_t, Val(1))
        raw_d2 = TaylorDiff.derivative(z -> interp(z), eval_t, Val(2))
        push!(results, ("AAAD raw", raw_d0, raw_d1, raw_d2))

        # FHD5
        fhd_d0 = fhd_interp(eval_t)
        fhd_d1 = TaylorDiff.derivative(z -> fhd_interp(z), eval_t, Val(1))
        fhd_d2 = TaylorDiff.derivative(z -> fhd_interp(z), eval_t, Val(2))
        push!(results, ("FHD5 (TaylorDiff)", fhd_d0, fhd_d1, fhd_d2))

        # Strategy (a): Deflate nearest — compute deflated d0, d1, d2
        for radius in [0.1, 1.0, 5.0]
            dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = radius)
            if isempty(dangerous)
                push!(results, ("Deflate nearest (r=$radius, n=0)", raw_d0, raw_d1, raw_d2))
            else
                idx_list = [dangerous[1]]
                dfunc = make_deflated_func(z -> interp(z), poles, residues, idx_list)
                d0 = dfunc(eval_t)
                d1 = TaylorDiff.derivative(dfunc, eval_t, Val(1))
                d2 = TaylorDiff.derivative(dfunc, eval_t, Val(2))
                push!(results, ("Deflate nearest (r=$radius, n=1)", d0, d1, d2))
            end
        end

        # Strategy (b-all): Deflate ALL dangerous (the most useful variant)
        for radius in [1.0, 5.0]
            dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = radius)
            if isempty(dangerous)
                push!(results, (@sprintf("All dangerous r=%.1f (n=0)", radius), raw_d0, raw_d1, raw_d2))
            else
                dfunc = make_deflated_func(z -> interp(z), poles, residues, dangerous)
                d0 = dfunc(eval_t)
                d1 = TaylorDiff.derivative(dfunc, eval_t, Val(1))
                d2 = TaylorDiff.derivative(dfunc, eval_t, Val(2))
                push!(results, (@sprintf("All dangerous r=%.1f (n=%d)", radius, length(dangerous)),
                    d0, d1, d2))
            end
        end

        # Strategy (c): Analytical correction — d0 is raw, d1/d2 corrected analytically
        for radius in [1.0, 5.0]
            dangerous = classify_dangerous_poles(poles, residues, eval_t; danger_radius = radius)
            # d0: compute value correction too
            val_corr = sum(real(residues[i]) / (eval_t - real(poles[i])) for i in dangerous; init = 0.0)
            d0_corr = raw_d0 - val_corr
            # d1
            d1_pole = sum((-1) * 1 * real(residues[i]) / (eval_t - real(poles[i]))^2 for i in dangerous; init = 0.0)
            d1_corr = raw_d1 - d1_pole
            # d2
            d2_pole = sum((-1)^2 * 2 * real(residues[i]) / (eval_t - real(poles[i]))^3 for i in dangerous; init = 0.0)
            d2_corr = raw_d2 - d2_pole
            push!(results, (@sprintf("Analytic corr r=%.1f (n=%d)", radius, length(dangerous)),
                d0_corr, d1_corr, d2_corr))
        end

        # Fornberg FD
        for n_pts in [30, 50]
            fd_d0 = fornberg_deriv(t_data, obs_data[obs_idx], eval_t, 0, n_pts)
            fd_d1 = fornberg_deriv(t_data, obs_data[obs_idx], eval_t, 1, n_pts)
            fd_d2 = fornberg_deriv(t_data, obs_data[obs_idx], eval_t, 2, n_pts)
            push!(results, ("Fornberg $(n_pts)pt", fd_d0, fd_d1, fd_d2))
        end

        # Print table with d0, d1, d2
        println()
        @printf("  %-38s  %14s  %14s  %14s  %18s  %18s\n",
            "Method", "d0 (value)", "d1 (deriv)", "d2 (2nd)", "d0 error", "d1 error")
        println("  " * "-"^38 * "  " * "-"^14 * "  " * "-"^14 * "  " * "-"^14 * "  " * "-"^18 * "  " * "-"^18)

        for (method, d0, d1, d2) in results
            if method == "GROUND TRUTH"
                @printf("  %-38s  %14.6f  %14.6f  %14.4f  %18s  %18s\n", method, d0, d1, d2, "—", "—")
            else
                d0_err = compute_error_str(d0, gt_d0)
                d1_err = compute_error_str(d1, gt_d1)
                @printf("  %-38s  %14.6f  %14.6f  %14.4f  %s  %s\n", method, d0, d1, d2, d0_err, d1_err)
            end
        end
    end
end

# ─────────────────────────────────────────────────────────────────────────────
# Run benchmarks at key points
# ─────────────────────────────────────────────────────────────────────────────

run_benchmark(0.0, "LEFT BOUNDARY — stiff transient, catastrophic poles")
run_benchmark(10.0, "INTERIOR — should be well-behaved")
run_benchmark(20.0, "RIGHT BOUNDARY — should be fine")

# ─────────────────────────────────────────────────────────────────────────────
# Additional analysis: pole contribution decomposition at t=0
# ─────────────────────────────────────────────────────────────────────────────

println()
println("="^80)
println("  DETAILED POLE CONTRIBUTION DECOMPOSITION AT t=0")
println("="^80)

for name in obs_names
    poles = pole_info[name].poles
    residues = pole_info[name].residues

    # Find all near-real poles
    near_real_idx = findall(i -> abs(imag(poles[i])) < 1e-6, eachindex(poles))

    if isempty(near_real_idx)
        println("\n$name: No near-real poles")
        continue
    end

    # Sort by distance from t=0
    sort!(near_real_idx, by = i -> abs(real(poles[i])))

    println("\n--- $name: Near-real pole contributions to d/dt at t=0 ---")
    @printf("  %-4s  %22s  %14s  %14s  %18s\n",
        "#", "Real(pole)", "|Residue|", "Dist(0)", "d1 contribution")
    println("  " * "-"^76)

    total_contribution = 0.0
    for (rank, idx) in enumerate(near_real_idx)
        p = real(poles[idx])
        R = real(residues[idx])
        # First derivative contribution of R/(z-p) at z=0 is -R/p^2
        contrib = -R / (0.0 - p)^2
        total_contribution += contrib

        @printf("  %-4d  %+22.14e  %14.6e  %14.6e  %+18.6e\n",
            rank, p, abs(R), abs(p), contrib)

        if rank >= 20
            println("  ... ($(length(near_real_idx) - 20) more)")
            # Sum remaining contributions
            for j in 21:length(near_real_idx)
                idx2 = near_real_idx[j]
                p2 = real(poles[idx2])
                R2 = real(residues[idx2])
                total_contribution += -R2 / (0.0 - p2)^2
            end
            break
        end
    end

    raw_d1 = TaylorDiff.derivative(z -> aaa_interps[name](z), 0.0, Val(1))
    @printf("\n  Total near-real pole d1 contribution: %+.6e\n", total_contribution)
    @printf("  Raw AAAD d1:                         %+.6e\n", raw_d1)
    @printf("  Raw - total_contribution:             %+.6e\n", raw_d1 - total_contribution)
    @printf("  Ground truth d1:                      %+.6e\n", ground_truth_d1_t0[name])
end

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

println()
println("="^80)
println("  SUMMARY")
println("="^80)
println()
println("Key questions answered:")
println("  1. Does deflating nearest pole help? → Check 'Deflate nearest' rows")
println("  2. Does deflating ALL spurious poles help? → Check 'Spur thr=*' rows")
println("  3. How does FHD5 (pole-free) perform? → Check 'FHD5' rows")
println("  4. Analytical correction vs TaylorDiff re-differentiation? → Compare strategies (b) vs (c)")
println("  5. Does anything achieve <10% error at t=0? → Check error column")
println()
println("Script complete.")
