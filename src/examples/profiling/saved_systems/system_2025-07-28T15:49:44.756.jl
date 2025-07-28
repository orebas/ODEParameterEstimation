# Polynomial system saved on 2025-07-28T15:49:44.757
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:44.757
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
    -3.9550334389715753 + _t67_x2_t_,
    -8.018093254954964 + _t67_x2ˍt_t_,
    24.693749211776517 + _t67_x2ˍtt_t_,
    -6.284163211213869 + _t67_x1_t_,
    12.942343802619384 + _t67_x1ˍt_t_,
    18.694142852551437 + _t67_x1ˍtt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x2ˍtt_t_ + _t67_x2ˍt_t_*_tpc_ - _t67_x1_t_*_t67_x2ˍt_t_*_tpd_ - _t67_x1ˍt_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    _t67_x1ˍtt_t_ - _t67_x1ˍt_t_*_tpa_ + _t67_x1_t_*_t67_x2ˍt_t_*_tpb_ + _t67_x1ˍt_t_*_t67_x2_t_*_tpb_
]

