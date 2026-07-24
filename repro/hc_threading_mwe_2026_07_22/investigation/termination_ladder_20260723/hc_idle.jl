using HomotopyContinuation

include(joinpath(@__DIR__, "ready_common.jl"))

@var x
system = System([x^2 - 1])
result = solve(system; threading = true, show_progress = false)
nsolutions(result) == 2 || error("tiny HC control returned $(nsolutions(result)) solutions")

const NEVER_SET = Base.Event()

print_ready(
	"hc_idle";
	hc = Base.pkgversion(HomotopyContinuation),
	nsolutions = nsolutions(result),
)

wait(NEVER_SET)
