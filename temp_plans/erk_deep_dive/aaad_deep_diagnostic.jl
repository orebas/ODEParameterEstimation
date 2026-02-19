#!/usr/bin/env julia
# Deep diagnostic: exactly what happens inside AAAD at boundaries

using ODEParameterEstimation
using ModelingToolkit, OrdinaryDiffEq, OrderedCollections
# Access dependencies through ODEParameterEstimation's imports
const BaryRational = ODEParameterEstimation.BaryRational
const TaylorDiff = ODEParameterEstimation.TaylorDiff

# ── ERK model setup ──────────────────────────────────────────────────
solver = AutoVern9(Rodas4P())
@independent_variables t
@parameters kf1 kr1 kc1 kf2 kr2 kc2
@variables S0(t) C1(t) C2(t) S1(t) S2(t) E(t) y0(t) y1(t) y2(t)
D = Differential(t)
states = [S0, C1, C2, S1, S2, E]
parameters = [kf1, kr1, kc1, kf2, kr2, kc2]
eqs = [
    D(S0) ~ -kf1*E*S0 + kr1*C1,
    D(C1) ~ kf1*E*S0 - (kr1 + kc1)*C1,
    D(C2) ~ kc1*C1 - (kr2 + kc2)*C2 + kf2*E*S1,
    D(S1) ~ -kf2*E*S1 + kr2*C2,
    D(S2) ~ kc2*C2,
    D(E) ~ -kf1*E*S0 + kr1*C1 - kf2*E*S1 + (kr2 + kc2)*C2,
]
@named model = ODESystem(eqs, t, states, parameters)
measured_quantities = [y0 ~ S0, y1 ~ S1, y2 ~ S2]
ic = [5.0, 0.0, 0.0, 0.0, 0.0, 0.65]
p_true = [11.5, 300.0, 12.45, 11.15, 4.864, 428.13]

# Generate data
datasize = 2001
data_sample = ODEParameterEstimation.sample_data(
    model, measured_quantities, [0.0, 20.0],
    Dict(parameters .=> p_true), Dict(states .=> ic),
    datasize; solver=solver)

t_data = Float64.(data_sample["t"])
h = t_data[2] - t_data[1]
println("Data: $datasize points, h = $h")
println("t range: [$(t_data[1]), $(t_data[end])]")

# ── Build AAA interpolants for each observable ───────────────────────
# data_sample keys can be Num symbols or strings — find by string match
function find_obs_key(ds, pattern)
    for k in keys(ds)
        ks = string(k)
        if contains(ks, pattern)
            return k
        end
    end
    error("Key matching '$pattern' not found. Available: $(string.(keys(ds)))")
end

println("data_sample keys: ", [string(k) for k in keys(data_sample)])

obs_data = Dict(
    "S0" => Float64.(data_sample[find_obs_key(data_sample, "S0")]),
    "S1" => Float64.(data_sample[find_obs_key(data_sample, "S1")]),
    "S2" => Float64.(data_sample[find_obs_key(data_sample, "S2")]),
)

println("\n" * "="^100)
println("PART 1: AAA SUPPORT POINT ANALYSIS")
println("="^100)

for obs_name in ["S0", "S1", "S2"]
    y_data = obs_data[obs_name]

    # Build AAA approximant directly (same as aaad_old_reliable does)
    aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)

    support_pts = aaa_approx.x
    support_vals = aaa_approx.f
    support_weights = aaa_approx.w

    println("\n--- $obs_name ---")
    println("  Number of support points: $(length(support_pts))")
    println("  Support point range: [$(minimum(support_pts)), $(maximum(support_pts))]")

    # Is t=0 a support point?
    idx_zero = findfirst(x -> abs(x) < 1e-14, support_pts)
    if !isnothing(idx_zero)
        println("  *** t=0 IS a support point (index $idx_zero)")
        println("      value = $(support_vals[idx_zero]), weight = $(support_weights[idx_zero])")
    else
        println("  t=0 is NOT a support point")
        nearest_to_zero = argmin(abs.(support_pts))
        println("  Nearest support point to 0: t=$(support_pts[nearest_to_zero]) (index $nearest_to_zero)")
        println("      value = $(support_vals[nearest_to_zero]), weight = $(support_weights[nearest_to_zero])")
    end

    # Is t=20 a support point?
    idx_end = findfirst(x -> abs(x - 20.0) < 1e-14, support_pts)
    if !isnothing(idx_end)
        println("  *** t=20 IS a support point (index $idx_end)")
        println("      value = $(support_vals[idx_end]), weight = $(support_weights[idx_end])")
    else
        println("  t=20 is NOT a support point")
        nearest_to_end = argmin(abs.(support_pts .- 20.0))
        println("  Nearest support point to 20: t=$(support_pts[nearest_to_end])")
    end

    # Show first 10 and last 10 support points (sorted)
    sorted_idx = sortperm(support_pts)
    println("  First 10 support points (sorted by t):")
    for i in 1:min(10, length(sorted_idx))
        j = sorted_idx[i]
        println("    t=$(support_pts[j])  f=$(support_vals[j])  w=$(support_weights[j])")
    end
    println("  Last 5 support points:")
    for i in max(1, length(sorted_idx)-4):length(sorted_idx)
        j = sorted_idx[i]
        println("    t=$(support_pts[j])  f=$(support_vals[j])  w=$(support_weights[j])")
    end
end

println("\n" * "="^100)
println("PART 2: BREAKFLAG BEHAVIOR WITH TAYLORDIFF")
println("="^100)

# Focus on S0 for detailed analysis
y_data = obs_data["S0"]
aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)
sp = aaa_approx.x
sf = aaa_approx.f
sw = aaa_approx.w

# Our baryEval (from derivatives.jl)
function baryEval_debug(z, f, x, w; tol=1e-13, verbose=false)
    num = zero(typeof(z))
    den = zero(typeof(z))
    breakflag = false
    breakindex = -1
    for j in eachindex(f)
        t_val = w[j] / (z - x[j])
        num += t_val * f[j]
        den += t_val
        check = (z - x[j])^2
        if verbose && j <= 5
            println("    j=$j: x=$(x[j]), z-x=$(z-x[j]), (z-x)^2=$check, threshold=$(sqrt(tol))")
        end
        if check < sqrt(tol)
            breakflag = true
            breakindex = j
            if verbose
                println("    *** BREAKFLAG triggered at j=$j, x=$(x[j])")
            end
        end
    end
    fz = num / den
    if breakflag
        if verbose
            println("    Entering break branch, breakindex=$breakindex, x[break]=$(x[breakindex])")
        end
        num = zero(typeof(z))
        den = zero(typeof(z))
        for j in eachindex(f)
            if j != breakindex
                t_val = w[j] / (z - x[j])
                num += t_val * f[j]
                den += t_val
            end
        end
        m = z - x[breakindex]
        fz = (w[breakindex] * f[breakindex] + m * num) / (w[breakindex] + m * den)
        if verbose
            println("    m = $m")
            println("    num (excluding break) = $num")
            println("    den (excluding break) = $den")
            println("    result = $fz")
        end
    else
        if verbose
            println("    No breakflag triggered, using standard formula")
            println("    num = $num, den = $den, result = $fz")
        end
    end
    return fz
end

# Test at z=0 with a plain Float64
println("\n--- baryEval at z=0.0 (Float64) ---")
val_0 = baryEval_debug(0.0, sf, sp, sw; verbose=true)
println("  Result: $val_0")

# Test at z=0 with TaylorScalar (what TaylorDiff.derivative does internally)
println("\n--- baryEval at z=TaylorScalar(0.0) ---")
# TaylorDiff creates a TaylorScalar like make_seed(0.0, Val(1)) for first derivative
z_taylor = TaylorDiff.make_seed(0.0, 1.0, Val(1))
println("  TaylorScalar: $z_taylor (type: $(typeof(z_taylor)))")

# Check: can we compare TaylorScalar < Float64?
test_cmp = try
    result = (z_taylor - sp[1])^2
    println("  (z_taylor - sp[1])^2 = $result (type: $(typeof(result)))")
    is_less = result < sqrt(1e-13)
    println("  result < sqrt(1e-13) = $is_less")
    "works"
catch e
    println("  Comparison FAILED: $e")
    "fails"
end

# Now test the actual TaylorDiff derivative
println("\n--- TaylorDiff.derivative at z=0.0 ---")
aaad_interp = ODEParameterEstimation.AAADapprox(aaa_approx)

for order in 0:3
    val = try
        ODEParameterEstimation.nth_deriv(x -> aaad_interp(x), order, 0.0)
    catch e
        "ERROR: $e"
    end
    println("  Order $order at t=0: $val")
end

# Compare with BaryRational's own bary function
println("\n--- BaryRational.bary at z=0.0 ---")
val_bary = BaryRational.bary(0.0, aaa_approx)
println("  bary(0.0) = $val_bary")

# And BaryRational's bary through TaylorDiff
println("\n--- TaylorDiff through BaryRational.bary ---")
for order in 0:3
    val = try
        TaylorDiff.derivative(z -> BaryRational.bary(z, sf, sp, sw), 0.0, Val(order))
    catch e
        "ERROR: $e"
    end
    println("  Order $order at t=0: $val")
end

println("\n" * "="^100)
println("PART 3: COMPARISON AT BOTH BOUNDARIES")
println("="^100)

# Analytical ground truth at t=0
kf1_v, kr1_v, kc1_v, kf2_v, kr2_v, kc2_v = p_true
S0_0, C1_0, C2_0, S1_0, S2_0, E_0 = ic
S0_1 = -kf1_v*E_0*S0_0 + kr1_v*C1_0  # = -37.375
S0_2 = -kf1_v*((-37.375)*S0_0 + E_0*S0_1) + kr1_v*(kf1_v*E_0*S0_0 - (kr1_v+kc1_v)*C1_0)

println("\nGround truth at t=0: S0=$S0_0, S0'=$S0_1, S0''=$S0_2")

for obs_name in ["S0", "S1", "S2"]
    y_data = obs_data[obs_name]
    aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)
    interp = ODEParameterEstimation.AAADapprox(aaa_approx)

    println("\n--- $obs_name: derivatives at both boundaries ---")

    for eval_t in [0.0, 20.0]
        print("  t=$eval_t: ")
        for order in 0:2
            val = try
                ODEParameterEstimation.nth_deriv(x -> interp(x), order, eval_t)
            catch e
                NaN
            end
            print("  d$(order)=$(val)")
        end
        println()
    end

    # Also test at t = h/2 (between first two data points)
    eval_mid = h/2
    print("  t=$eval_mid: ")
    for order in 0:2
        val = try
            ODEParameterEstimation.nth_deriv(x -> interp(x), order, eval_mid)
        catch e
            NaN
        end
        print("  d$(order)=$(val)")
    end
    println()
end

println("\n" * "="^100)
println("PART 4: WHAT IF WE BYPASS baryEval AND USE BaryRational DIRECTLY?")
println("="^100)

for obs_name in ["S0", "S1", "S2"]
    y_data = obs_data[obs_name]
    aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)

    println("\n--- $obs_name ---")
    println("  Our baryEval vs BaryRational.bary, TaylorDiff derivatives at t=0:")

    for order in 0:2
        val_ours = try
            f_ours = z -> ODEParameterEstimation.baryEval(z, aaa_approx.f, aaa_approx.x, aaa_approx.w)
            TaylorDiff.derivative(f_ours, 0.0, Val(order))
        catch e
            "ERR: $(sprint(showerror, e))"
        end

        val_bary = try
            f_bary = z -> BaryRational.bary(z, aaa_approx.f, aaa_approx.x, aaa_approx.w)
            TaylorDiff.derivative(f_bary, 0.0, Val(order))
        catch e
            "ERR: $(sprint(showerror, e))"
        end

        println("  Order $order:  baryEval=$val_ours  |  BaryRational.bary=$val_bary")
    end
end

println("\n" * "="^100)
println("PART 5: POLES OF THE AAA APPROXIMANT")
println("="^100)

for obs_name in ["S0", "S1", "S2"]
    y_data = obs_data[obs_name]
    aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)

    pol, res, zer = BaryRational.prz(aaa_approx)

    println("\n--- $obs_name ---")
    println("  Number of poles: $(length(pol))")

    # Find poles near t=0
    near_zero = filter(p -> abs(p) < 1.0, pol)
    println("  Poles within |z| < 1 of origin:")
    for p in sort(near_zero, by=abs)
        r_idx = findfirst(pp -> pp == p, pol)
        println("    pole=$(p), |pole|=$(abs(p)), residue=$(res[r_idx])")
    end

    # Find poles near t=20
    near_end = filter(p -> abs(p - 20.0) < 1.0, pol)
    println("  Poles within |z-20| < 1:")
    for p in sort(near_end, by=x->abs(x-20))
        r_idx = findfirst(pp -> pp == p, pol)
        println("    pole=$(p), |pole-20|=$(abs(p-20)), residue=$(res[r_idx])")
    end

    # Find real poles in [0, 20]
    real_poles = filter(p -> abs(imag(p)) < 1e-10 && real(p) >= -0.5 && real(p) <= 20.5, pol)
    if !isempty(real_poles)
        println("  *** REAL poles near [0,20]: $real_poles")
    else
        println("  No real poles near [0,20]")
    end
end

println("\n" * "="^100)
println("PART 6: DERIVATIVE VALUE SWEEP NEAR BOUNDARIES")
println("="^100)

# For S0, compute derivatives at many points near both boundaries
y_data = obs_data["S0"]
aaa_approx = BaryRational.aaa(t_data, y_data, verbose=false)
interp = ODEParameterEstimation.AAADapprox(aaa_approx)

println("\nS0 first derivative near left boundary (t=0):")
println("  t               | d1_baryEval       | d1_BaryRational.bary")
for exp_val in [0, -15, -14, -13, -12, -10, -8, -6, -5, -4, -3, -2]
    eval_t = exp_val == 0 ? 0.0 : 10.0^exp_val

    d1_ours = try
        ODEParameterEstimation.nth_deriv(x -> interp(x), 1, eval_t)
    catch e
        NaN
    end

    d1_bary = try
        TaylorDiff.derivative(z -> BaryRational.bary(z, aaa_approx.f, aaa_approx.x, aaa_approx.w), eval_t, Val(1))
    catch e
        NaN
    end

    println("  $(lpad(eval_t, 16)) | $(lpad(d1_ours, 18)) | $(lpad(d1_bary, 18))")
end

println("\nS0 first derivative near right boundary (t=20):")
for delta in [0.0, 1e-15, 1e-12, 1e-10, 1e-8, 1e-6, 1e-4, 1e-3, 1e-2, 1e-1]
    eval_t = 20.0 - delta

    d1_ours = try
        ODEParameterEstimation.nth_deriv(x -> interp(x), 1, eval_t)
    catch e
        NaN
    end

    println("  t=$(lpad(eval_t, 16)) (20-$(delta)): d1=$d1_ours")
end

println("\n" * "="^100)
println("PART 7: IS THE BREAKFLAG BRANCH EVEN REACHED BY TAYLORDIFF?")
println("="^100)

# Instrument baryEval to print when breakflag triggers with TaylorScalar
println("\nTesting breakflag with TaylorScalar types...")

# Manual test: create TaylorScalar at t=0 and check the comparison
z_ts = TaylorDiff.make_seed(0.0, 1.0, Val(2))  # For 2nd derivative
println("TaylorScalar for t=0, order 2: $z_ts")
println("Type: $(typeof(z_ts))")

# Check if t=0 is a support point
idx_at_zero = findfirst(x -> abs(x) < 1e-14, sp)
if !isnothing(idx_at_zero)
    diff_val = z_ts - sp[idx_at_zero]
    println("z_ts - sp[$idx_at_zero] = $diff_val  (type: $(typeof(diff_val)))")
    sq = diff_val^2
    println("(z_ts - sp[$idx_at_zero])^2 = $sq  (type: $(typeof(sq)))")
    threshold = sqrt(1e-13)
    println("threshold = $threshold")
    cmp_result = try
        sq < threshold
    catch e
        "COMPARISON ERROR: $e"
    end
    println("comparison result: $cmp_result")
else
    println("t=0 is not a support point, checking nearest...")
    nearest = argmin(abs.(sp))
    diff_val = z_ts - sp[nearest]
    println("z_ts - sp[$nearest] = $diff_val  (sp[$nearest]=$(sp[nearest]))")
    sq = diff_val^2
    println("(z_ts - sp[$nearest])^2 = $sq")
    threshold = sqrt(1e-13)
    cmp_result = try
        sq < threshold
    catch e
        "COMPARISON ERROR: $e"
    end
    println("comparison result: $cmp_result")
end

# Check what methods exist for < on TaylorScalar
println("\nMethods for < involving TaylorScalar:")
ts_type = typeof(z_ts)
println("  isless(::$ts_type, ::Float64): ", hasmethod(isless, (ts_type, Float64)))
println("  <(::$ts_type, ::Float64): ", hasmethod(<, (ts_type, Float64)))
println("  isless(::Float64, ::$ts_type): ", hasmethod(isless, (Float64, ts_type)))
