# Polynomial system saved on 2025-07-28T15:45:41.013
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:45:41.013
# num_equations: 3

# Variables
varlist_str = """
_tpa_
_t134_x1_t_
_t134_x1ˍt_t_
"""
@variables _tpa_ _t134_x1_t_ _t134_x1ˍt_t_
varlist = [_tpa__t134_x1_t__t134_x1ˍt_t_]

# Polynomial System
poly_system = [
    -2.9504023254557548 + _t134_x1_t_^3,
    0.8851206839207488 + 3(_t134_x1_t_^2)*_t134_x1ˍt_t_,
    _t134_x1ˍt_t_ + _t134_x1_t_*_tpa_
]

