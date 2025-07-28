# Polynomial system saved on 2025-07-28T15:44:56.065
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:56.065
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t67_x1_t_
_t67_x2_t_
_t67_x2ˍt_t_
_t67_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t67_x1_t_ _t67_x2_t_ _t67_x2ˍt_t_ _t67_x1ˍt_t_
varlist = [_tpa__tpb__t67_x1_t__t67_x2_t__t67_x2ˍt_t__t67_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7754043459002689 + _t67_x2_t_,
    0.14468182798976204 + _t67_x2ˍt_t_,
    0.18085227246913538 + _t67_x1_t_,
    0.3101617385651257 + _t67_x1ˍt_t_,
    _t67_x2ˍt_t_ - _t67_x1_t_*_tpb_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

