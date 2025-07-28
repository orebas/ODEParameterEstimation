# Polynomial system saved on 2025-07-28T15:15:23.517
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:15:23.517
# num_equations: 12

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
_t390_rˍtttt_t_
_t390_wˍt_t_
_t390_wˍtt_t_
_t390_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t390_r_t_ _t390_w_t_ _t390_rˍt_t_ _t390_rˍtt_t_ _t390_rˍttt_t_ _t390_rˍtttt_t_ _t390_wˍt_t_ _t390_wˍtt_t_ _t390_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t390_r_t__t390_w_t__t390_rˍt_t__t390_rˍtt_t__t390_rˍttt_t__t390_rˍtttt_t__t390_wˍt_t__t390_wˍtt_t__t390_wˍttt_t_]

# Polynomial System
poly_system = [
    -1.4129169765419958 + _t390_r_t_,
    1.6193274340153465 + _t390_rˍt_t_,
    -0.6234105386542979 + _t390_rˍtt_t_,
    -4.064727162796771 + _t390_rˍttt_t_,
    11.163896700367332 + _t390_rˍtttt_t_,
    _t390_rˍt_t_ - _t390_r_t_*_tpk1_ + _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_rˍtt_t_ - _t390_rˍt_t_*_tpk1_ + _t390_r_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍt_t_*_t390_w_t_*_tpk2_,
    _t390_rˍttt_t_ - _t390_rˍtt_t_*_tpk1_ + _t390_r_t_*_t390_wˍtt_t_*_tpk2_ + 2_t390_rˍt_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍtt_t_*_t390_w_t_*_tpk2_,
    _t390_rˍtttt_t_ - _t390_rˍttt_t_*_tpk1_ + _t390_r_t_*_t390_wˍttt_t_*_tpk2_ + 3_t390_rˍt_t_*_t390_wˍtt_t_*_tpk2_ + 3_t390_rˍtt_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍttt_t_*_t390_w_t_*_tpk2_,
    _t390_wˍt_t_ + _t390_w_t_*_tpk3_ - _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_wˍtt_t_ + _t390_wˍt_t_*_tpk3_ - _t390_r_t_*_t390_wˍt_t_*_tpk2_ - _t390_rˍt_t_*_t390_w_t_*_tpk2_,
    _t390_wˍttt_t_ + _t390_wˍtt_t_*_tpk3_ - _t390_r_t_*_t390_wˍtt_t_*_tpk2_ - 2_t390_rˍt_t_*_t390_wˍt_t_*_tpk2_ - _t390_rˍtt_t_*_t390_w_t_*_tpk2_
]

