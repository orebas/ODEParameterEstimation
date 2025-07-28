# Polynomial system saved on 2025-07-28T15:19:00.007
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:00.007
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
    -2.9459800157369043 + _t334_x1_t_^3,
    0.883794115199257 + 3(_t334_x1_t_^2)*_t334_x1ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_
]

