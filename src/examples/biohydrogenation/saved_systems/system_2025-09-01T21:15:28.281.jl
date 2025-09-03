# Polynomial system saved on 2025-09-01T21:15:28.281
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:15:28.281
# num_equations: 3
# deriv_level: Dict(1 => 1)

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
    -0.7608857977764886 + _t14_x_t_,
    -0.41011789711698743 + _t14_xˍt_t_,
    _t14_xˍt_t_ - _t14_x_t_*_tpk1_
]

