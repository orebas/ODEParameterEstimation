# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=10 nvar=10
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x1_0 x2_0 x3_1 x1_1 x2_1 x3_2 x3_3 x1_2 x2_2
system = HomotopyContinuation.System([
    1.00000067772319 - x3_0,
    -x1_0 - x2_0 + x3_1,
    0.37498915485725 - x3_1,
    -x1_1 - x2_1 + x3_2,
    (-27560243/178785869)*x1_0 + x1_1,
    (2450887073/5155750)*x2_0 + x2_1,
    0.0301133350729794 - x3_2,
    -x1_2 - x2_2 + x3_3,
    (-27560243/178785869)*x1_1 + x1_2,
    (2450887073/5155750)*x2_1 + x2_2,
  ], variables = [x3_0, x1_0, x2_0, x3_1, x1_1, x2_1, x3_2, x3_3, x1_2, x2_2])
