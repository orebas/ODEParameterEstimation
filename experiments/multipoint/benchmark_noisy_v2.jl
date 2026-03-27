# Benchmark: single-point vs multi-point estimation with noise
#
# Run: julia --startup-file=no -e 'using ODEParameterEstimation; include("experiments/multipoint/benchmark_noisy_v2.jl")'

using ODEParameterEstimation
using Printf
using Random

Random.seed!(42)

function flatten_results(x)
    out = ParameterEstimationResult[]
    if x isa ParameterEstimationResult; push!(out, x)
    elseif x isa Tuple; for item in x; append!(out, flatten_results(item)); end
    elseif x isa Vector; for item in x; append!(out, flatten_results(item)); end
    end; out
end

function best_error(raw)
    results = flatten_results(raw)
    errs = [r.err for r in results if !isnothing(r.err) && isfinite(r.err)]
    isempty(errs) ? NaN : minimum(errs)
end

models = [
    (:simple, ODEParameterEstimation.simple(), [0.0, 1.0]),
    (:lotka_volterra, ODEParameterEstimation.lotka_volterra(), nothing),
    (:fitzhugh_nagumo, ODEParameterEstimation.fitzhugh_nagumo(), nothing),
    (:biohydrogenation, ODEParameterEstimation.biohydrogenation(), [0.0, 1.0]),
    (:seir, ODEParameterEstimation.seir(), nothing),
]

noise_levels = [0.0, 0.01, 0.05]

struct BenchRow
    model::Symbol; noise::Float64
    sp_err::Float64; mp_err::Float64
    sp_time::Float64; mp_time::Float64
end

rows = BenchRow[]

for (name, pep, ti_override) in models
    for noise in noise_levels
        @printf(">>> %-20s noise=%.2f ... ", name, noise)
        flush(stdout)

        ti = !isnothing(ti_override) ? ti_override :
             !isnothing(pep.recommended_time_interval) ? pep.recommended_time_interval : [0.0, 5.0]

        sp_err = mp_err = NaN
        sp_time = mp_time = 0.0

        try
            # Sample data once (shared between SP and MP for fair comparison)
            sp_opts = EstimationOptions(datasize=201, noise_level=noise, time_interval=ti, nooutput=true)
            pep_data = ODEParameterEstimation.sample_problem_data(pep, sp_opts)

            # Single-point estimation
            t0 = time()
            res_sp = analyze_parameter_estimation_problem(pep_data, sp_opts)
            sp_time = time() - t0
            sp_err = best_error(res_sp)

            # Multi-point estimation (same data)
            mp_opts = EstimationOptions(use_multipoint=true, multipoint_n_points=2, multipoint_n_pairs=6,
                datasize=201, noise_level=noise, time_interval=ti, nooutput=true)
            t0 = time()
            res_mp = analyze_parameter_estimation_problem(pep_data, mp_opts)
            mp_time = time() - t0
            mp_err = best_error(res_mp)

        catch e
            @printf("FAILED: %s\n", sprint(showerror, e)[1:min(80,end)])
            flush(stdout)
        end

        push!(rows, BenchRow(name, noise, sp_err, mp_err, sp_time, mp_time))
        @printf("SP=%.4f MP=%.4f\n", sp_err, mp_err)
        flush(stdout)
    end
end

println("\n", "=" ^ 100)
@printf("%-20s %6s | %10s %7s | %10s %7s | %8s\n",
    "Model", "Noise", "Single-Pt", "Time", "Multi-Pt", "Time", "Ratio")
println("-" ^ 100)
for r in rows
    ratio = r.sp_err / r.mp_err
    ratio_str = (isnan(ratio) || isinf(ratio)) ? "   N/A" : @sprintf("%7.1f×", ratio)
    @printf("%-20s %6.2f | %10.4f %6.1fs | %10.4f %6.1fs | %s\n",
        r.model, r.noise, r.sp_err, r.sp_time, r.mp_err, r.mp_time, ratio_str)
end
println("=" ^ 100)
println("Ratio = SP_err / MP_err  (>1 means multi-point is better)")
