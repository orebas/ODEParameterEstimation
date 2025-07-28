# Polynomial system saved on 2025-07-28T15:14:19.739
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:19.739
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t56_r_t_
_t56_w_t_
_t56_rˍt_t_
_t56_rˍtt_t_
_t56_rˍttt_t_
_t56_rˍtttt_t_
_t56_wˍt_t_
_t56_wˍtt_t_
_t56_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t56_r_t_ _t56_w_t_ _t56_rˍt_t_ _t56_rˍtt_t_ _t56_rˍttt_t_ _t56_rˍtttt_t_ _t56_wˍt_t_ _t56_wˍtt_t_ _t56_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t56_r_t__t56_w_t__t56_rˍt_t__t56_rˍtt_t__t56_rˍttt_t__t56_rˍtttt_t__t56_wˍt_t__t56_wˍtt_t__t56_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.8547989401523806 + _t56_r_t_,
    1.176432442280314 + _t56_rˍt_t_,
    -1.3603130121687534 + _t56_rˍtt_t_,
    -0.0019903817198406843 + _t56_rˍttt_t_,
    6.96499767340773 + _t56_rˍtttt_t_,
    _t56_rˍt_t_ - _t56_r_t_*_tpk1_ + _t56_r_t_*_t56_w_t_*_tpk2_,
    _t56_rˍtt_t_ - _t56_rˍt_t_*_tpk1_ + _t56_r_t_*_t56_wˍt_t_*_tpk2_ + _t56_rˍt_t_*_t56_w_t_*_tpk2_,
    _t56_rˍttt_t_ - _t56_rˍtt_t_*_tpk1_ + _t56_r_t_*_t56_wˍtt_t_*_tpk2_ + 2_t56_rˍt_t_*_t56_wˍt_t_*_tpk2_ + _t56_rˍtt_t_*_t56_w_t_*_tpk2_,
    _t56_rˍtttt_t_ - _t56_rˍttt_t_*_tpk1_ + _t56_r_t_*_t56_wˍttt_t_*_tpk2_ + 3_t56_rˍt_t_*_t56_wˍtt_t_*_tpk2_ + 3_t56_rˍtt_t_*_t56_wˍt_t_*_tpk2_ + _t56_rˍttt_t_*_t56_w_t_*_tpk2_,
    _t56_wˍt_t_ + _t56_w_t_*_tpk3_ - _t56_r_t_*_t56_w_t_*_tpk2_,
    _t56_wˍtt_t_ + _t56_wˍt_t_*_tpk3_ - _t56_r_t_*_t56_wˍt_t_*_tpk2_ - _t56_rˍt_t_*_t56_w_t_*_tpk2_,
    _t56_wˍttt_t_ + _t56_wˍtt_t_*_tpk3_ - _t56_r_t_*_t56_wˍtt_t_*_tpk2_ - 2_t56_rˍt_t_*_t56_wˍt_t_*_tpk2_ - _t56_rˍtt_t_*_t56_w_t_*_tpk2_
]

