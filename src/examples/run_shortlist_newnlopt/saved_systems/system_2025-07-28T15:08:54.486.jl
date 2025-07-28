# Polynomial system saved on 2025-07-28T15:08:54.487
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:54.487
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x3ˍt_t_
_t501_x3ˍtt_t_
_t501_x3ˍttt_t_
_t501_x3ˍtttt_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
_t501_x1ˍtt_t_
_t501_x2ˍtt_t_
_t501_x2ˍttt_t_
_t501_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x3ˍt_t_ _t501_x3ˍtt_t_ _t501_x3ˍttt_t_ _t501_x3ˍtttt_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_ _t501_x1ˍtt_t_ _t501_x2ˍtt_t_ _t501_x2ˍttt_t_ _t501_x1ˍttt_t_
varlist = [_tpa__tpb__t501_x1_t__t501_x2_t__t501_x3_t__t501_x3ˍt_t__t501_x3ˍtt_t__t501_x3ˍttt_t__t501_x3ˍtttt_t__t501_x1ˍt_t__t501_x2ˍt_t__t501_x1ˍtt_t__t501_x2ˍtt_t__t501_x2ˍttt_t__t501_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -14.0930842697899 + _t501_x3_t_,
    -2.8103720414461435 + _t501_x3ˍt_t_,
    -0.4528988896240662 + _t501_x3ˍtt_t_,
    -0.10149733045597031 + _t501_x3ˍttt_t_,
    -0.019207715226457367 + _t501_x3ˍtttt_t_,
    -0.7529928499843371(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.7529928499843371(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.7529928499843371(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    -0.7529928499843371(_t501_x1ˍttt_t_ + _t501_x2ˍttt_t_) + _t501_x3ˍtttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_,
    _t501_x2ˍttt_t_ - _t501_x2ˍtt_t_*_tpb_,
    _t501_x1ˍttt_t_ + _t501_x1ˍtt_t_*_tpa_
]

