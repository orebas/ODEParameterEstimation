# Polynomial system saved on 2025-07-28T15:33:29.577
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:29.577
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t14_x_t_
_t14_xˍt_t_
"""
@variables _tpk1_ _t14_x_t_ _t14_xˍt_t_
varlist = [_tpk1__t14_x_t__t14_xˍt_t_]

# Polynomial System
poly_system = [
    -0.7608864542682877 + _t14_x_t_,
    -0.4101173481439355 + _t14_xˍt_t_,
    _t14_xˍt_t_ - _t14_x_t_*_tpk1_
]

