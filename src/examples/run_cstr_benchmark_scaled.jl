# Self-contained benchmark-scaled CSTR test
#
# Replicates the benchmark CSTR from no-matlab-no-worry (cstr_0_0/script.jl)
# as a standalone script that generates its own data.
#
# The benchmark rescales all parameters to [0.1, 0.9] with scaling coefficients
# baked into the ODE equations.  This tests whether ODEPE's identifiability
# reporting matches SI.jl when parameters are well-conditioned.
#
# Usage: julia src/examples/run_cstr_benchmark_scaled.jl

include("load_examples.jl")

using StructuralIdentifiability
using Logging

println("=" ^ 70)
println("Benchmark-Scaled CSTR (self-contained)")
println("=" ^ 70)

# ── Model definition (exact copy from benchmark cstr_0_0/script.jl) ──────

parameters_list = @parameters tau Tin Cin dH_rhoCP UA_VrhoCP
states_list = @variables C(t) Temp(t) r_eff(t)
observables_list = @variables y1(t)

state_equations = [
    D(C) ~ (2.0 * Cin - C) / (2.0 * tau) - 1.999863916554819 * r_eff * C,
    D(Temp) ~ (Tin - Temp) / (2.0 * tau) + 0.0285694845222117 * dH_rhoCP * r_eff * C - 2.0 * UA_VrhoCP * Temp + 0.8571428571428571 * UA_VrhoCP + 0.05714285714285714 * UA_VrhoCP * sin(0.5 * t),
    D(r_eff) ~ 12.5 * r_eff / (Temp^2) * ((Tin - Temp) / (2.0 * tau) + 0.0285694845222117 * dH_rhoCP * r_eff * C - 2.0 * UA_VrhoCP * Temp + 0.8571428571428571 * UA_VrhoCP + 0.05714285714285714 * UA_VrhoCP * sin(0.5 * t)),
]

measured_quantities = [y1 ~ 700.0 * Temp]

p_true = [0.32, 0.574, 0.817, 0.425, 0.542]
ic_true = [0.317, 0.464, 0.421]

println("\nModel (benchmark-scaled CSTR):")
println("  States:      C(t), Temp(t), r_eff(t)")
println("  Parameters:  tau, Tin, Cin, dH_rhoCP, UA_VrhoCP")
println("  Observable:  y1 ~ 700.0*Temp")
println("  True params: $p_true  (all in [0.1, 0.9])")
println("  True ICs:    $ic_true")
println("  Time:        [0, 20]")
println("  Note: sin(0.5*t) in ODE — auto_handle_transcendentals will polynomialize it")
println()

# ── Build model and generate data ────────────────────────────────────────

model, mq = create_ordered_ode_system(
    "cstr_benchmark_scaled", states_list, parameters_list, state_equations, measured_quantities
)

pep_template = ParameterEstimationProblem(
    "cstr_benchmark_scaled",
    model,
    mq,
    nothing,
    [0.0, 20.0],
    nothing,
    OrderedDict(parameters_list .=> p_true),
    OrderedDict(states_list .=> ic_true),
    0,
)

opts = EstimationOptions(
    datasize = 1001,
    noise_level = 0.0,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 50000,
    polish_method = PolishBFGS,
    abstol = 1e-13,
    reltol = 1e-13,
    diagnostics = true,
)

println("Generating data from model...")
pep = sample_problem_data(pep_template, opts)
println("  Generated $(length(pep.data_sample["t"])) time points")
println()

# ── Part 1: SI.jl direct identifiability check ──────────────────────────
# SI.jl requires polynomial RHS, so we polynomialize sin(0.5*t) first
# using ODEPE's transform_pep_for_estimation.

println("=" ^ 70)
println("PART 1: SI.jl assess_identifiability (on polynomialized system)")
println("=" ^ 70)
println()

t_var = ModelingToolkit.get_iv(pep.model.system)
pep_poly, tr_info = ODEParameterEstimation.transform_pep_for_estimation(pep, t_var)
if !isnothing(tr_info)
    println("Transcendental transform: $(length(tr_info.entries)) expression(s) polynomialized")
end

try
    id_result = StructuralIdentifiability.assess_identifiability(
        pep_poly.model.system;
        measured_quantities = pep_poly.measured_quantities,
        prob_threshold = 0.99,
        loglevel = Logging.Warn,
    )

    println("\nSI.jl Results:")
    println("-" ^ 50)
    n_unid = 0
    for (param, status) in id_result
        flag = status == :nonidentifiable ? " *** UNIDENTIFIABLE ***" : ""
        println("  $param => $status$flag")
        if status == :nonidentifiable
            n_unid += 1
        end
    end
    println("-" ^ 50)
    println("Total unidentifiable: $n_unid / $(length(id_result))")
catch e
    println("SI.jl direct call failed: $e")
    println("(This can happen with large rational coefficients in Groebner basis.)")
    println("SI.jl will still run internally via ODEPE's use_si_template path below.")
end
println()

# ── Part 2: ODEPE full estimation ────────────────────────────────────────

println("=" ^ 70)
println("PART 2: ODEPE analyze_parameter_estimation_problem")
println("=" ^ 70)
println()

result = analyze_parameter_estimation_problem(pep, opts)
