# Polynomial system saved on 2025-09-01T22:28:21.053
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# reconstruction_attempt: 0
# timestamp: 2025-09-01T22:28:21.044
# num_equations: 22
# deriv_level: Dict(2 => 5, 1 => 2)

# Variables
varlist_str = """
_tpk5_
_tpk6_
_tpk7_
_tpk8_
_tpk9_
_tpk10_
_t499_x4_t_
_t499_x5_t_
_t499_x6_t_
_t499_x5ˍt_t_
_t499_x5ˍtt_t_
_t499_x5ˍttt_t_
_t499_x5ˍtttt_t_
_t499_x5ˍttttt_t_
_t499_x4ˍt_t_
_t499_x4ˍtt_t_
_t499_x6ˍt_t_
_t499_x6ˍtt_t_
_t499_x4ˍttt_t_
_t499_x6ˍttt_t_
_t499_x4ˍtttt_t_
_t499_x6ˍtttt_t_
"""
@variables _tpk5_ _tpk6_ _tpk7_ _tpk8_ _tpk9_ _tpk10_ _t499_x4_t_ _t499_x5_t_ _t499_x6_t_ _t499_x5ˍt_t_ _t499_x5ˍtt_t_ _t499_x5ˍttt_t_ _t499_x5ˍtttt_t_ _t499_x5ˍttttt_t_ _t499_x4ˍt_t_ _t499_x4ˍtt_t_ _t499_x6ˍt_t_ _t499_x6ˍtt_t_ _t499_x4ˍttt_t_ _t499_x6ˍttt_t_ _t499_x4ˍtttt_t_ _t499_x6ˍtttt_t_
varlist = [_tpk5__tpk6__tpk7__tpk8__tpk9__tpk10__t499_x4_t__t499_x5_t__t499_x6_t__t499_x5ˍt_t__t499_x5ˍtt_t__t499_x5ˍttt_t__t499_x5ˍtttt_t__t499_x5ˍttttt_t__t499_x4ˍt_t__t499_x4ˍtt_t__t499_x6ˍt_t__t499_x6ˍtt_t__t499_x4ˍttt_t__t499_x6ˍttt_t__t499_x4ˍtttt_t__t499_x6ˍtttt_t_]

# Polynomial System
poly_system = [
    -0.8057411083924787 + _t499_x5_t_,
    0.012833356507975893 + _t499_x5ˍt_t_,
    -0.002651583339133037 + _t499_x5ˍtt_t_,
    -0.05821955998735111 + _t499_x5ˍttt_t_,
    -0.09021281848450953 + _t499_x5ˍtttt_t_,
    -0.16545611796444548 + _t499_x5ˍttttt_t_,
    -0.2661307133780445 + _t499_x4_t_,
    0.15290453979649787 + _t499_x4ˍt_t_,
    -0.0629291373443147 + _t499_x4ˍtt_t_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4_t_*_t499_x5_t_*_tpk5_ + _t499_x4_t_*_t499_x5_t_*_tpk7_ - _t499_x4_t_*_t499_x6_t_*_tpk5_ - _t499_x4_t_*_tpk5_*_tpk8_ + _t499_x5_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + (_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - _t499_x4_t_*_t499_x5ˍt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍt_t_*_tpk5_*_tpk8_ + _t499_x5ˍt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 2(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - _t499_x4_t_*_t499_x5ˍtt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍtt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍtt_t_*_tpk5_ + 2_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 2_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 2_t499_x4ˍt_t_*_t499_x5ˍt_t_*_tpk5_ + 2_t499_x4ˍt_t_*_t499_x5ˍt_t_*_tpk7_ - 2_t499_x4ˍt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍtt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍtt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍtt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍtt_t_*_tpk5_*_tpk8_ + _t499_x5ˍtt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtttt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) + 3(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍttt_t_ + 3(_t499_x4_t_ + _tpk6_)*_t499_x5ˍtt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - _t499_x4_t_*_t499_x5ˍttt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍttt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍttt_t_*_tpk5_ + 3_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 3_t499_x4ˍt_t_*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) + 6_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ - 3_t499_x4ˍt_t_*_t499_x5ˍtt_t_*_tpk5_ + 3_t499_x4ˍt_t_*_t499_x5ˍtt_t_*_tpk7_ - 3_t499_x4ˍt_t_*_t499_x6ˍtt_t_*_tpk5_ + 3_t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 3_t499_x4ˍtt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 3_t499_x4ˍtt_t_*_t499_x5ˍt_t_*_tpk5_ + 3_t499_x4ˍtt_t_*_t499_x5ˍt_t_*_tpk7_ - 3_t499_x4ˍtt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍttt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍttt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍttt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍttt_t_*_tpk5_*_tpk8_ + _t499_x5ˍttt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttttt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍtttt_t_ + _t499_x6ˍtttt_t_) + 4(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtttt_t_ + 6(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x5ˍttt_t_ + 4(_t499_x4_t_ + _tpk6_)*_t499_x5ˍtt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) - _t499_x4_t_*_t499_x5ˍtttt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍtttt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍtttt_t_*_tpk5_ + 4_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtttt_t_ + 12_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍttt_t_ + 4_t499_x4ˍt_t_*_t499_x5ˍt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) + 12_t499_x4ˍt_t_*_t499_x5ˍtt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - 4_t499_x4ˍt_t_*_t499_x5ˍttt_t_*_tpk5_ + 4_t499_x4ˍt_t_*_t499_x5ˍttt_t_*_tpk7_ - 4_t499_x4ˍt_t_*_t499_x6ˍttt_t_*_tpk5_ + 6_t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 6_t499_x4ˍtt_t_*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) + 12_t499_x4ˍtt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ - 6_t499_x4ˍtt_t_*_t499_x5ˍtt_t_*_tpk5_ + 6_t499_x4ˍtt_t_*_t499_x5ˍtt_t_*_tpk7_ - 6_t499_x4ˍtt_t_*_t499_x6ˍtt_t_*_tpk5_ + 4_t499_x4ˍttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 4_t499_x4ˍttt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 4_t499_x4ˍttt_t_*_t499_x5ˍt_t_*_tpk5_ + 4_t499_x4ˍttt_t_*_t499_x5ˍt_t_*_tpk7_ - 4_t499_x4ˍttt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍtttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍtttt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍtttt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍtttt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍtttt_t_*_tpk5_*_tpk8_ + _t499_x5ˍtttt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍt_t_ + _t499_x4_t_*_tpk5_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍtt_t_ + _t499_x4ˍt_t_^2 + _t499_x4ˍt_t_*_tpk5_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5_t_*_tpk10_*_tpk7_ - _t499_x5_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5_t_*_t499_x6_t_*_tpk10_*_tpk9_ - (_t499_x6_t_^3)*_tpk9_ + (_t499_x6_t_^2)*_tpk10_*_tpk9_ - (_t499_x6_t_^2)*_tpk8_*_tpk9_ + _t499_x6_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + _t499_x5_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍt_t_*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍt_t_*_tpk8_*_tpk9_ + _t499_x6ˍt_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍttt_t_ + 3_t499_x4ˍt_t_*_t499_x4ˍtt_t_ + _t499_x4ˍtt_t_*_tpk5_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍttt_t_*_tpk10_ + 2(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍtt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍtt_t_*_tpk9_ - 2_t499_x5_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + _t499_x5_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 4_t499_x5ˍt_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + 2_t499_x5ˍt_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍtt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍtt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍtt_t_*_tpk9_ - 6_t499_x6_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍtt_t_*_tpk8_*_tpk9_ + 2(_t499_x6ˍt_t_^2)*_tpk10_*_tpk9_ - 2(_t499_x6ˍt_t_^2)*_tpk8_*_tpk9_ + _t499_x6ˍtt_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍtttt_t_ + 4_t499_x4ˍt_t_*_t499_x4ˍttt_t_ + 3(_t499_x4ˍtt_t_^2) + _t499_x4ˍttt_t_*_tpk5_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍtttt_t_*_tpk10_ + 3(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍttt_t_*_tpk10_ + 3(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍttt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍttt_t_*_tpk9_ - 6_t499_x5_t_*_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk9_ + _t499_x5_t_*_t499_x6ˍttt_t_*_tpk10_*_tpk9_ - 6_t499_x5ˍt_t_*_t499_x6_t_*_t499_x6ˍtt_t_*_tpk9_ - 6_t499_x5ˍt_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + 3_t499_x5ˍt_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 6_t499_x5ˍtt_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + 3_t499_x5ˍtt_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍttt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍttt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍttt_t_*_tpk9_ - 18_t499_x6_t_*_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍttt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍttt_t_*_tpk8_*_tpk9_ - 6(_t499_x6ˍt_t_^3)*_tpk9_ + 6_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 6_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk8_*_tpk9_ + _t499_x6ˍttt_t_*_tpk10_*_tpk8_*_tpk9_
]

