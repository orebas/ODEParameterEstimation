# Polynomial system saved on 2025-07-28T15:19:48.004
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:48.003
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpc__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.041658656300144 + _t111_x2_t_,
    -0.8958342014583264 + _t111_x2ˍt_t_,
    -1.7916682684644305 + _t111_x1_t_,
    0.17916684270385672 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*(0.5956968294621431 + _tpc_),
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_
]

