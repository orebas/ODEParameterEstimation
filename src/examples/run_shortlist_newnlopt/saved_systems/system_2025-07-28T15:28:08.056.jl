# Polynomial system saved on 2025-07-28T15:28:08.056
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:28:08.056
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
    -2.9690622302712355 + _t56_Y_t_,
    -0.3209046743586258 + _t56_X_t_,
    -0.022134351673463802 + _t56_Xˍt_t_,
    -0.021290046798365127 + _t56_Xˍtt_t_,
    -1.0 + _t56_Xˍt_t_ + _t56_X_t_*(1 + _tpb_) - (_t56_X_t_^2)*_t56_Y_t_*_tpa_,
    _t56_Xˍtt_t_ - _t56_Xˍt_t_*(-1 - _tpb_) - (_t56_X_t_^2)*_t56_Yˍt_t_*_tpa_ - 2_t56_X_t_*_t56_Xˍt_t_*_t56_Y_t_*_tpa_,
    _t56_Yˍt_t_ - _t56_X_t_*_tpb_ + (_t56_X_t_^2)*_t56_Y_t_*_tpa_
]

