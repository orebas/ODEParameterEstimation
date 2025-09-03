# Polynomial system saved on 2025-09-01T21:15:28.065
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:15:28.064
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t5_x_t_
_t5_xˍt_t_
"""
@variables _tpk1_ _t5_x_t_ _t5_xˍt_t_
varlist = [_tpk1__t5_x_t__t5_xˍt_t_]

# Polynomial System
poly_system = [
    -0.5970101233827627 + _t5_x_t_,
    -0.32178800361131654 + _t5_xˍt_t_,
    _t5_xˍt_t_ - _t5_x_t_*_tpk1_
]

