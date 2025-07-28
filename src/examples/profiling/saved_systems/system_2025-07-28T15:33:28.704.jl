# Polynomial system saved on 2025-07-28T15:33:28.705
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:28.704
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
    -0.6649648360056777 + _t9_x_t_,
    -0.35841604660708093 + _t9_xˍt_t_,
    _t9_xˍt_t_ - _t9_x_t_*_tpk1_
]

