# Polynomial system saved on 2025-07-28T15:15:31.401
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:31.401
# num_equations: 18

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
_t167_wˍt_t_
_t167_wˍtt_t_
_t334_r_t_
_t334_w_t_
_t334_rˍt_t_
_t334_rˍtt_t_
_t334_rˍttt_t_
_t334_wˍt_t_
_t334_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t167_r_t_ _t167_w_t_ _t167_rˍt_t_ _t167_rˍtt_t_ _t167_rˍttt_t_ _t167_wˍt_t_ _t167_wˍtt_t_ _t334_r_t_ _t334_w_t_ _t334_rˍt_t_ _t334_rˍtt_t_ _t334_rˍttt_t_ _t334_wˍt_t_ _t334_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t167_r_t__t167_w_t__t167_rˍt_t__t167_rˍtt_t__t167_rˍttt_t__t167_wˍt_t__t167_wˍtt_t__t334_r_t__t334_w_t__t334_rˍt_t__t334_rˍtt_t__t334_rˍttt_t__t334_wˍt_t__t334_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.04087325335092806 + _t167_r_t_,
    -0.004168095602521725 + _t167_rˍt_t_,
    -0.010686971742488751 + _t167_rˍtt_t_,
    -0.00024251704879528615 + _t167_rˍttt_t_,
    _t167_rˍt_t_ - _t167_r_t_*_tpk1_ + _t167_r_t_*_t167_w_t_*_tpk2_,
    _t167_rˍtt_t_ - _t167_rˍt_t_*_tpk1_ + _t167_r_t_*_t167_wˍt_t_*_tpk2_ + _t167_rˍt_t_*_t167_w_t_*_tpk2_,
    _t167_rˍttt_t_ - _t167_rˍtt_t_*_tpk1_ + _t167_r_t_*_t167_wˍtt_t_*_tpk2_ + 2_t167_rˍt_t_*_t167_wˍt_t_*_tpk2_ + _t167_rˍtt_t_*_t167_w_t_*_tpk2_,
    _t167_wˍt_t_ + _t167_w_t_*_tpk3_ - _t167_r_t_*_t167_w_t_*_tpk2_,
    _t167_wˍtt_t_ + _t167_wˍt_t_*_tpk3_ - _t167_r_t_*_t167_wˍt_t_*_tpk2_ - _t167_rˍt_t_*_t167_w_t_*_tpk2_,
    -1.5681738675556791 + _t334_r_t_,
    -0.96105196246461 + _t334_rˍt_t_,
    -0.29507819294517323 + _t334_rˍtt_t_,
    0.6134032719437571 + _t334_rˍttt_t_,
    _t334_rˍt_t_ - _t334_r_t_*_tpk1_ + _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtt_t_ - _t334_rˍt_t_*_tpk1_ + _t334_r_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍttt_t_ - _t334_rˍtt_t_*_tpk1_ + _t334_r_t_*_t334_wˍtt_t_*_tpk2_ + 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍtt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍt_t_ + _t334_w_t_*_tpk3_ - _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_wˍtt_t_ + _t334_wˍt_t_*_tpk3_ - _t334_r_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍt_t_*_t334_w_t_*_tpk2_
]

