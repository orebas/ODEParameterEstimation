# Polynomial system saved on 2025-09-01T20:32:28.284
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T20:32:28.284
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t19_x_t_
_t19_xˍt_t_
"""
@variables _tpk1_ _t19_x_t_ _t19_xˍt_t_
varlist = [_tpk1__t19_x_t__t19_xˍt_t_]

# Polynomial System
poly_system = [
    -0.8706454132557025 + _t19_x_t_,
    -0.4692792642197178 + _t19_xˍt_t_,
    _t19_xˍt_t_ - _t19_x_t_*_tpk1_
]

