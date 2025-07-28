# Polynomial system saved on 2025-07-28T15:50:06.121
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:50:06.121
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x2ˍtt_t_
_t156_x1ˍt_t_
_t156_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x2ˍtt_t_ _t156_x1ˍt_t_ _t156_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x2ˍtt_t__t156_x1ˍt_t__t156_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.686847953191071 + _t156_x2_t_,
    -3.371094103615551 + _t156_x2ˍt_t_,
    44.957320043056825 + _t156_x2ˍtt_t_,
    -4.6490834931308305 + _t156_x1_t_,
    12.636967468901206 + _t156_x1ˍt_t_,
    -20.244091245331447 + _t156_x1ˍtt_t_,
    _t156_x2ˍt_t_ + _t156_x2_t_*_tpc_ - _t156_x1_t_*_t156_x2_t_*_tpd_,
    _t156_x2ˍtt_t_ + _t156_x2ˍt_t_*_tpc_ - _t156_x1_t_*_t156_x2ˍt_t_*_tpd_ - _t156_x1ˍt_t_*_t156_x2_t_*_tpd_,
    _t156_x1ˍt_t_ - _t156_x1_t_*_tpa_ + _t156_x1_t_*_t156_x2_t_*_tpb_,
    _t156_x1ˍtt_t_ - _t156_x1ˍt_t_*_tpa_ + _t156_x1_t_*_t156_x2ˍt_t_*_tpb_ + _t156_x1ˍt_t_*_t156_x2_t_*_tpb_
]

