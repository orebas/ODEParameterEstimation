# Polynomial system saved on 2025-07-28T15:15:26.783
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:15:26.783
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
    -0.04006611274646622 + _t501_r_t_,
    9.246381310529239e-5 + _t501_rˍt_t_,
    -0.011243287083794629 + _t501_rˍtt_t_,
    0.003223677798930069 + _t501_rˍttt_t_,
    -0.010148114731791225 + _t501_rˍtttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtttt_t_ - _t501_rˍttt_t_*_tpk1_ + _t501_r_t_*_t501_wˍttt_t_*_tpk2_ + 3_t501_rˍt_t_*_t501_wˍtt_t_*_tpk2_ + 3_t501_rˍtt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍttt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍttt_t_ + _t501_wˍtt_t_*_tpk3_ - _t501_r_t_*_t501_wˍtt_t_*_tpk2_ - 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍtt_t_*_t501_w_t_*_tpk2_
]

