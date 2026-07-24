# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=4 nvar=4
using HomotopyContinuation
HomotopyContinuation.@var x_0 k1_0 x_1 x_2
system = HomotopyContinuation.System([
    0.610701389596067 - x_0,
    x_1 - x_0*k1_0,
    0.305350805513166 - x_1,
    x_2 - x_1*k1_0,
  ], variables = [x_0, k1_0, x_1, x_2])
