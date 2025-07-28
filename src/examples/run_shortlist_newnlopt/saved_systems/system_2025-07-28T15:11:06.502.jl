# Polynomial system saved on 2025-07-28T15:11:06.502
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:06.502
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t445_x1_t_
_t445_x2_t_
_t445_x3_t_
_t445_x2ˍt_t_
_t445_x3ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x2ˍt_t_ _t445_x3ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t445_x1_t__t445_x2_t__t445_x3_t__t445_x2ˍt_t__t445_x3ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.05364450394318 + _t445_x2_t_^3,
    1.7424251374646937 + 3(_t445_x2_t_^2)*_t445_x2ˍt_t_,
    -8.922608141414194 + _t445_x3_t_^3,
    3.818004442707093 + 3(_t445_x3_t_^2)*_t445_x3ˍt_t_,
    -0.9589571630861546 + _t445_x1_t_^3,
    0.5006362822461154 + 3(_t445_x1_t_^2)*_t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x1_t_*_tpb_,
    _t445_x3ˍt_t_ + _t445_x1_t_*_tpc_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

