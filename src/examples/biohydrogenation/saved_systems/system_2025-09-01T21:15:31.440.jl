# Polynomial system saved on 2025-09-01T21:15:31.440
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:15:31.440
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t7_x_t_
_t7_xˍt_t_
"""
@variables _tpk1_ _t7_x_t_ _t7_xˍt_t_
varlist = [_tpk1__t7_x_t__t7_xˍt_t_]

# Polynomial System
poly_system = [
    -0.6300720393801589 + _t7_x_t_,
    -0.3396088292259778 + _t7_xˍt_t_,
    _t7_xˍt_t_ - _t7_x_t_*_tpk1_
]

