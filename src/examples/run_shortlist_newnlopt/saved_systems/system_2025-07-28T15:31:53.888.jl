# Polynomial system saved on 2025-07-28T15:31:53.888
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:53.888
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
    -0.839895326564645 + _t445_x2_t_,
    -0.5647875127293315 + _t445_x2ˍt_t_,
    1.4211129775626068 + _t445_x1_t_,
    -0.8398952646953658 + _t445_x1ˍt_t_,
    _t445_x1_t_ + _t445_x2ˍt_t_ + (-1 + _t445_x1_t_^2)*_t445_x2_t_*_tpb_,
    _t445_x1ˍt_t_ - _t445_x2_t_*_tpa_
]

