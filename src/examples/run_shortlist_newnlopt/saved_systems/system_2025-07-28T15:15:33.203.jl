# Polynomial system saved on 2025-07-28T15:15:33.203
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:33.203
# num_equations: 18

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
_t278_wˍt_t_
_t278_wˍtt_t_
_t445_r_t_
_t445_w_t_
_t445_rˍt_t_
_t445_rˍtt_t_
_t445_rˍttt_t_
_t445_wˍt_t_
_t445_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t278_r_t_ _t278_w_t_ _t278_rˍt_t_ _t278_rˍtt_t_ _t278_rˍttt_t_ _t278_wˍt_t_ _t278_wˍtt_t_ _t445_r_t_ _t445_w_t_ _t445_rˍt_t_ _t445_rˍtt_t_ _t445_rˍttt_t_ _t445_wˍt_t_ _t445_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t278_r_t__t278_w_t__t278_rˍt_t__t278_rˍtt_t__t278_rˍttt_t__t278_wˍt_t__t278_wˍtt_t__t445_r_t__t445_w_t__t445_rˍt_t__t445_rˍtt_t__t445_rˍttt_t__t445_wˍt_t__t445_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.333285259799691 + _t278_r_t_,
    -0.23111804584087303 + _t278_rˍt_t_,
    -0.1738943028408687 + _t278_rˍtt_t_,
    -0.1258539975139957 + _t278_rˍttt_t_,
    _t278_rˍt_t_ - _t278_r_t_*_tpk1_ + _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_rˍtt_t_ - _t278_rˍt_t_*_tpk1_ + _t278_r_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    _t278_rˍttt_t_ - _t278_rˍtt_t_*_tpk1_ + _t278_r_t_*_t278_wˍtt_t_*_tpk2_ + 2_t278_rˍt_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍtt_t_*_t278_w_t_*_tpk2_,
    _t278_wˍt_t_ + _t278_w_t_*_tpk3_ - _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_wˍtt_t_ + _t278_wˍt_t_*_tpk3_ - _t278_r_t_*_t278_wˍt_t_*_tpk2_ - _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    -0.0955471000647311 + _t445_r_t_,
    0.0808350105771921 + _t445_rˍt_t_,
    -0.11287594951757463 + _t445_rˍtt_t_,
    0.17484145895343708 + _t445_rˍttt_t_,
    _t445_rˍt_t_ - _t445_r_t_*_tpk1_ + _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_rˍtt_t_ - _t445_rˍt_t_*_tpk1_ + _t445_r_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍt_t_*_t445_w_t_*_tpk2_,
    _t445_rˍttt_t_ - _t445_rˍtt_t_*_tpk1_ + _t445_r_t_*_t445_wˍtt_t_*_tpk2_ + 2_t445_rˍt_t_*_t445_wˍt_t_*_tpk2_ + _t445_rˍtt_t_*_t445_w_t_*_tpk2_,
    _t445_wˍt_t_ + _t445_w_t_*_tpk3_ - _t445_r_t_*_t445_w_t_*_tpk2_,
    _t445_wˍtt_t_ + _t445_wˍt_t_*_tpk3_ - _t445_r_t_*_t445_wˍt_t_*_tpk2_ - _t445_rˍt_t_*_t445_w_t_*_tpk2_
]

