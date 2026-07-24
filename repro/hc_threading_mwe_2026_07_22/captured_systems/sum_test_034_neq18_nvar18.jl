# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=sum_test neq=18 nvar=18
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x1_0 x2_0 x3_1 x1_1 x2_1 x3_2 b_0 a_0 x3_3 x1_2 x2_2 x1_3 x2_3 x3_4 x1_4 x3_5 x2_4
system = HomotopyContinuation.System([
    1.29044813632501 - x3_0,
    -x1_0 - x2_0 + x3_1,
    0.40057554511997 - x3_1,
    -x1_1 - x2_1 + x3_2,
    x2_1 - b_0*x2_0,
    x1_1 + a_0*x1_0,
    0.0383701091242169 - x3_2,
    -x1_2 - x2_2 + x3_3,
    x2_2 - b_0*x2_1,
    x1_2 + a_0*x1_1,
    0.0118520311467454 - x3_3,
    -x1_3 - x2_3 + x3_4,
    x2_3 - b_0*x2_2,
    x1_3 + a_0*x1_2,
    0.0021198952805706 - x3_4,
    -x1_4 - x2_4 + x3_5,
    x2_4 - b_0*x2_3,
    x1_4 + a_0*x1_3,
  ], variables = [x3_0, x1_0, x2_0, x3_1, x1_1, x2_1, x3_2, b_0, a_0, x3_3, x1_2, x2_2, x1_3, x2_3, x3_4, x1_4, x3_5, x2_4])
