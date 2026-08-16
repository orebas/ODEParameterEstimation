using TOML

const CAMPAIGN_TOML_MISSING = "__missing__"

"""Atomically write one resumable campaign record as TOML.

TOML has no null value, while production timing and provenance payloads can
legitimately contain `nothing`. Unsupported values therefore pass through a
deterministic conversion function; `nothing` receives an explicit sentinel so
a completed scientific cell is not lost at the final write step.
"""
function _atomic_toml(path::String, payload::Dict{String, Any})
	mkpath(dirname(path))
	tmp_path, io = mktemp(dirname(path))
	try
		TOML.print(
			value -> value === nothing ? CAMPAIGN_TOML_MISSING : string(value),
			io, payload; sorted = true,
		)
		close(io)
		mv(tmp_path, path; force = true)
	catch
		isopen(io) && close(io)
		isfile(tmp_path) && rm(tmp_path; force = true)
		rethrow()
	end
	return path
end
