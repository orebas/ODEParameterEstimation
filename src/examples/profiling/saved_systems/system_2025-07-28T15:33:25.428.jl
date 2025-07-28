# Polynomial system saved on 2025-07-28T15:33:25.429
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:25.429
# num_equations: 3

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
    -0.9188593430068296 + _t21_x_t_,
    -0.4952658575408064 + _t21_xˍt_t_,
    _t21_xˍt_t_ - _t21_x_t_*_tpk1_
]

