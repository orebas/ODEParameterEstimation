# Polynomial system saved on 2025-07-28T15:14:08.312
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:14:08.312
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x2ˍt_t_
_t501_x3ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x2ˍt_t_ _t501_x3ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t501_x1_t__t501_x2_t__t501_x3_t__t501_x2ˍt_t__t501_x3ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.180222492314384 + _t501_x2_t_^3,
    1.390433594370495 + 3(_t501_x2_t_^2)*_t501_x2ˍt_t_,
    -7.037471475601656 + _t501_x3_t_^3,
    2.9514922862949566 + 3(_t501_x3_t_^2)*_t501_x3ˍt_t_,
    -0.7121727087497973 + _t501_x1_t_^3,
    0.3853992846332763 + 3(_t501_x1_t_^2)*_t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x1_t_*_tpb_,
    _t501_x3ˍt_t_ + _t501_x1_t_*_tpc_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_
]

