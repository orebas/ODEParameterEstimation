# Polynomial system saved on 2025-07-28T15:14:53.128
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:53.128
# num_equations: 12

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
_t334_rˍtttt_t_
_t334_wˍt_t_
_t334_wˍtt_t_
_t334_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t334_r_t_ _t334_w_t_ _t334_rˍt_t_ _t334_rˍtt_t_ _t334_rˍttt_t_ _t334_rˍtttt_t_ _t334_wˍt_t_ _t334_wˍtt_t_ _t334_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t334_r_t__t334_w_t__t334_rˍt_t__t334_rˍtt_t__t334_rˍttt_t__t334_rˍtttt_t__t334_wˍt_t__t334_wˍtt_t__t334_wˍttt_t_]

# Polynomial System
poly_system = [
    -1.5681738700745953 + _t334_r_t_,
    -0.9610521936135402 + _t334_rˍt_t_,
    -0.2950785296082002 + _t334_rˍtt_t_,
    0.6134436488363436 + _t334_rˍttt_t_,
    1.921894989643227 + _t334_rˍtttt_t_,
    _t334_rˍt_t_ - _t334_r_t_*_tpk1_ + _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtt_t_ - _t334_rˍt_t_*_tpk1_ + _t334_r_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍttt_t_ - _t334_rˍtt_t_*_tpk1_ + _t334_r_t_*_t334_wˍtt_t_*_tpk2_ + 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍtt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtttt_t_ - _t334_rˍttt_t_*_tpk1_ + _t334_r_t_*_t334_wˍttt_t_*_tpk2_ + 3_t334_rˍt_t_*_t334_wˍtt_t_*_tpk2_ + 3_t334_rˍtt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍttt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍt_t_ + _t334_w_t_*_tpk3_ - _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_wˍtt_t_ + _t334_wˍt_t_*_tpk3_ - _t334_r_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍttt_t_ + _t334_wˍtt_t_*_tpk3_ - _t334_r_t_*_t334_wˍtt_t_*_tpk2_ - 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍtt_t_*_t334_w_t_*_tpk2_
]

