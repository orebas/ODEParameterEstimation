# Polynomial system saved on 2025-07-28T15:14:57.519
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:57.518
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t501_r_t_
_t501_w_t_
_t501_rˍt_t_
_t501_rˍtt_t_
_t501_rˍttt_t_
_t501_rˍtttt_t_
_t501_wˍt_t_
_t501_wˍtt_t_
_t501_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t501_r_t_ _t501_w_t_ _t501_rˍt_t_ _t501_rˍtt_t_ _t501_rˍttt_t_ _t501_rˍtttt_t_ _t501_wˍt_t_ _t501_wˍtt_t_ _t501_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t501_r_t__t501_w_t__t501_rˍt_t__t501_rˍtt_t__t501_rˍttt_t__t501_rˍtttt_t__t501_wˍt_t__t501_wˍtt_t__t501_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.04006610449540027 + _t501_r_t_,
    9.24147692603392e-5 + _t501_rˍt_t_,
    -0.011262130368313594 + _t501_rˍtt_t_,
    0.002221771201691777 + _t501_rˍttt_t_,
    -0.04144290519089512 + _t501_rˍtttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtttt_t_ - _t501_rˍttt_t_*_tpk1_ + _t501_r_t_*_t501_wˍttt_t_*_tpk2_ + 3_t501_rˍt_t_*_t501_wˍtt_t_*_tpk2_ + 3_t501_rˍtt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍttt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍttt_t_ + _t501_wˍtt_t_*_tpk3_ - _t501_r_t_*_t501_wˍtt_t_*_tpk2_ - 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍtt_t_*_t501_w_t_*_tpk2_
]

