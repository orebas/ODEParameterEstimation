# Polynomial system saved on 2025-07-28T15:29:55.736
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:55.736
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_X_t_
_t390_Y_t_
_t390_Xˍt_t_
_t501_X_t_
_t501_Y_t_
_t501_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t390_X_t_ _t390_Y_t_ _t390_Xˍt_t_ _t501_X_t_ _t501_Y_t_ _t501_Xˍt_t_
varlist = [_tpa__tpb__t390_X_t__t390_Y_t__t390_Xˍt_t__t501_X_t__t501_Y_t__t501_Xˍt_t_]

# Polynomial System
poly_system = [
    -2.0656604384278294 + _t390_Y_t_,
    -0.9037197708082119 + _t390_X_t_,
    0.9278370381663895 + _t390_Xˍt_t_,
    -1.0 + _t390_Xˍt_t_ + _t390_X_t_*(1 + _tpb_) - (_t390_X_t_^2)*_t390_Y_t_*_tpa_,
    -4.720891467776454 + _t501_Y_t_,
    -0.6184299080016666 + _t501_X_t_,
    -0.33216275321634886 + _t501_Xˍt_t_,
    -1.0 + _t501_Xˍt_t_ + _t501_X_t_*(1 + _tpb_) - (_t501_X_t_^2)*_t501_Y_t_*_tpa_
]

