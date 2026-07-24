# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -0.701849031350629 + (27043135/48431079)*x3_0 + x3_1,
    -0.701849031350629 + (86250824/154465097)*x4_0 + x4_1,
    1.50346924678981 + x1_1 + (-27043135/48431079)*x3_0 + (-86250824/154465097)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-93701368/53402681)*x1_1 + (27043135/48431079)*x3_1 + x3_2,
    (-93701368/53402681)*x1_1 + (86250824/154465097)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
