using ODEParameterEstimation
include("all_examples.jl")

# Create output directory if it doesn't exist
mkpath("petab-examples")

# List of all example functions
example_functions = [
	biohydrogenation,
	crauste,
	daisy_ex3,
	daisy_mamil3,
	daisy_mamil4,
	fitzhugh_nagumo,
	lv_periodic,
	hiv,
	lotka_volterra,
	seir,
	simple,
	simple_linear_combination,
	slowfast,
	substr_test,
	threesp_cubed,
	onesp_cubed,
	treatment,
	vanderpol,
	global_unident_test,
	sum_test,
	sirsforced,
	trivial_unident,
]

# Generate TOML for each example
for func in example_functions
	pep = func()
	toml_file = joinpath("petab-examples", "$(pep.name).toml")
	save_to_toml(pep, toml_file)
	println("Generated $(toml_file)")
end
