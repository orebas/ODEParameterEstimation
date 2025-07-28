# Polynomial system saved on 2025-07-28T15:20:01.655
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:01.655
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
    -6.93469339784891 + _t501_x2_t_,
    -0.6065302893387826 + _t501_x2ˍt_t_,
    -1.2130613194065194 + _t501_x1_t_,
    0.12130612350127595 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ - _t501_x1_t_*(0.36095026990482326 + _tpc_),
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_
]

