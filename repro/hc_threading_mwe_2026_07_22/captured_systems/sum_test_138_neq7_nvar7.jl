# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x1_0 x2_0 x1_1 x2_1 x3_3 x1_2 x2_2
system = HomotopyContinuation.System([
    0.37498915485725 - x1_0 - x2_0,
    0.0301133350729794 - x1_1 - x2_1,
    (-5254777/94888641)*x1_0 + x1_1,
    (-37056669/669154364)*x2_0 + x2_1,
    -x1_2 - x2_2 + x3_3,
    (-5254777/94888641)*x1_1 + x1_2,
    (-37056669/669154364)*x2_1 + x2_2,
  ], variables = [x1_0, x2_0, x1_1, x2_1, x3_3, x1_2, x2_2])
