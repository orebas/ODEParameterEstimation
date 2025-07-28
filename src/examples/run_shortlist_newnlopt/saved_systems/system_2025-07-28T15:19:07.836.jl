# Polynomial system saved on 2025-07-28T15:19:07.836
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:07.836
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t56_x1_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _t56_x1_t_ _t56_x1ˍt_t_
varlist = [_tpa__t56_x1_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.783149632703235 + _t56_x1_t_^3,
    2.0349448898106317 + 3(_t56_x1_t_^2)*_t56_x1ˍt_t_,
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_
]

