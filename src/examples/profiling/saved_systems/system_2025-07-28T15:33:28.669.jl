# Polynomial system saved on 2025-07-28T15:33:28.669
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:28.669
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t7_x_t_
_t7_xˍt_t_
"""
@variables _tpk1_ _t7_x_t_ _t7_xˍt_t_
varlist = [_tpk1__t7_x_t__t7_xˍt_t_]

# Polynomial System
poly_system = [
    -0.6300720393801589 + _t7_x_t_,
    -0.3396088292259778 + _t7_xˍt_t_,
    _t7_xˍt_t_ - _t7_x_t_*_tpk1_
]

