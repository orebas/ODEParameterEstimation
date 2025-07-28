# Polynomial system saved on 2025-07-28T15:36:59.979
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:36:59.979
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t45_x1_t_
_t45_x1ˍt_t_
"""
@variables _tpa_ _t45_x1_t_ _t45_x1ˍt_t_
varlist = [_tpa__t45_x1_t__t45_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.751389867455545 + _t45_x1_t_^3,
    1.7254169602362595 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x1_t_*_tpa_
]

