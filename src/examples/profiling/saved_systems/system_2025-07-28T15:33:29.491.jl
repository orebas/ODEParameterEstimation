# Polynomial system saved on 2025-07-28T15:33:29.492
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:29.492
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t9_x_t_
_t9_xˍt_t_
"""
@variables _tpk1_ _t9_x_t_ _t9_xˍt_t_
varlist = [_tpk1__t9_x_t__t9_xˍt_t_]

# Polynomial System
poly_system = [
    -0.6649645703552857 + _t9_x_t_,
    -0.3584166136241498 + _t9_xˍt_t_,
    _t9_xˍt_t_ - _t9_x_t_*_tpk1_
]

