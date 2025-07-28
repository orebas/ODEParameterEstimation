# Polynomial system saved on 2025-07-28T15:18:56.967
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:18:56.967
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t167_x1_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _t167_x1_t_ _t167_x1ˍt_t_
varlist = [_tpa__t167_x1_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.861959490588423 + _t167_x1_t_^3,
    1.4585876464100724 + 3(_t167_x1_t_^2)*_t167_x1ˍt_t_,
    _t167_x1ˍt_t_ + _t167_x1_t_*_tpa_
]

