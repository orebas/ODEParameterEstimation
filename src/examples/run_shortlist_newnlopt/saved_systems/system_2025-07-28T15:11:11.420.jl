# Polynomial system saved on 2025-07-28T15:11:11.420
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:11.420
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
    -5.053644449924292 + _t445_x2_t_^3,
    1.7424250350664785 + 3(_t445_x2_t_^2)*_t445_x2ˍt_t_,
    -8.922608261703417 + _t445_x3_t_^3,
    3.818007609747383 + 3(_t445_x3_t_^2)*_t445_x3ˍt_t_,
    -0.9589571208241047 + _t445_x1_t_^3,
    0.5006362294439679 + 3(_t445_x1_t_^2)*_t445_x1ˍt_t_,
    _t445_x2ˍt_t_ + _t445_x1_t_*_tpb_,
    _t445_x3ˍt_t_ + _t445_x1_t_*_tpc_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

