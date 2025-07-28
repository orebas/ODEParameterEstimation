# Polynomial system saved on 2025-07-28T15:15:12.026
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:15:12.026
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t223_r_t_
_t223_w_t_
_t223_rˍt_t_
_t223_rˍtt_t_
_t223_rˍttt_t_
_t223_rˍtttt_t_
_t223_wˍt_t_
_t223_wˍtt_t_
_t223_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t223_r_t_ _t223_w_t_ _t223_rˍt_t_ _t223_rˍtt_t_ _t223_rˍttt_t_ _t223_rˍtttt_t_ _t223_wˍt_t_ _t223_wˍtt_t_ _t223_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t223_r_t__t223_w_t__t223_rˍt_t__t223_rˍtt_t__t223_rˍttt_t__t223_rˍtttt_t__t223_wˍt_t__t223_wˍtt_t__t223_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.08561391546877826 + _t223_r_t_,
    -0.0438003487323716 + _t223_rˍt_t_,
    -0.03316255476518215 + _t223_rˍtt_t_,
    -0.024288170949390064 + _t223_rˍttt_t_,
    -0.019996792836991517 + _t223_rˍtttt_t_,
    _t223_rˍt_t_ - _t223_r_t_*_tpk1_ + _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_rˍtt_t_ - _t223_rˍt_t_*_tpk1_ + _t223_r_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍt_t_*_t223_w_t_*_tpk2_,
    _t223_rˍttt_t_ - _t223_rˍtt_t_*_tpk1_ + _t223_r_t_*_t223_wˍtt_t_*_tpk2_ + 2_t223_rˍt_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍtt_t_*_t223_w_t_*_tpk2_,
    _t223_rˍtttt_t_ - _t223_rˍttt_t_*_tpk1_ + _t223_r_t_*_t223_wˍttt_t_*_tpk2_ + 3_t223_rˍt_t_*_t223_wˍtt_t_*_tpk2_ + 3_t223_rˍtt_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍttt_t_*_t223_w_t_*_tpk2_,
    _t223_wˍt_t_ + _t223_w_t_*_tpk3_ - _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_wˍtt_t_ + _t223_wˍt_t_*_tpk3_ - _t223_r_t_*_t223_wˍt_t_*_tpk2_ - _t223_rˍt_t_*_t223_w_t_*_tpk2_,
    _t223_wˍttt_t_ + _t223_wˍtt_t_*_tpk3_ - _t223_r_t_*_t223_wˍtt_t_*_tpk2_ - 2_t223_rˍt_t_*_t223_wˍt_t_*_tpk2_ - _t223_rˍtt_t_*_t223_w_t_*_tpk2_
]

