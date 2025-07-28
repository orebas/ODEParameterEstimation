# Polynomial system saved on 2025-07-28T15:20:01.991
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:01.991
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpc__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.529537658105959 + _t167_x2_t_,
    -0.8470462341894593 + _t167_x2ˍt_t_,
    -1.6940924683788081 + _t167_x1_t_,
    0.1694092468378921 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ - _t167_x1_t_*(0.2227389902951572 + _tpc_),
    _t167_x1ˍt_t_ + _t167_x1_t_*_tpa_
]

