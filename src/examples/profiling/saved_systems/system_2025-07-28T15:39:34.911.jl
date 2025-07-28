# Polynomial system saved on 2025-07-28T15:39:34.911
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:34.911
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x2ˍtt_t_
_t112_x1ˍt_t_
_t112_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x2ˍtt_t_ _t112_x1ˍt_t_ _t112_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x2ˍtt_t__t112_x1ˍt_t__t112_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.591122116956141 + _t112_x2_t_,
    -4.4569322162596805 + _t112_x2ˍt_t_,
    43.65695406325415 + _t112_x2ˍtt_t_,
    -4.963448317315331 + _t112_x1_t_,
    13.06391690130162 + _t112_x1ˍt_t_,
    -14.476096541104917 + _t112_x1ˍtt_t_,
    _t112_x2ˍt_t_ + _t112_x2_t_*_tpc_ - _t112_x1_t_*_t112_x2_t_*_tpd_,
    _t112_x2ˍtt_t_ + _t112_x2ˍt_t_*_tpc_ - _t112_x1_t_*_t112_x2ˍt_t_*_tpd_ - _t112_x1ˍt_t_*_t112_x2_t_*_tpd_,
    _t112_x1ˍt_t_ - _t112_x1_t_*_tpa_ + _t112_x1_t_*_t112_x2_t_*_tpb_,
    _t112_x1ˍtt_t_ - _t112_x1ˍt_t_*_tpa_ + _t112_x1_t_*_t112_x2ˍt_t_*_tpb_ + _t112_x1ˍt_t_*_t112_x2_t_*_tpb_
]

