# Polynomial system saved on 2025-07-28T15:19:04.439
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:04.439
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t445_x1_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _t445_x1_t_ _t445_x1ˍt_t_
varlist = [_tpa__t445_x1_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.111590672395364 + _t445_x1_t_^3,
    0.633477187227776 + 3(_t445_x1_t_^2)*_t445_x1ˍt_t_,
    _t445_x1ˍt_t_ + _t445_x1_t_*_tpa_
]

