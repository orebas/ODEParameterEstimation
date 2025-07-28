# Polynomial system saved on 2025-07-28T15:36:33.302
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:36:33.302
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t22_x1_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _t22_x1_t_ _t22_x1ˍt_t_
varlist = [_tpa__t22_x1_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.834214401399642 + _t22_x1_t_^3,
    2.0502638740813137 + 3(_t22_x1_t_^2)*_t22_x1ˍt_t_,
    _t22_x1ˍt_t_ + _t22_x1_t_*_tpa_
]

