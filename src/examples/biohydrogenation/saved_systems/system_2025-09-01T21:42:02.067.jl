# Polynomial system saved on 2025-09-01T21:42:02.067
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T21:42:02.067
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
    -0.8030351655227629 + _t16_x_t_,
    -0.43288080292981795 + _t16_xˍt_t_,
    _t16_xˍt_t_ - _t16_x_t_*_tpk1_
]

