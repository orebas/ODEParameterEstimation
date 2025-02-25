module PEtabLoader

using PEtab
using ModelingToolkit

"""
	load_model(yaml_file)

Load a PEtab model from a YAML file with homotopy continuation disabled by default.
"""
function load_model(yaml_file)
	# Create PEtabModel with homotopy continuation disabled
	return PEtabModel(yaml_file; use_homotopy_continuation = false)
end

# Alias for consistency with extension naming
const load_petab_model = load_model

end
