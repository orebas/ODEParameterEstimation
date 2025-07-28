# Polynomial system saved on 2025-07-28T15:14:42.339
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:42.339
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t111_r_t_
_t111_w_t_
_t111_rˍt_t_
_t111_rˍtt_t_
_t111_rˍttt_t_
_t111_rˍtttt_t_
_t111_wˍt_t_
_t111_wˍtt_t_
_t111_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t111_r_t_ _t111_w_t_ _t111_rˍt_t_ _t111_rˍtt_t_ _t111_rˍttt_t_ _t111_rˍtttt_t_ _t111_wˍt_t_ _t111_wˍtt_t_ _t111_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t111_r_t__t111_w_t__t111_rˍt_t__t111_rˍtt_t__t111_rˍttt_t__t111_rˍtttt_t__t111_wˍt_t__t111_wˍtt_t__t111_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.07100906619618663 + _t111_r_t_,
    0.047405580964859216 + _t111_rˍt_t_,
    -0.06296722874789566 + _t111_rˍtt_t_,
    0.08933218723256031 + _t111_rˍttt_t_,
    -0.1502807617866332 + _t111_rˍtttt_t_,
    _t111_rˍt_t_ - _t111_r_t_*_tpk1_ + _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtt_t_ - _t111_rˍt_t_*_tpk1_ + _t111_r_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍttt_t_ - _t111_rˍtt_t_*_tpk1_ + _t111_r_t_*_t111_wˍtt_t_*_tpk2_ + 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍtt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtttt_t_ - _t111_rˍttt_t_*_tpk1_ + _t111_r_t_*_t111_wˍttt_t_*_tpk2_ + 3_t111_rˍt_t_*_t111_wˍtt_t_*_tpk2_ + 3_t111_rˍtt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍttt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍt_t_ + _t111_w_t_*_tpk3_ - _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_wˍtt_t_ + _t111_wˍt_t_*_tpk3_ - _t111_r_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍttt_t_ + _t111_wˍtt_t_*_tpk3_ - _t111_r_t_*_t111_wˍtt_t_*_tpk2_ - 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍtt_t_*_t111_w_t_*_tpk2_
]

