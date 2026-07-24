function _ready_field(value)
	return replace(string(value), '\t' => ' ', '\r' => ' ', '\n' => ' ')
end

function _active_project()
	project = Base.active_project()
	return project === nothing ? "" : project
end

function print_ready(case::AbstractString; fields...)
	common = (
		case = case,
		pid = getpid(),
		julia = VERSION,
		julia_executable = joinpath(Sys.BINDIR, Base.julia_exename()),
		active_project = _active_project(),
		load_path = join(Base.load_path(), ';'),
		depot_path = join(DEPOT_PATH, ';'),
		threads = Threads.nthreads(),
		gc_threads = Threads.ngcthreads(),
	)
	values = String["READY"]
	append!(
		values,
		["$(_ready_field(key))=$(_ready_field(value))" for (key, value) in pairs(common)],
	)
	append!(
		values,
		["$(_ready_field(key))=$(_ready_field(value))" for (key, value) in pairs(fields)],
	)
	println(join(values, '\t'))
	flush(stdout)
	return nothing
end
