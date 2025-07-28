# Polynomial system saved on 2025-07-28T15:44:45.458
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:45.458
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.26591693986157283 + _t179_x2_t_,
    0.43669860487800505 + _t179_x2ˍt_t_,
    0.5458732247968481 + _t179_x1_t_,
    -0.10636672631794031 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

