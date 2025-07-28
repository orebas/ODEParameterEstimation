# Polynomial system saved on 2025-07-28T15:15:27.881
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:27.881
# num_equations: 18

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
_t56_wˍt_t_
_t56_wˍtt_t_
_t223_r_t_
_t223_w_t_
_t223_rˍt_t_
_t223_rˍtt_t_
_t223_rˍttt_t_
_t223_wˍt_t_
_t223_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t56_r_t_ _t56_w_t_ _t56_rˍt_t_ _t56_rˍtt_t_ _t56_rˍttt_t_ _t56_wˍt_t_ _t56_wˍtt_t_ _t223_r_t_ _t223_w_t_ _t223_rˍt_t_ _t223_rˍtt_t_ _t223_rˍttt_t_ _t223_wˍt_t_ _t223_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t56_r_t__t56_w_t__t56_rˍt_t__t56_rˍtt_t__t56_rˍttt_t__t56_wˍt_t__t56_wˍtt_t__t223_r_t__t223_w_t__t223_rˍt_t__t223_rˍtt_t__t223_rˍttt_t__t223_wˍt_t__t223_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.8547988928742597 + _t56_r_t_,
    1.1764326567439698 + _t56_rˍt_t_,
    -1.3603090693503652 + _t56_rˍtt_t_,
    -0.002023637567595767 + _t56_rˍttt_t_,
    _t56_rˍt_t_ - _t56_r_t_*_tpk1_ + _t56_r_t_*_t56_w_t_*_tpk2_,
    _t56_rˍtt_t_ - _t56_rˍt_t_*_tpk1_ + _t56_r_t_*_t56_wˍt_t_*_tpk2_ + _t56_rˍt_t_*_t56_w_t_*_tpk2_,
    _t56_rˍttt_t_ - _t56_rˍtt_t_*_tpk1_ + _t56_r_t_*_t56_wˍtt_t_*_tpk2_ + 2_t56_rˍt_t_*_t56_wˍt_t_*_tpk2_ + _t56_rˍtt_t_*_t56_w_t_*_tpk2_,
    _t56_wˍt_t_ + _t56_w_t_*_tpk3_ - _t56_r_t_*_t56_w_t_*_tpk2_,
    _t56_wˍtt_t_ + _t56_wˍt_t_*_tpk3_ - _t56_r_t_*_t56_wˍt_t_*_tpk2_ - _t56_rˍt_t_*_t56_w_t_*_tpk2_,
    -0.08561391365221283 + _t223_r_t_,
    -0.043800352926911555 + _t223_rˍt_t_,
    -0.03316236343797009 + _t223_rˍtt_t_,
    -0.0242853398185517 + _t223_rˍttt_t_,
    _t223_rˍt_t_ - _t223_r_t_*_tpk1_ + _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_rˍtt_t_ - _t223_rˍt_t_*_tpk1_ + _t223_r_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍt_t_*_t223_w_t_*_tpk2_,
    _t223_rˍttt_t_ - _t223_rˍtt_t_*_tpk1_ + _t223_r_t_*_t223_wˍtt_t_*_tpk2_ + 2_t223_rˍt_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍtt_t_*_t223_w_t_*_tpk2_,
    _t223_wˍt_t_ + _t223_w_t_*_tpk3_ - _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_wˍtt_t_ + _t223_wˍt_t_*_tpk3_ - _t223_r_t_*_t223_wˍt_t_*_tpk2_ - _t223_rˍt_t_*_t223_w_t_*_tpk2_
]

