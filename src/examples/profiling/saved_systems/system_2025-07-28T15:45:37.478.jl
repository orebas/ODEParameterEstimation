# Polynomial system saved on 2025-07-28T15:45:37.478
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:45:37.478
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t45_x1_t_
_t45_x1ˍt_t_
"""
@variables _tpa_ _t45_x1_t_ _t45_x1ˍt_t_
varlist = [_tpa__t45_x1_t__t45_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.751390081598753 + _t45_x1_t_^3,
    1.7254170420289279 + 3(_t45_x1_t_^2)*_t45_x1ˍt_t_,
    _t45_x1ˍt_t_ + _t45_x1_t_*_tpa_
]

