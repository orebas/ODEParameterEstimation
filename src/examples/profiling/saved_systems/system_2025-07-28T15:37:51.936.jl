# Polynomial system saved on 2025-07-28T15:37:51.936
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:37:51.936
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t67_x1_t_
_t67_x2_t_
_t67_x3_t_
_t67_x2ˍt_t_
_t67_x3ˍt_t_
_t67_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t67_x1_t_ _t67_x2_t_ _t67_x3_t_ _t67_x2ˍt_t_ _t67_x3ˍt_t_ _t67_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t67_x1_t__t67_x2_t__t67_x3_t__t67_x2ˍt_t__t67_x3ˍt_t__t67_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.10303547296607 + _t67_x2_t_^3,
    5.446832903813516 + 3(_t67_x2_t_^2)*_t67_x2ˍt_t_,
    -30.490068641054332 + _t67_x3_t_^3,
    13.660468707523904 + 3(_t67_x3_t_^2)*_t67_x3ˍt_t_,
    -3.7614302007741944 + _t67_x1_t_^3,
    1.7530487590222303 + 3(_t67_x1_t_^2)*_t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x1_t_*_tpb_,
    _t67_x3ˍt_t_ + _t67_x1_t_*_tpc_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

