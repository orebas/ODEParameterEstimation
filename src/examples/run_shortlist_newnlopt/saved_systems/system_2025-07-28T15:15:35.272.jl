# Polynomial system saved on 2025-07-28T15:15:35.272
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:35.272
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
    -1.5681737869503531 + _t334_r_t_,
    -0.9610520996721963 + _t334_rˍt_t_,
    -0.2950750778189117 + _t334_rˍtt_t_,
    0.6134435276981733 + _t334_rˍttt_t_,
    _t334_rˍt_t_ - _t334_r_t_*_tpk1_ + _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtt_t_ - _t334_rˍt_t_*_tpk1_ + _t334_r_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍttt_t_ - _t334_rˍtt_t_*_tpk1_ + _t334_r_t_*_t334_wˍtt_t_*_tpk2_ + 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍtt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍt_t_ + _t334_w_t_*_tpk3_ - _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_wˍtt_t_ + _t334_wˍt_t_*_tpk3_ - _t334_r_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    -0.04006610147263978 + _t501_r_t_,
    9.293258215219595e-5 + _t501_rˍt_t_,
    -0.011237843462005676 + _t501_rˍtt_t_,
    0.0033064633914747857 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_
]

