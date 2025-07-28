# Polynomial system saved on 2025-07-28T15:29:02.750
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:29:02.750
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_X_t_
_t56_Y_t_
_t56_Xˍt_t_
_t56_Xˍtt_t_
_t56_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t56_X_t_ _t56_Y_t_ _t56_Xˍt_t_ _t56_Xˍtt_t_ _t56_Yˍt_t_
varlist = [_tpa__tpb__t56_X_t__t56_Y_t__t56_Xˍt_t__t56_Xˍtt_t__t56_Yˍt_t_]

# Polynomial System
poly_system = [
    -2.9690622245678147 + _t56_Y_t_,
    -0.32090467333690975 + _t56_X_t_,
    -0.02213476854447738 + _t56_Xˍt_t_,
    -0.02129399151467748 + _t56_Xˍtt_t_,
    -1.0 + _t56_Xˍt_t_ + _t56_X_t_*(1 + _tpb_) - (_t56_X_t_^2)*_t56_Y_t_*_tpa_,
    _t56_Xˍtt_t_ - _t56_Xˍt_t_*(-1 - _tpb_) - (_t56_X_t_^2)*_t56_Yˍt_t_*_tpa_ - 2_t56_X_t_*_t56_Xˍt_t_*_t56_Y_t_*_tpa_,
    _t56_Yˍt_t_ - _t56_X_t_*_tpb_ + (_t56_X_t_^2)*_t56_Y_t_*_tpa_
]

