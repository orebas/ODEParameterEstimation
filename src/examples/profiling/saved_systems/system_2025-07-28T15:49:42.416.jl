# Polynomial system saved on 2025-07-28T15:49:42.416
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:42.416
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
    -3.9550334596414243 + _t67_x2_t_,
    -8.018093740548956 + _t67_x2ˍt_t_,
    24.693765993597957 + _t67_x2ˍtt_t_,
    -6.28416320669697 + _t67_x1_t_,
    12.942344352150693 + _t67_x1ˍt_t_,
    18.694142519653674 + _t67_x1ˍtt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x2ˍtt_t_ + _t67_x2ˍt_t_*_tpc_ - _t67_x1_t_*_t67_x2ˍt_t_*_tpd_ - _t67_x1ˍt_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    _t67_x1ˍtt_t_ - _t67_x1ˍt_t_*_tpa_ + _t67_x1_t_*_t67_x2ˍt_t_*_tpb_ + _t67_x1ˍt_t_*_t67_x2_t_*_tpb_
]

