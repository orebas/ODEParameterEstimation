# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -0.823615840013854 + (65138512/113534307)*x3_0 + x3_1,
    -0.823615840013854 + (81447420/141960203)*x4_0 + x4_1,
    1.74980477581855 + x1_1 + (-65138512/113534307)*x3_0 + (-81447420/141960203)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-51748945/25132613)*x1_1 + (65138512/113534307)*x3_1 + x3_2,
    (-51748945/25132613)*x1_1 + (81447420/141960203)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
