# Polynomial system saved on 2025-07-28T15:33:29.538
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:29.538
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t12_x_t_
_t12_xˍt_t_
"""
@variables _tpk1_ _t12_x_t_ _t12_xˍt_t_
varlist = [_tpk1__t12_x_t__t12_xˍt_t_]

# Polynomial System
poly_system = [
    -0.7209604162620681 + _t12_x_t_,
    -0.38859723977952887 + _t12_xˍt_t_,
    _t12_xˍt_t_ - _t12_x_t_*_tpk1_
]

