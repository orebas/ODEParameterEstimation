using ODEParameterEstimation

# Include all model files
include("../../models/simple_models.jl")
include("../../models/classical_systems.jl")
include("../../models/biological_systems.jl")
include("../../models/test_models.jl")

# Create output directory if it doesn't exist
mkpath("../tomls")

# Dictionary mapping model names to their constructor functions
model_dict = Dict(
	# Simple models
	:simple => simple,
	:simple_linear_combination => simple_linear_combination,
	:onesp_cubed => onesp_cubed,
	:threesp_cubed => threesp_cubed,

	# Classical systems
	:lotka_volterra => lotka_volterra,
	:vanderpol => vanderpol,
	:brusselator => brusselator,

	# Biological systems
	:hiv => hiv,
	:seir => seir,
	:treatment => treatment,
	:biohydrogenation => biohydrogenation,
	:repressilator => repressilator,

	# Test models
	:substr_test => substr_test,
	:global_unident_test => global_unident_test,
	:sum_test => sum_test,
	:trivial_unident => trivial_unident,
)

# Generate TOML for each model
for (name, func) in model_dict
	try
		@info "Generating TOML for $name"
		pep = func()
		toml_file = joinpath("..", "tomls", "$(pep.name).toml")
		save_to_toml(pep, toml_file)
		println("Generated $(toml_file)")
	catch e
		@warn "Failed to generate TOML for $name" exception = e
	end
end
