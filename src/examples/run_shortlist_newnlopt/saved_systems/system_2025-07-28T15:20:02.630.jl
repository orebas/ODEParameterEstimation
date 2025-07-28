# Polynomial system saved on 2025-07-28T15:20:02.630
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:02.630
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
    -6.934693402873666 + _t501_x2_t_,
    -0.6065306597135329 + _t501_x2ˍt_t_,
    -1.2130613194252668 + _t501_x1_t_,
    0.12130613194270712 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x1_t_*(-0.174433183927437 - _tpc_),
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_
]

