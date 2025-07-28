# Polynomial system saved on 2025-07-28T15:15:15.784
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:15:15.783
# num_equations: 12

# Variables
varlist_str = """
_tpk1_
_tpk2_
_tpk3_
_t334_r_t_
_t334_w_t_
_t334_rˍt_t_
_t334_rˍtt_t_
_t334_rˍttt_t_
_t334_rˍtttt_t_
_t334_wˍt_t_
_t334_wˍtt_t_
_t334_wˍttt_t_
"""
@variables _tpk1_ _tpk2_ _tpk3_ _t334_r_t_ _t334_w_t_ _t334_rˍt_t_ _t334_rˍtt_t_ _t334_rˍttt_t_ _t334_rˍtttt_t_ _t334_wˍt_t_ _t334_wˍtt_t_ _t334_wˍttt_t_
varlist = [_tpk1__tpk2__tpk3__t334_r_t__t334_w_t__t334_rˍt_t__t334_rˍtt_t__t334_rˍttt_t__t334_rˍtttt_t__t334_wˍt_t__t334_wˍtt_t__t334_wˍttt_t_]

# Polynomial System
poly_system = [
    -1.5681738677533137 + _t334_r_t_,
    -0.9610519555423247 + _t334_rˍt_t_,
    -0.29507882272383057 + _t334_rˍtt_t_,
    0.6134041716832996 + _t334_rˍttt_t_,
    1.921904568161608 + _t334_rˍtttt_t_,
    _t334_rˍt_t_ - _t334_r_t_*_tpk1_ + _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtt_t_ - _t334_rˍt_t_*_tpk1_ + _t334_r_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍttt_t_ - _t334_rˍtt_t_*_tpk1_ + _t334_r_t_*_t334_wˍtt_t_*_tpk2_ + 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍtt_t_*_t334_w_t_*_tpk2_,
    _t334_rˍtttt_t_ - _t334_rˍttt_t_*_tpk1_ + _t334_r_t_*_t334_wˍttt_t_*_tpk2_ + 3_t334_rˍt_t_*_t334_wˍtt_t_*_tpk2_ + 3_t334_rˍtt_t_*_t334_wˍt_t_*_tpk2_ + _t334_rˍttt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍt_t_ + _t334_w_t_*_tpk3_ - _t334_r_t_*_t334_w_t_*_tpk2_,
    _t334_wˍtt_t_ + _t334_wˍt_t_*_tpk3_ - _t334_r_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍt_t_*_t334_w_t_*_tpk2_,
    _t334_wˍttt_t_ + _t334_wˍtt_t_*_tpk3_ - _t334_r_t_*_t334_wˍtt_t_*_tpk2_ - 2_t334_rˍt_t_*_t334_wˍt_t_*_tpk2_ - _t334_rˍtt_t_*_t334_w_t_*_tpk2_
]

