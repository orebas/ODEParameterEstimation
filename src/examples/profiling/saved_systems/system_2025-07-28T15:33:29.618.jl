# Polynomial system saved on 2025-07-28T15:33:29.619
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:29.618
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t16_x_t_
_t16_xˍt_t_
"""
@variables _tpk1_ _t16_x_t_ _t16_xˍt_t_
varlist = [_tpk1__t16_x_t__t16_xˍt_t_]

# Polynomial System
poly_system = [
    -0.8030228163489048 + _t16_x_t_,
    -0.4328293457084773 + _t16_xˍt_t_,
    _t16_xˍt_t_ - _t16_x_t_*_tpk1_
]

