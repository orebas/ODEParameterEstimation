# Polynomial system saved on 2025-07-28T15:18:56.600
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:18:56.600
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t111_x1_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _t111_x1_t_ _t111_x1ˍt_t_
varlist = [_tpa__t111_x1_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.751389850652334 + _t111_x1_t_^3,
    1.7254172274534594 + 3(_t111_x1_t_^2)*_t111_x1ˍt_t_,
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_
]

