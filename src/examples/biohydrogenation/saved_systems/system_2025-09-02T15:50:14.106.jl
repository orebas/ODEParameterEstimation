# Polynomial system saved on 2025-09-02T15:50:14.115
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# reconstruction_attempt: 0
# timestamp: 2025-09-02T15:50:14.106
# num_equations: 3
# deriv_level: Dict(1 => 1)

# Variables
varlist_str = """
_tpk1_
_t21_x_t_
_t21_xˍt_t_
"""
@variables _tpk1_ _t21_x_t_ _t21_xˍt_t_
varlist = [_tpk1__t21_x_t__t21_xˍt_t_]

# Polynomial System
poly_system = [
    -0.91886061583929 + _t21_x_t_,
    -0.495256694440506 + _t21_xˍt_t_,
    _t21_xˍt_t_ - _t21_x_t_*_tpk1_
]

