# Polynomial system saved on 2025-07-28T15:08:50.449
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:50.449
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x3ˍt_t_
_t278_x3ˍtt_t_
_t278_x3ˍttt_t_
_t278_x3ˍtttt_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
_t278_x1ˍtt_t_
_t278_x2ˍtt_t_
_t278_x2ˍttt_t_
_t278_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x3ˍt_t_ _t278_x3ˍtt_t_ _t278_x3ˍttt_t_ _t278_x3ˍtttt_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_ _t278_x1ˍtt_t_ _t278_x2ˍtt_t_ _t278_x2ˍttt_t_ _t278_x1ˍttt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x3_t__t278_x3ˍt_t__t278_x3ˍtt_t__t278_x3ˍttt_t__t278_x3ˍtttt_t__t278_x1ˍt_t__t278_x2ˍt_t__t278_x1ˍtt_t__t278_x2ˍtt_t__t278_x2ˍttt_t__t278_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -8.782572636450748 + _t278_x3_t_,
    -2.0210127189035973 + _t278_x3ˍt_t_,
    -0.2677528191404924 + _t278_x3ˍtt_t_,
    -0.06719278531097078 + _t278_x3ˍttt_t_,
    -0.012068704874995317 + _t278_x3ˍtttt_t_,
    -0.8081793163059472(_t278_x1_t_ + _t278_x2_t_) + _t278_x3ˍt_t_,
    -0.8081793163059472(_t278_x1ˍt_t_ + _t278_x2ˍt_t_) + _t278_x3ˍtt_t_,
    -0.8081793163059472(_t278_x1ˍtt_t_ + _t278_x2ˍtt_t_) + _t278_x3ˍttt_t_,
    -0.8081793163059472(_t278_x1ˍttt_t_ + _t278_x2ˍttt_t_) + _t278_x3ˍtttt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x2_t_*_tpb_,
    _t278_x1ˍtt_t_ + _t278_x1ˍt_t_*_tpa_,
    _t278_x2ˍtt_t_ - _t278_x2ˍt_t_*_tpb_,
    _t278_x2ˍttt_t_ - _t278_x2ˍtt_t_*_tpb_,
    _t278_x1ˍttt_t_ + _t278_x1ˍtt_t_*_tpa_
]

