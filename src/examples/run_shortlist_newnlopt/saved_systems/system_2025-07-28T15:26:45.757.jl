# Polynomial system saved on 2025-07-28T15:26:45.757
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:45.757
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.40766683224779166 + _t334_x2_t_,
    0.4430408658197626 + _t334_x2ˍt_t_,
    -2.391535599976905 + _t334_x1_t_,
    -2.709848209437823 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x2_t_*_tpc_ - _t334_x1_t_*_t334_x2_t_*_tpd_,
    _t334_x1ˍt_t_ - _t334_x1_t_*_tpa_ + _t334_x1_t_*_t334_x2_t_*_tpb_,
    -4.804236571758379 + _t501_x2_t_,
    0.8910609769592438 + _t501_x2ˍt_t_,
    -3.5181615815857388 + _t501_x1_t_,
    9.9345756906701 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_
]

