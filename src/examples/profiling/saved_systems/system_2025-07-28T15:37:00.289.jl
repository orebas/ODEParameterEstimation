# Polynomial system saved on 2025-07-28T15:37:00.290
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:37:00.289
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t156_x1_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _t156_x1_t_ _t156_x1ˍt_t_
varlist = [_tpa__t156_x1_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.5016275540709083 + _t156_x1_t_^3,
    0.7504882662205983 + 3(_t156_x1_t_^2)*_t156_x1ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x1_t_*_tpa_
]

