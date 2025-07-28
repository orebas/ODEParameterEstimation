# Polynomial system saved on 2025-07-28T15:36:59.730
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:36:59.729
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
    -1.785041417059464 + _t201_x1_t_^3,
    0.5355094336327524 + 3(_t201_x1_t_^2)*_t201_x1ˍt_t_,
    _t201_x1ˍt_t_ + _t201_x1_t_*_tpa_
]

