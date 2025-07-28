# Polynomial system saved on 2025-07-28T15:44:54.998
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:54.998
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
    -0.7754043638352992 + _t67_x2_t_,
    0.14468181214714465 + _t67_x2ˍt_t_,
    0.18085227412139615 + _t67_x1_t_,
    0.31016173818412507 + _t67_x1ˍt_t_,
    _t67_x2ˍt_t_ - _t67_x1_t_*_tpb_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

