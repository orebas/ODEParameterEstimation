# Polynomial system saved on 2025-07-28T15:15:24.821
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:15:24.821
# num_equations: 12

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
_t445_rˍtttt_t_
_t445_wˍt_t_
_t445_wˍtt_t_
_t445_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t445_r_t_ _t445_w_t_ _t445_rˍt_t_ _t445_rˍtt_t_ _t445_rˍttt_t_ _t445_rˍtttt_t_ _t445_wˍt_t_ _t445_wˍtt_t_ _t445_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t445_r_t__t445_w_t__t445_rˍt_t__t445_rˍtt_t__t445_rˍttt_t__t445_rˍtttt_t__t445_wˍt_t__t445_wˍtt_t__t445_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.09554709531755992 + _t445_r_t_,
    0.08083488836215363 + _t445_rˍt_t_,
    -0.1128762482821597 + _t445_rˍtt_t_,
    0.17486385798315318 + _t445_rˍttt_t_,
    -0.3034768759139297 + _t445_rˍtttt_t_,
    _t445_rˍt_t_ - _t445_r_t_*_tpk1_ + _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtt_t_ - _t445_rˍt_t_*_tpk1_ + _t445_r_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍttt_t_ - _t445_rˍtt_t_*_tpk1_ + _t445_r_t_*_t445_wˍtt_t_*_tpk2_ + 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍtt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtttt_t_ - _t445_rˍttt_t_*_tpk1_ + _t445_r_t_*_t445_wˍttt_t_*_tpk2_ + 3_t445_rˍt_t_*_t445_wˍtt_t_*_tpk2_ + 3_t445_rˍtt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍttt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍt_t_ + _t445_w_t_*_tpk3_ - _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_wˍtt_t_ + _t445_wˍt_t_*_tpk3_ - _t445_r_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍttt_t_ + _t445_wˍtt_t_*_tpk3_ - _t445_r_t_*_t445_wˍtt_t_*_tpk2_ - 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍtt_t_*_t445_w_t_*_tpk2_
]

