# Polynomial system saved on 2025-07-28T15:28:32.865
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:28:32.865
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_X_t_
_t111_Y_t_
_t111_Xˍt_t_
_t111_Xˍtt_t_
_t111_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t111_X_t_ _t111_Y_t_ _t111_Xˍt_t_ _t111_Xˍtt_t_ _t111_Yˍt_t_
varlist = [_tpa__tpb__t111_X_t__t111_Y_t__t111_Xˍt_t__t111_Xˍtt_t__t111_Yˍt_t_]

# Polynomial System
poly_system = [
    -4.28152199755357 + _t111_Y_t_,
    -0.41681675707671423 + _t111_X_t_,
    -0.07658776198627748 + _t111_Xˍt_t_,
    -0.055000061074399455 + _t111_Xˍtt_t_,
    -1.0 + _t111_Xˍt_t_ + _t111_X_t_*(1 + _tpb_) - (_t111_X_t_^2)*_t111_Y_t_*_tpa_,
    _t111_Xˍtt_t_ - _t111_Xˍt_t_*(-1 - _tpb_) - (_t111_X_t_^2)*_t111_Yˍt_t_*_tpa_ - 2_t111_X_t_*_t111_Xˍt_t_*_t111_Y_t_*_tpa_,
    _t111_Yˍt_t_ - _t111_X_t_*_tpb_ + (_t111_X_t_^2)*_t111_Y_t_*_tpa_
]

