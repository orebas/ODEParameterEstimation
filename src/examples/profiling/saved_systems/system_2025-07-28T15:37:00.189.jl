# Polynomial system saved on 2025-07-28T15:37:00.190
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:37:00.189
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t112_x1_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _t112_x1_t_ _t112_x1ˍt_t_
varlist = [_tpa__t112_x1_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.479684196999397 + _t112_x1_t_^3,
    1.0439052590996756 + 3(_t112_x1_t_^2)*_t112_x1ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x1_t_*_tpa_
]

