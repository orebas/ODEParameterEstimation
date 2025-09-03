# Polynomial system saved on 2025-09-01T20:48:02.747
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-01T20:48:02.747
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
    -0.7209606870390212 + _t12_x_t_,
    -0.3885978724792555 + _t12_xˍt_t_,
    _t12_xˍt_t_ - _t12_x_t_*_tpk1_
]

