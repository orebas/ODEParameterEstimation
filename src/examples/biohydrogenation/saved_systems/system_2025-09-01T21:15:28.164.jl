# Polynomial system saved on 2025-09-01T21:15:28.164
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:15:28.164
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t9_x_t_
_t9_xˍt_t_
"""
@variables _tpk1_ _t9_x_t_ _t9_xˍt_t_
varlist = [_tpk1__t9_x_t__t9_xˍt_t_]

# Polynomial System
poly_system = [
    -0.6649647768866099 + _t9_x_t_,
    -0.3584161806313201 + _t9_xˍt_t_,
    _t9_xˍt_t_ - _t9_x_t_*_tpk1_
]

