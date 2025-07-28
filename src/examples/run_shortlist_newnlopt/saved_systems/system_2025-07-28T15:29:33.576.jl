# Polynomial system saved on 2025-07-28T15:29:33.577
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:33.576
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_X_t_
_t111_Y_t_
_t111_Xˍt_t_
_t278_X_t_
_t278_Y_t_
_t278_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t111_X_t_ _t111_Y_t_ _t111_Xˍt_t_ _t278_X_t_ _t278_Y_t_ _t278_Xˍt_t_
varlist = [_tpa__tpb__t111_X_t__t111_Y_t__t111_Xˍt_t__t278_X_t__t278_Y_t__t278_Xˍt_t_]

# Polynomial System
poly_system = [
    -4.281522008229032 + _t111_Y_t_,
    -0.41681675014647185 + _t111_X_t_,
    -0.07658796100525024 + _t111_Xˍt_t_,
    -1.0 + _t111_Xˍt_t_ + _t111_X_t_*(1 + _tpb_) - (_t111_X_t_^2)*_t111_Y_t_*_tpa_,
    -4.014377528011007 + _t278_Y_t_,
    -0.3930738326875422 + _t278_X_t_,
    -0.047954093281744097 + _t278_Xˍt_t_,
    -1.0 + _t278_Xˍt_t_ + _t278_X_t_*(1 + _tpb_) - (_t278_X_t_^2)*_t278_Y_t_*_tpa_
]

