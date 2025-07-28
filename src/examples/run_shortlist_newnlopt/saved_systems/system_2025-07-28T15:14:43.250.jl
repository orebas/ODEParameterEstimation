# Polynomial system saved on 2025-07-28T15:14:43.251
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:14:43.250
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
    -0.0710089964415821 + _t111_r_t_,
    0.04740543625928835 + _t111_rˍt_t_,
    -0.06297135152353182 + _t111_rˍtt_t_,
    0.08935002759952469 + _t111_rˍttt_t_,
    -0.14971283096297547 + _t111_rˍtttt_t_,
    _t111_rˍt_t_ - _t111_r_t_*_tpk1_ + _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtt_t_ - _t111_rˍt_t_*_tpk1_ + _t111_r_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍttt_t_ - _t111_rˍtt_t_*_tpk1_ + _t111_r_t_*_t111_wˍtt_t_*_tpk2_ + 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍtt_t_*_t111_w_t_*_tpk2_,
    _t111_rˍtttt_t_ - _t111_rˍttt_t_*_tpk1_ + _t111_r_t_*_t111_wˍttt_t_*_tpk2_ + 3_t111_rˍt_t_*_t111_wˍtt_t_*_tpk2_ + 3_t111_rˍtt_t_*_t111_wˍt_t_*_tpk2_ + _t111_rˍttt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍt_t_ + _t111_w_t_*_tpk3_ - _t111_r_t_*_t111_w_t_*_tpk2_,
    _t111_wˍtt_t_ + _t111_wˍt_t_*_tpk3_ - _t111_r_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍt_t_*_t111_w_t_*_tpk2_,
    _t111_wˍttt_t_ + _t111_wˍtt_t_*_tpk3_ - _t111_r_t_*_t111_wˍtt_t_*_tpk2_ - 2_t111_rˍt_t_*_t111_wˍt_t_*_tpk2_ - _t111_rˍtt_t_*_t111_w_t_*_tpk2_
]

