# Polynomial system saved on 2025-07-28T15:14:47.397
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:47.397
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t167_r_t_
_t167_w_t_
_t167_rˍt_t_
_t167_rˍtt_t_
_t167_rˍttt_t_
_t167_rˍtttt_t_
_t167_wˍt_t_
_t167_wˍtt_t_
_t167_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t167_r_t_ _t167_w_t_ _t167_rˍt_t_ _t167_rˍtt_t_ _t167_rˍttt_t_ _t167_rˍtttt_t_ _t167_wˍt_t_ _t167_wˍtt_t_ _t167_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t167_r_t__t167_w_t__t167_rˍt_t__t167_rˍtt_t__t167_rˍttt_t__t167_rˍtttt_t__t167_wˍt_t__t167_wˍtt_t__t167_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.04087326381411871 + _t167_r_t_,
    -0.004168166822308208 + _t167_rˍt_t_,
    -0.010686738680078975 + _t167_rˍtt_t_,
    -0.00023539466163441573 + _t167_rˍttt_t_,
    -0.007816906615124155 + _t167_rˍtttt_t_,
    _t167_rˍt_t_ - _t167_r_t_*_tpk1_ + _t167_r_t_*_t167_w_t_*_tpk2_,
    _t167_rˍtt_t_ - _t167_rˍt_t_*_tpk1_ + _t167_r_t_*_t167_wˍt_t_*_tpk2_ + _t167_rˍt_t_*_t167_w_t_*_tpk2_,
    _t167_rˍttt_t_ - _t167_rˍtt_t_*_tpk1_ + _t167_r_t_*_t167_wˍtt_t_*_tpk2_ + 2_t167_rˍt_t_*_t167_wˍt_t_*_tpk2_ + _t167_rˍtt_t_*_t167_w_t_*_tpk2_,
    _t167_rˍtttt_t_ - _t167_rˍttt_t_*_tpk1_ + _t167_r_t_*_t167_wˍttt_t_*_tpk2_ + 3_t167_rˍt_t_*_t167_wˍtt_t_*_tpk2_ + 3_t167_rˍtt_t_*_t167_wˍt_t_*_tpk2_ + _t167_rˍttt_t_*_t167_w_t_*_tpk2_,
    _t167_wˍt_t_ + _t167_w_t_*_tpk3_ - _t167_r_t_*_t167_w_t_*_tpk2_,
    _t167_wˍtt_t_ + _t167_wˍt_t_*_tpk3_ - _t167_r_t_*_t167_wˍt_t_*_tpk2_ - _t167_rˍt_t_*_t167_w_t_*_tpk2_,
    _t167_wˍttt_t_ + _t167_wˍtt_t_*_tpk3_ - _t167_r_t_*_t167_wˍtt_t_*_tpk2_ - 2_t167_rˍt_t_*_t167_wˍt_t_*_tpk2_ - _t167_rˍtt_t_*_t167_w_t_*_tpk2_
]

