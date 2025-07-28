# Polynomial system saved on 2025-07-28T15:15:34.337
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:34.337
# num_equations: 18

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t334_r_t_
_t334_w_t_
_t334_rˍt_t_
_t334_rˍtt_t_
_t334_rˍttt_t_
_t334_wˍt_t_
_t334_wˍtt_t_
_t501_r_t_
_t501_w_t_
_t501_rˍt_t_
_t501_rˍtt_t_
_t501_rˍttt_t_
_t501_wˍt_t_
_t501_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t334_r_t_ _t334_w_t_ _t334_rˍt_t_ _t334_rˍtt_t_ _t334_rˍttt_t_ _t334_wˍt_t_ _t334_wˍtt_t_ _t501_r_t_ _t501_w_t_ _t501_rˍt_t_ _t501_rˍtt_t_ _t501_rˍttt_t_ _t501_wˍt_t_ _t501_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t334_r_t__t334_w_t__t334_rˍt_t__t334_rˍtt_t__t334_rˍttt_t__t334_wˍt_t__t334_wˍtt_t__t501_r_t__t501_w_t__t501_rˍt_t__t501_rˍtt_t__t501_rˍttt_t__t501_wˍt_t__t501_wˍtt_t_]

# Polynomial System
poly_system = [
    -1.568173898557616 + _t334_r_t_,
    -0.9610519161408785 + _t334_rˍt_t_,
    -0.2950704309765142 + _t334_rˍtt_t_,
    0.6134088888824943 + _t334_rˍttt_t_,
    _t334_rˍt_t_ - _t334_r_t_*_tpk1_ + _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtt_t_ - _t334_rˍt_t_*_tpk1_ + _t334_r_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍttt_t_ - _t334_rˍtt_t_*_tpk1_ + _t334_r_t_*_t334_wˍtt_t_*_tpk2_ + 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍtt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍt_t_ + _t334_w_t_*_tpk3_ - _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_wˍtt_t_ + _t334_wˍt_t_*_tpk3_ - _t334_r_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    -0.04006610942353639 + _t501_r_t_,
    9.033778352533631e-5 + _t501_rˍt_t_,
    -0.011394916492923823 + _t501_rˍtt_t_,
    -0.002484562712667721 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_
]

