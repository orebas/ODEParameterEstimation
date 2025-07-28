# Polynomial system saved on 2025-07-28T15:25:37.085
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:37.085
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x2ˍtt_t_
_t501_x1ˍt_t_
_t501_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x2ˍtt_t_ _t501_x1ˍt_t_ _t501_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x2ˍtt_t__t501_x1ˍt_t__t501_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.804236560271276 + _t501_x2_t_,
    0.8910788434496266 + _t501_x2ˍt_t_,
    38.0221592003715 + _t501_x2ˍtt_t_,
    -3.5181616366184096 + _t501_x1_t_,
    9.934568426684342 + _t501_x1ˍt_t_,
    -30.88565690966581 + _t501_x1ˍtt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x2ˍtt_t_ + _t501_x2ˍt_t_*_tpc_ - _t501_x1_t_*_t501_x2ˍt_t_*_tpd_ - _t501_x1ˍt_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ - _t501_x1ˍt_t_*_tpa_ + _t501_x1_t_*_t501_x2ˍt_t_*_tpb_ + _t501_x1ˍt_t_*_t501_x2_t_*_tpb_
]

