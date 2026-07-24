# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=10 nvar=10
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x1_0 x2_0 x3_1 x1_1 x2_1 x3_2 x3_3 x1_2 x2_2
system = HomotopyContinuation.System([
    1.00000067772319 - x3_0,
    -x1_0 - x2_0 + x3_1,
    0.37498915485725 - x3_1,
    -x1_1 - x2_1 + x3_2,
    (-337023501/3106732)*x1_0 + x1_1,
    (-13048874/766448551)*x2_0 + x2_1,
    0.0301133350729794 - x3_2,
    -x1_2 - x2_2 + x3_3,
    (-337023501/3106732)*x1_1 + x1_2,
    (-13048874/766448551)*x2_1 + x2_2,
  ], variables = [x3_0, x1_0, x2_0, x3_1, x1_1, x2_1, x3_2, x3_3, x1_2, x2_2])
