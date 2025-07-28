# Polynomial system saved on 2025-07-28T15:15:29.125
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:29.125
# num_equations: 18

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
_t111_wˍt_t_
_t111_wˍtt_t_
_t278_r_t_
_t278_w_t_
_t278_rˍt_t_
_t278_rˍtt_t_
_t278_rˍttt_t_
_t278_wˍt_t_
_t278_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t111_r_t_ _t111_w_t_ _t111_rˍt_t_ _t111_rˍtt_t_ _t111_rˍttt_t_ _t111_wˍt_t_ _t111_wˍtt_t_ _t278_r_t_ _t278_w_t_ _t278_rˍt_t_ _t278_rˍtt_t_ _t278_rˍttt_t_ _t278_wˍt_t_ _t278_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t111_r_t__t111_w_t__t111_rˍt_t__t111_rˍtt_t__t111_rˍttt_t__t111_wˍt_t__t111_wˍtt_t__t278_r_t__t278_w_t__t278_rˍt_t__t278_rˍtt_t__t278_rˍttt_t__t278_wˍt_t__t278_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.07100906774628901 + _t111_r_t_,
    0.047405588935872905 + _t111_rˍt_t_,
    -0.06296746507813746 + _t111_rˍtt_t_,
    0.0893323391694429 + _t111_rˍttt_t_,
    _t111_rˍt_t_ - _t111_r_t_*_tpk1_ + _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtt_t_ - _t111_rˍt_t_*_tpk1_ + _t111_r_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍttt_t_ - _t111_rˍtt_t_*_tpk1_ + _t111_r_t_*_t111_wˍtt_t_*_tpk2_ + 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍtt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍt_t_ + _t111_w_t_*_tpk3_ - _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_wˍtt_t_ + _t111_wˍt_t_*_tpk3_ - _t111_r_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    -0.33328526541881187 + _t278_r_t_,
    -0.23111795960262765 + _t278_rˍt_t_,
    -0.17389375122783005 + _t278_rˍtt_t_,
    -0.12586534976677552 + _t278_rˍttt_t_,
    _t278_rˍt_t_ - _t278_r_t_*_tpk1_ + _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_rˍtt_t_ - _t278_rˍt_t_*_tpk1_ + _t278_r_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    _t278_rˍttt_t_ - _t278_rˍtt_t_*_tpk1_ + _t278_r_t_*_t278_wˍtt_t_*_tpk2_ + 2_t278_rˍt_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍtt_t_*_t278_w_t_*_tpk2_,
    _t278_wˍt_t_ + _t278_w_t_*_tpk3_ - _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_wˍtt_t_ + _t278_wˍt_t_*_tpk3_ - _t278_r_t_*_t278_wˍt_t_*_tpk2_ - _t278_rˍt_t_*_t278_w_t_*_tpk2_
]

