# Polynomial system saved on 2025-07-28T15:32:54.341
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:32:54.197
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t2_x_t_
_t2_xˍt_t_
"""
@variables _tpk1_ _t2_x_t_ _t2_xˍt_t_
varlist = [_tpk1__t2_x_t__t2_xˍt_t_]

# Polynomial System
poly_system = [
    -0.5506417371092661 + _t2_x_t_,
    -0.29679622081570983 + _t2_xˍt_t_,
    _t2_xˍt_t_ - _t2_x_t_*_tpk1_
]

