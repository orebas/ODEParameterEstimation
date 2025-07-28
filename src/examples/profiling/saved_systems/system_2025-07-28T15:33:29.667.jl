# Polynomial system saved on 2025-07-28T15:33:29.668
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:29.667
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t19_x_t_
_t19_xˍt_t_
"""
@variables _tpk1_ _t19_x_t_ _t19_xˍt_t_
varlist = [_tpk1__t19_x_t__t19_xˍt_t_]

# Polynomial System
poly_system = [
    -0.8706451332431843 + _t19_x_t_,
    -0.4692770190635301 + _t19_xˍt_t_,
    _t19_xˍt_t_ - _t19_x_t_*_tpk1_
]

