# Polynomial system saved on 2025-07-28T15:29:25.061
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:29:25.060
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_X_t_
_t390_Y_t_
_t390_Xˍt_t_
_t390_Xˍtt_t_
_t390_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t390_X_t_ _t390_Y_t_ _t390_Xˍt_t_ _t390_Xˍtt_t_ _t390_Yˍt_t_
varlist = [_tpa__tpb__t390_X_t__t390_Y_t__t390_Xˍt_t__t390_Xˍtt_t__t390_Yˍt_t_]

# Polynomial System
poly_system = [
    -2.0656605020780887 + _t390_Y_t_,
    -0.9037198076191734 + _t390_X_t_,
    0.9278346938991897 + _t390_Xˍt_t_,
    -1.0836197562662662 + _t390_Xˍtt_t_,
    -1.0 + _t390_Xˍt_t_ + _t390_X_t_*(1 + _tpb_) - (_t390_X_t_^2)*_t390_Y_t_*_tpa_,
    _t390_Xˍtt_t_ - _t390_Xˍt_t_*(-1 - _tpb_) - (_t390_X_t_^2)*_t390_Yˍt_t_*_tpa_ - 2_t390_X_t_*_t390_Xˍt_t_*_t390_Y_t_*_tpa_,
    _t390_Yˍt_t_ - _t390_X_t_*_tpb_ + (_t390_X_t_^2)*_t390_Y_t_*_tpa_
]

