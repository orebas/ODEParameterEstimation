# Polynomial system saved on 2025-07-28T15:49:51.222
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:51.222
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x2ˍtt_t_
_t179_x1ˍt_t_
_t179_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x2ˍtt_t_ _t179_x1ˍt_t_ _t179_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x2ˍtt_t__t179_x1ˍt_t__t179_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3749304465674219 + _t179_x2_t_,
    0.3344082277180638 + _t179_x2ˍt_t_,
    -1.217033931270003 + _t179_x2ˍtt_t_,
    -2.6350914455131864 + _t179_x1_t_,
    -3.0634567002909114 + _t179_x1ˍt_t_,
    -4.354602538529271 + _t179_x1ˍtt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x2ˍtt_t_ + _t179_x2ˍt_t_*_tpc_ - _t179_x1_t_*_t179_x2ˍt_t_*_tpd_ - _t179_x1ˍt_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_,
    _t179_x1ˍtt_t_ - _t179_x1ˍt_t_*_tpa_ + _t179_x1_t_*_t179_x2ˍt_t_*_tpb_ + _t179_x1ˍt_t_*_t179_x2_t_*_tpb_
]

