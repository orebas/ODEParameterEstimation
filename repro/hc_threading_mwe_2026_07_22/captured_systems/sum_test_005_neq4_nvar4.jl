# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=4 nvar=4
using HomotopyContinuation
HomotopyContinuation.@var x_0 k1_0 x_1 x_2
system = HomotopyContinuation.System([
    0.6107016490017 - x_0,
    x_1 - x_0*k1_0,
    0.305349077592903 - x_1,
    x_2 - x_1*k1_0,
  ], variables = [x_0, k1_0, x_1, x_2])
