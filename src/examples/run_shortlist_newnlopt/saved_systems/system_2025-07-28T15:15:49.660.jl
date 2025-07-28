# Polynomial system saved on 2025-07-28T15:15:49.661
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:15:49.660
# num_equations: 18

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
_t501_wˍt_t_
_t501_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t501_r_t_ _t501_w_t_ _t501_rˍt_t_ _t501_rˍtt_t_ _t501_rˍttt_t_ _t501_wˍt_t_ _t501_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t501_r_t__t501_w_t__t501_rˍt_t__t501_rˍtt_t__t501_rˍttt_t__t501_wˍt_t__t501_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.040066111397692006 + _t501_r_t_,
    9.141951274297052e-5 + _t501_rˍt_t_,
    -0.011318644773839353 + _t501_rˍtt_t_,
    0.00043951213727278806 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    -0.040066111397692006 + _t501_r_t_,
    9.141951274297052e-5 + _t501_rˍt_t_,
    -0.011318644773839353 + _t501_rˍtt_t_,
    0.00043951213727278806 + _t501_rˍttt_t_,
    _t501_rˍt_t_ - _t501_r_t_*_tpk1_ + _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_rˍtt_t_ - _t501_rˍt_t_*_tpk1_ + _t501_r_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍt_t_*_t501_w_t_*_tpk2_,
    _t501_rˍttt_t_ - _t501_rˍtt_t_*_tpk1_ + _t501_r_t_*_t501_wˍtt_t_*_tpk2_ + 2_t501_rˍt_t_*_t501_wˍt_t_*_tpk2_ + _t501_rˍtt_t_*_t501_w_t_*_tpk2_,
    _t501_wˍt_t_ + _t501_w_t_*_tpk3_ - _t501_r_t_*_t501_w_t_*_tpk2_,
    _t501_wˍtt_t_ + _t501_wˍt_t_*_tpk3_ - _t501_r_t_*_t501_wˍt_t_*_tpk2_ - _t501_rˍt_t_*_t501_w_t_*_tpk2_
]

