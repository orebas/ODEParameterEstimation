# Polynomial system saved on 2025-09-01T19:13:23.401
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T19:13:23.401
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
    -0.597010019814397 + _t5_x_t_,
    -0.3217871133250392 + _t5_xˍt_t_,
    _t5_xˍt_t_ - _t5_x_t_*_tpk1_
]

