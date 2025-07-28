# Polynomial system saved on 2025-07-28T15:46:01.747
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:46:01.747
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t201_x1_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _t201_x1_t_ _t201_x1ˍt_t_
varlist = [_tpa__t201_x1_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -1.785041446460149 + _t201_x1_t_^3,
    0.535508442697169 + 3(_t201_x1_t_^2)*_t201_x1ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x1_t_*_tpa_
]

