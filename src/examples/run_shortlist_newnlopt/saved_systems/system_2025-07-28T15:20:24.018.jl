# Polynomial system saved on 2025-07-28T15:20:24.018
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:24.018
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpc__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.934693406133093 + _t501_x2_t_,
    -0.606530631534326 + _t501_x2ˍt_t_,
    -1.213061324170307 + _t501_x1_t_,
    0.12130597197169422 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x1_t_*(-0.3077646199042302 - _tpc_),
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_
]

