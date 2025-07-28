# Polynomial system saved on 2025-07-28T15:08:52.193
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:52.192
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x3_t_
_t390_x3ˍt_t_
_t390_x3ˍtt_t_
_t390_x3ˍttt_t_
_t390_x3ˍtttt_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
_t390_x1ˍtt_t_
_t390_x2ˍtt_t_
_t390_x2ˍttt_t_
_t390_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x3_t_ _t390_x3ˍt_t_ _t390_x3ˍtt_t_ _t390_x3ˍttt_t_ _t390_x3ˍtttt_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_ _t390_x1ˍtt_t_ _t390_x2ˍtt_t_ _t390_x2ˍttt_t_ _t390_x1ˍttt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x3_t__t390_x3ˍt_t__t390_x3ˍtt_t__t390_x3ˍttt_t__t390_x3ˍtttt_t__t390_x1ˍt_t__t390_x2ˍt_t__t390_x1ˍtt_t__t390_x2ˍtt_t__t390_x2ˍttt_t__t390_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -11.230605922848714 + _t390_x3_t_,
    -2.3660430798420333 + _t390_x3ˍt_t_,
    -0.3512170412561242 + _t390_x3ˍtt_t_,
    -0.08243591209460766 + _t390_x3ˍttt_t_,
    -0.015227694864815117 + _t390_x3ˍtttt_t_,
    -0.3924801679072325(_t390_x1_t_ + _t390_x2_t_) + _t390_x3ˍt_t_,
    -0.3924801679072325(_t390_x1ˍt_t_ + _t390_x2ˍt_t_) + _t390_x3ˍtt_t_,
    -0.3924801679072325(_t390_x1ˍtt_t_ + _t390_x2ˍtt_t_) + _t390_x3ˍttt_t_,
    -0.3924801679072325(_t390_x1ˍttt_t_ + _t390_x2ˍttt_t_) + _t390_x3ˍtttt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x2_t_*_tpb_,
    _t390_x1ˍtt_t_ + _t390_x1ˍt_t_*_tpa_,
    _t390_x2ˍtt_t_ - _t390_x2ˍt_t_*_tpb_,
    _t390_x2ˍttt_t_ - _t390_x2ˍtt_t_*_tpb_,
    _t390_x1ˍttt_t_ + _t390_x1ˍtt_t_*_tpa_
]

