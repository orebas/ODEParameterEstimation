# Polynomial system saved on 2025-07-28T15:19:08.046
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:08.046
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
    -3.4849076398976466 + _t278_x1_t_^3,
    1.0454722919693076 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_
]

