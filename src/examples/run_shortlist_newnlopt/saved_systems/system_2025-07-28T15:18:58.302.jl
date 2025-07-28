# Polynomial system saved on 2025-07-28T15:18:58.302
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:18:58.302
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t278_x1_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _t278_x1_t_ _t278_x1ˍt_t_
varlist = [_tpa__t278_x1_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.4849076294479406 + _t278_x1_t_^3,
    1.0454721473911255 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_
]

