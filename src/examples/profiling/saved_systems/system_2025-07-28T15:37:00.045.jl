# Polynomial system saved on 2025-07-28T15:37:00.045
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:37:00.045
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t67_x1_t_
_t67_x1ˍt_t_
"""
@variables _tpa_ _t67_x1_t_ _t67_x1ˍt_t_
varlist = [_tpa__t67_x1_t__t67_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.876567258370595 + _t67_x1_t_^3,
    1.4629701775114476 + 3(_t67_x1_t_^2)*_t67_x1ˍt_t_,
    _t67_x1ˍt_t_ + _t67_x1_t_*_tpa_
]

