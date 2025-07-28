# Polynomial system saved on 2025-07-28T15:29:00.095
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:29:00.095
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_X_t_
_t501_Y_t_
_t501_Xˍt_t_
_t501_Xˍtt_t_
_t501_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t501_X_t_ _t501_Y_t_ _t501_Xˍt_t_ _t501_Xˍtt_t_ _t501_Yˍt_t_
varlist = [_tpa__tpb__t501_X_t__t501_Y_t__t501_Xˍt_t__t501_Xˍtt_t__t501_Yˍt_t_]

# Polynomial System
poly_system = [
    -4.720891486212738 + _t501_Y_t_,
    -0.6184299085324968 + _t501_X_t_,
    -0.3321575709198679 + _t501_Xˍt_t_,
    -0.6734700690242865 + _t501_Xˍtt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_,
    _t501_Xˍtt_t_ - _t501_Xˍt_t_*(-1 - _tpb_) - (_t501_X_t_^2)*_t501_Yˍt_t_*_tpa_ - 2_t501_X_t_*_t501_Xˍt_t_*_t501_Y_t_*_tpa_,
    _t501_Yˍt_t_ - _t501_X_t_*_tpb_ + (_t501_X_t_^2)*_t501_Y_t_*_tpa_
]

