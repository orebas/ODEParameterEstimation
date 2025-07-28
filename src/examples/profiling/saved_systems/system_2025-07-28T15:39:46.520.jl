# Polynomial system saved on 2025-07-28T15:39:46.520
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:39:46.520
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t22_x1_t_
_t22_x2_t_
_t22_x2ˍt_t_
_t22_x1ˍt_t_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t22_x1_t_ _t22_x2_t_ _t22_x2ˍt_t_ _t22_x1ˍt_t_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t22_x1_t__t22_x2_t__t22_x2ˍt_t__t22_x1ˍt_t__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.0826240754325136 + _t22_x2_t_,
    -9.057672214914662 + _t22_x2ˍt_t_,
    -7.422846756732204 + _t22_x1_t_,
    9.459471765917367 + _t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x2_t_*_tpc_ - _t22_x1_t_*_t22_x2_t_*_tpd_,
    _t22_x1ˍt_t_ - _t22_x1_t_*_tpa_ + _t22_x1_t_*_t22_x2_t_*_tpb_,
    -0.46789084447471363 + _t89_x2_t_,
    0.6150443522558 + _t89_x2ˍt_t_,
    -2.1068522876593887 + _t89_x1_t_,
    -2.273072656042912 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_
]

