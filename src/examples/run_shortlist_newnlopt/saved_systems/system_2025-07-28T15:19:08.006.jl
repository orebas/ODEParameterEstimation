# Polynomial system saved on 2025-07-28T15:19:08.006
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:19:08.006
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t223_x1_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _t223_x1_t_ _t223_x1ˍt_t_
varlist = [_tpa__t223_x1_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.110076089840153 + _t223_x1_t_^3,
    1.2330228269342598 + 3(_t223_x1_t_^2)*_t223_x1ˍt_t_,
    _t223_x1ˍt_t_ + _t223_x1_t_*_tpa_
]

