# Polynomial system saved on 2025-07-28T15:18:34.847
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:34.847
# num_equations: 10

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
    3.794365340027345 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    3.50760825248589 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.6188192835141678 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_,
    3.794365340027345 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    3.50760825248589 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.6188192835141678 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_
]

