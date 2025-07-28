# Polynomial system saved on 2025-07-28T15:26:51.791
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:51.791
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.38551702048515124 + _t445_x2_t_,
    0.3715984892308662 + _t445_x2ˍt_t_,
    -2.5451292818226383 + _t445_x1_t_,
    -2.9346224408039516 + _t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x2_t_*_tpc_ - _t445_x1_t_*_t445_x2_t_*_tpd_,
    _t445_x1ˍt_t_ - _t445_x1_t_*_tpa_ + _t445_x1_t_*_t445_x2_t_*_tpb_,
    -4.80423653477518 + _t501_x2_t_,
    0.8910001087267975 + _t501_x2ˍt_t_,
    -3.5181616367366932 + _t501_x1_t_,
    9.93456345323706 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_
]

