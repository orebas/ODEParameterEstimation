# Polynomial system saved on 2025-07-28T15:29:58.800
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:58.800
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_X_t_
_t445_Y_t_
_t445_Xˍt_t_
_t501_X_t_
_t501_Y_t_
_t501_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t445_X_t_ _t445_Y_t_ _t445_Xˍt_t_ _t501_X_t_ _t501_Y_t_ _t501_Xˍt_t_
varlist = [_tpa__tpb__t445_X_t__t445_Y_t__t445_Xˍt_t__t501_X_t__t501_Y_t__t501_Xˍt_t_]

# Polynomial System
poly_system = [
    -3.7378658226969566 + _t445_Y_t_,
    -0.3755110040790374 + _t445_X_t_,
    -0.025026776613915842 + _t445_Xˍt_t_,
    -1.0 + _t445_Xˍt_t_ + _t445_X_t_*(1 + _tpb_) - (_t445_X_t_^2)*_t445_Y_t_*_tpa_,
    -4.7208914539594 + _t501_Y_t_,
    -0.6184299127072264 + _t501_X_t_,
    -0.33215413422699663 + _t501_Xˍt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_
]

