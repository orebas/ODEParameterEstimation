# Polynomial system saved on 2025-07-28T15:37:21.083
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:37:21.083
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t22_x1_t_
_t22_x2_t_
_t22_x3_t_
_t22_x2ˍt_t_
_t22_x3ˍt_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t22_x1_t_ _t22_x2_t_ _t22_x3_t_ _t22_x2ˍt_t_ _t22_x3ˍt_t_ _t22_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t22_x1_t__t22_x2_t__t22_x3_t__t22_x2ˍt_t__t22_x3ˍt_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -21.90686218318304 + _t22_x2_t_^3,
    8.680458194653955 + 3(_t22_x2_t_^2)*_t22_x2ˍt_t_,
    -50.534781537793364 + _t22_x3_t_^3,
    22.732159615820876 + 3(_t22_x3_t_^2)*_t22_x3ˍt_t_,
    -6.309783252580864 + _t22_x1_t_^3,
    2.8663157184561525 + 3(_t22_x1_t_^2)*_t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x1_t_*_tpb_,
    _t22_x3ˍt_t_ + _t22_x1_t_*_tpc_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_
]

