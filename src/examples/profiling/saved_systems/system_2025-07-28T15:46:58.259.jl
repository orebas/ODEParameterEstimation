# Polynomial system saved on 2025-07-28T15:46:58.260
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:46:58.259
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t179_x1_t_
_t179_x2_t_
_t179_x3_t_
_t179_x2ˍt_t_
_t179_x3ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t179_x1_t_ _t179_x2_t_ _t179_x3_t_ _t179_x2ˍt_t_ _t179_x3ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t179_x1_t__t179_x2_t__t179_x3_t__t179_x2ˍt_t__t179_x3ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.036255406014853 + _t179_x2_t_^3,
    1.73540061854187 + 3(_t179_x2_t_^2)*_t179_x2ˍt_t_,
    -8.884515541721012 + _t179_x3_t_^3,
    3.8005090448363714 + 3(_t179_x3_t_^2)*_t179_x3ˍt_t_,
    -0.9539622360028797 + _t179_x1_t_^3,
    0.4983237147154658 + 3(_t179_x1_t_^2)*_t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x1_t_*_tpb_,
    _t179_x3ˍt_t_ + _t179_x1_t_*_tpc_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

