# Polynomial system saved on 2025-07-28T15:25:31.594
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:31.593
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
    -4.804236584732122 + _t501_x2_t_,
    0.8910533167249897 + _t501_x2ˍt_t_,
    38.01890053782605 + _t501_x2ˍtt_t_,
    -3.5181616127880213 + _t501_x1_t_,
    9.934563910186872 + _t501_x1ˍt_t_,
    -30.886205420642966 + _t501_x1ˍtt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x2ˍtt_t_ + _t501_x2ˍt_t_*_tpc_ - _t501_x1_t_*_t501_x2ˍt_t_*_tpd_ - _t501_x1ˍt_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ - _t501_x1ˍt_t_*_tpa_ + _t501_x1_t_*_t501_x2ˍt_t_*_tpb_ + _t501_x1ˍt_t_*_t501_x2_t_*_tpb_
]

