using ODEParameterEstimation
using PEtab
using Statistics
using Plots
using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using DataFrames
include("../all_examples.jl")

function compare_data_sources(example_func, petab_dir)
	println("\nValidating $(example_func)")

	# Get original problem and sample data
	pep = example_func()
	orig_data = sample_problem_data(pep, datasize = 1001, time_interval = [0.0, 5.0])

	# Load and simulate PEtab problem
	yaml_file = joinpath(petab_dir, "problem.yaml")
	petab_model = PEtabModel(yaml_file)
	petab_prob = PEtabODEProblem(petab_model)

	# Get measurement data from PEtab
	meas_df = petab_model.petab_tables[:measurements]
	unique_times = sort(unique(meas_df.time))

	println("\nPEtab measurement data overview:")
	println("Number of measurements: ", nrow(meas_df))
	println("Time points: ", unique_times)
	println("Observable IDs: ", unique(meas_df.observableId))

	# Compare each observable
	max_rel_diffs = Float64[]
	mean_rel_diffs = Float64[]

	for (i, mq) in enumerate(pep.measured_quantities)
		println("\nObservable $i: $(mq.lhs)")

		# Get original data
		orig_values = orig_data.data_sample[Num(mq.rhs)]

		# Get PEtab data for this observable
		# Remove (t) from the observable name
		obs_name = string(mq.lhs)
		obs_name = replace(obs_name, "(t)" => "")
		obs_id = "obs_$obs_name"
		println("Looking for observable ID: $obs_id")

		obs_data = Vector{Float64}(undef, length(unique_times))
		for (i, t) in enumerate(unique_times)
			# Get measurements at this time point
			measurements = meas_df[meas_df.time.==t.&&meas_df.observableId.==obs_id, :measurement]
			println("Time $t: found $(length(measurements)) measurements")
			# Use mean if multiple measurements exist
			if isempty(measurements)
				println("WARNING: No measurements found for time $t")
				obs_data[i] = NaN
			else
				obs_data[i] = mean(measurements)
			end
		end

		# Calculate relative differences
		valid_indices = .!isnan.(obs_data)
		if any(valid_indices)
			rel_diffs = abs.(orig_values[valid_indices] .- obs_data[valid_indices]) ./
						(abs.(orig_values[valid_indices]) .+ abs.(obs_data[valid_indices]) .+ 1e-10)
			max_rel_diff = maximum(rel_diffs)
			mean_rel_diff = mean(rel_diffs)

			push!(max_rel_diffs, max_rel_diff)
			push!(mean_rel_diffs, mean_rel_diff)

			println("  Max relative difference: $(round(max_rel_diff * 100, digits=2))%")
			println("  Mean relative difference: $(round(mean_rel_diff * 100, digits=2))%")

			# Optional: Plot comparison
			p = plot(orig_data.data_sample["t"], orig_values, label = "Original", title = "Observable $i")
			scatter!(unique_times[valid_indices], obs_data[valid_indices], label = "PEtab")
			display(p)
		else
			println("WARNING: No valid data points for comparison")
		end
	end

	if !isempty(max_rel_diffs)
		return (max = maximum(max_rel_diffs), mean = mean(mean_rel_diffs))
	else
		return (max = NaN, mean = NaN)
	end
end

# List of all example functions and their corresponding PEtab directories
examples = [
	(biohydrogenation, "petab_BioHydrogenation"),
	(crauste, "petab_Crauste"),
	(daisy_ex3, "petab_DAISY_ex3"),
	(daisy_mamil3, "petab_DAISY_mamil3"),
	(daisy_mamil4, "petab_DAISY_mamil4"),
	(fitzhugh_nagumo, "petab_fitzhugh-nagumo"),
	(hiv, "petab_hiv"),
	(lotka_volterra, "petab_Lotka_Volterra"),
	(seir, "petab_SEIR"),
	(simple, "petab_simple"),
	(simple_linear_combination, "petab_simple_linear_combination"),
	(slowfast, "petab_slowfast"),
	(substr_test, "petab_substr_test"),
	(threesp_cubed, "petab_threesp_cubed"),
	(onesp_cubed, "petab_onesp_cubed"),
	(treatment, "petab_treatment"),
	(vanderpol, "petab_vanderpol"),
	(global_unident_test, "petab_global_unident_test"),
	(sum_test, "petab_sum_test"),
	(sirsforced, "petab_sirsforced"),
]

# Run validation for all examples
println("Starting validation...")
results = Dict{String, Union{NamedTuple{(:max, :mean), Tuple{Float64, Float64}}, Symbol}}()

for (func, dir) in examples
	try
		results[string(func)] = compare_data_sources(func, dir)
		println("\nResults for $(func):")
		println("  Maximum relative difference: $(round(results[string(func)].max * 100, digits=2))%")
		println("  Mean relative difference: $(round(results[string(func)].mean * 100, digits=2))%")
	catch e
		println("\nError processing $(func):")
		println(sprint(showerror, e))
		results[string(func)] = :error
	end

end

# Print summary
println("\n=== Validation Summary ===")
println("Number of models tested: $(length(examples))")
println("\nDetailed Results:")
for (model, result) in sort!(collect(results), by = first)  # Sort by model name
	if result === :error
		println("❌ $model: Failed to validate")
	else
		println("✓ $model: Max diff = $(round(result.max * 100, digits=2))%, Mean diff = $(round(result.mean * 100, digits=2))%")
	end
end
