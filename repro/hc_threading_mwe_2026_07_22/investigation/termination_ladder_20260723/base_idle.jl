include(joinpath(@__DIR__, "ready_common.jl"))

const NEVER_SET = Base.Event()

print_ready("base_idle")

wait(NEVER_SET)
