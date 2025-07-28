# Polynomial system saved on 2025-07-28T15:19:16.758
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:16.757
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t334_x1_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _t334_x1_t_ _t334_x1ˍt_t_
varlist = [_tpa__t334_x1_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.9459800360740234 + _t334_x1_t_^3,
    0.8837941164403983 + 3(_t334_x1_t_^2)*_t334_x1ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_
]

