# Polynomial system saved on 2025-07-28T15:37:00.129
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:37:00.129
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t89_x1_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _t89_x1_t_ _t89_x1ˍt_t_
varlist = [_tpa__t89_x1_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.134810675933562 + _t89_x1_t_^3,
    1.2404432027800407 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x1_t_*_tpa_
]

