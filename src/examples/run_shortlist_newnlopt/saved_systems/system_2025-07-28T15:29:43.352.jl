# Polynomial system saved on 2025-07-28T15:29:43.352
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:43.352
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_X_t_
_t334_Y_t_
_t334_Xˍt_t_
_t501_X_t_
_t501_Y_t_
_t501_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t334_X_t_ _t334_Y_t_ _t334_Xˍt_t_ _t501_X_t_ _t501_Y_t_ _t501_Xˍt_t_
varlist = [_tpa__tpb__t334_X_t__t334_Y_t__t334_Xˍt_t__t501_X_t__t501_Y_t__t501_Xˍt_t_]

# Polynomial System
poly_system = [
    -4.554684973200771 + _t334_Y_t_,
    -0.9110165541544806 + _t334_X_t_,
    -1.1361470088504169 + _t334_Xˍt_t_,
    -1.0 + _t334_Xˍt_t_ + _t334_X_t_*(1 + _tpb_) - (_t334_X_t_^2)*_t334_Y_t_*_tpa_,
    -4.720891458557427 + _t501_Y_t_,
    -0.6184299091787929 + _t501_X_t_,
    -0.33215216609004483 + _t501_Xˍt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_
]

