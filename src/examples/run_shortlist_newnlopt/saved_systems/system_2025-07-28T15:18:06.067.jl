# Polynomial system saved on 2025-07-28T15:18:06.068
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:06.067
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_x1_t_
_t501_x2_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t501_x1_t_ _t501_x2_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_
varlist = [_tpa__tpb__t501_x1_t__t501_x2_t__t501_x1ˍt_t__t501_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.7943653506011743 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    -2.037863465491064 + 3.0_t501_x1ˍt_t_ - 0.25_t501_x2ˍt_t_,
    3.507608271230619 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.6188211375494185 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_
]

