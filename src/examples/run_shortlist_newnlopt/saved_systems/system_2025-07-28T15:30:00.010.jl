# Polynomial system saved on 2025-07-28T15:30:00.011
using Symbolics
using StaticArrays

# Metadata
# num_variables: 5
# timestamp: 2025-07-28T15:30:00.010
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_X_t_
_t501_Y_t_
_t501_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t501_X_t_ _t501_Y_t_ _t501_Xˍt_t_
varlist = [_tpa__tpb__t501_X_t__t501_Y_t__t501_Xˍt_t_]

# Polynomial System
poly_system = [
    -4.72089144694713 + _t501_Y_t_,
    -0.6184299160446527 + _t501_X_t_,
    -0.3321545655562696 + _t501_Xˍt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_,
    -4.72089144694713 + _t501_Y_t_,
    -0.6184299160446527 + _t501_X_t_,
    -0.3321545655562696 + _t501_Xˍt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_
]

