# Polynomial system saved on 2025-07-28T15:15:29.837
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:29.836
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
    -0.07100897163994502 + _t111_r_t_,
    0.04740597220942031 + _t111_rˍt_t_,
    -0.06296800534655272 + _t111_rˍtt_t_,
    0.08932214871295048 + _t111_rˍttt_t_,
    _t111_rˍt_t_ - _t111_r_t_*_tpk1_ + _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtt_t_ - _t111_rˍt_t_*_tpk1_ + _t111_r_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍttt_t_ - _t111_rˍtt_t_*_tpk1_ + _t111_r_t_*_t111_wˍtt_t_*_tpk2_ + 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍtt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍt_t_ + _t111_w_t_*_tpk3_ - _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_wˍtt_t_ + _t111_wˍt_t_*_tpk3_ - _t111_r_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    -0.3332852553431468 + _t278_r_t_,
    -0.2311181824679579 + _t278_rˍt_t_,
    -0.17389595549558348 + _t278_rˍtt_t_,
    -0.12583610342766074 + _t278_rˍttt_t_,
    _t278_rˍt_t_ - _t278_r_t_*_tpk1_ + _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_rˍtt_t_ - _t278_rˍt_t_*_tpk1_ + _t278_r_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍt_t_*_t278_w_t_*_tpk2_,
    _t278_rˍttt_t_ - _t278_rˍtt_t_*_tpk1_ + _t278_r_t_*_t278_wˍtt_t_*_tpk2_ + 2_t278_rˍt_t_*_t278_wˍt_t_*_tpk2_ + _t278_rˍtt_t_*_t278_w_t_*_tpk2_,
    _t278_wˍt_t_ + _t278_w_t_*_tpk3_ - _t278_r_t_*_t278_w_t_*_tpk2_,
    _t278_wˍtt_t_ + _t278_wˍt_t_*_tpk3_ - _t278_r_t_*_t278_wˍt_t_*_tpk2_ - _t278_rˍt_t_*_t278_w_t_*_tpk2_
]

