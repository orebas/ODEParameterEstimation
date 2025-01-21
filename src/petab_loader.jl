module PEtabLoader

using PEtab
using ModelingToolkit

function load_model(yaml_file)
	# Create PEtabModel with homotopy continuation disabled
	return PEtabModel(yaml_file; use_homotopy_continuation = false)
end

end
