# Polynomial system saved on 2025-07-28T15:29:23.776
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:29:23.776
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_X_t_
_t334_Y_t_
_t334_Xˍt_t_
_t334_Xˍtt_t_
_t334_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t334_X_t_ _t334_Y_t_ _t334_Xˍt_t_ _t334_Xˍtt_t_ _t334_Yˍt_t_
varlist = [_tpa__tpb__t334_X_t__t334_Y_t__t334_Xˍt_t__t334_Xˍtt_t__t334_Yˍt_t_]

# Polynomial System
poly_system = [
    -4.554682435575093 + _t334_Y_t_,
    -0.911019363067546 + _t334_X_t_,
    -1.1361098380127626 + _t334_Xˍt_t_,
    -4.014846357536271 + _t334_Xˍtt_t_,
    -1.0 + _t334_Xˍt_t_ + _t334_X_t_*(1 + _tpb_) - (_t334_X_t_^2)*_t334_Y_t_*_tpa_,
    _t334_Xˍtt_t_ - _t334_Xˍt_t_*(-1 - _tpb_) - (_t334_X_t_^2)*_t334_Yˍt_t_*_tpa_ - 2_t334_X_t_*_t334_Xˍt_t_*_t334_Y_t_*_tpa_,
    _t334_Yˍt_t_ - _t334_X_t_*_tpb_ + (_t334_X_t_^2)*_t334_Y_t_*_tpa_
]

