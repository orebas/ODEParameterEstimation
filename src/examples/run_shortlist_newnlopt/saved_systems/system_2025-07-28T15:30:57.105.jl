# Polynomial system saved on 2025-07-28T15:30:57.105
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:57.105
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
    -1.3070889418151364 + _t501_x2_t_,
    -1.228293519670743 + _t501_x2ˍt_t_,
    0.8370774719792451 + _t501_x1_t_,
    -1.3070860737174255 + _t501_x1ˍt_t_,
    _t501_x1_t_ + _t501_x2ˍt_t_ + (-1 + _t501_x1_t_^2)*_t501_x2_t_*_tpb_,
    _t501_x1ˍt_t_ - _t501_x2_t_*_tpa_
]

