# Polynomial system saved on 2025-09-01T19:13:23.450
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T19:13:23.450
# num_equations: 3
# deriv_level: Dict(1 => 1)

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
    -0.6300711172883785 + _t7_x_t_,
    -0.33960788802316827 + _t7_xˍt_t_,
    _t7_xˍt_t_ - _t7_x_t_*_tpk1_
]

