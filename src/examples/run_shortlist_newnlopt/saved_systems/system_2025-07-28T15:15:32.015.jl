# Polynomial system saved on 2025-07-28T15:15:32.015
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:15:32.015
# num_equations: 18

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
_t223_wˍt_t_
_t223_wˍtt_t_
_t390_r_t_
_t390_w_t_
_t390_rˍt_t_
_t390_rˍtt_t_
_t390_rˍttt_t_
_t390_wˍt_t_
_t390_wˍtt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t223_r_t_ _t223_w_t_ _t223_rˍt_t_ _t223_rˍtt_t_ _t223_rˍttt_t_ _t223_wˍt_t_ _t223_wˍtt_t_ _t390_r_t_ _t390_w_t_ _t390_rˍt_t_ _t390_rˍtt_t_ _t390_rˍttt_t_ _t390_wˍt_t_ _t390_wˍtt_t_
varlist = [_tpk1__tpk2__tpk3__t223_r_t__t223_w_t__t223_rˍt_t__t223_rˍtt_t__t223_rˍttt_t__t223_wˍt_t__t223_wˍtt_t__t390_r_t__t390_w_t__t390_rˍt_t__t390_rˍtt_t__t390_rˍttt_t__t390_wˍt_t__t390_wˍtt_t_]

# Polynomial System
poly_system = [
    -0.08561391791499418 + _t223_r_t_,
    -0.04380029917383475 + _t223_rˍt_t_,
    -0.03316302206004105 + _t223_rˍtt_t_,
    -0.024294917624585844 + _t223_rˍttt_t_,
    _t223_rˍt_t_ - _t223_r_t_*_tpk1_ + _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_rˍtt_t_ - _t223_rˍt_t_*_tpk1_ + _t223_r_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍt_t_*_t223_w_t_*_tpk2_,
    _t223_rˍttt_t_ - _t223_rˍtt_t_*_tpk1_ + _t223_r_t_*_t223_wˍtt_t_*_tpk2_ + 2_t223_rˍt_t_*_t223_wˍt_t_*_tpk2_ + _t223_rˍtt_t_*_t223_w_t_*_tpk2_,
    _t223_wˍt_t_ + _t223_w_t_*_tpk3_ - _t223_r_t_*_t223_w_t_*_tpk2_,
    _t223_wˍtt_t_ + _t223_wˍt_t_*_tpk3_ - _t223_r_t_*_t223_wˍt_t_*_tpk2_ - _t223_rˍt_t_*_t223_w_t_*_tpk2_,
    -1.4129169965545176 + _t390_r_t_,
    1.6193277701758766 + _t390_rˍt_t_,
    -0.6234242845337823 + _t390_rˍtt_t_,
    -4.064789566932445 + _t390_rˍttt_t_,
    _t390_rˍt_t_ - _t390_r_t_*_tpk1_ + _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_rˍtt_t_ - _t390_rˍt_t_*_tpk1_ + _t390_r_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍt_t_*_t390_w_t_*_tpk2_,
    _t390_rˍttt_t_ - _t390_rˍtt_t_*_tpk1_ + _t390_r_t_*_t390_wˍtt_t_*_tpk2_ + 2_t390_rˍt_t_*_t390_wˍt_t_*_tpk2_ + _t390_rˍtt_t_*_t390_w_t_*_tpk2_,
    _t390_wˍt_t_ + _t390_w_t_*_tpk3_ - _t390_r_t_*_t390_w_t_*_tpk2_,
    _t390_wˍtt_t_ + _t390_wˍt_t_*_tpk3_ - _t390_r_t_*_t390_wˍt_t_*_tpk2_ - _t390_rˍt_t_*_t390_w_t_*_tpk2_
]

