# Polynomial system saved on 2025-07-28T15:39:32.099
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:32.099
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
    -3.955033426196611 + _t67_x2_t_,
    -8.018093588339964 + _t67_x2ˍt_t_,
    24.693747734818366 + _t67_x2ˍtt_t_,
    -6.2841632410736725 + _t67_x1_t_,
    12.942343729739843 + _t67_x1ˍt_t_,
    18.694153825518438 + _t67_x1ˍtt_t_,
    _t67_x2ˍt_t_ + _t67_x2_t_*_tpc_ - _t67_x1_t_*_t67_x2_t_*_tpd_,
    _t67_x2ˍtt_t_ + _t67_x2ˍt_t_*_tpc_ - _t67_x1_t_*_t67_x2ˍt_t_*_tpd_ - _t67_x1ˍt_t_*_t67_x2_t_*_tpd_,
    _t67_x1ˍt_t_ - _t67_x1_t_*_tpa_ + _t67_x1_t_*_t67_x2_t_*_tpb_,
    _t67_x1ˍtt_t_ - _t67_x1ˍt_t_*_tpa_ + _t67_x1_t_*_t67_x2ˍt_t_*_tpb_ + _t67_x1ˍt_t_*_t67_x2_t_*_tpb_
]

