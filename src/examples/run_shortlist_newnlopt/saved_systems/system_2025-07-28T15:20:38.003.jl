# Polynomial system saved on 2025-07-28T15:20:38.015
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:38.003
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.4894780136489547 + _t501_x2_t_,
    0.36968241315427497 + _t501_x2ˍt_t_,
    0.4621029402866196 + _t501_x1_t_,
    -0.19579125674716097 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_
]

