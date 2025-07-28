# Polynomial system saved on 2025-07-28T15:33:25.007
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:33:25.007
# num_equations: 3

# Variables
varlist_str = """
_tpk1_
_t5_x_t_
_t5_xˍt_t_
"""
@variables _tpk1_ _t5_x_t_ _t5_xˍt_t_
varlist = [_tpk1__t5_x_t__t5_xˍt_t_]

# Polynomial System
poly_system = [
    -0.5970102729435832 + _t5_x_t_,
    -0.32178827798738513 + _t5_xˍt_t_,
    _t5_xˍt_t_ - _t5_x_t_*_tpk1_
]

