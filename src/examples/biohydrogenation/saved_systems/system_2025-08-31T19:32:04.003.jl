# Polynomial system saved on 2025-08-31T19:32:04.003
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-08-31T19:32:04.003
# num_equations: 3
# deriv_level: Dict(1 => 1)

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

