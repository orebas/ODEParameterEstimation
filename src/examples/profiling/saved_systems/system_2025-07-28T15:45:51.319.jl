# Polynomial system saved on 2025-07-28T15:45:51.319
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:45:51.319
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
    -4.134810710057604 + _t89_x1_t_^3,
    1.2404429936735972 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x1_t_*_tpa_
]

