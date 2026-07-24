using ODEParameterEstimation

include(joinpath(@__DIR__, "ready_common.jl"))

function git_output(root::AbstractString, args::AbstractString...)
	command = Cmd(vcat(["git", "-C", String(root)], String[args...]))
	return readchomp(command)
end

odepe_path = String(pathof(ODEParameterEstimation))
source_root = dirname(dirname(odepe_path))
source_commit = git_output(source_root, "rev-parse", "HEAD")
source_tree = git_output(source_root, "rev-parse", "HEAD^{tree}")
source_status = git_output(
	source_root,
	"status",
	"--porcelain=v1",
	"--untracked-files=all",
)

const NEVER_SET = Base.Event()

print_ready(
	"odepe_idle";
	odepe = Base.pkgversion(ODEParameterEstimation),
	odepe_path = odepe_path,
	source_root = source_root,
	source_commit = source_commit,
	source_tree = source_tree,
	source_dirty = !isempty(source_status),
)

wait(NEVER_SET)
