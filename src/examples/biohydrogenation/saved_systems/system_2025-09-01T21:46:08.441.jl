# Polynomial system saved on 2025-09-01T21:46:08.442
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:46:08.441
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t10_x_t_
_t10_xˍt_t_
"""
@variables _tpk1_ _t10_x_t_ _t10_xˍt_t_
varlist = [_tpk1__t10_x_t__t10_xˍt_t_]

# Polynomial System
poly_system = [
    -0.6831293051629526 + _t10_x_t_,
    -0.36820669548278134 + _t10_xˍt_t_,
    _t10_xˍt_t_ - _t10_x_t_*_tpk1_
]

