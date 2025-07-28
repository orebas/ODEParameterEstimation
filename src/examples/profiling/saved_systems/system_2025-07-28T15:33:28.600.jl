# Polynomial system saved on 2025-07-28T15:33:28.600
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:28.600
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t2_x_t_
_t2_xˍt_t_
"""
@variables _tpk1_ _t2_x_t_ _t2_xˍt_t_
varlist = [_tpk1__t2_x_t__t2_xˍt_t_]

# Polynomial System
poly_system = [
    -0.5506416095124411 + _t2_x_t_,
    -0.2967958275272178 + _t2_xˍt_t_,
    _t2_xˍt_t_ - _t2_x_t_*_tpk1_
]

