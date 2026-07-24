# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=18 nvar=18
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x1_0 x2_0 x3_1 x1_1 x2_1 x3_2 b_0 a_0 x3_3 x1_2 x2_2 x1_3 x2_3 x3_4 x1_4 x3_5 x2_4
system = HomotopyContinuation.System([
    1.00000067772319 - x3_0,
    -x1_0 - x2_0 + x3_1,
    0.37498915485725 - x3_1,
    -x1_1 - x2_1 + x3_2,
    x2_1 - b_0*x2_0,
    x1_1 + a_0*x1_0,
    0.0301133350729794 - x3_2,
    -x1_2 - x2_2 + x3_3,
    x2_2 - b_0*x2_1,
    x1_2 + a_0*x1_1,
    0.00965296197412973 - x3_3,
    -x1_3 - x2_3 + x3_4,
    x2_3 - b_0*x2_2,
    x1_3 + a_0*x1_2,
    0.00536373232368503 - x3_4,
    -x1_4 - x2_4 + x3_5,
    x2_4 - b_0*x2_3,
    x1_4 + a_0*x1_3,
  ], variables = [x3_0, x1_0, x2_0, x3_1, x1_1, x2_1, x3_2, b_0, a_0, x3_3, x1_2, x2_2, x1_3, x2_3, x3_4, x1_4, x3_5, x2_4])
