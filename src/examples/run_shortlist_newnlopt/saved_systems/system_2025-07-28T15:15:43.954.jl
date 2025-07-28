# Polynomial system saved on 2025-07-28T15:15:43.954
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:43.954
# num_equations: 18

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t390_r_t_
_t390_w_t_
_t390_rˍt_t_
_t390_rˍtt_t_
_t390_rˍttt_t_
_t390_wˍt_t_
_t390_wˍtt_t_
_t501_r_t_
_t501_w_t_
_t501_rˍt_t_
_t501_rˍtt_t_
_t501_rˍttt_t_
_t501_wˍt_t_
_t501_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t390_r_t_ _t390_w_t_ _t390_rˍt_t_ _t390_rˍtt_t_ _t390_rˍttt_t_ _t390_wˍt_t_ _t390_wˍtt_t_ _t501_r_t_ _t501_w_t_ _t501_rˍt_t_ _t501_rˍtt_t_ _t501_rˍttt_t_ _t501_wˍt_t_ _t501_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t390_r_t__t390_w_t__t390_rˍt_t__t390_rˍtt_t__t390_rˍttt_t__t390_wˍt_t__t390_wˍtt_t__t501_r_t__t501_w_t__t501_rˍt_t__t501_rˍtt_t__t501_rˍttt_t__t501_wˍt_t__t501_wˍtt_t_]

# Polynomial System
poly_system = [
    -1.412916964683804 + _t390_r_t_,
    1.6193273744573897 + _t390_rˍt_t_,
    -0.6234131231984315 + _t390_rˍtt_t_,
    -4.064717119446127 + _t390_rˍttt_t_,
    _t390_rˍt_t_ - _t390_r_t_*_tpk1_ + _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_rˍtt_t_ - _t390_rˍt_t_*_tpk1_ + _t390_r_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍt_t_*_t390_w_t_*_tpk2_,
    _t390_rˍttt_t_ - _t390_rˍtt_t_*_tpk1_ + _t390_r_t_*_t390_wˍtt_t_*_tpk2_ + 2_t390_rˍt_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍtt_t_*_t390_w_t_*_tpk2_,
    _t390_wˍt_t_ + _t390_w_t_*_tpk3_ - _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_wˍtt_t_ + _t390_wˍt_t_*_tpk3_ - _t390_r_t_*_t390_wˍt_t_*_tpk2_ - _t390_rˍt_t_*_t390_w_t_*_tpk2_,
    -0.04006611750010636 + _t501_r_t_,
    9.158683902258241e-5 + _t501_rˍt_t_,
    -0.01128404920267967 + _t501_rˍtt_t_,
    0.0019703123919144142 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_
]

