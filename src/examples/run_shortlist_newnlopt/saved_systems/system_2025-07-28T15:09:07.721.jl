# Polynomial system saved on 2025-07-28T15:09:07.721
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:09:07.721
# num_equations: 22

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
_t501_x1ˍt_t_
_t501_x2ˍt_t_
_t501_x1ˍtt_t_
_t501_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x3ˍt_t_ _t501_x3ˍtt_t_ _t501_x3ˍttt_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_ _t501_x1ˍtt_t_ _t501_x2ˍtt_t_
varlist = [_tpa__tpb__t501_x1_t__t501_x2_t__t501_x3_t__t501_x3ˍt_t__t501_x3ˍtt_t__t501_x3ˍttt_t__t501_x1ˍt_t__t501_x2ˍt_t__t501_x1ˍtt_t__t501_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -14.093084048495955 + _t501_x3_t_,
    -2.810365608360703 + _t501_x3ˍt_t_,
    -0.4528061557915358 + _t501_x3ˍtt_t_,
    -0.10063365591471658 + _t501_x3ˍttt_t_,
    -0.6815298657153118(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.6815298657153118(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.6815298657153118(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_,
    -14.093084048495955 + _t501_x3_t_,
    -2.810365608360703 + _t501_x3ˍt_t_,
    -0.4528061557915358 + _t501_x3ˍtt_t_,
    -0.10063365591471658 + _t501_x3ˍttt_t_,
    -0.6815298657153118(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.6815298657153118(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.6815298657153118(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_
]

