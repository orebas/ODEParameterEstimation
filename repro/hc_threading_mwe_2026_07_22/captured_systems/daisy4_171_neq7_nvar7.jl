# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -0.838295758751715 + (45718745/79262201)*x3_0 + x3_1,
    -0.838295758751715 + (22502679/39012704)*x4_0 + x4_1,
    1.8349164371736 + x1_1 + (-45718745/79262201)*x3_0 + (-22502679/39012704)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-712284120/339873127)*x1_1 + (45718745/79262201)*x3_1 + x3_2,
    (-712284120/339873127)*x1_1 + (22502679/39012704)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
