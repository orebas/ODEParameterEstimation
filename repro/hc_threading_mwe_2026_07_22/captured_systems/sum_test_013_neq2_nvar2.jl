# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=2 nvar=2
using HomotopyContinuation
HomotopyContinuation.@var x_0 x_1
system = HomotopyContinuation.System([
    0.500000007537826 - x_0,
    (-91738118/183476225)*x_0 + x_1,
  ], variables = [x_0, x_1])
