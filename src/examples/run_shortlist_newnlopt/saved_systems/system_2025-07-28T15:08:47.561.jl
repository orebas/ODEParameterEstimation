# Polynomial system saved on 2025-07-28T15:08:47.562
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:47.561
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x3_t_
_t111_x3ˍt_t_
_t111_x3ˍtt_t_
_t111_x3ˍttt_t_
_t111_x3ˍtttt_t_
_t111_x1ˍt_t_
_t111_x2ˍt_t_
_t111_x1ˍtt_t_
_t111_x2ˍtt_t_
_t111_x2ˍttt_t_
_t111_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x3_t_ _t111_x3ˍt_t_ _t111_x3ˍtt_t_ _t111_x3ˍttt_t_ _t111_x3ˍtttt_t_ _t111_x1ˍt_t_ _t111_x2ˍt_t_ _t111_x1ˍtt_t_ _t111_x2ˍtt_t_ _t111_x2ˍttt_t_ _t111_x1ˍttt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x3_t__t111_x3ˍt_t__t111_x3ˍtt_t__t111_x3ˍttt_t__t111_x3ˍtttt_t__t111_x1ˍt_t__t111_x2ˍt_t__t111_x1ˍtt_t__t111_x2ˍtt_t__t111_x2ˍttt_t__t111_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -5.732340457379875 + _t111_x3_t_,
    -1.6589694575118967 + _t111_x3ˍt_t_,
    -0.170543885412563 + _t111_x3ˍtt_t_,
    -0.05023660745890045 + _t111_x3ˍttt_t_,
    -0.008429106767331525 + _t111_x3ˍtttt_t_,
    -0.5982393991634904(_t111_x1_t_ + _t111_x2_t_) + _t111_x3ˍt_t_,
    -0.5982393991634904(_t111_x1ˍt_t_ + _t111_x2ˍt_t_) + _t111_x3ˍtt_t_,
    -0.5982393991634904(_t111_x1ˍtt_t_ + _t111_x2ˍtt_t_) + _t111_x3ˍttt_t_,
    -0.5982393991634904(_t111_x1ˍttt_t_ + _t111_x2ˍttt_t_) + _t111_x3ˍtttt_t_,
    _t111_x1ˍt_t_ + _t111_x1_t_*_tpa_,
    _t111_x2ˍt_t_ - _t111_x2_t_*_tpb_,
    _t111_x1ˍtt_t_ + _t111_x1ˍt_t_*_tpa_,
    _t111_x2ˍtt_t_ - _t111_x2ˍt_t_*_tpb_,
    _t111_x2ˍttt_t_ - _t111_x2ˍtt_t_*_tpb_,
    _t111_x1ˍttt_t_ + _t111_x1ˍtt_t_*_tpa_
]

