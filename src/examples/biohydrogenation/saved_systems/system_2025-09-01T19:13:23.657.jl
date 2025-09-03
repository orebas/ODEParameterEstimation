# Polynomial system saved on 2025-09-01T19:13:23.657
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T19:13:23.657
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t16_x_t_
_t16_xˍt_t_
"""
@variables _tpk1_ _t16_x_t_ _t16_xˍt_t_
varlist = [_tpk1__t16_x_t__t16_xˍt_t_]

# Polynomial System
poly_system = [
    -0.8030236712680235 + _t16_x_t_,
    -0.4328289968841518 + _t16_xˍt_t_,
    _t16_xˍt_t_ - _t16_x_t_*_tpk1_
]

