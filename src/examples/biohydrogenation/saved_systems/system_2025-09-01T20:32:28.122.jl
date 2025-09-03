# Polynomial system saved on 2025-09-01T20:32:28.123
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T20:32:28.122
# num_equations: 3
# deriv_level: Dict(1 => 1)

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
    -0.7209603143086903 + _t12_x_t_,
    -0.38859728838076485 + _t12_xˍt_t_,
    _t12_xˍt_t_ - _t12_x_t_*_tpk1_
]

