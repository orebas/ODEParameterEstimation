# Polynomial system saved on 2025-07-28T15:15:48.193
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:48.193
# num_equations: 18

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t445_r_t_
_t445_w_t_
_t445_rˍt_t_
_t445_rˍtt_t_
_t445_rˍttt_t_
_t445_wˍt_t_
_t445_wˍtt_t_
_t501_r_t_
_t501_w_t_
_t501_rˍt_t_
_t501_rˍtt_t_
_t501_rˍttt_t_
_t501_wˍt_t_
_t501_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t445_r_t_ _t445_w_t_ _t445_rˍt_t_ _t445_rˍtt_t_ _t445_rˍttt_t_ _t445_wˍt_t_ _t445_wˍtt_t_ _t501_r_t_ _t501_w_t_ _t501_rˍt_t_ _t501_rˍtt_t_ _t501_rˍttt_t_ _t501_wˍt_t_ _t501_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t445_r_t__t445_w_t__t445_rˍt_t__t445_rˍtt_t__t445_rˍttt_t__t445_wˍt_t__t445_wˍtt_t__t501_r_t__t501_w_t__t501_rˍt_t__t501_rˍtt_t__t501_rˍttt_t__t501_wˍt_t__t501_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.09554709531624772 + _t445_r_t_,
    0.08083482759243334 + _t445_rˍt_t_,
    -0.11287624610340903 + _t445_rˍtt_t_,
    0.17487669154928848 + _t445_rˍttt_t_,
    _t445_rˍt_t_ - _t445_r_t_*_tpk1_ + _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtt_t_ - _t445_rˍt_t_*_tpk1_ + _t445_r_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍttt_t_ - _t445_rˍtt_t_*_tpk1_ + _t445_r_t_*_t445_wˍtt_t_*_tpk2_ + 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍtt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍt_t_ + _t445_w_t_*_tpk3_ - _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_wˍtt_t_ + _t445_wˍt_t_*_tpk3_ - _t445_r_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    -0.04006611667002413 + _t501_r_t_,
    9.281946101317484e-5 + _t501_rˍt_t_,
    -0.011230328953471657 + _t501_rˍtt_t_,
    0.003336529369885261 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_
]

