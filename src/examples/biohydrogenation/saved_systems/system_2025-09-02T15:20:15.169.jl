# Polynomial system saved on 2025-09-02T15:20:15.318
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-02T15:20:15.174
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
    -0.6831289506367254 + _t10_x_t_,
    -0.3682077505834571 + _t10_xˍt_t_,
    _t10_xˍt_t_ - _t10_x_t_*_tpk1_
]

