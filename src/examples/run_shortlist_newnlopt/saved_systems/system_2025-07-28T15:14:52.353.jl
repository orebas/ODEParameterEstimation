# Polynomial system saved on 2025-07-28T15:14:52.353
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:52.353
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t278_r_t_
_t278_w_t_
_t278_rˍt_t_
_t278_rˍtt_t_
_t278_rˍttt_t_
_t278_rˍtttt_t_
_t278_wˍt_t_
_t278_wˍtt_t_
_t278_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t278_r_t_ _t278_w_t_ _t278_rˍt_t_ _t278_rˍtt_t_ _t278_rˍttt_t_ _t278_rˍtttt_t_ _t278_wˍt_t_ _t278_wˍtt_t_ _t278_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t278_r_t__t278_w_t__t278_rˍt_t__t278_rˍtt_t__t278_rˍttt_t__t278_rˍtttt_t__t278_wˍt_t__t278_wˍtt_t__t278_wˍttt_t_]

# Polynomial System
poly_system = [
    -0.3332852553431468 + _t278_r_t_,
    -0.23111797608064097 + _t278_rˍt_t_,
    -0.17389546918679455 + _t278_rˍtt_t_,
    -0.12586981270476422 + _t278_rˍttt_t_,
    -0.07620924406554871 + _t278_rˍtttt_t_,
    _t278_rˍt_t_ - _t278_r_t_*_tpk1_ + _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_rˍtt_t_ - _t278_rˍt_t_*_tpk1_ + _t278_r_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    _t278_rˍttt_t_ - _t278_rˍtt_t_*_tpk1_ + _t278_r_t_*_t278_wˍtt_t_*_tpk2_ + 2_t278_rˍt_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍtt_t_*_t278_w_t_*_tpk2_,
    _t278_rˍtttt_t_ - _t278_rˍttt_t_*_tpk1_ + _t278_r_t_*_t278_wˍttt_t_*_tpk2_ + 3_t278_rˍt_t_*_t278_wˍtt_t_*_tpk2_ + 3_t278_rˍtt_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍttt_t_*_t278_w_t_*_tpk2_,
    _t278_wˍt_t_ + _t278_w_t_*_tpk3_ - _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_wˍtt_t_ + _t278_wˍt_t_*_tpk3_ - _t278_r_t_*_t278_wˍt_t_*_tpk2_ - _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    _t278_wˍttt_t_ + _t278_wˍtt_t_*_tpk3_ - _t278_r_t_*_t278_wˍtt_t_*_tpk2_ - 2_t278_rˍt_t_*_t278_wˍt_t_*_tpk2_ - _t278_rˍtt_t_*_t278_w_t_*_tpk2_
]

