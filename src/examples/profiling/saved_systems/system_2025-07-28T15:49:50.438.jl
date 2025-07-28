# Polynomial system saved on 2025-07-28T15:49:50.439
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:50.438
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
    -0.3749304385616339 + _t179_x2_t_,
    0.3344083987011763 + _t179_x2ˍt_t_,
    -1.2170415291966838 + _t179_x2ˍtt_t_,
    -2.6350914547445976 + _t179_x1_t_,
    -3.063456279818442 + _t179_x1ˍt_t_,
    -4.354607251009304 + _t179_x1ˍtt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x2ˍtt_t_ + _t179_x2ˍt_t_*_tpc_ - _t179_x1_t_*_t179_x2ˍt_t_*_tpd_ - _t179_x1ˍt_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_,
    _t179_x1ˍtt_t_ - _t179_x1ˍt_t_*_tpa_ + _t179_x1_t_*_t179_x2ˍt_t_*_tpb_ + _t179_x1ˍt_t_*_t179_x2_t_*_tpb_
]

