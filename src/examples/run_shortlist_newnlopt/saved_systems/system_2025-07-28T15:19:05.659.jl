# Polynomial system saved on 2025-07-28T15:19:05.659
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:05.659
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t501_x1_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _t501_x1_t_ _t501_x1ˍt_t_
varlist = [_tpa__t501_x1_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -1.7850413602312596 + _t501_x1_t_^3,
    0.5355100450721902 + 3(_t501_x1_t_^2)*_t501_x1ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_
]

