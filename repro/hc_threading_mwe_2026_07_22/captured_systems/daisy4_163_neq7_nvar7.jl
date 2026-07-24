# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -0.5166915482886 + (44615760/44781251)*x3_0 + x3_1,
    -0.5166915482886 + (56453194/56662593)*x4_0 + x4_1,
    1.15004712819659 + x1_1 + (-44615760/44781251)*x3_0 + (-56453194/56662593)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-103502108/80126961)*x1_1 + (44615760/44781251)*x3_1 + x3_2,
    (-96296693/74548833)*x1_1 + (56453194/56662593)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
