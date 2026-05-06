# Run cstr_1_0 under current code with bilby config + my cluster-first fix.
# Verify whether the truth-near candidate (memo says it's at rank 66 of 101 in the
# saved March pool) survives as a cluster rep under current code.

using CSV
using ModelingToolkit
using ODEParameterEstimation
using OrderedCollections
using Symbolics
using ModelingToolkit: D_nounits as D, t_nounits as t
using Logging
using Printf

const ODEPE = ODEParameterEstimation

function _load_bilby_data(case_dir, mq)
    csv_data = CSV.read(joinpath(case_dir, "data.csv"), Tuple, header = false)
    data_sample = OrderedDict{Union{String, Symbolics.Num}, Vector{Float64}}()
    data_sample["t"] = collect(Float64, csv_data[1])
    for (i, eq) in enumerate(mq)
        data_sample[Symbolics.Num(eq.rhs)] = collect(Float64, csv_data[i + 1])
    end
    return data_sample
end

parameters = @parameters tau Tin dH_rhoCP UA_VrhoCP
states = @variables C(t) Temp(t) r_eff(t)
observables = @variables y1(t)
eqs = [
    D(C) ~ (1.0 - C) / (2.0*tau) - 1.999863916554819*r_eff*C,
    D(Temp) ~ (Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t),
    D(r_eff) ~ 12.5*r_eff/(Temp^2)*((Tin - Temp) / (2.0*tau) + 0.0285694845222117*dH_rhoCP*r_eff*C - 2.0*UA_VrhoCP*Temp + 0.8571428571428571*UA_VrhoCP + 0.05714285714285714*UA_VrhoCP*sin(0.5*t)),
]
mq_orig = [y1 ~ 700.0*Temp]
ic = [0.843, 0.18, 0.856]
p_true = [0.385, 0.113, 0.248, 0.421]
model, mq = ODEPE.create_ordered_ode_system("cstr", states, parameters, eqs, mq_orig)
case_dir = "/home/orebas/ParameterEstimationBenchmarking/benchmark_bilby_2026_03_09/filetree/odepe_nopolish/cstr_1_0"
pep = ParameterEstimationProblem("cstr_1_0", model, mq, _load_bilby_data(case_dir, mq), [0.0, 20.0], nothing,
    OrderedDict(parameters .=> p_true), OrderedDict(states .=> ic), 0)

opts = EstimationOptions(
    datasize = length(pep.data_sample["t"]),
    noise_level = 0.000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    interpolators = InterpolatorMethod[
        InterpolatorAAAD, InterpolatorAAADGPR, InterpolatorS2AAAMLE,
        InterpolatorAGPRobust, InterpolatorAGPRobustRQ,
        InterpolatorAGPRobustSEpRQ, InterpolatorAGPRobustSExRQ,
        InterpolatorS3SE, InterpolatorS3RQ,
        InterpolatorS3SEpRQ, InterpolatorS3SExRQ, InterpolatorFHD,
    ],
    shooting_points = 12,
    shooting_warp = true,
    shooting_warp_beta = 3.0,
    use_parameter_homotopy = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 5000,
    polish_method = PolishBFGS,
    abstol = 1e-13, reltol = 1e-13,
    polish_maxtime = 1200.0,
    polish_divergence_factor = 10.0,
    polish_stagnation_window = 50,
    polish_ode_maxiters = 20000,
    diagnostics = false,
    nooutput = true,
    save_system = false,
    use_sensitivity_seeds = false,
)

println("Running cstr_1_0 on current code with bilby config...")
flush(stdout)
elapsed = @elapsed begin
    results = with_logger(NullLogger()) do
        ODEPE.analyze_parameter_estimation_problem(pep, opts)
    end
end

solutions_vector = results[2][1]
besterror = results[2][2]
@printf("Elapsed: %.1fs, %d cluster reps\n", elapsed, length(solutions_vector))

function _max_rel(c, truth)
    rels = Float64[]
    for (sym, true_val) in truth
        for (k, v) in c.parameters
            if string(k) == string(sym); push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v)-Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v)-Float64(true_val))); break; end
        end
        for (k, v) in c.states
            if string(k) == string(sym); push!(rels, abs(true_val) > 1e-12 ? abs(Float64(v)-Float64(true_val))/abs(Float64(true_val)) : abs(Float64(v)-Float64(true_val))); break; end
        end
    end
    return isempty(rels) ? NaN : maximum(rels)
end

truth = OrderedDict{Any, Any}()
for (k, v) in pep.p_true; truth[k] = v; end
for (k, v) in pep.ic; truth[k] = v; end

@printf("Truth: tau=%g, Tin=%g, dH_rhoCP=%g, UA_VrhoCP=%g; C=%g, Temp=%g, r_eff=%g\n",
    p_true[1], p_true[2], p_true[3], p_true[4], ic[1], ic[2], ic[3])

println("\nSolutions_vector[1] (the winner):")
println("  parameters: ", solutions_vector[1].parameters)
println("  states:     ", solutions_vector[1].states)
println("  err:        ", solutions_vector[1].err)
@printf("  rel-err: %.4g\n", _max_rel(solutions_vector[1], truth))

# Check if any cluster rep is truth-near
all_rels = [(i, _max_rel(c, truth), c.err) for (i, c) in enumerate(solutions_vector)]
finite = filter(t -> isfinite(t[2]), all_rels)
sorted_by_rel = sort(finite; by = t -> t[2])
println("\nTop 10 cluster reps by rel-err:")
for (i, rel, err) in first(sorted_by_rel, 10)
    @printf("  pos %d: rel=%.4g, err=%.4g\n", i, rel, err)
end

# Count near-truth reps
@printf("\nReps with rel<0.10: %d\n", count(t -> t[2] < 0.10, finite))
@printf("Reps with rel<0.50: %d\n", count(t -> t[2] < 0.50, finite))

println("\nCSTR_CHECK_DONE")
