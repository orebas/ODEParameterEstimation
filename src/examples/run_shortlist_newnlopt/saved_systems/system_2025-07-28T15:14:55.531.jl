# Polynomial system saved on 2025-07-28T15:14:55.531
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:55.531
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
    -0.09554710581875314 + _t445_r_t_,
    0.08083507607239757 + _t445_rˍt_t_,
    -0.11287464776247746 + _t445_rˍtt_t_,
    0.17483506949145763 + _t445_rˍttt_t_,
    -0.30372511299764804 + _t445_rˍtttt_t_,
    _t445_rˍt_t_ - _t445_r_t_*_tpk1_ + _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtt_t_ - _t445_rˍt_t_*_tpk1_ + _t445_r_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍttt_t_ - _t445_rˍtt_t_*_tpk1_ + _t445_r_t_*_t445_wˍtt_t_*_tpk2_ + 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍtt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtttt_t_ - _t445_rˍttt_t_*_tpk1_ + _t445_r_t_*_t445_wˍttt_t_*_tpk2_ + 3_t445_rˍt_t_*_t445_wˍtt_t_*_tpk2_ + 3_t445_rˍtt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍttt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍt_t_ + _t445_w_t_*_tpk3_ - _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_wˍtt_t_ + _t445_wˍt_t_*_tpk3_ - _t445_r_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍttt_t_ + _t445_wˍtt_t_*_tpk3_ - _t445_r_t_*_t445_wˍtt_t_*_tpk2_ - 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍtt_t_*_t445_w_t_*_tpk2_
]

