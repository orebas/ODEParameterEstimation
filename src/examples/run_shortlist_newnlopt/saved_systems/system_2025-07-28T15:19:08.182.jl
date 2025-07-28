# Polynomial system saved on 2025-07-28T15:19:08.182
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:08.182
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t390_x1_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _t390_x1_t_ _t390_x1ˍt_t_
varlist = [_tpa__t390_x1_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.4903955211057855 + _t390_x1_t_^3,
    0.7471186563314776 + 3(_t390_x1_t_^2)*_t390_x1ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_
]

