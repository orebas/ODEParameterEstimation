# Captured ODEPE fresh HC system (pure HomotopyContinuation.jl).
# tag=daisy4 neq=7 nvar=7
using HomotopyContinuation
HomotopyContinuation.@var x3_0 x4_0 x3_1 x4_1 x1_1 x3_2 x4_2
system = HomotopyContinuation.System([
    1.39999950254762 + (-1/2)*x3_0 + (-1/2)*x4_0,
    -5.68766793270656 + (-1135189402/19269587)*x3_0 + x3_1,
    -5.68766793270654 + (-698761873/11861327)*x4_0 + x4_1,
    11.2436163834899 + x1_1 + (1135189402/19269587)*x3_0 + (698761873/11861327)*x4_0,
    -0.29993324066383 + (-1/2)*x3_1 + (-1/2)*x4_1,
    (-444302452/31246783)*x1_1 + (-1135189402/19269587)*x3_1 + x3_2,
    (-577183436/40592001)*x1_1 + (-698761873/11861327)*x4_1 + x4_2,
  ], variables = [x3_0, x4_0, x3_1, x4_1, x1_1, x3_2, x4_2])
