# Polynomial system saved on 2025-07-28T15:19:07.880
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:07.879
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
    -5.751389867455534 + _t111_x1_t_^3,
    1.725416960236851 + 3(_t111_x1_t_^2)*_t111_x1ˍt_t_,
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_
]

