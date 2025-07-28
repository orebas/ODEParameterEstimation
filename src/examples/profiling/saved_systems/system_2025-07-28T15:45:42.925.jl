# Polynomial system saved on 2025-07-28T15:45:42.926
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:45:42.925
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t179_x1_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _t179_x1_t_ _t179_x1ˍt_t_
varlist = [_tpa__t179_x1_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.105265379076412 + _t179_x1_t_^3,
    0.6315794110662233 + 3(_t179_x1_t_^2)*_t179_x1ˍt_t_,
    _t179_x1ˍt_t_ + _t179_x1_t_*_tpa_
]

