# Polynomial system saved on 2025-07-28T15:49:40.850
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:40.846
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t67_x1_t_
_t67_x2_t_
_t67_x2ˍt_t_
_t67_x2ˍtt_t_
_t67_x1ˍt_t_
_t67_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t67_x1_t_ _t67_x2_t_ _t67_x2ˍt_t_ _t67_x2ˍtt_t_ _t67_x1ˍt_t_ _t67_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t67_x1_t__t67_x2_t__t67_x2ˍt_t__t67_x2ˍtt_t__t67_x1ˍt_t__t67_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -3.955033437062922 + _t67_x2_t_,
    -8.018093606976187 + _t67_x2ˍt_t_,
    24.693750401484397 + _t67_x2ˍtt_t_,
    -6.2841632027317536 + _t67_x1_t_,
    12.942344002408607 + _t67_x1ˍt_t_,
    18.694150709995284 + _t67_x1ˍtt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x2ˍtt_t_ + _t67_x2ˍt_t_*_tpc_ - _t67_x1_t_*_t67_x2ˍt_t_*_tpd_ - _t67_x1ˍt_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    _t67_x1ˍtt_t_ - _t67_x1ˍt_t_*_tpa_ + _t67_x1_t_*_t67_x2ˍt_t_*_tpb_ + _t67_x1ˍt_t_*_t67_x2_t_*_tpb_
]

