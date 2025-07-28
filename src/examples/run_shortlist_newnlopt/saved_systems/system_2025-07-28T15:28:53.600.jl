# Polynomial system saved on 2025-07-28T15:28:53.601
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:28:53.600
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_X_t_
_t278_Y_t_
_t278_Xˍt_t_
_t278_Xˍtt_t_
_t278_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t278_X_t_ _t278_Y_t_ _t278_Xˍt_t_ _t278_Xˍtt_t_ _t278_Yˍt_t_
varlist = [_tpa__tpb__t278_X_t__t278_Y_t__t278_Xˍt_t__t278_Xˍtt_t__t278_Yˍt_t_]

# Polynomial System
poly_system = [
    -4.0143775260717085 + _t278_Y_t_,
    -0.3930738256060896 + _t278_X_t_,
    -0.04795469494085327 + _t278_Xˍt_t_,
    -0.045893149721304496 + _t278_Xˍtt_t_,
    -1.0 + _t278_Xˍt_t_ + _t278_X_t_*(1 + _tpb_) - (_t278_X_t_^2)*_t278_Y_t_*_tpa_,
    _t278_Xˍtt_t_ - _t278_Xˍt_t_*(-1 - _tpb_) - (_t278_X_t_^2)*_t278_Yˍt_t_*_tpa_ - 2_t278_X_t_*_t278_Xˍt_t_*_t278_Y_t_*_tpa_,
    _t278_Yˍt_t_ - _t278_X_t_*_tpb_ + (_t278_X_t_^2)*_t278_Y_t_*_tpa_
]

