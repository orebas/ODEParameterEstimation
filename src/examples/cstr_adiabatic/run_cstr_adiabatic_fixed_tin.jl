"""
Run parameter estimation for the CSTR model with fixed inlet temperature.

This model has 4 parameters (E_R, tau, Delta_T_ad, UA_VrhoCP) with Tin fixed.
"""

using ODEParameterEstimation
using Logging
using GaussianProcesses
using LineSearches
using Optim
using Statistics
using SciMLBase
using Optimization
using OptimizationOptimJL
using OptimizationOptimisers
using OptimizationMOI
using NLSolversBase: NLSolversBase
using NonlinearSolve
using LeastSquaresOptim
using AbstractAlgebra

include("cstr_adiabatic_fixed_tin.jl")

log_dir = joinpath(@__DIR__, "logs")
!isdir(log_dir) && mkpath(log_dir)

standard_opts = EstimationOptions(
    datasize = 501,
    noise_level = 0.000000,
    system_solver = SolverHC,
    flow = FlowStandard,
    use_si_template = true,
    polish_solver_solutions = true,
    polish_solutions = false,
    polish_maxiters = 50,
    polish_method = PolishLBFGS,
    opt_ad_backend = :enzyme,
    interpolator = InterpolatorAAADGPR,
    diagnostics = true
)

function run_cstr_adiabatic_fixed_tin_estimation(; opts = standard_opts)
    model_name = :cstr_adiabatic_fixed_tin
    log_file_path = joinpath(log_dir, "$(model_name).log")

    println("Running model: $model_name")
    println("Log file: $log_file_path")

    original_stdout = stdout
    original_stderr = stderr

    open(log_file_path, "w") do log_stream
        with_logger(ConsoleLogger(log_stream)) do
            redirect_stdout(log_stream) do
                redirect_stderr(log_stream) do
                    try
                        pep = cstr_adiabatic_fixed_tin()

                        println("Model: $(pep.name)")
                        println("Parameters: $(keys(pep.p_true))")
                        println("True parameter values: $(values(pep.p_true))")
                        println("States: $(keys(pep.ic))")
                        println("True initial conditions: $(values(pep.ic))")
                        println()

                        time_interval = isnothing(pep.recommended_time_interval) ? [0.0, 5.0] : pep.recommended_time_interval

                        println("Using NEW optimized workflow")
                        println("Starting model: $model_name")

                        model_opts = merge_options(opts, time_interval = time_interval)

                        @time analyze_parameter_estimation_problem(
                            sample_problem_data(pep, model_opts),
                            model_opts,
                        )

                        println("SUCCESS")
                        println(original_stdout, "Model $model_name completed successfully. See $log_file_path")
                    catch e
                        println("FAILURE")
                        println(original_stderr, "Model $model_name failed. See $log_file_path for details.")
                        showerror(log_stream, e, catch_backtrace())
                    end
                end
            end
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_cstr_adiabatic_fixed_tin_estimation()
end
