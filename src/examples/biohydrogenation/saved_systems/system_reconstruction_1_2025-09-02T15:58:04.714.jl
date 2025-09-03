# Polynomial system saved on 2025-09-02T15:58:04.786
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# reconstruction_attempt: 1
# timestamp: 2025-09-02T15:58:04.714
# num_equations: 23
# deriv_level: Dict(2 => 5, 1 => 3)
# description: Reconstructed system after incrementing derivatives

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
_t499_x4ˍttt_t_
_t499_x6ˍt_t_
_t499_x6ˍtt_t_
_t499_x6ˍttt_t_
_t499_x4ˍtttt_t_
_t499_x6ˍtttt_t_
"""
@variables _tpk5_ _tpk6_ _tpk7_ _tpk8_ _tpk9_ _tpk10_ _t499_x4_t_ _t499_x5_t_ _t499_x6_t_ _t499_x5ˍt_t_ _t499_x5ˍtt_t_ _t499_x5ˍttt_t_ _t499_x5ˍtttt_t_ _t499_x5ˍttttt_t_ _t499_x4ˍt_t_ _t499_x4ˍtt_t_ _t499_x4ˍttt_t_ _t499_x6ˍt_t_ _t499_x6ˍtt_t_ _t499_x6ˍttt_t_ _t499_x4ˍtttt_t_ _t499_x6ˍtttt_t_
varlist = [_tpk5__tpk6__tpk7__tpk8__tpk9__tpk10__t499_x4_t__t499_x5_t__t499_x6_t__t499_x5ˍt_t__t499_x5ˍtt_t__t499_x5ˍttt_t__t499_x5ˍtttt_t__t499_x5ˍttttt_t__t499_x4ˍt_t__t499_x4ˍtt_t__t499_x4ˍttt_t__t499_x6ˍt_t__t499_x6ˍtt_t__t499_x6ˍttt_t__t499_x4ˍtttt_t__t499_x6ˍtttt_t_]

# Polynomial System
poly_system = [
    -0.8057411090288927 + _t499_x5_t_,
    0.012833353715989022 + _t499_x5ˍt_t_,
    -0.0026515755094745465 + _t499_x5ˍtt_t_,
    -0.05821790813099706 + _t499_x5ˍttt_t_,
    -0.09021517380060275 + _t499_x5ˍtttt_t_,
    -0.16654040222935554 + _t499_x5ˍttttt_t_,
    -0.26613071189600346 + _t499_x4_t_,
    0.15290454063115086 + _t499_x4ˍt_t_,
    -0.06292913826709874 + _t499_x4ˍtt_t_,
    0.005388191553780484 + _t499_x4ˍttt_t_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4_t_*_t499_x5_t_*_tpk5_ + _t499_x4_t_*_t499_x5_t_*_tpk7_ - _t499_x4_t_*_t499_x6_t_*_tpk5_ - _t499_x4_t_*_tpk5_*_tpk8_ + _t499_x5_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + (_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - _t499_x4_t_*_t499_x5ˍt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍt_t_*_tpk5_*_tpk8_ + _t499_x5ˍt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 2(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - _t499_x4_t_*_t499_x5ˍtt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍtt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍtt_t_*_tpk5_ + 2_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 2_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 2_t499_x4ˍt_t_*_t499_x5ˍt_t_*_tpk5_ + 2_t499_x4ˍt_t_*_t499_x5ˍt_t_*_tpk7_ - 2_t499_x4ˍt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍtt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍtt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍtt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍtt_t_*_tpk5_*_tpk8_ + _t499_x5ˍtt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtttt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) + 3(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍttt_t_ + 3(_t499_x4_t_ + _tpk6_)*_t499_x5ˍtt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - _t499_x4_t_*_t499_x5ˍttt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍttt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍttt_t_*_tpk5_ + 3_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 3_t499_x4ˍt_t_*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) + 6_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ - 3_t499_x4ˍt_t_*_t499_x5ˍtt_t_*_tpk5_ + 3_t499_x4ˍt_t_*_t499_x5ˍtt_t_*_tpk7_ - 3_t499_x4ˍt_t_*_t499_x6ˍtt_t_*_tpk5_ + 3_t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 3_t499_x4ˍtt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 3_t499_x4ˍtt_t_*_t499_x5ˍt_t_*_tpk5_ + 3_t499_x4ˍtt_t_*_t499_x5ˍt_t_*_tpk7_ - 3_t499_x4ˍtt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍttt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍttt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍttt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍttt_t_*_tpk5_*_tpk8_ + _t499_x5ˍttt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttttt_t_ + (_t499_x4_t_ + _tpk6_)*_t499_x5ˍt_t_*(_t499_x5ˍtttt_t_ + _t499_x6ˍtttt_t_) + 4(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtttt_t_ + 6(_t499_x4_t_ + _tpk6_)*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x5ˍttt_t_ + 4(_t499_x4_t_ + _tpk6_)*_t499_x5ˍtt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) - _t499_x4_t_*_t499_x5ˍtttt_t_*_tpk5_ + _t499_x4_t_*_t499_x5ˍtttt_t_*_tpk7_ - _t499_x4_t_*_t499_x6ˍtttt_t_*_tpk5_ + 4_t499_x4ˍt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtttt_t_ + 12_t499_x4ˍt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍttt_t_ + 4_t499_x4ˍt_t_*_t499_x5ˍt_t_*(_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_) + 12_t499_x4ˍt_t_*_t499_x5ˍtt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) - 4_t499_x4ˍt_t_*_t499_x5ˍttt_t_*_tpk5_ + 4_t499_x4ˍt_t_*_t499_x5ˍttt_t_*_tpk7_ - 4_t499_x4ˍt_t_*_t499_x6ˍttt_t_*_tpk5_ + 6_t499_x4ˍtt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍttt_t_ + 6_t499_x4ˍtt_t_*_t499_x5ˍt_t_*(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_) + 12_t499_x4ˍtt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍtt_t_ - 6_t499_x4ˍtt_t_*_t499_x5ˍtt_t_*_tpk5_ + 6_t499_x4ˍtt_t_*_t499_x5ˍtt_t_*_tpk7_ - 6_t499_x4ˍtt_t_*_t499_x6ˍtt_t_*_tpk5_ + 4_t499_x4ˍttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍtt_t_ + 4_t499_x4ˍttt_t_*(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x5ˍt_t_ - 4_t499_x4ˍttt_t_*_t499_x5ˍt_t_*_tpk5_ + 4_t499_x4ˍttt_t_*_t499_x5ˍt_t_*_tpk7_ - 4_t499_x4ˍttt_t_*_t499_x6ˍt_t_*_tpk5_ + _t499_x4ˍtttt_t_*(_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x5ˍt_t_ - _t499_x4ˍtttt_t_*_t499_x5_t_*_tpk5_ + _t499_x4ˍtttt_t_*_t499_x5_t_*_tpk7_ - _t499_x4ˍtttt_t_*_t499_x6_t_*_tpk5_ - _t499_x4ˍtttt_t_*_tpk5_*_tpk8_ + _t499_x5ˍtttt_t_*_tpk6_*_tpk7_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍt_t_ + _t499_x4_t_*_tpk5_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍtt_t_ + _t499_x4ˍt_t_^2 + _t499_x4ˍt_t_*_tpk5_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍttt_t_ + 3_t499_x4ˍt_t_*_t499_x4ˍtt_t_ + _t499_x4ˍtt_t_*_tpk5_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5_t_*_tpk10_*_tpk7_ - _t499_x5_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5_t_*_t499_x6_t_*_tpk10_*_tpk9_ - (_t499_x6_t_^3)*_tpk9_ + (_t499_x6_t_^2)*_tpk10_*_tpk9_ - (_t499_x6_t_^2)*_tpk8_*_tpk9_ + _t499_x6_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + _t499_x5_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍt_t_*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍt_t_*_tpk8_*_tpk9_ + _t499_x6ˍt_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍttt_t_*_tpk10_ + 2(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍtt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍtt_t_*_tpk9_ - 2_t499_x5_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + _t499_x5_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 4_t499_x5ˍt_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + 2_t499_x5ˍt_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍtt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍtt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍtt_t_*_tpk9_ - 6_t499_x6_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍtt_t_*_tpk8_*_tpk9_ + 2(_t499_x6ˍt_t_^2)*_tpk10_*_tpk9_ - 2(_t499_x6ˍt_t_^2)*_tpk8_*_tpk9_ + _t499_x6ˍtt_t_*_tpk10_*_tpk8_*_tpk9_,
    (_t499_x4_t_ + _tpk6_)*_t499_x4ˍtttt_t_ + 4_t499_x4ˍt_t_*_t499_x4ˍttt_t_ + 3(_t499_x4ˍtt_t_^2) + _t499_x4ˍttt_t_*_tpk5_,
    (_t499_x5_t_ + _t499_x6_t_ + _tpk8_)*_t499_x6ˍtttt_t_*_tpk10_ + 3(_t499_x5ˍt_t_ + _t499_x6ˍt_t_)*_t499_x6ˍttt_t_*_tpk10_ + 3(_t499_x5ˍtt_t_ + _t499_x6ˍtt_t_)*_t499_x6ˍtt_t_*_tpk10_ + (_t499_x5ˍttt_t_ + _t499_x6ˍttt_t_)*_t499_x6ˍt_t_*_tpk10_ - _t499_x5ˍttt_t_*_tpk10_*_tpk7_ - 2_t499_x5_t_*_t499_x6_t_*_t499_x6ˍttt_t_*_tpk9_ - 6_t499_x5_t_*_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk9_ + _t499_x5_t_*_t499_x6ˍttt_t_*_tpk10_*_tpk9_ - 6_t499_x5ˍt_t_*_t499_x6_t_*_t499_x6ˍtt_t_*_tpk9_ - 6_t499_x5ˍt_t_*(_t499_x6ˍt_t_^2)*_tpk9_ + 3_t499_x5ˍt_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 6_t499_x5ˍtt_t_*_t499_x6_t_*_t499_x6ˍt_t_*_tpk9_ + 3_t499_x5ˍtt_t_*_t499_x6ˍt_t_*_tpk10_*_tpk9_ - _t499_x5ˍttt_t_*(_t499_x6_t_^2)*_tpk9_ + _t499_x5ˍttt_t_*_t499_x6_t_*_tpk10_*_tpk9_ - 3(_t499_x6_t_^2)*_t499_x6ˍttt_t_*_tpk9_ - 18_t499_x6_t_*_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk9_ + 2_t499_x6_t_*_t499_x6ˍttt_t_*_tpk10_*_tpk9_ - 2_t499_x6_t_*_t499_x6ˍttt_t_*_tpk8_*_tpk9_ - 6(_t499_x6ˍt_t_^3)*_tpk9_ + 6_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk10_*_tpk9_ - 6_t499_x6ˍt_t_*_t499_x6ˍtt_t_*_tpk8_*_tpk9_ + _t499_x6ˍttt_t_*_tpk10_*_tpk8_*_tpk9_
]

