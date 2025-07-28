# Polynomial system saved on 2025-07-28T15:26:52.898
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:26:52.898
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t501_x1_t_
_t501_x2_t_
_t501_x2ˍt_t_
_t501_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t501_x1_t_ _t501_x2_t_ _t501_x2ˍt_t_ _t501_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t501_x1_t__t501_x2_t__t501_x2ˍt_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.804236579836228 + _t501_x2_t_,
    0.8910606539367968 + _t501_x2ˍt_t_,
    -3.518161613189784 + _t501_x1_t_,
    9.934572144312234 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_,
    -4.804236579836228 + _t501_x2_t_,
    0.8910606539367968 + _t501_x2ˍt_t_,
    -3.518161613189784 + _t501_x1_t_,
    9.934572144312234 + _t501_x1ˍt_t_,
    _t501_x2ˍt_t_ + _t501_x2_t_*_tpc_ - _t501_x1_t_*_t501_x2_t_*_tpd_,
    _t501_x1ˍt_t_ - _t501_x1_t_*_tpa_ + _t501_x1_t_*_t501_x2_t_*_tpb_
]

