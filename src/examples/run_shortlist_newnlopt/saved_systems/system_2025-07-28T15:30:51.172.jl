# Polynomial system saved on 2025-07-28T15:30:51.173
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:51.172
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.8398953075678058 + _t445_x2_t_,
    -0.5647873726134238 + _t445_x2ˍt_t_,
    1.421112950313356 + _t445_x1_t_,
    -0.8398956464479885 + _t445_x1ˍt_t_,
    _t445_x1_t_ + _t445_x2ˍt_t_ + (-1 + _t445_x1_t_^2)*_t445_x2_t_*_tpb_,
    _t445_x1ˍt_t_ - _t445_x2_t_*_tpa_
]

