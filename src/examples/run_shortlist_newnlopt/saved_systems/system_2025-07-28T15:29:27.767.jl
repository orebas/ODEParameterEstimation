# Polynomial system saved on 2025-07-28T15:29:27.767
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:29:27.767
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_X_t_
_t445_Y_t_
_t445_Xˍt_t_
_t445_Xˍtt_t_
_t445_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t445_X_t_ _t445_Y_t_ _t445_Xˍt_t_ _t445_Xˍtt_t_ _t445_Yˍt_t_
varlist = [_tpa__tpb__t445_X_t__t445_Y_t__t445_Xˍt_t__t445_Xˍtt_t__t445_Yˍt_t_]

# Polynomial System
poly_system = [
    -3.7378658186413265 + _t445_Y_t_,
    -0.37551100086525996 + _t445_X_t_,
    -0.025026892824268954 + _t445_Xˍt_t_,
    -0.05467766897143278 + _t445_Xˍtt_t_,
    -1.0 + _t445_Xˍt_t_ + _t445_X_t_*(1 + _tpb_) - (_t445_X_t_^2)*_t445_Y_t_*_tpa_,
    _t445_Xˍtt_t_ - _t445_Xˍt_t_*(-1 - _tpb_) - (_t445_X_t_^2)*_t445_Yˍt_t_*_tpa_ - 2_t445_X_t_*_t445_Xˍt_t_*_t445_Y_t_*_tpa_,
    _t445_Yˍt_t_ - _t445_X_t_*_tpb_ + (_t445_X_t_^2)*_t445_Y_t_*_tpa_
]

