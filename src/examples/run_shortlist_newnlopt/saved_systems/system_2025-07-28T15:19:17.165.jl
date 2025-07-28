# Polynomial system saved on 2025-07-28T15:19:17.165
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:17.165
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t390_x1_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _t390_x1_t_ _t390_x1ˍt_t_
varlist = [_tpa__t390_x1_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.490395530423087 + _t390_x1_t_^3,
    0.7471185258894615 + 3(_t390_x1_t_^2)*_t390_x1ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_
]

