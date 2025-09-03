# Polynomial system saved on 2025-09-01T22:37:47.722
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T22:37:47.557
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
    -0.6831296194166724 + _t10_x_t_,
    -0.36820750757727716 + _t10_xˍt_t_,
    _t10_xˍt_t_ - _t10_x_t_*_tpk1_
]

