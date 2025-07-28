# Polynomial system saved on 2025-07-28T15:18:29.960
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:29.959
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x1ˍt_t__t334_x2ˍt_t__t501_x1_t__t501_x2_t__t501_x1ˍt_t__t501_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.142607998631041 + 3.0_t334_x1_t_ - 0.25_t334_x2_t_,
    2.9418563220747247 + 2.0_t334_x1_t_ + 0.5_t334_x2_t_,
    1.2452124338811437 + 2.0_t334_x1ˍt_t_ + 0.5_t334_x2ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x2_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x1_t_*_tpb_,
    3.7943653349842945 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    3.507608270638238 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.6188198275402137 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_
]

