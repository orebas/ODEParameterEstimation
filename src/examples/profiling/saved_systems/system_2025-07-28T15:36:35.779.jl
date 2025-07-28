# Polynomial system saved on 2025-07-28T15:36:35.780
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:36:35.779
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
    -6.834214525361853 + _t22_x1_t_^3,
    2.0502645911134048 + 3(_t22_x1_t_^2)*_t22_x1ˍt_t_,
    _t22_x1ˍt_t_ + _t22_x1_t_*_tpa_
]

