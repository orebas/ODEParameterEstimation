# Polynomial system saved on 2025-07-28T15:08:53.506
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:53.506
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
    -14.093084043996111 + _t501_x3_t_,
    -2.8103651733623733 + _t501_x3ˍt_t_,
    -0.4527974313102847 + _t501_x3ˍtt_t_,
    -0.10052437128463658 + _t501_x3ˍttt_t_,
    -0.012527136690784924 + _t501_x3ˍtttt_t_,
    -0.19606098591480925(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.19606098591480925(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.19606098591480925(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    -0.19606098591480925(_t501_x1ˍttt_t_ + _t501_x2ˍttt_t_) + _t501_x3ˍtttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_,
    _t501_x2ˍttt_t_ - _t501_x2ˍtt_t_*_tpb_,
    _t501_x1ˍttt_t_ + _t501_x1ˍtt_t_*_tpa_
]

