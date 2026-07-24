# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -265.253640194386 + (-681207744/20980613)*x3_0 + x3_1,
    -265.253640194386 + (-164924083/5079520)*x4_0 + x4_1,
    530.431160903196 + x1_1 + (681207744/20980613)*x3_0 + (164924083/5079520)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-2475003306/3732289)*x1_1 + (-681207744/20980613)*x3_1 + x3_2,
    (-2475003306/3732289)*x1_1 + (-164924083/5079520)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
